Shader "MomomaShader/Raymarching/MeltBall"
{
	Properties
	{
		_Color ("Main Color", Color) = (0.8, 0.8, 0.8, 1)
		_Glossiness ("Smoothness", Range(0, 1)) = 0.5
		_Metallic ("Metallic", Range(0, 1)) = 0.5
		[NoScaleOffset] _MatcapTexture ("MatCap Texture", 2D) = "white" {}
		_Size ("Sphere Size", Range(0, 10)) = 0.1
		[Enum(Sphere, 0, Box, 1, Torus, 2, Hexagonal Prism, 3, Capsule, 4, Cylinder, 5, Octahedron, 6)] _Shape0 ("Shape0", Float) = 0
		[Enum(Sphere, 0, Box, 1, Torus, 2, Hexagonal Prism, 3, Capsule, 4, Cylinder, 5, Octahedron, 6)] _Shape1 ("Shape1", Float) = 0
	}
	SubShader
	{
		Tags { "RenderType" = "TransparentCutout" "Queue" = "AlphaTest" "IgnoreProjector" = "True" "DisableBatching" = "True" }
		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			#include "AutoLight.cginc"

			sampler2D _MatcapTexture;
			fixed4 _Color;
			fixed _Glossiness, _Metallic;
			fixed _Size;
			fixed _Shape0, _Shape1;
			
			struct g2f
			{
				float4 pos : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				float3 position : TEXCOORD1;
				float3x3 rotation : TEXCOORD2;
			};

			struct fragOut
			{
				fixed4 color : SV_Target;
				float depth : SV_Depth;
			};

			float4 vert (float4 v : POSITION) : TEXCOORD0
			{
				return v;
			}

			[maxvertexcount(8)]
			void geom (triangle float4 input[3] : TEXCOORD0, inout TriangleStream<g2f> outStream)
			{
				g2f o;

				o.position = mul(unity_ObjectToWorld, input[0]);
				o.rotation[0] = normalize(mul((float3x3)unity_ObjectToWorld, (input[1] - input[0]).xyz));
				o.rotation[1] = normalize(mul((float3x3)unity_ObjectToWorld, (input[2] - input[0]).xyz));
				o.rotation[2] = normalize(cross(o.rotation[0], o.rotation[1]));

				float2 dir = float2(1.0 - 2.0 * (dot(cross(UNITY_MATRIX_V[0], UNITY_MATRIX_V[1]), UNITY_MATRIX_V[2]) > 0), 1);

				[unroll]
				for(int x = 0; x < 2; x++)
				{
					[unroll]
					for(int y = 0; y < 2; y++)
					{
						o.pos.xyz = UnityObjectToViewPos((float3)0);
						o.pos.w = 1;
						o.pos.xy += (float2(x, y) - 0.5) * dir * _Size * 4;
						o.worldPos = mul(UNITY_MATRIX_I_V, o.pos);
						o.pos = mul(UNITY_MATRIX_P, o.pos);
						
						outStream.Append (o);
					}
				}
				outStream.RestartStrip();
				
				[unroll]
				for(x = 0; x < 2; x++)
				{
					[unroll]
					for(int y = 0; y < 2; y++)
					{
						o.pos.xyz = UnityObjectToViewPos(input[0]);
						o.pos.w = 1;
						o.pos.xy += (float2(x, y) - 0.5) * dir * _Size * 4;
						o.worldPos = mul(UNITY_MATRIX_I_V, o.pos);
						o.pos = mul(UNITY_MATRIX_P, o.pos);
						
						outStream.Append (o);
					}
				}
				outStream.RestartStrip();
			}

			inline float sphere(float3 p, float s)
			{
				return length(p)-s;
			}

			inline float box(float3 p, float3 b)
			{
				float3 d = abs(p) - b;
				return length(max(d, 0)) + min(max(d.x, max(d.y, d.z)), 0);
			}
			
			inline float torus(float3 p, float2 t)
			{
				float2 q = float2(length(p.xz) - t.x, p.y);
				return length(q) - t.y;
			}

			inline float hexPrism(float3 p, float2 h)
			{
				const float3 k = float3(-0.8660254, 0.5, 0.57735);
				p = abs(p);
				p.xy -= 2.0 * min(dot(k.xy, p.xy), 0) * k.xy;
				float2 d = float2(length(p.xy - float2(clamp(p.x, -k.z * h.x, k.z * h.x), h.x)) * sign(p.y - h.x), p.z - h.y);
				return min(max(d.x, d.y), 0) + length(max(d, 0));
			}

			inline float capsule(float3 p, float h, float r)
			{
				p.z -= sign(p.z) * clamp(abs(p.z), 0, h);
				return length(p) - r;
			}

			inline float cylinder(float3 p, float h, float r)
			{
				float2 d = abs(float2(length(p.xy), p.z)) - float2(r, h);
				return min(max(d.x, d.y), 0) + length(max(d, 0));
			}

			inline float octahedron(float3 p, float s)
			{
				p = abs(p);
				float m = p.x + p.y + p.z - s;
				float3 q;
				q = 3.0 * p.x < m ? p.xyz :
					3.0 * p.y < m ? p.yzx :
					3.0 * p.z < m ? p.zxy : 0;
				float k = clamp(0.5 * (q.z - q.y + s), 0, s);
				return (3.0 * p.x < m || 3.0 * p.y < m || 3.0 * p.z < m) ? length(float3(q.x, q.y - s + k, q.z - k)) : m * 0.57735027;
			}

			inline float smoothUnion(float d1, float d2, float k)
			{
				float h = saturate(0.5 + 0.5 * (d2 - d1) / k);
				return lerp(d2, d1, h) - k * h * (1.0 - h);
			}

			float distanceFunction(float3 ray, g2f i)
			{
				float3 r0 = mul((float3x3)unity_WorldToObject, ray - mul(unity_ObjectToWorld, float4(0, 0, 0, 1)));
				float3 r1 = mul(i. rotation, ray - i.position);
				float d0, d1;
				if(_Shape0 == 0)
					d0 = sphere(r0, _Size);
				else if(_Shape0 == 1)
					d0 = box(r0, _Size * .7);
				else if(_Shape0 == 2)
					d0 = torus(r0, _Size * float2(.8, .2));
				else if(_Shape0 == 3)
					d0 = hexPrism(r0, _Size * .6);
				else if(_Shape0 == 4)
					d0 = capsule(r0, _Size * .6, _Size * .4);
				else if(_Shape0 == 5)
					d0 = cylinder(r0, _Size * .8, _Size * .4);
				else
					d0 = octahedron(r0, _Size);
				if(_Shape1 == 0)
					d1 = sphere(r1, _Size);
				else if(_Shape1 == 1)
					d1 = box(r1, _Size * .7);
				else if(_Shape1 == 2)
					d1 = torus(r1, _Size * float2(.8, .2));
				else if(_Shape1 == 3)
					d1 = hexPrism(r1, _Size * .6);
				else if(_Shape1 == 4)
					d1 = capsule(r1, _Size * .6, _Size * .4);
				else if(_Shape1 == 5)
					d1 = cylinder(r1, _Size * .8, _Size * .4);
				else
					d1 = octahedron(r1, _Size);
				return smoothUnion(d0, d1, 0.1);
			}

			float3 getNormal(float3 pos, g2f i)
			{
				float2 e = float2(1.0, -1.0) * 0.5773 * 0.001;
				return normalize (
					e.xyy * distanceFunction(pos + e.xyy, i) +
					e.yyx * distanceFunction(pos + e.yyx, i) +
					e.yxy * distanceFunction(pos + e.yxy, i) +
					e.xxx * distanceFunction(pos + e.xxx, i));
			}

			float compute_depth(float4 pos)
			{
				#if UNITY_UV_STARTS_AT_TOP
					return pos.z / pos.w;
				#else
					return (pos.z / pos.w) * 0.5 + 0.5;
				#endif
			}
			
			fragOut frag (g2f i)
			{
				float3 direction = normalize(i.worldPos - _WorldSpaceCameraPos);
				float3 r0 = _WorldSpaceCameraPos;
				if(unity_OrthoParams.w == 1)
				{
					direction = mul((float3x3)UNITY_MATRIX_I_V, float3(0, 0, -1));
					r0 = mul(UNITY_MATRIX_I_V, float4(mul(UNITY_MATRIX_V, float4(i.worldPos, 1)).xy , 0, 1)).xyz;
				}

				bool fail;
				float radius, pixelt;
				float outside = (distanceFunction(r0, i) > 0) * 2 - 1;
				float omega = 1.3;
				float previousRadius = 0;
				float t = 0.0001;
				float step = 0;
				float pixelRadius = 2.0 * min(abs(UNITY_MATRIX_P[0][0]) / _ScreenParams.x, abs(UNITY_MATRIX_P[1][1]) / _ScreenParams.y);
				float minPixelt = 999999999;
				float mint = 0;
				float hit = 0.001;
				
				for(int k = 0; k < 64; k++)
				{
					radius = outside * distanceFunction(r0 + t * direction, i);
					fail = omega > 1 && step > (abs(radius) + abs(previousRadius));
					if(fail)
					{
						step -= step * omega;
						omega = 1.0;
					}else
					{
						step = omega * radius;
					}
					previousRadius = radius;
					pixelt = radius / t;
					if(!fail && pixelt < minPixelt)
					{
						minPixelt = pixelt;
						mint = t;
					}
					if(!fail && pixelt < pixelRadius) break;
					t += step;
				}
				
				clip(-(minPixelt > pixelRadius && mint > hit));

				fragOut fo;
				
				float3 worldPos = r0 + mint * direction;
				float3 worldNormal = getNormal(worldPos, i);
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				
				float2 matcapUV = 0.5 + 0.5 * mul((float3x3)UNITY_MATRIX_V, worldNormal).xy;
				float4 matcapColor = tex2D(_MatcapTexture, matcapUV);
				
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT(SurfaceOutputStandard, o);
				o.Albedo = _Color * matcapColor;
				o.Emission = 0.0;
				o.Alpha = 1.0;
				o.Metallic = _Metallic;
				o.Smoothness = _Glossiness;
				o.Occlusion = 1.0;
				o.Normal = worldNormal;

				UnityGI gi;
				UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
				gi.indirect.diffuse = 0;
				gi.indirect.specular = 0;
				gi.light.color = _LightColor0.rgb;
				gi.light.dir = _WorldSpaceLightPos0.xyz;

				UnityGIInput giInput;
				UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
				giInput.light = gi.light;
				giInput.worldPos = worldPos;
				giInput.worldViewDir = worldViewDir;
				giInput.atten = 1;
				giInput.lightmapUV = 0.0;
				giInput.ambient.rgb = 0.0;

				giInput.probeHDR[0] = unity_SpecCube0_HDR;
				giInput.probeHDR[1] = unity_SpecCube1_HDR;

				#if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
					giInput.boxMin[0] = unity_SpecCube0_BoxMin;
				#endif

				#ifdef UNITY_SPECCUBE_BOX_PROJECTION
					giInput.boxMax[0] = unity_SpecCube0_BoxMax;
					giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
					giInput.boxMax[1] = unity_SpecCube1_BoxMax;
					giInput.boxMin[1] = unity_SpecCube1_BoxMin;
					giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
				#endif

				LightingStandard_GI(o, giInput, gi);
				fo.color = LightingStandard(o, worldViewDir, gi);

				float4 screenPos = UnityWorldToClipPos(worldPos);
				fo.depth = compute_depth(screenPos);

				UNITY_CALC_FOG_FACTOR(screenPos.z);
				UNITY_APPLY_FOG(unityFogFactor, fo.color);
				fo.color.a = 1;

				return fo;
			}
			ENDCG			
		}
	}
}
