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
    uniform vec4 mainColor;
uniform float gridSize;
uniform float dashLength;
uniform float dashWidthPixels;
varying vec2 gridPosition;
varying float pixelToMeterFactor;
void main()
{
    float x = gridPosition.x;
    float y = gridPosition.y;
    float cellX = x - (gridSize * floor(x / gridSize));
    float cellY = y - (gridSize * floor(y / gridSize));
    cellX = min(cellX, gridSize - cellX);
    cellY = min(cellY, gridSize - cellY);
    float distanceToEdge = min(cellX, cellY);
    float phase = max(cellX, cellY);
    float dashPhase = phase - (dashLength * floor(phase / dashLength));
    dashPhase = min(dashPhase, dashLength - dashPhase) - 0.25 * dashLength + dashWidthPixels;
    float distanceToEdgePixels = max(distanceToEdge / pixelToMeterFactor, dashPhase);
    gl_FragColor = antiAliasedBorder(distanceToEdgePixels, dashWidthPixels / 2.0, dashWidthPixels,
                                     mainColor, vec4(0.5, 0.5, 0.5, 0.5));
}
