precision highp int;
precision highp float;
 #include <OgreUnifiedShader.h>
uniform mat4 worldViewProjectionMatrix;
attribute vec4 position;
attribute vec4 colour;
varying vec4 oColor;
void main()
{
    oColor = colour;
    gl_Position = worldViewProjectionMatrix * position;
}
