extends GutTest

var balance: GameBalance
var lang: LanguageData
var dict: WordDictionary
var session: GameSession


func before_each() -> void:
	balance = load("res://data/balance.tres") as GameBalance
	lang = load("res://data/languages/de/language.tres") as LanguageData
	dict = WordDictionary.from_words(PackedStringArray([
		"STERN", "STERNE", "TEE", "HAUS", "ERNST", "RENNST", "STERNEN"]))
	session = GameSession.new(balance, lang, dict, 42)
	watch_signals(session)


## Feld leeren und eine Spalte von unten nach oben belegen.
func _column(c: int, letters: String, clear: bool = true) -> Array[Vector2i]:
	if clear:
		session.grid.clear_all()
	var cells: Array[Vector2i] = []
	for i in letters.length():
		var cell := Vector2i(c, i)
		session.grid.set_letter(cell, letters[i])
		cells.append(cell)
	return cells


func _path(cells: Array) -> Array[Vector2i]:
	var p: Array[Vector2i] = []
	for c in cells:
		p.append(c)
	return p


# --- Start ----------------------------------------------------------------------

func test_start_places_15_tiles() -> void:
	session.start()
	assert_eq(session.grid.size() - session.grid.free_count(), 15)
	assert_signal_emit_count(session, "tile_spawned", 15)
	assert_eq(session.score, 0)
	assert_eq(session.level(), 1)
	assert_false(session.is_over)


func test_start_tiles_do_not_float() -> void:
	session.start()
	for cell in session.grid.all_cells():
		if session.grid.is_occupied(cell) and cell.y > 0:
			assert_true(session.grid.is_occupied(Vector2i(cell.x, cell.y - 1)), "schwebt: %s" % cell)


func test_same_seed_same_start() -> void:
	var other := GameSession.new(balance, lang, dict, 42)
	session.start()
	other.start()
	for cell in session.grid.all_cells():
		assert_eq(session.grid.get_letter(cell), other.grid.get_letter(cell))


# --- Wörter ------------------------------------------------------------------------

func test_valid_word_is_removed_and_scored() -> void:
	session.start()
	var cells := _column(0, "TEE")
	assert_true(session.submit_path(cells))
	for cell in cells:
		assert_true(session.grid.is_free(cell))
	assert_eq(session.score, 30)
	assert_eq(session.last_word, "TEE")
	assert_eq(session.words_found, 1)
	assert_signal_emitted_with_parameters(session, "word_accepted", ["TEE", cells, 30])


func test_holes_stay_open_after_word() -> void:
	session.start()
	var cells := _column(0, "TEEX")
	assert_true(session.submit_path(cells.slice(0, 3)))
	assert_eq(session.grid.get_letter(Vector2i(0, 3)), "X", "nichts rutscht nach")


func test_no_new_tiles_without_level_up() -> void:
	session.start()
	_column(0, "TEE")
	var before: int = get_signal_emit_count(session, "tile_spawned")
	session.submit_path(_path([Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)]))
	assert_eq(get_signal_emit_count(session, "tile_spawned"), before, "kein Takt, kein Nachschub")


func test_unknown_word_changes_nothing() -> void:
	session.start()
	var cells := _column(0, "STERX")
	assert_false(session.submit_path(cells))
	assert_eq(session.score, 0)
	assert_signal_emitted_with_parameters(session, "word_rejected", [cells, GameSession.REASON_NOT_A_WORD])


func test_non_neighbors_and_duplicates_rejected() -> void:
	session.start()
	_column(0, "TEE")
	session.grid.set_letter(Vector2i(4, 0), "E")
	assert_false(session.submit_path(_path([Vector2i(0, 0), Vector2i(0, 1), Vector2i(4, 0)])))
	assert_false(session.submit_path(_path([Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 1)])))


# --- Level -------------------------------------------------------------------------

func test_level_up_at_100_brings_10_tiles() -> void:
	session.start()
	_column(0, "STERN")  # 100 Punkte
	var before: int = get_signal_emit_count(session, "tile_spawned")
	assert_true(session.submit_path(_column(0, "STERN")))
	assert_eq(session.score, 100)
	assert_eq(session.level(), 2)
	assert_signal_emitted_with_parameters(session, "level_changed", [2])
	assert_eq(get_signal_emit_count(session, "tile_spawned"), before + 10)


