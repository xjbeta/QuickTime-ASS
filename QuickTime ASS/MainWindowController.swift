//
//  MainWindowController.swift
//  QuickTime ASS
//
//  Created by xjbeta on 1/19/21.
//

import Cocoa

class MainWindowController: NSWindowController {

    let player = QTPlayer.shared
    
    var targeWindow: QuickTimePlayerWindow?
    
    var windowInFront = false {
        didSet {
            NotificationCenter.default.post(name: .updateTargeWindowState, object: nil)
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.level = .floating
        window?.backgroundColor = .clear
        window?.isOpaque = false
        window?.ignoresMouseEvents = true
        window?.orderOut(self)
        
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(updateWindowState), name: NSWorkspace.didActivateApplicationNotification, object: nil)
        
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(updateWindowState), name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
        
        acquirePrivileges {
            print("Accessibility enabled: \($0)")
        }
    }
    
    @objc func updateWindowState(_ notification: NSNotification) {
        
        let info = QTPlayer.shared.frontmostAppInfo()
        guard info.isQTPlayer else {
                if let window = window, window.isVisible {
                    window.orderOut(self)
                    windowInFront = false
                }
                return
        }
        
        setObserver(info.processIdentifier)
        self.resizeWindow()
    }
    
    func acquirePrivileges(_ block: @escaping (Bool) -> Void) {
        let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        let privOptions = [trusted: true] as CFDictionary
        let accessEnabled = AXIsProcessTrustedWithOptions(privOptions)
        if !accessEnabled {
            let alert = NSAlert()
            alert.messageText = "Enable QuickTimer Player ASS"
            alert.informativeText = "Once you have enabled QuickTimer Player ASS in System Preferences, click OK."

            alert.runModal()
            let t = AXIsProcessTrustedWithOptions(privOptions)
            block(t)
        } else {
            block(true)
        }
    }
    
    func setObserver(_ pid: pid_t) {

        let observerCallback: AXObserverCallback = {
            observer, element, notification, refcon in

            guard let ref = refcon else { return }
            let wc = Unmanaged<MainWindowController>.fromOpaque(ref).takeUnretainedValue()
            
            switch String(notification) {
            case kAXMovedNotification:
                wc.resizeWindowA(element)
            case kAXResizedNotification:
                wc.resizeWindowA(element)
            case kAXValueChangedNotification:
                var des: CFTypeRef?
                AXUIElementCopyAttributeValue(element, kAXDescription as CFString, &des)
                guard let str = des as? String else { return }

                switch str {
                case "play/pause":
                    NotificationCenter.default.post(name: .updatePlayState, object: nil)
                case "timeline":
                    guard let vc = wc.contentViewController as? MainViewController,
                          let playing = vc.playerWindow?.document?.playing,
                          !playing else { return }
                    vc.updateSubtitle()
                default:
                    break
                }
            default:
                break
            }
        }
        
        var window: CFTypeRef?
        
        let app = AXUIElementCreateApplication(pid)
        AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &window)
        
        let observer = UnsafeMutablePointer<AXObserver?>.allocate(capacity: 1)
        AXObserverCreate(pid, observerCallback as AXObserverCallback, observer)

        guard let obs = observer.pointee,
              let windowRef = window else { return }
        
        let s = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        AXObserverAddNotification(
            obs,
            windowRef as! AXUIElement,
            kAXMovedNotification as CFString,
            s)
        AXObserverAddNotification(
            obs,
            windowRef as! AXUIElement,
            kAXResizedNotification as CFString,
            s)
        
        var children: CFTypeRef?
        AXUIElementCopyAttributeValue(windowRef as! AXUIElement, kAXChildrenAttribute as CFString, &children)
        
        let elements = children as! [AXUIElement]
        let pauseButton = elements.first { element in
            var des: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXDescription as CFString, &des)
            return des as? String == "play/pause"
        }
        
        guard let pauseButtonRef = pauseButton else { return }
        
        AXObserverAddNotification(
            obs,
            pauseButtonRef,
            kAXValueChangedNotification as CFString,
            s)
        
        let timeSlider = elements.first { element in
            var des: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXDescription as CFString, &des)
            return des as? String == "timeline"
        }

        guard let timeSliderRef = timeSlider else { return }

        let error = AXObserverAddNotification(
            obs,
            timeSliderRef,
            kAXValueChangedNotification as CFString,
            s)
        
        print(error)
        
        CFRunLoopAddSource(
            CFRunLoopGetCurrent(),
            AXObserverGetRunLoopSource(obs),
            CFRunLoopMode.commonModes)
    }
    
    @objc func resizeWindow() {
        guard let w = self.window,
              let pWindow = player.targeWindow(),
              var rect = pWindow.bounds,
              let screen = NSScreen.main else { return }
        
        rect.origin.y = screen.frame.height - rect.height - rect.origin.y
        
        w.setFrame(rect, display: true)
        

        if !w.isVisible || !w.isOnActiveSpace {
            w.orderFront(self)
            windowInFront = true
        }
    }
    
    @objc func resizeWindowA(_ window: AXUIElement) {
        var position: CFTypeRef?
        var size: CFTypeRef?
        var p = CGPoint()
        var s = CGSize()
        AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &position)
        AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &size)
        
        guard position != nil,
              size != nil,
              let w = self.window,
              let screen = NSScreen.main else { return }
        AXValueGetValue(position as! AXValue, AXValueType.cgPoint, &p)
        AXValueGetValue(size as! AXValue, AXValueType.cgSize, &s)
        
        var rect = NSRect(origin: p, size: s)
        
        rect.origin.y = screen.frame.height - rect.height - rect.origin.y
        
        updateImageSize(rect)
        
        w.setFrame(rect, display: true)
        

        if !w.isVisible || !w.isOnActiveSpace {
            w.orderFront(self)
            windowInFront = true
        }
    }
    
    func updateImageSize(_ rect: NSRect) {
        guard let vc = window?.contentViewController as? MainViewController,
              let image = vc.currentCGImage else { return }
        vc.imageView.image = NSImage(cgImage: image, size: rect.size)
    }
    
}


