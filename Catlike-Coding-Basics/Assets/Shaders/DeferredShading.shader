Shader "Custom/DeferredShading" {
    Properties {
    }

    SubShader {
        Pass {
            Blend [_SrcBlend] [_DstBlend] //blend variable to support both LDR and HDR
            ZWrite Off

            CGPROGRAM
                #pragma target 3.0
                #pragma vertex vert
                #pragma fragment frag

                #pragma exclude_renderers nomrt

                #pragma multi_compile_lightpass
                #pragma multi_compile _ UNITY_HDR_ON

                #include "MyDeferredShading.cginc"

            ENDCG
        }

        Pass {
            Cull Off
            ZTest Always
            ZWrite Off

            Stencil {
                Ref [_StencilNonBackground]
                ReadMask [_StencilNonBackground]
                CompBack Equal
                CompFront Equal
            }

            CGPROGRAM
                #pragma target 3.0
                #pragma vertex vert
                #pragma fragment frag

                #pragma exclude_renderers nomrt

                #include "UnityCG.cginc"

                sampler2D _LightBuffer;

                struct appdata {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                };

                struct v2f {
                    float4 pos : SV_POSITION;
                    float2 uv : TEXCOORD0;
                };

                v2f vert(appdata v) {
                    v2f i;
                    i.pos = UnityObjectToClipPos(v.vertex);
                    i.uv = v.uv;
                    return i;
                }

                float4 frag(v2f i) : SV_Target {
                    return -log2(tex2D(_LightBuffer, i.uv));
                }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
