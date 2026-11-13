extends GutTest

var balance: GameBalance
var curve: QuestCurve
var lang: LanguageData
var dict: WordDictionary
var run: RunSession


func before_each() -> void:
	balance = load("res://data/balance.tres") as GameBalance
	curve = load("res://data/quest_curve.tres") as QuestCurve
	lang = load("res://data/languages/de/language.tres") as LanguageData
	dict = WordDictionary.from_words(PackedStringArray([
		"TEE", "AST", "OHR", "HAUS", "BAUM", "MAUS", "STERN", "STERNE"]))
	run = RunSession.new(balance, curve, lang, dict, 42)
	watch_signals(run)


## Feld leeren und eine Spalte von unten nach oben belegen.
func _column(c: int, letters: String, clear: bool = true) -> Array[Vector2i]:
	if clear:
		run.grid.clear_all()
	var cells: Array[Vector2i] = []
	for i in letters.length():
		var cell := Vector2i(c, i)
		run.grid.set_letter(cell, letters[i])
		cells.append(cell)
	return cells


## Eigenen Auftrag mit diesen Zeilen setzen.
func _use_rows(rows: Array, reward: int = 100) -> Quest:
	var q := Quest.new()
	q.rows = PackedInt32Array(rows)
	q.reward = reward
	run.quest = q.start()
	return run.quest


func _occupied() -> int:
	return run.grid.size() - run.grid.free_count()


# --- Start -----------------------------------------------------------------------

func test_start_from_spec() -> void:
	run.start()
	assert_eq(_occupied(), 20)
	assert_eq(run.coins, 0)
	assert_eq(run.level(), 1)
	assert_not_null(run.quest, "Auftrag kommt sofort")
	assert_eq(run.quest.rows, PackedInt32Array([3]))
	assert_signal_emitted(run, "quest_started")
	assert_false(run.is_over)


func test_start_tiles_do_not_float() -> void:
	run.start()
	for cell in run.grid.all_cells():
		if run.grid.is_occupied(cell) and cell.y > 0:
			assert_true(run.grid.is_occupied(Vector2i(cell.x, cell.y - 1)), "schwebt: %s" % cell)


func test_same_seed_same_start() -> void:
	var other := RunSession.new(balance, curve, lang, dict, 42)
	run.start()
	other.start()
	for cell in run.grid.all_cells():
		assert_eq(run.grid.get_letter(cell), other.grid.get_letter(cell))


# --- Wörter und Aufträge -------------------------------------------------------------

func test_word_completes_quest_and_next_comes_automatically() -> void:
	run.start()
	_use_rows([3], 100)
	var cells := _column(0, "AST")
	assert_true(run.submit_path(cells))
	assert_eq(_occupied(), 2, "3 weg, 2 automatisch neu")
	assert_eq(run.coins, 100)
	assert_eq(run.level(), 2)
	assert_not_null(run.quest, "nächster Auftrag sofort da")
	assert_eq(run.quest.rows, PackedInt32Array([4]), "Level 2 laut Kurve")
	assert_signal_emitted(run, "quest_completed")
	assert_signal_emit_count(run, "quest_started", 2)


func test_reward_from_curve() -> void:
	run.start()
	_column(0, "AST")
	run.submit_path(_column(0, "AST", false))
	assert_eq(run.coins, 110, "Level 1: 100 + 10")


func test_word_fills_row_and_reports_it() -> void:
	run.start()
	_use_rows([4, 3])
	var cells := _column(0, "AST")
	assert_true(run.submit_path(cells))
	assert_signal_emitted_with_parameters(run, "word_accepted", ["AST", cells, 1])
	assert_eq(run.quest.filled[1], "AST")
	assert_false(run.quest.is_done())
	assert_eq(run.level(), 1)


func test_mixed_rows_need_all_words() -> void:
	run.start()
	_use_rows([3, 3, 4])
	run.submit_path(_column(0, "AST"))
	run.submit_path(_column(0, "OHR"))
	assert_eq(run.level(), 1)
	run.submit_path(_column(0, "HAUS"))
	assert_eq(run.level(), 2)


