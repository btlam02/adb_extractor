precision highp int;
precision highp float;
 #include <OgreUnifiedShader.h>
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
vec4 adjustRenderingParameters(vec4 color, float brightness, float saturation)
{
    vec3 c = color.rgb;
    c = rgb2hsv(c);
    c.y *= saturation;
    c = hsv2rgb(c);
    c = c * brightness;
    return vec4(c, color.a);
}
vec4 preMultiplyColor(vec4 color)
{
    color.rgb *= color.a;
    return color;
}
vec4 premultipliedAlphaBlend(vec4 bgColor, vec4 fgColor)
{
    return fgColor + (1.0 - fgColor.a) * bgColor;
}
float linearRamp(float x, float x0, float x1) { return clamp((x - x0) / (x1 - x0), 0.0, 1.0); }
    varying vec2 vUv;
uniform sampler2D _WinterImageryTex;
uniform float winterImageryFadeOutFactor;
uniform float renderingParameters[6];
void main()
{
    vec4 color = texture2D(_WinterImageryTex, vUv);
    color = adjustRenderingParameters(color, renderingParameters[0], renderingParameters[1]);
    color.a *= winterImageryFadeOutFactor;
    gl_FragColor = color;
}
