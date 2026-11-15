class_name RunSession
extends RefCounted
## Ein Lauf im Lauf-Modus (Roguelike, siehe spec/run-mode.md). Reine Logik, ohne Zeit.
##
## Ablauf: start() → Auftrag für Level 1 (quest_started) → Wörter mit submit_path(cells) →
## jedes passende Wort füllt eine Block-Zeile → alle gefüllt: Münzen, Level +1, nächster
## Auftrag automatisch … bis give_up().
## Hilfen: refill(), swap(), clear_useless(), hint(), replace(cell), solve(), joker(), shuffle(), magnet(cell), shorten(), split(), strike(), scan(), complete(prefix).

## Ein neues Hexagon ist erschienen.
signal tile_spawned(cell: Vector2i, letter: String)
## Ein vorhandenes Hexagon hat einen neuen Buchstaben bekommen (Tauschen, Ersetzen).
signal tile_changed(cell: Vector2i, letter: String)
## Lösen: eine Zeile wurde ohne Wort aus dem Feld gefüllt (Buchstaben erscheinen direkt).
signal row_filled(row: int, word: String)
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
## Die Zeilen des laufenden Auftrags haben sich geändert (Hilfe „Teilen“).
signal quest_reshaped(quest: Quest)
## Scan: diese Steine gehören zu einem passenden Wort.
signal scan_shown(cells: Array[Vector2i])
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
## Buchstabe eines Joker-Steins im Raster (steht beim Wischen für jeden Buchstaben).
const JOKER := "*"

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


## Liegt im Feld ein gültiges Wort (ganzes Wörterbuch), das genau in eine freie Zeile passt?
## Ein Joker im Feld zählt als „vielleicht“ (true), damit nichts fälschlich als ausweglos gilt.
func has_fitting_word() -> bool:
	if quest == null:
		return false
	var lengths := quest.free_lengths()
	if lengths.is_empty():
		return false
	for cell in grid.all_cells():
		if grid.is_occupied(cell) and grid.get_letter(cell) == JOKER:
			return true
	var q := quest
	var finder: WordFinder = _hint_finders[_hint_finders.size() - 1]
	return not finder.find_paths(grid, lengths[0], lengths[lengths.size() - 1],
			func(w: String) -> bool: return q.matches(w), 1).is_empty()


## Soll der Auffüllen-Knopf pulsieren? Kein gültiges passendes Wort im Feld und Auffüllen möglich.
func refill_suggested() -> bool:
	if quest == null or quest.is_done() or not can_refill():
		return false
	return not has_fitting_word()


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


## Wie viele Steine Aufräumen höchstens entfernen darf: clear_count, und es bleiben immer so viele
## Steine liegen, wie alle freien Zeilen zusammen Blöcke haben (z. B. 4 + 5 → mindestens 9).
func clear_amount() -> int:
	if quest == null:
		return 0
	var blocks := 0
	for i in quest.rows.size():
		if quest.filled[i] == "":
			blocks += quest.rows[i]
	var tiles := grid.size() - grid.free_count()
	return clampi(tiles - blocks, 0, _balance.clear_count)


## Hilfe „Aufräumen“: bis zu clear_amount() der am wenigsten hilfreichen Steine entfernen, aber nur
## so, dass danach noch ein passendes geläufiges Wort im Feld liegt (dessen Steine bleiben).
## Liegt kein solches Wort im Feld, wird nichts entfernt (kostet nichts).
## Gibt die entfernten Plätze zurück.
func clear_useless() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if not can_clear():
		return cells
	var amount := clear_amount()
	if amount <= 0:
		return cells
	var keep := protected_word()
	if keep.is_empty():
		return cells
	cells = clear_candidates(keep)
	cells.resize(mini(cells.size(), amount))
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


## Lösen möglich? (Auftrag aktiv, Münzen reichen)
func can_solve() -> bool:
	return not is_over and quest != null and coins >= _balance.solve_price


