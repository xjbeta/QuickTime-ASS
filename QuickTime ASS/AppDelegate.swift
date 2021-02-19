//
//  AppDelegate.swift
//  QuickTime ASS
//
//  Created by xjbeta on 1/18/21.
//

import Cocoa
import ScriptingBridge
import Sparkle

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    let subtitleFileItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    
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
        
        acquirePrivileges {
            print("Accessibility enabled: \($0)")
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
        
        subtitleFileItem.isHidden = true
        
        menu.addItem(subtitleFileItem)
        menu.addItem(withTitle: "Select Subtitle", action: #selector(selectSubtitle), keyEquivalent: "s")

        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(preferences), keyEquivalent: ","))
        
        menu.addItem(NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdate), keyEquivalent: ""))
        
        let debugItem = NSMenuItem(title: "Debug", action: #selector(debug), keyEquivalent: "")
        let enableDebug = UserDefaults().bool(forKey: Notification.Name.enableDebug.rawValue)
        debugItem.state = enableDebug ? .on : .off
        menu.addItem(debugItem)
        
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
        
        if menuItem.action == #selector(debug(_:)) {
            return true
        }
        
        if menuItem.action == #selector(checkForUpdate) {
            return true
        }
        
        if menuItem.action == #selector(preferences) {
            return true
        }
        
        return false
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        let player = QTPlayer.shared
        let info = player.frontmostAppInfo()
        keyAppName.title = info.name
        keyWindowTitle.title = info.windowTitle
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        acquirePrivileges {
            print("Accessibility enabled: \($0)")
        }
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
        
        setSubtitleName(url.lastPathComponent)
    }
    
    func setSubtitleName(_ str: String) {
        
        let re = str.truncated(limit: 30, position: .middle, leader: "...")
        
        
        subtitleFileItem.title = re
        subtitleFileItem.isHidden = false
    }
    
    @objc func preferences() {
        NotificationCenter.default.post(name: .preferences, object: nil)
    }
    
    @objc func checkForUpdate(_ sender: NSMenuItem) {
        SUUpdater().checkForUpdates(sender)
    }
    
    @objc func debug(_ sender: NSMenuItem) {
        let enableDebug = sender.state == .on
        sender.state = enableDebug ? .off : .on
        UserDefaults().set(!enableDebug, forKey: Notification.Name.enableDebug.rawValue)
        
        NotificationCenter.default.post(name: .enableDebug, object: nil)
    }
    
    func acquirePrivileges(_ block: @escaping (Bool) -> Void) {
        let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        let privOptions = [trusted: true] as CFDictionary
        let accessEnabled = AXIsProcessTrustedWithOptions(privOptions)
        if !accessEnabled {
            let alert = NSAlert()
            alert.messageText = "Enable QuickTimer Player ASS"
            alert.informativeText = "Once you have enabled QuickTimer Player ASS in System Preferences, click OK."

            alert.runModal()
            let t = AXIsProcessTrustedWithOptions(privOptions)
            block(t)
        } else {
            block(true)
        }
    }
    
}

