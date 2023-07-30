#define FOV 1.0
#define MAX_STEPS 256
#define MAX_DIST 500.0
#define EPSILON 0.00001

#define PI 3.14159265
#define TAU (2.0*PI)
#define PHI (sqrt(5.0) * 0.5 + 0.5)

/// HELPER FUNCTIONS ///
// Sign function that doesn't return 0
float sgn(float x) {
	return (x<0.0)?-1.0:1.0;
}

vec2 sgn(vec2 v) {
	return vec2((v.x<0.0)?-1.0:1.0, (v.y<0.0)?-1.0:1.0);
}

// Maximum/minumum elements of a vector
float vmax(vec2 v) {
	return max(v.x, v.y);
}

float vmax(vec3 v) {
	return max(max(v.x, v.y), v.z);
}

float vmax(vec4 v) {
	return max(max(v.x, v.y), max(v.z, v.w));
}

float vmin(vec2 v) {
	return min(v.x, v.y);
}

float vmin(vec3 v) {
	return min(min(v.x, v.y), v.z);
}

float vmin(vec4 v) {
	return min(min(v.x, v.y), min(v.z, v.w));
}

// Repeat space along one axis. Use like this to repeat along the x axis:
// <float cell = pMod1(p.x,5);> - using the return value is optional.
float pMod1(inout float p, float size) {
	float halfsize = size*0.5;
	float c = floor((p + halfsize)/size);
	p = mod(p + halfsize, size) - halfsize;
	return c;
}

void pR(inout vec2 p, float a) {
    p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

// Shortcut for 45-degrees rotation
void pR45(inout vec2 p) {
	p = (p + vec2(p.y, -p.x))*sqrt(0.5);
}

float fSphere(vec3 p, float radius) {
    return length(p) - radius;
}

float fPlane(vec3 p, vec3 n, float distanceFromOrigin) {
    return dot(p, n) + distanceFromOrigin;
}

float fBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
	return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}

float fBox2(vec2 p, vec2 b) {
	vec2 d = abs(p) - b;
	return length(max(d, vec2(0))) + vmax(min(d, vec2(0)));
}

float fCylinder(vec3 p, float r, float height) {
	float d = length(p.xz) - r;
	d = max(d, abs(p.y) - height);
	return d;
}

vec2 fOpUnionId(vec2 res1, vec2 res2) {
    return (res1.x < res2.x) ? res1 : res2;
}

vec2 fOpDiffId(vec2 res1, vec2 res2) {
    return (res1.x > -res2.x) ? res1 : vec2(-res2.x, res2.y);
}

float fOpDiffColumns(float a, float b, float r, float n) {
    a = -a;
	float m = min(a, b);
	//avoid the expensive computation where not needed (produces discontinuity though)
	if ((a < r) && (b < r)) {
		vec2 p = vec2(a, b);
		float columnradius = r*sqrt(2.0)/n/2.0;
		columnradius = r*sqrt(2.0)/((n-1.0)*2.0+sqrt(2.0));

		pR45(p);
		p.y += columnradius;
		p.x -= sqrt(2.0)/2.0*r;
		p.x += -columnradius*sqrt(2.0)/2.0;

		if (mod(n,2.0) == 1.0) {
			p.y += columnradius;
		}
		pMod1(p.y,columnradius*2.0);

		float result = -length(p) + columnradius;
		result = max(result, p.x);
		result = min(result, a);
		return -min(result, b);
	} else {
		return -m;
	}
}

float fOpUnionChamfer(float a, float b, float r) {
	return min(min(a, b), (a - r + b)*sqrt(0.5));
}

float fOpUnionStairs(float a, float b, float r, float n) {
	float s = r/n;
	float u = b-r;
	return min(min(a,b), 0.5 * (u + a + abs ((mod (u - a + s, 2.0 * s)) - s)));
}

vec2 fOpDiffColumnsId(vec2 res1, vec2 res2, float r, float n) {
    float dist = fOpDiffColumns(res1.x, res2.x, r, n);
    return (res1.x > -res2.x) ? vec2(dist, res1.y) : vec2(dist, res2.y);
}

vec2 fOpUnionChamferId(vec2 res1, vec2 res2, float r) {
    float dist = fOpUnionChamfer(res1.x, res2.x, r);
    return (res1.x < res2.x) ? vec2(dist, res1.y) : vec2(dist, res2.y);
}

vec2 fOpUnionStairsId(vec2 res1, vec2 res2, float b, float n) {
    float dist = fOpUnionStairs(res1.x, res2.x, b, n);
    return (res1.x < res2.x) ? vec2(dist, res1.y) : vec2(dist, res2.y);
}

// Mirror at an axis-aligned plane which is at a specified distance <dist> from the origin.
float pMirror (inout float p, float dist) {
	float s = sgn(p);
	p = abs(p)-dist;
	return s;
}

// Mirror in both dimensions and at the diagonal, yielding one eighth of the space.
// translate by dist before mirroring.
vec2 pMirrorOctant (inout vec2 p, vec2 dist) {
	vec2 s = sgn(p);
	pMirror(p.x, dist.x);
	pMirror(p.y, dist.y);
	if (p.y > p.x)
		p.xy = p.yx;
	return s;
}

float fDisplace(vec3 p) {
    pR(p.yz, sin(2.0 * iTime));
    return (sin(p.x + 4.0 * iTime) * sin(p.y + sin(2.0 * iTime)) * sin(p.z + 6.0 * iTime));
}

