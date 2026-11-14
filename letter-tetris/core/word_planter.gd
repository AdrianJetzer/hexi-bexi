class_name WordPlanter
extends RefCounted
## Schlaues Tauschen (siehe spec/run-mode.md, „Tauschen“): sucht eine Kette benachbarter
## vorhandener Steine, die mit möglichst wenigen Buchstaben-Änderungen ein Wort ergibt.
## Reine Suche, verändert das Feld nicht.
##
## Vorgehen: zufällige Ketten im Feld (Zufallswege über belegte Nachbarn) gegen zufällige
## Wörter passender Länge vergleichen und die Kombination mit den wenigsten Änderungen nehmen.
## Bei Ketten bis zur erlaubten Änderungszahl passt jedes Wort, bei längeren hilft der Vergleich.

## Wie viele Ketten und wie viele Wörter je Kette verglichen werden (begrenzt die Rechenzeit).
const PATHS := 300
const WORDS_PER_PATH := 80

var _rng: RandomNumberGenerator


func _init(rng: RandomNumberGenerator = null) -> void:
	_rng = rng if rng else RandomNumberGenerator.new()


## Beste Kette für ein Wort in einer der Längen, mit höchstens max_changes Änderungen.
## Ergebnis: {"path": Array[Vector2i], "word": String, "changes": int} oder {} (nicht möglich).
func plant(grid: HexGrid, words: WordDictionary, lengths: PackedInt32Array, max_changes: int) -> Dictionary:
	var tiles: Array[Vector2i] = []
	for cell in grid.all_cells():
		if grid.is_occupied(cell):
			tiles.append(cell)
	var usable := PackedInt32Array()
	for n in lengths:
		if n <= tiles.size() and words.count_of_length(n) > 0:
			usable.append(n)
	if usable.is_empty():
		return {}
	var best := {}
	for p in PATHS:
		var n := usable[_rng.randi_range(0, usable.size() - 1)]
		var path := _random_path(grid, tiles, n)
		if path.is_empty():
			continue
		var letters := ""
		for cell in path:
			letters += grid.get_letter(cell)
		var count := words.count_of_length(n)
		for w in WORDS_PER_PATH:
			var word := words.word_at(n, _rng.randi_range(0, count - 1))
			var changes := _distance(letters, word)
			if changes <= max_changes and (best.is_empty() or changes < best["changes"]):
				best = {"path": path, "word": word, "changes": changes}
				if changes <= 1:
					return best
	return best


## Wie plant(), aber die Kette muss `center` enthalten und dessen Buchstaben behalten
## (Hilfe „Magnet“). Ohne Obergrenze für Änderungen. Ergebnis wie plant(), oder {}.
## keep_letter: Buchstabe, der an center stehen muss ("" = beliebig, z. B. bei einem Joker).
func plant_around(grid: HexGrid, words: WordDictionary, lengths: PackedInt32Array,
		center: Vector2i, keep_letter: String) -> Dictionary:
	var usable := PackedInt32Array()
	for n in lengths:
		if words.count_of_length(n) > 0:
			usable.append(n)
	if usable.is_empty() or not grid.is_occupied(center):
		return {}
	var best := {}
	for p in PATHS:
		var n := usable[_rng.randi_range(0, usable.size() - 1)]
		var path := _path_through(grid, center, n)
		if path.is_empty():
			continue
		var idx := path.find(center)
		var letters := ""
		for cell in path:
			letters += grid.get_letter(cell)
		var count := words.count_of_length(n)
		for w in WORDS_PER_PATH:
			var word := words.word_at(n, _rng.randi_range(0, count - 1))
			if keep_letter != "" and word[idx] != keep_letter:
				continue
			var changes := _distance(letters, word)
			if best.is_empty() or changes < best["changes"]:
				best = {"path": path, "word": word, "changes": changes}
				if changes <= 1:
					return best
	return best


## Zufallsweg der Länge n über belegte Nachbarn, der `center` an zufälliger Stelle enthält.
func _path_through(grid: HexGrid, center: Vector2i, n: int) -> Array[Vector2i]:
	for attempt in 8:
		var before := _rng.randi_range(0, n - 1)
		var used := {center: true}
		var back := _walk(grid, center, before, used)
		var front := _walk(grid, center, n - 1 - before, used)
		if back.size() + front.size() + 1 == n:
			back.reverse()
			var path: Array[Vector2i] = []
			path.append_array(back)
			path.append(center)
			path.append_array(front)
			return path
	return []


## Zufallsweg mit `steps` Schritten ab `from` (ohne `from`), über belegte, unbenutzte Nachbarn.
func _walk(grid: HexGrid, from: Vector2i, steps: int, used: Dictionary) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var last := from
	for s in steps:
		var options: Array[Vector2i] = []
		for nb in grid.neighbors(last):
			if grid.is_occupied(nb) and not used.has(nb):
				options.append(nb)
		if options.is_empty():
			break
		last = options[_rng.randi_range(0, options.size() - 1)]
		used[last] = true
		path.append(last)
	return path


## Zufallsweg der Länge n über belegte Nachbarn, oder leer (Sackgasse).
func _random_path(grid: HexGrid, tiles: Array[Vector2i], n: int) -> Array[Vector2i]:
	for attempt in 8:
		var path: Array[Vector2i] = [tiles[_rng.randi_range(0, tiles.size() - 1)]]
		while path.size() < n:
			var options: Array[Vector2i] = []
			for nb in grid.neighbors(path[path.size() - 1]):
				if grid.is_occupied(nb) and not path.has(nb):
					options.append(nb)
			if options.is_empty():
				break
			path.append(options[_rng.randi_range(0, options.size() - 1)])
		if path.size() == n:
			return path
	return []


func _distance(a: String, b: String) -> int:
	var d := 0
	for i in a.length():
		if a[i] != b[i]:
			d += 1
	return d
