shader_type spatial;
render_mode unshaded, cull_disabled;
// Hintergrund: langsam ziehender Nebel in mehreren Schichten, Sterne (einige funkeln),
// Lichtschein hinter dem Spielfeld und Vignette zum Rand hin.

uniform vec4 color_deep : source_color = vec4(0.01, 0.01, 0.04, 1.0);
uniform vec4 color_mid : source_color = vec4(0.07, 0.06, 0.24, 1.0);
uniform vec4 color_high : source_color = vec4(0.30, 0.10, 0.42, 1.0);
uniform vec4 color_accent : source_color = vec4(0.05, 0.35, 0.45, 1.0);
uniform float cloud_strength = 1.0;
uniform float cloud_scale = 0.16;
uniform float drift_speed = 0.01;
uniform float star_density = 0.6;
uniform float star_brightness = 1.2;
uniform float glow_strength = 0.25;
uniform vec4 glow_color : source_color = vec4(0.25, 0.45, 0.9, 1.0);
uniform float vignette = 0.75;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
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
	for (int i = 0; i < 6; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

float stars(vec2 p, float density, float t) {
	vec2 cell = floor(p);
	vec2 f = fract(p) - 0.5;
	float h = hash(cell);
	if (h > density * 0.12) {
		return 0.0;
	}
	vec2 offset = vec2(hash(cell + 3.1), hash(cell + 7.7)) - 0.5;
	float d = length(f - offset * 0.7);
	float size = 0.03 + 0.05 * hash(cell + 1.3);
	float twinkle = 0.6 + 0.4 * sin(t * (1.0 + 3.0 * hash(cell + 9.9)) + h * 50.0);
	return smoothstep(size, 0.0, d) * twinkle;
}

void fragment() {
	vec2 p = world_pos.xz * cloud_scale;
	float t = TIME * drift_speed;
	// Zwei Nebelschichten, verschieden schnell (Tiefe)
	float n1 = fbm(p + vec2(t, t * 0.6));
	float n2 = fbm(p * 1.8 - vec2(t * 1.7, t * 0.4) + n1 * 1.5);
	float n = mix(n1, n2, 0.5);
	vec3 col = mix(color_deep.rgb, color_mid.rgb, smoothstep(0.25, 0.65, n));
	col = mix(col, color_high.rgb, smoothstep(0.55, 0.85, n2) * cloud_strength);
	col += color_accent.rgb * smoothstep(0.6, 0.9, n1) * 0.5 * cloud_strength;
	col = mix(color_deep.rgb, col, cloud_strength);
	// Sterne in zwei Größen
	float s = stars(world_pos.xz * 1.6, star_density, TIME) + 0.6 * stars(world_pos.xz * 3.1 + 17.0, star_density, TIME * 1.3);
	col += vec3(0.85, 0.9, 1.0) * s * star_brightness;
	// Lichtschein hinter dem Feld und Vignette (Bildschirmmitte)
	vec2 c = SCREEN_UV - vec2(0.5, 0.48);
	c.x *= 0.8;
	float r = length(c);
	col += glow_color.rgb * glow_strength * smoothstep(0.55, 0.0, r);
	col *= mix(1.0, smoothstep(0.95, 0.25, r), vignette);
	ALBEDO = col;
}
