//
//  Metal.metal
//  Raytraced
//
//  Created by Markus Moenig on 10/3/21.
//

#include <metal_stdlib>
using namespace metal;

#import "Metal.h"

using namespace metal;

// MARK: Pathtracer

/*
 * MIT License
 *
 * Copyright(c) 2019-2021 Asif Ali
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this softwareand associated documentation files(the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and /or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions :
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

class PTMaterial
 {
 public:
     PTMaterial()
     {
         albedo   = float3(1.0f, 1.0f, 1.0f);
         specular = 0.5f;

         emission    = float3(0.0f, 0.0f, 0.0f);
         anisotropic = 0.0f;

         metallic     = 0.0f;
         roughness    = 0.5f;
         subsurface   = 0.0f;
         specularTint = 0.0f;
         
         sheen          = 0.0f;
         sheenTint      = 0.0f;
         clearcoat      = 0.0f;
         clearcoatGloss = 0.0f;

         transmission  = 0.0f;
         ior           = 1.45f;
         extinction    = float3(1.0f, 1.0f, 1.0f);
     };

     float3 albedo;
     float specular;

     float3 emission;
     float anisotropic;

     float metallic;
     float roughness;
     float subsurface;
     float specularTint;
     
     float sheen;
     float sheenTint;
     float clearcoat;
     float clearcoatGloss;

     float transmission;
     float ior;
     float3 extinction;

     float3 texIDs;
     // Roughness calculated from anisotropic
     float ax;
     float ay;
 };

struct PTRay
{
    float3 origin;
    float3 direction;
};

struct PTLight
{
    float3 position;
    float3 emission;
    float3 u;
    float3 v;
    float radius;
    float area;
    float type;
};

class PTState
{
public:
    
    PTState()
    {
        depth = 0;
        
        isEmitter = false;
        specularBounce = false;
        isSubsurface = true;
    }
    
    int depth;
    float eta;
    float hitDist;

    float3 fhp;
    float3 normal;
    float3 ffnormal;
    float3 tangent;
    float3 bitangent;

    bool isEmitter;
    bool specularBounce;
    bool isSubsurface;

    float2 texCoord;
    float3 bary;
    //ivec3 triID;
    int matID;
    PTMaterial mat;
};

struct PTBsdfSampleRec
{
    float3 L;
    float3 f;
    float pdf;
};

struct PTLightSampleRec
{
    float3 surfacePos;
    float3 normal;
    float3 emission;
    float pdf;
};

class PTRandom;
float rand(PTRandom random);

class PTRandom
{
public:

    PTRandom(float2 seed, float3 randomVector, uint numberOfLights = 1)
    {
        this->seed = seed;
        this->randomVector = randomVector;
        this->numberOfLights = numberOfLights;
    }
    
    uint getRandomLightIndex()
    {
        return uint(rand(*this) * float(numberOfLights));
    }
    
    float2          seed;
    float3          randomVector;
    uint            numberOfLights;
};

float rand(PTRandom random)
{
    random.seed -= random.randomVector.xy;
    return fract(sin(dot(random.seed, float2(12.9898, 78.233))) * 43758.5453);
}

float3 FaceForward(float3 a, float3 b)
{
    return dot(a, b) < 0.0 ? -b : b;
}

//-----------------------------------------------------------------------
void Onb(float3 N, thread float3 &T, thread float3 B)
//-----------------------------------------------------------------------
{
    float3 UpVector = abs(N.z) < 0.999 ? float3(0, 0, 1) : float3(1, 0, 0);
    T = normalize(cross(UpVector, N));
    B = cross(N, T);
}

//----------------------------------------------------------------------
float3 ImportanceSampleGTR1(float rgh, float r1, float r2)
//----------------------------------------------------------------------
{
   float a = max(0.001, rgh);
   float a2 = a * a;

   float phi = r1 * M_2_PI_F;

   float cosTheta = sqrt((1.0 - pow(a2, 1.0 - r1)) / (1.0 - a2));
   float sinTheta = clamp(sqrt(1.0 - (cosTheta * cosTheta)), 0.0, 1.0);
   float sinPhi = sin(phi);
   float cosPhi = cos(phi);

   return float3(sinTheta * cosPhi, sinTheta * sinPhi, cosTheta);
}

//----------------------------------------------------------------------
float3 ImportanceSampleGTR2_aniso(float ax, float ay, float r1, float r2)
//----------------------------------------------------------------------
{
   float phi = r1 * M_2_PI_F;

   float sinPhi = ay * sin(phi);
   float cosPhi = ax * cos(phi);
   float tanTheta = sqrt(r2 / (1 - r2));

   return float3(tanTheta * cosPhi, tanTheta * sinPhi, 1.0);
}

//----------------------------------------------------------------------
float3 ImportanceSampleGTR2(float rgh, float r1, float r2)
//----------------------------------------------------------------------
{
   float a = max(0.001, rgh);

   float phi = r1 * M_2_PI_F;

   float cosTheta = sqrt((1.0 - r2) / (1.0 + (a * a - 1.0) * r2));
   float sinTheta = clamp(sqrt(1.0 - (cosTheta * cosTheta)), 0.0, 1.0);
   float sinPhi = sin(phi);
   float cosPhi = cos(phi);

   return float3(sinTheta * cosPhi, sinTheta * sinPhi, cosTheta);
}

//-----------------------------------------------------------------------
float SchlickFresnel(float u)
//-----------------------------------------------------------------------
{
   float m = clamp(1.0 - u, 0.0, 1.0);
   float m2 = m * m;
   return m2 * m2 * m; // pow(m,5)
}

//-----------------------------------------------------------------------
float DielectricFresnel(float cos_theta_i, float eta)
//-----------------------------------------------------------------------
{
   float sinThetaTSq = eta * eta * (1.0f - cos_theta_i * cos_theta_i);

   // Total internal reflection
   if (sinThetaTSq > 1.0)
       return 1.0;

   float cos_theta_t = sqrt(max(1.0 - sinThetaTSq, 0.0));

   float rs = (eta * cos_theta_t - cos_theta_i) / (eta * cos_theta_t + cos_theta_i);
   float rp = (eta * cos_theta_i - cos_theta_t) / (eta * cos_theta_i + cos_theta_t);

   return 0.5f * (rs * rs + rp * rp);
}

//-----------------------------------------------------------------------
float GTR1(float NDotH, float a)
//-----------------------------------------------------------------------
{
   if (a >= 1.0)
       return (1.0 / M_PI_F);
   float a2 = a * a;
   float t = 1.0 + (a2 - 1.0) * NDotH * NDotH;
   return (a2 - 1.0) / (M_PI_F * log(a2) * t);
}

//-----------------------------------------------------------------------
float GTR2(float NDotH, float a)
//-----------------------------------------------------------------------
{
   float a2 = a * a;
   float t = 1.0 + (a2 - 1.0) * NDotH * NDotH;
   return a2 / (M_PI_F * t * t);
}

//-----------------------------------------------------------------------
float GTR2_aniso(float NDotH, float HDotX, float HDotY, float ax, float ay)
//-----------------------------------------------------------------------
{
   float a = HDotX / ax;
   float b = HDotY / ay;
   float c = a * a + b * b + NDotH * NDotH;
   return 1.0 / (M_PI_F * ax * ay * c * c);
}

//-----------------------------------------------------------------------
float SmithG_GGX(float NDotV, float alphaG)
//-----------------------------------------------------------------------
{
   float a = alphaG * alphaG;
   float b = NDotV * NDotV;
   return 1.0 / (NDotV + sqrt(a + b - a * b));
}

//-----------------------------------------------------------------------
float SmithG_GGX_aniso(float NDotV, float VDotX, float VDotY, float ax, float ay)
//-----------------------------------------------------------------------
{
   float a = VDotX * ax;
   float b = VDotY * ay;
   float c = NDotV;
   return 1.0 / (NDotV + sqrt(a * a + b * b + c * c));
}

//-----------------------------------------------------------------------
float3 CosineSampleHemisphere(float r1, float r2)
//-----------------------------------------------------------------------
{
   float3 dir;
   float r = sqrt(r1);
   float phi = M_2_PI_F * r2;
   dir.x = r * cos(phi);
   dir.y = r * sin(phi);
   dir.z = sqrt(max(0.0, 1.0 - dir.x * dir.x - dir.y * dir.y));

   return dir;
}

//-----------------------------------------------------------------------
float3 UniformSampleHemisphere(float r1, float r2)
//-----------------------------------------------------------------------
{
   float r = sqrt(max(0.0, 1.0 - r1 * r1));
   float phi = M_2_PI_F * r2;

   return float3(r * cos(phi), r * sin(phi), r1);
}

//-----------------------------------------------------------------------
float3 UniformSampleSphere(float r1, float r2)
//-----------------------------------------------------------------------
{
   float z = 1.0 - 2.0 * r1;
   float r = sqrt(max(0.0, 1.0 - z * z));
   float phi = M_2_PI_F * r2;

   return float3(r * cos(phi), r * sin(phi), z);
}

//-----------------------------------------------------------------------
float powerHeuristic(float a, float b)
//-----------------------------------------------------------------------
{
   float t = a * a;
   return t / (b * b + t);
}

//-----------------------------------------------------------------------
void sampleSphereLight(PTLight light, thread PTLightSampleRec &lightSampleRec, PTRandom random)
//-----------------------------------------------------------------------
{
   float r1 = rand(random);
   float r2 = rand(random);
    
   lightSampleRec.surfacePos = light.position + UniformSampleSphere(r1, r2) * light.radius;
   lightSampleRec.normal = normalize(lightSampleRec.surfacePos - light.position);
   lightSampleRec.emission = light.emission * float(random.numberOfLights);
}

//-----------------------------------------------------------------------
void sampleRectLight(PTLight light, thread PTLightSampleRec &lightSampleRec, PTRandom random)
//-----------------------------------------------------------------------
{
   float r1 = rand(random);
   float r2 = rand(random);

   lightSampleRec.surfacePos = light.position + light.u * r1 + light.v * r2;
   lightSampleRec.normal = normalize(cross(light.u, light.v));
   lightSampleRec.emission = light.emission * float(random.numberOfLights);
}

//-----------------------------------------------------------------------
void sampleLight(PTLight light, thread PTLightSampleRec &lightSampleRec, PTRandom random)
//-----------------------------------------------------------------------
{
   if (int(light.type) == 0) // Rect Light
       sampleRectLight(light, lightSampleRec, random);
   else
       sampleSphereLight(light, lightSampleRec, random);
}

#ifdef ENVMAP
#ifndef CONSTANT_BG

//-----------------------------------------------------------------------
float EnvPdf(in Ray r)
//-----------------------------------------------------------------------
{
   float theta = acos(clamp(r.direction.y, -1.0, 1.0));
   vec2 uv = vec2((PI + atan(r.direction.z, r.direction.x)) * (1.0 / TWO_PI), theta * (1.0 / PI));
   float pdf = texture(hdrCondDistTex, uv).y * texture(hdrMarginalDistTex, vec2(uv.y, 0.)).y;
   return (pdf * hdrResolution) / (2.0 * PI * PI * sin(theta));
}

//-----------------------------------------------------------------------
vec4 EnvSample(inout vec3 color)
//-----------------------------------------------------------------------
{
   float r1 = rand();
   float r2 = rand();

   float v = texture(hdrMarginalDistTex, vec2(r1, 0.)).x;
   float u = texture(hdrCondDistTex, vec2(r2, v)).x;

   color = texture(hdrTex, vec2(u, v)).xyz * hdrMultiplier;
   float pdf = texture(hdrCondDistTex, vec2(u, v)).y * texture(hdrMarginalDistTex, vec2(v, 0.)).y;

   float phi = u * TWO_PI;
   float theta = v * PI;

   if (sin(theta) == 0.0)
       pdf = 0.0;

   return vec4(-sin(theta) * cos(phi), cos(theta), -sin(theta) * sin(phi), (pdf * hdrResolution) / (2.0 * PI * PI * sin(theta)));
}

#endif
#endif

//-----------------------------------------------------------------------
float3 EmitterSample(PTRay r, PTState state, PTLightSampleRec lightSampleRec, PTBsdfSampleRec bsdfSampleRec)
//-----------------------------------------------------------------------
{
   float3 Le;

   if (state.depth == 0 || state.specularBounce)
       Le = lightSampleRec.emission;
   else
       Le = powerHeuristic(bsdfSampleRec.pdf, lightSampleRec.pdf) * lightSampleRec.emission;

   return Le;
}

//-----------------------------------------------------------------------
float3 EvalDielectricReflection(PTState state, float3 V, float3 N, float3 L, float3 H, thread float &pdf)
//-----------------------------------------------------------------------
{
    if (dot(N, L) < 0.0) return float3(0.0);

    float F = DielectricFresnel(dot(V, H), state.eta);
    float D = GTR2(dot(N, H), state.mat.roughness);
    
    pdf = D * dot(N, H) * F / (4.0 * dot(V, H));

    float G = SmithG_GGX(abs(dot(N, L)), state.mat.roughness) * SmithG_GGX(dot(N, V), state.mat.roughness);
    return state.mat.albedo * F * D * G;
}

//-----------------------------------------------------------------------
float3 EvalDielectricRefraction(PTState state, float3 V, float3 N, float3 L, float3 H, thread float &pdf)
//-----------------------------------------------------------------------
{
    float F = DielectricFresnel(abs(dot(V, H)), state.eta);
    float D = GTR2(dot(N, H), state.mat.roughness);

    float denomSqrt = dot(L, H) * state.eta + dot(V, H);
    pdf = D * dot(N, H) * (1.0 - F) * abs(dot(L, H)) / (denomSqrt * denomSqrt);

    float G = SmithG_GGX(abs(dot(N, L)), state.mat.roughness) * SmithG_GGX(dot(N, V), state.mat.roughness);
    return state.mat.albedo * (1.0 - F) * D * G * abs(dot(V, H)) * abs(dot(L, H)) * 4.0 * state.eta * state.eta / (denomSqrt * denomSqrt);
}

//-----------------------------------------------------------------------
float3 EvalSpecular(PTState state, float3 Cspec0, float3 V, float3 N, float3 L, float3 H, thread float &pdf)
//-----------------------------------------------------------------------
{
    if (dot(N, L) < 0.0) return float3(0.0);

    float D = GTR2_aniso(dot(N, H), dot(H, state.tangent), dot(H, state.bitangent), state.mat.ax, state.mat.ay);
    pdf = D * dot(N, H) / (4.0 * dot(V, H));

    float FH = SchlickFresnel(dot(L, H));
    float3 F = mix(Cspec0, float3(1.0), FH);
    float G = SmithG_GGX_aniso(dot(N, L), dot(L, state.tangent), dot(L, state.bitangent), state.mat.ax, state.mat.ay);
    G *= SmithG_GGX_aniso(dot(N, V), dot(V, state.tangent), dot(V, state.bitangent), state.mat.ax, state.mat.ay);
    return F * D * G;
}

//-----------------------------------------------------------------------
float3 EvalClearcoat(PTState state, float3 V, float3 N, float3 L, float3 H, thread float &pdf)
//-----------------------------------------------------------------------
{
    if (dot(N, L) < 0.0) return float3(0.0);

    float D = GTR1(dot(N, H), state.mat.clearcoatGloss);
    pdf = D * dot(N, H) / (4.0 * dot(V, H));

    float FH = SchlickFresnel(dot(L, H));
    float F = mix(0.04, 1.0, FH);
    float G = SmithG_GGX(dot(N, L), 0.25) * SmithG_GGX(dot(N, V), 0.25);
    return float3(0.25 * state.mat.clearcoat * F * D * G);
}

//-----------------------------------------------------------------------
float3 EvalDiffuse(PTState state, float3 Csheen, float3 V, float3 N, float3 L, float3 H, thread float &pdf)
//-----------------------------------------------------------------------
{
    if (dot(N, L) < 0.0) return float3(0.0);

    pdf = dot(N, L) * (1.0 / M_PI_F);

    float FL = SchlickFresnel(dot(N, L));
    float FV = SchlickFresnel(dot(N, V));
    float FH = SchlickFresnel(dot(L, H));
    float Fd90 = 0.5 + 2.0 * dot(L, H) * dot(L, H) * state.mat.roughness;
    float Fd = mix(1.0, Fd90, FL) * mix(1.0, Fd90, FV);
    float3 Fsheen = FH * state.mat.sheen * Csheen;
    return ((1.0 / M_PI_F) * Fd * (1.0 - state.mat.subsurface) * state.mat.albedo + Fsheen) * (1.0 - state.mat.metallic);
}

//-----------------------------------------------------------------------
float3 EvalSubsurface(PTState state, float3 V, float3 N, float3 L, thread float &pdf)
//-----------------------------------------------------------------------
{
    pdf = (1.0 / M_2_PI_F);

    float FL = SchlickFresnel(abs(dot(N, L)));
    float FV = SchlickFresnel(dot(N, V));
    float Fd = (1.0f - 0.5f * FL) * (1.0f - 0.5f * FV);
    return sqrt(state.mat.albedo) * state.mat.subsurface * (1.0 / M_PI_F) * Fd * (1.0 - state.mat.metallic) * (1.0 - state.mat.transmission);
}

//-----------------------------------------------------------------------
float3 DisneySample(PTState state, float3 V, float3 N, thread float3 &L, thread float &pdf, PTRandom random)
//-----------------------------------------------------------------------
{
    state.isSubsurface = false;
    pdf = 0.0;
    float3 f = float3(0.0);

    float r1 = rand(random);
    float r2 = rand(random);

    float diffuseRatio = 0.5 * (1.0 - state.mat.metallic);
    float transWeight = (1.0 - state.mat.metallic) * state.mat.transmission;

    float3 Cdlin = state.mat.albedo;
    float Cdlum = 0.3 * Cdlin.x + 0.6 * Cdlin.y + 0.1 * Cdlin.z; // luminance approx.

    float3 Ctint = Cdlum > 0.0 ? Cdlin / Cdlum : float3(1.0f); // normalize lum. to isolate hue+sat
    float3 Cspec0 = mix(state.mat.specular * 0.08 * mix(float3(1.0), Ctint, state.mat.specularTint), Cdlin, state.mat.metallic);
    float3 Csheen = mix(float3(1.0), Ctint, state.mat.sheenTint);

    // BSDF
    if (rand(random) < transWeight)
    {
        float3 H = ImportanceSampleGTR2(state.mat.roughness, r1, r2);
        H = state.tangent * H.x + state.bitangent * H.y + N * H.z;

        float3 R = reflect(-V, H);
        float F = DielectricFresnel(abs(dot(R, H)), state.eta);

        // Reflection/Total internal reflection
        if (rand(random) < F)
        {
            L = normalize(R);
            f = EvalDielectricReflection(state, V, N, L, H, pdf);
        }
        else // Transmission
        {
            L = normalize(refract(-V, H, state.eta));
            f = EvalDielectricRefraction(state, V, N, L, H, pdf);
        }

        f *= transWeight;
        pdf *= transWeight;
    }
    else // BRDF
    {
        if (rand(random) < diffuseRatio)
        {
            // Diffuse transmission. A way to approximate subsurface scattering
            if (rand(random) < state.mat.subsurface)
            {
                L = UniformSampleHemisphere(r1, r2);
                L = state.tangent * L.x + state.bitangent * L.y - N * L.z;

                f = EvalSubsurface(state, V, N, L, pdf);
                pdf *= state.mat.subsurface * diffuseRatio;

                state.isSubsurface = true; // Required when sampling lights from inside surface
            }
            else // Diffuse
            {
                L = CosineSampleHemisphere(r1, r2);
                L = state.tangent * L.x + state.bitangent * L.y + N * L.z;

                float3 H = normalize(L + V);

                f = EvalDiffuse(state, Csheen, V, N, L, H, pdf);
                pdf *= (1.0 - state.mat.subsurface) * diffuseRatio;
            }
        }
        else // Specular
        {
            float primarySpecRatio = 1.0 / (1.0 + state.mat.clearcoat);
            
            // Sample primary specular lobe
            if (rand(random) < primarySpecRatio)
            {
                // TODO: Implement http://jcgt.org/published/0007/04/01/
                float3 H = ImportanceSampleGTR2_aniso(state.mat.ax, state.mat.ay, r1, r2);
                H = state.tangent * H.x + state.bitangent * H.y + N * H.z;
                L = normalize(reflect(-V, H));

                f = EvalSpecular(state, Cspec0, V, N, L, H, pdf);
                pdf *= primarySpecRatio * (1.0 - diffuseRatio);
            }
            else // Sample clearcoat lobe
            {
                float3 H = ImportanceSampleGTR1(state.mat.clearcoatGloss, r1, r2);
                H = state.tangent * H.x + state.bitangent * H.y + N * H.z;
                L = normalize(reflect(-V, H));

                f = EvalClearcoat(state, V, N, L, H, pdf);
                pdf *= (1.0 - primarySpecRatio) * (1.0 - diffuseRatio);
            }
        }

        f *= (1.0 - transWeight);
        pdf *= (1.0 - transWeight);
    }
    return f;
}

//-----------------------------------------------------------------------
float3 DisneyEval(PTState state, float3 V, float3 N, float3 L, thread float &pdf)
//-----------------------------------------------------------------------
{
    float3 H;

    if (dot(N, L) < 0.0)
        H = normalize(L * (1.0 / state.eta) + V);
    else
        H = normalize(L + V);

    if (dot(N, H) < 0.0)
        H = -H;

    float diffuseRatio = 0.5 * (1.0 - state.mat.metallic);
    float primarySpecRatio = 1.0 / (1.0 + state.mat.clearcoat);
    float transWeight = (1.0 - state.mat.metallic) * state.mat.transmission;

    float3 brdf = float3(0.0);
    float3 bsdf = float3(0.0);
    float brdfPdf = 0.0;
    float bsdfPdf = 0.0;

    // BSDF
    if (transWeight > 0.0)
    {
        // Transmission
        if (dot(N, L) < 0.0)
        {
            bsdf = EvalDielectricRefraction(state, V, N, L, H, bsdfPdf);
        }
        else // Reflection
        {
            bsdf = EvalDielectricReflection(state, V, N, L, H, bsdfPdf);
        }
    }

    float m_pdf;

    if (transWeight < 1.0)
    {
        // Subsurface
        if (dot(N, L) < 0.0)
        {
            // TODO: Double check this. Fails furnace test when used with rough transmission
            if (state.mat.subsurface > 0.0)
            {
                brdf = EvalSubsurface(state, V, N, L, m_pdf);
                brdfPdf = m_pdf * state.mat.subsurface * diffuseRatio;
            }
        }
        // BRDF
        else
        {
            float3 Cdlin = state.mat.albedo;
            float Cdlum = 0.3 * Cdlin.x + 0.6 * Cdlin.y + 0.1 * Cdlin.z; // luminance approx.

            float3 Ctint = Cdlum > 0.0 ? Cdlin / Cdlum : float3(1.0f); // normalize lum. to isolate hue+sat
            float3 Cspec0 = mix(state.mat.specular * 0.08 * mix(float3(1.0), Ctint, state.mat.specularTint), Cdlin, state.mat.metallic);
            float3 Csheen = mix(float3(1.0), Ctint, state.mat.sheenTint);

            // Diffuse
            brdf += EvalDiffuse(state, Csheen, V, N, L, H, m_pdf);
            brdfPdf += m_pdf * (1.0 - state.mat.subsurface) * diffuseRatio;
            
            // Specular
            brdf += EvalSpecular(state, Cspec0, V, N, L, H, m_pdf);
            brdfPdf += m_pdf * primarySpecRatio * (1.0 - diffuseRatio);
            
            // Clearcoat
            brdf += EvalClearcoat(state, V, N, L, H, m_pdf);
            brdfPdf += m_pdf * (1.0 - primarySpecRatio) * (1.0 - diffuseRatio);
        }
    }

    pdf = mix(brdfPdf, bsdfPdf, transWeight);
    return mix(brdf, bsdf, transWeight);
}

#define EPS 0.0001

#define REFL 0
#define REFR 1
#define SUBS 2

// MARK: MPS Renderer

struct Ray {
    packed_float3       origin;
    float               minDistance;
    packed_float3       direction;
    float               maxDistance;
    
    float3              color;
    
    float3              surfacePos;
    float3              surfaceNormal;

    float3              radiance;
    float3              throughput;
    float3              absorption;
};

struct Intersection {
  float                 distance;
  int                   primitiveIndex;
  float2                coordinates;
};

kernel void primaryRays(constant Uniforms & uniforms [[buffer(0)]],
                        device Ray *rays [[buffer(1)]],
                        texture2d<float, access::write> t [[texture(0)]],
                        //texture2d<float, access::write> radianceT [[texture(1)]],
                        //texture2d<float, access::write> throughputT [[texture(2)]],
                        //texture2d<float, access::write> absorptionT [[texture(3)]],
                        uint2 tid [[thread_position_in_grid]])
{
    if (tid.x < uniforms.width && tid.y < uniforms.height)
    {
        float2 pixel = (float2)tid;
        float2 uv = (float2)pixel / float2(uniforms.width, uniforms.height);
        uv.y = 1.0 - uv.y;
        
        PTRandom random = PTRandom(uv, uniforms.randomVector);
        
        constant Camera & camera = uniforms.camera;
        unsigned int rayIdx = tid.y * uniforms.width + tid.x;
        device Ray & ray = rays[rayIdx];
        
        float2 size = float2(uniforms.width, uniforms.height);
        
        const float fov = camera.fov;

        float3 position = camera.position;
        float3 pivot = camera.lookAt;
        float focalDist = camera.focalDist;
        float aperture = camera.aperture;
        
        float3 dir = normalize(pivot - position);
        float pitch = asin(dir.y);
        float yaw = atan2(dir.z, dir.x);

        float radius = distance(position, pivot);

        float3 forward_temp = float3();
        
        forward_temp.x = cos(yaw) * cos(pitch);
        forward_temp.y = sin(pitch);
        forward_temp.z = sin(yaw) * cos(pitch);

        float3 worldUp = float3(0,1,0);
        float3 forward = normalize(forward_temp);
        position = pivot + (forward * -1.0) * radius;

        float3 right = normalize(cross(forward, worldUp));
        float3 up = normalize(cross(right, forward));

        float2 r2D = 2.0 * float2(rand(random), rand(random));

        float2 jitter = float2();
        jitter.x = r2D.x < 1.0 ? sqrt(r2D.x) - 1.0 : 1.0 - sqrt(2.0 - r2D.x);
        jitter.y = r2D.y < 1.0 ? sqrt(r2D.y) - 1.0 : 1.0 - sqrt(2.0 - r2D.y);

        jitter /= (size * 0.5);
        float2 d = (2.0 * uv - 1.0) + jitter;

        float scale = tan(fov * 0.5);
        d.y *= size.y / size.x * scale;
        d.x *= scale;
        float3 rayDir = normalize(d.x * right + d.y * up + forward);

        float3 focalPoint = focalDist * rayDir;
        float cam_r1 = rand(random) * M_2_PI_F;
        float cam_r2 = rand(random) * aperture;
        float3 randomAperturePos = (cos(cam_r1) * right + sin(cam_r1) * up) * sqrt(cam_r2);
        float3 finalRayDir = normalize(focalPoint - randomAperturePos);
        
        ray.origin = position + randomAperturePos;
        ray.direction = finalRayDir;
        
        ray.minDistance = 0;
        ray.maxDistance = INFINITY;
        ray.color = float3(1.0);
        ray.radiance = float3(0);
        ray.throughput = float3(1);
        ray.absorption = float3(0);

        t.write(float4(0), tid);
        //radianceT.write(float4(0), tid);
        //throughputT.write(float4(1), tid);
        //absorptionT.write(float4(0), tid);
        
    }
}

// Interpolates vertex attribute of an arbitrary type across the surface of a triangle
// given the barycentric coordinates and triangle index in an intersection struct
template<typename T>
inline T interpolateVertexAttribute(device T *attributes, Intersection intersection) {
  float3 uvw;
  uvw.xy = intersection.coordinates;
  uvw.z = 1.0 - uvw.x - uvw.y;
  unsigned int triangleIndex = intersection.primitiveIndex;
  T T0 = attributes[triangleIndex * 3 + 0];
  T T1 = attributes[triangleIndex * 3 + 1];
  T T2 = attributes[triangleIndex * 3 + 2];
  return uvw.x * T0 + uvw.y * T1 + uvw.z * T2;
}

void fillMaterialData(thread PTMaterial *material, device float4 *materialData)
{
    material->albedo = materialData[0].xyz;
    material->specular = materialData[0].w;
    
    material->emission = materialData[1].xyz;
    material->anisotropic = materialData[1].w;
    
    material->metallic = materialData[2].x;
    material->roughness = materialData[2].y;
    material->subsurface = materialData[2].z;
    material->specularTint = materialData[2].w;

    material->sheen = materialData[3].x;
    material->sheenTint = materialData[3].y;
    material->clearcoat = materialData[3].z;
    material->clearcoatGloss = materialData[3].w;
    
    material->transmission = materialData[4].x;
    
    material->extinction = materialData[5].xyz;
    material->ior = materialData[5].w;
}

kernel void shadeKernel(uint2 tid [[thread_position_in_grid]],
                        constant Uniforms & uniforms,
                        device Ray *rays,
                        device Ray *shadowRays,
                        device Intersection *intersections,
                        device float4 *materialData,
                        device float3 *vertexNormals,
                        device float2 *random,
                        device uint *materialIndeces,
                        device float4 *lightData,
                        texture2d<float, access::write> renderTarget)
{
    if (tid.x < uniforms.width && tid.y < uniforms.height) {
        unsigned int rayIdx = tid.y * uniforms.width + tid.x;
        device Ray & ray = rays[rayIdx];
        device Ray & shadowRay = shadowRays[rayIdx];
        device Intersection & intersection = intersections[rayIdx];
        //float3 color = ray.color;
        
        if (ray.maxDistance >= 0.0 && intersection.distance >= 0.0)
        {
            float3 Li = float3(0.0);

            float2 pixel = (float2)tid;
            float2 uv = (float2)pixel / float2(uniforms.width, uniforms.height);
            uv.y = 1.0 - uv.y;
            
            PTRandom random = PTRandom(uv, uniforms.randomVector, uniforms.numberOfLights);
            
            float3 surfacePos = ray.origin + ray.direction * intersection.distance;
            float3 surfaceNormal = interpolateVertexAttribute(vertexNormals, intersection);
            surfaceNormal = normalize(surfaceNormal);
            
            ray.surfacePos = surfacePos;
            ray.surfaceNormal = surfaceNormal;
                        
            PTLightSampleRec lightSampleRec = PTLightSampleRec();
            PTLight light = PTLight();
            
            PTState state = PTState();

            uint materialIndex = materialIndeces[intersection.primitiveIndex * 3] * 6;
            fillMaterialData(&state.mat, &materialData[materialIndex]);

            state.fhp = surfacePos;
            state.normal = surfaceNormal;
            state.ffnormal = dot(surfaceNormal, ray.direction) <= 0.0 ? surfaceNormal : surfaceNormal * -1.0;
            Onb(state.ffnormal, state.tangent, state.bitangent);
            
            // Calculate anisotropic roughness along the tangent and bitangent directions
            float aspect = sqrt(1.0 - state.mat.anisotropic * 0.9);
            state.mat.ax = max(0.001, state.mat.roughness / aspect);
            state.mat.ay = max(0.001, state.mat.roughness * aspect);

            state.eta = dot(state.normal, state.ffnormal) > 0.0 ? (1.0 / state.mat.ior) : state.mat.ior;

            ray.color.x = float(materialIndex);
            ray.color.y = intersection.distance;

            // DirectLight for a random light source

            uint index = random.getRandomLightIndex();

            // Fetch light Data
            /*
            vec3 position = texelFetch(lightsTex, ivec2(index * 5 + 0, 0), 0).xyz;
            vec3 emission = texelFetch(lightsTex, ivec2(index * 5 + 1, 0), 0).xyz;
            vec3 u        = texelFetch(lightsTex, ivec2(index * 5 + 2, 0), 0).xyz; // u vector for rect
            vec3 v        = texelFetch(lightsTex, ivec2(index * 5 + 3, 0), 0).xyz; // v vector for rect
            vec3 params   = texelFetch(lightsTex, ivec2(index * 5 + 4, 0), 0).xyz;
            float radius  = params.x;
            float area    = params.y;
            float type    = params.z; // 0->rect, 1->sphere*/
            
            light.position = lightData[index * 5 + 0].xyz;
            light.emission = lightData[index * 5 + 1].xyz;
            light.u        = lightData[index * 5 + 2].xyz; // u vector for rect
            light.v        = lightData[index * 5 + 3].xyz; // v vector for rect
            float3 params  = lightData[index * 5 + 4].xyz;
            light.radius   = params.x;
            light.area     = params.y;
            light.type     = params.z; // 0->rect, 1->sphere*/
            
            /*
            
            light.position = float3(3, 2, -2);
            light.emission = float3(4, 4, 4);
            light.u = float3(1, 2, 1);
            light.v = float3(0, 2, 1);
            light.radius = 1;
            light.area = 50;
            light.type = 0;*/

            sampleLight(light, lightSampleRec, random);
            
            float3 lightDir = lightSampleRec.surfacePos - surfacePos;
            float lightDist = length(lightDir);
            float lightDistSq = lightDist * lightDist;
            lightDir /= sqrt(lightDistSq);
            
            if (!state.isSubsurface && (dot(lightDir, state.ffnormal) <= 0.0 || dot(lightDir, lightSampleRec.normal) >= 0.0)) {
                
                //
            } else {
                //Ray shadowRay = PTRay(surfacePos + FaceForward(state.normal, lightDir) * EPS, lightDir);
                //bool inShadow = AnyHit(shadowRay, lightDist - EPS);

                PTBsdfSampleRec bsdfSampleRec;

                bsdfSampleRec.f = DisneyEval(state, -ray.direction, state.ffnormal, lightDir, bsdfSampleRec.pdf);
                float lightPdf = lightDistSq / (light.area * abs(dot(lightSampleRec.normal, lightDir)));

                if (bsdfSampleRec.pdf > 0.0)
                    Li += powerHeuristic(lightPdf, bsdfSampleRec.pdf) * bsdfSampleRec.f * abs(dot(state.ffnormal, lightDir)) * lightSampleRec.emission / lightPdf;
            }
            
            shadowRay.color = Li;

            shadowRay.origin = surfacePos + FaceForward(state.normal, lightDir) * EPS;
            shadowRay.direction = lightDir;
            shadowRay.maxDistance = lightDist - 1e-3;
            
            /*
            float2 r = random[(tid.y % 16) * 16 + (tid.x % 16)];
            float3 lightDirection;
            float3 lightColor;
            float lightDistance;
            sampleAreaLight(uniforms.light, r, intersectionPoint,
                            lightDirection, lightColor, lightDistance);
            lightColor *= saturate(dot(surfaceNormal, lightDirection));
            color *= interpolateVertexAttribute(vertexColors, intersection);
            shadowRay.origin = intersectionPoint + surfaceNormal * 1e-3;
            shadowRay.direction = lightDirection;
            shadowRay.maxDistance = lightDistance - 1e-3;
            shadowRay.color = lightColor * color;
      
            float3 sampleDirection = sampleCosineWeightedHemisphere(r);
            sampleDirection = alignHemisphereWithNormal(sampleDirection,
                                                  surfaceNormal);
            ray.origin = intersectionPoint + surfaceNormal * 1e-3f;
            ray.direction = sampleDirection;
            ray.color = color;*/
            
        } else {
            ray.maxDistance = -1.0;
            shadowRay.maxDistance = -1.0;
        }
    }
}

