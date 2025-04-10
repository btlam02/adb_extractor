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
float calculatePixelToMeterFactor(vec4 scaledCenterPos, float screenHeight, mat4 viewMatrix,
                                  mat4 projectionMatrix)
{
    vec4 screenPos1 = projectionMatrix * viewMatrix * scaledCenterPos;
    screenPos1.xy /= abs(screenPos1.w);
    float distance = abs(screenPos1.w) / 20.0;
    vec4 position2 = viewMatrix * scaledCenterPos;
    position2.y += distance;
    vec4 screenPos2 = projectionMatrix * position2;
    screenPos2.xy /= abs(screenPos2.w);
    vec2 screenDiff = screenPos1.xy - screenPos2.xy;
    float screenDistance = length(screenDiff);
    float screenToView = 2.0 / screenHeight;
    float pixelDistance = screenDistance / screenToView;
    return distance / pixelDistance;
}
float edgeAntiAliasing(float distance, float edge)
{
    float halfPixel = 0.5;
    return smoothstep(edge - halfPixel, edge + halfPixel, distance);
}
vec4 antiAliasedBorder(float distance, float borderStart, float borderEnd, vec4 mainColor,
                       vec4 borderColor)
{
    float alphaBorder = edgeAntiAliasing(distance, borderStart);
    float alphaOutside = edgeAntiAliasing(distance, borderEnd);
    vec4 col = mix(mainColor, borderColor, alphaBorder);
    col = mix(col, vec4(borderColor.rgb, 0), alphaOutside);
    return col;
}
vec4 unitBoxVertex(vec4 pos)
{
    pos.xyz = normalize(pos.xyz) * 1.4142;
    return pos;
}
    uniform float screenHeight;
varying vec3 vVertex;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 projectionMatrix;
attribute vec4 position;
void main()
{
    float sizeInPixels = 48.0;
    vec4 centerPos = vec4(modelMatrix[3][0], modelMatrix[3][1], modelMatrix[3][2], 1.0);
    vec4 scaledCenterPos = upScalePoint(centerPos);
    float pixelToMeterFactor =
        calculatePixelToMeterFactor(scaledCenterPos, screenHeight, viewMatrix, projectionMatrix);
    vec3 normalizedVertex = unitBoxVertex(position).xyz;
    vec3 rotatedVertex = mat4ToMat3(modelMatrix) * normalizedVertex;
    vec4 pos = scaledCenterPos;
    vec3 offset = rotatedVertex * (sizeInPixels * pixelToMeterFactor);
    pos.xyz += offset;
    vVertex = normalizedVertex;
    gl_Position = projectionMatrix * viewMatrix * pos;
}
