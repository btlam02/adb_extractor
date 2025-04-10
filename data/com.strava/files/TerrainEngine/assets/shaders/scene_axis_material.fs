precision highp int;
precision highp float;
 #include <OgreUnifiedShader.h>
varying vec4 oColor;
void main ()
{
    gl_FragColor = oColor;
}
