class_name ChapterBoard3D
extends Node3D
## Kapitel-Brett des Story-Modus (spec/story-mode.md, „Kapitel-Brett“): große 3D-Kristall-
## Hexagons wie die Spielsteine, StoryChapter.BOARD_COLS × BOARD_ROWS, Reihe 0 unten.
## Aufgedeckt: Name und Sterne. Verdeckt: Rückseite oben (obere, leere Reihen mit „bald“).
## Lebt in einer eigenen SubViewport-Welt (eigene Kamera, Licht, Hintergrund).

const HEX_RADIUS := 1.0
const GAP := 0.06
const THICKNESS := 0.42
const CORNER := 0.16
const BEVEL := 0.13
## Enger Blickwinkel aus großer Entfernung: fast ohne Perspektive, damit Steine am Rand nicht
## schräg (mit sichtbaren Seitenwänden) wirken.
const CAMERA_FOV := 8.0
const FRAME_MARGIN := 0.2
const HIT_TOLERANCE := 0.9
## Schrift auf den Steinen.
const NAME_COLOR := Color(0.9, 1.4, 1.5)
const NAME_DIM := Color(0.6, 0.75, 0.85, 0.7)
const STAR_GOLD := Color(1.7, 1.25, 0.4)
const STAR_EMPTY := Color(0.55, 0.7, 0.85, 0.65)
const BACK_TEXT := Color(0.5, 0.9, 1.0, 0.45)
## Schloss auf gesperrten Kapiteln (leuchtendes Cyan, > 1 = Glow).
const LOCK_COLOR := Color(0.45, 1.1, 1.35)
const LOCK_HOLE := Color(0.02, 0.05, 0.1)
const FONT_SIZE := 96
## Dunkler Rand um die Schrift (lesbar auch über dem leuchtenden Kern).
const TEXT_OUTLINE := Color(0.0, 0.02, 0.06, 0.85)
## Aufdeck-Animation: Pause vor der ersten Drehung, Abstand zwischen den Steinen.
const TURN_START := 0.35
const TURN_STAGGER := 0.07

var layout: BoardLayout
var camera: Camera3D
## Vector2i(Spalte, Reihe) -> HexTile3D
var tiles: Dictionary = {}
var _mesh: ArrayMesh
var _mat_open: Material
var _mat_back: Material
var _mat_medal: Array[Material] = []


func _ready() -> void:
	var tile_r := HEX_RADIUS * (1.0 - GAP)
	_mesh = HexMesh.build(tile_r, THICKNESS, CORNER, BEVEL)
	_mat_open = CosmicMaterials.chapter_open(HEX_RADIUS)
	_mat_back = CosmicMaterials.chapter_back(HEX_RADIUS)
	for st in [1, 2, 3]:
		_mat_medal.append(CosmicMaterials.chapter_medal(HEX_RADIUS, st))
	var we := WorldEnvironment.new()
	we.environment = CosmicMaterials.environment()
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, 35, 0)
	sun.light_energy = 1.3
	sun.light_color = Color(1.0, 0.95, 0.9)
	sun.shadow_enabled = true
	add_child(sun)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-5, 4, 3)
	fill.omni_range = 20
	fill.light_energy = 2.0
	fill.light_color = Color(0.7, 0.4, 1.0)
	add_child(fill)
	var bg := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(400, 400)
	bg.mesh = plane
	bg.material_override = CosmicMaterials.nebula_background(3)
	bg.position.y = -3.0
	bg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(bg)
	camera = Camera3D.new()
	camera.fov = CAMERA_FOV
	camera.rotation = Vector3(-PI / 2.0, 0, 0)
	add_child(camera)
	camera.make_current()
	var probe := BoardLayout.new(StoryChapter.BOARD_COLS, StoryChapter.BOARD_ROWS, HEX_RADIUS)
	layout = BoardLayout.new(StoryChapter.BOARD_COLS, StoryChapter.BOARD_ROWS, HEX_RADIUS,
			-probe.grid_size() / 2.0)


## Steine neu aufbauen. stars: Callable(id) -> int (beste Sterne, 0 = nicht geschafft).
## Beim Betreten liegen alle Steine verdeckt; dann drehen sich die aufgedeckten nacheinander
## um (von unten nach oben, ohne Vibration), geschaffte zu Bronze / Silber / Gold.
## Gibt die Zahl der Drehungen zurück.
func build(stars: Callable) -> int:
	for t in tiles.values():
		t.queue_free()
	tiles.clear()
	var turns: Array[HexTile3D] = []
	for row in StoryChapter.BOARD_ROWS:
		for col in StoryChapter.BOARD_COLS:
			var cell := Vector2i(col, row)
			var slot := StoryChapter.slot(col, row)
			var tile := HexTile3D.new()
			add_child(tile)
			tiles[cell] = tile
			var c := layout.center(cell)
			var front: Material = _mat_open
			var open := StoryChapter.cell_open(cell, stars)
			var playable := not slot.is_empty() and StoryChapter.playable(slot[0])
			var s := 0
			if open and playable:
				s = int(stars.call(slot[0]))
				if s > 0:
					front = _mat_medal[clampi(s, 1, 3) - 1]
			tile.setup("", _mesh, HEX_RADIUS * (1.0 - GAP), THICKNESS, front, _mat_back)
			tile.place(Vector3(c.x, 0.0, c.y))
			if open and playable:
				_front_text(tile, slot[1], -0.16, 1.0, NAME_COLOR)
				_front_text(tile, "★".repeat(s) + "☆".repeat(3 - s), 0.34, 0.8,
						STAR_GOLD if s > 0 else STAR_EMPTY)
				turns.append(tile)
			elif slot.is_empty():
				_back_text(tile, "bald")
			else:
				_back_lock(tile)  # Kapitel gibt es, aber noch kein Nachbar ist geschafft
			tile.set_flip(0.0)
	# Von unten nach oben drehen (Bildschirm-unten = +Z), bei gleicher Höhe von links.
	turns.sort_custom(func(a: HexTile3D, b: HexTile3D) -> bool:
		if not is_equal_approx(a.position.z, b.position.z):
			return a.position.z > b.position.z
		return a.position.x < b.position.x)
	for k in turns.size():
		turns[k].turn(TURN_START + k * TURN_STAGGER)
	return turns.size()


