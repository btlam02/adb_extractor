precision highp int;
precision highp float;
 #include <OgreUnifiedShader.h>
float calculateHalfWidth_(float lineWidth, float lineGapWidth)
{
    return lineGapWidth == 0.0 ? lineWidth / 2.0 : lineGapWidth / 2.0 + lineWidth;
}
float calculateHalfWidth(float lineWidth, float lineGapWidth)
{
    return 1.0 + calculateHalfWidth_(lineWidth, lineGapWidth);
}
varying float vUV_x;
varying float vUV_y;
varying vec3 vLineData;
varying float vHalfWidth;
varying vec4 vHazeColor;
    varying vec4 oColor;
float antialiasedBorder(float value, float border)
{
    float epsilon = 0.2;
    float f = (value - border + epsilon) / (epsilon * 2.0);
    f = clamp(f, 0.0, 1.0);
    return f;
}
float calculateFactor(float distanceFromCenter, float lineGapWidth, float lineWidth)
{
    return lineGapWidth == 0.0
               ? antialiasedBorder(lineWidth / 2.0, distanceFromCenter)
               : antialiasedBorder(distanceFromCenter, lineGapWidth / 2.0) *
                     antialiasedBorder(lineGapWidth / 2.0 + lineWidth, distanceFromCenter);
}
vec4 calculateColor(float distanceFromCenter, vec3 lineData, vec4 lineColor, float lineDash,
                    float lineDashGap, float opacityMultiplier)
{
    float lineWidth = lineData[0];
    float lineGapWidth = lineData[1];
    float lineOpacity = lineData[2];
    vec4 color = lineColor;
    color.a *= lineOpacity * opacityMultiplier;
    float lineFactor = calculateFactor(distanceFromCenter, lineGapWidth, lineWidth);
    color.a *= lineFactor;
    return color;
}
uniform vec4 lineColor;
uniform float lineDash;
uniform float lineDashGap;
uniform float opacityMultiplier;
uniform float visibleDistance;
uniform float fadeOutLength;
void main()
{
    float fadeOutLength = 0.0;
    if (
        (visibleDistance >= 0.0) &&
        (vUV_y >= visibleDistance))
    {
        gl_FragColor = vec4(0.0);
        return;
    }
    float distanceFromCenter = abs(vUV_x - 0.5) / 0.5 * vHalfWidth;
    vec4 baseColor = lineColor;
    baseColor = oColor;
    vec4 color = calculateColor(distanceFromCenter, vLineData, baseColor, lineDash, lineDashGap,
                                opacityMultiplier);
    color.rgb = mix(color.rgb, vHazeColor.rgb, vHazeColor.a);
    if (fadeOutLength > 0.0)
    {
        float vertexDistance = vUV_y;
        float fadeOutStart = visibleDistance - fadeOutLength;
        float fadeOutEnd = visibleDistance;
        float alpha = 1.0 - clamp((vertexDistance - fadeOutStart) / fadeOutLength, 0.0, 1.0);
        color.a *= alpha;
    }
    color.rgb *= color.a;
    gl_FragColor = color;
}
