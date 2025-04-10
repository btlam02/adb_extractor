precision highp int;
precision highp float;
 #include <OgreUnifiedShader.h>
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
mat3 mat4ToMat3(mat4 m) { return mat3(m[0].xyz, m[1].xyz, m[2].xyz); }
    uniform float screenHeight;
varying vec2 gridPosition;
varying float pixelToMeterFactor;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
attribute vec4 position;
void main()
{
    gl_Position = projectionMatrix * modelViewMatrix * position;
    pixelToMeterFactor = calculatePixelToMeterFactor(modelMatrix * position, screenHeight,
                                                     viewMatrix, projectionMatrix);
    gridPosition = (modelMatrix * position).xy;
}
