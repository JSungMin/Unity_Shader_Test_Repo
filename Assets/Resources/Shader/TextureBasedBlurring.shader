Shader "Unlit/TextureBasedBlurring"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurTex ("BlurMap", 2D) = "black" {}
        _Sample  ("Sample", Range(4, 32)) = 16
        _Effect  ("Effect", float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
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

            sampler2D _MainTex;
            sampler2D _BlurTex;
            sampler2D _CameraDepthTexture;
            sampler2D _CameraDepthNormalsTexture;
            
            float4 _MainTex_ST;
            float4 _BlurTex_ST;
            float _Sample;
            float _Effect;

            float3 DecodeNormal(float4 enc)
            {
                float kScale = 1.7777;
                float3 nn = enc.xyz*float3(2*kScale,2*kScale,0) + float3(-kScale,-kScale,1);
                float g = 2.0 / dot(nn.xyz,nn.xyz);
                float3 n;
                n.xy = g*nn.xy;
                n.z = g-1;
                return n;
            }
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = fixed4(0,0,0,0);
                //  R = X, G = Y => RG = UV offset
                float4 oOffset = tex2D(_BlurTex, i.uv);
                float2 oDir = (oOffset.rg);
                float oIntensity = oOffset.b;
                oIntensity = pow(oIntensity, 3);
                float pIntensity = oIntensity;
                float2 pDir = oDir;
                float3 screenNormal = DecodeNormal(tex2D(_CameraDepthNormalsTexture, i.uv));
                float screenDepth = tex2D(_CameraDepthTexture, i.uv).r;
                
                for(int j = 0; j < _Sample; j++)
                {
                    float scale = (j/_Sample);
                    float2 cCoord = i.uv + (.5 - i.uv) * pDir*pIntensity*scale*_Effect*.5;
                    float4 offset = tex2D(_BlurTex, cCoord);
                    pDir = (offset.rg);
                    pIntensity = offset.b;
                    pIntensity = pow(pIntensity, 3);
                    col += tex2D(_MainTex, cCoord);
                }
                col /= _Sample;
                return col;
            }
            ENDCG
        }
    }
}
