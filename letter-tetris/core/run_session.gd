class_name RunSession
extends RefCounted
## Ein Lauf im Lauf-Modus (Roguelike, siehe spec/run-mode.md). Reine Logik, ohne Zeit.
##
## Ablauf: start() → quest_offered → choose_quest(i) → Wörter mit submit_path(cells) →
## Auftrag erfüllt: Münzen, Level +1, neue Karten … bis give_up() oder Zuglimit verfehlt.
## Hilfen: refill(), hint(), replace(cell).

## Ein neues Hexagon ist erschienen.
signal tile_spawned(cell: Vector2i, letter: String)
## Ein vorhandenes Hexagon hat einen neuen Buchstaben bekommen (Ersetzen, Säen).
signal tile_changed(cell: Vector2i, letter: String)
## Tipp: der erste Stein eines passenden Worts.
signal hint_shown(cell: Vector2i)
## Ein gültiges Wort wurde angenommen; die Hexagons sind entfernt.
## counted: hat das Wort für den Auftrag gezählt?
signal word_accepted(word: String, cells: Array[Vector2i], counted: bool)
## Gewischte Buchstaben ergeben kein gültiges Wort (oder es ist gerade kein Auftrag aktiv).
signal word_rejected(cells: Array[Vector2i], reason: String)
## Zwei Auftragskarten zur Wahl: [sicher, riskant].
signal quest_offered(cards: Array[Quest])
signal quest_started(quest: Quest)
## Fortschritt oder Züge des Auftrags haben sich geändert.
signal quest_progress(quest: Quest)
signal quest_completed(quest: Quest, reward: int)
signal coins_changed(coins: int)
signal level_changed(level: int)
## Lauf vorbei. reason: REASON_GAVE_UP oder REASON_OUT_OF_MOVES.
signal run_ended(level: int, reason: String)

const REASON_TOO_SHORT := "too_short"
const REASON_INVALID_PATH := "invalid_path"
const REASON_NOT_A_WORD := "not_a_word"
const REASON_NO_QUEST := "no_quest"
const REASON_RUN_OVER := "run_over"

const NO_CELL := Vector2i(-1, -1)

const REASON_GAVE_UP := "gave_up"
const REASON_OUT_OF_MOVES := "out_of_moves"

var grid: HexGrid
var coins: int = 0
var words_found: int = 0
var is_over: bool = false
## Aktueller Auftrag; null, solange die Karten zur Wahl stehen.
var quest: Quest
## Angebotene Karten (leer, sobald gewählt).
var offer: Array[Quest] = []

var _balance: GameBalance
var _dictionary: WordDictionary
var _generator: QuestGenerator
var _curve: QuestCurve
var _picker: LetterPicker
## Sucht Wörter für den Tipp: zuerst geläufige, dann alle.
var _hint_finders: Array[WordFinder] = []
var _hint_rng: RandomNumberGenerator
var _seeder: WordSeeder
## Woraus Zielwörter gezogen werden (geläufige Wörter, sonst alle).
var _target_words: WordDictionary
var _spawner: Spawner
var _level: int = 1


## seed_value < 0: zufällig; sonst reproduzierbar (für Tests).
## common_words: geläufige Wörter für die Wort-Hilfe (null = keine Hilfe).
func _init(balance: GameBalance, curve: QuestCurve, lang: LanguageData, dictionary: WordDictionary,
		seed_value: int = -1, common_words: WordDictionary = null) -> void:
	_balance = balance
	_curve = curve
	_dictionary = dictionary
	var rng_letters := RandomNumberGenerator.new()
	var rng_cells := RandomNumberGenerator.new()
	var rng_quests := RandomNumberGenerator.new()
	if seed_value >= 0:
		rng_letters.seed = seed_value
		rng_cells.seed = seed_value + 7919
		rng_quests.seed = seed_value + 104729
	else:
		rng_letters.randomize()
		rng_cells.randomize()
		rng_quests.randomize()
	_picker = LetterPicker.new(lang, rng_letters)
	_spawner = Spawner.new(_picker, rng_cells)
	_generator = QuestGenerator.new(curve, rng_quests)
	_hint_rng = rng_cells
	_seeder = WordSeeder.new(rng_quests)
	_target_words = common_words if common_words != null else dictionary
	if common_words != null:
		_hint_finders.append(WordFinder.new(common_words))
	_hint_finders.append(WordFinder.new(dictionary))
	if common_words != null:
		_spawner.finder = WordFinder.new(common_words, balance.min_length, balance.help_max_word_length)
	grid = HexGrid.new(balance.grid_cols, balance.grid_rows)


