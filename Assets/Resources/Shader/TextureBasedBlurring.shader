Shader "Unlit/TextureBasedBlurring"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurTex ("BlurMap", 2D) = "black" {}
        _Sample  ("Sample", Range(4, 32)) = 16
        _Effect  ("Effect", float) = 1
        _Radius  ("Radius", float) = 0.1
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
            // make fog work
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

            sampler2D _MainTex;
            sampler2D _BlurTex;
            float4 _MainTex_ST;
            float4 _BlurTex_ST;
            float _Sample;
            float _Effect;
            float _Radius;
            
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
                float4 blurOffset = tex2D(_BlurTex, i.uv);
                float4 blurVector = 1 - float4(blurOffset.r, blurOffset.g,0,0);
                float dist = length(blurVector) + 1;
                float2 dir = normalize(blurVector) * 10;
                for(int j = 0; j < _Sample; j++)
                {
                    float scale = (j / _Sample);
                    float2 offset = dir * scale;
                    //  가운대 집중형
                    //col += tex2D(_MainTex, i.uv + ((i.uv + float2(-.5,-.5)) * (offset)) * .5);
                    float2 subDir = tex2D(_BlurTex, i.uv + (offset) * .02).rg;
                    subDir = smoothstep(0, 1, (1 - subDir));
                    dist = length(subDir) + 1;
                    col += tex2D(_MainTex, i.uv + ((i.uv - subDir) * (offset*0.02)) * _Effect / dist);
                }
                //col = tex2D(_MainTex, i.uv);
                col /= (_Sample);
                // apply fog
                //(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
