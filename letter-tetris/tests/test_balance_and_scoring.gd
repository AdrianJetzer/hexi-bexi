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
	assert_eq(b.grid_cols, 6)
	assert_eq(b.grid_rows, 9)
	assert_eq(b.start_rows, 2)
	assert_eq(b.min_word_length, 3)
	assert_almost_eq(b.spawn_interval_start, 3.0, 0.0001)
	assert_almost_eq(b.speedup_every, 30.0, 0.0001)
	assert_almost_eq(b.speedup_factor, 0.9, 0.0001)
	assert_almost_eq(b.spawn_interval_min, 0.8, 0.0001)
	assert_eq(b.points_factor, 5)


func test_interval_per_level() -> void:
	var b := GameBalance.new()
	assert_almost_eq(b.interval_for_level(1), 3.0, 0.0001)
	assert_almost_eq(b.interval_for_level(2), 2.7, 0.0001)
	assert_almost_eq(b.interval_for_level(3), 2.43, 0.0001)


func test_interval_never_below_minimum() -> void:
	var b := GameBalance.new()
	for level in range(1, 100):
		assert_true(b.interval_for_level(level) >= b.spawn_interval_min - 0.00001)
	assert_almost_eq(b.interval_for_level(b.max_level()), 0.8, 0.0001)
	assert_gt(b.interval_for_level(b.max_level() - 1), 0.8)


func test_level_increases_every_30_seconds() -> void:
	var b := GameBalance.new()
	assert_eq(b.level_at(0.0), 1)
	assert_eq(b.level_at(29.9), 1)
	assert_eq(b.level_at(30.0), 2)
	assert_eq(b.level_at(65.0), 3)


func test_level_stops_at_max() -> void:
	var b := GameBalance.new()
	assert_eq(b.level_at(100000.0), b.max_level())
