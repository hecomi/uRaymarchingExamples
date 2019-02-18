Shader "Raymarching/TransformProvider"
{

Properties
{
    [Header(PBS)]
    _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
    _Metallic("Metallic", Range(0.0, 1.0)) = 0.5
    _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5

    [Header(Pass)]
    [Enum(UnityEngine.Rendering.CullMode)] _Cull("Culling", Int) = 2

    [Toggle][KeyEnum(Off, On)] _ZWrite("ZWrite", Float) = 1

    [Header(Raymarching)]
    _Loop("Loop", Range(1, 100)) = 30
    _MinDistance("Minimum Distance", Range(0.001, 0.1)) = 0.01
    _DistanceMultiplier("Distance Multiplier", Range(0.001, 2.0)) = 1.0
    _ShadowLoop("Shadow Loop", Range(1, 100)) = 30
    _ShadowMinDistance("Shadow Minimum Distance", Range(0.001, 0.1)) = 0.01
    _ShadowExtraBias("Shadow Extra Bias", Range(0.0, 0.1)) = 0.0

// @block Properties
[Header(Additional Parameters)]
_Smooth("Smooth", float) = 1.0
_CubeColor("Cube Color", Color) = (1.0, 1.0, 1.0, 1.0)
_SphereColor("Sphere Color", Color) = (1.0, 1.0, 1.0, 1.0)
_TorusColor("Torus Color", Color) = (1.0, 1.0, 1.0, 1.0)
_PlaneColor("Plane Color", Color) = (1.0, 1.0, 1.0, 1.0)
// @endblock
}

SubShader
{

Tags
{
    "RenderType" = "Opaque"
    "Queue" = "Geometry"
    "DisableBatching" = "True"
}

Cull [_Cull]

CGINCLUDE

#define WORLD_SPACE

#define OBJECT_SHAPE_CUBE

#define USE_RAYMARCHING_DEPTH

#define SPHERICAL_HARMONICS_PER_PIXEL

#define DISTANCE_FUNCTION DistanceFunction
#define PostEffectOutput SurfaceOutputStandard
#define POST_EFFECT PostEffect

#include "Assets\uRaymarching\Shaders\Include/Common.cginc"

// @block DistanceFunction
// These inverse transform matrices are provided
// from TransformProvider script 
float4x4 _Cube;
float4x4 _Sphere;
float4x4 _Torus;
float4x4 _Plane; 

float _Smooth;

inline float DistanceFunction(float3 wpos)
{
    float4 cPos = mul(_Cube, float4(wpos, 1.0));
    float4 sPos = mul(_Sphere, float4(wpos, 1.0));
    float4 tPos = mul(_Torus, float4(wpos, 1.0));
    float4 pPos = mul(_Plane, float4(wpos, 1.0));
    float s = Sphere(sPos, 0.5);
    float c = Box(cPos, 0.5);
    float t = Torus(tPos, float2(0.5, 0.2));
    float p = Plane(pPos, float3(0, 1, 0));
    float sc = SmoothMin(s, c, _Smooth);
    float tp = SmoothMin(t, p, _Smooth);
    return SmoothMin(sc, tp, _Smooth);
}
// @endblock

// @block PostEffect
float4 _CubeColor;
float4 _SphereColor;
float4 _TorusColor;
float4 _PlaneColor;

inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
{
    float3 wpos = ray.endPos;
    float4 cPos = mul(_Cube, float4(wpos, 1.0));
    float4 sPos = mul(_Sphere, float4(wpos, 1.0));
    float4 tPos = mul(_Torus, float4(wpos, 1.0));
    float4 pPos = mul(_Plane, float4(wpos, 1.0));
    float s = Sphere(sPos, 0.5);
    float c = Box(cPos, 0.5);
    float t = Torus(tPos, float2(0.5, 0.2));
    float p = Plane(pPos, float3(0, 1, 0));
    float4 a = normalize(float4(1.0 / s, 1.0 / c, 1.0 / t, 1.0 / p));
    o.Albedo =
        a.x * _SphereColor +
        a.y * _CubeColor +
        a.z * _TorusColor +
        a.w * _PlaneColor;
}
// @endblock

ENDCG

Pass
{
    Tags { "LightMode" = "ForwardBase" }

    ZWrite [_ZWrite]

    CGPROGRAM
    #include "Assets\uRaymarching\Shaders\Include/ForwardBaseStandard.cginc"
    #pragma target 3.0
    #pragma vertex Vert
    #pragma fragment Frag
    #pragma multi_compile_instancing
    #pragma multi_compile_fog
    #pragma multi_compile_fwdbase
    ENDCG
}

Pass
{
    Tags { "LightMode" = "ForwardAdd" }
    ZWrite Off 
    Blend One One

    CGPROGRAM
    #include "Assets\uRaymarching\Shaders\Include/ForwardAddStandard.cginc"
    #pragma target 3.0
    #pragma vertex Vert
    #pragma fragment Frag
    #pragma multi_compile_instancing
    #pragma multi_compile_fog
    #pragma skip_variants INSTANCING_ON
    #pragma multi_compile_fwdadd_fullshadows
    ENDCG
}

Pass
{
    Tags { "LightMode" = "ShadowCaster" }

    CGPROGRAM
    #include "Assets\uRaymarching\Shaders\Include/ShadowCaster.cginc"
    #pragma target 3.0
    #pragma vertex Vert
    #pragma fragment Frag
    #pragma fragmentoption ARB_precision_hint_fastest
    #pragma multi_compile_shadowcaster
    ENDCG
}

}

Fallback Off

CustomEditor "uShaderTemplate.MaterialEditor"

}