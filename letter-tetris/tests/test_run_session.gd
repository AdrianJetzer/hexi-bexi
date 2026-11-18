extends GutTest

var balance: GameBalance
var curve: QuestCurve
var lang: LanguageData
var dict: WordDictionary
var run: RunSession


func before_each() -> void:
	# Eigene Kopie mit festen Test-Preisen: so brechen die Tests nicht, wenn die Spielwerte
	# (Preise) in balance.tres zum Feintuning geändert werden.
	balance = (load("res://data/balance.tres") as GameBalance).duplicate() as GameBalance
	# Feste Rastergröße für die Tests (manche Tests legen Wörter mit 6 Buchstaben in eine Spalte).
	balance.grid_rows = 6
	# Ohne Roguelike-Draft: alle Hilfen von Anfang an (Draft-Tests schalten ihn selbst ein).
	balance.draft_enabled = false
	# Ohne automatisches Auffüllen: die Tests bauen Felder von Hand (eigene Tests schalten es ein).
	balance.auto_refill = false
	balance.refill_price = 100
	balance.swap_price = 50
	balance.clear_price = 100
	balance.hint_price = 100
	balance.replace_price = 100
	balance.solve_price = 100
	for p in ["joker_price", "shuffle_price", "magnet_price", "complete_price", "shorten_price", "strike_price",
			"split_price", "scan_price"]:
		balance.set(p, 50)
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
	assert_eq(_occupied(), 10)
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
	assert_eq(run.coins, curve.reward(1), "fest laut Kurve")


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


# --- Auffüllen -----------------------------------------------------------------------

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


func test_refill_price_is_fixed() -> void:
	run.start()
	_use_rows([3])
	run.coins = 1000
	assert_eq(run.refill_price(), 100)
	run.refill()
	run.refill()
	assert_eq(run.refill_price(), 100, "wird nicht teurer")
	assert_eq(run.coins, 800)


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
	var top := run.grid.rows - 1
	run.grid.clear(Vector2i(0, top))
	run.grid.clear(Vector2i(1, top))
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
	assert_signal_emit_count(run, "tile_spawned", 10 + 3)


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


# --- Wort-Hilfe auf den Auftrag ausgerichtet ------------------------------------------------

func test_help_aims_at_free_row_lengths() -> void:
	var common := WordDictionary.from_words(PackedStringArray(["TEE", "HAUS", "STERN"]))
	var r := RunSession.new(balance, curve, lang, dict, 3, common)
	r.start()
	assert_eq(r._spawner.finder.only_lengths, PackedInt32Array([3]), "Level 1: ▢▢▢")
	var q := Quest.new()
	q.rows = PackedInt32Array([4, 7])
	r.quest = q.start()
	r._aim_help()
	assert_eq(r._spawner.finder.only_lengths, PackedInt32Array([4, 7]))
	assert_eq(r._spawner.finder.min_length, 4)
	assert_eq(r._spawner.finder.max_length, 7)
	r.quest.fill(0, "HAUS")
	r._aim_help()
	assert_eq(r._spawner.finder.only_lengths, PackedInt32Array([7]), "nur noch die freie Zeile")


# --- Aufräumen -----------------------------------------------------------------------------

func test_clear_removes_least_helpful_first() -> void:
	run.start()
	_use_rows([4])
	var haus := _column(0, "HAUS")
	_column(2, "QEEE", false)
	_column(4, "XYEN", false)
	run.coins = 150
	var removed := run.clear_useless()
	assert_eq(removed.size(), 5)
	assert_eq(run.coins, 50)
	for cell in removed:
		assert_true(run.grid.is_free(cell), "Platz bleibt frei")
	for cell in haus:
		assert_false(removed.has(cell), "HAUS passt und bleibt")
	assert_true(removed.has(Vector2i(2, 0)), "Q zuerst")
	assert_true(removed.has(Vector2i(4, 0)) and removed.has(Vector2i(4, 1)), "X und Y")
	assert_signal_emitted_with_parameters(run, "tiles_removed", [removed])


func test_clear_keeps_a_fitting_word() -> void:
	run.start()
	_use_rows([5])
	var stern := _column(0, "STERN")
	_column(2, "QX", false)
	run.coins = 100
	var removed := run.clear_useless()
	assert_eq(removed.size(), 2, "nur QX, STERN bleibt")
	for cell in stern:
		assert_true(run.grid.is_occupied(cell))
	assert_false(run.is_stuck(), "danach lässt sich noch STERN schreiben")


