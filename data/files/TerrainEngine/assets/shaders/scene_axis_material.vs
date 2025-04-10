precision highp int;
precision highp float;
 #include <OgreUnifiedShader.h>
uniform mat4 aWorldViewProj;
uniform vec4 aCameraPosition;
uniform vec4 aViewDirection;
uniform float aNearClipDistance;
attribute vec4 position;
attribute vec4 normal;
varying vec4 oColor;
void main()
{
 oColor = normal;
 vec4 pos = position;
 pos.xyz *= aNearClipDistance;
 pos.xyz += aCameraPosition.xyz;
 pos.xyz += aViewDirection.xyz * aNearClipDistance * 2.0;
    gl_Position = aWorldViewProj * pos;
    gl_Position += vec4(gl_Position.w * 0.8, gl_Position.w * 0.8, 0, 0);
}
