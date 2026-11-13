class_name GameSession
extends RefCounted
## Eine Spielrunde (reine Logik). Verbindet Raster, Takt, Buchstabenwahl,
## Wörterbuch und Punkte und meldet alles Wichtige über Signale.
##
## Ablauf: start() → regelmäßig update(delta) → Wörter mit submit_path(cells) einlösen.

## Ein neues Hexagon ist erschienen.
signal tile_spawned(cell: Vector2i, letter: String)
## Ein gültiges Wort wurde eingelöst; die Hexagons sind entfernt.
signal word_accepted(word: String, cells: Array[Vector2i], points: int)
## Gewischte Buchstaben ergeben kein gültiges Wort (oder der Weg ist ungültig).
signal word_rejected(cells: Array[Vector2i], reason: String)
signal score_changed(score: int)
signal level_changed(level: int)
## Kein Platz mehr frei.
signal game_over(final_score: int)

const REASON_TOO_SHORT := "too_short"
const REASON_INVALID_PATH := "invalid_path"
const REASON_NOT_A_WORD := "not_a_word"
const REASON_GAME_OVER := "game_over"

var grid: HexGrid
var score: int = 0
var words_found: int = 0
var last_word: String = ""
var last_points: int = 0
var is_over: bool = false
var is_paused: bool = false
## Schwierigkeitsstufe dieser Runde (1..5).
var difficulty: int = 3

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
	_spawner = Spawner.new(balance, _picker, rng_cells)
	difficulty = difficulty_level if difficulty_level > 0 else balance.default_difficulty
	if common_words != null:
		_spawner.finder = WordFinder.new(common_words, balance.min_word_length, balance.help_max_word_length)
		_spawner.difficulty = balance.difficulty(difficulty)
	grid = HexGrid.new(balance.grid_cols, balance.grid_rows)


# --- Rundenablauf ----------------------------------------------------------------

## Neue Runde: Feld leeren und die Startreihen füllen.
func start() -> void:
	grid.clear_all()
	score = 0
	words_found = 0
	last_word = ""
	last_points = 0
	is_over = false
	is_paused = false
	_level = 1
	for i in _balance.start_rows * _balance.grid_cols:
		_spawn_one()
	score_changed.emit(score)
	level_changed.emit(_level)


## Spielzeit weiterzählen; setzt fällige neue Hexagons.
func update(delta: float) -> void:
	if is_over or is_paused:
		return
	var due := _spawner.tick(delta)
	var new_level := _spawner.level()
	if new_level != _level:
		_level = new_level
		level_changed.emit(_level)
	for i in due:
		if not _spawn_one():
			return


## Anhalten (App im Hintergrund, Nachfrage „Runde beenden?“).
func pause() -> void:
	is_paused = true


func resume() -> void:
	is_paused = false


## Runde vorzeitig beenden (Menü-Knopf → „Ja“). Löst kein game_over aus.
func abort() -> void:
	is_over = true


func level() -> int:
	return _level


func elapsed() -> float:
	return _spawner.elapsed


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
		word_rejected.emit(path, REASON_GAME_OVER)
		return false
	if not _is_valid_path(path):
		word_rejected.emit(path, REASON_INVALID_PATH)
		return false
	if path.size() < _balance.min_word_length:
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
	return true


# --- intern ----------------------------------------------------------------------

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


## Ein neues Hexagon setzen. Gibt false zurück, wenn das Spiel dadurch endet.
func _spawn_one() -> bool:
	var r := _spawner.spawn_into(grid)
	if r.is_empty():
		_end()
		return false
	tile_spawned.emit(r["cell"], r["letter"])
	if grid.is_full():
		_end()
		return false
	return true


func _end() -> void:
	if is_over:
		return
	is_over = true
	game_over.emit(score)
