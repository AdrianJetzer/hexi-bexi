extends Node3D
## Prototyp: 3D-Hexagons mit Licht und Material, Kamera von oben mit leichter Perspektive.
## Nur zum Ausprobieren der Optik, nicht Teil des Spiels.

@export var hex_radius: float = 1.0
@export var thickness: float = 0.42
@export var corner: float = 0.16
@export var bevel: float = 0.13
## Abstand zwischen den Hexagons (Anteil des Radius).
@export var gap: float = 0.07
@export var camera_fov: float = 32.0
## Leichte Neigung der Kamera (Grad, 0 = genau senkrecht).
@export var camera_tilt: float = 8.0
## Drehung des „gerade erscheinenden“ Hexagons (0 = Rückseite, 1 = Vorderseite).
@export var flip_demo: float = 0.35
## Material-Variante: 0 = Eis-Kristall, 1 = Amethyst, 2 = Rauchglas mit Energiekern
@export var material_variant: int = 2
## Rückseite: 0 = milchig weiß, 1 = mattes Rauchglas, 2 = gefrostetes Rauchglas mit schwachem Kern,
## 3 = dunkles Metall mit Leuchtring und gravierter Buchstabe
@export var back_variant: int = 3

const LETTERS := ["S", "T", "E", "R", "N", "A", "H", "U", "K", "R", "E", "L"]
const CRYSTAL_SHADER := preload("res://shaders/crystal.gdshader")

const VARIANTS := [
	{
		"name": "Eis-Kristall",
		"base_color": Color(0.35, 0.55, 1.0), "tint_color": Color(0.6, 0.8, 1.0),
		"rim_color": Color(0.7, 0.95, 1.0), "core_color": Color(0.3, 0.5, 1.0),
		"opacity": 0.35, "rim_strength": 0.75, "core_strength": 0.35, "core_size": 0.8,
		"iridescence": 0.3, "letter": Color(1.3, 1.35, 1.5), "letter_depth": 0.06,
	},
	{
		"name": "Amethyst",
		"base_color": Color(0.45, 0.18, 0.75), "tint_color": Color(0.7, 0.4, 1.0),
		"rim_color": Color(1.0, 0.6, 1.0), "core_color": Color(0.6, 0.2, 0.9),
		"opacity": 0.6, "rim_strength": 0.7, "core_strength": 0.6, "core_size": 0.75,
		"iridescence": 0.6, "letter": Color(1.4, 1.1, 0.6), "letter_depth": 0.04,
	},
	{
		"name": "Rauchglas mit Energiekern",
		"base_color": Color(0.08, 0.1, 0.18), "tint_color": Color(0.3, 0.35, 0.5),
		"rim_color": Color(0.3, 0.9, 1.0), "core_color": Color(0.1, 0.8, 1.0),
		"opacity": 0.75, "rim_strength": 0.6, "core_strength": 1.4, "core_size": 0.6,
		"iridescence": 0.1, "letter": Color(0.9, 1.4, 1.5), "letter_depth": 0.0,
	},
]


func _ready() -> void:
	_build_environment()
	_build_lights()
	_build_base()
	_build_tiles()
	_build_camera()


func _crystal(v: Dictionary, selected: bool) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = CRYSTAL_SHADER
	for key in ["base_color", "tint_color", "rim_color", "core_color", "opacity",
			"rim_strength", "core_strength", "core_size", "iridescence"]:
		m.set_shader_parameter(key, v[key])
	m.set_shader_parameter("hex_radius", hex_radius)
	if selected:
		m.set_shader_parameter("core_color", Color(0.2, 0.9, 1.0))
		m.set_shader_parameter("rim_color", Color(0.5, 1.0, 1.0))
		m.set_shader_parameter("core_strength", v["core_strength"] * 2.5 + 0.8)
		m.set_shader_parameter("rim_strength", v["rim_strength"] * 1.5)
	return m


