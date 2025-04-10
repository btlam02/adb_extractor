precision highp int;
precision highp float;
 #include <OgreUnifiedShader.h>
    attribute vec4 position;
uniform float mercatorScale;
uniform float elevationExaggerationFactor;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform vec4 _NightlyHeatmapTexTransform;
uniform vec4 _WeeklyHeatmapTexTransform;
uniform vec4 _GlobalHeatmapTexTransform;
uniform vec4 _PersonalHeatmapTexTransform;
uniform int weeklyHeatmapEnabled;
uniform int globalHeatmapEnabled;
uniform int nightlyHeatmapEnabled;
uniform int personalHeatmapEnabled;
varying vec2 nightlyHeatmapUV;
varying vec2 weeklyHeatmapUV;
varying vec2 globalHeatmapUV;
varying vec2 personalHeatmapUV;
vec4 upScalePoint(vec4 vec)
{
    vec4 scaledVec = vec;
    scaledVec.z *= mercatorScale * elevationExaggerationFactor;
    return scaledVec;
}
vec2 CalculateUV(vec4 ipos, vec4 texTransform)
{
    return (ipos.xy - texTransform.xy) / texTransform.zw;
}
void main()
{
    vec3 outPos = position.xyz;
    if (nightlyHeatmapEnabled != 0)
    {
        nightlyHeatmapUV = CalculateUV(vec4(outPos, 1.0), _NightlyHeatmapTexTransform);
    }
    if (weeklyHeatmapEnabled != 0)
    {
        weeklyHeatmapUV = CalculateUV(vec4(outPos, 1.0), _WeeklyHeatmapTexTransform);
    }
    if (globalHeatmapEnabled != 0)
    {
        globalHeatmapUV = CalculateUV(vec4(outPos, 1.0), _GlobalHeatmapTexTransform);
    }
    if (personalHeatmapEnabled != 0)
    {
        personalHeatmapUV = CalculateUV(vec4(outPos, 1.0), _PersonalHeatmapTexTransform);
    }
    vec4 scaledPosition = upScalePoint(position);
    gl_Position = projectionMatrix * modelViewMatrix * scaledPosition;
}