func test_clear_keeps_enough_tiles_for_all_free_rows() -> void:
	run.start()
	_use_rows([4, 5])
	_column(0, "HAUS")
	_column(2, "QXYQX", false)
	_column(4, "QX", false)
	run.coins = 100
	assert_eq(run.clear_amount(), 2, "11 Steine, 4 + 5 = 9 müssen bleiben")
	assert_eq(run.clear_useless().size(), 2)
	assert_eq(run.grid.size() - run.grid.free_count(), 9)
	run.quest.fill(0, "HAUS")
	assert_eq(run.clear_amount(), 4, "nur noch die 5er-Zeile frei")


func test_clear_does_nothing_when_no_word_fits() -> void:
	run.start()
	_use_rows([5])
	_column(0, "ATMHA")
	_column(2, "EEEEE", false)
	run.coins = 100
	assert_eq(run.clear_useless().size(), 0)
	assert_eq(run.coins, 100, "kostet nichts")
	assert_signal_not_emitted(run, "tiles_removed")


func test_clear_with_only_the_word_left_does_nothing() -> void:
	run.start()
	_use_rows([5])
	_column(0, "STERN")
	run.coins = 100
	assert_eq(run.clear_useless().size(), 0)
	assert_eq(run.coins, 100)


func test_clear_always_removes_five_if_possible() -> void:
	run.start()
	_use_rows([3])
	_column(0, "AST")
	_column(2, "OHR", false)
	_column(4, "TEE", false)
	run.coins = 100
	assert_eq(run.clear_useless().size(), 5, "auch wenn alle Steine in Wörtern stecken")
	assert_eq(run.coins, 0)


func test_clear_keeps_hint_word() -> void:
	run.start()
	_use_rows([4])
	var maus := _column(2, "MAUS")
	_column(0, "HAUS", false)
	run.coins = 300
	run.hint()
	var hinted := run.hinted_cells()[0]
	var word := maus if hinted == maus[0] else _column(0, "HAUS", false)
	run.clear_useless()
	for cell in word:
		assert_true(run.grid.is_occupied(cell), "Tipp-Wort bleibt")


func test_clear_needs_coins() -> void:
	run.start()
	_use_rows([4])
	_column(0, "HAUS")
	_column(3, "QXY", false)
	run.coins = 99
	assert_false(run.can_clear())
	assert_eq(run.clear_useless().size(), 0)


func test_clear_with_real_dictionary_is_fast_enough() -> void:
	var words := WordDictionary.from_file(lang.words_path)
	var common := WordDictionary.from_file(lang.common_words_path)
	var r := RunSession.new(balance, curve, lang, words, 5, common)
	r.start()
	for i in 20:
		r._spawn(1)
	var q := Quest.new()
	q.rows = PackedInt32Array([3, 5, 8])
	r.quest = q.start()
	var t0 := Time.get_ticks_msec()
	var ranked := r.clear_candidates(r.protected_word())
	var ms := Time.get_ticks_msec() - t0
	gut.p("Aufräumen bei %d Kandidaten: %d ms" % [ranked.size(), ms])
	assert_lt(ms, 2000)


# --- Feststecken und automatisches Auffüllen (v8.5) -----------------------------------------

func test_has_fitting_word() -> void:
	run.start()
	_use_rows([5])
	_column(0, "WABUH")
	assert_false(run.has_fitting_word())
	_column(0, "STERN")
	assert_true(run.has_fitting_word())


func test_no_fitting_word_for_other_length() -> void:
	run.start()
	_use_rows([4])
	_column(0, "STERN")
	assert_false(run.has_fitting_word(), "STERN hat 5 Buchstaben, gesucht sind 4")


func test_stuck_without_nice_word() -> void:
	# STERN ist gültig, aber kein schönes Wort: man steckt fest (v8.4).
	var common := WordDictionary.from_words(PackedStringArray(["HAUS"]))
	run = RunSession.new(balance, curve, lang, dict, 42, common)
	run.start()
	_use_rows([5])
	_column(0, "STERN")
	assert_true(run.is_stuck(), "kein schönes Wort")
	assert_false(run.has_fitting_word())


