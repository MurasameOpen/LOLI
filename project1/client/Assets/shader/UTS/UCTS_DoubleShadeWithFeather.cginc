﻿//UCTS_DoubleShadeWithFeather.cginc
//v.2.0.4.2
//#pragma multi_compile _IS_CLIPPING_OFF _IS_CLIPPING_MODE  _IS_CLIPPING_TRANSMODE
//#pragma multi_compile _IS_PASS_FWDBASE _IS_PASS_FWDDELTA
//

            uniform sampler2D _BaseMap; uniform float4 _BaseMap_ST;
            uniform float4 _BaseColor;
            uniform fixed _Is_LightColor_Base;
            uniform sampler2D _1st_ShadeMap; uniform float4 _1st_ShadeMap_ST;
            uniform float4 _1st_ShadeColor;
            uniform fixed _Is_LightColor_1st_Shade;
            uniform sampler2D _2nd_ShadeMap; uniform float4 _2nd_ShadeMap_ST;
            uniform float4 _2nd_ShadeColor;
            uniform fixed _Is_LightColor_2nd_Shade;
            uniform sampler2D _NormalMap; uniform float4 _NormalMap_ST;
            uniform fixed _Is_NormalMapToBase;
            uniform fixed _Set_SystemShadowsToBase;
            uniform float _Tweak_SystemShadowsLevel;
            uniform float _BaseColor_Step;
            uniform float _BaseShade_Feather;
            uniform sampler2D _Set_1st_ShadePosition; uniform float4 _Set_1st_ShadePosition_ST;
            uniform float _ShadeColor_Step;
            uniform float _1st2nd_Shades_Feather;
            uniform sampler2D _Set_2nd_ShadePosition; uniform float4 _Set_2nd_ShadePosition_ST;
            uniform float4 _HighColor;
            uniform sampler2D _HighColor_Tex; uniform float4 _HighColor_Tex_ST;
            uniform fixed _Is_LightColor_HighColor;
            uniform fixed _Is_NormalMapToHighColor;
            uniform float _HighColor_Power;
            uniform fixed _Is_SpecularToHighColor;
            uniform fixed _Is_BlendAddToHiColor;
            uniform fixed _Is_UseTweakHighColorOnShadow;
            uniform float _TweakHighColorOnShadow;
            uniform sampler2D _Set_HighColorMask; uniform float4 _Set_HighColorMask_ST;
            uniform float _Tweak_HighColorMaskLevel;
            uniform fixed _RimLight;
            uniform float4 _RimLightColor;
            uniform fixed _Is_LightColor_RimLight;
            uniform fixed _Is_NormalMapToRimLight;
            uniform float _RimLight_Power;
            uniform float _RimLight_InsideMask;
            uniform fixed _RimLight_FeatherOff;
            uniform fixed _LightDirection_MaskOn;
            uniform float _Tweak_LightDirection_MaskLevel;
            uniform fixed _Add_Antipodean_RimLight;
            uniform float4 _Ap_RimLightColor;
            uniform fixed _Is_LightColor_Ap_RimLight;
            uniform float _Ap_RimLight_Power;
            uniform fixed _Ap_RimLight_FeatherOff;
            uniform sampler2D _Set_RimLightMask; uniform float4 _Set_RimLightMask_ST;
            uniform float _Tweak_RimLightMaskLevel;
            uniform fixed _MatCap;
            uniform sampler2D _MatCap_Sampler; uniform float4 _MatCap_Sampler_ST;
            uniform float4 _MatCapColor;
            uniform fixed _Is_LightColor_MatCap;
            uniform fixed _Is_BlendAddToMatCap;
            uniform float _Tweak_MatCapUV;
            uniform float _Rotate_MatCapUV;
            uniform fixed _Is_NormalMapForMatCap;
            uniform sampler2D _NormalMapForMatCap; uniform float4 _NormalMapForMatCap_ST;
            uniform float _Rotate_NormalMapForMatCapUV;
            uniform fixed _Is_UseTweakMatCapOnShadow;
            uniform float _TweakMatCapOnShadow;
//MatcapMask
            uniform sampler2D _Set_MatcapMask; uniform float4 _Set_MatcapMask_ST;
            uniform float _Tweak_MatcapMaskLevel;
