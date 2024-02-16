// 给eyebuffer挖洞的shader
Shader "Pico/PXR_HoleDigger"
{
	Properties
	{
//	    _MainTex("Texture(A)", 2D) = "black" {}
//	    _Cutoff  ("Cutoff", Float) = 0.3
//	    _UorV ("Cutoff based on u or v", Int) = 0
	    _MaskColor ("Mask Color", Color) = (0,0,0,0)
	}
	SubShader {
	    Tags {"Queue"="Geometry-1" "RenderType"="Opaque"}
	    LOD 100
     
	    Lighting Off
	    ZWrite On
//	    Blend Zero One
//        Stencil {
//            Ref 1
//            Comp Always
//            Pass Replace
//            Fail Keep
//        }
     Pass {  
         CGPROGRAM
             #pragma vertex vert
             #pragma fragment frag
             #include "UnityCG.cginc"
 
             struct appdata_t {
                 float4 vertex : POSITION;
                 // float2 texcoord : TEXCOORD0;
             };
 
             struct v2f {
                 float4 vertex : SV_POSITION;
                 // half2 texcoord : TEXCOORD0;
             };
 
             // sampler2D _MainTex;
             // float4 _MainTex_ST;
             // float _Cutoff;
             // int _UorV;
            fixed4 _MaskColor;

             
             v2f vert (appdata_t v)
             {
                 v2f o;
                 o.vertex = UnityObjectToClipPos(v.vertex);
                 // o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                 return o;
             }
             
             fixed4 frag (v2f i) : SV_Target
             {
                 // fixed4 col = tex2D(_MainTex, i.texcoord);
                 // todo 改成step
                 // if (_UorV == 0)
                 // {
                 //     if (i.texcoord.x < _Cutoff || i.texcoord.x > (1 - _Cutoff))
                 //     {
                 //         col.a = 0;
                 //     }    
                 // }
                 // else
                 // {
                 //     if (i.texcoord.y < _Cutoff || i.texcoord.y > (1 - _Cutoff))
                 //     {
                 //         col.a = 0;
                 //     }
                 // }
                 //
                 // clip(col.a - 0.9);
                 return _MaskColor;
             }
         ENDCG
     }
 }
	
}
