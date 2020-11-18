// Dear developers
// Feel free to make pull requests!
// https://github.com/sh1mc/GamingRGB
// - sh1mc
Shader "Pair/marker"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [MaterialToggle] _IsSecond ("Second", Float ) = 0
    }
    SubShader
    {
        Tags {
            "Queue" = "Geometry-100"
            "RenderType" = "Opaque"
        }
        LOD 100

        GrabPass{}

        Pass
        {
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _IsSecond;

            sampler2D _GrabTexture;
            float4 _GrabTexture_ST;
            float4 _GrabTexture_TexelSize;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                //float4 world : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //o.world = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = float4(v.uv * 2 - float2(1, 1), 0, 1);
                //UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {   
                float isID1 =    step(i.vertex.x, 1) * step(i.vertex.y, 1);
                float isID2 =    step(i.vertex.x, 1) * step(i.vertex.y, 2) * (1 - isID1);
                //step(i.vertex.y, 0) * step(0 + scale, i.vertex.y);
                float4 col =    float4(1, 0, 0, 0) * isID1 * (1 - _IsSecond) + 
                                float4(0, 1, 0, 0) * isID2 * _IsSecond;
                fixed4 o = fixed4(col);
                clip(isID1 * (1 - _IsSecond) + isID2 * _IsSecond - 0.5);
                return o;
            }
            ENDCG
        }
    }
}

