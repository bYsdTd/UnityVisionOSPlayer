Shader "Unlit/ViewPortCrop"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Cull off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float positionX : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 ScaleOffset0;
            float4 ScaleOffset1;
            float4 ScaleOffset2;
            float4 ScaleOffset3;
            float4 ScaleOffset4;
            float4 ScaleOffset5;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = v.vertex;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.positionX = o.vertex.x;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float rectCount = 6.0;
                float u = (i.positionX + 1.0) / 2.0;
                float2 uv = float2(i.uv.x, 1.0 - i.uv.y);
                if (u > 0.0 / rectCount && u <= 1.0 / rectCount)
                {
                    return tex2D(_MainTex, uv * ScaleOffset0.xy + ScaleOffset0.zw);
                }
                else if (u > 1.0 / rectCount && u <= 2.0 / rectCount)
                {
                    return tex2D(_MainTex, uv * ScaleOffset1.xy + ScaleOffset1.zw);
                }
                else if (u > 2.0 / rectCount && u <= 3.0 / rectCount)
                {
                    return tex2D(_MainTex, uv * ScaleOffset2.xy + ScaleOffset2.zw);
                }
                else if (u > 3.0 / rectCount && u <= 4.0 / rectCount)
                {
                    return tex2D(_MainTex, uv * ScaleOffset3.xy + ScaleOffset3.zw);
                }
                else if (u > 4.0 / rectCount && u <= 5.0 / rectCount)
                {
                    return tex2D(_MainTex, uv * ScaleOffset4.xy + ScaleOffset4.zw);
                }
                else if (u > 5.0 / rectCount && u <= 6.0 / rectCount)
                {
                    return tex2D(_MainTex, uv * ScaleOffset5.xy + ScaleOffset5.zw);
                }
                
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                
                return col;
            }
            ENDCG
        }
    }
}