# --- Ablauf des Laufs ---------------------------------------------------------------

## Neuer Lauf: Level 1, Startmünzen, Start-Hexagons, erste Karten.
func start() -> void:
	grid.clear_all()
	coins = _balance.start_coins
	words_found = 0
	is_over = false
	quest = null
	_level = 1
	_apply_help()
	_spawn(_balance.run_start_tiles)
	coins_changed.emit(coins)
	level_changed.emit(_level)
	_offer_cards()


## Eine der angebotenen Karten wählen (0 = sicher, 1 = riskant).
func choose_quest(index: int) -> bool:
	if is_over or quest != null or index < 0 or index >= offer.size():
		return false
	var chosen := offer[index]
	var target := ""
	if chosen.kind == Quest.Kind.SPECIFIC_WORD:
		target = _seed_target(chosen.word_length)
		if target == "":
			# Kein Zielwort möglich (sehr selten): stattdessen ein Wort dieser Länge suchen.
			chosen = chosen.duplicate() as Quest
			chosen.kind = Quest.Kind.LENGTH
	quest = chosen.start(target)
	offer.clear()
	quest_started.emit(quest)
	return true


## Knopf „Aufgeben“ → „Ja“.
func give_up() -> void:
	_end(REASON_GAVE_UP)


func level() -> int:
	return _level


# --- Hilfen ---------------------------------------------------------------------------

## Nachfüllen möglich? (Münzen reichen, Platz frei, Auftrag erlaubt es)
func can_refill() -> bool:
	return (not is_over and coins >= _balance.refill_price and grid.free_count() > 0
			and not (quest != null and quest.no_refill))


## Hilfe „Nachfüllen“: einige neue Hexagons gegen Münzen. Gibt die Anzahl neuer Hexagons zurück.
func refill() -> int:
	if not can_refill():
		return 0
	var placed := _spawn(_balance.refill_count)
	_pay(_balance.refill_price)
	return placed


## Tipp möglich? (Auftrag aktiv, Münzen reichen)
func can_hint() -> bool:
	return not is_over and quest != null and coins >= _balance.hint_price


## Hilfe „Tipp“: zeigt den ersten Stein eines Worts, das zum Auftrag passt.
## Gibt den Platz zurück, oder NO_CELL, wenn kein passendes Wort im Feld liegt
## (dann kostet es nichts).
func hint() -> Vector2i:
	if not can_hint():
		return NO_CELL
	var path := _hint_path()
	if path.is_empty():
		return NO_CELL
	_pay(_balance.hint_price)
	hint_shown.emit(path[0])
	return path[0]


## Ersetzen möglich? (Münzen reichen; ohne Platz: allgemein, mit Platz: dieser Stein)
func can_replace(cell: Vector2i = NO_CELL) -> bool:
	if is_over or coins < _balance.replace_price:
		return false
	return cell == NO_CELL or grid.is_occupied(cell)


