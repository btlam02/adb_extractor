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
    uniform mat4 modelMatrix;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform vec3 cameraPosition;
attribute vec4 position;
attribute vec2 uv0;
varying vec2 vUvLow;
varying vec2 vUvHigh;
varying float vSkyColorFactor;
void main()
{
    vec4 worldPosition = modelMatrix * position;
    vSkyColorFactor = calculateHazeAltitudeFactor(cameraPosition.z);
    const float textureHeight = 90000.0;
    vUvHigh = vec2(uv0.x, 1.0 - worldPosition.z / textureHeight);
    vUvLow = vec2(uv0.x, 1.0 - worldPosition.z / textureHeight / mix(2.0, 3.0, vSkyColorFactor));
    gl_Position = projectionMatrix * modelViewMatrix * position;
}