func test_joker_counts_as_fitting() -> void:
	run.start()
	_use_rows([5])
	_column(0, "WAB*H")
	assert_true(run.has_fitting_word(), "Joker zählt als vielleicht")


func test_auto_refill_after_word_when_stuck() -> void:
	balance.auto_refill = true
	run.start()
	_use_rows([3, 5])
	var ohr := _column(0, "OHR")
	_column(1, "WABUH", false)
	var coins := run.coins
	assert_true(run.submit_path(ohr))
	assert_true(run.has_fitting_word() or run.grid.free_count() == 0,
			"selbst aufgefüllt, bis ein Wort geht oder das Feld voll ist")
	assert_gt(_occupied(), 5 + 2, "mehr als die üblichen Wortlänge − 1 neuen Steine")
	assert_eq(run.coins, coins, "gratis")


func test_no_auto_refill_when_word_fits() -> void:
	balance.auto_refill = true
	run.start()
	_use_rows([3, 5])
	var ohr := _column(0, "OHR")
	_column(1, "STERN", false)
	assert_true(run.submit_path(ohr))
	assert_eq(_occupied(), 5 + 2, "STERN passt noch: nur Wortlänge − 1 neue Steine")


func test_auto_refill_stops_when_board_full() -> void:
	balance.auto_refill = true
	run.start()
	_use_rows([5])
	for cell in run.grid.all_cells():
		run.grid.set_letter(cell, "Q")
	run.grid.clear(Vector2i(0, 0))
	run._auto_refill()
	assert_eq(run.grid.free_count(), 0, "letzter freier Platz gefüllt, dann Schluss")


func test_auto_refill_plants_word_when_board_full() -> void:
	balance.auto_refill = true
	run.start()
	_use_rows([5])
	for cell in run.grid.all_cells():
		run.grid.set_letter(cell, "Q")
	assert_false(run.has_fitting_word(), "volles Feld, kein Wort")
	var coins := run.coins
	run._auto_refill()
	assert_eq(run.grid.free_count(), 0, "Feld bleibt voll")
	assert_true(run.has_fitting_word(), "Steine haben sich zu einem passenden Wort umgedreht")
	assert_false(run.solution().is_empty(), "Tipp und Lösen finden es")
	assert_eq(run.coins, coins, "gratis")


func test_solve_and_hint_only_use_nice_words() -> void:
	# STERN ist gültig, aber kein schönes Wort: Lösen nimmt es nicht, sondern dreht Steine zu einem
	# schönen Wort um und nimmt dieses (v8.4).
	var common := WordDictionary.from_words(PackedStringArray(["HAUS", "BLUME"]))
	run = RunSession.new(balance, curve, lang, dict, 42, common)
	run.start()
	_use_rows([5])
	_column(0, "STERN")
	run.coins = 1000
	assert_eq(run.solution().size(), 0, "keine Lösung aus dem ganzen Wörterbuch")
	assert_eq(run.solution_fallback()["word"], "BLUME", "Aufgeben zeigt ein schönes Wort")
	watch_signals(run)
	assert_true(run.solve())
	assert_signal_not_emitted(run, "row_filled", "kein Wort aus dem Nichts")
	assert_signal_emitted(run, "tile_changed", "Steine drehen sich um")
	var params: Array = get_signal_parameters(run, "word_accepted")
	assert_eq(params[0], "BLUME", "das schöne Wort fliegt aus dem Feld")


# --- Schlaues Tauschen -------------------------------------------------------------------

func test_stuck_when_no_fitting_common_word() -> void:
	run.start()
	_use_rows([5])
	_column(0, "WABUH")
	assert_true(run.is_stuck())
	_column(0, "STERN")
	assert_false(run.is_stuck())


func test_swap_plants_word_when_stuck() -> void:
	run.start()
	_use_rows([5])
	_column(0, "WABUH")
	run.coins = 50
	var changed := run.swap()
	assert_eq(changed.size(), 5)
	assert_eq(run.coins, 0)
	assert_false(run.is_stuck(), "danach liegt ein passendes Wort im Feld")
	var finder := WordFinder.new(dict)
	assert_false(finder.find_paths(run.grid, 5, 5, func(w: String) -> bool: return w == "STERN").is_empty())


