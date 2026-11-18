class_name QuestBlocks
extends Control
## Auftrag als Block-Zeilen über dem Spielfeld (siehe spec/run-mode.md, „Block-Zeilen“):
## 1–3 Zeilen leerer Blöcke, zentriert. Gefundene Buchstaben werden mit put_letter()
## eingetragen (die Flug-Animation macht der Spiel-Screen).

const BLOCK_BG := Color(0.08, 0.12, 0.26, 0.55)
const BLOCK_BORDER := Color(0.55, 0.95, 1.0, 0.55)
const FILLED_BG := Color(0.12, 0.42, 0.6, 0.85)
const FILLED_BORDER := Color(0.75, 1.0, 1.0, 1.0)
const LETTER := Color(1.0, 0.97, 0.9)

## Größte Zeile und Zeilenzahl, nach denen sich die Blockgröße richtet (damit sie nicht springt).
const MAX_COLS := 8
const MAX_ROWS := 3
## Abstand zwischen Blöcken (Anteil der Blockgröße).
const GAP := 0.18
## Randbreite der Blöcke (Pixel); die Vorschau-Füllung liegt innerhalb.
const BORDER := 3

var block_size: float = 80.0

## _blocks[row][i] = {"panel": Panel, "glow": Panel, "label": Label}
var _blocks: Array = []
var _rows := PackedInt32Array()
var _fade: Tween
## Wisch-Vorschau (spec/screens.md v4.35): Blöcke füllen sich beim Wischen türkis wie gelöste,
## nur leicht durchsichtig, mit weißem Buchstaben (Rand bleibt gleich); kurzes Aufblitzen beim
## Erscheinen, beim Loslassen blenden sie aus; Puls bei „zu lang“.
const PREVIEW_FILL := Color(0.12, 0.42, 0.6, 0.6)
## Stärke: 1 = ruhig gefüllt, darüber heller (Aufblitzen), 0 = aus.
const GLOW_REST := 1.0
const GLOW_PEAK := 1.7
const GLOW_IN := 0.05
const GLOW_SETTLE := 0.25
const GLOW_OUT_PEAK := 0.08
const GLOW_OUT := 0.28
var _preview_panels: Array[Panel] = []
var _pulse: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Bereich festlegen; die Blockgröße passt sich an (gleich für alle Aufträge).
func layout(rect: Rect2) -> void:
	position = rect.position
	size = rect.size
	_fit()
	_place()


## Blockgröße: passend für MAX_ROWS Zeilen (gleich für alle Aufträge); nur bei mehr Zeilen
## (z. B. nach „Teilen“) kleiner.
func _fit() -> void:
	var n := maxi(MAX_ROWS, _rows.size())
	var by_width := size.x / (MAX_COLS + (MAX_COLS - 1) * GAP)
	var by_height := size.y / (n + (n - 1) * GAP)
	block_size = minf(by_width, by_height)


## Neuen Auftrag zeigen (Blöcke ploppen nacheinander auf).
func show_quest(q: Quest, animate: bool = true) -> void:
	if _fade:
		_fade.kill()
	modulate.a = 1.0
	for row in _blocks:
		for b in row:
			b["panel"].queue_free()
	_blocks.clear()
	_rows = q.rows.duplicate()
	_fit()
	var k := 0
	for r in _rows.size():
		var row: Array = []
		for i in _rows[r]:
			var panel := Panel.new()
			panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.add_theme_stylebox_override("panel", _style(false))
			add_child(panel)
			var glow := _make_glow()
			panel.add_child(glow)
			glow.add_child(_make_ghost())
			var label := Label.new()
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.add_theme_color_override("font_color", LETTER)
			label.set_anchors_preset(Control.PRESET_FULL_RECT)
			panel.add_child(label)
			row.append({"panel": panel, "glow": glow, "label": label})
			if animate:
				panel.scale = Vector2.ZERO
				var t := panel.create_tween()
				t.tween_interval(k * 0.035)
				t.tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			k += 1
		_blocks.append(row)
	_place()
	for r in q.rows.size():
		if r < q.filled.size() and q.filled[r] != "":
			for i in q.filled[r].length():
				put_letter(r, i, q.filled[r][i], false)


