class_name HexGrid
extends RefCounted
## Hexagon-Raster des Spielfelds (reine Logik, keine Grafik).
##
## Koordinaten: Vector2i(spalte, reihe). Spalte 0 = links, Reihe 0 = unten.
## Hexagons sind unten flach; die Spalten stehen senkrecht.
## Ungerade Spalten liegen ein halbes Feld TIEFER als gerade Spalten.
##
## Nachbarn von (c, r):
##   gleiche Spalte:        (c, r-1), (c, r+1)
##   gerade Spalte c:       (c±1, r), (c±1, r+1)
##   ungerade Spalte c:     (c±1, r-1), (c±1, r)

const EMPTY := ""

var cols: int
var rows: int
var _cells: PackedStringArray


func _init(p_cols: int = 6, p_rows: int = 9) -> void:
	assert(p_cols > 0 and p_rows > 0)
	cols = p_cols
	rows = p_rows
	_cells = PackedStringArray()
	_cells.resize(cols * rows)
	_cells.fill(EMPTY)


# --- Zugriff -----------------------------------------------------------------

func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < cols and cell.y >= 0 and cell.y < rows


func get_letter(cell: Vector2i) -> String:
	assert(is_inside(cell))
	return _cells[_index(cell)]


func set_letter(cell: Vector2i, letter: String) -> void:
	assert(is_inside(cell))
	assert(letter != EMPTY, "Zum Leeren clear() verwenden")
	_cells[_index(cell)] = letter


func clear(cell: Vector2i) -> void:
	assert(is_inside(cell))
	_cells[_index(cell)] = EMPTY


func clear_all() -> void:
	_cells.fill(EMPTY)


func is_free(cell: Vector2i) -> bool:
	return get_letter(cell) == EMPTY


func is_occupied(cell: Vector2i) -> bool:
	return not is_free(cell)


func size() -> int:
	return cols * rows


func free_count() -> int:
	return _cells.count(EMPTY)


func is_full() -> bool:
	return free_count() == 0


func all_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for c in cols:
		for r in rows:
			result.append(Vector2i(c, r))
	return result


# --- Nachbarschaft -----------------------------------------------------------

func neighbors(cell: Vector2i) -> Array[Vector2i]:
	assert(is_inside(cell))
	var c := cell.x
	var r := cell.y
	var candidates: Array[Vector2i] = [Vector2i(c, r - 1), Vector2i(c, r + 1)]
	var side_offset := 0 if c % 2 == 0 else -1
	var side_rows: Array[int] = [r + side_offset, r + 1 + side_offset]
	for dc in [-1, 1]:
		for sr in side_rows:
			candidates.append(Vector2i(c + dc, sr))
	var result: Array[Vector2i] = []
	for n in candidates:
		if is_inside(n):
			result.append(n)
	return result


func are_neighbors(a: Vector2i, b: Vector2i) -> bool:
	return is_inside(a) and is_inside(b) and neighbors(a).has(b)


var _distances: PackedInt32Array = PackedInt32Array()


## Anzahl Schritte über Nachbarn von a nach b (unabhängig davon, ob belegt).
func distance(a: Vector2i, b: Vector2i) -> int:
	if _distances.is_empty():
		_compute_distances()
	return _distances[_index(a) * size() + _index(b)]


func _compute_distances() -> void:
	var n := size()
	_distances.resize(n * n)
	_distances.fill(-1)
	for start in all_cells():
		var si := _index(start)
		var queue: Array[Vector2i] = [start]
		_distances[si * n + si] = 0
		var head := 0
		while head < queue.size():
			var cur := queue[head]
			head += 1
			var d := _distances[si * n + _index(cur)]
			for nb in neighbors(cur):
				var k := si * n + _index(nb)
				if _distances[k] < 0:
					_distances[k] = d + 1
					queue.append(nb)


# --- Höhe, Löcher, Plätze für neue Hexagons ----------------------------------

## Vergleichswert für die sichtbare Höhe: kleiner = tiefer.
## Ungerade Spalten liegen ein halbes Feld tiefer als gerade.
func height_key(cell: Vector2i) -> int:
	return cell.y * 2 + (0 if cell.x % 2 == 1 else 1)


## Ein Loch ist ein freier Platz, über dem in derselben Spalte ein Hexagon liegt.
func holes() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for c in cols:
		var top := _top_occupied_row(c)
		for r in range(0, top):
			var cell := Vector2i(c, r)
			if is_free(cell):
				result.append(cell)
	return result


## Freie Plätze direkt auf dem Stapel jeder Spalte (schweben nicht).
func stack_tops() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for c in cols:
		var r := _top_occupied_row(c) + 1
		if r < rows:
			result.append(Vector2i(c, r))
	return result


## Mögliche Plätze für das nächste neue Hexagon:
## gibt es Löcher, die tiefsten Löcher; sonst die tiefsten Stapel-Plätze.
## Bei mehreren gleich tiefen Plätzen werden alle zurückgegeben (Zufall wählt später).
func spawn_candidates() -> Array[Vector2i]:
	var pool := holes()
	if pool.is_empty():
		pool = stack_tops()
	return _lowest(pool)


# --- intern ------------------------------------------------------------------

func _index(cell: Vector2i) -> int:
	return cell.x * rows + cell.y


func _top_occupied_row(c: int) -> int:
	for r in range(rows - 1, -1, -1):
		if is_occupied(Vector2i(c, r)):
			return r
	return -1


func _lowest(cells: Array[Vector2i]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if cells.is_empty():
		return result
	var best := height_key(cells[0])
	for cell in cells:
		best = mini(best, height_key(cell))
	for cell in cells:
		if height_key(cell) == best:
			result.append(cell)
	return result
