precision highp int;
precision highp float;
 #include <OgreUnifiedShader.h>
uniform float aTime;
varying vec4 oColor;
void main ()
{
    gl_FragColor = oColor;
}