## Buchstaben in einen Block setzen (mit kurzem Aufploppen).
func put_letter(row: int, i: int, letter: String, pop: bool = true) -> void:
	if row < 0 or row >= _blocks.size() or i < 0 or i >= _blocks[row].size():
		return
	var b: Dictionary = _blocks[row][i]
	(b["label"] as Label).text = letter
	(b["panel"] as Panel).add_theme_stylebox_override("panel", _style(true))
	if pop:
		var panel: Panel = b["panel"]
		var t := panel.create_tween()
		t.tween_property(panel, "scale", Vector2.ONE * 1.18, 0.07)
		t.tween_property(panel, "scale", Vector2.ONE, 0.12)


## Wisch-Vorschau: `count` Buchstaben sind gerade verbunden. In der kürzesten freien Zeile, in die
## so ein Wort noch passt, füllen sich die ersten `count` Blöcke (neu dazukommende blitzen kurz auf).
## Passt es in keine freie Zeile (zu lang), blitzen die längsten freien Zeilen kurz zweimal auf.
## 0 = Vorschau aus: alles blendet mit einem letzten Puls aus.
func preview(word: String) -> void:
	var count := word.length()
	var want: Array[Panel] = []
	var best := -1
	var longest := 0
	if count > 0:
		for r in _blocks.size():
			if not _row_free(r):
				continue
			var n: int = _blocks[r].size()
			longest = maxi(longest, n)
			if n >= count and (best < 0 or n < _blocks[best].size()):
				best = r
		if best >= 0:
			for i in count:
				want.append(_blocks[best][i]["panel"])
	for p in _preview_panels:
		if is_instance_valid(p) and not want.has(p):
			_glow_out(p)
	for i in want.size():
		var p := want[i]
		_ghost_of(p).text = word[i]
		if not _preview_panels.has(p):
			_glow_in(p)
	_preview_panels = want
	if count > 0 and best < 0 and longest > 0:
		_pulse_rows(longest)


func _row_free(r: int) -> bool:
	return not _blocks[r].is_empty() and (_blocks[r][0]["label"] as Label).text == ""


## Alle freien Zeilen der Länge n kurz zweimal aufblitzen lassen („zu viele Buchstaben“).
func _pulse_rows(n: int) -> void:
	if _pulse and _pulse.is_running():
		return
	var panels: Array[Panel] = []
	for r in _blocks.size():
		if _row_free(r) and _blocks[r].size() == n:
			for b in _blocks[r]:
				panels.append(b["panel"])
	if panels.is_empty():
		return
	_pulse = create_tween()
	for k in 2:
		_pulse.tween_callback(func() -> void:
			for p in panels:
				if is_instance_valid(p):
					_glow_flash(p))
		_pulse.tween_interval(0.22)


## Vorschau-Füllung im Block: innerhalb des Randes, unter dem Buchstaben.
func _make_glow() -> Panel:
	var glow := Panel.new()
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.visible = false
	glow.set_meta("v", 0.0)
	return glow


## Vorschau-Buchstabe in der Füllung (blendet mit ihr ein und aus).
func _make_ghost() -> Label:
	var l := Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.add_theme_color_override("font_color", LETTER)
	return l


func _ghost_of(panel: Panel) -> Label:
	return _glow_of(panel).get_child(0) as Label


func _glow_of(panel: Panel) -> Panel:
	for row in _blocks:
		for b in row:
			if b["panel"] == panel:
				return b["glow"]
	return null


func _set_glow(v: float, glow: Panel) -> void:
	if not is_instance_valid(glow):
		return
	glow.set_meta("v", v)
	glow.visible = v > 0.001
	var b := maxf(1.0, v / GLOW_REST)
	glow.modulate = Color(b, b, b, clampf(v / GLOW_REST, 0.0, 1.0))


func _glow_tween(panel: Panel) -> Tween:
	if panel.has_meta("glow_tween"):
		var old: Tween = panel.get_meta("glow_tween")
		if old:
			old.kill()
	var t := panel.create_tween()
	panel.set_meta("glow_tween", t)
	return t


func _glow_value(glow: Panel) -> float:
	return float(glow.get_meta("v", 0.0))


