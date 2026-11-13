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
var _back_nodes: Array[Node3D] = []


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
	set_flip(1.0 - rotation.z / PI)


## Material der Vorderseite tauschen (z. B. für die Auswahl).
func set_front_material(mat: Material) -> void:
	_front_mat = mat
	set_flip(1.0 - rotation.z / PI)


## 0 = Rückseite oben (gerade erschienen), 1 = Vorderseite oben. Drehung um die Z-Achse.
## Solange die Rückseite oben ist, ist die untere Hälfte milchig; danach ist das ganze
## Prisma Kristall (sonst sähe man die milchige Rückseite durch den Kristall).
func set_flip(f: float) -> void:
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
