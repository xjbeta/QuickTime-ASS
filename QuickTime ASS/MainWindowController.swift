//
//  MainWindowController.swift
//  QuickTime ASS
//
//  Created by xjbeta on 1/19/21.
//

import Cocoa
import AXSwift

class MainWindowController: NSWindowController {

    let player = QTPlayer.shared
    var targeWindow: QuickTimePlayerWindow?
    
    var mainVC: MainViewController? {
        get {
            return window?.contentViewController as? MainViewController
        }
    }
    
    var windowInFront = false {
        didSet {
            updateTimerState()
        }
    }
    
    var playing = true {
        didSet {
            updateTimerState()
        }
    }
    
    var observer: Observer? = nil
    
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
        guard let app = Application(forProcessID: pid) else { return }
        
        observer = app.createObserver { observer, element, notification in
            do {
                switch notification {
                case .moved, .resized:
                    guard let frame: NSRect? = try element.attribute(.frame),
                          let f = frame else { return }
                    self.resizeWindowAX(f)
                case .valueChanged where try element.attribute(.description) == "play/pause":
                    guard let playing: Bool? = try element.attribute(.value),
                          let p = playing else { return }
                    self.playing = p
                case .valueChanged where try element.attribute(.description) == "timeline":
                    self.mainVC?.updateSubtitle()
                default:
                    break
                }
            } catch let error {
                print(error)
            }
        }
        
        do {
            guard let window = try app.windows()?.first(where: {
                try $0.attribute(.title) == player.targeWindowTitle
            }) else { return }
            try observer?.addNotification(.moved, forElement: window)
            try observer?.addNotification(.resized, forElement: window)
            
            guard let elements: [UIElement] = try window.arrayAttribute(.children) else { return }
            
            try elements.forEach {
                let str: String? = try $0.attribute(.description)
                switch str {
                case "play/pause":
                    try observer?.addNotification(.valueChanged, forElement: $0)
                case "timeline":
                    try observer?.addNotification(.valueChanged, forElement: $0)
                default:
                    break
                }
            }
        } catch let error {
            print(error)
        }
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
    
    func resizeWindowAX(_ rect: NSRect) {
        guard let w = self.window,
              let screen = NSScreen.main else { return }
        
        var r = rect
        r.origin.y = screen.frame.height - r.height - r.origin.y
        
        updateImageSize(r)
        
        w.setFrame(r, display: true)
        

        if !w.isVisible || !w.isOnActiveSpace {
            w.orderFront(self)
            windowInFront = true
        }
    }
    
    func updateImageSize(_ rect: NSRect) {
        guard let vc = mainVC,
              let image = vc.currentCGImage else { return }
        vc.imageView.image = NSImage(cgImage: image, size: rect.size)
    }
    
    func updateTimerState() {
        guard let vc = mainVC else { return }
        print("isPlaying \(playing)", "windowInFront \(windowInFront)")
        
        if !playing || !windowInFront {
            vc.suspendTimer()
        } else {
            vc.suspendTimer(false)
        }
    }
    
}


