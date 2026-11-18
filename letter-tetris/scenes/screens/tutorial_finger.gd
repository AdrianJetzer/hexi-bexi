class_name TutorialFinger
extends Control
## Gezeichneter Finger fürs Tutorial (spec/screens.md, „Tutorial“): fährt in einer Schleife den
## Weg eines Worts nach (aufsetzen, über die Steine ziehen, anheben), mit leuchtender Spur.
## Liegt als Ebene über dem Bildschirm; Punkte in Bildschirm-Koordinaten (wie das Elternelement).

const FADE := 0.25
const PRESS := 0.18
const STEP := 0.38
const HOLD := 0.25
const PAUSE := 0.55
## Größe des Fingers (Pixel, Länge Fingerspitze bis Handballen).
const SIZE := 190.0
const FILL := Color(0.97, 0.98, 1.0, 0.95)
const EDGE := Color(0.35, 0.85, 1.0, 1.0)
const TRAIL := Color(0.45, 0.95, 1.0, 0.75)

var _points: PackedVector2Array = PackedVector2Array()
var _loop: Tween
## Animationszustand: Position der Spitze, Fortschritt der Spur, Druck (Ring), Sichtbarkeit.
var _tip := Vector2.ZERO
var _trail := 0.0
var _press := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	modulate.a = 0.0


## Der gerade gezeigte Weg.
func points() -> PackedVector2Array:
	return _points


func is_playing() -> bool:
	return _loop != null and _loop.is_valid()


## Weg in einer Schleife zeigen (ersetzt einen laufenden).
func play(points: PackedVector2Array) -> void:
	stop()
	if points.size() < 2:
		return
	_points = points
	_loop = create_tween().set_loops()
	_loop.tween_callback(func() -> void:
		_tip = _points[0]
		_trail = 0.0
		_press = 0.0
		queue_redraw())
	_loop.tween_property(self, "modulate:a", 1.0, FADE)
	_loop.tween_method(_set_press, 0.0, 1.0, PRESS)
	for i in range(1, _points.size()):
		_loop.tween_method(_set_trail, float(i - 1), float(i), STEP) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_loop.tween_interval(HOLD)
	_loop.tween_method(_set_press, 1.0, 0.0, PRESS)
	_loop.tween_property(self, "modulate:a", 0.0, FADE)
	_loop.tween_interval(PAUSE)


func stop() -> void:
	if _loop:
		_loop.kill()
	_loop = null
	_points = PackedVector2Array()
	modulate.a = 0.0
	queue_redraw()


func _set_press(v: float) -> void:
	_press = v
	queue_redraw()


func _set_trail(v: float) -> void:
	_trail = v
	var i := mini(int(floor(v)), _points.size() - 2)
	_tip = _points[i].lerp(_points[i + 1], v - i)
	queue_redraw()


func _draw() -> void:
	if _points.size() < 2:
		return
	# Spur über die bereits überfahrenen Steine
	var trail := PackedVector2Array([_points[0]])
	for i in range(1, _points.size()):
		if i <= _trail:
			trail.append(_points[i])
	trail.append(_tip)
	if trail.size() >= 2:
		draw_polyline(trail, Color(TRAIL, 0.25), 34.0, true)
		draw_polyline(trail, TRAIL, 12.0, true)
	# Berührung: leuchtender Ring unter der Fingerspitze
	if _press > 0.0:
		draw_circle(_tip, 38.0 * _press, Color(EDGE, 0.22 * _press))
		draw_arc(_tip, 30.0 * _press, 0.0, TAU, 32, Color(EDGE, 0.8 * _press), 4.0, true)
	_draw_hand(_tip + Vector2(10, 14) * (1.0 - _press))


## Zeigende Hand: Zeigefinger von der Spitze nach unten rechts, Handballen und Daumen.
func _draw_hand(tip: Vector2) -> void:
	var k := SIZE / 190.0
	draw_set_transform(tip, deg_to_rad(-28.0), Vector2.ONE * k)
	var shapes: Array[PackedVector2Array] = [
		_capsule(Vector2(0, 6), Vector2(0, 104), 17.0),  # Zeigefinger
		_capsule(Vector2(30, 92), Vector2(30, 122), 16.0),  # Mittelfinger (eingerollt)
		_capsule(Vector2(56, 102), Vector2(56, 128), 15.0),  # Ringfinger
		_capsule(Vector2(-22, 124), Vector2(-44, 96), 15.0),  # Daumen
		_round_rect(Rect2(-30, 96, 100, 92), 26.0),  # Handballen
	]
	for p in shapes:
		var edge := p.duplicate()
		edge.append(p[0])
		draw_polyline(edge, EDGE, 7.0, true)
	for p in shapes:
		draw_colored_polygon(p, FILL)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _capsule(a: Vector2, b: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var ang := (b - a).angle()
	for i in 13:
		pts.append(b + Vector2.from_angle(ang - PI / 2 + PI * i / 12.0) * r)
	for i in 13:
		pts.append(a + Vector2.from_angle(ang + PI / 2 + PI * i / 12.0) * r)
	return pts


static func _round_rect(r: Rect2, rad: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var corners := [r.position + Vector2(r.size.x - rad, rad), r.end - Vector2(rad, rad),
		Vector2(r.position.x + rad, r.end.y - rad), r.position + Vector2(rad, rad)]
	var start := [-PI / 2, 0.0, PI / 2, PI]
	for c in 4:
		for i in 7:
			pts.append(corners[c] + Vector2.from_angle(start[c] + PI / 2 * i / 6.0) * rad)
	return pts