func test_wrong_length_rejected_tiles_stay() -> void:
	run.start()
	_use_rows([4])
	var cells := _column(0, "AST")
	assert_false(run.submit_path(cells))
	assert_signal_emitted_with_parameters(run, "word_rejected", [cells, RunSession.REASON_NOT_MATCHING])
	assert_signal_not_emitted(run, "word_accepted")
	assert_eq(run.grid.get_letter(cells[0]), "A", "Steine bleiben liegen")


func test_longer_word_does_not_count() -> void:
	run.start()
	_use_rows([4])
	var cells := _column(0, "STERN")
	assert_false(run.submit_path(cells), "genau 4, nicht mindestens")


func test_full_row_length_rejected() -> void:
	run.start()
	_use_rows([3, 4])
	run.submit_path(_column(0, "AST"))
	var cells := _column(0, "OHR")
	assert_false(run.submit_path(cells), "3er-Zeile schon gefüllt")


func test_field_stays_between_levels() -> void:
	run.start()
	_use_rows([3])
	_column(0, "AST")
	_column(2, "OHR", false)
	run.submit_path(_column(0, "AST", false))
	assert_eq(run.level(), 2)
	assert_eq(run.grid.get_letter(Vector2i(2, 0)), "O", "übrige Steine bleiben liegen")


func test_minimum_length_is_3() -> void:
	run.start()
	_use_rows([3])
	var cells := _column(0, "AS")
	assert_false(run.submit_path(cells))
	assert_signal_emitted_with_parameters(run, "word_rejected", [cells, RunSession.REASON_TOO_SHORT])


func test_unknown_word_rejected() -> void:
	run.start()
	_use_rows([3])
	var cells := _column(0, "XYZ")
	assert_false(run.submit_path(cells))
	assert_signal_emitted_with_parameters(run, "word_rejected", [cells, RunSession.REASON_NOT_A_WORD])
	assert_eq(run.grid.get_letter(cells[0]), "X", "Steine bleiben liegen")


func test_nothing_accepted_after_end() -> void:
	run.start()
	_use_rows([3])
	run.give_up()
	var cells := _column(0, "AST")
	assert_false(run.submit_path(cells))
	assert_signal_emitted_with_parameters(run, "word_rejected", [cells, RunSession.REASON_RUN_OVER])


# --- Aufgeben ----------------------------------------------------------------------

func test_give_up_ends_run_once() -> void:
	run.start()
	run.give_up()
	run.give_up()
	assert_true(run.is_over)
	assert_signal_emit_count(run, "run_ended", 1)
	assert_signal_emitted_with_parameters(run, "run_ended", [1, RunSession.REASON_GAVE_UP])


# --- Nachfüllen ----------------------------------------------------------------------

func test_refill_needs_coins() -> void:
	run.start()
	_use_rows([3])
	assert_false(run.can_refill(), "Start mit 0 Münzen")
	assert_eq(run.refill(), 0)


func test_refill_brings_5_tiles_for_100() -> void:
	run.start()
	_use_rows([3])
	run.coins = 120
	var before := _occupied()
	assert_eq(run.refill(), 5)
	assert_eq(_occupied(), before + 5)
	assert_eq(run.coins, 20)


func test_refill_price_rises_per_purchase() -> void:
	run.start()
	_use_rows([3])
	run.coins = 1000
	assert_eq(run.refill_price(), 100)
	run.refill()
	assert_eq(run.refill_price(), 125)
	run.refill()
	assert_eq(run.refill_price(), 150)
	assert_eq(run.coins, 1000 - 100 - 125)


func test_refill_price_resets_with_new_run() -> void:
	run.start()
	_use_rows([3])
	run.coins = 1000
	run.refill()
	run.start()
	assert_eq(run.refill_price(), 100)


func test_refill_blocked_on_full_board() -> void:
	run.start()
	_use_rows([3])
	run.coins = 500
	for cell in run.grid.all_cells():
		run.grid.set_letter(cell, "E")
	assert_false(run.can_refill())
	assert_eq(run.coins, 500)


func test_refill_partial_when_little_space() -> void:
	run.start()
	_use_rows([3])
	run.coins = 100
	for cell in run.grid.all_cells():
		run.grid.set_letter(cell, "E")
	run.grid.clear(Vector2i(0, 8))
	run.grid.clear(Vector2i(1, 8))
	assert_eq(run.refill(), 2)
	assert_eq(run.coins, 0)


