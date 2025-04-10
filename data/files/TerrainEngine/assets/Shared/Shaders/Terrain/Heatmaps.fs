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
    varying vec2 nightlyHeatmapUV;
varying vec2 weeklyHeatmapUV;
varying vec2 globalHeatmapUV;
varying vec2 personalHeatmapUV;
uniform sampler2D _WeeklyHeatmapTex;
uniform sampler2D _WeeklyHeatmapColorMapTex;
uniform sampler2D _GlobalHeatmapTex;
uniform sampler2D _GlobalHeatmapColorMapTex;
uniform sampler2D _PersonalHeatmapTex;
uniform sampler2D _PersonalHeatmapColorMapTex;
uniform sampler2D _NightlyHeatmapTex;
uniform int nightlyHeatmapEnabled;
uniform int weeklyHeatmapEnabled;
uniform int globalHeatmapEnabled;
uniform int personalHeatmapEnabled;
uniform float weeklyHeatmapOpacity;
uniform float globalHeatmapOpacity;
uniform float personalHeatmapOpacity;
const float kHalfColorMapPixel = 0.5 / 255.0;
vec4 queryColorMap(sampler2D colorMap, float intensity)
{
    vec2 coords = vec2(mix(kHalfColorMapPixel, 1.0 - kHalfColorMapPixel, intensity), 0.5);
    return texture2D(colorMap, coords);
}
vec4 queryColorMapForPersonalHeatmap(sampler2D colorMap, float intensity)
{
    vec4 color = queryColorMap(colorMap, intensity);
    color.a = linearRamp(intensity, 0.0, 20.0 / 255.0);
    return color;
}
vec4 applyColorMap(sampler2D colorMap, float intensity)
{
    return preMultiplyColor(queryColorMap(colorMap, intensity));
}
vec4 applyColorMapForPersonalHeatmap(sampler2D colorMap, float intensity)
{
    return preMultiplyColor(queryColorMapForPersonalHeatmap(colorMap, intensity));
}
void main()
{
    vec4 blendedColor = vec4(0.0);
    if (nightlyHeatmapEnabled != 0)
    {
        vec4 nightlyHeatmapColor = texture2D(_NightlyHeatmapTex, nightlyHeatmapUV);
        nightlyHeatmapColor.rgb *= nightlyHeatmapColor.a;
        blendedColor = premultipliedAlphaBlend(blendedColor, nightlyHeatmapColor);
    }
    if (weeklyHeatmapEnabled != 0)
    {
        float weeklyHeatmapIntensity = texture2D(_WeeklyHeatmapTex, weeklyHeatmapUV).r;
        vec4 weeklyHeatmapColor = applyColorMap(_WeeklyHeatmapColorMapTex, weeklyHeatmapIntensity);
        weeklyHeatmapColor *= weeklyHeatmapOpacity;
        blendedColor = premultipliedAlphaBlend(blendedColor, weeklyHeatmapColor);
    }
    if (globalHeatmapEnabled != 0)
    {
        float globalHeatmapIntensity = texture2D(_GlobalHeatmapTex, globalHeatmapUV).r;
        vec4 globalHeatmapColor = applyColorMap(_GlobalHeatmapColorMapTex, globalHeatmapIntensity);
        globalHeatmapColor *= globalHeatmapOpacity;
        blendedColor = premultipliedAlphaBlend(blendedColor, globalHeatmapColor);
    }
    if (personalHeatmapEnabled != 0)
    {
        float personalHeatmapIntensity = texture2D(_PersonalHeatmapTex, personalHeatmapUV).r;
        vec4 personalHeatmapColor =
            applyColorMapForPersonalHeatmap(_PersonalHeatmapColorMapTex, personalHeatmapIntensity);
        personalHeatmapColor *= personalHeatmapOpacity;
        blendedColor = premultipliedAlphaBlend(blendedColor, personalHeatmapColor);
    }
    gl_FragColor = blendedColor;
}
