//
//  MainViewController.swift
//  QuickTime ASS
//
//  Created by xjbeta on 1/18/21.
//

import Cocoa
import Quartz

class MainViewController: NSViewController {
    
    @IBOutlet var imageView: IKImageView!
    
    let libass = Libass(size: CGSize(width: 1920, height: 1080))
    
    let player = QuickTimePlayer()
    
    let timer = DispatchSource.makeTimerSource(flags: [], queue: .main)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            self.player.currentTime().done(on: .main) {
                if let image = self.libass.generateImage(Int64($0)) {
                    self.imageView.setImage(image, imageProperties: nil)
                }
            }.catch {
                print($0)
            }
        }
        timer.resume()
    }
}

