class_name GlyphIcon
extends Control
## Schlichtes Linien-Symbol für Symbol-Knöpfe (spec/screens.md): „close“ = Kreuz (Aufgeben),
## „menu“ = drei Striche, „home“ = Haus (Home-Screen). Gezeichnet statt Bilddatei, damit es auf jedem Display
## scharf bleibt. Füllt das Elternelement; die Symbolgröße ist ein Anteil der kleineren Seite.

var kind: String = "close":
	set(v):
		kind = v
		queue_redraw()
var color: Color = Color(1, 1, 1):
	set(v):
		color = v
		queue_redraw()
## Symbolgröße relativ zur kleineren Seite.
var scale_ratio: float = 0.42


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * scale_ratio * 0.5
	var w := maxf(2.0, r * 0.26)
	match kind:
		"close":
			_line(c + Vector2(-r, -r), c + Vector2(r, r), w)
			_line(c + Vector2(r, -r), c + Vector2(-r, r), w)
		"menu":
			for k in [-1, 0, 1]:
				var y: float = c.y + k * r * 0.8
				_line(Vector2(c.x - r * 1.15, y), Vector2(c.x + r * 1.15, y), w)
		"home":
			# Haus: Dach als Spitze, darunter die Wände mit Tür (offene Linien, wie das Kreuz).
			var roof := c + Vector2(0, -r * 1.05)
			var eave_l := c + Vector2(-r * 1.15, -r * 0.05)
			var eave_r := c + Vector2(r * 1.15, -r * 0.05)
			_line(eave_l, roof, w)
			_line(roof, eave_r, w)
			var wl := c.x - r * 0.78
			var wr := c.x + r * 0.78
			var top := c.y - r * 0.3
			var bottom := c.y + r * 1.0
			var door := r * 0.28
			_line(Vector2(wl, top), Vector2(wl, bottom), w)
			_line(Vector2(wr, top), Vector2(wr, bottom), w)
			_line(Vector2(wl, bottom), Vector2(c.x - door, bottom), w)
			_line(Vector2(c.x + door, bottom), Vector2(wr, bottom), w)
			_line(Vector2(c.x - door, bottom), Vector2(c.x - door, c.y + r * 0.42), w)
			_line(Vector2(c.x + door, bottom), Vector2(c.x + door, c.y + r * 0.42), w)
			_line(Vector2(c.x - door, c.y + r * 0.42), Vector2(c.x + door, c.y + r * 0.42), w)


## Linie mit runden Enden.
func _line(a: Vector2, b: Vector2, w: float) -> void:
	draw_line(a, b, color, w, true)
	draw_circle(a, w * 0.5, color)
	draw_circle(b, w * 0.5, color)
