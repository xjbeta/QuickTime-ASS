//
//  MainViewController.swift
//  QuickTime ASS
//
//  Created by xjbeta on 1/18/21.
//

import Cocoa
import Quartz

class MainViewController: NSViewController {
    
    @IBOutlet var imageView: NSImageView!
    @IBOutlet var debugBox: NSBox!
    
    var libass: Libass? = nil
    
    let player = QTPlayer.shared
    var playerWindow: QuickTimePlayerWindow? = nil
    
    let timer = DispatchSource.makeTimerSource(flags: [], queue: .main)
    var timerIsRunning = false
    
    var lastRequestTime: Int64 = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.isHidden = true

        let nCenter = NotificationCenter.default
        
        nCenter.addObserver(forName: .loadNewSubtilte, object: nil, queue: .main) {
            guard let info = $0.userInfo as? [String: String],
                  let url = info["url"],
                  let wc = self.view.window?.windowController as? MainWindowController,
                  let tWindow = self.player.targeWindow() else {
                print("load subtitle failed, not found url info or targe window.")
                return
            }
            
            self.playerWindow = tWindow
            
            guard var size = self.playerWindow?.bounds?.size,
                  let scale = NSScreen.main?.backingScaleFactor else {
                print("load subtitle failed, not player info window or screen scale.")
                return
            }
            
            size.width *= scale
            size.height *= scale
            
            self.libass = Libass(size: size)
            
            wc.resizeWindow()
            self.libass?.setFile(url)
            self.initTimer()
        }
        
        nCenter.addObserver(forName: .updatePlayState, object: nil, queue: .main) { _ in
            self.updateTimerState()
        }
        
        nCenter.addObserver(forName: .updateTargeWindowState, object: nil, queue: .main) { _ in
            self.updateTimerState()
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func updateTimerState() {
        guard let isPlaying = playerWindow?.document?.playing,
              let wc = view.window?.windowController as? MainWindowController else { return }
        let windowInFront = wc.windowInFront
        
        print("isPlaying \(isPlaying)", "windowInFront \(windowInFront)")
        
        
        if !isPlaying || !windowInFront {
            suspendTimer()
        } else {
            suspendTimer(false)
        }
    }
    
    func suspendTimer(_ suspend: Bool = true) {
        if suspend {
            if timerIsRunning {
                timer.suspend()
                timerIsRunning = false
            }
        } else {
            if !timerIsRunning {
                timer.resume()
                timerIsRunning = true
            }
        }
    }

    func initTimer() {
        timer.schedule(deadline: .now(), repeating: .milliseconds(100))
        timer.setEventHandler {
            self.updateSubtitle()
        }
        timer.resume()
        timerIsRunning = true
        updateTimerState()
    }
    
    func updateSubtitle() {
        guard let cTime = playerWindow?.document?.currentTime else { return }
        
        let time = Int64(cTime * 1000)
        guard lastRequestTime != time else { return }
        
        lastRequestTime = time
        guard let image = libass?.generateImage(time) else { return }
        
        guard let size = playerWindow?.bounds?.size else { return }
        
        imageView.image = NSImage(cgImage: image, size: size)
    }
}

