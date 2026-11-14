class_name RunSession
extends RefCounted
## Ein Lauf im Lauf-Modus (Roguelike, siehe spec/run-mode.md). Reine Logik, ohne Zeit.
##
## Ablauf: start() → Auftrag für Level 1 (quest_started) → Wörter mit submit_path(cells) →
## jedes passende Wort füllt eine Block-Zeile → alle gefüllt: Münzen, Level +1, nächster
## Auftrag automatisch … bis give_up().
## Hilfen: refill(), swap(), clear_useless(), hint(), replace(cell).

## Ein neues Hexagon ist erschienen.
signal tile_spawned(cell: Vector2i, letter: String)
## Ein vorhandenes Hexagon hat einen neuen Buchstaben bekommen (Tauschen, Ersetzen).
signal tile_changed(cell: Vector2i, letter: String)
## Aufräumen: diese Steine sind entfernt (die Plätze bleiben frei).
signal tiles_removed(cells: Array[Vector2i])
## Tipp: die bisher gezeigten Steine eines passenden Worts, in Wortreihenfolge
## (leer = kein Tipp mehr, z. B. weil sich ein Stein des Worts geändert hat).
signal hint_changed(cells: Array[Vector2i])
## Ein passendes Wort wurde angenommen; die Hexagons sind entfernt.
## row: die Block-Zeile des Auftrags, die das Wort gefüllt hat.
signal word_accepted(word: String, cells: Array[Vector2i], row: int)
## Gewischte Buchstaben ergeben kein gültiges Wort (oder es ist gerade kein Auftrag aktiv).
signal word_rejected(cells: Array[Vector2i], reason: String)
signal quest_started(quest: Quest)
## Eine Zeile des Auftrags wurde gefüllt.
signal quest_progress(quest: Quest)
signal quest_completed(quest: Quest, reward: int)
signal coins_changed(coins: int)
signal level_changed(level: int)
## Lauf vorbei. reason: REASON_GAVE_UP.
signal run_ended(level: int, reason: String)

const REASON_TOO_SHORT := "too_short"
const REASON_INVALID_PATH := "invalid_path"
const REASON_NOT_A_WORD := "not_a_word"
## Echtes Wort, passt aber in keine freie Zeile (falsche Länge).
const REASON_NOT_MATCHING := "not_matching"
const REASON_NO_QUEST := "no_quest"
const REASON_RUN_OVER := "run_over"

const NO_CELL := Vector2i(-1, -1)

const REASON_GAVE_UP := "gave_up"

var grid: HexGrid
var coins: int = 0
var words_found: int = 0
var is_over: bool = false
## Aktueller Auftrag (kommt automatisch).
var quest: Quest

var _balance: GameBalance
var _lang: LanguageData
var _dictionary: WordDictionary
var _generator: QuestGenerator
var _curve: QuestCurve
var _picker: LetterPicker
## Sucht Wörter für den Tipp: zuerst geläufige, dann alle.
var _hint_finders: Array[WordFinder] = []
var _hint_rng: RandomNumberGenerator
var _planter: WordPlanter
## Woraus schlaues Tauschen seine Wörter nimmt (geläufige Wörter, sonst alle).
var _plant_words: WordDictionary
## Laufender Tipp: Weg und Wort, davon _hint_count Buchstaben gezeigt.
var _hint_cells: Array[Vector2i] = []
var _hint_word: String = ""
var _hint_count: int = 0
var _spawner: Spawner
var _level: int = 1


## seed_value < 0: zufällig; sonst reproduzierbar (für Tests).
## common_words: geläufige Wörter für die Wort-Hilfe (null = keine Hilfe).
func _init(balance: GameBalance, curve: QuestCurve, lang: LanguageData, dictionary: WordDictionary,
		seed_value: int = -1, common_words: WordDictionary = null) -> void:
	_balance = balance
	_lang = lang
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
	_planter = WordPlanter.new(rng_quests)
	_plant_words = common_words if common_words != null else dictionary
	if common_words != null:
		_hint_finders.append(WordFinder.new(common_words))
	_hint_finders.append(WordFinder.new(dictionary))
	if common_words != null:
		_spawner.finder = WordFinder.new(common_words, balance.min_length, balance.help_max_word_length)
	grid = HexGrid.new(balance.grid_cols, balance.grid_rows)


