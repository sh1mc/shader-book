Shader "VTex/VTexShaderP"
{
    Properties
    {
        _FonTex ("Font Texture", 2D) = "white" {}
        _TexTex ("Book Texture", 2D) = "white" {}
        _Page ("Page", Float) = 0
        [MaterialToggle] _IsDark ("Dark Mode", Float ) = 0
        [MaterialToggle] _IsHorizontal ("Horizontal", Float ) = 0
        _Aspect ("Aspect Ratio", Range(0.2, 5)) = 1.4
        _LineWidth ("Line Width", Range(1, 300)) = 32
        _LineHeight ("Line Height", Range(1, 300)) = 32
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
            float _Page;
            float _IsDark;
            float _IsHorizontal;
            float _Aspect;
            float _LineWidth;
            float _LineHeight;
            
            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _TexTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {   
                float MARGIN = 0.02;
                float scale = 1;

                float MARGIN_TOP = 13;
                float MARGIN_BOTTOM = 14;
                float XHEIGHT = 1;
                float YHEIGHT = 1;
                float LINEWIDTH = floor(_LineWidth);
                float LINEHEIGHT = floor(_LineHeight);
                float IS_HORIZONTAL = _IsHorizontal;
                float2 xy = float2(i.uv.x / XHEIGHT * LINEWIDTH, (i.uv.y / YHEIGHT) * LINEHEIGHT) + float2(0, -MARGIN_TOP);
                float iswithinpage = step(-0.1, xy.x * xy.y) * step(MARGIN_BOTTOM, LINEHEIGHT - xy.y);
                xy = IS_HORIZONTAL * xy + (1 - IS_HORIZONTAL) * float2(LINEHEIGHT - xy.y, xy.x);

                float BOOKWIDTH = 1024;
                float BOOKHEIGHT = 1024;
                float PAGE = _Page;
                float charaindex = floor(LINEHEIGHT - xy.y - 1) * (LINEWIDTH - MARGIN_BOTTOM) - (MARGIN_TOP + 1) + floor(xy.x) + LINEWIDTH * (LINEHEIGHT - MARGIN_BOTTOM) * floor(PAGE + 0.5);
                float2 charaxy = float2((charaindex % BOOKWIDTH + 0.4) / BOOKWIDTH, 1 - (floor(charaindex / BOOKWIDTH) + 0.4) / BOOKHEIGHT);
                float4 characol = tex2D(_TexTex, charaxy);
                float unicode = floor(characol.g * 256 + 0.4) * 256 + floor(characol.b * 256 + 0);

                float FONTWIDTH = 32;
                float FONTHEIGHT = 32;
                float LINESPACE = 15;
                float CHARSPACE = 6;
                float2 fontxy = float2(floor(((xy.x % 1.0)) * (FONTWIDTH + CHARSPACE)), floor((1 - (xy.y % 1.0)) * (FONTHEIGHT + LINESPACE)));
                fontxy = IS_HORIZONTAL * fontxy + (1 - IS_HORIZONTAL) * float2(FONTWIDTH - fontxy.y, fontxy.x);

                float FONTEXWIDTH = 2048;
                float FONTEXHEIGHT = 2048;
                float fontcolindex = unicode * 32 + fontxy.y;
                float2 fontexxy = float2((fontcolindex % FONTEXWIDTH) / FONTEXHEIGHT,  1 - (fontcolindex / FONTEXWIDTH) / FONTEXWIDTH);
                float4 fontcol = tex2D(_FonTex, fontexxy);
                int fontbyte = (int)(fontcol[floor(fontxy.x / 8)] * 256);
                int fontbitindex = (int)(floor(fontxy.x) % 8);

                int bitindex = 7 - (fontxy.x % 8);
                int mask = (0x0000000f << bitindex);
                int fontbit = ((fontbyte & mask) >> bitindex);
                
                float IS_DARK = _IsDark;
                
                float iswithinfont = 1 - clamp( step(FONTWIDTH - 0.1, fontxy.x) + 
                                                step(FONTHEIGHT - 0.1, fontxy.y) + 
                                                step(fontxy.x, -0.1) +
                                                step(fontxy.y, -0.1)
                                                , 0, 1);
                float c = clamp(fontbit, 0, 1) * iswithinpage * iswithinfont;
                c = IS_DARK * c + (1 - IS_DARK) * (1 - c);

                float4 o = float4(c, c, c, 1);
                return o;
            }
            ENDCG
        }
    }
}