func test_swap_fills_up_with_normal_swaps() -> void:
	run.start()
	_use_rows([5])
	_column(0, "STERX")
	_column(2, "EEEEE", false)
	run.coins = 50
	var changed := run.swap()
	assert_eq(changed.size(), 5, "1 für das Wort, 4 normal getauscht")
	assert_false(run.is_stuck())
	for i in 4:
		assert_eq(run.grid.get_letter(Vector2i(0, i)), "STER"[i], "Kette bleibt unangetastet")


# --- Lösen --------------------------------------------------------------------------------

func test_solve_uses_words_from_board_without_reward() -> void:
	run.start()
	_use_rows([3, 4], 150)
	var ast := _column(0, "AST")
	var haus := _column(2, "HAUS", false)
	run.coins = balance.solve_price + 100
	assert_true(run.solve())
	assert_eq(run.coins, 100, "Preis bezahlt, keine Belohnung")
	assert_eq(run.level(), 2, "nächstes Level")
	assert_signal_emit_count(run, "word_accepted", 2)
	assert_eq(get_signal_parameters(run, "quest_completed")[1], 0, "Belohnung 0")
	assert_signal_not_emitted(run, "row_filled")
	var used: Array = []
	for p in [get_signal_parameters(run, "word_accepted", 0), get_signal_parameters(run, "word_accepted", 1)]:
		used.append(p[0])
	assert_true(used.has("AST") and used.has("HAUS"), "Wörter aus dem Feld")


func test_solve_fills_missing_rows_with_random_words() -> void:
	run.start()
	_use_rows([5])
	_column(0, "AST")
	run.coins = balance.solve_price
	assert_true(run.solve())
	assert_signal_emitted(run, "row_filled")
	var params: Array = get_signal_parameters(run, "row_filled")
	assert_eq(params[0], 0)
	assert_eq((params[1] as String).length(), 5)
	assert_true(dict.contains(params[1]))
	assert_eq(run.grid.get_letter(Vector2i(0, 0)), "A", "Feld bleibt dafür unverändert")
	assert_eq(run.level(), 2)


func test_solve_needs_coins() -> void:
	run.start()
	_use_rows([3])
	run.coins = balance.solve_price - 1
	assert_false(run.can_solve())
	assert_false(run.solve())
	assert_eq(run.level(), 1)
	assert_eq(run.coins, balance.solve_price - 1)


func test_solve_keeps_filled_rows() -> void:
	run.start()
	_use_rows([3, 4])
	run.submit_path(_column(0, "AST"))
	assert_signal_emit_count(run, "word_accepted", 1)
	_column(2, "HAUS", false)
	run.coins = balance.solve_price
	run.solve()
	assert_signal_emit_count(run, "word_accepted", 2, "nur die 4er-Zeile wird noch gelöst")


# --- Joker -------------------------------------------------------------------------------

func test_joker_turns_a_tile_into_joker() -> void:
	run.start()
	_use_rows([3])
	_column(0, "AST")
	run.coins = 50
	var chosen := Vector2i(0, 1)
	var cell := run.joker(chosen)
	assert_eq(cell, chosen, "der angetippte Stein wird zum Joker")
	assert_eq(run.grid.get_letter(cell), RunSession.JOKER)
	assert_eq(run.coins, 0)
	assert_signal_emitted_with_parameters(run, "tile_changed", [cell, RunSession.JOKER])


func test_joker_on_joker_or_empty_is_free() -> void:
	run.start()
	_use_rows([3])
	_column(0, "A*T")
	run.coins = 100
	assert_eq(run.joker(Vector2i(0, 1)), RunSession.NO_CELL, "schon Joker")
	var empty := Vector2i(-1, -1)
	for c in run.grid.all_cells():
		if not run.grid.is_occupied(c):
			empty = c
			break
	assert_eq(run.joker(empty), RunSession.NO_CELL, "leerer Platz")
	assert_eq(run.coins, 100, "kostet nichts")


func test_joker_stands_for_any_letter() -> void:
	run.start()
	_use_rows([4])
	var cells := _column(0, "H*US")
	assert_true(run.submit_path(cells))
	assert_signal_emitted_with_parameters(run, "word_accepted", ["HAUS", cells, 0])
	assert_eq(run.level(), 2)


