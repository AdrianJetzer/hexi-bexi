class_name GameSession
extends RefCounted
## Eine Spielrunde im ruhigen Level-Modus (reine Logik, ohne Zeit).
## Verbindet Raster, Buchstabenwahl, Wörterbuch, Punkte und Level und meldet alles
## Wichtige über Signale.
##
## Ablauf: start() → Wörter mit submit_path(cells) einlösen → Level-Ups bringen neue
## Hexagons → request_more_letters() bei Bedarf → end_round().

## Ein neues Hexagon ist erschienen.
signal tile_spawned(cell: Vector2i, letter: String)
## Ein gültiges Wort wurde eingelöst; die Hexagons sind entfernt.
signal word_accepted(word: String, cells: Array[Vector2i], points: int)
## Gewischte Buchstaben ergeben kein gültiges Wort (oder der Weg ist ungültig).
signal word_rejected(cells: Array[Vector2i], reason: String)
signal score_changed(score: int)
## Neues Level erreicht (vor dem Nachschub an Hexagons).
signal level_changed(level: int)
## Der Spieler hat die Runde beendet.
signal round_ended(final_score: int, final_level: int)

const REASON_TOO_SHORT := "too_short"
const REASON_INVALID_PATH := "invalid_path"
const REASON_NOT_A_WORD := "not_a_word"
const REASON_ROUND_OVER := "round_over"

var grid: HexGrid
var score: int = 0
var words_found: int = 0
var last_word: String = ""
var last_points: int = 0
var is_over: bool = false
## Schwierigkeitsstufe dieser Runde (1..5).
var difficulty: int = 1

var _balance: GameBalance
var _dictionary: WordDictionary
var _picker: LetterPicker
var _spawner: Spawner
var _level: int = 1


## seed_value < 0: zufällig; sonst reproduzierbar (für Tests).
## common_words: geläufige Wörter für die Wort-Hilfe (null = keine Hilfe).
## difficulty_level: Schwierigkeitsstufe 1..5 (siehe GameBalance.difficulty_levels).
func _init(balance: GameBalance, lang: LanguageData, dictionary: WordDictionary, seed_value: int = -1,
		common_words: WordDictionary = null, difficulty_level: int = -1) -> void:
	_balance = balance
	_dictionary = dictionary
	var rng_letters := RandomNumberGenerator.new()
	var rng_cells := RandomNumberGenerator.new()
	if seed_value >= 0:
		rng_letters.seed = seed_value
		rng_cells.seed = seed_value + 7919
	else:
		rng_letters.randomize()
		rng_cells.randomize()
	_picker = LetterPicker.new(lang, rng_letters)
	_spawner = Spawner.new(_picker, rng_cells)
	difficulty = difficulty_level if difficulty_level > 0 else balance.default_difficulty
	if common_words != null:
		_spawner.finder = WordFinder.new(common_words, balance.min_word_length(1), balance.help_max_word_length)
		_spawner.difficulty = balance.difficulty(difficulty)
	grid = HexGrid.new(balance.grid_cols, balance.grid_rows)


# --- Rundenablauf ----------------------------------------------------------------

## Neue Runde: Feld leeren und die Start-Hexagons setzen.
func start() -> void:
	grid.clear_all()
	score = 0
	words_found = 0
	last_word = ""
	last_points = 0
	is_over = false
	_level = 1
	_update_finder_length()
	_spawn(_balance.start_tiles)
	score_changed.emit(score)
	level_changed.emit(_level)


## Knopf „Neue Buchstaben“: einige Hexagons gegen Punkte. Gibt die Anzahl neuer Hexagons zurück.
## Ist kein Platz frei, passiert nichts (und es kostet nichts).
func request_more_letters() -> int:
	if is_over or grid.free_count() == 0:
		return 0
	var placed := _spawn(_balance.refill_tiles)
	score = maxi(score - _balance.refill_cost, 0)
	score_changed.emit(score)
	return placed


## Runde beenden (Menü-Knopf → „Ja“).
func end_round() -> void:
	if is_over:
		return
	is_over = true
	round_ended.emit(score, _level)


func level() -> int:
	return _level


## Mindestlänge eines Wortes im aktuellen Level.
func min_word_length() -> int:
	return _balance.min_word_length(_level)


## Punkte, ab denen das nächste Level erreicht ist.
func next_level_score() -> int:
	return _balance.threshold(_level + 1)


# --- Wischen ---------------------------------------------------------------------

## Darf dieser Platz an den bisherigen Weg angehängt werden?
## (belegt, noch nicht im Weg, Nachbar des letzten Platzes)
func can_extend(path: Array[Vector2i], cell: Vector2i) -> bool:
	if is_over or not grid.is_inside(cell) or grid.is_free(cell) or path.has(cell):
		return false
	return path.is_empty() or grid.are_neighbors(path[path.size() - 1], cell)


## Buchstaben entlang eines Wegs.
func word_for(path: Array[Vector2i]) -> String:
	var w := ""
	for cell in path:
		w += grid.get_letter(cell)
	return w


## Gewischten Weg einlösen (beim Loslassen). Gibt true zurück, wenn das Wort gültig war.
func submit_path(path: Array[Vector2i]) -> bool:
	if is_over:
		word_rejected.emit(path, REASON_ROUND_OVER)
		return false
	if not _is_valid_path(path):
		word_rejected.emit(path, REASON_INVALID_PATH)
		return false
	if path.size() < min_word_length():
		word_rejected.emit(path, REASON_TOO_SHORT)
		return false
	var word := word_for(path)
	if not _dictionary.contains(word):
		word_rejected.emit(path, REASON_NOT_A_WORD)
		return false
	for cell in path:
		grid.clear(cell)
	var points := Scoring.word_points(word.length(), _balance.points_factor)
	score += points
	words_found += 1
	last_word = word
	last_points = points
	word_accepted.emit(word, path, points)
	score_changed.emit(score)
	_check_level_up()
	return true


# --- intern ----------------------------------------------------------------------

## Level steigt, solange die nächste Schwelle erreicht ist; je Level kommt Nachschub.
func _check_level_up() -> void:
	while score >= next_level_score():
		_level += 1
		_update_finder_length()
		level_changed.emit(_level)
		_spawn(_balance.tiles_per_level)


## Die Wort-Hilfe zählt nur Wörter, die im aktuellen Level gültig sind.
func _update_finder_length() -> void:
	if _spawner.finder != null:
		_spawner.finder.min_length = min_word_length()
		_spawner.finder.max_length = maxi(_balance.help_max_word_length, min_word_length() + 1)


func _is_valid_path(path: Array[Vector2i]) -> bool:
	var seen := {}
	for i in path.size():
		var cell := path[i]
		if not grid.is_inside(cell) or grid.is_free(cell) or seen.has(cell):
			return false
		if i > 0 and not grid.are_neighbors(path[i - 1], cell):
			return false
		seen[cell] = true
	return true


## Bis zu `count` neue Hexagons setzen (weniger, wenn kein Platz). Gibt die Anzahl zurück.
func _spawn(count: int) -> int:
	var placed := 0
	for i in count:
		var r := _spawner.spawn_into(grid)
		if r.is_empty():
			break
		placed += 1
		tile_spawned.emit(r["cell"], r["letter"])
	return placed