//-----------------------------------------------------------------------
float SphereIntersect(float rad, float3 pos, PTRay r)
//-----------------------------------------------------------------------
{
    float3 op = pos - r.origin;
    float eps = 0.001;
    float b = dot(op, r.direction);
    float det = b * b - dot(op, op) + rad * rad;
    if (det < 0.0)
        return INFINITY;

    det = sqrt(det);
    float t1 = b - det;
    if (t1 > eps)
        return t1;

    float t2 = b + det;
    if (t2 > eps)
        return t2;

    return INFINITY;
}

float TestLights(PTRay r, thread PTState &state, thread PTLightSampleRec &lightSampleRec, uint numberOfLights, device float4 *lightData, float dist)
{
    float t = dist;
    float d;

    for (uint i = 0; i < numberOfLights; i++)
    {
        float3 position = lightData[i * 5 + 0].xyz;
        float3 emission = lightData[i * 5 + 1].xyz;
        float3 u        = lightData[i * 5 + 2].xyz; // u vector for rect
        float3 v        = lightData[i * 5 + 3].xyz; // v vector for rect
        float3 params  = lightData[i * 5 + 4].xyz;
        float radius   = params.x;
        float area     = params.y;
        float type     = params.z; // 0->rect, 1->sphere*/
        
        // Spherical Area Light
        if (type == 1.)
        {
            d = SphereIntersect(radius, position, r);
            if (d < 0.)
                d = INFINITY;
            if (d < t)
            {
                t = d;
                float pdf = (t * t) / area;
                lightSampleRec.emission = emission;
                lightSampleRec.pdf = pdf;
                state.isEmitter = true;
            }
        }
    }
    
    return t;
}