func test_joker_word_must_fit_a_row() -> void:
	run.start()
	_use_rows([5])
	var cells := _column(0, "H*US")
	assert_false(run.submit_path(cells))
	assert_signal_emitted_with_parameters(run, "word_rejected", [cells, RunSession.REASON_NOT_MATCHING])


func test_joker_without_valid_word_rejected() -> void:
	run.start()
	_use_rows([4])
	var cells := _column(0, "XQ*Z")
	assert_false(run.submit_path(cells))
	assert_signal_emitted_with_parameters(run, "word_rejected", [cells, RunSession.REASON_NOT_A_WORD])


func test_two_jokers() -> void:
	run.start()
	_use_rows([5])
	var cells := _column(0, "S**RN")
	assert_true(run.submit_path(cells))
	assert_signal_emitted_with_parameters(run, "word_accepted", ["STERN", cells, 0])


func test_joker_needs_coins_and_normal_tile() -> void:
	run.start()
	_use_rows([3])
	_column(0, "**")
	run.coins = 50
	assert_false(run.can_joker(), "nur Joker im Feld")
	_column(0, "AST")
	run.coins = 49
	assert_false(run.can_joker())


# --- Mischen -------------------------------------------------------------------------------

func test_shuffle_keeps_letters_and_places() -> void:
	run.start()
	_use_rows([3])
	_column(0, "ABCDEF")
	_column(2, "GHIJKL", false)
	_column(4, "MNOP", false)
	run.coins = 50
	var before := {}
	for cell in run.grid.all_cells():
		if run.grid.is_occupied(cell):
			before[run.grid.get_letter(cell)] = true
	var changed := run.shuffle()
	assert_gt(changed.size(), 0)
	assert_eq(run.grid.size() - run.grid.free_count(), 16, "gleich viele Steine")
	var after := {}
	for cell in run.grid.all_cells():
		if run.grid.is_occupied(cell):
			after[run.grid.get_letter(cell)] = true
	assert_eq(after.keys().size(), 16)
	for l in before:
		assert_true(after.has(l), "Buchstabe %s bleibt" % l)
	assert_eq(run.coins, 0)


func test_shuffle_needs_two_tiles() -> void:
	run.start()
	_use_rows([3])
	_column(0, "A")
	run.coins = 50
	assert_false(run.can_shuffle())


# --- Magnet ------------------------------------------------------------------------

func test_magnet_builds_word_around_tapped_tile() -> void:
	run.start()
	_use_rows([5])
	var cells := _column(0, "QQQRQ")
	run.coins = 50
	var changed := run.magnet(cells[3])
	assert_gt(changed.size(), 0)
	assert_false(changed.has(cells[3]), "angetippter Stein bleibt")
	assert_eq(run.grid.get_letter(cells[3]), "R")
	assert_false(run.is_stuck(), "STERN liegt jetzt im Feld")
	assert_eq(run.coins, 0)


func test_magnet_impossible_is_free() -> void:
	run.start()
	_use_rows([5])
	var cells := _column(0, "RQ")
	run.coins = 50
	assert_eq(run.magnet(cells[0]).size(), 0)
	assert_eq(run.coins, 50)


# --- Teilen und Scan ---------------------------------------------------------------------------

func test_strike_removes_longest_free_row() -> void:
	run.start()
	_use_rows([4, 7, 7])
	run.coins = 50
	assert_true(run.strike())
	assert_eq(run.quest.rows, PackedInt32Array([4, 7]), "bei Gleichstand die oberste")
	assert_eq(run.coins, 0)
	assert_signal_emitted(run, "quest_reshaped")
	assert_false(run.quest.is_done())


func test_strike_needs_two_free_rows() -> void:
	run.start()
	var q := _use_rows([3, 5])
	q.fill(1, "STERN")
	run.coins = 50
	assert_false(run.can_strike(), "nur noch eine Zeile frei")
	assert_false(run.strike())
	assert_eq(run.coins, 50, "kostet nichts")
	assert_eq(run.quest.rows, PackedInt32Array([3, 5]))


func test_strike_keeps_filled_rows() -> void:
	run.start()
	var q := _use_rows([8, 3, 5])
	q.fill(0, "STERNEXX")
	run.coins = 50
	assert_true(run.strike())
	assert_eq(run.quest.rows, PackedInt32Array([8, 3]), "gefüllte 8er bleibt, freie 5er fällt weg")
	assert_eq(run.quest.filled[0], "STERNEXX")


