precision highp int;
precision highp float;
 #include <OgreUnifiedShader.h>
uniform vec4 aViewportSize;
uniform float aPixelRatio;
attribute vec4 position;
attribute vec4 colour;
varying vec4 oColor;
void main()
{
 oColor = colour;
  gl_Position = vec4(position.xy * aViewportSize.zw * aPixelRatio * 2.0 - 1.0, 0.0, 1.0);
}
