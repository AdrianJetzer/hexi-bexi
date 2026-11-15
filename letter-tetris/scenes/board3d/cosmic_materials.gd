class_name CosmicMaterials
extends RefCounted
## Materialien des Themes „Kosmisch“ (Version 1), siehe spec/look-and-sound.md.
## Später als austauschbare Theme-Daten; vorerst an einer Stelle gesammelt.

const CRYSTAL_SHADER := preload("res://shaders/crystal.gdshader")

## Farbe des Buchstabens auf der Vorderseite (Werte > 1 leuchten durch Glow).
const LETTER := Color(0.9, 1.4, 1.5)
## Seitenverkehrter Buchstabe auf der Rückseite.
const BACK_LETTER := Color(0.5, 0.9, 1.0, 0.6)


## Vorderseite: Rauchglas mit Energiekern.
static func front(hex_radius: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = CRYSTAL_SHADER
	m.set_shader_parameter("base_color", Color(0.08, 0.1, 0.18))
	m.set_shader_parameter("tint_color", Color(0.3, 0.35, 0.5))
	m.set_shader_parameter("rim_color", Color(0.3, 0.9, 1.0))
	m.set_shader_parameter("core_color", Color(0.1, 0.8, 1.0))
	m.set_shader_parameter("opacity", 0.75)
	m.set_shader_parameter("rim_strength", 0.6)
	m.set_shader_parameter("core_strength", 1.4)
	m.set_shader_parameter("core_size", 0.6)
	m.set_shader_parameter("iridescence", 0.1)
	m.set_shader_parameter("hex_radius", hex_radius)
	return m


## Vorderseite, ausgewählt: Kern und Kante heller.
static func selected(hex_radius: float) -> ShaderMaterial:
	var m := front(hex_radius)
	m.set_shader_parameter("core_color", Color(0.2, 0.9, 1.0))
	m.set_shader_parameter("rim_color", Color(0.5, 1.0, 1.0))
	m.set_shader_parameter("core_strength", 4.3)
	m.set_shader_parameter("rim_strength", 0.9)
	return m


## Rückseite: gefrostetes Rauchglas mit schwachem Kern.
static func back(hex_radius: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = CRYSTAL_SHADER
	m.set_shader_parameter("base_color", Color(0.12, 0.14, 0.22))
	m.set_shader_parameter("tint_color", Color(0.25, 0.3, 0.4))
	m.set_shader_parameter("rim_color", Color(0.4, 0.8, 0.9))
	m.set_shader_parameter("core_color", Color(0.1, 0.6, 0.8))
	m.set_shader_parameter("opacity", 0.92)
	m.set_shader_parameter("rim_strength", 0.35)
	m.set_shader_parameter("core_strength", 0.35)
	m.set_shader_parameter("core_size", 0.7)
	m.set_shader_parameter("iridescence", 0.0)
	m.set_shader_parameter("roughness_value", 0.5)
	m.set_shader_parameter("hex_radius", hex_radius)
	return m


## Rahmen: dunkles Metall.
static func frame_metal() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.1, 0.1, 0.14)
	m.metallic = 0.9
	m.roughness = 0.4
	return m


## Leuchtende Zickzack-Innenkante des Rahmens.
static func frame_glow() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.35, 1.3, 1.6)
	return m