func test_shorten_takes_one_block_from_longest_free_row() -> void:
	run.start()
	_use_rows([4, 7, 7])
	run.coins = 50
	assert_true(run.shorten())
	assert_eq(run.quest.rows, PackedInt32Array([4, 6, 7]), "bei Gleichstand die oberste")
	assert_eq(run.coins, 0)
	assert_signal_emitted(run, "quest_reshaped")


func test_shorten_skips_filled_rows_and_stops_at_three() -> void:
	run.start()
	var q := _use_rows([3, 5])
	q.fill(1, "STERN")
	run.coins = 50
	assert_false(run.can_shorten(), "nur noch eine 3er-Zeile frei")
	assert_false(run.shorten())
	assert_eq(run.coins, 50, "kostet nichts")
	assert_eq(run.quest.rows, PackedInt32Array([3, 5]))


func test_split_halves_longest_free_row() -> void:
	run.start()
	_use_rows([6, 8])
	run.coins = 50
	assert_true(run.split())
	assert_eq(run.quest.rows, PackedInt32Array([6, 4, 4]))
	assert_eq(run.coins, 0)
	assert_signal_emitted(run, "quest_reshaped")


func test_split_odd_length() -> void:
	run.start()
	_use_rows([7])
	run.coins = 50
	run.split()
	assert_eq(run.quest.rows, PackedInt32Array([4, 3]))


func test_split_needs_long_row_and_is_free_otherwise() -> void:
	run.start()
	_use_rows([5, 4])
	run.coins = 50
	assert_false(run.can_split())
	assert_false(run.split())
	assert_eq(run.coins, 50)


func test_split_then_short_words_solve_it() -> void:
	run.start()
	_use_rows([8])
	run.coins = 50
	run.split()
	run.submit_path(_column(0, "HAUS"))
	assert_eq(run.level(), 1)
	run.submit_path(_column(0, "BAUM"))
	assert_eq(run.level(), 2, "4 + 4 statt 8")


func test_scan_shows_tiles_of_fitting_words() -> void:
	run.start()
	_use_rows([4])
	var haus := _column(0, "HAUS")
	_column(2, "QXZ", false)
	run.coins = 50
	var cells := run.scan()
	assert_eq(cells.size(), 4)
	for c in haus:
		assert_true(cells.has(c))
	assert_eq(run.coins, 0)
	assert_signal_emitted(run, "scan_shown")


func test_scan_shows_one_word_for_longest_row() -> void:
	run.start()
	_use_rows([3, 4])
	_column(0, "AST")
	var haus := _column(2, "HAUS", false)
	run.coins = 50
	var cells := run.scan()
	assert_eq(cells, haus, "nur HAUS (längere Zeile), nicht auch AST")


func test_scan_falls_back_to_shorter_row() -> void:
	run.start()
	_use_rows([3, 5])
	var ast := _column(0, "AST")
	run.coins = 50
	assert_eq(run.scan(), ast, "kein 5er-Wort, also das 3er-Wort")


func test_hint_after_scan_reveals_scanned_word() -> void:
	run.start()
	_use_rows([4])
	_column(0, "HAUS")
	_column(2, "MAUS", false)
	run.coins = 1000
	var scanned := run.scan()
	assert_eq(scanned.size(), 4)
	for i in 4:
		assert_eq(run.hint(), scanned[i], "Tipp zeigt das Scan-Wort, Buchstabe %d" % (i + 1))


func test_scan_after_hint_shows_hinted_word() -> void:
	run.start()
	_use_rows([4])
	_column(0, "HAUS")
	_column(2, "MAUS", false)
	run.coins = 1000
	var first := run.hint()
	var scanned := run.scan()
	assert_eq(scanned[0], first, "Scan zeigt das schon getippte Wort")
	assert_eq(run.hinted_cells().size(), 1, "gezeigte Tipp-Buchstaben bleiben")
	assert_eq(run.hint(), scanned[1])


# --- Vervollständigen -----------------------------------------------------------------

