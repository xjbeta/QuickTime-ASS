//
//  QuickTimePlayer.swift
//  QuickTime ASS
//
//  Created by xjbeta on 1/18/21.
//

import Cocoa
import PromiseKit

class QuickTimePlayer: NSObject {
    
    enum RunScriptError: Error {
        case noResult
    }
    
    func runScript(_ name: String) -> Promise<String> {
        return Promise { resolver in
            do {
                let script = try BXAppleScript(named: name)
                script.run { (s, e) in
                    if let error = e {
                        resolver.reject(error)
                    }
                    
                    if let ss = s {
                        resolver.fulfill(ss)
                    } else {
                        resolver.reject(RunScriptError.noResult)
                    }
                }
            } catch let error {
                resolver.reject(error)
            }
        }
    }
    
    // MS
    func currentTime() -> Promise<Double> {
        return runScript("CurrentTime").map { s -> Double in
            if let d = Double(s) {
                return d * 1000
            } else {
                return -1
            }
        }
    }

    // can't work
    func resolution() -> Promise<NSSize> {
        return runScript("Resolution").map { s -> NSSize in
            guard s.first == "{", s.last == "}" else {
                return .zero
            }
            var ss = s.dropLast()
            ss = ss.dropFirst()
            let wh = ss.components(separatedBy: ", ").compactMap(Int.init)
            guard wh.count == 2 else {
                return .zero
            }
            return NSSize(width: wh[0], height: wh[1])
        }
    }
    
    func playing() -> Promise<Bool> {
        return runScript("Playing").map {
            $0 == "true"
        }
    }
    
}
