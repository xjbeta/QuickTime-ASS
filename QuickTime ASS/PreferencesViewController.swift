//
//  PreferencesViewController.swift
//  QuickTime ASS
//
//  Created by xjbeta on 2/15/21.
//

import Cocoa

class PreferencesViewController: NSViewController {
    
    var mainVC: MainViewController? {
        get {
            let wc = view.window?.windowController as? MainWindowController
            return wc?.mainVC
        }
    }
    
    @IBOutlet var dailySlider: NSSlider!
    @IBOutlet var dailyTextField: NSTextField!
    
    @IBOutlet var scaleSlider: NSSlider!
    @IBOutlet var scaleTextField: NSTextField!
    
    @IBOutlet var positionSlider: NSSlider!
    @IBOutlet var positionTextField: NSTextField!
    
    @IBAction func sliderAction(_ sender: NSSlider) {
        guard let vc = mainVC else { return }
        switch sender {
        case dailySlider:
            let v = sender.doubleValue / 2
            dailyTextField.stringValue = "\(v >= 0 ? "+" : "")\(v)s"
            
            vc.subtitleDaily = Int64(v * 1000)
        case scaleSlider:
            var v = sender.doubleValue
            if v > 1 {
                v *= 2
            }
            
            let s = String(format: "%.2f", v)
            scaleTextField.stringValue = "\(s)x"
        case positionSlider:
            let v = sender.integerValue
            positionTextField.stringValue = "\(v)"
            
            vc.position = v
        default:
            break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        
        
        
    }
    
}
