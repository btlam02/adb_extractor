precision highp int;
precision highp float;
 #include <OgreUnifiedShader.h>
varying vec2 vUv;
    uniform sampler2D tex;
uniform float opacity;
uniform float opacityMultiplier;
uniform float fontSizeCur;
uniform vec3 color;
uniform float threshold;
uniform float softness;
const float G_fontSizePixels = 72.0;
const float G_distFieldWidth = 32.0;
const float G_extraDilationInCssPixels = 0.0;
varying vec4 vHazeColor;
void main()
{
    float _sample = texture2D(tex, vUv).r;
    float distToGlyphBoundaryInSdfTexels = G_distFieldWidth * (_sample - 0.5);
    float cssPixelsToSdfTexels = G_fontSizePixels / fontSizeCur;
    float featheringWidthInCssPixels = softness;
    float featheringWidthInSdfTexels = featheringWidthInCssPixels * cssPixelsToSdfTexels;
    float dilationInCssPixels = threshold + G_extraDilationInCssPixels;
    float dilationInSdfTexels = dilationInCssPixels * cssPixelsToSdfTexels;
    float alpha = smoothstep(-0.5 * featheringWidthInSdfTexels, 0.5 * featheringWidthInSdfTexels,
                             distToGlyphBoundaryInSdfTexels + dilationInSdfTexels);
    if (_sample == 0.0)
    {
        alpha = 0.0;
    }
    vec3 c = color;
    c.rgb = mix(c.rgb, vHazeColor.rgb, vHazeColor.a);
    gl_FragColor = vec4(c, alpha * opacity * opacityMultiplier);
}
