Shader "ERP2D/Transparent"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MaskColor ("Mask Color", Color) = (0,0,0,0)
    }
    SubShader {
    Tags {"Queue"="Transparent-200" "IgnoreProjector"="True" "RenderType"="Transparent" "ForceNoShadowCasting"="True" "PreviewType"="Plane"}
    LOD 100

    ZWrite Off
    Blend SrcAlpha OneMinusSrcAlpha 

    Pass {  
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "ShareColor.cginc"

            struct appdata_t {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                half2 texcoord : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _MaskColor;

            v2f vert (appdata_t v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.texcoord);
                fixed4 result = col * (1 - _MaskColor.a) + _MaskColor * _MaskColor.a;
                result.a = 1;
                return result;
            }
        ENDCG
        }
    }


}