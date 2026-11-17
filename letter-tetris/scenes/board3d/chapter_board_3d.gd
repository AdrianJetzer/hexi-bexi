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
const CAMERA_FOV := 32.0
const FRAME_MARGIN := 0.2
const HIT_TOLERANCE := 0.9
## Schrift auf den Steinen.
const NAME_COLOR := Color(0.9, 1.4, 1.5)
const NAME_DIM := Color(0.6, 0.75, 0.85, 0.7)
const STAR_GOLD := Color(1.7, 1.25, 0.4)
const STAR_EMPTY := Color(0.55, 0.7, 0.85, 0.65)
const BACK_TEXT := Color(0.5, 0.9, 1.0, 0.45)
const FONT_SIZE := 96
## Dunkler Rand um die Schrift (lesbar auch über dem leuchtenden Kern).
const TEXT_OUTLINE := Color(0.0, 0.02, 0.06, 0.85)
## Dreh-Animation: Pause vor der ersten Drehung, Abstand zwischen den Steinen einer Reihe.
const TURN_START := 0.35
const TURN_STAGGER := 0.16
## Nach den Drehungen der Wertung folgt die neue Reihe nach dieser Pause.
const ROW_AFTER_MEDAL := 0.8

var layout: BoardLayout
var camera: Camera3D
## Vector2i(Spalte, Reihe) -> HexTile3D
var tiles: Dictionary = {}
var _mesh: ArrayMesh
var _mat_open: Material
var _mat_back: Material
var _mat_medal: Array[Material] = []
## Zuletzt gezeigter Stand (Kennung -> Sterne, aufgedeckte Reihen), um Änderungen zu
## erkennen und nur diese zu drehen. Leer = noch nie gezeigt (dann ohne Animation).
var _shown_stars: Dictionary = {}
var _shown_rows: int = -1


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
## Seit dem letzten Aufbau verbesserte Kapitel drehen sich zu Bronze / Silber / Gold, danach
## drehen sich neu aufgedeckte Reihen Stein für Stein um. Gibt die Zahl der Drehungen zurück.
func build(stars: Callable) -> int:
	for t in tiles.values():
		t.queue_free()
	tiles.clear()
	var first := _shown_rows < 0
	var medal_turns: Array[HexTile3D] = []
	var row_turns: Array[HexTile3D] = []
	var open_rows := 0
	for row in StoryChapter.BOARD_ROWS:
		var open := StoryChapter.row_open(row, stars)
		if open:
			open_rows = row + 1
		for col in StoryChapter.BOARD_COLS:
			var cell := Vector2i(col, row)
			var slot := StoryChapter.slot(col, row)
			var tile := HexTile3D.new()
			add_child(tile)
			tiles[cell] = tile
			var c := layout.center(cell)
			if open and not slot.is_empty():
				var id: String = slot[0]
				var playable := StoryChapter.playable(id)
				var s: int = int(stars.call(id)) if playable else 0
				var front: Material = _mat_medal[clampi(s, 1, 3) - 1] if s > 0 else _mat_open
				tile.setup("", _mesh, HEX_RADIUS * (1.0 - GAP), THICKNESS, front, _mat_back)
				tile.place(Vector3(c.x, 0.0, c.y))
				_front_text(tile, slot[1], -0.16, 1.0, NAME_COLOR if playable else NAME_DIM)
				if playable:
					_front_text(tile, "★".repeat(s) + "☆".repeat(3 - s), 0.34, 0.8,
							STAR_GOLD if s > 0 else STAR_EMPTY)
				else:
					_front_text(tile, "bald", 0.34, 0.6, NAME_DIM)
				if not first:
					if row >= _shown_rows:
						row_turns.append(tile)
					elif s > int(_shown_stars.get(id, 0)):
						medal_turns.append(tile)
				_shown_stars[id] = s
			else:
				tile.setup("", _mesh, HEX_RADIUS * (1.0 - GAP), THICKNESS, _mat_open, _mat_back)
				tile.place(Vector3(c.x, 0.0, c.y))
				tile.set_flip(0.0)
				if slot.is_empty():
					_back_text(tile, "bald")
	_shown_rows = open_rows
	var delay := TURN_START
	for t in medal_turns:
		t.turn(delay)
		delay += TURN_STAGGER
	if not medal_turns.is_empty():
		delay += ROW_AFTER_MEDAL
	for t in row_turns:
		t.turn(delay)
		delay += TURN_STAGGER
	# Jede Drehung mit einem kurzen Vibrations-Tick, wenn der Stein umschlägt.
	var turned := medal_turns + row_turns
	for k in turned.size():
		var tw := create_tween()
		tw.tween_interval(TURN_START + k * TURN_STAGGER + 0.3 \
				+ (ROW_AFTER_MEDAL if k >= medal_turns.size() and not medal_turns.is_empty() else 0.0))
		tw.tween_callback(Settings.tick)
	return medal_turns.size() + row_turns.size()


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
