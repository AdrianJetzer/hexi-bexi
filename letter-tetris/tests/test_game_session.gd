extends GutTest

var balance: GameBalance
var lang: LanguageData
var dict: WordDictionary
var session: GameSession


func before_each() -> void:
	balance = GameBalance.new()
	lang = load("res://data/languages/de/language.tres") as LanguageData
	dict = WordDictionary.from_words(PackedStringArray(["STERN", "STERNE", "TEE", "HAUS"]))
	session = GameSession.new(balance, lang, dict, 42)
	watch_signals(session)


## Feld mit festen Buchstaben belegen (Spalte 0, von unten nach oben).
func _column(c: int, letters: String) -> Array[Vector2i]:
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

func test_start_fills_two_rows() -> void:
	session.start()
	assert_eq(session.grid.size() - session.grid.free_count(), 12)
	for c in 6:
		for r in 2:
			assert_true(session.grid.is_occupied(Vector2i(c, r)), "Startreihen: %s" % Vector2i(c, r))
	assert_signal_emit_count(session, "tile_spawned", 12)
	assert_eq(session.score, 0)
	assert_false(session.is_over)


func test_same_seed_same_start() -> void:
	var other := GameSession.new(balance, lang, dict, 42)
	session.start()
	other.start()
	for cell in session.grid.all_cells():
		assert_eq(session.grid.get_letter(cell), other.grid.get_letter(cell))


# --- Takt ------------------------------------------------------------------------

func test_update_spawns_on_time() -> void:
	session.start()
	session.update(2.9)
	assert_signal_emit_count(session, "tile_spawned", 12)
	session.update(0.2)
	assert_signal_emit_count(session, "tile_spawned", 13)


func test_pause_stops_time() -> void:
	session.start()
	session.pause()
	session.update(100.0)
	assert_signal_emit_count(session, "tile_spawned", 12)
	session.resume()
	session.update(3.1)
	assert_signal_emit_count(session, "tile_spawned", 13)


func test_level_changed_signal() -> void:
	session.start()
	for i in 60:
		session.update(0.5)
	assert_eq(session.level(), 2)
	assert_signal_emitted_with_parameters(session, "level_changed", [2])


func test_game_over_when_full() -> void:
	session.start()
	for i in 2000:
		session.update(0.5)
		if session.is_over:
			break
	assert_true(session.is_over)
	assert_true(session.grid.is_full())
	assert_signal_emit_count(session, "game_over", 1)


func test_no_spawns_after_game_over() -> void:
	session.start()
	for i in 2000:
		session.update(0.5)
	var spawned: int = get_signal_emit_count(session, "tile_spawned")
	session.update(100.0)
	assert_eq(get_signal_emit_count(session, "tile_spawned"), spawned)


func test_abort_ends_without_game_over_signal() -> void:
	session.start()
	session.abort()
	assert_true(session.is_over)
	assert_signal_not_emitted(session, "game_over")


# --- Wörter ------------------------------------------------------------------------

func test_valid_word_is_removed_and_scored() -> void:
	var cells := _column(0, "STERN")
	assert_true(session.submit_path(cells))
	for cell in cells:
		assert_true(session.grid.is_free(cell))
	assert_eq(session.score, 100)
	assert_eq(session.last_word, "STERN")
	assert_eq(session.last_points, 100)
	assert_eq(session.words_found, 1)
	assert_signal_emitted_with_parameters(session, "word_accepted", ["STERN", cells, 100])


func test_holes_stay_open_after_word() -> void:
	var cells := _column(0, "TEEX")  # TEE unten, X darüber
	assert_true(session.submit_path(cells.slice(0, 3)))
	assert_eq(session.grid.get_letter(Vector2i(0, 3)), "X", "nichts rutscht nach")
	assert_eq(session.grid.holes().size(), 3)


func test_unknown_word_changes_nothing() -> void:
	var cells := _column(0, "STERX")
	assert_false(session.submit_path(cells))
	assert_eq(session.score, 0)
	for cell in cells:
		assert_true(session.grid.is_occupied(cell))
	assert_signal_emitted_with_parameters(session, "word_rejected", [cells, GameSession.REASON_NOT_A_WORD])


func test_too_short_is_rejected() -> void:
	var cells := _column(0, "TE")
	assert_false(session.submit_path(cells))
	assert_signal_emitted_with_parameters(session, "word_rejected", [cells, GameSession.REASON_TOO_SHORT])


func test_non_neighbors_are_rejected() -> void:
	_column(0, "TEE")
	session.grid.set_letter(Vector2i(4, 0), "E")
	var path := _path([Vector2i(0, 0), Vector2i(0, 1), Vector2i(4, 0)])
	assert_false(session.submit_path(path))
	assert_signal_emitted_with_parameters(session, "word_rejected", [path, GameSession.REASON_INVALID_PATH])


func test_same_hexagon_twice_is_rejected() -> void:
	_column(0, "TE")
	var path := _path([Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 1)])
	assert_false(session.submit_path(path))


func test_word_across_columns() -> void:
	# H(0,0) A(1,0) U(1,1) S(2,1): Nachbarn über Spaltengrenzen
	session.grid.set_letter(Vector2i(0, 0), "H")
	session.grid.set_letter(Vector2i(1, 0), "A")
	session.grid.set_letter(Vector2i(1, 1), "U")
	session.grid.set_letter(Vector2i(2, 1), "S")
	var path := _path([Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)])
	assert_true(session.submit_path(path))
	assert_eq(session.score, 60)


func test_can_extend_rules() -> void:
	_column(0, "STE")
	session.grid.set_letter(Vector2i(3, 0), "R")
	var path := _path([Vector2i(0, 0)])
	assert_true(session.can_extend(path, Vector2i(0, 1)), "Nachbar")
	assert_false(session.can_extend(path, Vector2i(0, 0)), "schon im Weg")
	assert_false(session.can_extend(path, Vector2i(3, 0)), "kein Nachbar")
	assert_false(session.can_extend(path, Vector2i(1, 0)), "leer")
	assert_true(session.can_extend(_path([]), Vector2i(3, 0)), "Anfang überall auf belegtem Feld")


func test_submit_after_game_over_is_rejected() -> void:
	var cells := _column(0, "TEE")
	session.abort()
	assert_false(session.submit_path(cells))
