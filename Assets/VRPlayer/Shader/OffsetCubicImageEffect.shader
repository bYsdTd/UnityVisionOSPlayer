Shader "CubeOffset/OffsetCubicImageEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Enum(360 Degrees, 0, 180 Degrees, 1)] _ImageType("Image Type", Float) = 0
        [Enum(None, 0, Side by Side, 1, Over Under, 2)] _Layout("3D Layout", Float) = 0
        expandCoef ("expandCoef", float) = 1.01
        layoutType ("layoutType", Int) = 0
        //default CMP
        layoutFormat ("layoutFormat", Int) = 0
        _Force2D ("Force 2D", Int) = 0
    }
    SubShader
    {
        // 因为这个屏幕模型不会用在高光上，所以可以用这个渲染序列
        Tags {"Queue"="Background" "IgnoreProjector"="True" "RenderType"="Transparent"}
        LOD 100
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

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

                UNITY_VERTEX_OUTPUT_STEREO
            };

            //不同的offset方向需要不同的旋转角度
            uniform float4x4 offsetRot;
            //重叠系数，目前使用1.01
            uniform float expandCoef;
            //offset偏移值，目前使用z轴偏移0.4
            uniform float4 zOffset;
            //视频维度，0:2D视频；1:3D左右；2:3D上下
            uniform int layoutType;
            //视频格式，0:CMP; 1:EAC
            uniform int layoutFormat;
            // 强制2D
            uniform  int _Force2D;

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
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                //这里除了mvp变换外，还需要一个额外的旋转量，这个旋转量是根据外界设置的值变动的
                o.vertex = UnityObjectToClipPos(mul(offsetRot,v.vertex));
                o.verPosition = v.vertex.xyz;

                if (layoutType == 0) {
                    o.layout3DScaleAndOffset = float4(0,0,1,1);
                } else if (layoutType == 1) {
                    if (_Force2D == 1)
                    {
                        o.layout3DScaleAndOffset = float4(1, 0, 0.5, 1);
                    } else
                    {
                        o.layout3DScaleAndOffset = float4(unity_StereoEyeIndex, 0, 0.5, 1);
                    }
                } else {
                    if (_Force2D == 1)
                    {
                        o.layout3DScaleAndOffset = float4(0, 0, 1, 0.5);
                    } else
                    {
                        o.layout3DScaleAndOffset = float4(0, 1 - unity_StereoEyeIndex, 1, 0.5);
                    }
                }
                return o;
            }

            sampler2D _MainTex;
            // uniform int frontCenterMark;

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
                if (layoutFormat == 1) {
                    result = atan(result) / UNITY_PI * 4.0;
                }
                result.x = (result.x + 1.0 + 2 * texOffset[index].x) / 6.0;
                result.y = (result.y + 1.0 + 2 * texOffset[index].y) / 4.0;
                return result;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(1, 0, 0, 1);
                float3 normalizeCoords = normalize(i.verPosition);

                //process offset
                normalizeCoords = normalizeCoords - zOffset.xyz;
                normalizeCoords = normalizeCoords / max(max(abs(normalizeCoords.x),abs(normalizeCoords.y)),abs(normalizeCoords.z));
                
                float2 outTexCoord = cubeToTexture(normalizeCoords, expandCoef);
                outTexCoord = (outTexCoord + i.layout3DScaleAndOffset.xy) * i.layout3DScaleAndOffset.zw;
                // if (frontCenterMark == 1) {
                //     return float4(256,0,0,1);
                // }
                // return tex2D(_MainTex, outTexCoord);
                float4 oriColor = tex2Dlod(_MainTex, float4(outTexCoord, 0, 0));
                return oriColor;
            }

            ENDCG
        }
    }
}
