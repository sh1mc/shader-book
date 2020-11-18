Shader "Custom/gpuparticle1"
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

            float3x3 rotateX(float theta) {
                return float3x3(
                1, 0, 0,
                0, cos(theta), -sin(theta),
                0, sin(theta), cos(theta)
                );
            }

            float3x3 rotateY(float theta) {
                return float3x3(
                cos(theta), 0, sin(theta),
                0, 1, 0,
                -sin(theta), 0, cos(theta)
                );
            }

            float3x3 rotateZ(float theta) {
                return float3x3(
                cos(theta), -sin(theta), 0,
                sin(theta), cos(theta), 0,
                0, 0, 1
                );
            }

            float3x3 rodrigues(float3 n, float theta) {
                return float3x3(
                    n.x * n.x * (1 - cos(theta)) + cos(theta),
                    n.x * n.y * (1 - cos(theta)) - n.z * sin(theta),
                    n.x * n.z * (1 - cos(theta)) + n.y * sin(theta),
                    n.x * n.y * (1 - cos(theta)) + n.z * sin(theta),
                    n.y * n.y * (1 - cos(theta)) + cos(theta),
                    n.y * n.z * (1 - cos(theta)) - n.x * sin(theta),
                    n.x * n.z * (1 - cos(theta)) - n.y * sin(theta),
                    n.y * n.z * (1 - cos(theta)) + n.x * sin(theta),
                    n.z * n.z * (1 - cos(theta)) + cos(theta)
                );
            }

            float3 curve(float3 pos, float theta) {
                return mul(mul(mul(rotateZ(theta * 13), rotateY(theta * 16)), rotateX(theta * 17)), pos);
            }

            [maxvertexcount(4)]
            void geom(triangleadj v2g input[6], inout TriangleStream<g2f> outStream)
            {
                float PI = 3.14159265358;
                float r1 = rand(float2(input[0].vertex.x + input[0].vertex.y, input[0].vertex.z)) * 2 - 1;
                float r2 = rand(float2(input[1].vertex.y + input[1].vertex.z, input[0].vertex.x)) * 2 - 1;
                float r3 = rand(float2(input[2].vertex.z + input[2].vertex.x, input[3].vertex.y)) * 2 - 1;
                float3 random = float3(r1, r2, r3);
                float DISPERSION = 0.000023;
                float3 randpos = random * DISPERSION; 
                float isFirst = step(input[0].uv.y, 0.5);
                float isAround = step(input[0].uv.x, 0.5);
                float RADIUS = 0.0003;
                float3 inipos = (randpos + RADIUS * float3(1, 1, 1)) * (isFirst - (1 - isFirst));
                
                float l = length(inipos);
                float dt = 0.05;
                float theta = _Time.y * 0.4 + l * 9000;
                float dtheta = (_Time.y + dt) * 0.4 + l * 9000;

                float3 posnormal = normalize(inipos);
                float pos = posnormal * RADIUS * (1 + ((sin(theta * 4) - 1) / 2 * 0.7));
                float3 n = normalize(curve(pos, dtheta) - curve(pos, theta));
                float3 aroundvec = posnormal * mul(rodrigues(n, theta * 80), RADIUS * posnormal * isAround * 0.15);
                pos += aroundvec * isAround;
                
                g2f o;
                float colscale = 100000;
                o.col = float4(
                    (sin(l * colscale) + 1) / 2,
                    (sin(l * colscale + 2 * PI / 3) + 1) / 2,
                    (sin(l * colscale + 4 * PI / 3) + 1) / 2,
                     1);
                o.col = clamp(o.col + float4(1 - isAround, 1 - isAround, 1 - isAround, 0), 0, 1);

                float AroundLatency = 1;
                float3 c = curve(pos, theta - isAround * AroundLatency);
                o.vertex = UnityObjectToClipPos(
                    mul(rotateY(_Time.y * 0.8), c)
                );

                float SCALE = 0.001;
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