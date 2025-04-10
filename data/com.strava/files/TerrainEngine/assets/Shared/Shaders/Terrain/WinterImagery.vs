precision highp int;
precision highp float;
 #include <OgreUnifiedShader.h>
    attribute vec4 position;
uniform float mercatorScale;
uniform float elevationExaggerationFactor;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform vec4 _WinterImageryTexTransform;
varying vec2 vUv;
vec4 upScalePoint(vec4 vec)
{
    vec4 scaledVec = vec;
    scaledVec.z *= mercatorScale * elevationExaggerationFactor;
    return scaledVec;
}
vec2 CalculateUV(vec4 ipos, vec4 texTransform)
{
    return (ipos.xy - texTransform.xy) / texTransform.zw;
}
void main()
{
    vec3 outPos = position.xyz;
    vUv = CalculateUV(vec4(outPos, 1.0), _WinterImageryTexTransform);
    vec4 scaledPosition = upScalePoint(position);
    gl_Position = projectionMatrix * modelViewMatrix * scaledPosition;
}