## Hilfe „Lösen“: den ganzen Auftrag lösen, ohne Belohnung. Für jede freie Zeile wird ein
## passendes geläufiges Wort aus dem Feld genommen (Steine verschwinden, automatisches
## Auffüllen wie gewohnt); fehlt eines, wird die Zeile mit einem zufälligen Wort gefüllt.
## Gibt true zurück, wenn gelöst wurde.
func solve() -> bool:
	if not can_solve():
		return false
	_pay(_balance.solve_price)
	_reset_hint()
	for row in quest.rows.size():
		if quest.filled[row] != "":
			continue
		var n := quest.rows[row]
		var path := _find_word_of_length(n)
		if path.is_empty():
			var word := _random_word(n)
			quest.fill(row, word)
			row_filled.emit(row, word)
		else:
			var word := word_for(path)
			for cell in path:
				grid.clear(cell)
			words_found += 1
			quest.fill(row, word)
			word_accepted.emit(word, path, row)
			_spawn(maxi(n - _balance.auto_refill_less, 0))
		quest_progress.emit(quest)
	_complete_quest(false)
	return true


## Weg eines Worts mit genau n Buchstaben im Feld (zuerst geläufige Wörter), oder leer.
func _find_word_of_length(n: int) -> Array[Vector2i]:
	for finder in _hint_finders:
		var found := finder.find_paths(grid, n, n, func(w: String) -> bool: return w.length() == n)
		if not found.is_empty():
			var path: Array[Vector2i] = []
			path.assign(found[_hint_rng.randi_range(0, found.size() - 1)]["path"])
			return path
	return []


## Zufälliges geläufiges Wort mit n Buchstaben (für Zeilen ohne passendes Wort im Feld).
func _random_word(n: int) -> String:
	var count := _plant_words.count_of_length(n)
	if count == 0:
		return "?".repeat(n)
	return _plant_words.word_at(n, _hint_rng.randi_range(0, count - 1))


## Joker möglich? (Auftrag aktiv, Münzen reichen, ein normaler Stein liegt im Feld)
func can_joker() -> bool:
	if is_over or quest == null or coins < _balance.joker_price:
		return false
	for cell in grid.all_cells():
		if grid.is_occupied(cell) and grid.get_letter(cell) != JOKER:
			return true
	return false


## Hilfe „Joker“: ein zufälliger Stein wird zum Joker. Gibt den Platz zurück (NO_CELL = nicht möglich).
func joker() -> Vector2i:
	if not can_joker():
		return NO_CELL
	var cells: Array[Vector2i] = []
	for cell in grid.all_cells():
		if grid.is_occupied(cell) and grid.get_letter(cell) != JOKER:
			cells.append(cell)
	var cell := cells[_hint_rng.randi_range(0, cells.size() - 1)]
	grid.set_letter(cell, JOKER)
	_pay(_balance.joker_price)
	tile_changed.emit(cell, JOKER)
	_check_hint()
	return cell


## Mischen möglich? (Münzen reichen, mindestens zwei Steine)
func can_shuffle() -> bool:
	return not is_over and coins >= _balance.shuffle_price and grid.size() - grid.free_count() >= 2


## Hilfe „Mischen“: die Buchstaben aller Steine werden zufällig auf die belegten Plätze verteilt.
## Gibt die Plätze zurück, deren Buchstabe sich geändert hat.
func shuffle() -> Array[Vector2i]:
	var changed: Array[Vector2i] = []
	if not can_shuffle():
		return changed
	var cells: Array[Vector2i] = []
	var letters: Array[String] = []
	for cell in grid.all_cells():
		if grid.is_occupied(cell):
			cells.append(cell)
			letters.append(grid.get_letter(cell))
	for i in range(letters.size() - 1, 0, -1):
		var j := _hint_rng.randi_range(0, i)
		var t := letters[i]
		letters[i] = letters[j]
		letters[j] = t
	for i in cells.size():
		if grid.get_letter(cells[i]) != letters[i]:
			grid.set_letter(cells[i], letters[i])
			changed.append(cells[i])
			tile_changed.emit(cells[i], letters[i])
	_pay(_balance.shuffle_price)
	_check_hint()
	return changed


## Magnet möglich? (Auftrag aktiv, Münzen reichen; mit Platz: dieser Stein liegt im Feld)
func can_magnet(cell: Vector2i = NO_CELL) -> bool:
	if is_over or quest == null or coins < _balance.magnet_price:
		return false
	return cell == NO_CELL or grid.is_occupied(cell)


