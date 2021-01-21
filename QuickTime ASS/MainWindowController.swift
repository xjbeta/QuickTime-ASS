//
//  MainWindowController.swift
//  QuickTime ASS
//
//  Created by xjbeta on 1/19/21.
//

import Cocoa

class MainWindowController: NSWindowController {

    let player = (NSApp.delegate as! AppDelegate).qtPlayer
    
    var targeTitle = ""
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.level = .floating
        window?.backgroundColor = .clear
        window?.isOpaque = false
        window?.ignoresMouseEvents = true
        window?.orderOut(self)
        
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(updateWindowState), name: NSWorkspace.didActivateApplicationNotification, object: nil)
        
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(updateWindowState), name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
        
        NotificationCenter.default.addObserver(forName: .resizeWindow, object: nil, queue: .main) { _ in
            self.resizeWindow()
        }
        
        acquirePrivileges {
            print("Accessibility enabled: \($0)")
        }
    }
    
    @objc func updateWindowState(_ notification: NSNotification) {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let appDelegate = NSApp.delegate as? AppDelegate,
              app.bundleIdentifier == appDelegate.quickTimeIdentifier else {
                if let window = window, window.isVisible {
                    window.orderOut(self)
                    print("hide subtitle window")
                }
                return
        }
        
        setObserver(app.processIdentifier)
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
        
//        AXObserverAddNotification(
//            obs,
//            windowRef as! AXUIElement,
//            kaxnotification as CFString,
//            s)
        
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
    
    @objc func resizeWindow() {
        guard let w = self.window,
              let windows = player.windows?(),
              let window = windows.first(where: { $0.document?.file?.lastPathComponent == targeTitle }),
              let doc = window.document,
              var rect = window.bounds,
              let screen = NSScreen.main else { return }

        (w.contentViewController as? MainViewController)?.document = doc
        
        rect.origin.y = screen.frame.height - rect.height - rect.origin.y
        
        w.setFrame(rect, display: true)
        

        if !w.isVisible || !w.isOnActiveSpace {
            w.orderFront(self)
            print("show subtitle window")
        }
    }
    
}


