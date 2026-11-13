extends GutTest


# --- Punkte -------------------------------------------------------------------

func test_points_table_from_spec() -> void:
	var expected := {3: 30, 4: 60, 5: 100, 6: 150, 7: 210, 8: 280}
	for n in expected:
		assert_eq(Scoring.word_points(n), expected[n], "Länge %d" % n)


func test_points_use_factor() -> void:
	assert_eq(Scoring.word_points(3, 10), 60)


func test_points_zero_for_empty() -> void:
	assert_eq(Scoring.word_points(0), 0)


# --- Spielwerte ------------------------------------------------------------------

func test_balance_file_loads_with_spec_values() -> void:
	var b := load("res://data/balance.tres") as GameBalance
	assert_not_null(b)
	assert_eq(b.grid_cols, 5)
	assert_eq(b.grid_rows, 9)
	assert_eq(b.start_tiles, 15)
	assert_eq(b.first_threshold, 100)
	assert_almost_eq(b.threshold_growth, 1.5, 0.0001)
	assert_eq(b.tiles_per_level, 10)
	assert_eq(b.refill_tiles, 3)
	assert_eq(b.refill_cost, 20)
	assert_eq(b.points_factor, 5)


func test_balance_run_values_from_spec() -> void:
	var b := load("res://data/balance.tres") as GameBalance
	assert_eq(b.run_start_tiles, 20)
	assert_eq(b.start_coins, 0)
	assert_eq(b.min_length, 3)
	assert_eq(b.refill_count, 5)
	assert_eq(b.refill_price, 100)
	assert_eq(b.refill_price_step, 25)
	assert_eq(b.swap_count, 5)
	assert_eq(b.swap_price, 50)
	assert_eq(b.hint_price, 100)
	assert_eq(b.replace_price, 100)


func test_thresholds_grow_by_half() -> void:
	var b := load("res://data/balance.tres") as GameBalance
	assert_eq(b.threshold(1), 0)
	assert_eq(b.threshold(2), 100)
	assert_eq(b.threshold(3), 250)
	assert_eq(b.threshold(4), 475)
	assert_eq(b.threshold(5), 812)


func test_min_length_by_level() -> void:
	var b := load("res://data/balance.tres") as GameBalance
	var expected := {1: 3, 2: 3, 3: 4, 4: 4, 5: 5, 6: 5, 20: 5}
	for level in expected:
		assert_eq(b.min_word_length(level), expected[level], "Level %d" % level)
