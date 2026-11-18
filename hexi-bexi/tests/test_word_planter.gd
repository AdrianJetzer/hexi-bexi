extends GutTest


func _planter(seed_value: int = 1) -> WordPlanter:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return WordPlanter.new(rng)


func _column(grid: HexGrid, c: int, letters: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for i in letters.length():
		grid.set_letter(Vector2i(c, i), letters[i])
		cells.append(Vector2i(c, i))
	return cells


func test_finds_chain_with_fewest_changes() -> void:
	var words := WordDictionary.from_words(PackedStringArray(["STERN", "HAUS"]))
	var grid := HexGrid.new()
	_column(grid, 0, "STERX")
	var plan := _planter().plant(grid, words, PackedInt32Array([5]), 5)
	assert_false(plan.is_empty())
	assert_eq(plan["word"], "STERN")
	assert_eq(plan["changes"], 1, "nur das X muss zum N werden")


func test_any_word_fits_a_chain_up_to_max_changes() -> void:
	var words := WordDictionary.from_words(PackedStringArray(["STERN"]))
	var grid := HexGrid.new()
	_column(grid, 0, "WABUH")
	var plan := _planter().plant(grid, words, PackedInt32Array([5]), 5)
	assert_eq(plan["word"], "STERN")
	assert_eq(plan["changes"], 5)
	var path: Array = plan["path"]
	for i in range(1, path.size()):
		assert_true(grid.are_neighbors(path[i - 1], path[i]), "Kette aus Nachbarn")


func test_impossible_with_too_few_tiles() -> void:
	var words := WordDictionary.from_words(PackedStringArray(["STERN"]))
	var grid := HexGrid.new()
	_column(grid, 0, "STER")
	assert_true(_planter().plant(grid, words, PackedInt32Array([5]), 5).is_empty())


func test_impossible_when_too_many_changes_needed() -> void:
	var words := WordDictionary.from_words(PackedStringArray(["STERNE"]))
	var grid := HexGrid.new()
	_column(grid, 0, "XXXXXX")
	assert_true(_planter().plant(grid, words, PackedInt32Array([6]), 5).is_empty(), "6 Änderungen nötig")


func test_plant_around_keeps_center_letter() -> void:
	var words := WordDictionary.from_words(PackedStringArray(["STERN", "HAUS"]))
	var grid := HexGrid.new()
	var cells := _column(grid, 0, "XXXRX")
	var plan := _planter().plant_around(grid, words, PackedInt32Array([5]), cells[3], "R")
	assert_false(plan.is_empty())
	assert_eq(plan["word"], "STERN")
	var path: Array = plan["path"]
	assert_eq(path.find(cells[3]), 3, "R steht an der R-Stelle von STERN")


func test_plant_around_impossible_with_too_few_tiles() -> void:
	var words := WordDictionary.from_words(PackedStringArray(["STERN"]))
	var grid := HexGrid.new()
	var cells := _column(grid, 0, "RX")
	assert_true(_planter().plant_around(grid, words, PackedInt32Array([5]), cells[0], "R").is_empty())
