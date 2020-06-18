Shader "Custom/painterly"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _NoiseTex ("Noise", 2D) = "white" {}
        _NormalTex ("Normal", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _AmbientColor ("Ambient Color", Color) = (0,0,0,1)
        _AmbientStrength("_AmbientStrength", Range(0,1)) = 0.5

        _NoiseScale("Noise Scale", Range(1,100)) = 1
        _Step("Step", Range(1,100)) = 3


    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Custom 

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _NoiseTex;
        sampler2D _NormalTex;

        struct Input
        {
            float4 vertex; 
            float2 uv_MainTex;
            float2 uv_NormalTex;
            float4 screenPos;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        float4 _AmbientColor;
        float _AmbientStrength;
        
        float _NoiseScale;
        int _Step;

        struct SurfaceOutputCustom {
            fixed3 Albedo;
            fixed3 Normal;
            fixed3 Emission;
            fixed Alpha;
            float noise;
        };

        
        float invLerp(float a, float b, float v) {
            return (v - a)/(b - a);
        }

        float circle(float2 st, float radius, float fadeWidth) {
            float ic = radius - fadeWidth;
            float d = distance(st, float2(0.5, 0.5));
            float fc = invLerp(radius, ic, d);

            return fc;
        }

        float posterize(float v, float step) {
            return ceil(v*step)/step;
        }

        void surf (Input IN, inout SurfaceOutputCustom o)
        {

            float2 textureCoordinate = IN.screenPos.xy / IN.screenPos.w; // perspective divide
            float aspect = _ScreenParams.x / _ScreenParams.y;
            textureCoordinate.x = textureCoordinate.x * aspect;
            textureCoordinate += float2(_Time.y/10, _Time.y/20);

            fixed noise = tex2D (_NoiseTex, frac(textureCoordinate * _NoiseScale));
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex);

            //// THIS IS THE MAIN IDEA
            // fixed4 bar = step(IN.uv_MainTex.y, post) - step(IN.uv_MainTex.y, post-.01); //(a,x) => a < x
            // fixed4 c = (1-bar) * post + bar * float4(1,0,0,1); 

            o.Normal = UnpackNormal(tex2D(_NormalTex, IN.uv_NormalTex));
            o.Albedo = c.rgb;
            o.Alpha = c.a;
            o.noise = noise; 
        }

        half4 LightingCustom (SurfaceOutputCustom s, half3 lightDir, half3 viewDir) {
            float NdotL = max(0, dot(s.Normal, lightDir));

            float invP = 1.0/_Step;
            fixed post = posterize(NdotL, _Step);
            fixed bar = step(NdotL, post) - step(NdotL, post-invP/s.noise/10); //(a,x) => a < x

            fixed painterly = (1-bar) * post + bar * (post+invP);
            half3 l = (s.Albedo * painterly + _AmbientColor * _AmbientStrength);
        
            half4 col;
            col.rgb = l;
            col.a = s.Alpha;
            
            return col;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
