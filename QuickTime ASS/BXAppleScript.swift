//
//  BXAppleScript.swift
//
//  Created by peter on 30.05.20.
//  Copyright © 2020 Peter Baumgartner. All rights reserved.
//
import Foundation
import AppKit
import Carbon


//----------------------------------------------------------------------------------------------------------------------
    
    
// Find details at documentation://Architecture.pdf to get the big picture

//----------------------------------------------------------------------------------------------------------------------
    
    
public class BXAppleScript
{
    private var script:NSUserAppleScriptTask
    
    public enum Error : Swift.Error
    {
        case missingScript
        case incorrectDirectory
    }
    
    
//----------------------------------------------------------------------------------------------------------------------
    
    
    // MARK: -
    
    public class func scriptsDirectoryURL() throws -> URL
    {
        var scriptsDirectoryURL = try FileManager.default.url(for:.applicationScriptsDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
        
        if !scriptsDirectoryURL.path.hasSuffix(".Extension")
        {
            scriptsDirectoryURL = scriptsDirectoryURL.appendingPathExtension("Extension")
            
            if !FileManager.default.fileExists(atPath:scriptsDirectoryURL.path)
            {
                try FileManager.default.createDirectory(at:scriptsDirectoryURL, withIntermediateDirectories:true, attributes:nil)
            }
        }
        
        return scriptsDirectoryURL
    }
    
    
    public class func needsInstalling(for name:String) -> Bool
    {
        if let directoryURL = try? scriptsDirectoryURL()
        {
            let scriptURL = directoryURL.appendingPathComponent(name).appendingPathExtension("scpt")
            return !FileManager.default.fileExists(atPath:scriptURL.path)
        }
        
        return true
    }
    
    
    public class func installScript(named name:String) throws
    {
        guard let srcURL = Bundle.main.url(forResource:name, withExtension:"scpt") else { throw Error.missingScript }

        let directoryURL = try self.scriptsDirectoryURL()
        
        let panel = NSOpenPanel()
        panel.directoryURL = directoryURL
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.prompt = "Select Script Folder"
        panel.message = "Please select the User > Library > Application Scripts > com.boinx.XCDocumentation.Extension folder"
        
        let button = panel.runModal()
        
        if button == .OK
        {
            if let selectedURL = panel.url, selectedURL == directoryURL
            {
                let dstURL = directoryURL.appendingPathComponent(name).appendingPathExtension("scpt")
                try? FileManager.default.removeItem(at:dstURL)
                try FileManager.default.copyItem(at:srcURL, to:dstURL)
            }
            else
            {
                throw Error.incorrectDirectory
            }
        }
    }
    

//----------------------------------------------------------------------------------------------------------------------
    
    
    // MARK: -
    
    public init(named name:String) throws
    {
        let scriptsDirectoryURL = try FileManager.default.url(for:.applicationScriptsDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
        let scriptURL = scriptsDirectoryURL.appendingPathComponent(name).appendingPathExtension("scpt")
        self.script = try NSUserAppleScriptTask(url:scriptURL)
    }
    
    
//----------------------------------------------------------------------------------------------------------------------
    
    
    public func run(function functionName:String? = nil, argument:String? = nil, completionHandler:@escaping (String?,Swift.Error?)->Void)
    {
        var functionDesc:NSAppleEventDescriptor? = nil
        
        if let functionName = functionName
        {
            var psn = ProcessSerialNumber(highLongOfPSN:0, lowLongOfPSN:UInt32(kCurrentProcess))
            
            let target = NSAppleEventDescriptor(
                descriptorType: typeProcessSerialNumber,
                bytes: &psn,
                length: MemoryLayout<ProcessSerialNumber>.size)

            functionDesc = NSAppleEventDescriptor(
                eventClass: UInt32(kASAppleScriptSuite),
                eventID: UInt32(kASSubroutineEvent),
                targetDescriptor: target,
                returnID: Int16(kAutoGenerateReturnID),
                transactionID: Int32(kAnyTransactionID))

            let function = NSAppleEventDescriptor(string:functionName)
            
            functionDesc?.setParam(function, forKeyword:AEKeyword(keyASSubroutineName))

            if let argument = argument
            {
                let arg1 = NSAppleEventDescriptor(string:argument)
                let args = NSAppleEventDescriptor.list()
                args.insert(arg1, at:1) // Index starts at 1!
                functionDesc?.setParam(args, forKeyword:AEKeyword(keyDirectObject))
            }
        }

        self.script.execute(withAppleEvent:functionDesc)
        {
            result,error in

            if let error = error
            {
                NSLog("Script error: \(error)")
                completionHandler(nil,error)
            }
            else if let stringResult = result?.stringValue
            {
                completionHandler(stringResult,nil)
            }
            else
            {
                NSLog("got nil result")
                completionHandler(nil,nil)
            }
        }
    }
}
