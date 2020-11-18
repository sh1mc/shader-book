Shader "Custom/raymarch"
{
    Properties
    {
        _Radius("Radius", Range(0, 1)) = 0.01 // sliders
    }
    SubShader
    {
        Tags{ "Queue" = "Transparent" }
        LOD 100

        Pass
        {
            ZTest Less
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : TEXCOORD1;
                float4 objpos : TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = v.vertex + float4(_WorldSpaceCameraPos, 1);
                o.pos.w = 1;
                //o.vertex = UnityObjectToClipPos(v.vertex);
                o.vertex = mul(UNITY_MATRIX_VP, o.pos);
                //o.pos = mul(unity_ObjectToWorld, o.vertex);
                
                o.objpos = mul(unity_ObjectToWorld, float4(0, 0, 0, 1));
                o.uv = v.uv;
                return o;
            }

            float _Radius;

            // 座標がオブジェクト内か？を返し，形状を定義する形状関数
            // 形状は原点を中心とした球．
            // 原点から一定の距離内の座標に存在するので球になる．
            /*
            bool isInObject(float3 pos) {
                return distance(pos, float3(0.0, 0.0, 0.0)) < _Threshold;
            }
            */

            float distanceSphire(float3 p, float3 v, float3 c) {
                
                float d = 0.04;
                float t = (
                    v.x * (c.x - p.x) +
                    v.y * (c.y - p.y) +
                    v.z * (c.z - p.z)
                        ) / (
                    v.x * v.x +
                    v.y * v.y +
                    v.z * v.z );
                float3 per = c - (p + t * v);
                float3 pe = float3(per.x % d, per.y % d, per.z % d);
                return length(per);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float PI = 3.1415926535;
                fixed4 col;

                // 初期の色（黒）を設定
                col.xyz = 0.0;
                col.w = 1.0;

                // レイの初期位置
                float3 pos = i.pos.xyz; 

                // レイの進行方向
                float3 forward = normalize(pos.xyz - _WorldSpaceCameraPos); 

                float d = distanceSphire(pos, forward, i.objpos);
                float r = 50 * _Radius * _Radius * _Radius;
                float isThrough = (d < r);
                float3 c = float3(
                    (sin(-_Time.y * 10 + PI * 10 * d / r) + 1) / 2,
                    (sin(-_Time.y * 10 + PI * 10 * d / r + 2 * PI / 3) + 1) / 2,
                    (sin(-_Time.y * 10 + PI * 10 * d / r + 4 * PI / 3) + 1) / 2
                );

                /*

                // レイが進むことを繰り返す．
                // オブジェクト内に到達したら進行距離に応じて色決定
                // 当たらなかったらそのまま（今回は黒）
                const int StepNum = 30;
                const float MarchingDist = 0.03;
                for (int i = 0; i < StepNum; i++) {
                    if (isInObject(pos)) {
                        col.xyz = 1.0 - i * 0.02;
                        break;
                    }
                    pos.xyz += MarchingDist * forward.xyz;
                }
                */

                clip(isThrough - 0.1);
                return fixed4(c, 0.15);
            }
            ENDCG
        }
    }
}
