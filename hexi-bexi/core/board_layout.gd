class_name BoardLayout
extends RefCounted
## Geometrie des Spielfelds auf dem Bildschirm (reine Mathematik, keine Nodes).
##
## Hexagons sind unten flach. Ungerade Spalten liegen ein halbes Feld tiefer
## (passend zu HexGrid). Bildschirm-y zeigt nach unten.

var cols: int
var rows: int
## Außenradius eines Hexagons (Mitte bis Ecke) in Pixeln.
var radius: float
## Linke obere Ecke des Rasters (Begrenzungsrechteck aller Hexagons).
var origin: Vector2


func _init(p_cols: int, p_rows: int, p_radius: float, p_origin: Vector2 = Vector2.ZERO) -> void:
	cols = p_cols
	rows = p_rows
	radius = p_radius
	origin = p_origin


## Größtes Raster, das in rect passt, mittig ausgerichtet.
static func fit(p_cols: int, p_rows: int, rect: Rect2) -> BoardLayout:
	var r_w := rect.size.x / (1.5 * (p_cols - 1) + 2.0)
	var r_h := rect.size.y / ((p_rows + 0.5) * sqrt(3.0))
	var r := minf(r_w, r_h)
	var layout := BoardLayout.new(p_cols, p_rows, r)
	var s := layout.grid_size()
	layout.origin = rect.position + (rect.size - s) / 2.0
	return layout


## Höhe eines Hexagons (flache Seite bis flache Seite).
func hex_height() -> float:
	return sqrt(3.0) * radius


## Innenradius (Mitte bis flache Seite).
func inner_radius() -> float:
	return hex_height() / 2.0


func grid_size() -> Vector2:
	return Vector2(radius * (1.5 * (cols - 1) + 2.0), hex_height() * (rows + 0.5))


func grid_rect() -> Rect2:
	return Rect2(origin, grid_size())


## Mittelpunkt eines Platzes in Pixeln.
func center(cell: Vector2i) -> Vector2:
	var h := hex_height()
	var bottom := origin.y + grid_size().y
	var x := origin.x + radius + cell.x * 1.5 * radius
	var y := bottom - (h / 2.0 if cell.x % 2 == 1 else h) - cell.y * h
	return Vector2(x, y)


## Platz unter einem Punkt, oder Vector2i(-1, -1).
## tolerance: Anteil des Innenradius, ab dem ein Hexagon zählt (0.8 = 80 %).
func cell_at(point: Vector2, tolerance: float = 0.8) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_dist := INF
	for c in cols:
		for r in rows:
			var cell := Vector2i(c, r)
			var d := point.distance_to(center(cell))
			if d < best_dist:
				best_dist = d
				best = cell
	if best_dist <= inner_radius() * tolerance:
		return best
	return Vector2i(-1, -1)


## Ecken eines Hexagons (unten flach) um einen Mittelpunkt.
static func hex_points(at: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 6:
		var a := PI / 3.0 * i
		pts.append(at + Vector2(cos(a), sin(a)) * r)
	return pts


## Umriss aller Plätze zusammen (Zickzack-Innenkante des Rahmens), im Uhrzeigersinn.
func inner_contour() -> PackedVector2Array:
	var h := hex_height()
	var r := radius
	var p := PackedVector2Array()
	var last := cols - 1
	# oben, links nach rechts
	for c in cols:
		var top := center(Vector2i(c, rows - 1))
		p.append(top + Vector2(-r / 2.0, -h / 2.0))
		p.append(top + Vector2(r / 2.0, -h / 2.0))
	# rechte Seite, oben nach unten
	for row in range(rows - 1, -1, -1):
		var m := center(Vector2i(last, row))
		p.append(m + Vector2(r, 0))
		p.append(m + Vector2(r / 2.0, h / 2.0))
	# unten, rechts nach links
	var bottom_last := center(Vector2i(last, 0))
	p.append(bottom_last + Vector2(-r / 2.0, h / 2.0))
	for c in range(last - 1, -1, -1):
		var m := center(Vector2i(c, 0))
		p.append(m + Vector2(r / 2.0, h / 2.0))
		p.append(m + Vector2(-r / 2.0, h / 2.0))
	# linke Seite, unten nach oben
	for row in rows:
		var m := center(Vector2i(0, row))
		p.append(m + Vector2(-r, 0))
		if row < rows - 1:
			p.append(m + Vector2(-r / 2.0, -h / 2.0))
	return p
