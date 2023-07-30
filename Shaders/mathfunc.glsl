#iChannel0 "file://../cat.jpg"

float inverseLerp(float v, float minValue, float maxValue) {
    return (v - minValue) / (maxValue - minValue);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
    float t = inverseLerp(v, inMin, inMax);
    return mix(outMin, outMax, t);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv0 = fragCoord / iResolution.xy;
    vec2 uv = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;
    uv.y += sin(0.5 * iTime);

    float t = sin(uv.y * 100.0);
    vec4 col = texture2D(iChannel0, uv0);

    float colRed = texture2D(iChannel0, uv0 - 0.005 * sin(iTime)).r;
    float colGreen = texture2D(iChannel0, uv0).g;
    float colBlue = texture2D(iChannel0, uv0).b;

    col = vec4(colRed, colGreen, colBlue, 1.0);
    col += 0.02 * t;

    fragColor = col;
}