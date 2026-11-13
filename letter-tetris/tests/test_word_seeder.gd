extends GutTest


func _seeder(seed_value: int = 1) -> WordSeeder:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return WordSeeder.new(rng)


func _fill(grid: HexGrid, letter: String = "E") -> void:
	for cell in grid.all_cells():
		grid.set_letter(cell, letter)


func _assert_chain(grid: HexGrid, chain: Array[Vector2i], word: String) -> void:
	assert_eq(chain.size(), word.length())
	var seen := {}
	for i in chain.size():
		assert_false(seen.has(chain[i]), "Platz doppelt")
		seen[chain[i]] = true
		if i > 0:
			assert_true(grid.are_neighbors(chain[i - 1], chain[i]), "nicht benachbart")


func _assert_nothing_floats(grid: HexGrid) -> void:
	for cell in grid.all_cells():
		if grid.is_occupied(cell) and cell.y > 0:
			assert_true(grid.is_occupied(Vector2i(cell.x, cell.y - 1)), "schwebt: %s" % cell)


# --- Kette ------------------------------------------------------------------------

func test_full_board_uses_existing_tiles() -> void:
	var grid := HexGrid.new()
	_fill(grid)
	var changes := _seeder().seed(grid, "HIMMEL")
	assert_eq(changes.size(), 6)
	for ch in changes:
		assert_false(ch["new"], "kein neuer Stein nötig")
	var finder := WordFinder.new(WordDictionary.from_words(PackedStringArray(["HIMMEL"])))
	var found := finder.find_paths(grid, 6, 6, func(w: String) -> bool: return w == "HIMMEL")
	assert_false(found.is_empty(), "HIMMEL ist wischbar")
	_assert_chain(grid, found[0]["path"], "HIMMEL")


func test_sparse_board_adds_tiles_without_floating() -> void:
	var grid := HexGrid.new()
	grid.set_letter(Vector2i(2, 0), "A")
	grid.set_letter(Vector2i(3, 0), "B")
	var changes := _seeder(3).seed(grid, "STERNE")
	assert_eq(changes.size(), 6)
	var new_count := 0
	for ch in changes:
		if ch["new"]:
			new_count += 1
	assert_true(new_count >= 4, "nur 2 Steine vorhanden")
	_assert_nothing_floats(grid)


func test_empty_board_works() -> void:
	var grid := HexGrid.new()
	var changes := _seeder(5).seed(grid, "HAUS")
	assert_eq(changes.size(), 4)
	_assert_nothing_floats(grid)


func test_prefers_existing_tiles() -> void:
	# Genug zusammenhängende Steine für das Wort: keiner soll neu sein.
	var grid := HexGrid.new()
	for c in grid.cols:
		for r in 2:
			grid.set_letter(Vector2i(c, r), "E")
	for s in 10:
		var g := HexGrid.new()
		for cell in grid.all_cells():
			if grid.is_occupied(cell):
				g.set_letter(cell, "E")
		for ch in _seeder(s).seed(g, "STERN"):
			assert_false(ch["new"], "Seed %d" % s)


func test_chains_vary() -> void:
	var chains := {}
	for s in 20:
		var grid := HexGrid.new()
		_fill(grid)
		chains[str(_seeder(s).find_chain(grid, "STERN"))] = true
	assert_true(chains.size() > 5, "Kette soll zufällig verlaufen")


func test_find_chain_does_not_change_grid() -> void:
	var grid := HexGrid.new()
	_fill(grid, "E")
	_seeder().find_chain(grid, "HAUS")
	for cell in grid.all_cells():
		assert_eq(grid.get_letter(cell), "E")


# --- Zielwort ---------------------------------------------------------------------

func test_pick_target_has_length_and_is_valid() -> void:
	var common := WordDictionary.from_words(PackedStringArray(["HAUS", "BAUM", "ZZZZ", "STERN"]))
	var valid := WordDictionary.from_words(PackedStringArray(["HAUS", "BAUM", "STERN"]))
	var s := _seeder()
	for i in 20:
		var w := s.pick_target(common, valid, 4)
		assert_true(w == "HAUS" or w == "BAUM", w)
	assert_eq(s.pick_target(common, valid, 7), "")


func test_dictionary_words_by_length() -> void:
	var d := WordDictionary.from_words(PackedStringArray(["HAUS", "BAUM", "AST"]))
	assert_eq(d.count_of_length(4), 2)
	assert_eq(d.count_of_length(3), 1)
	assert_eq(d.count_of_length(9), 0)
	assert_eq(d.word_at(4, 0), "BAUM")
	assert_eq(d.word_at(4, 1), "HAUS")
	assert_eq(d.word_at(4, 2), "")
