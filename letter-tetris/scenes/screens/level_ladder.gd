class_name LevelLadder
extends Control
## Fortschritt zum Ziel als liegende Leiter (spec/screens.md, „Spiel“): eine Reihe Quadrate,
## eins je Level. Jedes Quadrat hat seine feste Farbe im Verlauf grün → orange → rot.
## Geschaffte Level leuchten, das laufende ist farbig umrandet, offene sind dunkel.

const GREEN := Color(0.25, 0.86, 0.45)
const ORANGE := Color(1.0, 0.62, 0.16)
const RED := Color(0.96, 0.26, 0.26)
const EMPTY := Color(1.0, 1.0, 1.0, 0.06)
const EMPTY_EDGE := Color(1.0, 1.0, 1.0, 0.16)
## Abstand zwischen den Quadraten im Verhältnis zur Quadratgröße.
const GAP := 0.28

var steps: int = 20:
	set(v):
		steps = maxi(v, 1)
		queue_redraw()
## Geschaffte Level (0 … steps).
var done: int = 0:
	set(v):
		done = clampi(v, 0, steps)
		queue_redraw()
## Eigene Farbe je Quadrat (leer = Verlauf grün → orange → rot). Für die Power-up-Anzeige.
var palette: Array[Color] = []:
	set(v):
		palette = v
		queue_redraw()
## Quadratgröße im Verhältnis zur Höhe des Controls.
var cell_ratio: float = 0.62:
	set(v):
		cell_ratio = v
		queue_redraw()
## Dieses Quadrat nicht zeichnen (z. B. während es sich dreht), -1 = keins.
var hidden_index: int = -1:
	set(v):
		hidden_index = v
		queue_redraw()
## Deckkraft der Umrandung des laufenden Levels (zum sanften Aufleuchten „ready“).
var current_alpha: float = 1.0:
	set(v):
		current_alpha = v
		queue_redraw()
## Laufendes Level hervorheben?
var show_current: bool = true:
	set(v):
		show_current = v
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Farbe des Quadrats i (0-basiert) im Verlauf grün → orange → rot.
func color_at(i: int) -> Color:
	if not palette.is_empty():
		return palette[i % palette.size()]
	var t := float(i) / float(maxi(steps - 1, 1))
	return GREEN.lerp(ORANGE, t * 2.0) if t < 0.5 else ORANGE.lerp(RED, (t - 0.5) * 2.0)


## Lage des Quadrats i im Control (für Animationen darüber).
func cell_rect(i: int) -> Rect2:
	var cell := minf(size.y * cell_ratio, size.x / (steps + (steps - 1) * GAP))
	return Rect2(i * cell * (1.0 + GAP), (size.y - cell) * 0.5, cell, cell)


func _draw() -> void:
	var cell := minf(size.y * cell_ratio, size.x / (steps + (steps - 1) * GAP))
	var gap := cell * GAP
	var y := (size.y - cell) * 0.5
	var radius := int(round(cell * 0.22))
	for i in steps:
		if i == hidden_index:
			continue
		var r := Rect2(i * (cell + gap), y, cell, cell)
		var box := StyleBoxFlat.new()
		box.set_corner_radius_all(radius)
		box.anti_aliasing = true
		var c := color_at(i)
		if i < done:
			# Geschafft: leuchtend, mit sanftem Schein und hellem Glanz oben.
			box.bg_color = c
			box.shadow_color = Color(c, 0.55)
			box.shadow_size = int(round(cell * 0.35))
			box.border_color = c.lightened(0.45)
			box.set_border_width_all(maxi(1, int(round(cell * 0.06))))
		elif i == done and show_current:
			# Laufendes Level: dunkel mit farbigem Rand.
			box.bg_color = Color(c, 0.18 * current_alpha)
			box.border_color = Color(c, current_alpha)
			box.set_border_width_all(maxi(2, int(round(cell * 0.1))))
			box.shadow_color = Color(c, 0.35 * current_alpha)
			box.shadow_size = int(round(cell * 0.25))
		else:
			box.bg_color = EMPTY
			box.border_color = EMPTY_EDGE
			box.set_border_width_all(maxi(1, int(round(cell * 0.05))))
		draw_style_box(box, r)
		if i < done:
			var shine := StyleBoxFlat.new()
			shine.set_corner_radius_all(maxi(radius - 1, 0))
			shine.anti_aliasing = true
			shine.bg_color = Color(1, 1, 1, 0.28)
			draw_style_box(shine, Rect2(r.position + Vector2(cell * 0.14, cell * 0.12),
					Vector2(cell * 0.72, cell * 0.28)))
