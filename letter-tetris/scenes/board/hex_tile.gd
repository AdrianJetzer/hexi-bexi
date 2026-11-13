class_name HexTile
extends Node2D
## Ein Buchstaben-Hexagon (Platzhalter-Optik, ohne Shader).
## Zustände: normal, ausgewählt, erscheint (Rückseite → Drehung), verschwindet, wackelt.

const FRONT := Color(0.93, 0.82, 0.58)
const FRONT_EDGE := Color(1.0, 0.96, 0.85)
const SELECTED := Color(0.45, 0.85, 1.0)
const SELECTED_EDGE := Color(0.9, 1.0, 1.0)
const BACK := Color(0.78, 0.78, 0.88)
const BACK_EDGE := Color(0.95, 0.95, 1.0)
const LETTER := Color(0.22, 0.13, 0.05)
const LETTER_SELECTED := Color(0.02, 0.18, 0.3)

var letter: String = ""
var radius: float = 40.0
var selected: bool = false:
	set(value):
		selected = value
		queue_redraw()
## 0 = Rückseite zu sehen (gerade erschienen), 1 = Vorderseite.
var flip: float = 1.0:
	set(value):
		flip = value
		queue_redraw()

var _font: Font
var _shake_tween: Tween


func _ready() -> void:
	_font = ThemeDB.fallback_font


func setup(p_letter: String, p_radius: float) -> void:
	letter = p_letter
	radius = p_radius
	queue_redraw()


## Erscheinen: Rückseite blendet ein, dann 3D-Drehung auf die Vorderseite.
func appear() -> void:
	flip = 0.0
	modulate.a = 0.0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.25)
	t.tween_interval(0.35)
	t.tween_property(self, "flip", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Verschwinden (gefundenes Wort): kurz aufblähen und ausblenden, dann entfernen.
func vanish(delay: float = 0.0) -> void:
	var t := create_tween()
	t.tween_interval(delay)
	t.set_parallel(true)
	t.tween_property(self, "scale", Vector2(1.3, 1.3), 0.25)
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.set_parallel(false)
	t.tween_callback(queue_free)


## Wackeln (ungültiges Wort).
func shake() -> void:
	if _shake_tween and _shake_tween.is_running():
		_shake_tween.kill()
	var base := position
	var a := radius * 0.12
	_shake_tween = create_tween()
	for dx in [a, -a, a * 0.6, -a * 0.6, 0.0]:
		_shake_tween.tween_property(self, "position", base + Vector2(dx, 0), 0.05)


func _draw() -> void:
	var sx := maxf(absf(cos(flip * PI)), 0.03)
	var back := flip < 0.5
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(sx, 1.0))

	var fill := FRONT
	var edge := FRONT_EDGE
	if back:
		fill = BACK.lerp(SELECTED, 0.5) if selected else BACK
		edge = SELECTED_EDGE if selected else BACK_EDGE
	elif selected:
		fill = SELECTED
		edge = SELECTED_EDGE

	var pts := BoardLayout.hex_points(Vector2.ZERO, radius * 0.92)
	draw_colored_polygon(pts, fill)
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, edge, maxf(radius * 0.06, 2.0), true)

	if letter.is_empty() or _font == null:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var size := int(radius * 0.95)
	var w := _font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var baseline := (_font.get_ascent(size) - _font.get_descent(size)) / 2.0
	if back:
		# Spiegelverkehrt und blass durchschimmernd
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-sx, 1.0))
		draw_string(_font, Vector2(-w / 2.0, baseline), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(LETTER, 0.35))
	else:
		var col := LETTER_SELECTED if selected else LETTER
		draw_string(_font, Vector2(-w / 2.0, baseline), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
