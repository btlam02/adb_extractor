precision highp int;
precision highp float;
 #include <OgreUnifiedShader.h>
    uniform sampler2D tex;
varying float vOpacity;
uniform float opacityMultiplier;
varying vec4 vHazeColor;
varying vec2 vUv;
void main()
{
    vec4 c = texture2D(tex, vUv);
    float alpha = vOpacity;
    c.rgb = mix(c.rgb, vHazeColor.rgb, vHazeColor.a);
    gl_FragColor = vec4(c.rgb, c.a * alpha * opacityMultiplier);
}
