#if !defined(MY_DEFERRED_SHADING)
#define MY_DEFERRED_SHADING

#include "UnityPBSLighting.cginc"

UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

//Gbuffers for deferred rendering
sampler2D _CameraGBufferTexture0;
sampler2D _CameraGBufferTexture1;
sampler2D _CameraGBufferTexture2;

float4 _LightColor, _LightDir;

sampler2D _LightTexture0; //cookie texture
float4x4 unity_WorldToLight;

//Only define variable for directional lights since UnityShadowLibrary already defines it for point and spotlights
#if defined (SHADOWS_SCREEN) 
    sampler2D _ShadowMapTexture;
#endif

struct appdata {
    float4 vertex : POSITION;
    float3 normal : NORMAL;
};

struct v2f {
    float4 pos : SV_POSITION;
    float4 uv : TEXCOORD0;
    float3 ray : TEXCOORD1;
};

UnityLight CreateLight(float2 uv, float3 worldPos, float viewZ) {
    UnityLight light;
    light.dir = -_LightDir;
    float attenuation = 1;
    float shadowAttenuation = 1;

    #if defined(DIRECTIONAL_COOKIE)
        float2 uvCookie = mul(unity_WorldToLight, float4(worldPos, 1)).xy;
        //Bias applied to avoid artifacts on geometry edges. Check http://aras-p.info/blog/2010/01/07/screenspace-vs-mip-mapping/ for more info 
        attenuation *= tex2Dbias(_LightTexture0, float4(uvCookie, 0, -8)).w; 
    #endif

    #if defined (SHADOWS_SCREEN)
        shadowAttenuation = tex2D(_ShadowMapTexture, uv).r;

        //Returns distance from shadow center or unmodified view depth depending if on 
        //Stable or Close Fit mode for shadow cascades
        float shadowFadeDistance = UnityComputeShadowFadeDistance(worldPos, viewZ); 
        //Calculate the apropriate fade factor
        float shadowFade = UnityComputeShadowFade(shadowFadeDistance);
        shadowAttenuation = saturate(shadowAttenuation + shadowFade);
    #endif
    light.color = _LightColor.rgb * (attenuation * shadowAttenuation);
    return light;
}

v2f vert(appdata v) {
    v2f i;
    i.pos = UnityObjectToClipPos(v.vertex);
    i.uv = ComputeScreenPos(i.pos);
    i.ray = v.normal;
    return i;
}

float4 frag(v2f i) : SV_Target {
    float2 uv = i.uv.xy / i.uv.w;
    
    float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
    depth = Linear01Depth(depth);

    float3 rayToFarPlane = i.ray * _ProjectionParams.z / i.ray.z; //the rays, defined in view space, reach the near plane and need to be scaled to reach the far one
    float3 viewPos = rayToFarPlane * depth;
    float3 worldPos = mul(unity_CameraToWorld, float4(viewPos, 1)).xyz;
    float3 viewDir = normalize(_WorldSpaceCameraPos - worldPos);

    //Reading data from GBuffers written in first deferred pass
    float3 albedo = tex2D(_CameraGBufferTexture0, uv).rgb;
    float3 specularTint = tex2D(_CameraGBufferTexture1, uv).rgb;
    float3 smoothness = tex2D(_CameraGBufferTexture1, uv).a;
    float3 normal = tex2D(_CameraGBufferTexture2, uv).rgb * 2 - 1;
    float oneMinusReflectivity = 1 - SpecularStrength(specularTint); //function extracts strongest color component

    UnityLight light = CreateLight(uv, worldPos, viewPos.z);
    UnityIndirect indirectLight;
    indirectLight.diffuse = 0;
    indirectLight.specular = 0;

    float4 color = UNITY_BRDF_PBS(
        albedo,
        specularTint,
        oneMinusReflectivity,
        smoothness,
        normal,
        viewDir,
        light,
        indirectLight
    );

    #if !defined(UNITY_HDR_ON)
        color = exp2(-color);
    #endif
    
    return color;
}

#endif