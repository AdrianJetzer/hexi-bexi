class_name BoardView3D
extends Node3D
## 3D-Spielfeld eines Laufs (RunSession): Rahmen, Hexagons, Licht, Kamera und Wisch-Eingabe.
## Geometrie wie BoardLayout, in der Ebene X/Z (Bildschirm-unten = +Z), Hexagon-Mitten bei y = 0.

## Die gerade gewischten Buchstaben (leer, wenn nicht gewischt wird).
signal path_changed(word: String)
## Antipp-Modus: ein Stein wurde angetippt (z. B. für „Stein ersetzen“).
signal cell_tapped(cell: Vector2i)
## Wortanfang-Modus („Vervollständigen“): ein Weg wurde gewischt (wird nicht eingelöst).
signal prefix_swiped(path: Array[Vector2i])

## Außenradius eines Hexagon-Platzes in Welt-Einheiten.
const HEX_RADIUS := 1.0
## Abstand zwischen den Hexagons (Anteil des Radius).
const GAP := 0.07
const THICKNESS := 0.42
const CORNER := 0.16
const BEVEL := 0.13
## Rand rund um das Raster (Platz für die Leuchtkante, kein sichtbarer Rahmen mehr).
const FRAME_MARGIN := 0.15
## Öffnungswinkel der Kamera (Grad).
const CAMERA_FOV := 32.0
## Treffer-Toleranz beim Wischen (Anteil des Innenradius).
const HIT_TOLERANCE := 0.8

var session: RunSession
var layout: BoardLayout
var camera: Camera3D

var _tiles: Dictionary = {}          # Vector2i -> HexTile3D
var _path: Array[Vector2i] = []
var _touch_index: int = -1
var _finger: Vector3 = Vector3.ZERO
var _tile_mesh: ArrayMesh
var _mat_front: Material
var _mat_selected: Material
var _mat_back: Material
var _beam: MeshInstance3D
var _beam_mat: StandardMaterial3D
var _static: Node3D
var _burst_frame: int = -1
var _burst_index: int = 0
## Antipp-Modus statt Wischen (z. B. „Stein ersetzen“).
var tap_mode: bool = false
## Wortanfang-Modus: Gewischtes wird nicht eingelöst, sondern als prefix_swiped gemeldet.
var prefix_mode: bool = false
## Steine, die gerade als Tipp oder Lösung pulsieren.
var _hint_cells: Array[Vector2i] = []
## Steine, die gerade als Scan-Ergebnis leuchten.
var _scan_cells: Array[Vector2i] = []

## Verzögerung zwischen Hexagons, die gleichzeitig erscheinen (Sekunden).
const BURST_DELAY := 0.09


func _ready() -> void:
	var tile_r := HEX_RADIUS * (1.0 - GAP)
	_tile_mesh = HexMesh.build(tile_r, THICKNESS, CORNER, BEVEL)
	_mat_front = CosmicMaterials.front(HEX_RADIUS)
	_mat_selected = CosmicMaterials.selected(HEX_RADIUS)
	_mat_back = CosmicMaterials.back(HEX_RADIUS)

	var we := WorldEnvironment.new()
	we.environment = CosmicMaterials.environment()
	add_child(we)
	_build_lights()

	camera = Camera3D.new()
	camera.fov = CAMERA_FOV
	camera.rotation = Vector3(-PI / 2.0, 0, 0)
	add_child(camera)
	camera.make_current()

	_beam = MeshInstance3D.new()
	_beam_mat = StandardMaterial3D.new()
	_beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam_mat.albedo_color = Color(0.5, 1.4, 1.7)
	_beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_beam)


