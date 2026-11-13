extends GutTest

var balance: GameBalance
var lang: LanguageData


func before_each() -> void:
	balance = GameBalance.new()
	lang = load("res://data/languages/de/language.tres") as LanguageData


func _spawner(seed_value: int = 1) -> Spawner:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var prng := RandomNumberGenerator.new()
	prng.seed = seed_value + 1000
	return Spawner.new(balance, LetterPicker.new(lang, prng), rng)


func _run(s: Spawner, seconds: float, step: float = 0.05) -> int:
	var total := 0
	var t := 0.0
	while t < seconds - 0.00001:
		total += s.tick(step)
		t += step
	return total


# --- Takt ---------------------------------------------------------------------

func test_first_spawn_after_three_seconds() -> void:
	var s := _spawner()
	assert_eq(s.tick(2.9), 0)
	assert_eq(s.tick(0.2), 1)


func test_ten_spawns_in_first_30_seconds() -> void:
	var s := _spawner()
	assert_eq(_run(s, 29.99), 9)
	assert_eq(_run(s, 0.02), 1)  # Sekunde 30


func test_level_rises_and_interval_shrinks() -> void:
	var s := _spawner()
	assert_eq(s.level(), 1)
	_run(s, 30.0)
	assert_eq(s.level(), 2)
	assert_almost_eq(s.current_interval(), 2.7, 0.0001)


func test_large_delta_reports_multiple_spawns() -> void:
	var s := _spawner()
	assert_eq(s.tick(9.0), 3)


func test_zero_or_negative_delta_does_nothing() -> void:
	var s := _spawner()
	assert_eq(s.tick(0.0), 0)
	assert_eq(s.tick(-5.0), 0)
	assert_almost_eq(s.elapsed, 0.0, 0.0001)


func test_interval_reaches_minimum_late_in_game() -> void:
	var s := _spawner()
	_run(s, 30.0 * 20, 0.5)
	assert_almost_eq(s.current_interval(), 0.8, 0.0001)
	assert_eq(s.level(), balance.max_level())


# --- Platzwahl ------------------------------------------------------------------

func test_spawn_into_places_letter_on_candidate() -> void:
	var s := _spawner()
	var grid := HexGrid.new()
	var candidates := grid.spawn_candidates()
	var r := s.spawn_into(grid)
	assert_has(candidates, r["cell"])
	assert_eq(grid.get_letter(r["cell"]), r["letter"])
	assert_has(lang.alphabet, r["letter"])


func test_spawn_into_full_grid_returns_empty() -> void:
	var s := _spawner()
	var grid := HexGrid.new()
	for cell in grid.all_cells():
		grid.set_letter(cell, "A")
	assert_eq(s.spawn_into(grid), {})


func test_spawn_fills_hole_first() -> void:
	var s := _spawner()
	var grid := HexGrid.new()
	for c in 6:
		for r in 3:
			grid.set_letter(Vector2i(c, r), "E")
	grid.clear(Vector2i(4, 1))
	var r := s.spawn_into(grid)
	assert_eq(r["cell"], Vector2i(4, 1))


func test_random_choice_among_equal_candidates() -> void:
	var seen := {}
	for seed_value in range(1, 40):
		var grid := HexGrid.new()
		var r := _spawner(seed_value).spawn_into(grid)
		seen[r["cell"]] = true
	assert_eq(seen.size(), 3, "alle drei tiefsten Plätze kommen vor")
