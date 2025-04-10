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
uniform float width;
uniform float height;
uniform float widthUV;
uniform float heightUV;
uniform float averageDepth;
uniform float scale;
uniform float bufferWidth;
uniform float bufferHeight;
uniform float offsetX;
uniform float offsetY;
uniform float pixelRatio;
uniform vec2 pixelSize;
uniform vec3 cameraPosition;
uniform mat4 modelMatrix;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
attribute vec4 position;
attribute vec2 uv0;
attribute float secondary_colour;
uniform float up;
uniform float opacity;
varying float vOpacity;
varying vec4 vHazeColor;
varying vec2 vUv;
void main()
{
    vec4 scaledPosition = upScalePoint(position, modelMatrix);
    vOpacity = opacity;
    vec4 sPosition = projectionMatrix * modelViewMatrix * scaledPosition;
    float perspectiveScale = clamp(0.5 + 0.5 * (averageDepth / sPosition.w), 0.5, 1.25);
    float totalScale = scale * perspectiveScale;
    vec2 screenSize = vec2(bufferWidth, bufferHeight) / 2.0;
    sPosition.xy = floor(sPosition.xy * screenSize / sPosition.w) / screenSize * sPosition.w;
    vec2 screenToView = 2.0 * pixelSize;
    float sizeToScreen = 1.0 / 2.0;
    sPosition.xy +=
        ((
             (uv0 * vec2(width * widthUV, height * heightUV) + 2.0 * vec2(offsetX, -offsetY))) *
         (sPosition.w * totalScale * sizeToScreen * screenToView));
    gl_Position = sPosition;
    gl_Position.z -= up;
    vUv.x = uv0.x > 0.0 ? 1.0 : 0.0;
    vUv.y = uv0.y < 0.0 ? 1.0 : 0.0;
    vUv.x = (vUv.x - 0.5) * widthUV + 0.5;
    vUv.y = (vUv.y - 0.5) * heightUV + 0.5;
    vHazeColor = calculateHaze((modelMatrix * scaledPosition).xyz, cameraPosition);
}