# --- Ablauf des Laufs ---------------------------------------------------------------

## Neuer Lauf: Level 1, Startmünzen, Start-Hexagons, erster Auftrag.
func start() -> void:
	grid.clear_all()
	coins = _balance.start_coins
	words_found = 0
	is_over = false
	quest = null
	_level = 1
	_reset_hint()
	_apply_help()
	_spawn(_balance.run_start_tiles)
	coins_changed.emit(coins)
	level_changed.emit(_level)
	_start_quest()


## Knopf „Aufgeben“ → „Ja“.
func give_up() -> void:
	_end(REASON_GAVE_UP)


func level() -> int:
	return _level


# --- Hilfen ---------------------------------------------------------------------------

## Preis fürs Auffüllen (fest).
func refill_price() -> int:
	return _balance.refill_price


## Auffüllen möglich? (Münzen reichen, Platz frei)
func can_refill() -> bool:
	return not is_over and coins >= refill_price() and grid.free_count() > 0


## Hilfe „Auffüllen“: einige neue Hexagons gegen Münzen. Gibt die Anzahl neuer Hexagons zurück.
func refill() -> int:
	if not can_refill():
		return 0
	var price := refill_price()
	var placed := _spawn(_balance.refill_count)
	_pay(price)
	return placed


## Tauschen möglich? (Münzen reichen, Steine im Feld). Auch bei vollem Feld.
func can_swap() -> bool:
	return not is_over and coins >= _balance.swap_price and grid.free_count() < grid.size()


## Hilfe „Tauschen“: einige zufällige Steine bekommen neue Buchstaben (Wort-Hilfe).
## Steckt man fest (kein geläufiges passendes Wort im Feld), legt es zuerst ein passendes
## Wort über eine Kette vorhandener Steine (siehe WordPlanter). Gibt die getauschten Plätze zurück.
func swap() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if not can_swap():
		return cells
	var changed: Array[Vector2i] = []
	var keep := {}
	if is_stuck():
		var plan := _planter.plant(grid, _plant_words, quest.free_lengths(), _balance.swap_count)
		if not plan.is_empty():
			var path: Array[Vector2i] = []
			path.assign(plan["path"])
			var word: String = plan["word"]
			for i in path.size():
				keep[path[i]] = true
				if grid.get_letter(path[i]) != word[i]:
					grid.set_letter(path[i], word[i])
					changed.append(path[i])
					tile_changed.emit(path[i], word[i])
	for cell in grid.all_cells():
		if grid.is_occupied(cell) and not keep.has(cell):
			cells.append(cell)
	for i in range(cells.size() - 1, 0, -1):
		var j := _hint_rng.randi_range(0, i)
		var t := cells[i]
		cells[i] = cells[j]
		cells[j] = t
	cells.resize(clampi(_balance.swap_count - changed.size(), 0, cells.size()))
	for cell in cells:
		tile_changed.emit(cell, _new_letter(cell))
	_pay(_balance.swap_price)
	_check_hint()
	return changed + cells


## Steckt man fest? Kein geläufiges Wort im Feld passt in eine freie Zeile.
func is_stuck() -> bool:
	if quest == null:
		return false
	var lengths := quest.free_lengths()
	if lengths.is_empty():
		return false
	var q := quest
	var finder: WordFinder = _hint_finders[0]
	return finder.find_paths(grid, lengths[0], lengths[lengths.size() - 1],
			func(w: String) -> bool: return q.matches(w), 1).is_empty()


## Aufräumen möglich? (Auftrag aktiv, Münzen reichen)
func can_clear() -> bool:
	return not is_over and quest != null and coins >= _balance.clear_price


