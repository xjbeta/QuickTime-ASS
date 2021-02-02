//
//  MainViewController.swift
//  QuickTime ASS
//
//  Created by xjbeta on 1/18/21.
//

import Cocoa
import Metal
import MetalKit

class MainViewController: NSViewController {
    
    @IBOutlet var mtkView: MTKView!
    @IBOutlet var debugBox: NSBox!
    
    // Metal
    var device: MTLDevice!
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var texture: MTLTexture!
    var vertices: MTLBuffer!
    var numVertices: Int!
    var viewPortSize = vector_uint2.zero
    
    
    var libass: Libass? = nil
//    var currentCGImage: CGImage? = nil
//
//    let player = QTPlayer.shared
//
//    let timer = DispatchSource.makeTimerSource(flags: [], queue: .main)
//    var timerIsRunning = false
//
//    var lastRequestTime: Int64 = -1
//
//
//    var mainWC: MainWindowController? {
//        get {
//            return view.window?.windowController as? MainWindowController
//        }
//    }
//
//    let date = Date()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        libass = Libass(size: mtkView.drawableSize)
        libass?.setFile("/Users/xjbeta/Downloads/test files/Shelter.ass")
    
        
        mtkView.delegate = self
        mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        
        device = MTLCreateSystemDefaultDevice()
        mtkView.device = device
        
        let t = loadTexttures(12500)[1]
        texture = t.texture


        let quadVertices = t.vertexs
        
        numVertices = quadVertices.count
        
        vertices = device.makeBuffer(
            bytes: quadVertices,
            length: MemoryLayout<ASSVertex>.stride * numVertices,
            options: .storageModeShared)
        
        let defaultLibrary = self.device.makeDefaultLibrary()
        let vertexFunction = defaultLibrary?.makeFunction(name: "vertexShader")
        let fragmentFunction = defaultLibrary?.makeFunction(name: "samplingShader")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        
//        pipelineStateDescriptor.colorAttachments[0].alpha
        
        
        pipelineStateDescriptor.label = "Texturing Pipeline"
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        
        // remove black transparent
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .destinationAlpha
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .destinationAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusBlendAlpha
        
        
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch let error {
            print(error)
        }
    
        commandQueue = device.makeCommandQueue()
        
        
//        mtkView.isPaused = true
//        mtkView.enableSetNeedsDisplay = true
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
//    func suspendTimer(_ suspend: Bool = true) {
//        if suspend {
//            if timerIsRunning {
//                timer.suspend()
//                timerIsRunning = false
//            }
//        } else {
//            if !timerIsRunning {
//                timer.resume()
//                timerIsRunning = true
//            }
//        }
//    }

//    func initTimer() {
//        timer.schedule(deadline: .now(), repeating: .milliseconds(100))
//        timer.setEventHandler {
//            self.updateSubtitle()
//        }
//
//        guard let wc = mainWC else { return }
//        wc.updateTimerState()
//        updateSubtitle()
//    }
    
    func loadTexttures(_ ms: Int64) -> [(vertexs: [ASSVertex],
                                         texture: MTLTexture)] {
        guard let images = libass?.generateImage(ms) else { return [] }
        
        return images.enumerated().compactMap { e -> (vertexs: [ASSVertex],
                                                      texture: MTLTexture)? in
            let i = e.element
            if let t = texture(i, e.offset) {
                let v = computeVertexs(i.origin, i.size)
                return (v, t)
            } else {
                return nil
            }
        }
    }
    
    func computeVertexs(_ origin: NSPoint, _ size: NSSize) -> [ASSVertex] {
        
        let dSize = mtkView.drawableSize
        
        func formatter(_ x: CGFloat, _ y: CGFloat) -> (Float, Float) {
            return (.init(x - dSize.width / 2),
                    .init(dSize.height / 2 - y))
        }
        
        let topLeft = ASSVertex(
            formatter(origin.x, origin.y),
            (0.0, 0.0))
        
        let topRight = ASSVertex(
            formatter(origin.x + size.width, origin.y),
            (1.0, 0.0))
        
        let bottomLeft = ASSVertex(
            formatter(origin.x, origin.y + size.height),
            (0.0, 1.0))
        let bottomRight = ASSVertex(
            formatter(origin.x + size.width, origin.y + size.height),
            (1.0, 1.0))
        
        return [
            bottomRight,
            bottomLeft,
            topLeft,
            
            bottomRight,
            topLeft,
            topRight]
    }
    
    
    
    
//    func updateSubtitle() {
//        guard let wc = mainWC,
//              let cTime = wc.targePlayerWindow?.document?.currentTime,
//              let size = wc.targePlayerWindow?.bounds?.size else { return }
//
//        let time = Int64(cTime * 1000)
//        guard lastRequestTime != time else { return }
//
//        lastRequestTime = time
//
//        let images = libass?.generateImage(time) ?? []
//
//        let textures = images.map {
//            texture($0)
//        }
//
//
//        print(textures)
//
//        guard textures.count == 4, let t = textures[1] else { return }
//
//
//
//
//
//
//
////        var vertices = [
////            Vertex(position: .init(x: 0, y: 0), textCoord: .init(x: 0, y: 0)),
////            Vertex(position: .init(x: Float(t.width), y: 0), textCoord: .init(x: 1, y: 0)),
////
////            Vertex(position: .init(x: 0, y: Float(t.height)), textCoord: .init(x: 0, y: 1)),
////            Vertex(position: .init(x: Float(t.width), y: Float(t.height)), textCoord: .init(x: 1, y: 1)),
////        ]
//
////        size.quadVertices
//
////        device.makeBuffer(bytes: vertices,
////                          length: MemoryLayout<Vertex>.stride * vertices.count,
////                          options: .storageModeShared)
//
//
//
//    }
    
    
    func texture(_ image: ASSImageObject, _ index: Int) -> MTLTexture? {

        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .bgra8Unorm
        
        textureDescriptor.width = image.image.width
        textureDescriptor.height = image.image.height
        let texture = device.makeTexture(descriptor: textureDescriptor)
        texture?.label = "ASS Image \(index)"
        
        let bytesPerRow = image.image.bytesPerRow

        let region = MTLRegion(
            origin: MTLOrigin(x: 0, y: 0, z: 0),
            size: MTLSize(width: image.image.width,
                          height: image.image.height,
                          depth: 1))

        texture?.replace(region: region,
                         mipmapLevel: 0,
                         withBytes: image.buffer,
                         bytesPerRow: bytesPerRow)
        return texture
    }
    
}

extension MainViewController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewPortSize.x = UInt32(size.width)
        viewPortSize.y = UInt32(size.height)
    }
    
    func draw(in view: MTKView) {
        
//        12/1000
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        
        guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor),
              let drawable = view.currentDrawable else {
            return
        }
        
        commandEncoder.label = "ASS encoder"
        commandEncoder.setViewport(
            MTLViewport(originX: 0.0,
                        originY: 0.0,
                        width: Double(viewPortSize.x),
                        height: Double(viewPortSize.y),
                        znear: -1.0,
                        zfar: 1.0))
        commandEncoder.setRenderPipelineState(pipelineState)
        commandEncoder.setVertexBuffer(vertices, offset: 0, index: ASSVertexInputIndex.Vertices.rawValue)
        commandEncoder.setVertexBytes(&viewPortSize, length: MemoryLayout<vector_uint2>.stride, index: ASSVertexInputIndex.ViewporSize.rawValue)
        
        commandEncoder.setFragmentTexture(texture, index: ASSTextureIndex.BaseColor.rawValue)
        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: numVertices)
        
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