//
            uniform sampler2D _Emissive_Tex; uniform float4 _Emissive_Tex_ST;
            uniform float4 _Emissive_Color;
            uniform float _Unlit_Intensity;
//v.2.0.4
#ifdef _IS_CLIPPING_MODE
//DoubleShadeWithFeather_Clipping
            uniform sampler2D _ClippingMask; uniform float4 _ClippingMask_ST;
            uniform float _Clipping_Level;
            uniform fixed _Inverse_Clipping;
#elif _IS_CLIPPING_TRANSMODE
//DoubleShadeWithFeather_TransClipping
            uniform sampler2D _ClippingMask; uniform float4 _ClippingMask_ST;
            uniform fixed _IsBaseMapAlphaAsClippingMask;
            uniform float _Clipping_Level;
            uniform fixed _Inverse_Clipping;
            uniform float _Tweak_transparency;
#elif _IS_CLIPPING_OFF
//DoubleShadeWithFeather
#endif

            fixed3 DecodeLightProbe( fixed3 N ){
            return ShadeSH9(float4(N,1));
            }
            
            uniform float _GI_Intensity;

            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                float3 tangentDir : TEXCOORD3;
                float3 bitangentDir : TEXCOORD4;
                LIGHTING_COORDS(5,6)
                UNITY_FOG_COORDS(7)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                float3 lightColor = _LightColor0.rgb;
                o.pos = UnityObjectToClipPos( v.vertex );
                UNITY_TRANSFER_FOG(o,o.pos);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }
            float4 frag(VertexOutput i) : SV_TARGET {
                i.normalDir = normalize(i.normalDir);
                float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float2 Set_UV0 = i.uv0;
                float3 _NormalMap_var = UnpackNormal(tex2D(_NormalMap,TRANSFORM_TEX(Set_UV0, _NormalMap)));
                float3 normalLocal = _NormalMap_var.rgb;
                float3 normalDirection = normalize(mul( normalLocal, tangentTransform )); // Perturbed normals
                float4 _BaseMap_var = tex2D(_BaseMap,TRANSFORM_TEX(Set_UV0, _BaseMap));
//v.2.0.4
#ifdef _IS_CLIPPING_MODE
//DoubleShadeWithFeather_Clipping
                float4 _ClippingMask_var = tex2D(_ClippingMask,TRANSFORM_TEX(Set_UV0, _ClippingMask));
                float Set_Clipping = saturate((lerp( _ClippingMask_var.r, (1.0 - _ClippingMask_var.r), _Inverse_Clipping )+_Clipping_Level));
                clip(Set_Clipping - 0.5);
#elif _IS_CLIPPING_TRANSMODE
//DoubleShadeWithFeather_TransClipping
                float4 _ClippingMask_var = tex2D(_ClippingMask,TRANSFORM_TEX(Set_UV0, _ClippingMask));
                float Set_BaseMapAlpha = _BaseMap_var.a;
                float _IsBaseMapAlphaAsClippingMask_var = lerp( _ClippingMask_var.r, Set_BaseMapAlpha, _IsBaseMapAlphaAsClippingMask );
                float _Inverse_Clipping_var = lerp( _IsBaseMapAlphaAsClippingMask_var, (1.0 - _IsBaseMapAlphaAsClippingMask_var), _Inverse_Clipping );
                float Set_Clipping = saturate((_Inverse_Clipping_var+_Clipping_Level));
                clip(Set_Clipping - 0.5);

#elif _IS_CLIPPING_OFF
//DoubleShadeWithFeather
#endif

//v.2.0.4
#ifdef _IS_PASS_FWDBASE
                float3 defaultLightDirection = float3(0.0,0.1,0.1);
                float3 defaultLightColor = float3(_Unlit_Intensity,_Unlit_Intensity,_Unlit_Intensity);
                float3 lightDirection = normalize(lerp(defaultLightDirection,_WorldSpaceLightPos0.xyz,any(_WorldSpaceLightPos0.xyz)));
                float3 lightColor = lerp(defaultLightColor,_LightColor0.rgb,any(_LightColor0.rgb));                
#elif _IS_PASS_FWDDELTA
                float3 lightDirection = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz,_WorldSpaceLightPos0.w));
                float3 lightColor = saturate(_LightColor0.rgb*0.5);
