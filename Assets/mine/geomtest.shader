Shader "Custom/geomtest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [MaterialToggle] _Decol ("Decolorization", Float ) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100

        Pass
        {
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geom

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2g
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            struct g2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2g vert(appdata v)
            {
                v2g o;
                o.vertex = v.vertex;
                o.uv = v.uv;
                return o;
            }

            float rand(float2 co){
                return frac(sin(dot(co.xy, float2(12.9898111,78.23333))) * 43758.545311);
            }

            float ease(float t) {
                float s = sin(t * 2) + 1;
                return pow(1.5, s) * 0.5;
            }

            [maxvertexcount(3)]
            void geom(triangle v2g input[3], inout TriangleStream<g2f> outStream)
            {
                float thetax = sin(_Time.y * input[0].vertex.y * 2);
                float3x3 Rx = float3x3(
                1, 0, 0,
                0, cos(thetax), -sin(thetax),
                0, sin(thetax), cos(thetax)
                );
                float thetay = _Time.y;
                float3x3 Ry = float3x3(
                cos(thetay), 0, sin(thetay),
                0, 1, 0,
                -sin(thetay), 0, cos(thetay)
                );
                float3 v1 = input[1].vertex.xyz - input[0].vertex.xyz;
                float3 v2 = input[2].vertex.xyz - input[0].vertex.xyz;
                float3 n = normalize(cross(v1, v2));
                float r = rand(float2(input[0].vertex.x + input[0].vertex.y, input[0].vertex.z));
                float e = ease(_Time.y);
                /*
                [unroll]
                for (int i = 0; i < 3; i++)
                {
                    appdata v = input[i];
                    g2f o;
                    o.uv = input[i].uv;
                    o.vertex = UnityObjectToClipPos(mul(mul(Rx, Ry), (input[i].vertex + n * 0.0002 * e + input[i].vertex * r * 10) * 0.1));
                    outStream.Append(o);
                }
                */
                g2f o;
                o.uv = input[0].uv;
                o.vertex = UnityObjectToClipPos(mul(mul(Rx, Ry), (input[0].vertex + n * 0.0002 * e + input[0].vertex * r * 10) * 0.09));
                outStream.Append(o);
                o.vertex += float4(0.03, 0, 0, 0);
                outStream.Append(o);
                o.vertex += float4(0, 0.03, 0, 0);
                outStream.Append(o);
                outStream.RestartStrip();
            }

            fixed4 frag(v2g i) : SV_Target
            {
                float3 col = (sin(float3(i.vertex.x + i.vertex.y, i.vertex.y + i.vertex.z, i.vertex.z + i.vertex.x) * 0.011) + 1) / 2;
                return float4(col , 1);
            }
            ENDCG
        }

    }
}