func test_complete_shows_word_starting_with_prefix() -> void:
	run.start()
	_use_rows([4])
	var haus := _column(0, "HAUS")
	_column(2, "MAUS", false)
	run.coins = 150
	var cells := run.complete(haus.slice(0, 2))
	assert_eq(cells, haus)
	assert_eq(run.coins, 100)
	assert_signal_emitted(run, "scan_shown")
	assert_eq(run.hint(), haus[0], "Tipp zeigt danach dasselbe Wort")


func test_complete_needs_two_letters_and_a_longer_word() -> void:
	run.start()
	_use_rows([4])
	var haus := _column(0, "HAUS")
	run.coins = 50
	assert_eq(run.complete(haus.slice(0, 1)).size(), 0, "1 Buchstabe reicht nicht")
	assert_eq(run.complete(haus).size(), 0, "das ganze Wort ist kein Anfang")
	assert_eq(run.coins, 50, "kostet nichts")


func test_complete_without_continuation_is_free() -> void:
	run.start()
	_use_rows([4])
	var cells := _column(0, "QXHAUS")
	run.coins = 50
	assert_eq(run.complete(cells.slice(0, 2)).size(), 0)
	assert_eq(run.coins, 50)


func test_complete_only_for_free_row_length() -> void:
	run.start()
	_use_rows([6])
	var sterne := _column(0, "STERNE")
	run.coins = 50
	assert_eq(run.complete(sterne.slice(0, 2)), sterne, "STERNE (6), nicht STERN (5)")


func test_complete_falls_back_to_all_valid_words() -> void:
	var common := WordDictionary.from_words(PackedStringArray(["TEE"]))
	run = RunSession.new(balance, curve, lang, dict, 42, common)
	run.start()
	_use_rows([5])
	var stern := _column(0, "STERN")
	run.coins = 50
	assert_eq(run.complete(stern.slice(0, 2)), stern, "STERN ist kein Vorschlags-Wort, aber gültig")


func test_scan_without_words_is_free() -> void:
	run.start()
	_use_rows([4])
	_column(0, "QXZ")
	run.coins = 50
	assert_eq(run.scan().size(), 0)
	assert_eq(run.coins, 50)


# --- Roguelike-Draft: Power-ups und Upgrades ---------------------------------------------

func _draft_run() -> RunSession:
	balance.draft_enabled = true
	run = RunSession.new(balance, curve, lang, dict, 42)
	watch_signals(run)
	run.start()
	return run


## Auftrag des laufenden Levels als gelöst werten (wie nach dem letzten Wort).
func _finish_levels(n: int) -> void:
	for i in n:
		run._complete_quest()


func test_draft_starts_with_refill_and_solve_only() -> void:
	_draft_run()
	assert_eq(run.owned.size(), 0)
	assert_true(run.has_help("refill"))
	assert_true(run.has_help("solve"))
	run.coins = 1000
	assert_false(run.can_hint(), "Tipp ist noch nicht freigeschaltet")
	assert_false(run.can_swap())
	assert_true(run.can_solve())


func test_powerup_after_level_five() -> void:
	_draft_run()
	assert_eq(run.levels_until_offer(), balance.draft_every)
	assert_eq(run.next_offer_kind(), "powerup")
	_finish_levels(balance.draft_every - 1)
	assert_true(run.offer.is_empty())
	assert_eq(run.levels_until_offer(), 1)
	_finish_levels(1)
	assert_signal_emitted(run, "offer_made")
	assert_eq(run.offer["kind"], "powerup")
	var options: PackedStringArray = run.offer["options"]
	assert_eq(options, PackedStringArray(["hint"]), "erste Stufe: nur Tipp (Ersetzen, Tauschen deaktiviert)")
	assert_false(run.choose("replace"), "nicht im Angebot")
	assert_true(run.choose("hint"))
	assert_true(run.offer.is_empty())
	assert_true(run.has_help("hint"))
	assert_false(run.has_help("replace"), "Ersetzen deaktiviert")
	assert_false(run.has_help("swap"), "Tauschen deaktiviert")
	assert_signal_emitted(run, "helps_changed")
	assert_eq(run.levels_until_offer(), balance.draft_every)


