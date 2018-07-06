using System.Collections;
using UnityEngine;

public class PostEffect : PostEffectsBase {

	//public Shader matCapShader;
	public Material matCapMaterial;
	public Material material{
		get{
			return matCapMaterial;
		}
	}
	

	void OnRenderImage(RenderTexture src, RenderTexture dest)
	{
		if(material != null){
			Graphics.Blit(src,dest,material);
		}else{
			Graphics.Blit(src,dest);
		}
	}
}
