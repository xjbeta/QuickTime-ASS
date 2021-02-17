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
    
    var targePlayerWindow: QuickTimePlayerWindow?
    var targeWindowTitle: String?
    var targeProcessIdentifier: pid_t?
    
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
        
        NotificationCenter.default.addObserver(forName: .loadNewSubtilte, object: nil, queue: .main) {
            guard let uInfo = $0.userInfo as? [String: Any],
                  let url = uInfo["url"] as? String,
                  let info = uInfo["info"] as? QTPlayer.FrontmostAppInfo,
                  let targeWindow = QTPlayer.shared.app.windows?().first(where: {
                    $0.document?.file?.lastPathComponent == info.windowTitle
                }) else {
                print("load subtitle failed, not found url info or targe window.")
                return
            }
            
            self.targeWindowTitle = info.windowTitle
            self.targeProcessIdentifier = info.processIdentifier
            self.targePlayerWindow = targeWindow
            self.resizeWindow()
            self.setObserver(info.processIdentifier)
            
            guard let vc = self.mainVC else {
                print("load subtitle failed, not player info window or screen scale.")
                return
            }
            
            let size = vc.mtkView.drawableSize
            vc.libass = Libass(size: size)
            vc.mtkView.isPaused = true
            vc.libass?.setFile(url)
        }
    }
    
    @objc func updateWindowState(_ notification: NSNotification) {
        
        guard let app = notification.userInfo?["NSWorkspaceApplicationKey"] as? NSRunningApplication,
              let w = self.window else {
            return
        }
        
        if app.bundleIdentifier == Bundle.main.bundleIdentifier {
            return
        }
        
        if app.bundleIdentifier == QTPlayer.shared.quickTimeIdentifier {
            resizeWindow()
        } else {
            if w.isVisible {
                w.orderOut(self)
                windowInFront = false
            }
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
                try $0.attribute(.title) == targeWindowTitle
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
              let pWindow = targePlayerWindow,
              var rect = pWindow.bounds,
              let screen = NSScreen.main else { return }
        
        rect.origin.y = screen.frame.height - rect.height - rect.origin.y
        
        w.setFrame(rect, display: true)
        

        if !w.isVisible || !w.isOnActiveSpace {
            w.orderFront(self)
        }
        windowInFront = true
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
//        guard let vc = mainVC,
//              let image = vc.currentCGImage else { return }
//        vc.imageView.image = NSImage(cgImage: image, size: rect.size)
    }
    
    func updateTimerState() {
        guard let vc = mainVC else { return }
        vc.mtkView.isPaused = !playing || !windowInFront
        print("mtkViewisPaused \(vc.mtkView.isPaused)", "isPlaying \(playing)", "windowInFront \(windowInFront)")
    }
    
}


