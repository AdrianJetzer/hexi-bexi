class_name BoardView
extends Node2D
## Zeigt das Spielfeld einer GameSession und nimmt das Wischen entgegen (Platzhalter-Optik).

## Die gerade gewischten Buchstaben (leer, wenn nicht gewischt wird).
signal path_changed(word: String)

const FRAME := Color(0.13, 0.12, 0.2)
const FRAME_EDGE := Color(0.35, 0.33, 0.5)
const WELL := Color(0.05, 0.05, 0.1)
const GLOW := Color(0.45, 0.8, 1.0)
const SLOT := Color(0.6, 0.7, 1.0, 0.07)
const LINE := Color(0.7, 0.95, 1.0, 0.85)

var session: GameSession
var layout: BoardLayout

var _tiles: Dictionary = {}          # Vector2i -> HexTile
var _path: Array[Vector2i] = []
var _touch_index: int = -1
var _finger: Vector2 = Vector2.ZERO
var _line: Line2D


func _ready() -> void:
	_line = Line2D.new()
	_line.default_color = LINE
	_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_line.z_index = 10
	add_child(_line)


## Neue Runde/Layout anbinden. Baut die Hexagons passend zum aktuellen Feld neu auf.
func setup(p_session: GameSession, p_layout: BoardLayout) -> void:
	if session != null:
		session.tile_spawned.disconnect(_on_tile_spawned)
		session.word_accepted.disconnect(_on_word_accepted)
		session.word_rejected.disconnect(_on_word_rejected)
	session = p_session
	layout = p_layout
	session.tile_spawned.connect(_on_tile_spawned)
	session.word_accepted.connect(_on_word_accepted)
	session.word_rejected.connect(_on_word_rejected)
	_cancel_swipe()
	_rebuild()


## Nur die Geometrie ändern (z. B. Bildschirmgröße), Hexagons bleiben.
func set_layout(p_layout: BoardLayout) -> void:
	layout = p_layout
	for cell in _tiles:
		var tile: HexTile = _tiles[cell]
		tile.position = layout.center(cell)
		tile.setup(tile.letter, layout.radius)
	_line.width = layout.radius * 0.28
	_update_line()
	queue_redraw()


func _rebuild() -> void:
	for tile in _tiles.values():
		tile.queue_free()
	_tiles.clear()
	if session == null:
		return
	for cell in session.grid.all_cells():
		if session.grid.is_occupied(cell):
			_make_tile(cell, session.grid.get_letter(cell))
	_line.width = layout.radius * 0.28
	queue_redraw()


func _make_tile(cell: Vector2i, letter: String) -> HexTile:
	if _tiles.has(cell):
		_tiles[cell].queue_free()
	var tile := HexTile.new()
	tile.position = layout.center(cell)
	add_child(tile)
	tile.setup(letter, layout.radius)
	_tiles[cell] = tile
	return tile


# --- Zeichnen (Rahmen) ----------------------------------------------------------

func _draw() -> void:
	if layout == null:
		return
	var contour := layout.inner_contour()
	var frame := layout.grid_rect().grow(layout.radius * 0.35)
	draw_rect(frame, FRAME)
	draw_rect(frame, FRAME_EDGE, false, 2.0)
	draw_colored_polygon(contour, WELL)
	for cell in (session.grid.all_cells() if session else []):
		var pts := BoardLayout.hex_points(layout.center(cell), layout.radius * 0.86)
		pts.append(pts[0])
		draw_polyline(pts, SLOT, 1.5, true)
	var closed := contour.duplicate()
	closed.append(contour[0])
	draw_polyline(closed, Color(GLOW, 0.25), layout.radius * 0.18, true)
	draw_polyline(closed, GLOW, maxf(layout.radius * 0.05, 2.0), true)


# --- Signale der Spiellogik ------------------------------------------------------

func _on_tile_spawned(cell: Vector2i, letter: String) -> void:
	_make_tile(cell, letter).appear()


func _on_word_accepted(_word: String, cells: Array[Vector2i], _points: int) -> void:
	for i in cells.size():
		var cell := cells[i]
		if _tiles.has(cell):
			var tile: HexTile = _tiles[cell]
			_tiles.erase(cell)
			tile.vanish(i * 0.05)


func _on_word_rejected(cells: Array[Vector2i], _reason: String) -> void:
	for cell in cells:
		if _tiles.has(cell):
			_tiles[cell].shake()


# --- Wischen --------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if session == null or layout == null or session.is_over or session.is_paused:
		return
	if event is InputEventScreenTouch:
		var local := (make_input_local(event) as InputEventScreenTouch).position
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_path.clear()
			_try_add(local)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == _touch_index:
			_finish_swipe()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_try_add((make_input_local(event) as InputEventScreenDrag).position)
		get_viewport().set_input_as_handled()


func _try_add(point: Vector2) -> void:
	_finger = point
	var cell := layout.cell_at(point)
	if cell.x >= 0 and session.can_extend(_path, cell):
		_path.append(cell)
		if _tiles.has(cell):
			_tiles[cell].selected = true
		path_changed.emit(session.word_for(_path))
	_update_line()


func _finish_swipe() -> void:
	var path: Array[Vector2i] = _path.duplicate()
	_cancel_swipe()
	if path.size() > 0:
		session.submit_path(path)


func _cancel_swipe() -> void:
	for cell in _path:
		if _tiles.has(cell):
			_tiles[cell].selected = false
	_path.clear()
	_touch_index = -1
	if _line:
		_line.clear_points()
	path_changed.emit("")


func _update_line() -> void:
	_line.clear_points()
	if _path.is_empty():
		return
	for cell in _path:
		_line.add_point(layout.center(cell))
	_line.add_point(_finger)
