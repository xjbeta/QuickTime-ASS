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
    
    let player = (NSApp.delegate as! AppDelegate).qtPlayer
    var document: QuickTimePlayerDocument? = nil
    
    let timer = DispatchSource.makeTimerSource(flags: [], queue: .main)
    
    var lastRequestTime: Int64 = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.isHidden = true
        
        imageView.backgroundColor = .clear
        imageView.setImage(nil, imageProperties: nil)
        
        NotificationCenter.default.addObserver(forName: .loadNewSubtilte, object: nil, queue: .main) {
            guard let info = $0.userInfo as? [String: String],
                  let url = info["url"],
                  let title = info["title"],
                  let wc = self.view.window?.windowController as? MainWindowController else { return }
            
            wc.targeTitle = title
            wc.resizeWindow()
            self.libass.setFile(url)
            self.startTimer()
        }
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func startTimer() {
        timer.schedule(deadline: .now(), repeating: .milliseconds(250))
        timer.setEventHandler {
            guard let cTime = self.document?.currentTime else { return }
            let time = Int64(cTime * 1000)
            guard self.lastRequestTime != time else { return }
            
            self.lastRequestTime = time
            guard let image = self.libass.generateImage(time) else { return }
            self.imageView.setImage(image, imageProperties: nil)
            self.imageView.isHidden = false
        }
        timer.resume()
    }
}

