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
    uniform float screenHeight;
uniform float radius;
varying vec3 vertexPosition;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 projectionMatrix;
attribute vec4 position;
void main()
{
    vec3 centerPos = vec3(modelMatrix[3][0], modelMatrix[3][1], modelMatrix[3][2]);
    vec4 scaledCenterPos = upScalePoint(vec4(centerPos, 1.0));
    float offsetCenterZ = scaledCenterPos.z - centerPos.z;
    vec4 sVertexPosition = projectionMatrix * viewMatrix * scaledCenterPos;
    float screenToView = 2.0 / screenHeight;
    float extraRadius = 1.0;
    vertexPosition = normalize(position.xyz) * (radius + extraRadius);
    float aspect = projectionMatrix[1][1] / projectionMatrix[0][0];
    vec3 offset = vertexPosition * vec3(1.0 / aspect, 1.0, 1.0);
    offset.xy *= abs(sVertexPosition.w) * screenToView;
    sVertexPosition.xyz += offset;
    gl_Position = sVertexPosition;
}
