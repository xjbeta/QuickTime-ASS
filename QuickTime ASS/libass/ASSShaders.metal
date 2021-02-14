//
//  ASSShaders.metal
//  QuickTime ASS
//
//  Created by xjbeta on 1/27/21.
//

#include <metal_stdlib>
using namespace metal;

typedef struct
{
    float2 position;
    float2 textureCoordinate;
} ASSVertex;

typedef enum AAPLVertexInputIndex
{
    ASSVertexInputIndexVertices     = 0,
    ASSVertexInputIndexViewportSize = 1,
} ASSVertexInputIndex;

typedef enum ASSTextureIndex
{
    ASSTextureIndexBaseColor = 0,
} ASSTextureIndex;


typedef struct
{
    float4 position [[position]];
    float2 textureCoordinate;
} RasterizerData;

// Vertex Function
vertex RasterizerData
vertexShader(uint vertexID [[ vertex_id ]],
             constant ASSVertex *vertexArray [[ buffer(ASSVertexInputIndexVertices) ]],
             constant vector_uint2 *viewportSizePointer  [[ buffer(ASSVertexInputIndexViewportSize) ]])

{

    RasterizerData out;
    
    float2 pixelSpacePosition = vertexArray[vertexID].position.xy;

    float2 viewportSize = float2(*viewportSizePointer);

    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = pixelSpacePosition / (viewportSize / 2.0);

    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;

    return out;
}

// Fragment function
fragment float4
samplingShader(RasterizerData in [[stage_in]],
               texture2d<half> colorTexture [[ texture(ASSTextureIndexBaseColor) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    
    return float4(colorSample);
}