## Funkel-Teilchen: weicher Lichtpunkt mit feinem Kreuz, immer zur Kamera gedreht, additiv.
static func sparkle() -> StandardMaterial3D:
	var size := 64
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := (size - 1) / 2.0
	for y in size:
		for x in size:
			var dx := (x - c) / c
			var dy := (y - c) / c
			var r := sqrt(dx * dx + dy * dy)
			var dot := pow(clampf(1.0 - r, 0.0, 1.0), 3.0)
			var cross := pow(clampf(1.0 - absf(dx) * 9.0, 0.0, 1.0), 2.0) * clampf(1.0 - absf(dy), 0.0, 1.0) \
					+ pow(clampf(1.0 - absf(dy) * 9.0, 0.0, 1.0), 2.0) * clampf(1.0 - absf(dx), 0.0, 1.0)
			var a := clampf(dot + cross * 0.7, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return m


## Boden im Inneren des Spielfelds: dunkler Nebel.
static func well_floor() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _nebula(Color(0.02, 0.02, 0.05), Color(0.05, 0.1, 0.25), Color(0.18, 0.06, 0.28))
	m.metallic = 0.4
	m.roughness = 0.6
	m.emission_enabled = true
	m.emission_texture = m.albedo_texture
	m.emission_energy_multiplier = 0.5
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.08, 0.08, 0.08)
	return m


## Hintergrund außerhalb des Spielfelds (Platzhalter für den animierten Nebel).
static func background() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = _nebula(Color(0.02, 0.01, 0.06), Color(0.12, 0.08, 0.35), Color(0.35, 0.1, 0.4))
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.03, 0.03, 0.03)
	return m


const NEBULA_SHADER := preload("res://scenes/board3d/nebula_background.gdshader")

## Animierter Hintergrund (Nebel, Sterne, Lichtschein, Vignette). Stile:
## 1 = Tiefsee-Nebel, 2 = Galaxie, 3 = Dunkle Eleganz.
static func nebula_background(style: int) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = NEBULA_SHADER
	match style:
		2:
			m.set_shader_parameter("color_deep", Color(0.02, 0.01, 0.06))
			m.set_shader_parameter("color_mid", Color(0.14, 0.06, 0.32))
			m.set_shader_parameter("color_high", Color(0.55, 0.15, 0.55))
			m.set_shader_parameter("color_accent", Color(0.1, 0.45, 0.7))
			m.set_shader_parameter("cloud_strength", 1.0)
			m.set_shader_parameter("star_density", 1.0)
			m.set_shader_parameter("star_brightness", 1.6)
			m.set_shader_parameter("glow_strength", 0.3)
			m.set_shader_parameter("glow_color", Color(0.45, 0.3, 0.9))
			m.set_shader_parameter("vignette", 0.6)
		3:
			m.set_shader_parameter("color_deep", Color(0.005, 0.008, 0.02))
			m.set_shader_parameter("color_mid", Color(0.03, 0.05, 0.12))
			m.set_shader_parameter("color_high", Color(0.08, 0.1, 0.22))
			m.set_shader_parameter("color_accent", Color(0.02, 0.15, 0.2))
			m.set_shader_parameter("cloud_strength", 0.6)
			m.set_shader_parameter("star_density", 0.35)
			m.set_shader_parameter("star_brightness", 0.9)
			m.set_shader_parameter("glow_strength", 0.35)
			m.set_shader_parameter("glow_color", Color(0.15, 0.4, 0.6))
			m.set_shader_parameter("vignette", 0.9)
		_:
			pass  # Standardwerte im Shader: Tiefsee-Nebel
	return m


static func environment() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.01, 0.05)
	# Unsichtbarer „Himmel“ nur für Spiegelungen
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.7, 0.72, 0.85)
	sky_mat.sky_horizon_color = Color(0.55, 0.4, 0.8)
	sky_mat.ground_horizon_color = Color(0.3, 0.6, 0.9)
	sky_mat.ground_bottom_color = Color(0.05, 0.05, 0.15)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.35, 0.6)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.85
	return env


static func _nebula(c0: Color, c1: Color, c2: Color) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.frequency = 0.004
	noise.fractal_octaves = 5
	var ramp := Gradient.new()
	ramp.set_color(0, c0)
	ramp.set_color(1, c2)
	ramp.add_point(0.55, c1)
	var tex := NoiseTexture2D.new()
	tex.width = 1024
	tex.height = 1024
	tex.seamless = true
	tex.noise = noise
	tex.color_ramp = ramp
	return tex
