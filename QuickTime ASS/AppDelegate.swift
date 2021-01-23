//
//  AppDelegate.swift
//  QuickTime ASS
//
//  Created by xjbeta on 1/18/21.
//

import Cocoa
import ScriptingBridge

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    let keyAppName = NSMenuItem()
    let keyWindowTitle = NSMenuItem()
    
    lazy var selectSubtitlePanel: NSOpenPanel = {
        let p = NSOpenPanel()
        p.canChooseDirectories = false
        p.canChooseFiles = true
        p.allowsMultipleSelection = false
        p.allowedFileTypes = ["utf", "utf8", "utf-8", "idx", "sub", "srt", "smi", "rt", "ssa", "aqt", "jss", "js", "ass", "mks", "vtt", "sup", "scc"]
        return p
    }()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        initMainMenu()
        
        if let button = statusItem.button {
            let image = NSImage(named:NSImage.Name("StatusBarImage"))
            image?.size = .init(width: 22, height: 22)
            button.image = image
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func initMainMenu() {
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(keyAppName)
        menu.addItem(keyWindowTitle)
        menu.addItem(.separator())
        
        menu.addItem(withTitle: "Select Subtitle", action: #selector(selectSubtitle), keyEquivalent: "s")
        

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    

}

extension AppDelegate: NSMenuDelegate, NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        let player = QTPlayer.shared
        let info = player.frontmostAppInfo()
        if menuItem.action == #selector(selectSubtitle) {
            return info.bundleIdentifier == player.quickTimeIdentifier
        }
        
        
        return false
        
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        let player = QTPlayer.shared
        let info = player.frontmostAppInfo()
        keyAppName.title = info.name
        keyWindowTitle.title = info.windowTitle
    }
    
    @objc func selectSubtitle() {
        let player = QTPlayer.shared
        let info = player.frontmostAppInfo()
        let re = selectSubtitlePanel.runModal()
        guard re == .OK,
              let url = selectSubtitlePanel.url else { return }

        NotificationCenter.default.post(
            name: .loadNewSubtilte,
            object: nil,
            userInfo: ["url": url.path, "info": info])
    }
    
}