#endif
                float3 halfDirection = normalize(viewDirection+lightDirection);
////// Lighting:
                float attenuation = LIGHT_ATTENUATION(i);// + abs( sin(i.uv0.x * 40));
                float3 Set_LightColor = lightColor.rgb;
                float3 Set_BaseColor = lerp( (_BaseColor.rgb*_BaseMap_var.rgb), ((_BaseColor.rgb*_BaseMap_var.rgb)*Set_LightColor), _Is_LightColor_Base );
                float4 _1st_ShadeMap_var = tex2D(_1st_ShadeMap,TRANSFORM_TEX(Set_UV0, _1st_ShadeMap));
                float3 Set_1st_ShadeColor = lerp( (_1st_ShadeColor.rgb*_1st_ShadeMap_var.rgb), ((_1st_ShadeColor.rgb*_1st_ShadeMap_var.rgb)*Set_LightColor), _Is_LightColor_1st_Shade );
                float4 _2nd_ShadeMap_var = tex2D(_2nd_ShadeMap,TRANSFORM_TEX(Set_UV0, _2nd_ShadeMap));
                float3 Set_2nd_ShadeColor = lerp( (_2nd_ShadeColor.rgb*_2nd_ShadeMap_var.rgb), ((_2nd_ShadeColor.rgb*_2nd_ShadeMap_var.rgb)*Set_LightColor), _Is_LightColor_2nd_Shade );
                float _HalfLambert_var = 0.5*dot(lerp( i.normalDir, normalDirection, _Is_NormalMapToBase ),lightDirection)+0.5;
                float4 _Set_2nd_ShadePosition_var = tex2D(_Set_2nd_ShadePosition,TRANSFORM_TEX(Set_UV0, _Set_2nd_ShadePosition));
                float4 _Set_1st_ShadePosition_var = tex2D(_Set_1st_ShadePosition,TRANSFORM_TEX(Set_UV0, _Set_1st_ShadePosition));
                float Set_FinalShadowSample = saturate((1.0 + ( (lerp( _HalfLambert_var, (_HalfLambert_var*saturate(((attenuation*0.5)+0.5+_Tweak_SystemShadowsLevel))), _Set_SystemShadowsToBase ) - (_BaseColor_Step-_BaseShade_Feather)) * ((1.0 - _Set_1st_ShadePosition_var.rgb).r - 1.0) ) / (_BaseColor_Step - (_BaseColor_Step-_BaseShade_Feather))));
                float3 _FinalColor_var = lerp(Set_BaseColor,lerp(Set_1st_ShadeColor,Set_2nd_ShadeColor,saturate((1.0 + ( (_HalfLambert_var - (_ShadeColor_Step-_1st2nd_Shades_Feather)) * ((1.0 - _Set_2nd_ShadePosition_var.rgb).r - 1.0) ) / (_ShadeColor_Step - (_ShadeColor_Step-_1st2nd_Shades_Feather))))),Set_FinalShadowSample); // Final Color
                float4 _Set_HighColorMask_var = tex2D(_Set_HighColorMask,TRANSFORM_TEX(Set_UV0, _Set_HighColorMask));
                float _Specular_var = 0.5*dot(halfDirection,lerp( i.normalDir, normalDirection, _Is_NormalMapToHighColor ))+0.5; //  Specular
                float _TweakHighColorMask_var = (saturate((_Set_HighColorMask_var.g+_Tweak_HighColorMaskLevel))*lerp( (1.0 - step(_Specular_var,(1.0 - _HighColor_Power))), pow(_Specular_var,exp2(lerp(11,1,_HighColor_Power))), _Is_SpecularToHighColor ));
                float4 _HighColor_Tex_var = tex2D(_HighColor_Tex,TRANSFORM_TEX(Set_UV0, _HighColor_Tex));
                float3 _HighColor_var = (lerp( (_HighColor_Tex_var.rgb*_HighColor.rgb), ((_HighColor_Tex_var.rgb*_HighColor.rgb)*Set_LightColor), _Is_LightColor_HighColor )*_TweakHighColorMask_var);
                float3 Set_HighColor = (lerp( saturate((_FinalColor_var-_TweakHighColorMask_var)), _FinalColor_var, _Is_BlendAddToHiColor )+lerp( _HighColor_var, (_HighColor_var*((1.0 - Set_FinalShadowSample)+(Set_FinalShadowSample*_TweakHighColorOnShadow))), _Is_UseTweakHighColorOnShadow ));
                float4 _Set_RimLightMask_var = tex2D(_Set_RimLightMask,TRANSFORM_TEX(Set_UV0, _Set_RimLightMask));
                float3 _Is_LightColor_RimLight_var = lerp( _RimLightColor.rgb, (_RimLightColor.rgb*Set_LightColor), _Is_LightColor_RimLight );
                float _RimArea_var = (1.0 - dot(lerp( i.normalDir, normalDirection, _Is_NormalMapToRimLight ),viewDirection));
                float _RimLightPower_var = pow(_RimArea_var,exp2(lerp(3,0,_RimLight_Power)));
                float _Rimlight_InsideMask_var = saturate(lerp( (0.0 + ( (_RimLightPower_var - _RimLight_InsideMask) * (1.0 - 0.0) ) / (1.0 - _RimLight_InsideMask)), step(_RimLight_InsideMask,_RimLightPower_var), _RimLight_FeatherOff ));
                float _VertHalfLambert_var = 0.5*dot(i.normalDir,lightDirection)+0.5;
                float3 _LightDirection_MaskOn_var = lerp( (_Is_LightColor_RimLight_var*_Rimlight_InsideMask_var), (_Is_LightColor_RimLight_var*saturate((_Rimlight_InsideMask_var-((1.0 - _VertHalfLambert_var)+_Tweak_LightDirection_MaskLevel)))), _LightDirection_MaskOn );
                float _ApRimLightPower_var = pow(_RimArea_var,exp2(lerp(3,0,_Ap_RimLight_Power)));
                float3 Set_RimLight = (saturate((_Set_RimLightMask_var.g+_Tweak_RimLightMaskLevel))*lerp( _LightDirection_MaskOn_var, (_LightDirection_MaskOn_var+(lerp( _Ap_RimLightColor.rgb, (_Ap_RimLightColor.rgb*Set_LightColor), _Is_LightColor_Ap_RimLight )*saturate((lerp( (0.0 + ( (_ApRimLightPower_var - _RimLight_InsideMask) * (1.0 - 0.0) ) / (1.0 - _RimLight_InsideMask)), step(_RimLight_InsideMask,_ApRimLightPower_var), _Ap_RimLight_FeatherOff )-(saturate(_VertHalfLambert_var)+_Tweak_LightDirection_MaskLevel))))), _Add_Antipodean_RimLight ));
                float3 _RimLight_var = lerp( Set_HighColor, (Set_HighColor+Set_RimLight), _RimLight );
                float _Rot_MatCapUV_var_ang = (_Rotate_MatCapUV*3.141592654);
                float _Rot_MatCapUV_var_spd = 1.0;
                float _Rot_MatCapUV_var_cos = cos(_Rot_MatCapUV_var_spd*_Rot_MatCapUV_var_ang);
                float _Rot_MatCapUV_var_sin = sin(_Rot_MatCapUV_var_spd*_Rot_MatCapUV_var_ang);
                float2 _Rot_MatCapUV_var_piv = float2(0.5,0.5);
                float _Rot_MatCapNmUV_var_ang = (_Rotate_NormalMapForMatCapUV*3.141592654);
                float _Rot_MatCapNmUV_var_spd = 1.0;
                float _Rot_MatCapNmUV_var_cos = cos(_Rot_MatCapNmUV_var_spd*_Rot_MatCapNmUV_var_ang);
                float _Rot_MatCapNmUV_var_sin = sin(_Rot_MatCapNmUV_var_spd*_Rot_MatCapNmUV_var_ang);
                float2 _Rot_MatCapNmUV_var_piv = float2(0.5,0.5);
                float2 _Rot_MatCapNmUV_var = (mul(Set_UV0-_Rot_MatCapNmUV_var_piv,float2x2( _Rot_MatCapNmUV_var_cos, -_Rot_MatCapNmUV_var_sin, _Rot_MatCapNmUV_var_sin, _Rot_MatCapNmUV_var_cos))+_Rot_MatCapNmUV_var_piv);
                float3 _NormalMapForMatCap_var = UnpackNormal(tex2D(_NormalMapForMatCap,TRANSFORM_TEX(_Rot_MatCapNmUV_var, _NormalMapForMatCap)));
                float2 _Rot_MatCapUV_var = (mul((0.0 + ( ((mul( UNITY_MATRIX_V, float4(lerp( i.normalDir, mul( _NormalMapForMatCap_var.rgb, tangentTransform ).rgb, _Is_NormalMapForMatCap ),0) ).rg*0.5+0.5) - (0.0+_Tweak_MatCapUV)) * (1.0 - 0.0) ) / ((1.0-_Tweak_MatCapUV) - (0.0+_Tweak_MatCapUV)))-_Rot_MatCapUV_var_piv,float2x2( _Rot_MatCapUV_var_cos, -_Rot_MatCapUV_var_sin, _Rot_MatCapUV_var_sin, _Rot_MatCapUV_var_cos))+_Rot_MatCapUV_var_piv);
                float4 _MatCap_Sampler_var = tex2D(_MatCap_Sampler,TRANSFORM_TEX(_Rot_MatCapUV_var, _MatCap_Sampler));
                //MatcapMask
                float4 _Set_MatcapMask_var = tex2D(_Set_MatcapMask,TRANSFORM_TEX(Set_UV0, _Set_MatcapMask));
                float _Tweak_MatcapMaskLevel_var = saturate(_Set_MatcapMask_var.g + _Tweak_MatcapMaskLevel);
                float3 _Is_LightColor_MatCap_var = lerp( (_MatCap_Sampler_var.rgb*_MatCapColor.rgb), ((_MatCap_Sampler_var.rgb*_MatCapColor.rgb)*Set_LightColor), _Is_LightColor_MatCap );
                float3 Set_MatCap = lerp( _Is_LightColor_MatCap_var, (_Is_LightColor_MatCap_var*((1.0 - Set_FinalShadowSample)+(Set_FinalShadowSample*_TweakMatCapOnShadow))), _Is_UseTweakMatCapOnShadow );
                float4 _Emissive_Tex_var = tex2D(_Emissive_Tex,TRANSFORM_TEX(Set_UV0, _Emissive_Tex));
                float3 finalColor = saturate((1.0-(1.0-(saturate(lerp( _RimLight_var, lerp( ((_RimLight_var*(1-(_Tweak_MatcapMaskLevel_var*0.5+0.5))+_RimLight_var*Set_MatCap*(_Tweak_MatcapMaskLevel_var*0.5+0.5))), (_RimLight_var+Set_MatCap*_Tweak_MatcapMaskLevel_var), _Is_BlendAddToMatCap ), _MatCap ))+(_Emissive_Tex_var.rgb*_Emissive_Color.rgb)))*(1.0-(DecodeLightProbe( normalDirection )*_GI_Intensity))));


//v.2.0.4
#ifdef _IS_CLIPPING_OFF
//DoubleShadeWithFeather
	#ifdef _IS_PASS_FWDBASE
	                fixed4 finalRGBA = fixed4(finalColor,1);
	#elif _IS_PASS_FWDDELTA
	                fixed4 finalRGBA = fixed4(finalColor * 1,0);
	#endif
#elif _IS_CLIPPING_MODE
//DoubleShadeWithFeather_Clipping
	#ifdef _IS_PASS_FWDBASE
	                fixed4 finalRGBA = fixed4(finalColor,1);
	#elif _IS_PASS_FWDDELTA
	                fixed4 finalRGBA = fixed4(finalColor * 1,0);
	#endif
#elif _IS_CLIPPING_TRANSMODE
//DoubleShadeWithFeather_TransClipping
    				float Set_Opacity = saturate((_Inverse_Clipping_var+_Tweak_transparency));
	#ifdef _IS_PASS_FWDBASE
                	fixed4 finalRGBA = fixed4(finalColor,Set_Opacity);
	#elif _IS_PASS_FWDDELTA
                	fixed4 finalRGBA = fixed4(finalColor * Set_Opacity,0);
	#endif
#endif
                UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
                return finalRGBA;
            }
