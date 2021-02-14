//
//  ASSShaderTypes.swift
//  QuickTime ASS
//
//  Created by xjbeta on 2/1/21.
//

import Foundation
import simd

struct ASSVertex {
    var position: vector_float2
    var textureCoordinate: vector_float2
    
    init(_ position: (Float, Float),
         _ textCoord: (Float, Float)) {
        self.position = .init(x: position.0,
                              y: position.1)
        
        self.textureCoordinate = .init(x: textCoord.0,
                                       y: textCoord.1)
    }
}

enum ASSVertexInputIndex: Int {
    case Vertices = 0
    case ViewporSize = 1
}

enum ASSTextureIndex: Int {
    case BaseColor = 0
}
