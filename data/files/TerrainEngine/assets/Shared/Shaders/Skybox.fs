precision highp int;
precision highp float;
 #include <OgreUnifiedShader.h>
    uniform sampler2D textureLow;
uniform sampler2D textureHigh;
varying vec2 vUvLow;
varying vec2 vUvHigh;
varying float vSkyColorFactor;
void main()
{
    gl_FragColor =
        mix(texture2D(textureHigh, vUvHigh), texture2D(textureLow, vUvLow), vSkyColorFactor);
}
