Shader "Tecnocampus/WaterShader"
{
	Properties
	{
		_MainTex("_MainTex", 2D) = ""{}
		_WaterDepthTex("_WaterDepthTex", 2D) = ""{}
		_FoamTex("_FoamTex", 2D) = ""{}
		_NoiseTex("_NoiseTex", 2D) = ""{}
		_WaterHeightmapTex("_WaterHeightmapTex", 2D) = ""{}
		_DeepWaterColor("_DeepWaterColor", Color) = (0, 0.1, 1, 1)
		_WaterColor("_WaterColor", Color) = (0, 0, 1, 1)
		_SpeedWater1("_SpeedWater1", float) = 0.05
		_DirectionWater1("_DirectionWater1", Vector) = (0.3, -0.1, 1, 1)
		_SpeedWater2("_SpeedWater2", float) = 0.01
		_DirectionWater2("_DirectionWater2", Vector) = (-0.4, 0.02, 1, 1)
		_DirectionNoise("_DirectionNoise", Vector) = (-0.18, 0.3, 1, 1)
		_FoamDistance("_FoamDistance", Range(0, 1)) = 0.57
		_SpeedFoam("_SpeedFoam", float) = 0.03
		_DirectionFoam("_DirectionFoam", Vector) = (1.5, 0, -0.3, 0.4)
		_FoamMultiplier("_FoamMultiplier", Range(0, 4)) = 0.3
		_MaxHeightWater("_MaxHeightWater", float) = 0.02
		_Threshold("_Threshold", Range(0.0,1.0)) = 0.5
		_Threshold2("_Threshold2", Range(0.0,10.0)) = 5.0

			//Extras
			_SpecularPower("_SpecularPower", Range(1.0, 100.0)) = 1
			_AmbientColor("_AmbientColor", Color) = (0,0,1,0)
			_AmbientIntensity("_AmbientIntensity", Range(0.0, 100.0)) = 0.5
	}
		SubShader
		{
			Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "True" }
			LOD 100

			Pass
			{
				Blend SrcAlpha OneMinusSrcAlpha
				ZWrite Off

				CGPROGRAM
				#pragma vertex MyVS
				#pragma fragment MyPS

				#include "UnityCG.cginc"

				sampler2D _MainTex;
				float4 _MainTex_ST;
				sampler2D _WaterDepthTex;
				float4 _WaterDepthTex_ST;
				sampler2D _FoamTex;
				float4 _FoamTex_ST;
				sampler2D _NoiseTex;
				float4 _NoiseTex_ST;
				sampler2D _WaterHeightmapTex;
				float4 _WaterHeightmapTex_ST;
				float4 _DeepWaterColor;
				float4 _WaterColor;
				float _SpeedWater1;
				float4 _DirectionWater1;
				float _SpeedWater2;
				float4 _DirectionWater2;
				float4 _DirectionNoise;
				float _FoamDistance;
				float _SpeedFoam;
				float4 _DirectionFoam;
				float _FoamMultiplier;
				float _MaxHeightWater;
				float4 _WaterDirection;
				float _Threshold;
				float _Threshold2;
				//Extras
				#define MAX_LIGHTS 4
				int _LightsCount;
				int _LightTypes[MAX_LIGHTS];//0=Spot, 1=Directional, 2=Point
				float4 _LightColors[MAX_LIGHTS];
				float4 _LightPositions[MAX_LIGHTS];
				float4 _LightDirections[MAX_LIGHTS];
				float4 _LightProperties[MAX_LIGHTS];//x=Range, y=Intensity, z=Spot Angle, w=cos(Half Spot Angle)
				float _SpecularPower;
				float4 _AmbientColor;
				float _AmbientIntensity;


				struct appdata
				{
					float4 vertex : POSITION;
					float2 UV : TEXCOORD0;
					float3 normal : NORMAL;
				};
				struct v2f
				{
					float4 vertex : SV_POSITION;
					float2 uv : TEXCOORD0;
					float2 uvFoam : TEXCOORD1;
					float2 uvNoise : TEXCOORD2;
					float2 uvWater : TEXCOORD3;
					float2 uvDepth : TEXCOORD4;
					float2 uvHeight : TEXCOORD5;
					float3 normal : NORMAL;
					float3 worldPosition : TEXCOORD6;
				};


				v2f MyVS(appdata v)
				{


					v2f o;
					o.vertex = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));

					//Apply height to each vertex
					o.uvHeight = TRANSFORM_TEX(v.UV, _WaterHeightmapTex);
					o.uvHeight.x += _DirectionWater1 * _SpeedWater1 * _Time.y;
					o.uvHeight.y += _DirectionWater2 * _SpeedWater2 * _Time.y;
					float l_HeightNormalized = tex2Dlod(_WaterHeightmapTex, float4(o.uvHeight, 0, 0)).x;
					float l_Height = l_HeightNormalized * _MaxHeightWater;
					o.vertex.y += l_Height;

					//Apply movement to vertex
					float3 l_WindDirection1 = _DirectionWater1.xyz * (v.UV.xy, 1) * cos(_Time.y * _SpeedWater1) * v.vertex.xyz;
					float3 l_WindDirection2 = _DirectionWater2.xyz * (v.UV.xy, 1) * cos(_Time.y * _SpeedWater2) * v.vertex.xyz;
					o.vertex.xyz += l_WindDirection1;
					o.vertex.xyz += l_WindDirection2;


					o.worldPosition = o.vertex.xyz;
					o.vertex = mul(UNITY_MATRIX_V, o.vertex);
					o.vertex = mul(UNITY_MATRIX_P, o.vertex);
					o.normal = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));

					//Transform uvs
					o.uv = TRANSFORM_TEX(v.UV, _MainTex);
					o.uvNoise = TRANSFORM_TEX(v.UV, _NoiseTex);
					o.uvFoam = TRANSFORM_TEX(v.UV, _FoamTex);
					o.uvDepth = TRANSFORM_TEX(v.UV, _WaterDepthTex);
					o.uvWater = v.UV;

					//Apply movement to textures
					o.uv = float2(0.5, l_HeightNormalized);
					o.uvFoam += _DirectionFoam * _SpeedFoam * _Time.y;
					o.uvNoise += -_DirectionFoam * (_SpeedFoam / 2) * _Time.y;
					o.uvWater.x += _DirectionWater1 * _SpeedWater1 * _Time.y;
					o.uvWater.y += _DirectionWater2 * _SpeedWater2 * _Time.y;

					return o;
				}

				void CalcLight(int IdLight, float3 Nn, float3 Vn, float3 worldPosition, float4 l_AlbedoColor, out float3 DiffuseLighting, out float3 SpecularLighting)
				{
					float l_Attenuation = 1.0;
					float3 l_DirectionLight;
					float Ks = 0.0;
					float Kd = 0.0;

					if (_LightTypes[IdLight] == 1) // Directional Light
					{
						l_DirectionLight = _LightDirections[IdLight].xyz;

					}
					else // point Light and Spot light
					{
						l_DirectionLight = worldPosition - _LightPositions[IdLight].xyz;
						float l_Distance = length(l_DirectionLight);
						l_DirectionLight /= l_Distance;
						l_Attenuation = 1 - min(1.0, l_Distance / _LightProperties[IdLight].x);


						if (_LightTypes[IdLight] == 0) // Spot Light
						{
							float l_SpotAngle = dot(l_DirectionLight, _LightDirections[IdLight].xyz);
							float l_AngleAtt = max(0, (l_SpotAngle - _LightProperties[IdLight].w) / (1 - _LightProperties[IdLight].w));
							l_Attenuation *= l_AngleAtt;
						}

					}
					Kd = saturate(dot(Nn, -l_DirectionLight.xyz));
					/*float3 Hn = normalize(Vn - l_DirectionLight.xyz);
					Ks = pow(saturate(dot(Nn, Hn)), _SpecularPower);*/
					float3 l_Reflected = reflect(l_DirectionLight, Nn);
					Ks = pow(saturate(dot(l_Reflected, Vn)), _SpecularPower);

					DiffuseLighting = Kd * _LightColors[IdLight].xyz * l_AlbedoColor.xyz * l_Attenuation * _LightProperties[IdLight].y;
					SpecularLighting = Ks * _LightColors[IdLight].xyz * l_Attenuation * _LightProperties[IdLight].y;


				}

				fixed4 MyPS(v2f VertexData) : SV_Target
				{
					float4 l_WaterTex = tex2D(_MainTex,VertexData.uvWater);
					float l_DepthMixer = tex2D(_WaterDepthTex, VertexData.uvDepth).x;
					float4 l_FoamColor;
					float l_FoamMixer = tex2D(_WaterDepthTex, VertexData.uvDepth).x;
					float l_NoiseMixer = tex2D(_NoiseTex, VertexData.uvNoise).x;
					//Apply depth color
					l_WaterTex.xyz *= _DeepWaterColor.xyz * (1.0 - l_DepthMixer) + _WaterColor.xyz * l_DepthMixer;




					//Extras
					float3 Nn = normalize(VertexData.normal);
					float3 Vn = normalize(_WorldSpaceCameraPos.xyz - VertexData.worldPosition);
					float3 l_DiffuseSpecularLighting = float3(0.0, 0.0, 0.0);
					float3 l_AmbientLighting = l_WaterTex.xyz * _AmbientColor.xyz * _AmbientIntensity;
					float3 l_FullLighting = l_AmbientLighting;
					for (int i = 0; i < _LightsCount; i++)
					{
						float3 l_DiffuseLighting;
						float3 l_SpecularLighting;
						CalcLight(i, Nn, Vn, VertexData.worldPosition, l_WaterTex, l_DiffuseLighting, l_SpecularLighting);
						l_FullLighting += l_DiffuseLighting;
						l_FullLighting += l_SpecularLighting;

					}

					//Apply Foam
					if (l_FoamMixer > _FoamDistance && VertexData.worldPosition.y > _Threshold2)
					{
						l_FoamColor = tex2D(_FoamTex, VertexData.uvFoam) * _FoamMultiplier;
						l_FoamColor *= saturate((l_NoiseMixer - _Threshold) / (1.0 - _Threshold)); ;
						l_FullLighting += l_FoamColor;
					}

					return float4(l_FullLighting, l_WaterTex.a);
				}
				ENDCG
			}
		}
}