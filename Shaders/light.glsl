float sdSphere( vec3 p, float s )
{
  return length(p) - s;
}

vec2 map(in vec3 pos) {
    return vec2(sdSphere(pos, 0.2));
}

vec3 calcNormal(in vec3 p)
{
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*map( p + e.xyy ).x + 
					  e.yyx*map( p + e.yyx ).x + 
					  e.yxy*map( p + e.yxy ).x + 
					  e.xxx*map( p + e.xxx ).x );
}

float inverseLerp(float v, float minValue, float maxValue) {
    return (v - minValue) / (maxValue - minValue);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
    float t = inverseLerp(v, inMin, inMax);
    return mix(outMin, outMax, t);
}

vec3 linearToRGB(vec3 value) {
    vec3 lt = vec3(lessThanEqual(value.rgb, vec3(0.0031308)));

    vec3 v1 = value * 12.92;
    vec3 v2 = pow(value.rgb, vec3(0.41666) * 1.055 - vec3(0.055));

    return mix(v2, v1, lt);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;

    float d = sdSphere(vec3(uv.xy, 0.0), 0.2);
    d = smoothstep(0.4, 0.399, d);

    // Ambiant light
    vec3 ambiantColor = d * vec3(0.2);

    // Hemi light
    vec3 skyColor = vec3(0.0, 0.3, 0.6);
    vec3 groundColor = vec3(0.6, 0.3, 0.1);

    vec3 modelNormal = normalize(calcNormal(vec3(uv.xy, 0.2)));
    float hemiMix = remap(modelNormal.y, -1.0, 1.0, 0.0, 1.0);
    vec3 hemi = d * mix(groundColor, skyColor, hemiMix);

    // Diffuse light
    vec3 lightDir = normalize(vec3(1.5, 1.0, 2.0));
    vec3 lightColor = vec3(1.0, 0.9, 0.9);
    float dp = max(0.0, dot(lightDir, modelNormal));

    // Phong specular
    vec3 r = normalize(reflect(-lightDir, modelNormal));
    float phongValue = max(0.0, dot(vec3(0.0), r));
    phongValue = pow(phongValue, 1.0);

    vec3 specular = d * vec3(phongValue);

    vec3 modelColor = d * dp * lightColor;

    vec3 col = 0.6 * modelColor + 0.1 * hemi + 0.02 * ambiantColor + specular;

    col = linearToRGB(col);

    fragColor = vec4(col, 1.0);
}