# --- Tipp ------------------------------------------------------------------------------

func test_hint_needs_coins_and_quest() -> void:
	run.start()
	run.give_up()
	run.coins = 500
	assert_false(run.can_hint(), "Lauf vorbei")
	run.start()
	_use_rows([3])
	run.coins = 99
	assert_false(run.can_hint())
	assert_eq(run.hint(), RunSession.NO_CELL)


func test_hint_shows_first_cell_of_matching_word() -> void:
	run.start()
	_use_rows([4])
	var cells := _column(0, "HAUS")
	_column(2, "AST", false)
	run.coins = 150
	var cell := run.hint()
	assert_eq(cell, cells[0], "nur HAUS hat 4 Buchstaben")
	assert_eq(run.coins, 50)
	assert_signal_emitted_with_parameters(run, "hint_changed", [[cells[0]]])


func test_hint_without_matching_word_is_free() -> void:
	run.start()
	_use_rows([5])
	_column(0, "AST")
	run.coins = 100
	assert_eq(run.hint(), RunSession.NO_CELL)
	assert_eq(run.coins, 100)
	assert_signal_not_emitted(run, "hint_changed")


# --- Stein ersetzen -----------------------------------------------------------------

func test_replace_gives_new_letter_for_100() -> void:
	run.start()
	_use_rows([3])
	var cells := _column(0, "AST")
	run.coins = 150
	var letter := run.replace(cells[1])
	assert_ne(letter, "")
	assert_ne(letter, "S", "immer ein anderer Buchstabe")
	assert_eq(run.grid.get_letter(cells[1]), letter)
	assert_eq(run.coins, 50)
	assert_signal_emitted_with_parameters(run, "tile_changed", [cells[1], letter])


func test_replace_always_changes_letter() -> void:
	run.start()
	_use_rows([3])
	var cells := _column(0, "EEE")
	for i in 30:
		run.coins = 100
		var before := run.grid.get_letter(cells[0])
		var after := run.replace(cells[0])
		assert_ne(after, before)


func test_replace_needs_coins_and_tile() -> void:
	run.start()
	_use_rows([3])
	_column(0, "AST")
	run.coins = 99
	assert_false(run.can_replace())
	assert_eq(run.replace(Vector2i(0, 0)), "")
	run.coins = 500
	assert_false(run.can_replace(Vector2i(3, 5)), "leerer Platz")
	assert_eq(run.replace(Vector2i(3, 5)), "")
	assert_eq(run.coins, 500)


func test_replace_works_on_full_board() -> void:
	run.start()
	_use_rows([3])
	for cell in run.grid.all_cells():
		run.grid.set_letter(cell, "E")
	run.coins = 100
	assert_false(run.can_refill())
	assert_true(run.can_replace(Vector2i(2, 4)))
	assert_ne(run.replace(Vector2i(2, 4)), "")


# --- Tauschen ----------------------------------------------------------------------------

func test_swap_changes_5_tiles_for_50() -> void:
	run.start()
	_use_rows([3])
	for cell in run.grid.all_cells():
		run.grid.set_letter(cell, "E")
	run.coins = 80
	var cells := run.swap()
	assert_eq(cells.size(), 5)
	assert_eq(run.coins, 30)
	assert_eq(run.grid.free_count(), 0, "Feld bleibt gleich voll")
	for cell in cells:
		assert_ne(run.grid.get_letter(cell), "E", "neuer Buchstabe")
	assert_signal_emit_count(run, "tile_changed", 5)


func test_swap_allowed_on_full_board() -> void:
	run.start()
	_use_rows([3])
	for cell in run.grid.all_cells():
		run.grid.set_letter(cell, "E")
	run.coins = 50
	assert_false(run.can_refill())
	assert_true(run.can_swap())


func test_swap_with_few_tiles_swaps_all() -> void:
	run.start()
	_use_rows([3])
	var cells := _column(0, "AST")
	run.coins = 50
	var swapped := run.swap()
	assert_eq(swapped.size(), 3)
	for cell in cells:
		assert_true(swapped.has(cell))