## Das Wort, das Aufräumen stehen lässt: der Weg eines geläufigen Worts, das in eine freie
## Zeile passt (bevorzugt das blinkende Tipp-Wort). Leer, wenn es keines gibt.
func protected_word() -> Array[Vector2i]:
	if _hint_valid():
		return _hint_cells.duplicate()
	var none: Array[Vector2i] = []
	if quest == null:
		return none
	var lengths := quest.free_lengths()
	if lengths.is_empty():
		return none
	var q := quest
	var found := (_hint_finders[0] as WordFinder).find_paths(grid, lengths[0], lengths[lengths.size() - 1],
			func(w: String) -> bool: return q.matches(w))
	if found.is_empty():
		return none
	var path: Array[Vector2i] = []
	path.assign(found[_hint_rng.randi_range(0, found.size() - 1)]["path"])
	return path


## Steine, die Aufräumen entfernen darf, vom am wenigsten hilfreichen zum hilfreichsten:
## zuerst nach der Zahl passender Wörter (Längen der freien Zeilen, geläufige Wörter), die durch
## den Stein führen, bei Gleichstand die seltensten Buchstaben zuerst. Die Steine von `keep`
## (geschütztes Wort) und blinkende Tipp-Steine sind ausgenommen.
func clear_candidates(keep: Array[Vector2i] = []) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if quest == null:
		return cells
	var hinted := hinted_cells()
	var uses := {}
	for cell in grid.all_cells():
		if grid.is_occupied(cell) and not hinted.has(cell) and not keep.has(cell):
			cells.append(cell)
			uses[cell] = 0
	var lengths := quest.free_lengths()
	if not lengths.is_empty():
		var q := quest
		var finder: WordFinder = _hint_finders[0]
		for hit in finder.find_paths(grid, lengths[0], lengths[lengths.size() - 1],
				func(w: String) -> bool: return q.matches(w), 1000000):
			for cell in hit["path"]:
				if uses.has(cell):
					uses[cell] += 1
	var key := {}
	for cell in cells:
		# Zufall nur als Gleichstands-Brecher bei gleich seltenen Buchstaben.
		key[cell] = uses[cell] * 1000.0 + _letter_weight(grid.get_letter(cell)) + _hint_rng.randf() * 0.0001
	cells.sort_custom(func(x: Vector2i, y: Vector2i) -> bool: return key[x] < key[y])
	return cells


## Hilfe „Aufräumen“: bis zu clear_count der am wenigsten hilfreichen Steine entfernen, aber nur
## so, dass danach noch ein passendes geläufiges Wort im Feld liegt (dessen Steine bleiben).
## Liegt kein solches Wort im Feld, wird nichts entfernt (kostet nichts).
## Gibt die entfernten Plätze zurück.
func clear_useless() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if not can_clear():
		return cells
	var keep := protected_word()
	if keep.is_empty():
		return cells
	cells = clear_candidates(keep)
	cells.resize(mini(cells.size(), _balance.clear_count))
	if cells.is_empty():
		return cells
	for cell in cells:
		grid.clear(cell)
	_pay(_balance.clear_price)
	tiles_removed.emit(cells)
	_check_hint()
	return cells


func _letter_weight(letter: String) -> float:
	var i := _lang.alphabet.find(letter)
	return _lang.weights[i] if i >= 0 else 0.0


## Tipp möglich? (Auftrag aktiv, Münzen reichen, noch nicht alle Buchstaben gezeigt)
func can_hint() -> bool:
	if is_over or quest == null or coins < _balance.hint_price:
		return false
	return not (_hint_valid() and _hint_count >= _hint_cells.size())


## Hilfe „Tipp“: zeigt den nächsten Buchstaben eines Worts, das in eine freie Zeile passt
## (beim ersten Tipp den ersten). Alle gezeigten bleiben sichtbar (hint_changed).
## Gibt den neu gezeigten Platz zurück, oder NO_CELL, wenn kein passendes Wort im Feld
## liegt (dann kostet es nichts).
func hint() -> Vector2i:
	if not can_hint():
		return NO_CELL
	_check_hint()
	if _hint_cells.is_empty():
		var path := _find_matching_path()
		if path.is_empty():
			return NO_CELL
		_hint_cells = path
		_hint_word = word_for(path)
		_hint_count = 0
	_hint_count += 1
	_pay(_balance.hint_price)
	hint_changed.emit(hinted_cells())
	return _hint_cells[_hint_count - 1]