## Neue Runde anbinden. Baut Raster, Rahmen und Hexagons passend zum aktuellen Feld auf.
func setup(p_session: RunSession) -> void:
	if session != null:
		session.tile_spawned.disconnect(_on_tile_spawned)
		session.word_accepted.disconnect(_on_word_accepted)
		session.word_rejected.disconnect(_on_word_rejected)
		session.tile_changed.disconnect(_on_tile_changed)
		session.tiles_removed.disconnect(_on_tiles_removed)
	session = p_session
	session.tile_spawned.connect(_on_tile_spawned)
	session.word_accepted.connect(_on_word_accepted)
	session.word_rejected.connect(_on_word_rejected)
	session.tile_changed.connect(_on_tile_changed)
	session.tiles_removed.connect(_on_tiles_removed)
	tap_mode = false
	prefix_mode = false
	_hint_cells.clear()

	var g := session.grid
	var probe := BoardLayout.new(g.cols, g.rows, HEX_RADIUS)
	layout = BoardLayout.new(g.cols, g.rows, HEX_RADIUS, -probe.grid_size() / 2.0)
	_build_static()
	_cancel_swipe()
	for tile in _tiles.values():
		tile.queue_free()
	_tiles.clear()
	for cell in g.all_cells():
		if g.is_occupied(cell):
			_make_tile(cell, g.get_letter(cell))


## Kamera so setzen, dass das Feld (mit Rahmen) in area passt (Pixel im Viewport).
func fit_to_screen(area: Rect2, viewport_size: Vector2) -> void:
	if layout == null:
		return
	var size := layout.grid_size() + Vector2.ONE * FRAME_MARGIN * 2.0
	var tan_half := tan(deg_to_rad(CAMERA_FOV) / 2.0)
	var aspect := viewport_size.x / viewport_size.y
	var fw := area.size.x / viewport_size.x
	var fh := area.size.y / viewport_size.y
	var d := maxf(size.y / (fh * 2.0 * tan_half), size.x / (fw * aspect * 2.0 * tan_half))
	var visible_h := 2.0 * d * tan_half
	var visible_w := visible_h * aspect
	var cx := (area.position.x + area.size.x / 2.0) / viewport_size.x
	var cy := (area.position.y + area.size.y / 2.0) / viewport_size.y
	var top := THICKNESS * 0.5
	camera.position = Vector3(-(cx - 0.5) * visible_w, top + d, -(cy - 0.5) * visible_h)


## Welt-Position der Mitte eines Platzes (Hexagon-Mitte).
func cell_position(cell: Vector2i) -> Vector3:
	var c := layout.center(cell)
	return Vector3(c.x, 0.0, c.y)


## Bildschirmpunkt (Viewport-Pixel) auf der Oberseite der Hexagons.
func screen_to_board(point: Vector2) -> Vector3:
	var o := camera.project_ray_origin(point)
	var n := camera.project_ray_normal(point)
	var plane_y := THICKNESS * 0.5
	if absf(n.y) < 0.0001:
		return Vector3(INF, INF, INF)
	var t := (plane_y - o.y) / n.y
	return o + n * t


# --- Aufbau ---------------------------------------------------------------------

func _build_lights() -> void:
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


## Rahmen, Boden, Leuchtkante und Hintergrund (ändern sich nur mit der Rastergröße).
func _build_static() -> void:
	if _static != null:
		_static.queue_free()
	_static = Node3D.new()
	add_child(_static)

	var inner := layout.inner_contour()
	var floor_y := -THICKNESS * 0.5
	var frame_top := THICKNESS * 0.1
	# Kein dunkler Rahmen mehr: das Feld wird nur von der leuchtenden Zickzack-Kante umschlossen.

	# Boden im Feld
	var well := _csg_polygon(inner, 0.05, CosmicMaterials.well_floor())
	well.position.y = floor_y - 0.05
	_static.add_child(well)

	# Leuchtende Innenkante: schmaler Streifen oben auf dem Rahmen
	var grown := Geometry2D.offset_polygon(inner, 0.06, Geometry2D.JOIN_MITER)
	if not grown.is_empty():
		var glow := CSGCombiner3D.new()
		_static.add_child(glow)
		var strip := _csg_polygon(grown[0], 0.01, CosmicMaterials.frame_glow())
		strip.position.y = frame_top + 0.002
		glow.add_child(strip)
		var cut := _csg_polygon(inner, 1.0, null)
		cut.operation = CSGShape3D.OPERATION_SUBTRACTION
		cut.rotation_degrees = Vector3.ZERO
		cut.position = Vector3(0, 0, 0.5)
		strip.add_child(cut)

	# Hintergrund (Platzhalter für den animierten Nebel)
	var bg := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(400, 400)  # groß genug auch für breite Fenster (Nebel ist triplanar)
	bg.mesh = plane
	bg.material_override = CosmicMaterials.background()
	bg.position.y = -3.0
	bg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_static.add_child(bg)