func test_powerup_tiers_in_order() -> void:
	_draft_run()
	balance.goal_level = 0  # endlos, damit nach Level 20 Upgrades kommen
	var expected := [["hint"], ["shuffle", "joker", "shorten"],
			["clear", "split", "magnet"], ["scan", "strike", "complete"]]
	for tier in expected:
		_finish_levels(balance.draft_every)
		assert_eq(run.offer["kind"], "powerup")
		var options: PackedStringArray = run.offer["options"]
		assert_eq(options.size(), mini(2, tier.size()))
		for id in options:
			assert_true(tier.has(id), id)
		run.choose(options[0])
	assert_eq(run.owned.size(), 4)
	assert_eq(run.next_offer_kind(), "upgrade")


func test_upgrade_lowers_price_by_quarter() -> void:
	_draft_run()
	balance.goal_level = 0  # endlos, damit nach Level 20 Upgrades kommen
	for i in 4:
		_finish_levels(balance.draft_every)
		run.choose(run.offer["options"][0])
	_finish_levels(balance.draft_every)
	assert_eq(run.offer["kind"], "upgrade")
	var options: PackedStringArray = run.offer["options"]
	assert_eq(options.size(), 5, "alle 4 eigenen Hilfen und Lösen")
	assert_true(options.has("solve"), "Lösen ist dabei")
	var base := run.price("solve")
	assert_true(run.choose("solve"))
	assert_eq(run.price("solve"), int(round(base * 0.75 / 5.0)) * 5)


func test_upgrade_rounding_and_minimum() -> void:
	_draft_run()
	balance.magnet_price = 200
	run.owned.append("magnet")
	var seen := []
	for i in 12:
		run.offer = {"kind": "upgrade", "options": PackedStringArray(["magnet"])}
		run.choose("magnet")
		seen.append(run.price("magnet"))
	assert_eq(seen.slice(0, 4), [150, 115, 85, 65])
	assert_eq(seen[-1], 25, "nie unter 25")


func test_new_run_resets_draft() -> void:
	_draft_run()
	_finish_levels(balance.draft_every)
	run.choose(run.offer["options"][0])
	run.start()
	assert_eq(run.owned.size(), 0)
	assert_true(run.offer.is_empty())
	assert_eq(run.price("solve"), balance.solve_price)


func test_no_draft_means_all_helps() -> void:
	run.start()
	for id in RunSession.HELP_IDS:
		assert_true(run.has_help(id), id)
	assert_eq(run.levels_until_offer(), 0)
	_finish_levels(balance.draft_every)
	assert_true(run.offer.is_empty())


func test_powerup_choices_vary_between_runs() -> void:
	balance.draft_enabled = true
	var seen := {}
	for seed_value in range(1, 13):
		run = RunSession.new(balance, curve, lang, dict, seed_value)
		run.start()
		# Zweite Stufe (nach Level 10): 2 von 4 zur Wahl.
		_finish_levels(balance.draft_every)
		run.choose(run.offer["options"][0])
		_finish_levels(balance.draft_every)
		seen[",".join(run.offer["options"])] = true
	assert_gt(seen.size(), 1, "nicht immer dieselben zwei")


func test_run_ends_at_goal_with_stars() -> void:
	watch_signals(run)
	run.start()
	_finish_levels(balance.goal_level - 1)
	assert_false(run.is_over)
	assert_eq(run.levels_until_goal(), 1)
	_finish_levels(1)
	assert_true(run.is_over, "nach Level 20 ist der Lauf geschafft")
	assert_true(run.completed)
	assert_eq(run.level(), balance.goal_level)
	assert_signal_emitted_with_parameters(run, "goal_reached", [3])
	assert_signal_not_emitted(run, "run_ended")


func test_give_up_is_not_completed() -> void:
	run.start()
	run.give_up()
	assert_true(run.is_over)
	assert_false(run.completed)



func test_all_four_powerups_before_goal() -> void:
	_draft_run()
	for i in 4:
		_finish_levels(balance.draft_every)
		assert_eq(run.offer["kind"], "powerup", "Power-up %d" % (i + 1))
		run.choose(run.offer["options"][0])
	assert_eq(run.owned.size(), 4, "alle vier Stufen kommen vor Level 20 dran")
	assert_lt(run.level(), balance.goal_level)
	assert_eq(run.levels_until_offer(), 0, "danach nur noch bis zum Ziel")
	assert_eq(run.levels_until_goal(), balance.goal_level - 4 * balance.draft_every)