## Kamera so setzen, dass das Brett in area passt (Pixel im Viewport), Blick von oben.
func fit(area: Rect2, viewport_size: Vector2) -> void:
	var tan_half := tan(deg_to_rad(CAMERA_FOV) / 2.0)
	var size := layout.grid_size() + Vector2.ONE * FRAME_MARGIN * 2.0
	var aspect := viewport_size.x / viewport_size.y
	var fh := area.size.y / viewport_size.y
	var fw := area.size.x / viewport_size.x
	var d := maxf(size.y / (fh * 2.0 * tan_half), size.x / (fw * aspect * 2.0 * tan_half))
	var units_per_px := 2.0 * d * tan_half / viewport_size.y
	var px := area.get_center() - viewport_size / 2.0
	camera.position = Vector3(-px.x * units_per_px, THICKNESS * 0.5 + d, -px.y * units_per_px)


## Brett-Platz unter einem Bildschirmpunkt (Viewport-Pixel), sonst Vector2i(-1, -1).
func cell_at_screen(point: Vector2) -> Vector2i:
	var o := camera.project_ray_origin(point)
	var n := camera.project_ray_normal(point)
	if absf(n.y) < 0.0001:
		return Vector2i(-1, -1)
	var p := o + n * ((THICKNESS * 0.5 - o.y) / n.y)
	return layout.cell_at(Vector2(p.x, p.z), HIT_TOLERANCE)


## Schrift oben auf dem Stein. z: Versatz nach unten (Bildschirm), rel: Größe relativ.
func _front_text(tile: HexTile3D, text: String, z: float, rel: float, color: Color) -> void:
	var l := _label(text, rel, color)
	l.position = Vector3(0, THICKNESS * 0.5 + 0.006, z * HEX_RADIUS)
	l.rotation_degrees = Vector3(-90, 0, 0)
	tile.add_child(l)


## Schrift auf der Rückseite (liegt nach set_flip(0) oben).
func _back_text(tile: HexTile3D, text: String) -> void:
	var l := _label(text, 0.6, BACK_TEXT)
	l.position = Vector3(0, -THICKNESS * 0.5 - 0.006, 0)
	l.rotation_degrees = Vector3(90, 0, 0)
	l.scale = Vector3(-1, -1, 1)
	l.double_sided = true
	tile.add_back_decoration(l)


## Leuchtendes Schloss auf der Rückseite (liegt nach set_flip(0) oben): flacher Körper mit
## Schlüsselloch und runder Bügel darüber. Die Drehung um Z spiegelt nur x (symmetrisch) und
## lässt z gleich, darum liegt der Bügel bei −z (oben auf dem Bildschirm).
func _back_lock(tile: HexTile3D) -> void:
	var lock := Node3D.new()
	lock.position = Vector3(0, -THICKNESS * 0.5 - 0.012, 0.06 * HEX_RADIUS)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = LOCK_COLOR
	glow.cull_mode = BaseMaterial3D.CULL_DISABLED
	var hole_mat := StandardMaterial3D.new()
	hole_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hole_mat.albedo_color = LOCK_HOLE
	hole_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var r := HEX_RADIUS
	# Bügel: flacher Ring, die untere Hälfte verdeckt der Körper.
	var shackle := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.13 * r
	torus.outer_radius = 0.19 * r
	torus.rings = 32
	shackle.mesh = torus
	shackle.material_override = glow
	shackle.scale = Vector3(1, 0.05, 1)
	shackle.position = Vector3(0, 0, -0.13 * r)
	lock.add_child(shackle)
	# Körper
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.5 * r, 0.02, 0.36 * r)
	body.mesh = box
	body.material_override = glow
	body.position = Vector3(0, -0.006, 0.05 * r)
	lock.add_child(body)
	# Schlüsselloch: Kreis und Schlitz
	var dot := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.045 * r
	cyl.bottom_radius = 0.045 * r
	cyl.height = 0.01
	dot.mesh = cyl
	dot.material_override = hole_mat
	dot.position = Vector3(0, -0.02, 0.02 * r)
	lock.add_child(dot)
	var slit := MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(0.035 * r, 0.01, 0.1 * r)
	slit.mesh = sb
	slit.material_override = hole_mat
	slit.position = Vector3(0, -0.02, 0.08 * r)
	lock.add_child(slit)
	for m in lock.get_children():
		(m as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tile.add_back_decoration(lock)


## Label3D, das höchstens so breit wird, dass es auf den Stein passt.
func _label(text: String, rel: float, color: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = FONT_SIZE
	l.modulate = color
	l.outline_size = 14
	l.outline_modulate = TEXT_OUTLINE
	l.shaded = false
	l.double_sided = false
	l.alpha_cut = Label3D.ALPHA_CUT_DISABLED
	l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var width_px := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			FONT_SIZE).x
	var max_w := HEX_RADIUS * 1.45
	var base := HEX_RADIUS * 0.34 * rel / FONT_SIZE
	l.pixel_size = minf(base, max_w / maxf(width_px, 1.0))
	return l