func test_multiple_level_ups_at_once() -> void:
	session.start()
	# STERNEN = 7 Buchstaben = 210 Punkte → Level 2 (100), noch nicht Level 3 (250)
	assert_true(session.submit_path(_column(0, "STERNEN")))
	assert_eq(session.level(), 2)
	# ERNST = 100 → 310 ≥ 250 → Level 3
	assert_true(session.submit_path(_column(1, "ERNST")))
	assert_eq(session.level(), 3)


func test_min_length_rises_with_level() -> void:
	session.start()
	assert_eq(session.min_word_length(), 3)
	session.submit_path(_column(0, "STERNEN"))  # 210 → Level 2
	session.submit_path(_column(1, "ERNST"))    # 310 → Level 3
	assert_eq(session.min_word_length(), 4)
	var cells := _column(0, "TEE")
	assert_false(session.submit_path(cells), "TEE zu kurz ab Level 3")
	assert_signal_emitted_with_parameters(session, "word_rejected", [cells, GameSession.REASON_TOO_SHORT])


func test_level_never_drops() -> void:
	session.start()
	session.submit_path(_column(0, "STERN"))  # 100 → Level 2
	session.request_more_letters()            # −20 → 80
	assert_eq(session.score, 80)
	assert_eq(session.level(), 2)


func test_next_level_score() -> void:
	session.start()
	assert_eq(session.next_level_score(), 100)
	session.submit_path(_column(0, "STERN"))
	assert_eq(session.next_level_score(), 250)


func test_level_up_on_full_board_adds_only_what_fits() -> void:
	session.start()
	for cell in session.grid.all_cells():
		session.grid.set_letter(cell, "X")
	for i in 5:
		session.grid.set_letter(Vector2i(0, i), "STERN"[i])
	var before: int = get_signal_emit_count(session, "tile_spawned")
	session.submit_path(_column(0, "STERN", false))
	# 5 Plätze frei geworden → nur 5 statt 10 neue
	assert_eq(get_signal_emit_count(session, "tile_spawned"), before + 5)
	assert_true(session.grid.is_full())


# --- Knopf „Neue Buchstaben“ ---------------------------------------------------------

func test_refill_brings_3_tiles_for_20_points() -> void:
	session.start()
	session.submit_path(_column(0, "TEE"))  # 30 Punkte
	var before: int = get_signal_emit_count(session, "tile_spawned")
	assert_eq(session.request_more_letters(), 3)
	assert_eq(session.score, 10)
	assert_eq(get_signal_emit_count(session, "tile_spawned"), before + 3)


func test_refill_never_below_zero() -> void:
	session.start()
	assert_eq(session.request_more_letters(), 3)
	assert_eq(session.score, 0)


func test_refill_on_full_board_does_nothing_and_costs_nothing() -> void:
	session.start()
	session.submit_path(_column(0, "TEE"))
	for cell in session.grid.all_cells():
		session.grid.set_letter(cell, "X")
	assert_eq(session.request_more_letters(), 0)
	assert_eq(session.score, 30)


# --- Rundenende --------------------------------------------------------------------

func test_end_round() -> void:
	session.start()
	session.submit_path(_column(0, "STERN"))
	session.end_round()
	assert_true(session.is_over)
	assert_signal_emitted_with_parameters(session, "round_ended", [100, 2])
	assert_false(session.submit_path(_column(0, "TEE")))
	assert_eq(session.request_more_letters(), 0)


func test_end_round_only_once() -> void:
	session.start()
	session.end_round()
	session.end_round()
	assert_signal_emit_count(session, "round_ended", 1)


# --- Wischen -----------------------------------------------------------------------

func test_can_extend_rules() -> void:
	session.start()
	_column(0, "STE")
	session.grid.set_letter(Vector2i(3, 0), "R")
	var path := _path([Vector2i(0, 0)])
	assert_true(session.can_extend(path, Vector2i(0, 1)), "Nachbar")
	assert_false(session.can_extend(path, Vector2i(0, 0)), "schon im Weg")
	assert_false(session.can_extend(path, Vector2i(3, 0)), "kein Nachbar")
	assert_false(session.can_extend(path, Vector2i(1, 0)), "leer")
	assert_true(session.can_extend(_path([]), Vector2i(3, 0)), "Anfang überall auf belegtem Feld")
