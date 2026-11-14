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
	# Preise (spec/run-mode.md, „Münzen“), 25er-Schritte; Auffüllen gratis.
	var prices := {"refill_price": 0, "solve_price": 400, "magnet_price": 150, "split_price": 125,
		"joker_price": 100, "swap_price": 100, "scan_price": 75, "column_price": 50, "clear_price": 50,
		"hint_price": 25, "replace_price": 25, "shuffle_price": 25, "gravity_price": 25}
	for p in prices:
		assert_eq(b.get(p), prices[p], p)
	assert_eq(b.auto_refill_less, 1)
	assert_eq(b.swap_count, 5)
	assert_eq(b.split_min_length, 6)

