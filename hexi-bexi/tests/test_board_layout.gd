extends GutTest

var layout: BoardLayout
var grid: HexGrid


func before_each() -> void:
	layout = BoardLayout.fit(6, 9, Rect2(0, 0, 900, 1400))
	grid = HexGrid.new(6, 9)


func test_fit_stays_inside_rect() -> void:
	var rect := Rect2(50, 100, 900, 1400)
	var l := BoardLayout.fit(6, 9, rect)
	assert_true(rect.grow(0.01).encloses(l.grid_rect()))


func test_fit_uses_width_on_tall_screens() -> void:
	# 9,5 Radien Breite bei 6 Spalten
	var tall := BoardLayout.fit(6, 9, Rect2(0, 0, 900, 2000))
	assert_almost_eq(tall.radius, 900.0 / 9.5, 0.001)


func test_fit_uses_height_on_wide_screens() -> void:
	# 9 Reihen + halbe Reihe Versatz
	assert_almost_eq(layout.radius, 1400.0 / (9.5 * sqrt(3.0)), 0.001)


func test_fit_is_centered() -> void:
	var rect := Rect2(0, 0, 900, 1400)
	var g := layout.grid_rect()
	assert_almost_eq(g.position.y - rect.position.y, rect.end.y - g.end.y, 0.001)


func test_neighbor_centers_touch() -> void:
	for a in grid.all_cells():
		for b in grid.neighbors(a):
			assert_almost_eq(layout.center(a).distance_to(layout.center(b)), layout.hex_height(), 0.001)


func test_odd_columns_drawn_lower() -> void:
	assert_gt(layout.center(Vector2i(1, 0)).y, layout.center(Vector2i(0, 0)).y)


func test_all_hexagons_inside_grid_rect() -> void:
	var g := layout.grid_rect().grow(0.01)
	for cell in grid.all_cells():
		for p in BoardLayout.hex_points(layout.center(cell), layout.radius):
			assert_true(g.has_point(p), "%s" % cell)


func test_cell_at_center_returns_cell() -> void:
	for cell in grid.all_cells():
		assert_eq(layout.cell_at(layout.center(cell)), cell)


func test_cell_at_near_edge_is_ignored() -> void:
	var cell := Vector2i(2, 4)
	var c := layout.center(cell)
	var near := c + Vector2(0, layout.inner_radius() * 0.7)
	var edge := c + Vector2(0, layout.inner_radius() * 0.95)
	assert_eq(layout.cell_at(near), cell)
	assert_eq(layout.cell_at(edge), Vector2i(-1, -1))


func test_cell_at_outside_returns_none() -> void:
	assert_eq(layout.cell_at(Vector2(-500, -500)), Vector2i(-1, -1))


func test_inner_contour_encloses_all_centers() -> void:
	var contour := layout.inner_contour()
	assert_gt(contour.size(), 10)
	for cell in grid.all_cells():
		assert_true(Geometry2D.is_point_in_polygon(layout.center(cell), contour), "%s" % cell)


func test_inner_contour_area_equals_all_hexagons() -> void:
	# Fläche eines Hexagons = 3·√3/2 · r²
	var hex_area := 3.0 * sqrt(3.0) / 2.0 * layout.radius * layout.radius
	assert_almost_eq(_area(layout.inner_contour()), hex_area * 54, hex_area * 0.001)


func _area(p: PackedVector2Array) -> float:
	var a := 0.0
	for i in p.size():
		var j := (i + 1) % p.size()
		a += p[i].x * p[j].y - p[j].x * p[i].y
	return absf(a) / 2.0
