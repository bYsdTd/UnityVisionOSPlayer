// 偏振电影幕布材质，支持左右格式或上下格式的3d视频，需每帧同步centerEye位置
Shader "MovieCurtain/Polarized3D"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LRorTB ("LR or TB", Int) = 0
        _CenterEyePos ("Center eye pos", Vector) = (0, 0, 0, 1)
        _Force2D ("Force 2D", Int) = 0
        _Alpha("Alpha",Range(0,1)) = 1
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
            int _LRorTB;
            float4 _CenterEyePos;
            int _Force2D;
            float _Alpha;
            v2f vert (appdata_t v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                // fixed3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                // fixed3 viewDir = UnityWorldSpaceViewDir(worldPos);
                // fixed3 centerEyeDir = fixed3(_CenterEyePos.x, _CenterEyePos.y, _CenterEyePos.z) - worldPos;
                // fixed3 crossCenterEyeDir = cross(viewDir, centerEyeDir); 
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                // todo 改成step
                if (_LRorTB == 0)
                {
                    if (_Force2D == 1)
                    {
                        o.texcoord.x = o.texcoord.x * 0.5;
                    }
                    else
                    {
                        o.texcoord.x = o.texcoord.x * 0.5 + step(0.5, unity_StereoEyeIndex) * 0.5;
                    }
                }
                else
                {
                    if (_Force2D == 1)
                    {
                        o.texcoord.y = o.texcoord.y * 0.5;
                    }
                    else
                    {
                        o.texcoord.y = o.texcoord.y * 0.5 + step(0.5, 1 - unity_StereoEyeIndex) * 0.5;
                    }
                }
                return o;
            }
             
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.texcoord);
                col.a *= _Alpha;
                return col;
            }
        ENDCG
        }
    }
 

}