## Flaches Polygon (in X/Z) nach oben extrudiert.
func _csg_polygon(points: PackedVector2Array, height: float, mat: Material) -> CSGPolygon3D:
	var p := CSGPolygon3D.new()
	p.polygon = points
	p.depth = height
	# Lokale XY-Ebene → Welt-XZ, Extrusion (lokal −Z) → Welt +Y
	p.rotation_degrees = Vector3(90, 0, 0)
	if mat:
		p.material = mat
	return p


func _make_tile(cell: Vector2i, letter: String) -> HexTile3D:
	_hint_cells.erase(cell)
	if _tiles.has(cell):
		_tiles[cell].queue_free()
	var tile := HexTile3D.new()
	add_child(tile)
	# Joker-Steine zeigen einen Stern statt eines Buchstabens.
	var shown := "★" if letter == RunSession.JOKER else letter
	tile.setup(shown, _tile_mesh, HEX_RADIUS * (1.0 - GAP), THICKNESS, _mat_front, _mat_back,
		CosmicMaterials.LETTER, 0.0, CosmicMaterials.BACK_LETTER)
	tile.set_selection_materials(_mat_front, _mat_selected)
	tile.place(cell_position(cell))
	_tiles[cell] = tile
	return tile


# --- Signale der Spiellogik ------------------------------------------------------

## Scan: diese Steine leuchten, bis sich das Feld ändert oder ein Wort angenommen wird.
func show_scan(cells: Array[Vector2i]) -> void:
	clear_scan()
	for cell in cells:
		if _tiles.has(cell):
			_scan_cells.append(cell)
			_tiles[cell].set_outline(true)


func clear_scan() -> void:
	for cell in _scan_cells:
		if _tiles.has(cell):
			_tiles[cell].set_outline(false)
	_scan_cells.clear()


func _on_tile_spawned(cell: Vector2i, letter: String) -> void:
	clear_scan()
	# Mehrere Hexagons im selben Moment (Start, Auffüllen, nach einem Wort) erscheinen nacheinander.
	_make_tile(cell, letter).appear(_next_burst_delay())


## Ein Stein bekommt einen neuen Buchstaben (Ersetzen, Säen): er dreht sich einmal um.
func _on_tile_changed(cell: Vector2i, letter: String) -> void:
	clear_scan()
	_make_tile(cell, letter).turn(_next_burst_delay())


## Tipp oder Lösung: diese Steine pulsieren lassen (leer = keiner).
func show_hint(cells: Array[Vector2i]) -> void:
	clear_hint()
	for cell in cells:
		if _tiles.has(cell):
			_hint_cells.append(cell)
			_tiles[cell].start_pulse()


func clear_hint() -> void:
	for cell in _hint_cells:
		if _tiles.has(cell):
			_tiles[cell].stop_pulse()
	_hint_cells.clear()


func _next_burst_delay() -> float:
	var frame := Engine.get_process_frames()
	if frame == _burst_frame:
		_burst_index += 1
	else:
		_burst_frame = frame
		_burst_index = 0
	return _burst_index * BURST_DELAY