## Rückseite: [Material, Buchstabenfarbe] je nach back_variant.
func _back() -> Array:
	match back_variant:
		3:
			# Dunkles, gebürstetes Metall
			var noise := FastNoiseLite.new()
			noise.frequency = 0.02
			var tex := NoiseTexture2D.new()
			tex.width = 256
			tex.height = 256
			tex.seamless = true
			tex.noise = noise
			var metal := StandardMaterial3D.new()
			metal.albedo_color = Color(0.16, 0.17, 0.21)
			metal.metallic = 0.95
			metal.roughness = 0.38
			metal.roughness_texture = tex
			metal.uv1_triplanar = true
			metal.uv1_scale = Vector3(0.6, 0.6, 18.0)
			metal.rim_enabled = true
			metal.rim = 0.3
			return [metal, Color(0.03, 0.035, 0.05, 0.95), Color(0.55, 0.62, 0.72, 0.45)]
		1:
			# Mattes Rauchglas
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.10, 0.12, 0.18)
			m.roughness = 0.55
			m.metallic = 0.1
			m.rim_enabled = true
			m.rim = 0.5
			m.rim_tint = 0.8
			return [m, Color(0.35, 0.75, 0.85, 0.55)]
		2:
			# Rauchglas, gefrostet, mit schwachem Kern
			var s := ShaderMaterial.new()
			s.shader = CRYSTAL_SHADER
			s.set_shader_parameter("base_color", Color(0.12, 0.14, 0.22))
			s.set_shader_parameter("tint_color", Color(0.25, 0.3, 0.4))
			s.set_shader_parameter("rim_color", Color(0.4, 0.8, 0.9))
			s.set_shader_parameter("core_color", Color(0.1, 0.6, 0.8))
			s.set_shader_parameter("opacity", 0.92)
			s.set_shader_parameter("rim_strength", 0.35)
			s.set_shader_parameter("core_strength", 0.35)
			s.set_shader_parameter("core_size", 0.7)
			s.set_shader_parameter("iridescence", 0.0)
			s.set_shader_parameter("roughness_value", 0.5)
			s.set_shader_parameter("hex_radius", hex_radius)
			return [s, Color(0.5, 0.9, 1.0, 0.6)]
		_:
			# Milchig weiß (bisher)
			var w := StandardMaterial3D.new()
			w.albedo_color = Color(0.9, 0.9, 0.95)
			w.roughness = 0.75
			w.rim_enabled = true
			w.rim = 0.25
			return [w, Color(0.45, 0.5, 0.7, 0.55)]


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.02, 0.07)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.35, 0.6)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.85
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _build_lights() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, 35, 0)
	sun.light_energy = 1.3
	sun.light_color = Color(1.0, 0.95, 0.9)
	sun.shadow_enabled = true
	add_child(sun)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-4, 3, 2)
	fill.omni_range = 12
	fill.light_energy = 2.0
	fill.light_color = Color(0.7, 0.4, 1.0)
	add_child(fill)


## Boden mit dunklem, farbigem Nebel-Muster, damit man die Lichtbrechung sieht.
func _build_base() -> void:
	var base := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(14, 0.1, 14)
	base.mesh = box
	var noise := FastNoiseLite.new()
	noise.frequency = 0.004
	noise.fractal_octaves = 5
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.02, 0.02, 0.06))
	ramp.set_color(1, Color(0.25, 0.08, 0.35))
	ramp.add_point(0.55, Color(0.05, 0.12, 0.3))
	var tex := NoiseTexture2D.new()
	tex.width = 1024
	tex.height = 1024
	tex.noise = noise
	tex.color_ramp = ramp
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.metallic = 0.5
	m.roughness = 0.5
	m.emission_enabled = true
	m.emission_texture = tex
	m.emission_energy_multiplier = 0.6
	base.material_override = m
	base.position = Vector3(0, -thickness * 0.5 - 0.05, 0)
	add_child(base)


func _build_tiles() -> void:
	var v: Dictionary = VARIANTS[clampi(material_variant, 0, VARIANTS.size() - 1)]
	var crystal := _crystal(v, false)
	var selected := _crystal(v, true)
	var back := _back()
	var mesh := HexMesh.build(hex_radius * (1.0 - gap), thickness, corner, bevel)
	var h := sqrt(3.0) * hex_radius
	var idx := 0
	var cols := 4
	var rows := 3
	for c in cols:
		for r in rows:
			var tile := HexTile3D.new()
			add_child(tile)
			tile.setup(LETTERS[idx % LETTERS.size()], mesh, hex_radius * (1.0 - gap), thickness,
				crystal, back[0], v["letter"], v["letter_depth"], back[1],
				back[2] if back.size() > 2 else Color(0, 0, 0, 0))
			if back_variant == 3:
				tile.add_back_decoration(_back_ring())
			var x := (c - (cols - 1) / 2.0) * 1.5 * hex_radius
			var z := -((r - (rows - 1) / 2.0) * h + (0.0 if c % 2 == 1 else h / 2.0)) + h * 0.25
			tile.position = Vector3(x, 0, z)
			# Beispiele: ein ausgewähltes, eines mitten in der Drehung, eines noch mit der Rückseite oben
			if c == 1 and r == 1:
				tile.set_front_material(selected)
			elif c == 2 and r == 2:
				tile.set_flip(flip_demo)
				tile.position.y += thickness * 0.6
			elif c == 3 and r == 0:
				tile.set_flip(0.0)
			idx += 1


## Dünner, leuchtender Sechseck-Ring knapp unter der Rückseite (nach der Drehung oben).
func _back_ring() -> MeshInstance3D:
	var r := hex_radius * (1.0 - gap) - bevel
	var ring := MeshInstance3D.new()
	ring.mesh = HexMesh.ring(r * 0.86, r * 0.86 - 0.035)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.35, 1.3, 1.5)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring.material_override = m
	ring.position = Vector3(0, -thickness * 0.5 - 0.003, 0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return ring


func _build_camera() -> void:
	var cam := Camera3D.new()
	cam.fov = camera_fov
	var height := 13.0
	var tilt := deg_to_rad(camera_tilt)
	cam.position = Vector3(0, height, height * tan(tilt))
	cam.rotation = Vector3(-PI / 2.0 + tilt, 0, 0)
	add_child(cam)
	cam.make_current()
