//
//  MainViewController.swift
//  QuickTime ASS
//
//  Created by xjbeta on 1/18/21.
//

import Cocoa
import Quartz

class MainViewController: NSViewController {
    
    @IBOutlet var debugBox: NSBox!
    @IBOutlet var imageView: IKImageView!
    
    let libass = Libass(size: CGSize(width: 1920, height: 1080))
    
    let player = QTPlayer.shared
    var playerWindow: QuickTimePlayerWindow? = nil
    
    let timer = DispatchSource.makeTimerSource(flags: [], queue: .main)
    var timerIsRunning = false
    
    var lastRequestTime: Int64 = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.isHidden = true
        
        imageView.backgroundColor = .clear
        imageView.setImage(nil, imageProperties: nil)
        
        let nCenter = NotificationCenter.default
        
        nCenter.addObserver(forName: .loadNewSubtilte, object: nil, queue: .main) {
            guard let info = $0.userInfo as? [String: String],
                  let url = info["url"],
                  let wc = self.view.window?.windowController as? MainWindowController else { return }
            
            wc.resizeWindow()
            self.libass.setFile(url)
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
            guard let cTime = self.playerWindow?.document?.currentTime else { return }
            
            let time = Int64(cTime * 1000)
            guard self.lastRequestTime != time else { return }
            
            self.lastRequestTime = time
            guard let image = self.libass.generateImage(time) else { return }
            self.imageView.setImage(image, imageProperties: nil)
            self.imageView.isHidden = false
        }
        timer.resume()
        timerIsRunning = true
        updateTimerState()
    }
}

