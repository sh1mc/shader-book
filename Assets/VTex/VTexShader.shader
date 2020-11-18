Shader "VTex/VTexShader"
{
    Properties
    {
        _FonTex ("Font Texture", 2D) = "white" {}
        _TexTex ("Book Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
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
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _FonTex;
            float4 _FonTex_ST;
            sampler2D _TexTex;
            float4 _TexTex_ST;
            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _TexTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {   
                float LINEWIDTH = 64;
                float LINEHEIGHT = 64;
                float BOOKWIDTH = 1024;
                float BOOKHEIGHT = 1024;
                float FONTEXWIDTH = 2048;
                float FONTEXHEIGHT = 2048;
                float FONTWIDTH = 32;
                float FONTHEIGHT = 32;

                float2 xy = float2(i.uv.x * LINEWIDTH, (i.uv.y) * LINEHEIGHT);
                float charaindex = floor(LINEHEIGHT - xy.y) * LINEWIDTH + floor(xy.x) + floor(_Time.y * 7) % 6000 * LINEWIDTH;//+ (floor(_Time.y * 10) % 1000) * LINEWIDTH;
                float2 charaxy = float2((charaindex % BOOKWIDTH + 0.4) / BOOKWIDTH, 1 - (floor(charaindex / BOOKWIDTH) + 0.4) / BOOKHEIGHT);
                float4 characol = tex2D(_TexTex, charaxy);
                float unicode = floor(characol.g * 256 + 0.4) * 256 + floor(characol.b * 256 + 0);
                //float unicode = 1; //test
                float2 fontxy = float2(floor(((xy.x % 1.0)) * FONTWIDTH), floor((1 - (xy.y % 1.0)) * FONTHEIGHT));
                float fontcolindex = unicode * 32 + fontxy.y;
                float2 fontexxy = float2((fontcolindex % FONTEXWIDTH) / FONTEXHEIGHT,  1 - (fontcolindex / FONTEXWIDTH) / FONTEXWIDTH);
                float4 fontcol = tex2D(_FonTex, fontexxy);
                int fontbyte = (int)(fontcol[floor(fontxy.x / 8)] * 256);
                int fontbitindex = (int)(floor(fontxy.x) % 8);

                int bitindex = 7 - (fontxy.x % 8);
                int mask = (0x0000000f << bitindex);
                int fontbit = ((fontbyte & mask) >> bitindex);
                
                float c = clamp(fontbit, 0, 1);

                float4 o = float4(c, c, c, 1);
                //clip(o.a - 0.01);
                return o;
            }
            ENDCG
        }
    }
}