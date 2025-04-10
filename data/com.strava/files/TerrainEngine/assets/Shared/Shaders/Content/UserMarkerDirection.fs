precision highp int;
precision highp float;
 #include <OgreUnifiedShader.h>
    uniform vec4 mainColor;
varying vec3 vVertex;
void main()
{
    float tan30 = 0.577;
    bool isDirectionPixel = vVertex.y > 0.0 && (abs(vVertex.x) / vVertex.y < tan30);
    float d = length(vVertex.xy);
    bool isInRadius = d <= 1.0;
    float radialGradient = mix(0.6, 0.2, smoothstep(0.5, 1.0, d));
    float alpha = (isDirectionPixel && isInRadius) ? mainColor.a * radialGradient : 0.0;
    gl_FragColor = vec4(mainColor.rgb, alpha);
}