## Hilfe „Magnet“: um den angetippten Stein entsteht ein passendes geläufiges Wort (der Stein
## behält seinen Buchstaben, die übrigen Steine der Kette verwandeln sich).
## Gibt die geänderten Plätze zurück (leer = nicht möglich, kostet nichts).
func magnet(cell: Vector2i) -> Array[Vector2i]:
	var changed: Array[Vector2i] = []
	if not can_magnet(cell):
		return changed
	var letter := grid.get_letter(cell)
	var plan := _planter.plant_around(grid, _plant_words, quest.free_lengths(), cell,
			"" if letter == JOKER else letter)
	if plan.is_empty():
		return changed
	var path: Array[Vector2i] = []
	path.assign(plan["path"])
	var word: String = plan["word"]
	for i in path.size():
		if grid.get_letter(path[i]) != word[i]:
			grid.set_letter(path[i], word[i])
			changed.append(path[i])
			tile_changed.emit(path[i], word[i])
	_pay(_balance.magnet_price)
	_check_hint()
	return changed


## Teilen möglich? (Münzen reichen, es gibt eine freie Zeile mit mindestens split_min_length Blöcken)
func can_split() -> bool:
	return not is_over and coins >= _balance.split_price and _split_row() >= 0


## Hilfe „Teilen“: die längste freie Zeile (ab split_min_length) wird halbiert.
## Gibt true zurück, wenn geteilt wurde (sonst kostet es nichts).
func split() -> bool:
	if not can_split():
		return false
	quest.split_row(_split_row())
	_pay(_balance.split_price)
	_aim_help()
	_check_hint()
	quest_reshaped.emit(quest)
	return true


func _split_row() -> int:
	if quest == null:
		return -1
	var best := -1
	for i in quest.rows.size():
		if quest.filled[i] == "" and quest.rows[i] >= _balance.split_min_length:
			if best < 0 or quest.rows[i] > quest.rows[best]:
				best = i
	return best


## Kürzen möglich? (Münzen reichen, es gibt eine freie Zeile, die länger als min_length ist)
func can_shorten() -> bool:
	return not is_over and coins >= _balance.shorten_price and _shorten_row() >= 0


## Hilfe „Kürzen“: die längste freie Zeile (bei Gleichstand die oberste) verliert einen Block.
## Gibt true zurück, wenn gekürzt wurde (sonst kostet es nichts).
func shorten() -> bool:
	if not can_shorten():
		return false
	quest.shorten_row(_shorten_row())
	_pay(_balance.shorten_price)
	_aim_help()
	_check_hint()
	quest_reshaped.emit(quest)
	return true


func _shorten_row() -> int:
	if quest == null:
		return -1
	var best := -1
	for i in quest.rows.size():
		if quest.filled[i] == "" and quest.rows[i] > _balance.min_length:
			if best < 0 or quest.rows[i] > quest.rows[best]:
				best = i
	return best


## Zeile streichen möglich? (Münzen reichen, mindestens 2 Zeilen frei)
func can_strike() -> bool:
	return not is_over and quest != null and coins >= _balance.strike_price \
			and _free_row_count() >= 2


## Hilfe „Zeile streichen“: die freie Zeile mit den meisten Blöcken (bei Gleichstand die oberste)
## fällt weg. Nur bei mindestens 2 freien Zeilen (sonst wäre es ein billiges Lösen).
## Gibt true zurück, wenn gestrichen wurde (sonst kostet es nichts).
func strike() -> bool:
	if not can_strike():
		return false
	var best := -1
	for i in quest.rows.size():
		if quest.filled[i] == "" and (best < 0 or quest.rows[i] > quest.rows[best]):
			best = i
	quest.remove_row(best)
	_pay(_balance.strike_price)
	_aim_help()
	_check_hint()
	quest_reshaped.emit(quest)
	return true


func _free_row_count() -> int:
	var n := 0
	for i in quest.rows.size():
		if quest.filled[i] == "":
			n += 1
	return n


## Scan möglich? (Auftrag aktiv, Münzen reichen)
func can_scan() -> bool:
	return not is_over and quest != null and coins >= _balance.scan_price


## Hilfe „Scan“: die Steine **eines** geläufigen Worts für die längste freie Zeile (gibt es dafür
## keines, für die nächstkürzere). Gibt sie zurück (leer = keines im Feld, kostet nichts).
## Danach tippt „Tipp“ dasselbe Wort. Läuft schon ein Tipp mit einem Wort dieser Länge,
## zeigt Scan dieses Wort.
func scan() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if not can_scan():
		return cells
	_check_hint()
	var lengths := quest.free_lengths()
	for k in range(lengths.size() - 1, -1, -1):
		var n := lengths[k]
		if _hint_valid() and _hint_word.length() == n:
			cells = _hint_cells.duplicate()
			break
		var found := (_hint_finders[0] as WordFinder).find_paths(grid, n, n,
				func(w: String) -> bool: return w.length() == n)
		if not found.is_empty():
			cells.assign(found[_hint_rng.randi_range(0, found.size() - 1)]["path"])
			break
	if cells.is_empty():
		return cells
	_adopt_hint(cells)
	_pay(_balance.scan_price)
	scan_shown.emit(cells)
	return cells


