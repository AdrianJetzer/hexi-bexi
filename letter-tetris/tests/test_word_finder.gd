extends GutTest

var grid: HexGrid
var dict: WordDictionary


func before_each() -> void:
	grid = HexGrid.new(6, 9)
	dict = WordDictionary.from_words(PackedStringArray(["TEE", "TEER", "REET", "STERN", "NEST", "ERNST", "XYZ"]))


func _column(c: int, letters: String) -> void:
	for i in letters.length():
		grid.set_letter(Vector2i(c, i), letters[i])


# --- Abstand (HexGrid) ---------------------------------------------------------

func test_distance_basics() -> void:
	assert_eq(grid.distance(Vector2i(0, 0), Vector2i(0, 0)), 0)
	for nb in grid.neighbors(Vector2i(2, 4)):
		assert_eq(grid.distance(Vector2i(2, 4), nb), 1)
	assert_eq(grid.distance(Vector2i(0, 0), Vector2i(0, 5)), 5)


func test_distance_symmetric() -> void:
	for a in [Vector2i(0, 0), Vector2i(3, 4), Vector2i(5, 8)]:
		for b in grid.all_cells():
			assert_eq(grid.distance(a, b), grid.distance(b, a))


# --- Wörter im Feld --------------------------------------------------------------

func test_finds_words_in_column() -> void:
	_column(0, "STERN")
	var w := WordFinder.new(dict).words_on_board(grid)
	assert_true(w.has("STERN"))
	assert_false(w.has("NEST"), "Buchstaben nicht benachbart in dieser Reihenfolge")


func test_finds_words_in_both_directions() -> void:
	_column(0, "TEER")
	var w := WordFinder.new(dict).words_on_board(grid)
	assert_true(w.has("TEE"))
	assert_true(w.has("TEER"))
	assert_true(w.has("REET"), "rückwärts gewischt")


func test_no_hexagon_twice() -> void:
	_column(0, "TE")  # TEE bräuchte das E zweimal
	assert_false(WordFinder.new(dict).words_on_board(grid).has("TEE"))


func test_respects_min_and_max_length() -> void:
	_column(0, "STERN")
	var short := WordFinder.new(dict, 3, 4).words_on_board(grid)
	assert_false(short.has("STERN"))


func test_words_through_cell() -> void:
	_column(0, "TEER")
	_column(2, "NEST")
	var f := WordFinder.new(dict)
	var through := f.words_through(grid, Vector2i(2, 3))  # das T von NEST
	assert_true(through.has("NEST"))
	assert_false(through.has("TEER"))
	assert_true(f.words_through(grid, Vector2i(0, 3)).has("TEER"))


func test_words_through_equals_filtered_board_search() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var letters := "STERNE"
	for cell in grid.all_cells():
		if cell.y < 4:
			grid.set_letter(cell, letters[rng.randi_range(0, letters.length() - 1)])
	var f := WordFinder.new(dict)
	var target := Vector2i(3, 2)
	var through := f.words_through(grid, target)
	# Gegenprobe: jedes gefundene Wort muss auch im ganzen Feld vorkommen
	var all := f.words_on_board(grid)
	for w in through:
		assert_true(all.has(w), w)
	assert_gt(all.size(), 0)


func test_words_for_letters_matches_setting_each_letter() -> void:
	_column(0, "TE")
	_column(1, "SNE")
	_column(2, "RT")
	var target := Vector2i(0, 2)  # frei, direkt über „TE“
	var letters := PackedStringArray(["E", "R", "S", "T", "N", "X"])
	var f := WordFinder.new(dict)
	var by_letter := f.words_for_letters(grid, target, letters)
	for l in letters:
		grid.set_letter(target, l)
		var expected := f.words_through(grid, target)
		grid.clear(target)
		assert_eq(by_letter[l].keys().size(), expected.keys().size(), "Buchstabe %s" % l)
		for w in expected:
			assert_true(by_letter[l].has(w), "%s: %s" % [l, w])
	assert_true(by_letter["E"].has("TEE"), "T-E-E senkrecht")


func test_free_cell_has_no_words() -> void:
	assert_true(WordFinder.new(dict).words_through(grid, Vector2i(0, 0)).is_empty())


func test_speed_with_real_common_words() -> void:
	var lang := load("res://data/languages/de/language.tres") as LanguageData
	var common := WordDictionary.from_file(lang.common_words_path)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var picker := LetterPicker.new(lang, rng)
	for cell in grid.all_cells():
		if cell.y < 5:
			grid.set_letter(cell, picker.pick(PackedStringArray()))
	var f := WordFinder.new(common, 3, 7)
	var t0 := Time.get_ticks_usec()
	var all := f.words_on_board(grid)
	var t1 := Time.get_ticks_usec()
	var through := f.words_through(grid, Vector2i(2, 4))
	var t2 := Time.get_ticks_usec()
	var t3 := Time.get_ticks_usec()
	f.words_on_board(grid)
	var t4 := Time.get_ticks_usec()
	var f6 := WordFinder.new(common, 3, 6)
	f6.words_on_board(grid)
	var t5 := Time.get_ticks_usec()
	f6.words_on_board(grid)
	var t6 := Time.get_ticks_usec()
	var free_cell := grid.spawn_candidates()[0]
	var t7 := Time.get_ticks_usec()
	f6.words_for_letters(grid, free_cell, lang.alphabet)
	var t8 := Time.get_ticks_usec()
	f6.words_for_letters(grid, free_cell, lang.alphabet)
	var t9 := Time.get_ticks_usec()
	gut.p("26 Buchstaben für einen Platz: kalt %.1f ms, warm %.1f ms" % [(t8 - t7) / 1000.0, (t9 - t8) / 1000.0])
	gut.p("Feld 30 Buchstaben: %d Wörter in %.1f ms (warm %.1f ms, max6 kalt %.1f / warm %.1f); durch einen Platz: %d in %.1f ms" % [
		all.size(), (t1 - t0) / 1000.0, (t4 - t3) / 1000.0, (t5 - t4) / 1000.0, (t6 - t5) / 1000.0,
		through.size(), (t2 - t1) / 1000.0])
	assert_gt(all.size(), 0)
