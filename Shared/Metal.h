//
//  Metal.h
//  Raytraced
//
//  Created by Markus Moenig on 10/3/21.
//

#ifndef Metal_h
#define Metal_h

#include <simd/simd.h>

struct Camera {
    vector_float3   position;
    vector_float3   lookAt;
    float           fov;
    float           focalDist;
    float           aperture;
};

struct Uniforms
{
    unsigned int    width;
    unsigned int    height;
    unsigned int    blocksWide;
    unsigned int    frameIndex;
    
    vector_float3   randomVector;
    
    unsigned int    numberOfLights;
    
    struct Camera   camera;
};

#endif /* Metal_h */