## Vervollständigen möglich? (Auftrag aktiv, Münzen reichen)
func can_complete() -> bool:
	return not is_over and quest != null and coins >= _balance.complete_price


## Hilfe „Vervollständigen“: zum angewischten Wortanfang (mindestens complete_min_prefix Steine)
## ein Wort suchen, das mit genau diesen Steinen beginnt, länger ist und genau in eine freie
## Zeile passt (zuerst geläufige Wörter, dann alle). Gibt den ganzen Weg zurück; er leuchtet wie
## beim Scan, und Tipp zeigt danach dasselbe Wort. Leer = keines (kostet nichts).
func complete(prefix: Array[Vector2i]) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if not can_complete() or prefix.size() < _balance.complete_min_prefix:
		return cells
	_check_hint()
	var lengths := quest.free_lengths()
	var p_min := maxi(prefix.size() + 1, lengths[0])
	var p_max := lengths[lengths.size() - 1]
	if p_min > p_max:
		return cells
	var q := quest
	for finder in _hint_finders:
		var found := finder.find_paths_from(grid, prefix, p_min, p_max,
				func(w: String) -> bool: return q.matches(w))
		if not found.is_empty():
			cells.assign(found[_hint_rng.randi_range(0, found.size() - 1)]["path"])
			break
	if cells.is_empty():
		return cells
	_adopt_hint(cells)
	_pay(_balance.complete_price)
	scan_shown.emit(cells)
	return cells


## Dieses Wort wird zum Tipp-Wort (Tipp zeigt es danach Buchstabe für Buchstabe).
func _adopt_hint(cells: Array[Vector2i]) -> void:
	if cells == _hint_cells:
		return
	_reset_hint()
	_hint_cells = cells.duplicate()
	_hint_word = word_for(cells)
	_hint_count = 0


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
	var word := _resolved_word(path)
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
	var raw := word_for(path)
	if raw.contains(JOKER):
		if _resolve_joker(raw, false) == "":
			return REASON_NOT_A_WORD
		if _resolve_joker(raw, true) == "":
			return REASON_NOT_MATCHING
		return ""
	if not _dictionary.contains(raw):
		return REASON_NOT_A_WORD
	if not quest.matches(raw):
		return REASON_NOT_MATCHING
	return ""


## Wort eines Wegs; Joker werden durch passende Buchstaben ersetzt.
func _resolved_word(path: Array[Vector2i]) -> String:
	var raw := word_for(path)
	return _resolve_joker(raw, true) if raw.contains(JOKER) else raw


## Joker in `raw` so ersetzen, dass ein gültiges Wort entsteht (bei must_fit: das auch in eine
## freie Zeile passt). Geläufige Wörter zuerst. Leer, wenn keine Belegung passt.
func _resolve_joker(raw: String, must_fit: bool) -> String:
	if must_fit and quest != null and not quest.free_lengths().has(raw.length()):
		return ""
	var dicts: Array[WordDictionary] = []
	if _plant_words != _dictionary:
		dicts.append(_plant_words)
	dicts.append(_dictionary)
	for d in dicts:
		var w := _fill_joker(raw, d)
		if w != "" and _dictionary.contains(w):
			return w
	return ""


func _fill_joker(raw: String, d: WordDictionary) -> String:
	var i := raw.find(JOKER)
	if i < 0:
		return raw if d.contains(raw) else ""
	for letter in _lang.alphabet:
		var candidate := raw.substr(0, i) + letter + raw.substr(i + 1)
		var prefix := candidate.substr(0, i + 1)
		if not d.has_prefix(prefix):
			continue
		var w := _fill_joker(candidate, d)
		if w != "":
			return w
	return ""


## rewarded = false: ohne Belohnung (Hilfe „Lösen“).
func _complete_quest(rewarded: bool = true) -> void:
	var done := quest
	quest = null
	var reward := done.reward if rewarded else 0
	coins += reward
	quest_completed.emit(done, reward)
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
