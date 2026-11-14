extends GutTest


# --- Spielwerte ------------------------------------------------------------------

func test_balance_file_loads_with_spec_values() -> void:
	var b := load("res://data/balance.tres") as GameBalance
	assert_not_null(b)
	assert_eq(b.grid_cols, 5)
	assert_eq(b.grid_rows, 9)


func test_balance_run_values_from_spec() -> void:
	var b := load("res://data/balance.tres") as GameBalance
	assert_eq(b.run_start_tiles, 10)
	assert_eq(b.start_coins, 0)
	assert_eq(b.min_length, 3)
	assert_eq(b.refill_count, 5)
	assert_eq(b.refill_price, 100)
	assert_eq(b.auto_refill_less, 1)
	assert_eq(b.swap_count, 5)
	assert_eq(b.swap_price, 50)
	assert_eq(b.hint_price, 100)
	assert_eq(b.replace_price, 100)
	assert_eq(b.solve_price, 500)

