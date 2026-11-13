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


## Eigenen Auftrag als einzige Karte anbieten und wählen.
func _use_quest(length: int, count: int = 1, max_moves: int = 0, no_refill: bool = false,
		reward: int = 100) -> Quest:
	var q := Quest.new()
	q.word_length = length
	q.count = count
	q.max_moves = max_moves
	q.no_refill = no_refill
	q.reward = reward
	run.quest = null
	run.offer = [q]
	run.choose_quest(0)
	return run.quest


func _occupied() -> int:
	return run.grid.size() - run.grid.free_count()


# --- Start -----------------------------------------------------------------------

func test_start_from_spec() -> void:
	run.start()
	assert_eq(_occupied(), 20)
	assert_eq(run.coins, 0)
	assert_eq(run.level(), 1)
	assert_null(run.quest, "erst Karte wählen")
	assert_eq(run.offer.size(), 2)
	assert_signal_emitted(run, "quest_offered")
	assert_false(run.is_over)


func test_start_tiles_do_not_float() -> void:
	run.start()
	for cell in run.grid.all_cells():
		if run.grid.is_occupied(cell) and cell.y > 0:
			assert_true(run.grid.is_occupied(Vector2i(cell.x, cell.y - 1)), "schwebt: %s" % cell)


func test_same_seed_same_start_and_cards() -> void:
	var other := RunSession.new(balance, curve, lang, dict, 42)
	run.start()
	other.start()
	for cell in run.grid.all_cells():
		assert_eq(run.grid.get_letter(cell), other.grid.get_letter(cell))
	assert_eq(run.offer[0].word_length, other.offer[0].word_length)


# --- Karten wählen ---------------------------------------------------------------

func test_choose_starts_quest() -> void:
	run.start()
	assert_true(run.choose_quest(1))
	assert_not_null(run.quest)
	assert_eq(run.quest.word_length, 4, "Level 1 riskant: 4 Buchstaben")
	assert_eq(run.offer.size(), 0)
	assert_signal_emitted(run, "quest_started")


func test_choose_invalid_or_twice_fails() -> void:
	run.start()
	assert_false(run.choose_quest(5))
	assert_true(run.choose_quest(0))
	assert_false(run.choose_quest(0), "schon gewählt")


func test_words_rejected_without_quest() -> void:
	run.start()
	var cells := _column(0, "AST")
	assert_false(run.submit_path(cells))
	assert_signal_emitted_with_parameters(run, "word_rejected", [cells, RunSession.REASON_NO_QUEST])


# --- Wörter und Aufträge -------------------------------------------------------------

func test_word_completes_quest_and_pays() -> void:
	run.start()
	_use_quest(3, 1, 0, false, 100)
	var cells := _column(0, "AST")
	assert_true(run.submit_path(cells))
	assert_true(run.grid.is_free(cells[0]), "Wort verschwindet")
	assert_eq(run.coins, 100)
	assert_eq(run.level(), 2)
	assert_null(run.quest)
	assert_eq(run.offer.size(), 2, "neue Karten für Level 2")
	assert_signal_emitted(run, "quest_completed")


func test_non_matching_word_accepted_but_not_counted() -> void:
	run.start()
	_use_quest(5)
	var cells := _column(0, "AST")
	assert_true(run.submit_path(cells))
	assert_signal_emitted_with_parameters(run, "word_accepted", ["AST", cells, false])
	assert_eq(run.quest.moves, 1)
	assert_eq(run.quest.found, 0)
	assert_eq(run.level(), 1)


func test_field_stays_between_levels() -> void:
	run.start()
	_use_quest(3)
	_column(0, "AST")
	_column(2, "OHR", false)
	run.submit_path(_column(0, "AST", false))
	assert_eq(run.level(), 2)
	assert_eq(run.grid.get_letter(Vector2i(2, 0)), "O", "übrige Steine bleiben liegen")


func test_minimum_length_is_3() -> void:
	run.start()
	_use_quest(3)
	var cells := _column(0, "AS")
	assert_false(run.submit_path(cells))
	assert_signal_emitted_with_parameters(run, "word_rejected", [cells, RunSession.REASON_TOO_SHORT])


func test_unknown_word_rejected() -> void:
	run.start()
	_use_quest(3)
	var cells := _column(0, "XYZ")
	assert_false(run.submit_path(cells))
	assert_signal_emitted_with_parameters(run, "word_rejected", [cells, RunSession.REASON_NOT_A_WORD])
	assert_eq(run.quest.moves, 0, "ungültig ist kein Zug")


func test_missed_move_limit_ends_run() -> void:
	run.start()
	_use_quest(4, 2, 2)
	run.submit_path(_column(0, "AST"))
	assert_false(run.is_over)
	run.submit_path(_column(0, "OHR"))
	assert_true(run.is_over)
	assert_signal_emitted_with_parameters(run, "run_ended", [1, RunSession.REASON_OUT_OF_MOVES])


func test_nothing_accepted_after_end() -> void:
	run.start()
	_use_quest(3)
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
	_use_quest(3)
	assert_false(run.can_refill(), "Start mit 0 Münzen")
	assert_eq(run.refill(), 0)


func test_refill_brings_5_tiles_for_50() -> void:
	run.start()
	_use_quest(3)
	run.coins = 120
	var before := _occupied()
	assert_eq(run.refill(), 5)
	assert_eq(_occupied(), before + 5)
	assert_eq(run.coins, 70)


func test_refill_blocked_by_no_refill_quest() -> void:
	run.start()
	_use_quest(3, 1, 0, true)
	run.coins = 500
	assert_false(run.can_refill())
	assert_eq(run.refill(), 0)
	assert_eq(run.coins, 500)


func test_refill_blocked_on_full_board() -> void:
	run.start()
	_use_quest(3)
	run.coins = 500
	for cell in run.grid.all_cells():
		run.grid.set_letter(cell, "E")
	assert_false(run.can_refill())
	assert_eq(run.coins, 500)


func test_refill_partial_when_little_space() -> void:
	run.start()
	_use_quest(3)
	run.coins = 50
	for cell in run.grid.all_cells():
		run.grid.set_letter(cell, "E")
	run.grid.clear(Vector2i(0, 8))
	run.grid.clear(Vector2i(1, 8))
	assert_eq(run.refill(), 2)
	assert_eq(run.coins, 0)
