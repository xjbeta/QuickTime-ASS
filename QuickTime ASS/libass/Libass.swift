//
//  Libass.swift
//  Eriri
//
//  Created by xjbeta on 2020/11/4.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa
import CoreGraphics
//import SwiftImage

class Libass: NSObject {
    let assLibrary: OpaquePointer
    let assRenderer: OpaquePointer
    var track: UnsafeMutablePointer<ASS_Track>?
    let size: CGSize
    
    init(size: CGSize) {
        assLibrary = ass_library_init()
        // NOTE: font lookup must be configured before an ASS_Renderer can be used.
//        let path = "/Users/xjbeta/Downloads/test files/[VCB-S&诸神]_Fonts/"
//        ass_set_fonts_dir(assLibrary, path.cString())
        assRenderer = ass_renderer_init(assLibrary)
        self.size = size
        super.init()
        ass_set_frame_size(assRenderer, Int32(size.width), Int32(size.height))
        ass_set_storage_size(assRenderer, Int32(size.width), Int32(size.height))
        
        ass_set_fonts(assRenderer, nil, "sans-serif".cString(), Int32(ASS_FONTPROVIDER_AUTODETECT.rawValue), nil, 1)
        
        ass_set_message_cb(assLibrary, { (level, fmt, va, data) in
            print("libass level \(level): ")
            vprintf(fmt, va!)
            print("\n")
        }, nil)
        
    }
    
    func version() -> String {
        return "\(ass_library_version())"
    }
    
    
    func setFile(_ path: String) {
        track = ass_read_file(assLibrary,
                              UnsafeMutablePointer<Int8>(mutating: path.cString()),
                              nil)
    }
    
    func setFontDir(_ path: String) {
        ass_set_fonts_dir(assLibrary, path.cString())
        
    }
    
    func setStyleOverrides() {
        ass_set_style_overrides(assLibrary, nil)
    }
    
    func generateImage(_ millisecond: Int64) -> CGImage? {
        guard let t = track else { return nil }
        
        var changed: Int32 = 1
        let image = ass_render_frame(assRenderer, t, millisecond, &changed)
        
        guard changed == 2 else { return nil }
        
        let img = blendBitmapData(image, Int32(size.width), Int32(size.height))
        
        let width = Int(img.width)
        let height = Int(img.height)
        
        guard let imageDataPointer = img.buffer else {
            return nil
        }
        
        let colorSpaceRef = CGColorSpaceCreateDeviceRGB()
        
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bitsPerPixel = bytesPerPixel * bitsPerComponent
        let bytesPerRow = bytesPerPixel * width
        let totalBytes = height * bytesPerRow
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue)
        
        
        guard let providerRef = CGDataProvider(dataInfo: nil, data: imageDataPointer, size: totalBytes, releaseData: {_,_,_ in}) else {
            return nil
        }
        
        let imageRef = CGImage(width: width,
                               height: height,
                               bitsPerComponent: bitsPerComponent,
                               bitsPerPixel: bitsPerPixel,
                               bytesPerRow: bytesPerRow,
                               space: colorSpaceRef,
                               bitmapInfo: bitmapInfo,
                               provider: providerRef,
                               decode: nil,
                               shouldInterpolate: false,
                               intent: .defaultIntent)
        return imageRef
    }
    
    
    
    deinit {
        ass_library_done(assLibrary)
        ass_renderer_done(assRenderer)
    }
}
