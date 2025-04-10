precision highp int;
precision highp float;
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
 #include <OgreUnifiedShader.h>
    uniform vec4 mainColor;
uniform float gridSize;
varying vec2 _uv;
varying float transitionAlpha;
varying float pixelToMeterFactor;
void main()
{
    float distanceFromCenter = sqrt(_uv.x * _uv.x / 2.0 + _uv.y * _uv.y / 2.0);
    float distanceFromCenterPixels = distanceFromCenter * gridSize / pixelToMeterFactor;
    float expandValue = transitionAlpha;
    float fillAmountPixels = expandValue * gridSize / pixelToMeterFactor;
    vec4 fillColor = mainColor * transitionAlpha;
    gl_FragColor =
        antiAliasedBorder(distanceFromCenterPixels, 0.0, fillAmountPixels, fillColor, fillColor);
}
