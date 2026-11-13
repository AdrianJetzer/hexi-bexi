class_name HexTile3D
extends Node3D
## Ein 3D-Buchstaben-Hexagon: dickes Prisma mit runden Kanten,
## leuchtender Buchstabe oben, milchige Rückseite mit seitenverkehrtem Buchstaben.

var letter: String = ""
var radius: float = 1.0
var thickness: float = 0.35

var _mesh: MeshInstance3D
var _front_label: Label3D
var _back_label: Label3D
var _front_mat: Material
var _back_mat: Material
var _normal_mat: Material
var _selected_mat: Material
var _back_nodes: Array[Node3D] = []
var _flip: float = 1.0
var _base_position: Vector3 = Vector3.ZERO
var _shake_tween: Tween
var _pulse_tween: Tween

## 0 = Rückseite oben, 1 = Vorderseite oben (für Animationen).
var flip: float:
	get:
		return _flip
	set(value):
		set_flip(value)
		# Beim Drehen kurz anheben, damit es nicht durch Nachbarn oder den Boden dreht.
		position.y = _base_position.y + sin(clampf(value, 0.0, 1.0) * PI) * thickness * 0.9


## letter_color: Farbe des Buchstabens (Werte > 1 leuchten stärker durch Glow).
## letter_depth: wie tief der Buchstabe im Kristall sitzt (0 = auf der Oberfläche).
func setup(p_letter: String, p_mesh: ArrayMesh, p_radius: float, p_thickness: float,
		front_mat: Material, back_mat: Material,
		letter_color: Color = Color(1.0, 0.96, 0.88), letter_depth: float = 0.0,
		back_letter_color: Color = Color(0.45, 0.5, 0.7, 0.55),
		back_letter_outline: Color = Color(0, 0, 0, 0)) -> void:
	letter = p_letter
	radius = p_radius
	thickness = p_thickness
	_front_mat = front_mat
	_back_mat = back_mat

	_mesh = MeshInstance3D.new()
	_mesh.mesh = p_mesh
	add_child(_mesh)

	_front_label = _make_label(letter_color)
	_front_label.position = Vector3(0, thickness * 0.5 + 0.004 - letter_depth, 0)
	_front_label.rotation_degrees = Vector3(-90, 0, 0)

	# Rückseite: liegt unter dem Prisma; nach der Drehung oben, seitenverkehrt und blass.
	_back_label = _make_label(back_letter_color)
	_back_label.position = Vector3(0, -thickness * 0.5 - 0.004, 0)
	_back_label.rotation_degrees = Vector3(90, 0, 0)
	# Nach der Drehung soll der Buchstabe nur seitenverkehrt erscheinen, nicht auf dem Kopf.
	_back_label.double_sided = true
	_back_label.scale = Vector3(1, -1, 1)
	if back_letter_outline.a > 0.0:
		# Heller Rand um einen dunklen Buchstaben wirkt wie eine Gravur.
		_back_label.outline_size = 10
		_back_label.outline_modulate = back_letter_outline
	_back_nodes.append(_back_label)
	set_flip(1.0)


## Zusätzliche Verzierung der Rückseite (z. B. Leuchtring). Wird mit der Rückseite
## ein- und ausgeblendet. Position im Koordinatensystem des Hexagons.
func add_back_decoration(node: Node3D) -> void:
	add_child(node)
	_back_nodes.append(node)
	set_flip(_flip)


## Material der Vorderseite tauschen (z. B. für die Auswahl).
func set_front_material(mat: Material) -> void:
	_front_mat = mat
	set_flip(_flip)


## Materialien für normal/ausgewählt festlegen (für set_selected).
func set_selection_materials(normal: Material, selected_mat: Material) -> void:
	_normal_mat = normal
	_selected_mat = selected_mat


func set_selected(on: bool) -> void:
	if _normal_mat and _selected_mat:
		set_front_material(_selected_mat if on else _normal_mat)


## Ruheposition (Animationen kehren dorthin zurück).
func place(at: Vector3) -> void:
	_base_position = at
	position = at


## Erscheinen: kurz aufploppen mit Rückseite oben, dann echte Drehung auf die Vorderseite.
func appear(delay: float = 0.0) -> void:
	set_flip(0.0)
	scale = Vector3.ONE * 0.01
	var t := create_tween()
	if delay > 0.0:
		t.tween_interval(delay)
	t.tween_property(self, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.35)
	t.tween_property(self, "flip", 1.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Umdrehen an Ort und Stelle (neuer Buchstabe): Rückseite oben, dann Drehung auf die Vorderseite.
func turn(delay: float = 0.0) -> void:
	set_flip(0.0)
	var t := create_tween()
	if delay > 0.0:
		t.tween_interval(delay)
	t.tween_property(self, "flip", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Verschwinden (gefundenes Wort): aufleuchten, kurz anheben, schrumpfen, dann entfernen.
## (Platzhalter für das Zerspringen in Splitter.)
func vanish(delay: float = 0.0) -> void:
	set_selected(true)
	var t := create_tween()
	t.tween_interval(delay)
	t.set_parallel(true)
	t.tween_property(self, "position:y", _base_position.y + thickness * 1.5, 0.22)
	t.tween_property(self, "scale", Vector3.ONE * 1.15, 0.12)
	t.chain().tween_property(self, "scale", Vector3.ONE * 0.01, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(queue_free)


## Pulsieren (Tipp): wechselt zwischen normal und ausgewählt, bis stop_pulse().
func start_pulse() -> void:
	stop_pulse()
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_callback(set_selected.bind(true))
	_pulse_tween.tween_interval(0.35)
	_pulse_tween.tween_callback(set_selected.bind(false))
	_pulse_tween.tween_interval(0.35)


func stop_pulse() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
		set_selected(false)


## Wackeln (ungültiges Wort).
func shake() -> void:
	if _shake_tween and _shake_tween.is_running():
		_shake_tween.kill()
	var a := radius * 0.1
	_shake_tween = create_tween()
	for dx in [a, -a, a * 0.6, -a * 0.6, 0.0]:
		_shake_tween.tween_property(self, "position:x", _base_position.x + dx, 0.05)


## 0 = Rückseite oben (gerade erschienen), 1 = Vorderseite oben. Drehung um die Z-Achse.
## Solange die Rückseite oben ist, ist die untere Hälfte milchig; danach ist das ganze
## Prisma Kristall (sonst sähe man die milchige Rückseite durch den Kristall).
func set_flip(f: float) -> void:
	_flip = f
	rotation.z = PI * (1.0 - f)
	var back_up := f < 0.5
	_mesh.set_surface_override_material(HexMesh.SURFACE_FRONT, _front_mat)
	_mesh.set_surface_override_material(HexMesh.SURFACE_BACK, _back_mat if back_up else _front_mat)
	for n in _back_nodes:
		n.visible = back_up
	_front_label.visible = not back_up or f > 0.25


func _make_label(color: Color) -> Label3D:
	var l := Label3D.new()
	l.text = letter
	l.font_size = 160
	l.pixel_size = radius * 0.95 / 160.0
	l.modulate = color
	l.outline_size = 0
	l.shaded = false
	l.double_sided = false
	l.alpha_cut = Label3D.ALPHA_CUT_DISABLED
	add_child(l)
	return l
