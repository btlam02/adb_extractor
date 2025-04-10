precision highp int;
precision highp float;
 #include <OgreUnifiedShader.h>
    varying float vFragCoordW;
uniform float nearPlane;
uniform float farPlane;
vec4 packDepth(const in float depth)
{
    const vec4 bit_shift = vec4(256.0 * 256.0 * 256.0, 256.0 * 256.0, 256.0, 1.0);
    const vec4 bit_mask = vec4(0.0, 1.0 / 256.0, 1.0 / 256.0, 1.0 / 256.0);
    vec4 res = mod(depth * bit_shift * vec4(255), vec4(256)) / vec4(255);
    res -= res.xxyz * bit_mask;
    return res;
}
float inverseDepth(float d, float near, float far)
{
    return -((far * near) / d - far) / (far - near);
}
void main()
{
    float distance = gl_FragCoord.x < -1.0 ? vFragCoordW : gl_FragCoord.w;
    float depth = inverseDepth(1.0 / distance, nearPlane, farPlane);
    {
        gl_FragColor = packDepth(depth);
    }
}
