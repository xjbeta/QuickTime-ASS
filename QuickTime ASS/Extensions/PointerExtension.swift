//
//  UnsafePointerExtension.swift
//  Eriri
//
//  Created by xjbeta on 2020/2/13.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa

extension UnsafePointer where Pointee == Int8 {
    func toString() -> String {
        return String(cString: self)
    }
}

extension UnsafeMutablePointer where Pointee == Int8 {
    func toString() -> String {
        return String(cString: self)
    }
}

extension String {
    func cString() -> UnsafePointer<Int8>? {
        return NSString(string: self).utf8String
    }
}
