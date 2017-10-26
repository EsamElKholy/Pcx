﻿Shader "PCX/Point Primitive"
{
    Properties
    {
        [HDR] _Color("Tint", Color) = (1, 1, 1, 1)
        _PointSize("Point Size", Float) = 0.05
        [Toggle] _PSize("Enable Point Size", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            CGPROGRAM

            #pragma vertex Vertex
            #pragma fragment Fragment
            #pragma multi_compile_fog
            #pragma multi_compile _ _PSIZE_ON
            #pragma multi_compile _ _COMPUTE_BUFFER

            #include "Common.cginc"

            struct Attributes
            {
                float4 position : POSITION;
                half4 color : COLOR;
            };

            struct Varyings
            {
                float4 position : SV_POSITION;
                half4 color : COLOR;
            #ifdef _PSIZE_ON
                float psize : PSIZE;
            #endif
                UNITY_FOG_COORDS(1)
            };

            half4 _Color;
            half _PointSize;

        #if _COMPUTE_BUFFER
            StructuredBuffer<float4> _PositionBuffer;
        #endif

        #if _COMPUTE_BUFFER
            Varyings Vertex(uint vid : SV_VertexID)
            {
                Varyings o;
                o.position = UnityObjectToClipPos(_PositionBuffer[vid]);
                o.color = 1;
        #else
            Varyings Vertex(Attributes input)
            {
                Varyings o;
                o.position = UnityObjectToClipPos(input.position);
                o.color = input.color * _Color;
        #endif
            #ifdef _PSIZE_ON
                o.psize = _PointSize / o.position.w * _ScreenParams.y;
            #endif
                UNITY_TRANSFER_FOG(o, o.position);
                return o;
            }

            half4 Fragment(Varyings input) : SV_Target
            {
                half4 c = input.color;
                UNITY_APPLY_FOG(input.fogCoord, c);
                return c;
            }

            ENDCG
        }
    }
}
