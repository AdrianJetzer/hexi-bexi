class_name HexMesh
extends RefCounted
## Erzeugt ein dickes Hexagon-Prisma mit abgerundeten Kanten (unten flach, Y = oben).
##
## Ergebnis-Mesh mit zwei Flächen (Surfaces):
##   0 = obere Hälfte (Vorderseite), 1 = untere Hälfte (Rückseite).
## Mittelpunkt liegt im Ursprung, das Prisma reicht von -thickness/2 bis +thickness/2.

const SURFACE_FRONT := 0
const SURFACE_BACK := 1


## radius: Außenradius (Mitte bis Ecke) in der Draufsicht.
## thickness: Dicke.
## corner: Rundung der senkrechten Ecken (Draufsicht).
## bevel: Rundung der oberen/unteren Kanten (wird auf corner und thickness/2 begrenzt).
static func build(radius: float = 1.0, thickness: float = 0.35, corner: float = 0.14,
		bevel: float = 0.1, corner_segments: int = 5, bevel_segments: int = 5) -> ArrayMesh:
	bevel = minf(bevel, minf(corner, thickness * 0.5))
	corner = minf(corner, radius * 0.5)

	# Umriss: je Ecke ein Kreisbogen; Mittelpunkte und Außen-Richtungen merken.
	var centers := PackedVector2Array()
	var outs := PackedVector2Array()
	var rc := radius - corner / sin(PI / 3.0)
	for i in 6:
		var a := PI / 3.0 * i
		var c := Vector2(cos(a), sin(a)) * rc
		for s in corner_segments + 1:
			var phi := a - PI / 6.0 + (PI / 3.0) * float(s) / corner_segments
			centers.append(c)
			outs.append(Vector2(cos(phi), sin(phi)))

	# Profil von unten nach oben: [Höhe, Einzug, Neigung der Normale]
	var rings: Array = []
	for s in bevel_segments + 1:
		var t := -PI / 2.0 + (PI / 2.0) * float(s) / bevel_segments
		rings.append([bevel + bevel * sin(t), bevel - bevel * cos(t), t])
	var mid_index := rings.size()
	rings.append([thickness * 0.5, 0.0, 0.0])
	for s in bevel_segments + 1:
		var t := (PI / 2.0) * float(s) / bevel_segments
		rings.append([thickness - bevel + bevel * sin(t), bevel - bevel * cos(t), t])

	var half := thickness * 0.5
	var mesh := ArrayMesh.new()
	_add_surface(mesh, centers, outs, rings, 0, mid_index, corner, half, -1)
	_add_surface(mesh, centers, outs, rings, mid_index, rings.size() - 1, corner, half, 1)
	# Reihenfolge der Surfaces: zuerst unten gebaut → umsortieren auf FRONT=0, BACK=1
	var sorted := ArrayMesh.new()
	sorted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh.surface_get_arrays(1))
	sorted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh.surface_get_arrays(0))
	return sorted


static func _add_surface(mesh: ArrayMesh, centers: PackedVector2Array, outs: PackedVector2Array,
		rings: Array, from_ring: int, to_ring: int, corner: float, half: float, cap: int) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := centers.size()
	for j in range(from_ring, to_ring):
		for k in n:
			var k2 := (k + 1) % n
			var a := _vertex(centers, outs, rings[j], k, corner, half)
			var b := _vertex(centers, outs, rings[j], k2, corner, half)
			var c := _vertex(centers, outs, rings[j + 1], k, corner, half)
			var d := _vertex(centers, outs, rings[j + 1], k2, corner, half)
			_tri(st, a, b, c)
			_tri(st, b, d, c)
	# Deckel (oben oder unten)
	var ring: Array = rings[to_ring] if cap > 0 else rings[from_ring]
	var up := Vector3(0, cap, 0)
	var center := [Vector3(0, cap * half, 0), up]
	for k in n:
		var k2 := (k + 1) % n
		var p := _vertex(centers, outs, ring, k, corner, half)
		var q := _vertex(centers, outs, ring, k2, corner, half)
		p[1] = up
		q[1] = up
		if cap > 0:
			_tri(st, center, q, p)
		else:
			_tri(st, center, p, q)
	st.commit(mesh)


static func _vertex(centers: PackedVector2Array, outs: PackedVector2Array, ring: Array, k: int,
		corner: float, half: float) -> Array:
	var y: float = ring[0]
	var inset: float = ring[1]
	var t: float = ring[2]
	var o := outs[k]
	var p2 := centers[k] + o * (corner - inset)
	var pos := Vector3(p2.x, y - half, p2.y)
	var normal := Vector3(o.x * cos(t), sin(t), o.y * cos(t)).normalized()
	return [pos, normal]


## Godot zeigt Dreiecke im Uhrzeigersinn als Vorderseite; die Punkte werden
## deshalb in umgekehrter Reihenfolge übergeben.
static func _tri(st: SurfaceTool, a: Array, b: Array, c: Array) -> void:
	for v in [a, c, b]:
		st.set_normal(v[1])
		st.add_vertex(v[0])
