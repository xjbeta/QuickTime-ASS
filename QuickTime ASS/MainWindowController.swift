//
//  MainWindowController.swift
//  QuickTime ASS
//
//  Created by xjbeta on 1/19/21.
//

import Cocoa

class MainWindowController: NSWindowController {

    var targeTitle = ""
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.level = .floating
        window?.backgroundColor = .clear
        window?.isOpaque = false
        window?.ignoresMouseEvents = true
        window?.orderOut(self)
        
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(foremostAppActivated), name: NSWorkspace.didActivateApplicationNotification, object: nil)
        
        NotificationCenter.default.addObserver(forName: .resizeWindow, object: nil, queue: .main) { _ in
            self.resizeWindow()
        }
        
        acquirePrivileges {
            print("Accessibility enabled: \($0)")
        }
    }
    
    @objc func foremostAppActivated(_ notification: NSNotification) {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let appDelegate = NSApp.delegate as? AppDelegate,
              app.bundleIdentifier == appDelegate.quickTimeIdentifier else {
                if let window = window, window.isVisible {
                    window.orderOut(self)
                    print("hide subtitle window")
                }
                return
        }
        
        print("AXIsProcessTrusted  \(AXIsProcessTrusted())")
        guard AXIsProcessTrusted() else {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = "No accessibility API permission."
            alert.informativeText = "Check enableDanmaku check in preferences."
            alert.addButton(withTitle: "OK")
            let response = alert.runModal()
//            if response == .alertFirstButtonReturn {
//                Preferences.shared.enableDanmaku = false
//            }
            return
        }
        
        setObserver(app.processIdentifier)
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

            let str = String(notification)
            switch str {
            case kAXMovedNotification, kAXResizedNotification:
                guard let ref = refcon else { return }
                let wc = Unmanaged<MainWindowController>.fromOpaque(ref).takeUnretainedValue()
                wc.resizeWindow()
            case kAXValueChangedNotification:
                var value: CFTypeRef?
                AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)
                guard value != nil,
                      let n = value as? NSNumber else { return }
                let isPlaying = n.intValue == 1
                print(isPlaying)
                
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
        
    
        
        
        CFRunLoopAddSource(
            CFRunLoopGetCurrent(),
            AXObserverGetRunLoopSource(obs),
            CFRunLoopMode.commonModes)
    }
    
    func resizeWindow() {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else { return }
        
        let app = AXUIElementCreateApplication(pid)
        var children: CFTypeRef?
        AXUIElementCopyAttributeValue(app, kAXChildrenAttribute as CFString, &children)
        
        guard let windows = children as? [AXUIElement] else { return }
        
        let targeWindows = windows.filter { element in
            var title: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &title)
            
            if let t = title as? String, t == targeTitle {
                return true
            }
            return false
        }
        
        guard let targeWindow = targeWindows.first else { return }
        
        var position: CFTypeRef?
        var size: CFTypeRef?
        var p = CGPoint()
        var s = CGSize()
        AXUIElementCopyAttributeValue(targeWindow, kAXPositionAttribute as CFString, &position)
        AXUIElementCopyAttributeValue(targeWindow, kAXSizeAttribute as CFString, &size)

        guard position != nil, size != nil else { return }
        AXValueGetValue(position as! AXValue, AXValueType.cgPoint, &p)
        AXValueGetValue(size as! AXValue, AXValueType.cgSize, &s)
        
        var rect = NSRect(origin: p, size: s)
        
        rect.origin.y = (NSScreen.main?.frame.size.height)! - rect.size.height - rect.origin.y
        guard let window = window else { return }
        window.setFrame(rect, display: true)
        if !window.isVisible {
            window.orderFront(self)
            print("show subtitle window")
        }
    }
    
}


