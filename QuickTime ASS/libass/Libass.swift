//
//  Libass.swift
//  Eriri
//
//  Created by xjbeta on 2020/11/4.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa
import CoreGraphics

class Libass: NSObject {
    let assLibrary: OpaquePointer
    let assRenderer: OpaquePointer
    var track: UnsafeMutablePointer<ASS_Track>?
    var size: CGSize
    
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
    
    func setSize(_ size: CGSize) {
        ass_set_frame_size(assRenderer, Int32(size.width), Int32(size.height))
        ass_set_storage_size(assRenderer, Int32(size.width), Int32(size.height))
        self.size = size
    }
    
    func setFontDir(_ path: String) {
        ass_set_fonts_dir(assLibrary, path.cString())
        
    }
    
    func setStyleOverrides() {
        ass_set_style_overrides(assLibrary, nil)
    }
    
    func processForceStyle() {
        ass_process_force_style(track)
    }
    
    func setFontScale(_ scale: Double) {
        ass_set_font_scale(assRenderer, scale)
    }
    
    
    func generateImage(_ millisecond: Int64) -> image_t? {
        guard let t = track else { return nil }
        var changed: Int32 = 1
        let image = ass_render_frame(assRenderer, t, millisecond, &changed)
        
        guard changed == 2 else { return nil }
        
        let date = Date()
        let re = blendBitmapData(image, Int32(size.width), Int32(size.height))
        print(date.timeIntervalSinceNow)
        
        return re
    }
    
    
    func initCGImage(_ data: UnsafeRawPointer, width: Int, height: Int) -> CGImage? {
        let colorSpaceRef = CGColorSpaceCreateDeviceRGB()

        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bitsPerPixel = bytesPerPixel * bitsPerComponent
        let bytesPerRow = bytesPerPixel * width
        let totalBytes = height * bytesPerRow

        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)

        guard let providerRef = CGDataProvider(dataInfo: nil, data: data, size: totalBytes, releaseData: {_,_,_ in}),
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
                                     intent: .defaultIntent) else {
            return nil
        }
        
        return imageRef
    }
    
    
    deinit {
        ass_library_done(assLibrary)
        ass_renderer_done(assRenderer)
    }
}
