class_name WordSeeder
extends RefCounted
## Gezieltes Säen (siehe spec/run-mode.md, „Bestimmtes Wort“): legt ein Zielwort als
## zusammenhängende Kette ins Feld. Bevorzugt werden vorhandene Steine (sie „verwandeln“
## sich); nur wenn das nicht reicht, kommen freie Plätze dazu, ohne dass etwas schwebt.
## Die Kette wird zufällig gewählt, damit sie nicht immer gerade verläuft.

## Wie viele Suchschritte pro Versuch erlaubt sind (begrenzt die Rechenzeit).
const BUDGET := 4000

var _rng: RandomNumberGenerator
var _steps: int = 0


func _init(rng: RandomNumberGenerator = null) -> void:
	_rng = rng if rng else RandomNumberGenerator.new()


## Zufälliges Wort der Länge `length` aus `words`, das auch in `valid` steht.
## Leer, wenn es keines gibt.
func pick_target(words: WordDictionary, valid: WordDictionary, length: int) -> String:
	var n := words.count_of_length(length)
	if n == 0:
		return ""
	for i in 50:
		var w := words.word_at(length, _rng.randi_range(0, n - 1))
		if valid == null or valid.contains(w):
			return w
	return ""


## Kette für `word` suchen. Ergebnis: Liste von Plätzen (Reihenfolge = Buchstaben),
## leer, wenn keine Kette passt. Das Feld wird nicht verändert.
func find_chain(grid: HexGrid, word: String) -> Array[Vector2i]:
	# 1. Versuch: nur vorhandene Steine. 2. Versuch: auch freie Plätze.
	for allow_free in [false, true]:
		var starts := grid.all_cells()
		_shuffle(starts)
		_steps = 0
		for start in starts:
			if _steps > BUDGET:
				break
			if not _usable(grid, start, allow_free):
				continue
			var path: Array[Vector2i] = [start]
			if _extend(grid, path, word.length(), allow_free):
				return path
	return []


## Zielwort ins Feld legen. Gibt die Änderungen zurück:
## [{"cell": Vector2i, "letter": String, "new": bool}] (new = vorher frei). Leer = nicht möglich.
func seed(grid: HexGrid, word: String) -> Array:
	var chain := find_chain(grid, word)
	var changes: Array = []
	if chain.is_empty():
		return changes
	# Von unten nach oben setzen, damit neue Steine nie (auch nicht kurz) schweben.
	var order := range(chain.size())
	order.sort_custom(func(a: int, b: int) -> bool: return chain[a].y < chain[b].y)
	for i in order:
		var cell := chain[i]
		var letter := word[i]
		changes.append({"cell": cell, "letter": letter, "new": grid.is_free(cell)})
		grid.set_letter(cell, letter)
	return changes


# --- intern ------------------------------------------------------------------------

func _usable(grid: HexGrid, cell: Vector2i, allow_free: bool) -> bool:
	return grid.is_occupied(cell) or allow_free


func _extend(grid: HexGrid, path: Array[Vector2i], length: int, allow_free: bool) -> bool:
	_steps += 1
	if _steps > BUDGET:
		return false
	if path.size() == length:
		return _supported(grid, path)
	var next := grid.neighbors(path[path.size() - 1])
	_shuffle(next)
	# Vorhandene Steine zuerst.
	next.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return grid.is_occupied(a) and not grid.is_occupied(b))
	for nb in next:
		if path.has(nb) or not _usable(grid, nb, allow_free):
			continue
		path.append(nb)
		if _extend(grid, path, length, allow_free):
			return true
		path.pop_back()
	return false


## Schwebt nach dem Setzen kein neuer Stein? Ein freier Platz braucht darunter einen
## Stein (vorhanden oder ebenfalls in der Kette) oder liegt in der untersten Reihe.
func _supported(grid: HexGrid, path: Array[Vector2i]) -> bool:
	for cell in path:
		if grid.is_occupied(cell) or cell.y == 0:
			continue
		var below := Vector2i(cell.x, cell.y - 1)
		if not (grid.is_occupied(below) or path.has(below)):
			return false
	return true


func _shuffle(cells: Array) -> void:
	for i in range(cells.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var t = cells[i]
		cells[i] = cells[j]
		cells[j] = t