## Hilfe „Stein ersetzen“: der Stein bekommt einen neuen Buchstaben (gewählt von der
## Wort-Hilfe, immer ein anderer als vorher). Gibt den neuen Buchstaben zurück ("" = nicht möglich).
func replace(cell: Vector2i) -> String:
	if not can_replace(cell):
		return ""
	var old := grid.get_letter(cell)
	grid.clear(cell)
	var letter := old
	# Die Wort-Hilfe kann wieder den alten Buchstaben wählen; dann neu ziehen, zuletzt ohne Hilfe.
	for i in 20:
		if i < 10:
			letter = _picker.pick_for_cell(grid, cell, _spawner.finder, _spawner.difficulty)
		else:
			letter = _picker.pick(PackedStringArray())
		if letter != old:
			break
	grid.set_letter(cell, letter)
	_pay(_balance.replace_price)
	tile_changed.emit(cell, letter)
	return letter


# --- Wischen ------------------------------------------------------------------------

## Darf dieser Platz an den bisherigen Weg angehängt werden?
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


## Gewischten Weg einlösen (beim Loslassen). Gibt true zurück, wenn das Wort angenommen wurde.
func submit_path(path: Array[Vector2i]) -> bool:
	var reason := _check_path(path)
	if reason != "":
		word_rejected.emit(path, reason)
		return false
	var word := word_for(path)
	for cell in path:
		grid.clear(cell)
	words_found += 1
	var counted := quest.register(word)
	word_accepted.emit(word, path, counted)
	quest_progress.emit(quest)
	if quest.is_done():
		_complete_quest()
	elif quest.is_failed():
		_end(REASON_OUT_OF_MOVES)
	return true


# --- intern --------------------------------------------------------------------------

## Zielwort wählen und als Kette ins Feld legen. Gibt das Wort zurück ("" = nicht möglich).
func _seed_target(length: int) -> String:
	for attempt in 5:
		var word := _seeder.pick_target(_target_words, _dictionary, length)
		if word == "":
			return ""
		var changes := _seeder.seed(grid, word)
		if changes.is_empty():
			continue
		for ch in changes:
			if ch["new"]:
				tile_spawned.emit(ch["cell"], ch["letter"])
			else:
				tile_changed.emit(ch["cell"], ch["letter"])
		return word
	return ""


## Weg eines Worts, das zum Auftrag passt (zufällig unter den gefundenen), oder leer.
func _hint_path() -> Array[Vector2i]:
	var q := quest
	var p_min := q.word_length
	var p_max := maxi(q.word_length, _balance.help_max_word_length)
	for finder in _hint_finders:
		var found := finder.find_paths(grid, p_min, p_max, func(w: String) -> bool: return q.matches(w))
		if not found.is_empty():
			var pick: Dictionary = found[_hint_rng.randi_range(0, found.size() - 1)]
			var path: Array[Vector2i] = []
			path.assign(pick["path"])
			return path
	return []


func _check_path(path: Array[Vector2i]) -> String:
	if is_over:
		return REASON_RUN_OVER
	if quest == null:
		return REASON_NO_QUEST
	if not _is_valid_path(path):
		return REASON_INVALID_PATH
	if path.size() < _balance.min_length:
		return REASON_TOO_SHORT
	if not _dictionary.contains(word_for(path)):
		return REASON_NOT_A_WORD
	return ""


func _complete_quest() -> void:
	var done := quest
	quest = null
	coins += done.reward
	quest_completed.emit(done, done.reward)
	coins_changed.emit(coins)
	_level += 1
	_apply_help()
	level_changed.emit(_level)
	_offer_cards()


func _offer_cards() -> void:
	offer = _generator.offer(_level)
	quest_offered.emit(offer)


func _end(reason: String) -> void:
	if is_over:
		return
	is_over = true
	run_ended.emit(_level, reason)


func _pay(amount: int) -> void:
	coins = maxi(coins - amount, 0)
	coins_changed.emit(coins)


## Stärke der Wort-Hilfe folgt dem Level (Hilfe-Stufe aus der Kurve).
func _apply_help() -> void:
	if _spawner.finder != null:
		_spawner.difficulty = _balance.difficulty(_curve.help_level(_level))


func _is_valid_path(path: Array[Vector2i]) -> bool:
	if path.is_empty():
		return false
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
