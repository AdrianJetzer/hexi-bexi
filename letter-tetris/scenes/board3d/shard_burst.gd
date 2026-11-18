class_name ShardBurst
extends Node3D
## Ein Stein zerspringt in Kristall-Splitter (spec/game-rules.md, „Wörter wischen“): jedes Mal
## zufällig – 7 bis 12 Splitter, Bruchpunkt nicht genau in der Mitte, unregelmäßige Schnitte.
## Die Splitter fliegen nach außen und leicht nach oben, drehen sich, fallen unter Schwerkraft,
## werden kleiner und verglimmen. Dazu ein kurzer Lichtblitz. Der Buchstabe fliegt derweil als
## eigenes Zeichen nach oben (das macht der Spiel-Bildschirm).

const MIN_SHARDS := 5
const MAX_SHARDS := 8
## Feinere Splitter: Größe und Dicke im Verhältnis zum Stein.
const SHARD_SCALE := 0.62
const SHARD_THICKNESS := 0.45
## Dauer bis die Splitter verschwunden sind (Sekunden).
const LIFE := 0.8
const GRAVITY := 14.0
const FLASH_ENERGY := 2.0
const FLASH_TIME := 0.18

var _shards: Array[MeshInstance3D] = []
var _vel: Array[Vector3] = []
var _spin: Array[Vector3] = []
var _age := 0.0
var _flash: OmniLight3D
var _rng := RandomNumberGenerator.new()


## radius/thickness wie der Stein; mat: wird nicht mehr genutzt (Splitter sind klares Glas);
## color: Farbe des Blitzes und der Glas-Tönung.
func setup(radius: float, thickness: float, _mat: Material = null, color: Color = Color(0.6, 1.0, 1.0)) -> void:
	_rng.randomize()
	var mat := _glass(color)
	thickness *= SHARD_THICKNESS
	var hex := PackedVector2Array()
	for i in 6:
		var a := PI / 3.0 * i
		hex.append(Vector2(cos(a), sin(a)) * radius)
	# Bruchpunkt: zufällig innerhalb des inneren Drittels.
	var center := Vector2.from_angle(_rng.randf() * TAU) * radius * _rng.randf_range(0.0, 0.35)
	# Zufällige, unregelmäßige Schnittwinkel rund um den Bruchpunkt.
	var n := _rng.randi_range(MIN_SHARDS, MAX_SHARDS)
	var angles: Array[float] = []
	var step := TAU / n
	var start := _rng.randf() * TAU
	for k in n:
		angles.append(start + step * k + _rng.randf_range(-0.38, 0.38) * step)
	angles.sort()
	for k in n:
		var a0 := angles[k]
		var a1 := angles[(k + 1) % n] + (TAU if k == n - 1 else 0.0)
		var poly := _wedge(hex, center, a0, a1)
		if poly.size() < 3:
			continue
		for i in poly.size():
			poly[i] *= SHARD_SCALE
		_add_shard(poly, thickness, mat)
	_flash = OmniLight3D.new()
	_flash.light_color = color
	_flash.light_energy = FLASH_ENERGY
	_flash.omni_range = radius * 2.2
	_flash.position = Vector3(center.x, thickness, center.y)
	add_child(_flash)


func _process(delta: float) -> void:
	_age += delta
	var t := clampf(_age / LIFE, 0.0, 1.0)
	for i in _shards.size():
		var s := _shards[i]
		_vel[i].y -= GRAVITY * delta
		s.position += _vel[i] * delta
		s.rotation += _spin[i] * delta
		# Erst kurz voll, dann kleiner werden (verglimmen).
		var k := 1.0 - smoothstep(0.35, 1.0, t)
		s.scale = Vector3.ONE * maxf(k, 0.01)
	if _flash:
		_flash.light_energy = FLASH_ENERGY * maxf(0.0, 1.0 - _age / FLASH_TIME)
	if _age >= LIFE:
		queue_free()


