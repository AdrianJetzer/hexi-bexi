extends GutTest

var grid: HexGrid


func before_each() -> void:
	grid = HexGrid.new(6, 9)


func _fill(cells: Array) -> void:
	for cell in cells:
		grid.set_letter(cell, "A")


# --- Grundlagen ---------------------------------------------------------------

func test_new_grid_is_empty() -> void:
	assert_eq(grid.size(), 54)
	assert_eq(grid.free_count(), 54)
	assert_false(grid.is_full())


func test_set_get_clear() -> void:
	grid.set_letter(Vector2i(2, 3), "Q")
	assert_eq(grid.get_letter(Vector2i(2, 3)), "Q")
	assert_true(grid.is_occupied(Vector2i(2, 3)))
	grid.clear(Vector2i(2, 3))
	assert_true(grid.is_free(Vector2i(2, 3)))


func test_is_inside() -> void:
	assert_true(grid.is_inside(Vector2i(0, 0)))
	assert_true(grid.is_inside(Vector2i(5, 8)))
	assert_false(grid.is_inside(Vector2i(6, 0)))
	assert_false(grid.is_inside(Vector2i(0, 9)))
	assert_false(grid.is_inside(Vector2i(-1, 0)))


func test_full_grid() -> void:
	_fill(grid.all_cells())
	assert_true(grid.is_full())
	assert_eq(grid.free_count(), 0)


# --- Nachbarn ----------------------------------------------------------------

func test_neighbors_even_column_inner() -> void:
	var n := grid.neighbors(Vector2i(2, 4))
	assert_eq(n.size(), 6)
	for expected in [Vector2i(2, 3), Vector2i(2, 5), Vector2i(1, 4), Vector2i(1, 5), Vector2i(3, 4), Vector2i(3, 5)]:
		assert_has(n, expected)


func test_neighbors_odd_column_inner() -> void:
	var n := grid.neighbors(Vector2i(3, 4))
	assert_eq(n.size(), 6)
	for expected in [Vector2i(3, 3), Vector2i(3, 5), Vector2i(2, 3), Vector2i(2, 4), Vector2i(4, 3), Vector2i(4, 4)]:
		assert_has(n, expected)


func test_neighbors_corners_are_clipped() -> void:
	# Spalte 0 (gerade, höher), unten: oben, rechts gleiche Reihe, rechts eine höher
	assert_eq(grid.neighbors(Vector2i(0, 0)).size(), 3)
	# Spalte 5 (ungerade, tiefer), unten: oben, links gleiche Reihe
	assert_eq(grid.neighbors(Vector2i(5, 0)).size(), 2)
	# Spalte 0, oben: unten, rechts gleiche Reihe
	assert_eq(grid.neighbors(Vector2i(0, 8)).size(), 2)


func test_neighbors_are_symmetric_everywhere() -> void:
	for a in grid.all_cells():
		for b in grid.neighbors(a):
			assert_true(grid.are_neighbors(b, a), "%s <-> %s" % [a, b])


func test_neighbors_have_equal_visual_distance() -> void:
	# Mittelpunkte (Hexagon-Radius 1, unten flach): alle Nachbarn gleich weit entfernt.
	for a in grid.all_cells():
		for b in grid.neighbors(a):
			assert_almost_eq(_center(a).distance_to(_center(b)), sqrt(3.0), 0.0001)


func test_non_neighbors() -> void:
	assert_false(grid.are_neighbors(Vector2i(0, 0), Vector2i(2, 0)))
	assert_false(grid.are_neighbors(Vector2i(0, 0), Vector2i(0, 2)))
	assert_false(grid.are_neighbors(Vector2i(0, 0), Vector2i(0, 0)))


func _center(cell: Vector2i) -> Vector2:
	var h := sqrt(3.0)
	var y := cell.y * h + (0.0 if cell.x % 2 == 1 else h / 2.0)
	return Vector2(cell.x * 1.5, y)


# --- Höhe ----------------------------------------------------------------------

func test_odd_columns_are_lower() -> void:
	assert_lt(grid.height_key(Vector2i(1, 0)), grid.height_key(Vector2i(0, 0)))
	assert_lt(grid.height_key(Vector2i(0, 0)), grid.height_key(Vector2i(1, 1)))


# --- Löcher und neue Plätze -----------------------------------------------------

func test_empty_grid_spawns_in_odd_bottom_cells() -> void:
	var c := grid.spawn_candidates()
	assert_eq(c.size(), 3)
	for expected in [Vector2i(1, 0), Vector2i(3, 0), Vector2i(5, 0)]:
		assert_has(c, expected)


func test_stack_tops_do_not_float() -> void:
	_fill([Vector2i(0, 0), Vector2i(0, 1)])
	assert_has(grid.stack_tops(), Vector2i(0, 2))
	assert_does_not_have(grid.stack_tops(), Vector2i(0, 3))


func test_holes_detected() -> void:
	_fill([Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)])
	grid.clear(Vector2i(2, 1))
	assert_eq(grid.holes(), [Vector2i(2, 1)] as Array[Vector2i])


func test_holes_have_priority_over_lower_stack_tops() -> void:
	# Spalte 1 leer (Stapel-Platz ganz unten), aber in Spalte 2 gibt es ein Loch weiter oben.
	_fill([Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3)])
	grid.clear(Vector2i(2, 2))
	assert_eq(grid.spawn_candidates(), [Vector2i(2, 2)] as Array[Vector2i])


func test_lowest_hole_first() -> void:
	_fill([Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)])
	grid.clear(Vector2i(0, 1))
	grid.clear(Vector2i(0, 2))
	assert_eq(grid.spawn_candidates(), [Vector2i(0, 1)] as Array[Vector2i])


func test_no_candidates_when_full() -> void:
	_fill(grid.all_cells())
	assert_true(grid.spawn_candidates().is_empty())


func test_filling_by_candidates_never_floats_and_fills_grid() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in grid.size():
		var c := grid.spawn_candidates()
		assert_false(c.is_empty())
		var cell: Vector2i = c[rng.randi_range(0, c.size() - 1)]
		if cell.y > 0:
			assert_true(grid.is_occupied(Vector2i(cell.x, cell.y - 1)), "schwebt: %s" % cell)
		grid.set_letter(cell, "A")
	assert_true(grid.is_full())