kernel void shadowKernel(uint2 tid [[thread_position_in_grid]],
                         constant Uniforms & uniforms,
                         device Ray *rays,
                         device Ray *shadowRays,
                         device float *intersections,
                         device float4 *materialData,
                         device float4 *lightData,
                         texture2d<float, access::read_write> renderTarget)
{
    if (tid.x < uniforms.width && tid.y < uniforms.height)
    {
        unsigned int rayIdx = tid.y * uniforms.width + tid.x;
        device Ray & ray = rays[rayIdx];
        device Ray & shadowRay = shadowRays[rayIdx];
        float intersectionDistance = intersections[rayIdx];
                    
        if (shadowRay.maxDistance >= 0.0 && intersectionDistance < 0.0) {

            PTLightSampleRec lightSampleRec;
            PTBsdfSampleRec bsdfSampleRec;
            
            //float lightPdf = 1.0f;

            float2 pixel = (float2)tid;
            float2 uv = (float2)pixel / float2(uniforms.width, uniforms.height);
            uv.y = 1.0 - uv.y;
            
            PTRandom random = PTRandom(uv, uniforms.randomVector, uniforms.numberOfLights);
            
            PTState state = PTState();
            
            unsigned int materialIndex = uint(ray.color.x);
            fillMaterialData(&state.mat, &materialData[materialIndex]);

            state.fhp = ray.surfacePos;
            state.normal = ray.surfaceNormal;
            state.ffnormal = dot(ray.surfaceNormal, ray.direction) <= 0.0 ? ray.surfaceNormal : ray.surfaceNormal * -1.0;
            Onb(state.ffnormal, state.tangent, state.bitangent);
            
            float3 radiance = ray.radiance;
            float3 throughput = ray.throughput;
            float3 absorption = ray.absorption;
            
            // Test if a light is closer
            
            PTRay ptRay;
            ptRay.origin = ray.origin;
            ptRay.direction = ray.direction;
            
            TestLights(ptRay, state, lightSampleRec, uniforms.numberOfLights, lightData, ray.color.y);
            

            // Reset absorption when ray is going out of surface
            if (dot(state.normal, state.ffnormal) > 0.0)
                absorption = float3(0.0);

            radiance += state.mat.emission * throughput;
            
            if (state.isEmitter) {
                radiance += EmitterSample(ptRay, state, lightSampleRec, bsdfSampleRec) * throughput;
                ray.maxDistance = -1.0;
                shadowRay.maxDistance = -1.0;
            } else {
            
                // Add absoption
                throughput *= exp(-absorption * distance(ray.origin, ray.surfacePos));

                radiance += shadowRay.color * throughput;

                bsdfSampleRec.f = DisneySample(state, -ray.direction, state.ffnormal, bsdfSampleRec.L, bsdfSampleRec.pdf, random);

                // Set absorption only if the ray is currently inside the object.
                if (dot(state.ffnormal, bsdfSampleRec.L) < 0.0)
                    absorption = -log(state.mat.extinction) / float3(0.2); // TODO: Add atDistance

                if (bsdfSampleRec.pdf > 0.0)
                    throughput *= bsdfSampleRec.f * abs(dot(state.ffnormal, bsdfSampleRec.L)) / bsdfSampleRec.pdf;
                else {
                    ray.maxDistance = -1.0;
                    shadowRay.maxDistance = -1.0;
                }
            }
            
            float3 color = radiance;
            //color += renderTarget.read(tid).xyz;
            renderTarget.write(float4(color, 1.0), tid);
            
            ray.direction = bsdfSampleRec.L;
            ray.origin = state.fhp + ray.direction * EPS;
            
            ray.radiance = radiance;
            ray.throughput = throughput;
            ray.absorption = absorption;
        } else {
            
            if(intersectionDistance < 0.0)
            {
                PTLightSampleRec lightSampleRec;
                PTBsdfSampleRec bsdfSampleRec;
                
                //float lightPdf = 1.0f;

                float2 pixel = (float2)tid;
                float2 uv = (float2)pixel / float2(uniforms.width, uniforms.height);
                uv.y = 1.0 - uv.y;
                
                PTState state = PTState();
                
                unsigned int materialIndex = uint(ray.color.x);
                fillMaterialData(&state.mat, &materialData[materialIndex]);

                state.fhp = ray.surfacePos;
                state.normal = ray.surfaceNormal;
                state.ffnormal = dot(ray.surfaceNormal, ray.direction) <= 0.0 ? ray.surfaceNormal : ray.surfaceNormal * -1.0;
                Onb(state.ffnormal, state.tangent, state.bitangent);
                
                float3 radiance = float3(0,0,1);
                
                // Test if a light is closer
                
                PTRay ptRay;
                ptRay.origin = ray.origin;
                ptRay.direction = ray.direction;
                
                TestLights(ptRay, state, lightSampleRec, uniforms.numberOfLights, lightData, INFINITY);
                
                if (state.isEmitter) {
                    radiance += EmitterSample(ptRay, state, lightSampleRec, bsdfSampleRec);
                }
                
                renderTarget.write(float4(radiance, 1.0), tid);
                
                ray.maxDistance = -1.0;
                shadowRay.maxDistance = -1.0;
            }
        }
    }
}

