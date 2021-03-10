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
  vector_float3 position;
  vector_float3 right;
  vector_float3 up;
  vector_float3 forward;
};

struct AreaLight {
  vector_float3 position;
  vector_float3 forward;
  vector_float3 right;
  vector_float3 up;
  vector_float3 color;
};

struct Uniforms
{
  unsigned int width;
  unsigned int height;
  unsigned int blocksWide;
  unsigned int frameIndex;
  struct Camera camera;
  struct AreaLight light;
};

#endif /* Metal_h */
