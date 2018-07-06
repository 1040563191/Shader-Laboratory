//=============================================================================
// shader for Doodle Project
// Post Effect for being attacked 
// created by Lethe @ 2018-7-5
//=============================================================================
Shader "Custom/PE_OnEnemyInk" {
	Properties {
		[HideinInspector]
		_MainTex("RTX",2D) = "white" {}

		[Header(Textures)]
		_NoiseTex("噪声纹理(Noise)",2D) = "white" {}
		_MatcapTex("材质捕获纹理(MatCap)",2D) = "white" {}

		[Header(Script Control)]
		_Color("主颜色",Color) = (1,1,1,1)
		_HpRatio("当前生命值(%)",Range(0.0,1.0)) = 0.5
		
		[Header(Base Control)]
		_SampleDis("采样距离",float) = 20
		_DissolveMin("最小融解范围",Range(0.2,0.5)) = 0.5
		_DissolveMax("最大融解范围",Range(0.5,1.0)) = 0.8
		_SpeedX("X轴速度",float) = 2
		_SpeedY("Y轴速度",float) = 10

		[Header(Additonal Control)]
		_RandScale("随机程度",Range(0.0,0.3)) = 0.1
		_RandSpeed("变换速度",Range(0.0,3.0)) = 1.0
		_SpecScale("高光强度",Range(0.0,1.0)) = 0.5
		_CenterY("遮罩中心高度(Y)",Range(0.0,1.0)) = 0.0
		_StretchX("遮罩横向拉伸(X)",Range(0.0,1.0)) = 0.9
		_StretchY("遮罩纵向拉伸(Y)",Range(0.0,1.0)) = 0.3
	}
	SubShader {
		// ------------   Tags   ---------------

		// ------------ Render Set -------------
		ZTest Always
		Cull Off
		ZWrite Off

		CGINCLUDE
		// ------------ Includes ---------------
		#include "UnityCG.cginc"

		// ------------ Variables --------------
		sampler2D _MainTex;		half4 _MainTex_ST;		
		sampler2D _NoiseTex;	half4 _NoiseTex_ST;		half4 _NoiseTex_TexelSize;
		sampler2D _MatcapTex;	half4 _MatcapTex_ST;

		fixed4    _Color;
		fixed     _HpRatio;

		float     _SampleDis;
		fixed     _DissolveMin;
		fixed     _DissolveMax;
		float     _SpeedX;
		float     _SpeedY;

		half      _RandScale;
		half      _RandSpeed;
		fixed     _SpecScale;
		fixed     _CenterY;
		fixed     _StretchX;
		fixed     _StretchY;
		
		// ------------ Structures -------------
		struct a2v {
			float4 vertex : POSITION;
			half2 texcoord : TEXCOORD0;
		};

		struct v2f {
			float4 pos : SV_POSITION;
			float4 uv : TEXCOORD0;
			float4 scrPos : TEXCOORD1;
			float dissolveFactor : TEXCOORD2;
		};

		// ----------- vert & frag -------------
		v2f vert(a2v v){
			v2f o;

			o.pos = UnityObjectToClipPos(v.vertex);

			o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
			o.uv.zw = TRANSFORM_TEX(v.texcoord,_NoiseTex);

			o.scrPos = ComputeScreenPos(o.pos);

			
			if(v.texcoord.x < 0.5){
				o.dissolveFactor = -0.5;
			}
			else{
				o.dissolveFactor = 0.3;
			}

			return o;
		}

		fixed4 frag(v2f i):SV_TARGET{

			float2 speed = _Time.y * float2(_SpeedX,_SpeedY) * _NoiseTex_TexelSize * 5;

			// 对噪声纹理采样
			fixed3 dissolve = tex2D(_NoiseTex,i.uv.zw  + speed );
			
			// 根据距离和血量计算插值因子
			fixed2 viewPortCRD = i.scrPos.xy/i.scrPos.w;
			fixed2 scrBottomCenter = fixed2(0.5,_CenterY);
			fixed sqDistance = (viewPortCRD.x - scrBottomCenter.x)*(viewPortCRD.x - scrBottomCenter.x)*_StretchX
							  +(viewPortCRD.y - scrBottomCenter.y)*(viewPortCRD.y - scrBottomCenter.y)*_StretchY;
			
			_HpRatio = clamp(1 - _HpRatio,_DissolveMin,_DissolveMax);
			_HpRatio *= sqDistance*3 ;
			_HpRatio += sin(_Time.y * _RandSpeed)* _RandScale * i.dissolveFactor;
			
			fixed lerpFactor = smoothstep(-0.02,0.02,_HpRatio - dissolve.r);
			

			// 从噪声纹理中提取法线
			fixed center = dissolve.r;
			half2 offset = _NoiseTex_TexelSize * _SampleDis ;
			half left = tex2D(_NoiseTex,i.uv.zw + offset).r;
			half right = tex2D(_NoiseTex,i.uv.zw - offset).r;
			float bumpScale = max(0,1/( _HpRatio - center));
			half gapLeft = (left - center) * bumpScale;
			half gapRight = (right - center) * bumpScale;
			half3 bump = normalize(half3(gapLeft,gapRight,1));
			
			// 使用法线采样材质捕获纹理
			fixed4 matCapTexColor = tex2D(_MatcapTex,bump.xy*0.5+0.5);

			// 使用插值因子将渲染纹理与后效插值混合
			fixed4 mainTexColor = tex2D(_MainTex,i.uv.xy);
			fixed3 finalColor = _Color.rgb;
			finalColor.rgb = finalColor.rgb * matCapTexColor.r + matCapTexColor.g * _SpecScale;
			finalColor.rgb = lerp(mainTexColor.rgb,finalColor.rgb,lerpFactor);

			return fixed4(finalColor.rgb,mainTexColor.a);
		}

		ENDCG
		
		pass{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}
	}
	FallBack Off
}
