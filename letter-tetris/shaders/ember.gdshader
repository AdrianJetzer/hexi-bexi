shader_type canvas_item;
// Glut in einem Auftrags-Block (spec/screens.md, „Wisch-Vorschau“): flackernde Lava,
// unten dunkelrot, darüber orange, zur Mitte fast gelb. intensity 0 = aus, 1 = Glut,
// über 1 = heller Puls.

uniform float intensity = 0.0;
// Eckenradius als Anteil der Breite (passt zur abgerundeten Block-Form).
uniform float radius = 0.15;
// Pro Block anders, damit nicht alle gleich flackern.
uniform float seed = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

vec3 lava(float h) {
	vec3 c0 = vec3(0.30, 0.02, 0.0);
	vec3 c1 = vec3(0.85, 0.16, 0.02);
	vec3 c2 = vec3(1.0, 0.52, 0.06);
	vec3 c3 = vec3(1.0, 0.93, 0.55);
	if (h < 0.4) return mix(c0, c1, h / 0.4);
	if (h < 0.7) return mix(c1, c2, (h - 0.4) / 0.3);
	return mix(c2, c3, clamp((h - 0.7) / 0.3, 0.0, 1.0));
}

void fragment() {
	vec2 uv = UV;
	vec2 q = abs(uv - 0.5) - (0.5 - radius);
	float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
	float mask = 1.0 - smoothstep(-0.03, 0.0, d);

	vec2 p = uv * 2.6 + vec2(seed, seed * 1.7);
	float n1 = fbm(p + vec2(0.0, TIME * 0.7));
	float n2 = fbm(p * 1.8 - vec2(TIME * 0.3, TIME * 1.1));
	float flow = n1 * 0.6 + n2 * 0.4;
	// Heller zur Mitte, unten dunkler.
	float center = 1.0 - clamp(length((uv - vec2(0.5, 0.42)) * vec2(1.0, 1.15)) * 1.7, 0.0, 1.0);
	float bottom = smoothstep(0.55, 1.0, uv.y);
	float heat = flow * 0.85 + center * 0.6 - bottom * 0.25;
	heat *= intensity;
	float a = mask * clamp(intensity, 0.0, 1.0) * mix(0.7, 1.0, clamp(heat, 0.0, 1.0));
	COLOR = vec4(lava(clamp(heat, 0.0, 1.0)), a);
}
