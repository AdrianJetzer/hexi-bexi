extends GutTest

var lang: LanguageData


func before_each() -> void:
	lang = load("res://data/languages/de/language.tres") as LanguageData


func _spawner(seed_value: int = 1) -> Spawner:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var prng := RandomNumberGenerator.new()
	prng.seed = seed_value + 1000
	return Spawner.new(LetterPicker.new(lang, prng), rng)


func test_spawn_into_places_letter_on_candidate() -> void:
	var s := _spawner()
	var grid := HexGrid.new(6, 9)
	var candidates := grid.spawn_candidates()
	var r := s.spawn_into(grid)
	assert_has(candidates, r["cell"])
	assert_eq(grid.get_letter(r["cell"]), r["letter"])
	assert_has(lang.alphabet, r["letter"])


func test_spawn_into_full_grid_returns_empty() -> void:
	var s := _spawner()
	var grid := HexGrid.new(6, 9)
	for cell in grid.all_cells():
		grid.set_letter(cell, "A")
	assert_eq(s.spawn_into(grid), {})


func test_spawn_fills_hole_first() -> void:
	var s := _spawner()
	var grid := HexGrid.new(6, 9)
	for c in 6:
		for r in 3:
			grid.set_letter(Vector2i(c, r), "E")
	grid.clear(Vector2i(4, 1))
	var r := s.spawn_into(grid)
	assert_eq(r["cell"], Vector2i(4, 1))


func test_random_choice_among_equal_candidates() -> void:
	var seen := {}
	for seed_value in range(1, 40):
		var grid := HexGrid.new(6, 9)
		var r := _spawner(seed_value).spawn_into(grid)
		seen[r["cell"]] = true
	assert_eq(seen.size(), 3, "alle drei tiefsten Plätze kommen vor")
