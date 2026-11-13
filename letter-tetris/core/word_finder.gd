class_name WordFinder
extends RefCounted
## Findet Wörter, die im Feld gerade gewischt werden könnten (Wege über Nachbarn,
## jedes Hexagon höchstens einmal). Wege, mit denen kein Wort beginnen kann,
## werden sofort abgebrochen. Bereits geprüfte Wortanfänge werden gemerkt.

var min_length: int
var max_length: int

var _dict: WordDictionary
var _prefix_cache: Dictionary = {}

const CACHE_LIMIT := 200000
const NONE := Vector2i(-1, -1)


func _init(dictionary: WordDictionary, p_min_length: int = 3, p_max_length: int = 7) -> void:
	_dict = dictionary
	min_length = p_min_length
	max_length = p_max_length


## Alle möglichen Wörter im Feld (Wort → true).
func words_on_board(grid: HexGrid) -> Dictionary:
	var result := {}
	for start in grid.all_cells():
		if grid.is_occupied(start):
			_search(grid, [start], {start: true}, grid.get_letter(start), NONE, NONE, "", result)
	return result


## Alle möglichen Wörter, deren Weg über den belegten Platz `through` führt.
func words_through(grid: HexGrid, through: Vector2i) -> Dictionary:
	var result := {}
	if not grid.is_inside(through) or grid.is_free(through):
		return result
	for start in grid.all_cells():
		if grid.is_occupied(start) and grid.distance(start, through) < max_length:
			_search(grid, [start], {start: true}, grid.get_letter(start), through, NONE, "", result)
	return result


## Für einen (noch freien) Platz: welche Wörter würde jeder Kandidat-Buchstabe möglich machen?
## Ergebnis: Buchstabe → {Wort → true}. Ein einziger Suchlauf für alle Buchstaben.
func words_for_letters(grid: HexGrid, cell: Vector2i, letters: PackedStringArray) -> Dictionary:
	var result := {}
	for l in letters:
		result[l] = {}
	if not grid.is_inside(cell):
		return result
	for start in grid.all_cells():
		if start == cell:
			for l in letters:
				_search(grid, [start], {start: true}, l, cell, cell, l, result[l], letters)
		elif grid.is_occupied(start) and grid.distance(start, cell) < max_length:
			_search_wild(grid, start, cell, letters, result)
	return result


## Wege im Feld, deren Wort im Wörterbuch steht, zwischen p_min und p_max Buchstaben lang ist
## und accept(word) erfüllt. Jeder Eintrag: {"word": String, "path": Array[Vector2i]}.
## Höchstens `limit` Treffer (die Suche bricht dann ab).
func find_paths(grid: HexGrid, p_min: int, p_max: int, accept: Callable, limit: int = 50) -> Array:
	var out: Array = []
	for start in grid.all_cells():
		if out.size() >= limit:
			break
		if grid.is_occupied(start):
			var path: Array[Vector2i] = [start]
			_collect(grid, path, {start: true}, grid.get_letter(start), p_min, p_max, accept, limit, out)
	return out


func _collect(grid: HexGrid, path: Array[Vector2i], used: Dictionary, word: String, p_min: int,
		p_max: int, accept: Callable, limit: int, out: Array) -> void:
	if out.size() >= limit or not _has_prefix(word):
		return
	if word.length() >= p_min and _dict.contains(word) and accept.call(word):
		out.append({"word": word, "path": path.duplicate()})
	if word.length() >= p_max:
		return
	for nb in grid.neighbors(path[path.size() - 1]):
		if used.has(nb) or grid.is_free(nb):
			continue
		path.append(nb)
		used[nb] = true
		_collect(grid, path, used, word + grid.get_letter(nb), p_min, p_max, accept, limit, out)
		used.erase(nb)
		path.pop_back()


func _search_wild(grid: HexGrid, start: Vector2i, cell: Vector2i, letters: PackedStringArray,
		result: Dictionary) -> void:
	# Bis zum Erreichen des Platzes ist der Weg für alle Buchstaben gleich; danach wird verzweigt.
	_search(grid, [start], {start: true}, grid.get_letter(start), cell, cell, "", result, letters)


## path/used: bisheriger Weg. through: Platz, über den das Wort führen muss (NONE = egal).
## wild: freier Platz, der als Kandidat zählt; wild_letter: gewählter Buchstabe dafür ("" = noch nicht).
## out: bei wild_letter != "" oder ohne wild das Ziel-Dictionary; sonst Buchstabe → Dictionary.
func _search(grid: HexGrid, path: Array, used: Dictionary, word: String, through: Vector2i,
		wild: Vector2i, wild_letter: String, out: Dictionary,
		letters: PackedStringArray = PackedStringArray()) -> void:
	if not _has_prefix(word):
		return
	var includes := through == NONE or used.has(through)
	if includes and word.length() >= min_length and _dict.contains(word):
		var target: Dictionary = out
		if wild != NONE and out.has(wild_letter) and out[wild_letter] is Dictionary:
			target = out[wild_letter]
		target[word] = true
	if word.length() >= max_length:
		return
	var last: Vector2i = path[path.size() - 1]
	for nb in grid.neighbors(last):
		if used.has(nb):
			continue
		var is_wild := nb == wild
		if grid.is_free(nb) and not is_wild:
			continue
		if not includes and nb != through:
			if grid.distance(nb, through) > max_length - word.length() - 1:
				continue
		path.append(nb)
		used[nb] = true
		if is_wild and wild_letter == "":
			for l in letters:
				_search(grid, path, used, word + l, through, wild, l, out, letters)
		else:
			var l2 := wild_letter if is_wild else grid.get_letter(nb)
			_search(grid, path, used, word + l2, through, wild, wild_letter, out, letters)
		used.erase(nb)
		path.pop_back()


func _has_prefix(p: String) -> bool:
	if _prefix_cache.has(p):
		return _prefix_cache[p]
	if _prefix_cache.size() > CACHE_LIMIT:
		_prefix_cache.clear()
	var v := _dict.has_prefix(p)
	_prefix_cache[p] = v
	return v