/// MAP ///
vec2 map(vec3 p) {
    // plane
    float planeDist = fPlane(p, vec3(0, 1, 0), 14.0);
    float planeId = 2.0;
    vec2 plane = vec2(planeDist, planeId);

    // sphere
    float sphereDist = fSphere(p, 9.0 + fDisplace(p) + 0.3*fDisplace(2.0*p.yxz) + 0.15*fDisplace(4.0*p.zyx));
    float sphereId = 1.0;
    vec2 sphere = vec2(sphereDist, sphereId);
    // repeat space
    pMirrorOctant(p.xz, vec2(50.0));
    p.x = -abs(p.x) + 20.0;
    pMod1(p.z, 15.0);
    // box
    float boxDist = fBox(p, vec3(3.0, 9.0, 4.0));
    float boxId = 3.0;
    vec2 box = vec2(boxDist, boxId);

    // cylinder
    vec3 pc = p;
    pc.y -= 9.0;
    float cylinderDist = fCylinder(pc.yxz, 4.0, 3.0);
    float cylinderId = 3.0;
    vec2 cylinder = vec2(cylinderDist, cylinderId);

    // roof
    vec3 pr = p;
    pr.y -= 15.5;
    pR(pr.xy, 0.6);
    pr.x -= 18.0;
    float roofDist = fBox2(pr.xy, vec2(20, 0.3));
    float roofId = 4.0;
    vec2 roof = vec2(roofDist, roofId);

    // wall
    float wallDist = fBox2(p.xy, vec2(1.0, 15.0));
    float wallId = 3.0;
    vec2 wall = vec2(wallDist, wallId);

    vec2 res;
    res = fOpUnionId(cylinder, box);
    res = fOpDiffColumnsId(wall, res, 0.6, 6.0);
    res = fOpUnionChamferId(res, roof, 0.9);
    res = fOpUnionStairsId(res, plane, 4.0, 5.0);
    res = fOpUnionId(res, sphere);
    return res;
}

/// RENDERING ///
vec2 rayMarch(vec3 ro, vec3 rd) {
    vec2 hit, object;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 pos = ro + object.x * rd;
        hit = map(pos);
        object.x += hit.x;
        object.y = hit.y;
        if (abs(hit.x) < EPSILON || object.x > MAX_DIST) break;
    }
    return object;
}

vec3 getNormal(vec3 p) {
    vec2 e = vec2(EPSILON, 0.0);
    vec3 n = vec3(map(p).x) - vec3(
        map(p - e.xyy).x,
        map(p - e.yxy).x,
        map(p - e.yyx).x);

    return normalize(n);
}

vec3 getMaterial(vec3 p, float id) {
    vec3 m;
    switch (int(id)) {
        case 1: 
        m = vec3(1.0, 0.01, 0.01); break;
        case 2:
        m = vec3(0.2 + 0.4 * mod(floor(p.x) + floor(p.z), 2.0)); break;
        case 3:
        m = vec3(0.7, 0.8, 0.9); break;
        case 4:
        vec2 i = step(fract(0.5 * p.xz), vec2(1.0 / 10.0));
        m = ((1.0 - i.x) * (1.0 - i.y)) * vec3(0.37, 0.12, 0.0); break;
    }

    return m;
}

vec3 getLight(vec3 p, vec3 rd, vec3 col) {
    vec3 lightPos = vec3(20.0, 40.0, -30.0);
    vec3 L = normalize(lightPos - p);
    vec3 N = getNormal(p);
    vec3 V = -rd;
    vec3 R = reflect(-L, N);

    // specular
    vec3 specCol = vec3(0.5);
    vec3 specular = specCol * pow(clamp(dot(R, V), 0.0, 1.0), 16.0); 
    // diffuse light
    vec3 diffuse = col * saturate(dot(L,N));
    // ambient
    vec3 ambient = col * 0.05;
    // fresnel
    vec3 fresnel = 0.25 * col * pow(1.0 + dot(rd, N), 3.0);

    // shadows
    float d = rayMarch(p + N * 0.02, normalize(lightPos)).x;
    if (d < length(lightPos - p)) return ambient + fresnel;

    return diffuse + ambient + specular + fresnel;
}

mat3 getCam(vec3 ro, vec3 lookAt) { 
    vec3 camF = normalize(vec3(lookAt - ro));
    vec3 camR = normalize(cross(vec3(0, 1, 0), camF));
    vec3 camU = cross(camF, camR);
    return mat3(camR, camU, camF);
}

void mouseControl(inout vec3 ro) {
    vec2 m = iMouse.xy / iResolution.xy;
    pR(ro.yz, m.y * PI * 0.4 - 0.4);
    pR(ro.xz, m.x * TAU);
}

void render(inout vec3 col, in vec2 uv) {
    vec3 rayOrigin = vec3(45.0, 25.0, -25.0);
    mouseControl(rayOrigin);
    
    vec3 lookAt = vec3(0.0, 1.0, 0.0);
    vec3 rayDir = getCam(rayOrigin, lookAt) * normalize(vec3(uv, FOV));

    vec2 object = rayMarch(rayOrigin, rayDir);

    vec3 background = vec3(0.4, 0.7, 0.9);
    if (object.x < MAX_DIST) {
        vec3 p = rayOrigin + object.x * rayDir;
        vec3 mat = getMaterial(p, object.y);
        col += getLight(p, rayDir, mat);

        // fog
        col = mix(col, background, 1.0 - exp(-0.00003 * object.x * object.x));
    } else {
        col += background - max(0.95 * rayDir.y, 0.0);
    }
}

/// MAIN FUNCTION ///

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;

    vec3 col;
    render(col, uv);

    // gamma correction
    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}