func _on_word_accepted(_word: String, cells: Array[Vector2i], _row: int) -> void:
	clear_scan()
	for i in cells.size():
		var cell := cells[i]
		if _tiles.has(cell):
			var tile: HexTile3D = _tiles[cell]
			_tiles.erase(cell)
			tile.vanish(i * 0.06)


## Aufräumen: diese Steine verschwinden (wie bei einem gefundenen Wort).
func _on_tiles_removed(cells: Array[Vector2i]) -> void:
	_on_word_accepted("", cells, -1)


func _on_word_rejected(cells: Array[Vector2i], _reason: String) -> void:
	for cell in cells:
		if _tiles.has(cell):
			_tiles[cell].shake()


# --- Wischen --------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	# Gewischt wird nur, solange ein Auftrag läuft (nicht während der Auftragswahl).
	if session == null or layout == null or session.is_over or session.quest == null:
		return
	if tap_mode:
		if event is InputEventScreenTouch and event.pressed:
			var p := screen_to_board(event.position)
			if is_finite(p.x):
				var cell := layout.cell_at(Vector2(p.x, p.z), HIT_TOLERANCE)
				if cell.x >= 0 and session.grid.is_occupied(cell):
					cell_tapped.emit(cell)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_path.clear()
			_try_add(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == _touch_index:
			_finish_swipe()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_try_add(event.position)
		get_viewport().set_input_as_handled()


func _try_add(screen_point: Vector2) -> void:
	var p := screen_to_board(screen_point)
	if not is_finite(p.x):
		return
	_finger = p
	var cell := layout.cell_at(Vector2(p.x, p.z), HIT_TOLERANCE)
	if cell.x >= 0 and session.can_extend(_path, cell):
		_path.append(cell)
		if _tiles.has(cell):
			_tiles[cell].set_selected(true)
		path_changed.emit(session.word_for(_path))
	_update_beam()


func _finish_swipe() -> void:
	var path: Array[Vector2i] = _path.duplicate()
	_cancel_swipe()
	if path.is_empty():
		return
	if prefix_mode:
		prefix_swiped.emit(path)
	else:
		session.submit_path(path)


## Diese Steine wackeln (z. B. Wortanfang ohne Fortsetzung).
func shake_cells(cells: Array[Vector2i]) -> void:
	for cell in cells:
		if _tiles.has(cell):
			_tiles[cell].shake()


func _cancel_swipe() -> void:
	for cell in _path:
		if _tiles.has(cell):
			_tiles[cell].set_selected(false)
	_path.clear()
	_touch_index = -1
	if _beam:
		_beam.mesh = null
	path_changed.emit("")


## Leuchtender Energie-Strahl über den gewählten Hexagons bis zum Finger.
func _update_beam() -> void:
	if _path.is_empty():
		_beam.mesh = null
		return
	var y := THICKNESS * 0.5 + 0.08
	var pts: Array[Vector3] = []
	for cell in _path:
		var c := cell_position(cell)
		pts.append(Vector3(c.x, y, c.z))
	pts.append(Vector3(_finger.x, y, _finger.z))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w := 0.09
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var dir := b - a
		if dir.length() < 0.001:
			continue
		var side := Vector3(-dir.z, 0, dir.x).normalized() * w
		for v in [a - side, a + side, b + side, a - side, b + side, b - side]:
			st.add_vertex(v)
	# runde Gelenke als kleine Sechsecke
	for p in pts:
		for k in 6:
			var a0 := PI / 3.0 * k
			var a1 := PI / 3.0 * (k + 1)
			st.add_vertex(p)
			st.add_vertex(p + Vector3(cos(a0), 0, sin(a0)) * w)
			st.add_vertex(p + Vector3(cos(a1), 0, sin(a1)) * w)
	var mesh := st.commit()
	if mesh.get_surface_count() > 0:
		mesh.surface_set_material(0, _beam_mat)
	_beam.mesh = mesh
