Shader "Custom/diffused-posterization"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _NoiseTex ("Noise", 2D) = "white" {}
        _NormalTex ("Normal", 2D) = "white" {}
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
        #pragma surface surf Custom 
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _NoiseTex;
        sampler2D _NormalTex;

        struct Input
        {
            float4 vertex; 
            float2 uv_MainTex;
            float2 uv_NoiseTex;
            float2 uv_NormalTex;
            float4 screenPos;
        };

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

        
        float posterize(float v, float k) {
            return ceil(v*k)/k;
        }

        void surf (Input IN, inout SurfaceOutputCustom o) {
            
            float2 textureCoordinate = IN.screenPos.xy / IN.screenPos.w; // perspective divide
            float aspect = _ScreenParams.x / _ScreenParams.y;
            textureCoordinate.x = textureCoordinate.x * aspect;
            textureCoordinate += float2(_Time.y/10, _Time.y/20);
            
            fixed noise = tex2D (_NoiseTex,  frac(textureCoordinate * _NoiseScale)); 
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex);

            o.Normal = UnpackNormal(tex2D(_NormalTex, IN.uv_NormalTex));
            o.Albedo = c.rgb;
            o.Alpha = c.a;
            o.noise = noise; 
        }

        half4 LightingCustom (SurfaceOutputCustom s, half3 lightDir, half3 viewDir) {
            float NdotL = max(0, dot(s.Normal, lightDir));

            float invStep = 1.0/_Step;
            fixed post = posterize(NdotL, _Step);
            fixed bar = step(NdotL, post) - step(NdotL, post-s.noise/_Step);

            fixed b = (1-bar) * post + bar * (post+invStep);
            half3 l = (s.Albedo * b + _AmbientColor * _AmbientStrength);
        
            half4 col;
            col.rgb = l;
            col.a = s.Alpha;
            
            return col;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
