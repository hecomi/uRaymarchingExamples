Shader "Raymarching/Folding"
{

Properties
{
    [Header(PBS)]
    _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
    _Metallic("Metallic", Range(0.0, 1.0)) = 0.5
    _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5

    [Header(Pass)]
    [Enum(UnityEngine.Rendering.CullMode)] _Cull("Culling", Int) = 2
    [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc("Blend Src", Float) = 5 
    [Enum(UnityEngine.Rendering.BlendMode)] _BlendDst("Blend Dst", Float) = 10
    [Toggle][KeyEnum(Off, On)] _ZWrite("ZWrite", Float) = 1

    [Header(Raymarching)]
    _Loop("Loop", Range(1, 100)) = 30
    _MinDistance("Minimum Distance", Range(0.001, 0.1)) = 0.01
    _DistanceMultiplier("Distance Multiplier", Range(0.001, 2.0)) = 1.0
    _ShadowLoop("Shadow Loop", Range(1, 100)) = 30
    _ShadowMinDistance("Shadow Minimum Distance", Range(0.001, 0.1)) = 0.01
    _ShadowExtraBias("Shadow Extra Bias", Range(0.0, 1.0)) = 0.0

// @block Properties
// _Color2("Color2", Color) = (1.0, 1.0, 1.0, 1.0)
// @endblock
}

SubShader
{

Tags
{
    "RenderType" = "Transparent"
    "Queue" = "Transparent"
    "DisableBatching" = "True"
}

Cull [_Cull]

CGINCLUDE

#define OBJECT_SHAPE_CUBE

#define CAMERA_INSIDE_OBJECT

#define USE_RAYMARCHING_DEPTH

#define USE_CAMERA_DEPTH_TEXTURE

#define SPHERICAL_HARMONICS_PER_PIXEL

#define DISTANCE_FUNCTION DistanceFunction
#define PostEffectOutput SurfaceOutputStandard
#define POST_EFFECT PostEffect

#include "Assets/uRaymarching/Shaders/Include/Common.cginc"

// @block DistanceFunction
// Ref: https://gam0022.net/blog/2017/03/02/raymarching-fold/

float2x2 rotate(in float a) 
{
    float s = sin(a), c = cos(a);
    return float2x2(c, s, -s, c);
}

// https://www.shadertoy.com/view/Mlf3Wj
float2 foldRotate(in float2 p, in float s) 
{
    float a = PI / s - atan2(p.x, p.y);
    float n = 2 * PI / s;
    a = floor(a / n) * n;
    p = mul(rotate(a), p);
    return p;
}

float dTree(float3 p) 
{
    float scale = 0.6 * saturate(1.5 * 10);//_SinTime.y);
    float width = lerp(0.3 * scale, 0.0, saturate(p.y));
    float3 size = float3(width, 1.0, width);
    float d = Box(p, size);
    for (int i = 0; i < 10; i++) {
        float3 q = p;
        q.x = abs(q.x);
        q.y -= 0.5 * size.y;
        q.xy = mul(rotate(-1.2), q.xy);
        d = min(d, Box(p, size));
        p = q;
        size *= scale;
    }
    return d;
}

float dSnowCrystal(float3 p) {
    p.xy = foldRotate(p.xy, 6.0);
    return dTree(p);
}

inline float DistanceFunction(float3 pos)
{
    return dSnowCrystal(pos);
}
// @endblock

// @block PostEffect
inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
{
    o.Occlusion = 1.0 - 1.0 * ray.loop / ray.maxLoop;
    o.Emission = o.Albedo * ray.loop / ray.maxLoop;
}
// @endblock

ENDCG

Pass
{
    Tags { "LightMode" = "ForwardBase" }
    Blend [_BlendSrc] [_BlendDst]
    ZWrite [_ZWrite]

    CGPROGRAM
    #include "Assets/uRaymarching/Shaders/Include/ForwardBaseStandard.cginc"
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
    #include "Assets/uRaymarching/Shaders/Include/ForwardAddStandard.cginc"
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
    #include "Assets/uRaymarching/Shaders/Include/ShadowCaster.cginc"
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