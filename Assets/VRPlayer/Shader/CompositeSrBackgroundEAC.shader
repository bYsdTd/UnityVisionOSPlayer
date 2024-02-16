Shader "Unlit/CompositeSrBackgroundEAC"
{
    Properties
    {
        _Background ("Background Texture", 2D) = "white" {}
        _SrResult ("SR Result Texture", 2D) = "white" {}

        _SrPixelOffset("_SrPixelOffset", float) = 1.0
        _ExpandCoef ("expandCoef", float) = 1.01
        _LRorTBor2D ("LRorTBor2D", Int) = 2
        //0:CMP 1:EAC
        _LayoutFormat ("layoutFormat", Int) = 1
        _Force2D ("Force 2D", Int) = 0
    }
    SubShader
    {
 		//Tags { "RenderType"="Opaque" }
        Tags {"Queue"="Background" "IgnoreProjector"="True" "RenderType"="Transparent"}
        LOD 100

        Cull Off ZWrite Off ZTest Always
        //ZWrite Off 
        //ZTest Always
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
                float3 verPosition : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 layout3DScaleAndOffset : TEXCOORD1;
                float4 cropAreaScaleAndOffset : TEXCOORD2;

                UNITY_VERTEX_OUTPUT_STEREO
            };

            //不同的offset方向需要不同的旋转角度
            uniform float4x4 offsetRot;
            //重叠系数，目前使用1.01
            uniform float _ExpandCoef;
            //offset偏移值，目前使用z轴偏移0.4
            uniform float4 zOffset;
            //视频维度，0:3D左右；1:3D上下；2:2D视频
            uniform int _LRorTBor2D;
            //视频格式，0:CMP; 1:EAC
            uniform int _LayoutFormat;
             // 强制2D
            uniform  int _Force2D;

            uniform float4 Border0;
            uniform float4 Border1;
            uniform float4 Border2;
            uniform float4 Border3;
            uniform float4 Border4;
            uniform float4 Border5;

            uniform float4 ScaleOffset0;
            uniform float4 ScaleOffset1;
            uniform float4 ScaleOffset2;
            uniform float4 ScaleOffset3;
            uniform float4 ScaleOffset4;
            uniform float4 ScaleOffset5;

            float4 _SrResultSize;
            float _SrPixelOffset;
            uniform float2 textureScale;
            
            sampler2D _Background;
            sampler2D _SrResult;

            static const float2 texOffset[6] = {
                float2(0.0,1.0),
                float2(1.0, 1.0),
                float2(2.0, 1.0),
                float2(2.0, 0.0),
                float2(1.0, 0.0),
                float2(0.0, 0.0)
            };
            static const float2x2 rotates[6] = {
                float2x2(1.0,0.0,0.0,1.0),
                float2x2(1.0,0.0,0.0,1.0),
                float2x2(1.0,0.0,0.0,1.0),
                float2x2(0.0,1.0,-1.0,0.0),
                float2x2(0.0,-1.0,1.0,0.0),
                float2x2(0.0,1.0,-1.0,0.0)
            };

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                // UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                //这里除了mvp变换外，还需要一个额外的旋转量，这个旋转量是根据外界设置的值变动的
                o.vertex = UnityObjectToClipPos(mul(offsetRot,v.vertex));
                o.verPosition = v.vertex.xyz;

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
                        o.cropAreaScaleAndOffset = float4(0, 1, 1, 0.5);
                    }
                    else
                    {
                       o.cropAreaScaleAndOffset = float4(0, 1 - unity_StereoEyeIndex, 1, 0.5);
                    }
                } else {
                    o.cropAreaScaleAndOffset = float4(0, 0,1,1);
                }
                return o;
            }

            float2 cubeToTexture(float3 cubeCoord, float expand) {
                float2 result;
                float absX = abs(cubeCoord.x);
                float absY = abs(cubeCoord.y);
                float absZ = abs(cubeCoord.z);
                int index;//0:左 1:前 2:右 3:上 4:后 5:下
                if (-cubeCoord.z >= absX && -cubeCoord.z >= absY) {
                    result = float2(-cubeCoord.x, cubeCoord.y);
                    index = 4;
                } else if (cubeCoord.z >= absX && cubeCoord.z >= absY) {
                    result = float2(cubeCoord.x, cubeCoord.y);
                    index = 1;
                    // if (result.x * result.x + result.y * result.y < 0.001) {
                    //     frontCenterMark = 1;
                    // }
                } else if (cubeCoord.y >= absX && cubeCoord.y >= absZ) {
                    result = float2(cubeCoord.x, -cubeCoord.z);
                    index = 3;
                } else if (-cubeCoord.y >= absX && -cubeCoord.y >= absZ) {
                    result = float2(cubeCoord.x, cubeCoord.z);
                    index = 5;
                } else if (cubeCoord.x >= absY && cubeCoord.x >= absZ) {
                    result = float2(-cubeCoord.z, cubeCoord.y);
                    index = 2;
                } else {
                    result = float2(cubeCoord.z, cubeCoord.y);
                    index = 0;
                }
                result = mul(result, rotates[index]) / expand;
                if (_LayoutFormat == 1) {
                    result = atan(result) / UNITY_PI * 4.0;
                } 
               
                result.x = (result.x + 1.0 + 2 * texOffset[index].x) / 6.0;
                result.y = (result.y + 1.0 + 2 * texOffset[index].y) / 4.0;
                return result;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                // return lerp(float4(255,0,0,0), float4(0,255,0,0), unity_StereoEyeIndex);
                float3 normalizeCoords = normalize(i.verPosition);

                //process offset
                normalizeCoords = normalizeCoords - zOffset.xyz;
                normalizeCoords = normalizeCoords / max(max(abs(normalizeCoords.x),abs(normalizeCoords.y)),abs(normalizeCoords.z));
                
                float2 outTexCoord = cubeToTexture(normalizeCoords, _ExpandCoef);
                
                float rectCount = 4.0;
                //int sampleSR = 0;
                float oneDivideWidth = _SrPixelOffset / _SrResultSize.x;
                float oneDivideHeight = _SrPixelOffset / _SrResultSize.y;
                float4 outColor;
                //float oneDivideHeight = 0.0f;
                if (outTexCoord.x > (Border0.x + oneDivideWidth) && outTexCoord.x <= (Border0.y - oneDivideWidth) && outTexCoord.y > (Border0.z + oneDivideHeight) && outTexCoord.y <= (Border0.w - oneDivideHeight))
                {
                    outTexCoord = (outTexCoord - ScaleOffset0.zw) / ScaleOffset0.xy;
                    outTexCoord = outTexCoord * float2(1.0 / rectCount, 1.0) + float2(0.0 / rectCount, 0.0);
                    //outTexCoord.x = clamp(outTexCoord.x, 0.0, 1.0 / rectCount - oneDivideWidth);
                   outTexCoord = ((outTexCoord + i.cropAreaScaleAndOffset.xy) * i.cropAreaScaleAndOffset.zw) * textureScale;
                    //sampleSR = 1;
					outColor = tex2Dlod(_SrResult, float4(outTexCoord, 0, 0));
                    #if !UNITY_COLORSPACE_GAMMA
                    outColor = pow(abs(outColor), 2.2);
                    #endif
                    return float4(colorShift(outColor.rgb), outColor.a);
                }
                else if (outTexCoord.x > (Border1.x + oneDivideWidth) && outTexCoord.x <= (Border1.y - oneDivideWidth) && outTexCoord.y > (Border1.z + oneDivideHeight) && outTexCoord.y <= (Border1.w - oneDivideHeight))
                {
                    outTexCoord = (outTexCoord - ScaleOffset1.zw) / ScaleOffset1.xy;
                    outTexCoord = outTexCoord * float2(1.0 / rectCount, 1.0) + float2(1.0 / rectCount, 0.0);
                    //outTexCoord.x = clamp(outTexCoord.x, 1.0 / rectCount + oneDivideWidth, 2.0 / rectCount - oneDivideWidth);
                    outTexCoord = ((outTexCoord + i.cropAreaScaleAndOffset.xy) * i.cropAreaScaleAndOffset.zw) * textureScale;
                    //sampleSR = 1;
                    outColor = tex2Dlod(_SrResult, float4(outTexCoord, 0, 0));
                    #if !UNITY_COLORSPACE_GAMMA
                    outColor = pow(abs(outColor), 2.2);
                    #endif
                    return float4(colorShift(outColor.rgb), outColor.a);
                }
                else if (outTexCoord.x > (Border2.x + oneDivideWidth) && outTexCoord.x <= (Border2.y - oneDivideWidth) && outTexCoord.y > (Border2.z + oneDivideHeight) && outTexCoord.y <= (Border2.w - oneDivideHeight))
               {
                    outTexCoord = (outTexCoord - ScaleOffset2.zw) / ScaleOffset2.xy;
                    outTexCoord = outTexCoord * float2(1.0 / rectCount, 1.0) + float2(2.0 / rectCount, 0.0);
                    //outTexCoord.x = clamp(outTexCoord.x, 2.0 / rectCount + oneDivideWidth, 3.0 / rectCount - oneDivideWidth);
                    outTexCoord = ((outTexCoord + i.cropAreaScaleAndOffset.xy) * i.cropAreaScaleAndOffset.zw) * textureScale;
                    //sampleSR = 1;
                    outColor = tex2Dlod(_SrResult, float4(outTexCoord, 0, 0));
                    #if !UNITY_COLORSPACE_GAMMA
                    outColor = pow(abs(outColor), 2.2);
                    #endif
                    return float4(colorShift(outColor.rgb), outColor.a);
                }
                else if (outTexCoord.x > (Border3.x + oneDivideWidth) && outTexCoord.x <= (Border3.y - oneDivideWidth) && outTexCoord.y > (Border3.z + oneDivideHeight) && outTexCoord.y <= (Border3.w - oneDivideHeight))
                {
                    outTexCoord = (outTexCoord - ScaleOffset3.zw) / ScaleOffset3.xy;
                    outTexCoord = outTexCoord * float2(1.0 / rectCount, 1.0) + float2(3.0 / rectCount, 0.0);
                    //outTexCoord.x = clamp(outTexCoord.x, 3.0 / rectCount + oneDivideWidth, 4.0 / rectCount - oneDivideWidth);
                    outTexCoord = ((outTexCoord + i.cropAreaScaleAndOffset.xy) * i.cropAreaScaleAndOffset.zw) * textureScale;
                    //sampleSR = 1;
                    outColor = tex2Dlod(_SrResult, float4(outTexCoord, 0, 0));
                    #if !UNITY_COLORSPACE_GAMMA
                    outColor = pow(abs(outColor), 2.2);
                    #endif
                    return float4(colorShift(outColor.rgb), outColor.a);
                //}

//                else if (outTexCoord.x > (Border4.x + oneDivideWidth) && outTexCoord.x <= (Border4.y - oneDivideWidth) && outTexCoord.y > (Border4.z + oneDivideHeight) && outTexCoord.y <= (Border4.w - oneDivideHeight))
//                {
//                    outTexCoord = (outTexCoord - ScaleOffset4.zw) / ScaleOffset4.xy;
//                    outTexCoord = outTexCoord * float2(1.0 / rectCount, 1.0) + float2(4.0 / rectCount, 0.0);
//                    //outTexCoord.x = clamp(outTexCoord.x, 4.0 / rectCount + oneDivideWidth, 5.0 / rectCount - oneDivideWidth);
//                    outTexCoord = ((outTexCoord + i.cropAreaScaleAndOffset.xy) * i.cropAreaScaleAndOffset.zw) * textureScale;
//                    sampleSR = 1;
//                }
//                else if (outTexCoord.x > (Border5.x + oneDivideWidth) && outTexCoord.x <= (Border5.y - oneDivideWidth) && outTexCoord.y > (Border5.z + oneDivideHeight) && outTexCoord.y <= (Border5.w - oneDivideHeight))
//                {
//                    outTexCoord = (outTexCoord - ScaleOffset5.zw) / ScaleOffset5.xy;
//                    outTexCoord = outTexCoord * float2(1.0 / rectCount, 1.0) + float2(5.0 / rectCount, 0.0);
//                    //outTexCoord.x = clamp(outTexCoord.x, 5.0 / rectCount + oneDivideWidth, 6.0 / rectCount - oneDivideWidth);
//                    outTexCoord = ((outTexCoord + i.cropAreaScaleAndOffset.xy) * i.cropAreaScaleAndOffset.zw) * textureScale;
//                    sampleSR = 1;
                } else {
                    outTexCoord = (outTexCoord + i.layout3DScaleAndOffset.xy) * i.layout3DScaleAndOffset.zw;
                    outColor = tex2Dlod(_Background, float4(outTexCoord, 0, 0));
                    #if !UNITY_COLORSPACE_GAMMA
                    outColor = pow(abs(outColor), 2.2);
                    #endif
                    return float4(colorShift(outColor.rgb), outColor.a);
                }
//                if (sampleSR == 0)
//                {
//                    return tex2Dlod(_Background, float4(outTexCoord, 0, 0));
//                }
//                else
//                {
//                    return tex2Dlod(_SrResult, float4(outTexCoord, 0, 0));
//                    //return fixed4(1.0,0.0,0.0,0.0);
//                }
            }

            ENDCG
        }
    }
}
