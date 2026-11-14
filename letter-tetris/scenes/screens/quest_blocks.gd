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

var block_size: float = 80.0

## _blocks[row][i] = {"panel": Panel, "label": Label}
var _blocks: Array = []
var _rows := PackedInt32Array()
var _fade: Tween


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
			var label := Label.new()
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.add_theme_color_override("font_color", LETTER)
			label.set_anchors_preset(Control.PRESET_FULL_RECT)
			panel.add_child(label)
			row.append({"panel": panel, "label": label})
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
			(_blocks[r][i]["label"] as Label).add_theme_font_size_override("font_size", int(block_size * 0.62))
		y += block_size + gap


func _style(filled: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = FILLED_BG if filled else BLOCK_BG
	s.border_color = FILLED_BORDER if filled else BLOCK_BORDER
	s.set_border_width_all(3)
	s.set_corner_radius_all(int(block_size * 0.18))
	if filled:
		s.shadow_color = Color(0.55, 0.95, 1.0, 0.45)
		s.shadow_size = 10
	return s