## Bisher gezeigte Tipp-Steine (in Wortreihenfolge).
func hinted_cells() -> Array[Vector2i]:
	return _hint_cells.slice(0, _hint_count)


## Lösung für den laufenden Auftrag (z. B. beim Aufgeben): Weg eines Worts, das in eine
## freie Zeile passt,
## bevorzugt das Tipp-Wort. Leer, wenn es keine gibt.
func solution() -> Array[Vector2i]:
	if _hint_valid():
		return _hint_cells.duplicate()
	if quest == null:
		return []
	return _find_matching_path()


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
	var letter := _new_letter(cell)
	_pay(_balance.replace_price)
	tile_changed.emit(cell, letter)
	_check_hint()
	return letter


## Neuer Buchstabe für einen belegten Platz (Wort-Hilfe, immer ein anderer als vorher).
func _new_letter(cell: Vector2i) -> String:
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
	var row := quest.free_row_for(word)
	for cell in path:
		grid.clear(cell)
	words_found += 1
	quest.fill(row, word)
	_aim_help()
	word_accepted.emit(word, path, row)
	# Automatisch auffüllen: eine Wortlänge minus eins.
	_spawn(maxi(word.length() - _balance.auto_refill_less, 0))
	_check_hint()
	quest_progress.emit(quest)
	if quest.is_done():
		_complete_quest()
	return true


# --- intern --------------------------------------------------------------------------

## Liegt das Tipp-Wort noch unverändert im Feld, und passt es noch in eine freie Zeile?
func _hint_valid() -> bool:
	if _hint_cells.is_empty() or quest == null or not quest.matches(_hint_word):
		return false
	for cell in _hint_cells:
		if grid.is_free(cell):
			return false
	return word_for(_hint_cells) == _hint_word


## Tipp verwerfen, wenn sich ein Stein des Tipp-Worts geändert hat.
func _check_hint() -> void:
	if not _hint_cells.is_empty() and not _hint_valid():
		_reset_hint()


func _reset_hint() -> void:
	var had := _hint_count > 0
	_hint_cells = []
	_hint_word = ""
	_hint_count = 0
	if had:
		hint_changed.emit(hinted_cells())


## Weg eines Worts, das in eine freie Zeile passt (zufällig unter den gefundenen), oder leer.
func _find_matching_path() -> Array[Vector2i]:
	var q := quest
	var lengths := q.free_lengths()
	if lengths.is_empty():
		return []
	var p_min := lengths[0]
	var p_max := lengths[lengths.size() - 1]
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
	var word := word_for(path)
	if not _dictionary.contains(word):
		return REASON_NOT_A_WORD
	if not quest.matches(word):
		return REASON_NOT_MATCHING
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
	_start_quest()


## Auftrag für das aktuelle Level erzeugen und starten.
func _start_quest() -> void:
	_reset_hint()
	quest = _generator.quest_for(_level).start()
	_aim_help()
	quest_started.emit(quest)


func _end(reason: String) -> void:
	if is_over:
		return
	is_over = true
	run_ended.emit(_level, reason)


func _pay(amount: int) -> void:
	coins = maxi(coins - amount, 0)
	coins_changed.emit(coins)


## Wort-Hilfe auf den Auftrag ausrichten: nur Wörter in den Längen der freien Zeilen zählen
## (z. B. ▢▢▢▢▢ → nur Wörter mit 5 Buchstaben). Siehe spec/game-rules.md, „Wort-Hilfe“.
func _aim_help() -> void:
	var f := _spawner.finder
	if f == null or quest == null:
		return
	var lengths := quest.free_lengths()
	if lengths.is_empty():
		return
	f.only_lengths = lengths
	f.min_length = lengths[0]
	f.max_length = mini(lengths[lengths.size() - 1], _balance.help_max_word_length)


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
