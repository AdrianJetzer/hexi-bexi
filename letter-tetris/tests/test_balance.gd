extends GutTest


# --- Spielwerte ------------------------------------------------------------------

func test_balance_file_loads_with_spec_values() -> void:
	var b := load("res://data/balance.tres") as GameBalance
	assert_not_null(b)
	assert_eq(b.grid_cols, 5)
	assert_eq(b.grid_rows, 6)


func test_balance_run_values_from_spec() -> void:
	var b := load("res://data/balance.tres") as GameBalance
	assert_eq(b.run_start_tiles, 10)
	assert_eq(b.start_coins, 0)
	assert_eq(b.min_length, 3)
	assert_eq(b.refill_count, 5)
	# Preise: zum Testen vorläufig alle 50 (werden am Schluss abgestimmt).
	# Auffüllen ist gratis (siehe spec/run-mode.md).
	assert_eq(b.refill_price, 0)
	for p in ["swap_price", "clear_price", "hint_price", "replace_price", "solve_price",
			"joker_price", "shuffle_price", "gravity_price", "magnet_price", "column_price",
			"split_price", "scan_price"]:
		assert_eq(b.get(p), 50, p)
	assert_eq(b.auto_refill_less, 1)
	assert_eq(b.swap_count, 5)
	assert_eq(b.split_min_length, 6)

