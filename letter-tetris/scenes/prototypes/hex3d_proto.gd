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

const LETTERS := ["S", "T", "E", "R", "N", "A", "H", "U", "K", "R", "E", "L"]


func _ready() -> void:
	_build_environment()
	_build_lights()
	_build_base()
	_build_tiles()
	_build_camera()


func _materials() -> Dictionary:
	var crystal := StandardMaterial3D.new()
	crystal.albedo_color = Color(0.32, 0.42, 0.95)
	crystal.metallic = 0.15
	crystal.roughness = 0.12
	crystal.metallic_specular = 0.8
	crystal.clearcoat_enabled = true
	crystal.clearcoat = 1.0
	crystal.clearcoat_roughness = 0.05
	crystal.rim_enabled = true
	crystal.rim = 0.6
	crystal.rim_tint = 0.4
	crystal.emission_enabled = true
	crystal.emission = Color(0.15, 0.25, 0.75)
	crystal.emission_energy_multiplier = 0.45
	crystal.cull_mode = BaseMaterial3D.CULL_DISABLED

	var milky := StandardMaterial3D.new()
	milky.albedo_color = Color(0.9, 0.9, 0.95)
	milky.roughness = 0.75
	milky.rim_enabled = true
	milky.rim = 0.25
	milky.cull_mode = BaseMaterial3D.CULL_DISABLED

	var selected := crystal.duplicate() as StandardMaterial3D
	selected.albedo_color = Color(0.3, 0.85, 1.0)
	selected.emission = Color(0.2, 0.8, 1.0)
	selected.emission_energy_multiplier = 1.6

	return {"crystal": crystal, "milky": milky, "selected": selected}


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


func _build_base() -> void:
	var base := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(14, 0.1, 14)
	base.mesh = box
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.07, 0.07, 0.11)
	m.metallic = 0.7
	m.roughness = 0.45
	base.material_override = m
	base.position = Vector3(0, -thickness * 0.5 - 0.05, 0)
	add_child(base)


func _build_tiles() -> void:
	var mats := _materials()
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
				mats["crystal"], mats["milky"])
			var x := (c - (cols - 1) / 2.0) * 1.5 * hex_radius
			var z := -((r - (rows - 1) / 2.0) * h + (0.0 if c % 2 == 1 else h / 2.0)) + h * 0.25
			tile.position = Vector3(x, 0, z)
			# Beispiele: ein ausgewähltes, eines mitten in der Drehung, eines noch mit der Rückseite oben
			if c == 1 and r == 1:
				tile.set_front_material(mats["selected"])
			elif c == 2 and r == 2:
				tile.set_flip(flip_demo)
				tile.position.y += thickness * 0.6
			elif c == 3 and r == 0:
				tile.set_flip(0.0)
			idx += 1


func _build_camera() -> void:
	var cam := Camera3D.new()
	cam.fov = camera_fov
	var height := 13.0
	var tilt := deg_to_rad(camera_tilt)
	cam.position = Vector3(0, height, height * tan(tilt))
	cam.rotation = Vector3(-PI / 2.0 + tilt, 0, 0)
	add_child(cam)
	cam.make_current()
