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
    var currentCGImage: CGImage? = nil
    
    let player = QTPlayer.shared
    
    let timer = DispatchSource.makeTimerSource(flags: [], queue: .main)
    var timerIsRunning = false
    
    var lastRequestTime: Int64 = -1
    
    var mainWC: MainWindowController? {
        get {
            return view.window?.windowController as? MainWindowController
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.isHidden = true
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
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
        
        guard let wc = mainWC else { return }
        wc.updateTimerState()
    }
    
    func updateSubtitle() {
        guard let wc = mainWC,
              let cTime = wc.targePlayerWindow?.document?.currentTime,
              let size = wc.targePlayerWindow?.bounds?.size else { return }
        
        let time = Int64(cTime * 1000)
        guard lastRequestTime != time else { return }
        
        lastRequestTime = time
        guard let image = libass?.generateImage(time) else { return }
        currentCGImage = image
        
        imageView.image = NSImage(cgImage: image, size: size)
        imageView.isHidden = false
    }
}

