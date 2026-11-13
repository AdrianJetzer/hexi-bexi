class_name HexTile3D
extends Node3D
## Ein 3D-Buchstaben-Hexagon: dickes Kristall-Prisma mit runden Kanten,
## leuchtender Buchstabe oben, milchige Rückseite mit spiegelverkehrtem Buchstaben.

var letter: String = ""
var radius: float = 1.0
var thickness: float = 0.35

var _mesh: MeshInstance3D
var _front_label: Label3D
var _back_label: Label3D
var _front_mat: StandardMaterial3D
var _back_mat: StandardMaterial3D


func setup(p_letter: String, p_mesh: ArrayMesh, p_radius: float, p_thickness: float,
		front_mat: StandardMaterial3D, back_mat: StandardMaterial3D) -> void:
	letter = p_letter
	radius = p_radius
	thickness = p_thickness
	_front_mat = front_mat
	_back_mat = back_mat

	_mesh = MeshInstance3D.new()
	_mesh.mesh = p_mesh
	_mesh.set_surface_override_material(HexMesh.SURFACE_FRONT, front_mat)
	_mesh.set_surface_override_material(HexMesh.SURFACE_BACK, back_mat)
	add_child(_mesh)

	_front_label = _make_label(Color(1.0, 0.96, 0.88), 1.0)
	_front_label.position = Vector3(0, thickness * 0.5 + 0.004, 0)
	_front_label.rotation_degrees = Vector3(-90, 0, 0)

	# Rückseite: liegt unter dem Prisma; nach der Drehung oben, spiegelverkehrt und blass.
	_back_label = _make_label(Color(0.45, 0.5, 0.7), 0.55)
	_back_label.position = Vector3(0, -thickness * 0.5 - 0.004, 0)
	_back_label.rotation_degrees = Vector3(90, 0, 0)
	# Nach der Drehung soll der Buchstabe nur seitenverkehrt erscheinen, nicht auf dem Kopf.
	_back_label.double_sided = true
	_back_label.scale = Vector3(1, -1, 1)


## Auswahl-Hervorhebung über eigenes Material.
func set_front_material(mat: StandardMaterial3D) -> void:
	_mesh.set_surface_override_material(HexMesh.SURFACE_FRONT, mat)


## 0 = Rückseite oben (gerade erschienen), 1 = Vorderseite oben. Drehung um die Z-Achse.
func set_flip(f: float) -> void:
	rotation.z = PI * (1.0 - f)


func _make_label(color: Color, alpha: float) -> Label3D:
	var l := Label3D.new()
	l.text = letter
	l.font_size = 160
	l.pixel_size = radius * 0.95 / 160.0
	l.modulate = Color(color, alpha)
	l.outline_size = 0
	l.shaded = false
	l.double_sided = false
	l.no_depth_test = false
	l.alpha_cut = Label3D.ALPHA_CUT_DISABLED
	add_child(l)
	return l
