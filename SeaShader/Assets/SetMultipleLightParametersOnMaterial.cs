using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class SetMultipleLightParametersOnMaterial : MonoBehaviour
{
	public List<Light> m_Lights;
	MeshRenderer m_MeshRenderer;
	Terrain m_Terrain;

	void Awake()
	{
		m_Terrain=GetComponent<Terrain>();
		m_MeshRenderer=GetComponent<MeshRenderer>();
	}
	void LateUpdate()
	{
#if UNITY_EDITOR
		m_Terrain=GetComponent<Terrain>();
		m_MeshRenderer=GetComponent<MeshRenderer>();
#endif
		if(m_MeshRenderer==null && m_Terrain==null)
			return;
		
		Material l_CurrentMaterial=m_Terrain!=null ? m_Terrain.materialTemplate : m_MeshRenderer.sharedMaterial;
		int l_LightsCount=Mathf.Min(4, m_Lights.Count);
		Color[] l_Colors=new Color[4];
		float[] l_Types=new float[4];
		Vector4[] l_Positions=new Vector4[4];
		Vector4[] l_Directions=new Vector4[4];
		Vector4[] l_LightProperties=new Vector4[4];

		for(int i=0;i<4;++i)
		{
			Light l_Light=i<m_Lights.Count ? m_Lights[i] : null;
			if(l_Light!=null)
			{
				l_Colors[i]=l_Light.color;
				l_Types[i]=(int)l_Light.type;
				l_Positions[i]=l_Light.transform.position;
				if(l_Light.type==LightType.Directional || l_Light.type==LightType.Spot)
					l_Directions[i]=l_Light.transform.forward;
				else
					l_Directions[i]=Vector4.zero;
				l_LightProperties[i]=new Vector4(l_Light.range, l_Light.intensity, l_Light.spotAngle*Mathf.Deg2Rad, Mathf.Cos(l_Light.spotAngle*Mathf.Deg2Rad*0.5f));
			}
			else
				l_Colors[i]=Color.black;
		}

		l_CurrentMaterial.SetInt("_LightsCount", l_LightsCount);
		l_CurrentMaterial.SetColorArray("_LightColors", l_Colors);
		l_CurrentMaterial.SetFloatArray("_LightTypes", l_Types);
		l_CurrentMaterial.SetVectorArray("_LightPositions", l_Positions);
		l_CurrentMaterial.SetVectorArray("_LightDirections", l_Directions);
		l_CurrentMaterial.SetVectorArray("_LightProperties", l_LightProperties);
		/*l_CurrentMaterial.SetColor("_LightColor", m_Light.color);
		l_CurrentMaterial.SetInt("_LightType", (int)m_Light.type);
		Vector4 l_Position=m_Light.transform.position;
		l_CurrentMaterial.SetVector("_LightPosition", l_Position);
		Vector4 l_Direction=Vector4.zero;
		if(m_Light.type==LightType.Directional || m_Light.type==LightType.Spot)
			l_Direction=m_Light.transform.forward;
		l_CurrentMaterial.SetVector("_LightDirection", l_Direction);
		Vector4 l_LightProperties=new Vector4(m_Light.range, m_Light.intensity, m_Light.spotAngle*Mathf.Deg2Rad, Mathf.Cos(m_Light.spotAngle*Mathf.Deg2Rad*0.5f));
		l_CurrentMaterial.SetVector("_LightProperties", l_LightProperties);*/
	}
}
