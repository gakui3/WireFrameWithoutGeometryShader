Shader "Unlit/WireFrame"
{
    Properties
    {
        [HDR] _WireframeColor ("Wireframe Color", Color) = (1,1,1)
        [ToggleOff] _WireframeVisible("Wireframe Visible", Float) = 0.0
        _WireframeColorIntencity("_WireframeColorIntencity", Float) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline" = "UniversalPipeline" }

        Blend SrcAlpha OneMinusSrcAlpha
		ZWrite Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            float4 _WireframeColor;
            float _WireframeColorIntencity;
            float _WireframeVisible;

            uniform float _CircleRadius;
            uniform float _UneUneValue;
            uniform float _VirticalValue;
            uniform float _HorizontalValue;

            struct Attributes
            {
                float4 position   : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD;
            };

            struct v2f
            {
                float4 position  : SV_POSITION;
                float2 uv : TEXCOORD;
                float mask : TEXCOORD1;
            };

            float rand( float2 co ){
                return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
            }

            float distanceSq(float2 pt1, float2 pt2)
            {
                float2 v = pt2 - pt1;
                return dot(v,v);
            }

            float minimum_distance(float2 v, float2 w, float2 p) {
                // Return minimum distance between line segment vw and point p
                float l2 = distanceSq(v, w);  // i.e. |w-v|^2 -  avoid a sqrt
                // Consider the line extending the segment, parameterized as v + t (w - v).
                // We find projection of point p onto the line. 
                // It falls where t = [(p-v) . (w-v)] / |w-v|^2
                // We clamp t from [0,1] to handle points outside the segment vw.
                float t = max(0, min(1, dot(p - v, w - v) / l2));
                float2 projection = v + t * (w - v);  // Projection falls on the segment
                return distance(p, projection);
            }

            float circle(float3 pos, float thickness){
                float3 center = float3(0, 0, 1.45);

                float d = distance(pos.xz, center.xz);
                float v = 0;

                if(d > _CircleRadius - thickness && d < _CircleRadius)
                    v = 1.5;
                
                return v;
            }

            float virtical(float3 pos){
                float v = 1;

                // if(pos.y < _VirticalValue)
                //     v = 0;
                
                return v;
            }

            // float4 horizontal(float3 pos, float thickness){
            //     float d = distance(pos.z, _HorizontalValue);
            //     float4 v = float4(1, 1, 1, 1);

            //     if(d < thickness)
            //         v = _CircleColor;
                
            //     return v;
            // }

            v2f vert(Attributes IN)
            {
                v2f o;
                float4 pos = IN.position;
                pos.xyz = pos.xyz + IN.normal*rand(pos.xz*_Time.x)*_UneUneValue;

                o.position = TransformObjectToHClip(pos.xyz);
                o.uv = IN.uv;

                float3 wpos = TransformObjectToWorld(pos.xyz);
                float mask = virtical(wpos);
                o.mask = mask;

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float lineWidthInPixels = 0.5;
                float lineAntiaAliasWidthInPixels = 1;

                float2 uVector = float2(ddx(i.uv.x),ddy(i.uv.x)); //also known as tangent vector
                float2 vVector = float2(ddx(i.uv.y),ddy(i.uv.y)); //also known as binormal vector
                // float2 uVector = float2(1, 0);
                // float2 vVector = float2(0, 1);

                float vLength = length(uVector);
                float uLength = length(vVector);
                float uvDiagonalLength = length(uVector+vVector);

                float maximumUDistance = lineWidthInPixels * vLength;
                float maximumVDistance = lineWidthInPixels * uLength;
                float maximumUVDiagonalDistance = lineWidthInPixels * uvDiagonalLength;

                float leftEdgeUDistance = i.uv.x;
                float rightEdgeUDistance = (1.0-leftEdgeUDistance);

                float bottomEdgeVDistance = i.uv.y;
                float topEdgeVDistance = 1.0 - bottomEdgeVDistance;

                float minimumUDistance = min(leftEdgeUDistance,rightEdgeUDistance);
                float minimumVDistance = min(bottomEdgeVDistance,topEdgeVDistance);
                float uvDiagonalDistance = minimum_distance(float2(0.0,1.0),float2(1.0,0.0),i.uv);

                float normalizedUDistance = minimumUDistance / maximumUDistance;
                float normalizedVDistance = minimumVDistance / maximumVDistance;
                float normalizedUVDiagonalDistance = uvDiagonalDistance / maximumUVDiagonalDistance;


                float closestNormalizedDistance = min(normalizedUDistance,normalizedVDistance);
                closestNormalizedDistance = min(closestNormalizedDistance,normalizedUVDiagonalDistance);


                float lineAlpha = 1.0 - smoothstep(1.0,1.0 + (lineAntiaAliasWidthInPixels/lineWidthInPixels),closestNormalizedDistance);

                lineAlpha *= 1;
                
                return float4(1, 1, 1, lineAlpha) * _WireframeColor * _WireframeColorIntencity * i.mask;
            }
            ENDHLSL
        }
    }
}
