precision highp int;
precision highp float;
 #include <OgreUnifiedShader.h>
mat3 mat4ToMat3(mat4 m) { return mat3(m[0].xyz, m[1].xyz, m[2].xyz); }
 const int kSC_SymbolCullingDistanceFactor = 4;
 const int kSC_OSMTileCullingDistanceFactor = 4;
 const int kSC_UseOSMDataFromAncestorDiff = 1;
 const int kSC_MaxOSMLevelFromServer = 15;
  const float kSC_Skybox_MinVisibleDistance = 500000.0;
  const float kSC_Skybox_Height = 1000000.0;
  const float kSC_UserMarker_OuterCircleRadius = 12.0;
 const float kSC_CameraFOV = 42.0;
 const float kSC_ElevationExaggerationMinHeightRange = 200.0;
 const float kSC_ElevationExaggerationMinHeightRangeFactor = 1.9;
 const float kSC_ElevationExaggerationMaxHeightRange = 2000.0;
 const float kSC_ElevationExaggerationMaxHeightRangeFactor = 1.15;
 const float kSC_FlatModeExaggeration = 0.1;
uniform float mercatorScale;
uniform float elevationExaggerationFactor;
vec4 upScalePoint(vec4 point, mat4 modelMatrix)
{
    vec4 scaledPoint = point;
    float offsetZ = modelMatrix[3][2];
    scaledPoint.z =
        (scaledPoint.z + offsetZ) * mercatorScale * elevationExaggerationFactor - offsetZ;
    return scaledPoint;
}
vec4 upScalePoint(vec4 vec)
{
    vec4 scaledVec = vec;
    scaledVec.z *= mercatorScale * elevationExaggerationFactor;
    return scaledVec;
}
vec3 _applyScaleOnNormal(vec3 vec, float scale)
{
    vec3 scaledVec = vec;
    scaledVec.xy *= scale;
    return normalize(scaledVec);
}
vec3 applyElevationScaleOnNormal(vec3 vec)
{
    return _applyScaleOnNormal(vec, mercatorScale * elevationExaggerationFactor);
}
vec3 applyMercatorScaleOnNormal(vec3 vec) { return _applyScaleOnNormal(vec, mercatorScale); }
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
varying vec4 vHazeColor;
varying vec2 vGeneratedUv;
varying float vDistanceAlpha;
varying vec2 vGradientUv;
const float kHazeAltitudeFadeoff = 100000.0;
const float kHazeDistancePowerLow = 0.8;
const float kHazeDistancePowerHigh = 0.8;
vec4 kHazeColorLow0 = vec4(0.67, 0.80, 0.94, 0.95);
vec4 kHazeColorLow1 = vec4(0.77, 0.87, 0.94, 0.0);
vec4 kHazeColorHigh0 = vec4(0.81, 0.79, 0.80, 0.95);
vec4 kHazeColorHigh1 = vec4(0.64, 0.75, 0.82, 0.0);
float calculateVisibleDistance(float cameraPositionZ)
{
    float cameraAltitude = max(1.0, cameraPositionZ);
    float radius = 6367444.65712;
    float visibleDistance =
        sqrt((radius + cameraAltitude) * (radius + cameraAltitude) - radius * radius);
    visibleDistance = max(kSC_Skybox_MinVisibleDistance, visibleDistance);
    visibleDistance += max(0.0, (cameraPositionZ - kSC_Skybox_Height / 2.0) * 10.0);
    return visibleDistance;
}
float calculateHazeAltitudeFactor(float altitude) { return exp(-altitude / kHazeAltitudeFadeoff); }
float calculateHazeDistanceFactor(float vertexDistance, float visibleDistance, float powerFactor)
{
    vertexDistance = min(vertexDistance, visibleDistance);
    return smoothstep(0.0, 1.0, pow(vertexDistance / visibleDistance, powerFactor));
}
vec4 calculateHaze(vec3 vertexWorldPos, vec3 cameraPosition)
{
    vec3 dir = vertexWorldPos - cameraPosition;
    float visibleDistance = calculateVisibleDistance(cameraPosition.z);
    float vertexDistance = length(dir.xy);
    float altitudeFactor = calculateHazeAltitudeFactor(cameraPosition.z);
    float vertexDistanceLow = visibleDistance / mix(1.0, 2.5, altitudeFactor);
    vec4 hazeColor = mix(
        mix(kHazeColorHigh1, kHazeColorHigh0,
            calculateHazeDistanceFactor(vertexDistance, visibleDistance, kHazeDistancePowerHigh)),
        mix(kHazeColorLow1, kHazeColorLow0,
            calculateHazeDistanceFactor(vertexDistance, vertexDistanceLow, kHazeDistancePowerLow)),
        altitudeFactor
    );
    return hazeColor;
}
uniform float averageDepth;
float getDistanceAlpha(float vertexDistance)
{
    float fadeStart = averageDepth * 1.0;
    float fadeEnd = averageDepth * 10.0;
    float distanceAlpha = 1.0 - (vertexDistance - fadeStart) / (fadeEnd - fadeStart);
    distanceAlpha = clamp(distanceAlpha, 0.0, 1.0);
    return distanceAlpha;
}
    attribute vec4 position;
attribute vec3 normal;
attribute vec2 uv0;
uniform mat4 modelMatrix;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform vec3 cameraPosition;
uniform vec4 _MainTexTransform;
uniform vec4 _GradientTransform;
uniform vec4 _GeneratedTexTransform;
uniform vec4 _TopoTransform;
vec2 CalculateUV(vec4 ipos, vec4 texTransform)
{
    return (ipos.xy - texTransform.xy) / texTransform.zw;
}
vec4 calc_vertex_pos(vec2 _uv)
{
    vec3 outPos = position.xyz;
    vUv = CalculateUV(vec4(outPos, 1.0), _MainTexTransform);
    vGradientUv = CalculateUV(vec4(outPos, 1.0), _GradientTransform);
    vec4 scaledPosition = upScalePoint(position);
    {
        vec3 vertexWorldPos = (modelMatrix * scaledPosition).xyz;
        vHazeColor = calculateHaze(vertexWorldPos, cameraPosition);
    }
    vec4 _position = projectionMatrix * modelViewMatrix * scaledPosition;
    vGeneratedUv = CalculateUV(vec4(outPos, 1.0), _GeneratedTexTransform);
    vDistanceAlpha = getDistanceAlpha(_position.w);
    return _position;
}
void main() { gl_Position = calc_vertex_pos(uv0); }
