precision highp int;
precision highp float;
 #include <OgreUnifiedShader.h>
mat3 mat4ToMat3(mat4 m) { return mat3(m[0].xyz, m[1].xyz, m[2].xyz); }
varying vec2 vUv;
    uniform vec2 pixelSize;
attribute vec4 position;
attribute vec2 uv0;
uniform float bufferWidth;
uniform float bufferHeight;
uniform float offsetX;
uniform float offsetY;
uniform float width;
uniform float height;
uniform float widthUV;
uniform float heightUV;
uniform float scale;
uniform float fontSizeCur;
uniform float fontSizeMax;
uniform float mercatorScale;
uniform float elevationExaggerationFactor;
uniform mat4 modelMatrix;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
varying vec4 vHazeColor;
void main()
{
    vUv = uv0;
    vec2 pos = position.xy * pixelSize * 2.0 - 1.0;
    gl_Position = vec4(pos.x, pos.y, 1.0, 1.0);
    vHazeColor = vec4(0.0);
}
