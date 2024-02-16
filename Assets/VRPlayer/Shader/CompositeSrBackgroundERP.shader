Shader "ERPSR/CompositeSrBackgroundERP"
{
    Properties
    {
         _Background ("Background Texture", 2D) = "white" {}
        _SrResult ("SR Result Texture", 2D) = "white" {}

        _LRorTBor2D ("LRorTBor2D", Int) = 2
        _Force2D ("Force 2D", Int) = 0
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
    	LOD 100
    	ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "ShareColor.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

           struct v2f
            {
                float2 textureCoords : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 layout3DScaleAndOffset : TEXCOORD1;
                float4 cropAreaScaleAndOffset : TEXCOORD2;

                UNITY_VERTEX_OUTPUT_STEREO
            };

            uniform int _LRorTBor2D;
            uniform float4 Border0;
            uniform float4 ScaleOffset0;
            uniform float2 textureScale;
			uniform float2 _Divide;
            int _Force2D;

            sampler2D _Background;
            sampler2D _SrResult;

            v2f vert (appdata v)
            {
              v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                // UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.textureCoords = v.uv;


                if (_LRorTBor2D == 0) {
                    if (_Force2D)
                    {
                        o.layout3DScaleAndOffset = float4(0, 0, 0.5, 1); 
                    }
                    else
                    {
                        o.layout3DScaleAndOffset = float4(unity_StereoEyeIndex, 0, 0.5, 1);
                    }
                } else if (_LRorTBor2D == 1) {
                    if (_Force2D)
                    {
                        o.layout3DScaleAndOffset = float4(0, 1, 1, 0.5);
                    }
                    else
                    {
                        o.layout3DScaleAndOffset = float4(0, 1 - unity_StereoEyeIndex, 1, 0.5);
                    }
                } else {
                    o.layout3DScaleAndOffset = float4(0,0,1,1);
                }

                if(_LRorTBor2D == 0 || _LRorTBor2D == 1) {
                    if (_Force2D)
                    {
                        o.cropAreaScaleAndOffset = float4(0, 0, 0.5, 1);
                    }
                    else
                    {
                        o.cropAreaScaleAndOffset = float4(unity_StereoEyeIndex, 0, 0.5, 1);
                    }
                } else {
                    o.cropAreaScaleAndOffset = float4(0, 0,1,1);
                }

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                // return lerp(float4(255,0,0,0), float4(0,255,0,0), unity_StereoEyeIndex);
                float2 outTexCoord = i.textureCoords;
              	float4 outColor;
				int1 insideleft = step(Border0.x + _Divide.x,outTexCoord.x);
				int1 insideright = step(outTexCoord.x,Border0.y - _Divide.x);
				int1 insidedbottom = step(Border0.z + _Divide.y,outTexCoord.y);
				int1 insidetop = step(outTexCoord.y,Border0.w - _Divide.y);
				int1 inside = insideleft * insideright * insidedbottom * insidetop;
				if (inside) {
					outTexCoord = (outTexCoord - ScaleOffset0.zw) / ScaleOffset0.xy;
                    outTexCoord = ((outTexCoord + i.cropAreaScaleAndOffset.xy) * i.cropAreaScaleAndOffset.zw) * textureScale;
                    outColor = tex2Dlod(_SrResult, float4(outTexCoord, 0, 0));
				} else {
					outTexCoord = (outTexCoord + i.layout3DScaleAndOffset.xy) * i.layout3DScaleAndOffset.zw;
                    outColor = tex2Dlod(_Background, float4(outTexCoord, 0, 0));
				}
                
                outColor = float4(colorShift(outColor.rgb), outColor.a);
                #if !UNITY_COLORSPACE_GAMMA
                    outColor = pow(abs(outColor), 2.2);
                #endif
                
                return outColor;
            }
            ENDCG
        }
    }
    
}
