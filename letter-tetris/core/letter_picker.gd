class_name LetterPicker
extends RefCounted
## Wählt den Buchstaben für ein neues Hexagon (Version 1):
## Zufall, gewichtet nach Häufigkeit, mit Vokal-Ausgleich.

var _lang: LanguageData
var _rng: RandomNumberGenerator


func _init(lang: LanguageData, rng: RandomNumberGenerator = null) -> void:
	assert(lang != null and lang.is_valid(), "LanguageData unvollständig")
	_lang = lang
	_rng = rng if rng != null else RandomNumberGenerator.new()


## board_letters: alle Buchstaben, die gerade im Feld liegen.
func pick(board_letters: PackedStringArray) -> String:
	match _needed_kind(board_letters):
		"vowel":
			return _weighted_pick(func(l: String) -> bool: return _lang.is_vowel(l))
		"consonant":
			return _weighted_pick(func(l: String) -> bool: return not _lang.is_vowel(l))
		_:
			return _weighted_pick(func(_l: String) -> bool: return true)


## Buchstabe für einen bestimmten freien Platz, mit Wort-Hilfe je nach Stufe.
## finder sucht in den geläufigen Wörtern. Ohne finder/Stufe oder bei Stärke 0 wie pick().
func pick_for_cell(grid: HexGrid, cell: Vector2i, finder: WordFinder, level: DifficultyLevel) -> String:
	var board := _board_letters(grid)
	if finder == null or level == null or level.help_strength <= 0.0:
		return pick(board)
	var kind := _needed_kind(board)
	var allowed := PackedStringArray()
	for l in _lang.alphabet:
		var vowel := _lang.is_vowel(l)
		if kind == "any" or (kind == "vowel" and vowel) or (kind == "consonant" and not vowel):
			allowed.append(l)
	var by_letter := finder.words_for_letters(grid, cell, allowed)
	var counts := {}
	for l in allowed:
		counts[l] = (by_letter[l] as Dictionary).size()
	last_counts = counts

	# Zu wenige Wörter im Feld: gezielt den Buchstaben mit den meisten neuen Wörtern.
	if finder.words_on_board(grid).size() < level.min_words:
		var best := 0
		for l in allowed:
			best = maxi(best, counts[l])
		if best > 0:
			var top := {}
			for l in allowed:
				if counts[l] == best:
					top[l] = true
			return _weighted_pick(func(l: String) -> bool: return top.has(l))

	# Sonst: Häufigkeit × (1 + Stärke × Anzahl Wörter)
	var weights := {}
	for i in _lang.alphabet.size():
		var l := _lang.alphabet[i]
		if counts.has(l):
			weights[l] = _lang.weights[i] * (1.0 + level.help_strength * counts[l])
	return _pick_from_weights(weights)


## Wortzahlen der letzten Bewertung (Buchstabe → Anzahl), z. B. für Tests und Anzeige.
var last_counts: Dictionary = {}


func _board_letters(grid: HexGrid) -> PackedStringArray:
	var letters := PackedStringArray()
	for c in grid.all_cells():
		if grid.is_occupied(c):
			letters.append(grid.get_letter(c))
	return letters


func _pick_from_weights(weights: Dictionary) -> String:
	var total := 0.0
	for l in weights:
		total += weights[l]
	var x := _rng.randf() * total
	var last := ""
	for l in _lang.alphabet:
		if not weights.has(l):
			continue
		last = l
		x -= weights[l]
		if x <= 0.0:
			return l
	return last


## "vowel", "consonant" oder "any" – je nach Vokal-Anteil im Feld.
func _needed_kind(board_letters: PackedStringArray) -> String:
	if board_letters.size() < _lang.balance_min_letters:
		return "any"
	var vowel_count := 0
	for l in board_letters:
		if _lang.is_vowel(l):
			vowel_count += 1
	var ratio := float(vowel_count) / board_letters.size()
	if ratio < _lang.min_vowel_ratio:
		return "vowel"
	if ratio > _lang.max_vowel_ratio:
		return "consonant"
	return "any"


func _weighted_pick(allowed: Callable) -> String:
	var total := 0.0
	for i in _lang.alphabet.size():
		if allowed.call(_lang.alphabet[i]):
			total += _lang.weights[i]
	assert(total > 0.0, "Keine erlaubten Buchstaben")
	var x := _rng.randf() * total
	var last := ""
	for i in _lang.alphabet.size():
		var l := _lang.alphabet[i]
		if not allowed.call(l):
			continue
		last = l
		x -= _lang.weights[i]
		if x <= 0.0:
			return l
	return last
