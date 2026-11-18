class_name SquareFlip
extends Control
## Effekt für die Power-up-Quadrate (spec/screens.md, „Power-up-Anzeige“): ein Quadrat dreht
## sich mit Perspektive um die senkrechte Achse, hebt sich dabei leicht an, wechselt in der Mitte
## von dunkel auf seine Farbe (mit Glanz) und versprüht Funken und farbigen Rauch.
## Liegt als Ebene über dem Bildschirm; Koordinaten wie das Elternelement.

signal finished

## Dauer der Drehung in Sekunden.
const FLIP_TIME := 0.75
## Wie stark die nahe Kante wächst und die ferne schrumpft (Perspektive).
const PERSPECTIVE := 0.22
## Anheben während der Drehung (Anteil der Quadratgröße).
const LIFT := 0.35
## Rauch: dezent und lange ausklingend.
const SMOKE_TIME := 2.6
const SMOKE_ALPHA := 0.16
const EMPTY := Color(1.0, 1.0, 1.0, 0.06)
const EMPTY_EDGE := Color(1.0, 1.0, 1.0, 0.16)

var _rect: Rect2
var _color: Color
var _t: float = 0.0
var _burst_done := false

static var _spark_tex: Texture2D
static var _smoke_tex: Texture2D


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Drehung des Quadrats `rect` (in Eltern-Koordinaten) zur Farbe `color` starten.
func play(rect: Rect2, color: Color) -> void:
	_rect = rect
	_color = color
	_t = 0.0
	var tw := create_tween()
	tw.tween_method(_set_t, 0.0, 1.0, FLIP_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void: finished.emit())
	# Partikel (vor allem der Rauch) in Ruhe ausklingen lassen, dann aufräumen.
	tw.tween_interval(SMOKE_TIME + 0.5)
	tw.tween_callback(queue_free)


func _set_t(v: float) -> void:
	_t = v
	if not _burst_done and _t >= 0.5:
		_burst_done = true
		_burst()
	queue_redraw()


func _draw() -> void:
	if _t >= 1.0:
		return  # danach zeigt die Anzeige selbst das gefüllte Quadrat
	var a := _t * PI
	var w := absf(cos(a))
	var lean := sin(a)
	var front := _t >= 0.5
	# Glanz läuft nach der Hälfte einmal über die Fläche.
	var shine := clampf((_t - 0.5) * 2.0, 0.0, 1.0) if front else -1.0
	_draw_square(w, 1.0 + LIFT * 0.6 * lean, lean, front, shine)


## w: sichtbare Breite (0–1); grow: Größe; lean: Perspektive (-1–1); front: farbige Seite.
func _draw_square(w: float, grow: float, lean: float, front: bool, shine: float) -> void:
	var c := _rect.get_center() - Vector2(0, _rect.size.y * LIFT * 0.5 * absf(lean))
	var half := _rect.size * 0.5 * grow
	var hx := half.x * maxf(w, 0.04)
	# Linke Kante kommt näher (größer), rechte geht weg (kleiner) – oder umgekehrt.
	var hl := half.y * (1.0 + PERSPECTIVE * lean)
	var hr := half.y * (1.0 - PERSPECTIVE * lean)
	var k := minf(half.x, half.y) * 0.22  # abgeschrägte Ecken statt Rundung
	var kx := minf(k, hx)
	var pts := PackedVector2Array([
		Vector2(c.x - hx + kx, c.y - hl), Vector2(c.x + hx - kx, c.y - hr),
		Vector2(c.x + hx, c.y - hr + k), Vector2(c.x + hx, c.y + hr - k),
		Vector2(c.x + hx - kx, c.y + hr), Vector2(c.x - hx + kx, c.y + hl),
		Vector2(c.x - hx, c.y + hl - k), Vector2(c.x - hx, c.y - hl + k)])
	if front:
		# Schein unter dem Stein
		for i in 3:
			draw_circle(c, half.x * (1.25 + i * 0.35), Color(_color, 0.12 - i * 0.035))
		draw_colored_polygon(pts, _color)
		var edge := pts.duplicate()
		edge.append(pts[0])
		draw_polyline(edge, _color.lightened(0.45), maxf(1.0, half.x * 0.12), true)
		# Glanzstreifen oben
		var gy := c.y - half.y * 0.55
		draw_rect(Rect2(c.x - hx * 0.72, gy, hx * 1.44, half.y * 0.32), Color(1, 1, 1, 0.28))
		if shine >= 0.0 and shine < 1.0:
			var sx := lerpf(c.x - hx, c.x + hx, shine)
			var band := PackedVector2Array([Vector2(sx - hx * 0.25, c.y - hl), Vector2(sx + hx * 0.05, c.y - hl),
				Vector2(sx + hx * 0.25, c.y + hl), Vector2(sx - hx * 0.05, c.y + hl)])
			draw_colored_polygon(band, Color(1, 1, 1, 0.55 * sin(shine * PI)))
	else:
		draw_colored_polygon(pts, EMPTY)
		var edge := pts.duplicate()
		edge.append(pts[0])
		draw_polyline(edge, EMPTY_EDGE, maxf(1.0, half.x * 0.08), true)


