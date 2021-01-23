//
//  QTPlayer.swift
//  QuickTime ASS
//
//  Created by xjbeta on 1/22/21.
//

import Foundation
import Cocoa
import ScriptingBridge
import AXSwift

class QTPlayer: NSObject {
    
    static let shared = QTPlayer()
    
    override init() {
        super.init()
    }
    
    let quickTimeIdentifier = "com.apple.QuickTimePlayerX"
    
    let app: QuickTimePlayerApplication = SBApplication(bundleIdentifier: "com.apple.QuickTimePlayerX")!
    
    struct FrontmostAppInfo {
        var isQTPlayer = false
        
        var processIdentifier: pid_t = -1
        var name = "unknown"
        var windowTitle = "unknown"
        var bundleIdentifier = "unknown"
    }
    
    func frontmostAppInfo() -> FrontmostAppInfo {
        var info = FrontmostAppInfo()
        let def = info.name
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return info
        }
        info.processIdentifier = app.processIdentifier
        info.bundleIdentifier = app.bundleIdentifier ?? def
        info.isQTPlayer = info.bundleIdentifier == quickTimeIdentifier
        info.name = app.localizedName ?? def
        
        var title = def
        
        do {
            let a = Application(forProcessID: app.processIdentifier)
            let window: UIElement? = try a?.attribute(.focusedWindow)
            let t: String? = try window?.attribute(.title)
            title = t ?? def
        } catch let error {
            print(error)
        }
        
        info.windowTitle = title
        
        return info
    }
}
