precision highp int;
precision highp float;
 #include <OgreUnifiedShader.h>
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
mat3 mat4ToMat3(mat4 m) { return mat3(m[0].xyz, m[1].xyz, m[2].xyz); }
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
    uniform mat4 modelMatrix;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform vec3 cameraPosition;
attribute vec4 position;
attribute vec3 normal;
attribute vec2 uv0;
uniform vec2 pixelSize;
uniform float averageDepth;
uniform float lineWidth;
uniform float lineGapWidth;
uniform float lineOpacity;
uniform float up;
void main()
{
    vec4 scaledPosition = upScalePoint(position, modelMatrix);
    float normalScale = length(normal);
    vec3 scaledNormal = applyElevationScaleOnNormal(normal);
    vec4 sPosition = modelViewMatrix * scaledPosition;
    float depth = abs(sPosition.z);
    float aspect = projectionMatrix[1][1] / projectionMatrix[0][0];
    mat4 mvp = projectionMatrix * modelViewMatrix;
    vec4 pos = mvp * scaledPosition;
    vec4 pos2 = mvp * (scaledPosition + vec4(scaledNormal, 0.0));
    vec2 lineNormal = pos2.xy / abs(pos2.w) - pos.xy / abs(pos.w);
    lineNormal = normalScale > 0.0
                     ? normalize(vec2(-lineNormal.y / aspect, lineNormal.x)) * normalScale
                     : vec2(0.0, 0.0);
    float perspectiveFactor = (1.0 - (depth / averageDepth)) * 0.5;
    float perspectiveScale = clamp(1.0 + perspectiveFactor, 0.25, 2.0);
    vLineData = vec3(lineWidth * perspectiveScale, lineGapWidth * perspectiveScale, lineOpacity);
    vHalfWidth = calculateHalfWidth(vLineData[0], vLineData[1]);
    vec2 screenToView = 2.0 * pixelSize;
    pos.xy += lineNormal.xy * depth * vHalfWidth * screenToView;
    gl_Position = pos;
    gl_Position.z -= up;
    vUV_x = uv0.x;
    vUV_y = uv0.y;
    vHazeColor = calculateHaze((modelMatrix * scaledPosition).xyz, cameraPosition);
}
