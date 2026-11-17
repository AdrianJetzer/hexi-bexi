extends GutTest


# --- Spielwerte ------------------------------------------------------------------

func test_balance_file_loads_with_spec_values() -> void:
	var b := load("res://data/balance.tres") as GameBalance
	assert_not_null(b)
	assert_eq(b.grid_cols, 5)
	assert_eq(b.grid_rows, 5)


func test_balance_run_values_from_spec() -> void:
	var b := load("res://data/balance.tres") as GameBalance
	assert_eq(b.run_start_tiles, 10)
	assert_eq(b.start_coins, 0)
	assert_eq(b.min_length, 3)
	assert_eq(b.refill_count, 5)
	# Preise (spec/run-mode.md, „Münzen“); Auffüllen gratis.
	var prices := {"refill_price": 0,
		"replace_price": 50, "shuffle_price": 50,
		"clear_price": 100, "joker_price": 100, "shorten_price": 100, "hint_price": 100,
		"swap_price": 150, "split_price": 150, "complete_price": 150,
		"magnet_price": 200, "scan_price": 200, "strike_price": 200,
		"solve_price": 500}
	for p in prices:
		assert_eq(b.get(p), prices[p], p)
	assert_eq(b.auto_refill_less, 1)
	assert_eq(b.swap_count, 5)
	assert_eq(b.split_min_length, 6)
	assert_eq(b.complete_min_prefix, 2)