func test_swap_needs_coins_and_tiles() -> void:
	run.start()
	_use_rows([3])
	run.coins = 49
	assert_false(run.can_swap())
	assert_eq(run.swap().size(), 0)
	run.grid.clear_all()
	run.coins = 100
	assert_false(run.can_swap(), "keine Steine")


# --- Automatisch auffüllen ------------------------------------------------------------------

func test_found_word_refills_length_minus_one() -> void:
	run.start()
	_use_rows([4, 4])
	_column(0, "HAUS")
	_column(2, "OHR", false)
	assert_true(run.submit_path(_column(0, "HAUS", false)))
	assert_eq(_occupied(), 3 + 3, "OHR bleibt, 3 neue für HAUS")
	assert_signal_emit_count(run, "tile_spawned", 20 + 3)


func test_rejected_word_does_not_refill() -> void:
	run.start()
	_use_rows([5])
	_column(0, "AST")
	run.submit_path(_column(0, "AST", false))
	assert_eq(_occupied(), 3)


# --- Tipp Buchstabe für Buchstabe, Lösung ---------------------------------------------------

## Auftrag mit einer 4er-Zeile; im Feld liegt nur MAUS als Wort mit 4 Buchstaben.
func _maus_quest() -> Array[Vector2i]:
	_use_rows([4])
	return _column(2, "MAUS")


func test_hints_reveal_letters_one_by_one() -> void:
	run.start()
	var maus := _maus_quest()
	run.coins = 1000
	for i in 4:
		assert_true(run.can_hint())
		assert_eq(run.hint(), maus[i])
		assert_eq(run.hinted_cells(), maus.slice(0, i + 1))
	assert_eq(run.coins, 600, "je Buchstabe 100")
	assert_false(run.can_hint(), "alle Buchstaben gezeigt")
	assert_eq(run.hint(), RunSession.NO_CELL)
	assert_eq(run.coins, 600)


func test_hint_stays_after_rejected_word() -> void:
	run.start()
	var maus := _maus_quest()
	_column(0, "AST", false)
	run.coins = 200
	run.hint()
	run.submit_path(_column(0, "AST", false))
	assert_eq(run.hinted_cells(), [maus[0]], "blinkt weiter")


func test_hint_resets_when_word_changes() -> void:
	run.start()
	var maus := _maus_quest()
	run.coins = 1000
	run.hint()
	run.hint()
	run.replace(maus[1])
	assert_eq(run.hinted_cells().size(), 0, "Tipp verfällt")
	assert_signal_emitted_with_parameters(run, "hint_changed", [[]])


func test_new_quest_resets_hint() -> void:
	run.start()
	_use_rows([3])
	_column(0, "AST")
	run.coins = 100
	run.hint()
	assert_eq(run.hinted_cells().size(), 1)
	run.submit_path(_column(0, "AST", false))
	assert_eq(run.level(), 2)
	assert_eq(run.hinted_cells().size(), 0)


func test_solution_prefers_hint_word() -> void:
	run.start()
	var maus := _maus_quest()
	run.coins = 100
	run.hint()
	assert_eq(run.solution(), maus)


func test_solution_without_hint_and_without_match() -> void:
	run.start()
	var maus := _maus_quest()
	assert_eq(run.solution(), maus)
	run.grid.clear_all()
	assert_eq(run.solution().size(), 0)


func test_solution_available_after_give_up() -> void:
	run.start()
	var maus := _maus_quest()
	run.give_up()
	assert_eq(run.solution(), maus)


func test_hint_drops_when_its_row_is_filled() -> void:
	run.start()
	_use_rows([4, 3])
	var maus := _column(2, "MAUS")
	var haus := _column(0, "HAUS", false)
	run.coins = 100
	run.hint()
	var hinted := run.hinted_cells()[0]
	# Das andere 4er-Wort füllt die einzige 4er-Zeile: der Tipp passt nicht mehr.
	run.submit_path(haus if hinted == maus[0] else maus)
	assert_eq(run.hinted_cells().size(), 0)


func test_hint_finds_word_for_any_free_row() -> void:
	run.start()
	_use_rows([5, 3])
	var ast := _column(0, "AST")
	run.coins = 100
	assert_eq(run.hint(), ast[0], "AST passt in die 3er-Zeile")
