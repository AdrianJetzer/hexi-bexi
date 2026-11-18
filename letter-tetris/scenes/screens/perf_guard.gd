class_name PerfGuard
extends Node
## Automatische 3D-Auflösung für schwächere Handys (spec/screens.md, „Leistung“): misst nach dem
## Start ein paar Sekunden die Bildrate. Ist sie zu niedrig, rechnet die 3D-Welt (Steine,
## Hintergrund) mit weniger Auflösung; Schrift, Knöpfe und Kästchen bleiben scharf. Auf schnellen
## Handys passiert nichts. Höchstens zwei Stufen, danach misst es nicht mehr.

## Einschwingen nach dem Start bzw. nach einer Änderung, dann so lange messen (Sekunden).
const WARMUP := 2.0
const MEASURE := 3.0
## Unter dieser Bildrate auf 75 %, wenn es danach noch unter LOW_FPS liegt, auf 60 %.
const SLOW_FPS := 50.0
const LOW_FPS := 40.0
const STEPS: Array[float] = [1.0, 0.75, 0.6]
## Längere Bilder (z. B. App im Hintergrund, Laden) zählen nicht.
const MAX_DELTA := 0.25

## Weitere Viewports, die mitskaliert werden (z. B. das Kapitel-Brett).
var extra_viewports: Array[Viewport] = []
var _step := 0
var _t := 0.0
var _frames := 0
var _time := 0.0


func _process(delta: float) -> void:
	if delta > MAX_DELTA:
		return
	_t += delta
	if _t < WARMUP:
		return
	_frames += 1
	_time += delta
	if _t < WARMUP + MEASURE:
		return
	var fps := _frames / maxf(_time, 0.001)
	var next := next_step(_step, fps)
	_t = 0.0
	_frames = 0
	_time = 0.0
	if next == _step:
		set_process(false)
		return
	_step = next
	_apply(STEPS[_step])
	print("PerfGuard: %.0f fps -> 3D-Auflösung %d %%" % [fps, int(STEPS[_step] * 100)])
	if _step >= STEPS.size() - 1:
		set_process(false)


## Nächste Stufe für die gemessene Bildrate (gleich = fertig).
static func next_step(step: int, fps: float) -> int:
	if step == 0 and fps < SLOW_FPS:
		return 1
	if step == 1 and fps < LOW_FPS:
		return 2
	return step


func _apply(scale: float) -> void:
	var vps: Array[Viewport] = [get_viewport()]
	vps.append_array(extra_viewports)
	for vp in vps:
		if is_instance_valid(vp):
			vp.scaling_3d_scale = scale
