Shader "Custom/geomtest1"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [MaterialToggle] _Decol ("Decolorization", Float ) = 1
    }
    SubShader
    {
        Tags { "Queue" = "AlphaTest"
            "RenderType" = "TransparentCutoff" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha


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
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 col : TEXCOORD1;
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
                return frac(sin(dot(co.xy, float2(12.9898,78.233))) * 43758.5453);
            }

            [maxvertexcount(4)]
            void geom(triangleadj v2g input[6], inout TriangleStream<g2f> outStream)
            {
                float PI = 3.14159265358;
                float r1 = rand(float2(input[0].vertex.x + input[0].vertex.y, input[0].vertex.z)) * 2 - 1;
                float r2 = rand(float2(input[1].vertex.y + input[1].vertex.z, input[0].vertex.x)) * 2 - 1;
                float r3 = rand(float2(input[2].vertex.z + input[2].vertex.x, input[3].vertex.y)) * 2 - 1;
                float3 ini = float3(r1, r2, r3); 
                float thetax = sin(pow(sin(_Time.y * ini.x * 1.5), 2) * PI) + ini.x;
                float thetay = _Time.y + ini.y * 0.8;
                float3x3 Rx = float3x3(
                1, 0, 0,
                0, cos(thetax), -sin(thetax),
                0, sin(thetax), cos(thetax)
                );
                float3x3 Ry = float3x3(
                cos(thetay), 0, sin(thetay),
                0, 1, 0,
                -sin(thetay), 0, cos(thetay)
                );
                /*
                float3 v1 = input[1].vertex.xyz - input[0].vertex.xyz;
                float3 v2 = input[2].vertex.xyz - input[0].vertex.xyz;
                float3 n = normalize(cross(v1, v2));
                */
                
                g2f o;
                o.col = float4(
                    (sin(ini.x * PI) + 1) / 2,
                    (sin(ini.y * PI) + 1) / 2,
                    (sin(ini.z * PI) + 1) / 2,
                     1);
                //o.uv = input[0].uv;
                //float3 ve = mul(mul(Rx, Ry), (input[i].vertex + n * 0.1 * e + input[i].vertex * r * 50));
                //o.vertex = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_MV, float4(0, 0, 0, 1)) + float4(ve.x, ve.y, 0, 0));
                o.vertex = UnityObjectToClipPos(
                    mul(mul(Rx, Ry),
                    (ini * 0.00015 + ini / length(ini) * 0.00015)
                    ));

                float SCALE = 0.0012;
                o.uv = float2(-1, -1);
                outStream.Append(o);
                o.vertex.x += SCALE;
                o.uv = float2(-1, 1);
                outStream.Append(o);
                o.vertex.x -= SCALE;
                o.vertex.y += SCALE;
                o.uv = float2(1, -1);
                outStream.Append(o);
                o.vertex.x += SCALE;
                o.uv = float2(1, 1);
                outStream.Append(o);
                outStream.RestartStrip();
            }

            fixed4 frag(g2f i) : SV_Target
            {
                float l = length(i.uv);
                clip(1 - l);
                return i.col;
            }
            ENDCG
        }
    }
}