// Dear developers
// Feel free to make pull requests!
// https://github.com/sh1mc/GamingRGB
// - sh1mc
Shader "Pair/test"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [MaterialToggle] _IsSecond ("Second", Float ) = 0
    }
    SubShader
    {
        Tags {
            "Queue" = "Geometry-95"
            "RenderType" = "TransparentCutoff"
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
                float4 world : TEXCOORD1;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _GrabTexture);
                o.world = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }

            float2 pos2texel(float x, float y) {
                return float2(
                    x * _GrabTexture_TexelSize.x,
                    -y * _GrabTexture_TexelSize.y);
            }

            fixed4 frag (v2f i) : SV_Target
            {   
                float4 ID1 = tex2D(_GrabTexture, pos2texel(0.5, 0.5));
                float4 ID2 = tex2D(_GrabTexture, pos2texel(0.5, 1.5));
                float is1 = (ID1 == float4(1, 0, 0, 0));
                float is2 = (ID2 == float4(0, 1, 0, 0));
                
                return fixed4(is1, is2, 0, 0);
            }
            ENDCG
        }
    }
}
