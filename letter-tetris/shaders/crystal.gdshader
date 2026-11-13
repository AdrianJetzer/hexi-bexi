// Kristall-Material für die Buchstaben-Hexagons.
// Durchscheinend mit leichter Lichtbrechung, leuchtender Kante (Fresnel),
// schillernder Kante (Iridescence) und innerem Leuchtkern.
shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_opaque, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.30, 0.42, 0.95, 1.0);
// Farbe, mit der der Hintergrund durch den Kristall getönt wird
uniform vec4 tint_color : source_color = vec4(0.55, 0.70, 1.0, 1.0);
uniform vec4 rim_color : source_color = vec4(0.65, 0.90, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(0.35, 0.50, 1.0, 1.0);
// 0 = ganz durchsichtig, 1 = undurchsichtig (Kanten werden immer dichter)
uniform float opacity : hint_range(0.0, 1.0) = 0.55;
uniform float refraction : hint_range(0.0, 0.2) = 0.04;
uniform float rim_power : hint_range(0.5, 8.0) = 2.5;
uniform float rim_strength : hint_range(0.0, 4.0) = 1.4;
uniform float core_strength : hint_range(0.0, 4.0) = 0.5;
// Größe des Leuchtkerns relativ zum Radius
uniform float core_size : hint_range(0.1, 1.5) = 0.75;
uniform float iridescence : hint_range(0.0, 2.0) = 0.35;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.04;
uniform float specular_value : hint_range(0.0, 1.0) = 0.9;
uniform float hex_radius = 1.0;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fres = pow(1.0 - ndv, rim_power);

	// Hintergrund durch den Kristall, leicht verschoben (Lichtbrechung) und weich
	vec2 offset = NORMAL.xy * refraction;
	vec3 behind = textureLod(screen_tex, SCREEN_UV + offset, 2.0).rgb;

	// Leuchtkern in der Mitte
	float d = length(local_pos.xz) / max(hex_radius, 0.001);
	float core = 1.0 - smoothstep(0.0, core_size, d);

	// Schillernde Kante (Regenbogen-Verlauf über den Fresnel-Wert)
	vec3 irid = 0.5 + 0.5 * cos(6.2831 * (fres * 1.4 + vec3(0.0, 0.33, 0.67)));

	ALBEDO = mix(behind * tint_color.rgb, base_color.rgb, 0.45);
	EMISSION = rim_color.rgb * fres * rim_strength
		+ core_color.rgb * core * core_strength
		+ irid * fres * iridescence;
	ROUGHNESS = roughness_value;
	SPECULAR = specular_value;
	METALLIC = 0.0;
	ALPHA = clamp(mix(opacity, 1.0, fres), 0.0, 1.0);
}