struct Vertex {
  float4 position [[position]];
  float2 uv;
};

constant float2 quadVertices[] = {
  float2(-1, -1),
  float2(-1,  1),
  float2( 1,  1),
  float2(-1, -1),
  float2( 1,  1),
  float2( 1, -1)
};

vertex Vertex vertexShader(unsigned short vid [[vertex_id]])
{
  float2 position = quadVertices[vid];
  Vertex out;
  out.position = float4(position, 0, 1);
  out.uv = position * 0.5 + 0.5;
  return out;
}

fragment float4 fragmentShader(Vertex in [[stage_in]],
                               texture2d<float> tex)
{
  constexpr sampler s(min_filter::nearest,
                      mag_filter::nearest,
                      mip_filter::none);
  float3 color = tex.sample(s, in.uv).xyz;
  return float4(color, 1.0);
}

kernel void accumulateKernel(constant Uniforms & uniforms,
                             texture2d<float> renderTex,
                             texture2d<float, access::read_write> t,
                             uint2 tid [[thread_position_in_grid]])
{
  if (tid.x < uniforms.width && tid.y < uniforms.height) {
    float3 color = renderTex.read(tid).xyz;
    if (uniforms.frameIndex > 0) {
      float3 prevColor = t.read(tid).xyz;
      prevColor *= uniforms.frameIndex;
      color += prevColor;
      color /= (uniforms.frameIndex + 1);
    }
    t.write(float4(color, 1.0), tid);
  }
}


