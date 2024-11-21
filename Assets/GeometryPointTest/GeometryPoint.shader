// Pcx - Point cloud importer & renderer for Unity
// https://github.com/keijiro/Pcx
// Esam-SCS Edit
Shader "Point Cloud/GeometryPoint"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Tint("Tint", Color) = (0.5, 0.5, 0.5, 1)
        _PointSize("Point Size", Float) = 0.05
        _Cutoff("Cutoff", Float) = 0.5
        _MipScale("Mip Scale", Range(0,1)) = 1
        [Toggle] _Distance("Apply Distance", Float) = 1
    }
    SubShader
    {
        Tags { "RenderQueue"="AlphaTest" "RenderType"="TransparentCutout" }
        Cull Off
        Pass
        {
            AlphaToMask On
            CGPROGRAM
            #pragma vertex Vertex
            #pragma geometry QuadGeometry
            #pragma fragment Fragment

            #pragma multi_compile _ UNITY_COLORSPACE_GAMMA
            #pragma multi_compile _ _DISTANCE_ON
            #pragma multi_compile _ _COMPUTE_BUFFER

            #include "UnityCG.cginc"

            struct Attributes
            {
                float4 position : POSITION;
                half3 color : COLOR;
            };

            struct VertexToGeometry
            {
                float4 position : Position;
                half3 color : COLOR;
                half2 psize : TEXCOORD0;
            };

            struct GeometryToFragment
            {
                float4 position : SV_Position;
                half3 color : COLOR;
                half2 uv : TEXCOORD0;
            };

            half4 _Tint;
            float4x4 _Transform;
            half _PointSize;
            half _Cutoff;
            half _MipScale;
            sampler2D _MainTex;
            half4 _MainTex_ST;
            float4 _MainTex_TexelSize;

            #define PCX_MAX_BRIGHTNESS 16

            uint PcxEncodeColor(half3 rgb)
            {
                half y = max(max(rgb.r, rgb.g), rgb.b);
                y = clamp(ceil(y * 255 / PCX_MAX_BRIGHTNESS), 1, 255);
                rgb *= 255 * 255 / (y * PCX_MAX_BRIGHTNESS);
                uint4 i = half4(rgb, y);
                return i.x | (i.y << 8) | (i.z << 16) | (i.w << 24);
            }

            half3 PcxDecodeColor(uint data)
            {
                half r = (data      ) & 0xff;
                half g = (data >>  8) & 0xff;
                half b = (data >> 16) & 0xff;
                half a = (data >> 24) & 0xff;
                return half3(r, g, b) * a * PCX_MAX_BRIGHTNESS / (255 * 255);
            }

        #if _COMPUTE_BUFFER
            StructuredBuffer<float4> _PointBuffer;
        #endif

        #if _COMPUTE_BUFFER
            VertexToGeometry Vertex(uint vid : SV_VertexID)
        #else
            VertexToGeometry Vertex(Attributes input)
        #endif
            {
            #if _COMPUTE_BUFFER
                float4 pt = _PointBuffer[vid];
                float4 pos = mul(_Transform, float4(pt.xyz, 1));
                half3 col = PcxDecodeColor(asuint(pt.w));
            #else
                float4 pos = input.position;
                half3 col = input.color;
            #endif

            #ifdef UNITY_COLORSPACE_GAMMA
                col *= _Tint.rgb * 2;
            #else
                col *= LinearToGammaSpace(_Tint.rgb) * 2;
                col = GammaToLinearSpace(col);
            #endif

                VertexToGeometry o;
                o.position = pos;
                o.color = col;

                half4 clipPos = UnityObjectToClipPos(pos);

            #ifdef _DISTANCE_ON
                o.psize = _PointSize / clipPos.w * _ScreenParams.y;
            #else
                o.psize = _PointSize;
            #endif

                return o;
            }

            [maxvertexcount(6)]
			void QuadGeometry(point VertexToGeometry IN[1], inout TriangleStream<GeometryToFragment> triStream)
			{
				half x = IN[0].psize.x / 2;
				half y = IN[0].psize.x / 2;

				const half4 vertices[4] =
				{
					half4(-x,  y, 0, 0), half4(x, y, 0, 0), half4(x, -y,0, 0), 
					half4(-x, -y, 0, 0)
				};

	            const int TRI_STRIP[6] =
	            {
		            0, 1, 2, 2, 3, 0
	            };

                half2 uv[4] = 
                {
                    half2(0, 1),
                    half2(1, 1),
                    half2(1, 0),                    
                    half2(0, 0)
                };
                
	            GeometryToFragment output[6];             

	            for (int i = 0; i < 4; i++)
	            {        
                    half4 pos = IN[0].position;
                    half4 rotatedVertex;                  

                    half3 forward = normalize(UNITY_MATRIX_V._m20_m21_m22);
    		        half3 up = normalize(UNITY_MATRIX_V._m10_m11_m12);
    		        half3 right = normalize(UNITY_MATRIX_V._m00_m01_m02);
                        
                    half4x4 rotationMatrix = half4x4(right, 0,
    			                                    up, 0,
    			                                    forward, 0,
    			                                    0, 0, 0, 1);
                    
                    rotatedVertex = mul(vertices[i], rotationMatrix);   

		            output[i].position = UnityObjectToClipPos(mul((float3x3)unity_WorldToObject, rotatedVertex.xyz) + pos);                   
		            output[i].color = IN[0].color;
		            output[i].uv = TRANSFORM_TEX(uv[i], _MainTex);
	            }

	            for (i = 0; i < 6 / 3; i++)
	            {
		            triStream.Append(output[TRI_STRIP[i * 3 + 0]]);
		            triStream.Append(output[TRI_STRIP[i * 3 + 1]]);
		            triStream.Append(output[TRI_STRIP[i * 3 + 2]]);

		            triStream.RestartStrip();
	            }
            }

            half CalcMipLevel(half2 texture_coord)
            {
                half2 dx = ddx(texture_coord);
                half2 dy = ddy(texture_coord);
                half delta_max_sqr = max(dot(dx, dx), dot(dy, dy));
                
                return max(0.0, 0.5 * log2(delta_max_sqr));
            }

            half4 Fragment(GeometryToFragment input) : SV_Target
            {
                // sample the texture
                half4 col = tex2D(_MainTex, input.uv);

                col = half4(input.color, _Tint.a) * col;
                col.a *= 1 + max(0, CalcMipLevel(input.uv * _MainTex_TexelSize.zw)) * _MipScale;
                col.a = (col.a - _Cutoff) / max(fwidth(col.a), 0.0001) + 0.5;
                
                return col;
            }

            ENDCG
        }
    }
    CustomEditor "CustomMaterialInspector"
}