## Funken und Rauch in der Farbe des Quadrats.
func _burst() -> void:
	_ensure_textures()
	var center := _rect.get_center()
	var size := _rect.size.x
	# Rauch (zuerst, liegt hinter den Funken)
	var smoke := CPUParticles2D.new()
	smoke.texture = _smoke_tex
	smoke.position = center
	smoke.one_shot = true
	smoke.explosiveness = 0.85
	smoke.amount = 10
	smoke.lifetime = SMOKE_TIME
	smoke.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	smoke.emission_sphere_radius = size * 0.35
	smoke.direction = Vector2(0, -1)
	smoke.spread = 70.0
	smoke.gravity = Vector2(0, -size * 0.25)
	smoke.initial_velocity_min = size * 0.25
	smoke.initial_velocity_max = size * 0.7
	smoke.damping_min = size * 0.4
	smoke.damping_max = size * 0.8
	smoke.angle_min = -180.0
	smoke.angle_max = 180.0
	smoke.angular_velocity_min = -40.0
	smoke.angular_velocity_max = 40.0
	smoke.scale_amount_min = size / 64.0 * 0.9
	smoke.scale_amount_max = size / 64.0 * 1.4
	var grow := Curve.new()
	grow.add_point(Vector2(0, 0.5))
	grow.add_point(Vector2(1, 2.4))
	smoke.scale_amount_curve = grow
	var sramp := Gradient.new()
	var tint := _color.lerp(Color(0.85, 0.9, 1.0), 0.45)
	# sanft ein, lange und weich aus (kein plötzliches Verschwinden)
	sramp.set_color(0, Color(tint, 0.0))
	sramp.add_point(0.12, Color(tint, SMOKE_ALPHA))
	sramp.add_point(0.45, Color(tint, SMOKE_ALPHA * 0.6))
	sramp.add_point(0.75, Color(tint, SMOKE_ALPHA * 0.25))
	sramp.set_color(1, Color(tint, 0.0))
	smoke.color_ramp = sramp
	add_child(smoke)
	smoke.emitting = true
	# Funken (additiv, leuchten über dem Hintergrund)
	var sparks := CPUParticles2D.new()
	sparks.texture = _spark_tex
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sparks.material = add
	sparks.position = center
	sparks.one_shot = true
	sparks.explosiveness = 0.95
	sparks.amount = 28
	sparks.lifetime = 0.9
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = size * 0.3
	sparks.spread = 180.0
	sparks.gravity = Vector2(0, size * 1.5)
	sparks.initial_velocity_min = size * 1.5
	sparks.initial_velocity_max = size * 4.0
	sparks.damping_min = size * 1.5
	sparks.damping_max = size * 3.0
	sparks.scale_amount_min = size / 32.0 * 0.15
	sparks.scale_amount_max = size / 32.0 * 0.4
	var fade := Curve.new()
	fade.add_point(Vector2(0, 1))
	fade.add_point(Vector2(0.7, 0.7))
	fade.add_point(Vector2(1, 0))
	sparks.scale_amount_curve = fade
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.6, 1.6, 1.6))
	ramp.add_point(0.25, _color.lightened(0.3) * 1.4)
	ramp.set_color(1, Color(_color, 0.0))
	sparks.color_ramp = ramp
	add_child(sparks)
	sparks.emitting = true


static func _ensure_textures() -> void:
	if _spark_tex == null:
		_spark_tex = _radial(32, [Color(1, 1, 1, 1), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)], [0.0, 0.25, 1.0])
	if _smoke_tex == null:
		_smoke_tex = _radial(64, [Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)], [0.0, 0.45, 1.0])


static func _radial(px: int, colors: Array, offsets: Array) -> Texture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offsets)
	g.colors = PackedColorArray(colors)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = px
	t.height = px
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	return t