## Durchsichtiges, leicht leuchtendes Glas: additiv gemischt, damit der dunkle Hintergrund
## durchscheint und überlappende Stücke heller wirken (wie Licht in Glaskanten).
static var _glass_cache: Dictionary = {}
static func _glass(tint: Color) -> StandardMaterial3D:
	if _glass_cache.has(tint):
		return _glass_cache[tint]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = tint.lerp(Color.WHITE, 0.25) * 0.42
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	_glass_cache[tint] = m
	return m


## Teil des Sechsecks zwischen den Strahlen a0 und a1 vom Bruchpunkt aus (in der Draufsicht).
func _wedge(hex: PackedVector2Array, c: Vector2, a0: float, a1: float) -> PackedVector2Array:
	var pts := PackedVector2Array([c, _ray_hit(hex, c, a0)])
	# Sechseck-Ecken, die zwischen den beiden Strahlen liegen
	var corners: Array = []
	for p in hex:
		var a := fposmod((p - c).angle() - a0, TAU)
		if a > 0.0 and a < a1 - a0:
			corners.append([a, p])
	corners.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	for e in corners:
		pts.append(e[1])
	pts.append(_ray_hit(hex, c, a1))
	return pts


## Schnittpunkt eines Strahls vom Punkt c mit dem Sechseck-Rand.
func _ray_hit(hex: PackedVector2Array, c: Vector2, a: float) -> Vector2:
	var d := Vector2.from_angle(a)
	var best := INF
	for i in hex.size():
		var p := hex[i]
		var q := hex[(i + 1) % hex.size()]
		var hit: Variant = Geometry2D.segment_intersects_segment(c, c + d * 100.0, p, q)
		if hit != null:
			best = minf(best, (hit as Vector2).distance_to(c))
	return c + d * (best if best < INF else 0.0)


## Splitter als flaches Prisma; Ursprung im Schwerpunkt (dreht sich um sich selbst).
func _add_shard(poly: PackedVector2Array, thickness: float, mat: Material) -> void:
	var centroid := Vector2.ZERO
	for p in poly:
		centroid += p
	centroid /= poly.size()
	var h := thickness * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var m := poly.size()
	for i in range(1, m - 1):
		var a := poly[0] - centroid
		var b := poly[i] - centroid
		var c := poly[i + 1] - centroid
		# oben
		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3(a.x, h, a.y))
		st.add_vertex(Vector3(c.x, h, c.y))
		st.add_vertex(Vector3(b.x, h, b.y))
		# unten
		st.set_normal(Vector3.DOWN)
		st.add_vertex(Vector3(a.x, -h, a.y))
		st.add_vertex(Vector3(b.x, -h, b.y))
		st.add_vertex(Vector3(c.x, -h, c.y))
	for i in m:
		var p := poly[i] - centroid
		var q := poly[(i + 1) % m] - centroid
		var nrm := Vector3(q.y - p.y, 0, -(q.x - p.x)).normalized()
		st.set_normal(nrm)
		st.add_vertex(Vector3(p.x, h, p.y))
		st.add_vertex(Vector3(q.x, -h, q.y))
		st.add_vertex(Vector3(p.x, -h, p.y))
		st.add_vertex(Vector3(p.x, h, p.y))
		st.add_vertex(Vector3(q.x, h, q.y))
		st.add_vertex(Vector3(q.x, -h, q.y))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(centroid.x, 0.0, centroid.y)
	add_child(mi)
	_shards.append(mi)
	var out := Vector3(centroid.x, 0.0, centroid.y).normalized()
	if out == Vector3.ZERO:
		var a := _rng.randf() * TAU
		out = Vector3(cos(a), 0.0, sin(a))
	_vel.append(out * _rng.randf_range(1.1, 2.6) + Vector3(0, _rng.randf_range(1.5, 3.5), 0))
	_spin.append(Vector3(_rng.randf_range(-9, 9), _rng.randf_range(-6, 6), _rng.randf_range(-9, 9)))
