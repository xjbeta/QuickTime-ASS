//
//  QTPlayer.swift
//  QuickTime ASS
//
//  Created by xjbeta on 1/22/21.
//

import Foundation
import Cocoa
import ScriptingBridge

class QTPlayer: NSObject {
    
    static let shared = QTPlayer()
    
    override init() {
        super.init()
    }
    
    let quickTimeIdentifier = "com.apple.QuickTimePlayerX"
    
    let app: QuickTimePlayerApplication = SBApplication(bundleIdentifier: "com.apple.QuickTimePlayerX")!
    
    var targeWindowTitle: String?
    
    struct FrontmostAppInfo {
        var isQTPlayer = false
        var isTargeWindow = false
        
        var processIdentifier: pid_t = -1
        var name = "unknown"
        var windowTitle = "unknown"
        var bundleIdentifier = "unknown"
    }
    
    func targeWindow() -> QuickTimePlayerWindow? {
        guard let windows = app.windows?(),
              let window = windows.first(where: { $0.document?.file?.lastPathComponent == targeWindowTitle }) else {
            return nil
        }
        
        return window
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
        
        var window: CFTypeRef?
        AXUIElementCopyAttributeValue(
            AXUIElementCreateApplication(app.processIdentifier),
            kAXFocusedWindowAttribute as CFString,
            &window)
        
        guard window != nil else {
            return info
        }
        
        var title: CFTypeRef?
        AXUIElementCopyAttributeValue(window as! AXUIElement, kAXTitleAttribute as CFString, &title)
        
        info.windowTitle = title as? String ?? def
        info.isTargeWindow = info.windowTitle == targeWindowTitle
        
        return info
    }
}