## Erscheinen: kurz heller und größer, dann ruhig gefüllt.
func _glow_in(panel: Panel) -> void:
	var glow := _glow_of(panel)
	if glow == null:
		return
	var t := _glow_tween(panel)
	t.tween_method(_set_glow.bind(glow), _glow_value(glow), GLOW_PEAK, GLOW_IN) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(panel, "scale", Vector2.ONE * 1.12, GLOW_IN) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t.tween_method(_set_glow.bind(glow), GLOW_PEAK, GLOW_REST, GLOW_SETTLE) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(panel, "scale", Vector2.ONE, GLOW_SETTLE) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Ausblenden: ein letzter kurzer Puls, dann verschwindet die Füllung.
func _glow_out(panel: Panel) -> void:
	var glow := _glow_of(panel)
	if glow == null:
		return
	var t := _glow_tween(panel)
	var from := _glow_value(glow)
	t.tween_method(_set_glow.bind(glow), from, maxf(from, GLOW_REST) * 1.3, GLOW_OUT_PEAK)
	t.tween_method(_set_glow.bind(glow), maxf(from, GLOW_REST) * 1.3, 0.0, GLOW_OUT) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(panel, "scale", Vector2.ONE, GLOW_OUT_PEAK)


## Kurzes Aufblitzen und wieder aus (für „zu viele Buchstaben“).
func _glow_flash(panel: Panel) -> void:
	var glow := _glow_of(panel)
	if glow == null:
		return
	var t := _glow_tween(panel)
	t.tween_method(_set_glow.bind(glow), 0.0, GLOW_PEAK, 0.08)
	t.parallel().tween_property(panel, "scale", Vector2.ONE * 1.1, 0.08)
	t.tween_method(_set_glow.bind(glow), GLOW_PEAK, 0.0, 0.14)
	t.parallel().tween_property(panel, "scale", Vector2.ONE, 0.14)


## Mitte eines Blocks in Koordinaten des Eltern-Controls (für den Flug).
func block_center(row: int, i: int) -> Vector2:
	if row < 0 or row >= _blocks.size() or i < 0 or i >= _blocks[row].size():
		return position + size / 2.0
	var panel: Panel = _blocks[row][i]["panel"]
	return position + panel.position + panel.size / 2.0


## Gelöster Auftrag: kurz aufleuchten, dann ausblenden. Ruft danach `done` auf.
func finish(done: Callable) -> void:
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(self, "modulate", Color(1.6, 1.6, 1.6, 1.0), 0.15)
	_fade.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.3)
	_fade.tween_callback(done)


func _place() -> void:
	var gap := block_size * GAP
	var n := _rows.size()
	var total_h := n * block_size + maxi(n - 1, 0) * gap
	var y := (size.y - total_h) / 2.0
	for r in n:
		var count := _rows[r]
		var w := count * block_size + (count - 1) * gap
		var x := (size.x - w) / 2.0
		for i in count:
			var panel: Panel = _blocks[r][i]["panel"]
			panel.position = Vector2(x + i * (block_size + gap), y)
			panel.size = Vector2.ONE * block_size
			panel.pivot_offset = panel.size / 2.0
			var glow: Panel = _blocks[r][i]["glow"]
			glow.position = Vector2.ONE * BORDER
			glow.size = panel.size - Vector2.ONE * BORDER * 2.0
			var fill := StyleBoxFlat.new()
			fill.bg_color = PREVIEW_FILL
			fill.set_corner_radius_all(maxi(int(block_size * 0.18) - BORDER, 0))
			glow.add_theme_stylebox_override("panel", fill)
			(_blocks[r][i]["label"] as Label).add_theme_font_size_override("font_size", int(block_size * 0.62))
			var ghost := glow.get_child(0) as Label
			ghost.add_theme_font_size_override("font_size", int(block_size * 0.62))
		y += block_size + gap


func _style(filled: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = FILLED_BG if filled else BLOCK_BG
	s.border_color = FILLED_BORDER if filled else BLOCK_BORDER
	s.set_border_width_all(BORDER)
	s.set_corner_radius_all(int(block_size * 0.18))
	if filled:
		s.shadow_color = Color(0.55, 0.95, 1.0, 0.45)
		s.shadow_size = 10
	return s
