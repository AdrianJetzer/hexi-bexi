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
