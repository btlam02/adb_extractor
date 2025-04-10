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
    uniform sampler2D _MainTex;
uniform sampler2D _Gradient;
uniform sampler2D _GeneratedTex;
uniform float tileOutlineWidth;
uniform float renderingParameters[6];
uniform float lightExaggerationFactor;
uniform vec3 viewLightDirection;
vec3 addAtmosphericHaze(vec3 color) { return mix(color, vHazeColor.rgb, vHazeColor.a); }
void main()
{
    vec3 textureNormal = texture2D(_Gradient, vGradientUv).rgb;
    textureNormal.xy = textureNormal.xy * 2.0 - 1.0;
    textureNormal.y = -textureNormal.y;
    textureNormal = applyMercatorScaleOnNormal(textureNormal);
    vec2 gPos;
    vec3 terrainColor = texture2D(_MainTex, vUv).rgb;
    terrainColor = addAtmosphericHaze(terrainColor);
    {
        float litTerrain = clamp(-dot(textureNormal, viewLightDirection), 0.0, 1.0);
        litTerrain = litTerrain * 1.2;
        litTerrain = pow(litTerrain, 40.0);
        litTerrain = min(litTerrain + 0.4, 1.7);
        litTerrain = mix(1.0, litTerrain, lightExaggerationFactor);
        terrainColor *= litTerrain;
    }
    vec4 overlayColor = vec4(0.0);
    vec4 generatedColor = texture2D(_GeneratedTex, vGeneratedUv);
    generatedColor.a = vDistanceAlpha * generatedColor.a;
    if (tileOutlineWidth > 0.0)
    {
        if (vUv.x < 0.05) terrainColor.r = 0.7;
        if (vUv.y < 0.05) terrainColor.r = 0.7;
    }
    vec4 c = adjustRenderingParameters(vec4(terrainColor, 1.0), renderingParameters[0],
                                       renderingParameters[1]);
    overlayColor =
        adjustRenderingParameters(overlayColor, renderingParameters[4], renderingParameters[5]);
    c.rgb = mix(c.rgb, overlayColor.rgb, overlayColor.a);
    c.rgb = mix(c.rgb, generatedColor.rgb, generatedColor.a);
    gl_FragColor = c;
}
