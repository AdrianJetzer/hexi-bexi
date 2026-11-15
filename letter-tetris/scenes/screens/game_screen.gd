extends Control
## Spiel-Screen im Lauf-Modus (siehe spec/run-mode.md, spec/screens.md):
## Auftrag als Block-Zeilen über dem 3D-Spielfeld, gefundene Buchstaben fliegen hinein.
## Unten Level, Rekord, Münzen und die Hilfen; oben rechts „Aufgeben“.
## Grundsatz: Symbole statt Text.

const BALANCE: GameBalance = preload("res://data/balance.tres")
const CURVE: QuestCurve = preload("res://data/quest_curve.tres")
const LANG: LanguageData = preload("res://data/languages/de/language.tres")

const TEXT := Color(0.85, 0.92, 1.0)
const TEXT_DIM := Color(0.6, 0.66, 0.85)
const ACCENT := Color(1.0, 0.84, 0.6)
const GLOW := Color(0.55, 0.95, 1.0)

## Anteile der Bildschirmhöhe/-breite für die Bereiche.
const SIDE_MARGIN := 0.03
const TOP_AREA := 0.2
const BOTTOM_AREA := 0.25

## Flug eines Buchstabens vom Stein in den Block (Sekunden) und Abstand zwischen Buchstaben.
const FLY_TIME := 0.5
const FLY_STAGGER := 0.07
## Kurze Pause nach dem letzten Buchstaben, bevor ein gelöster Auftrag verschwindet.
const DONE_PAUSE := 0.35
## Pulsieren des Auffüllen-Knopfs, wenn kein gültiges Wort passt: Dauer je halbem Puls, Größe, Helligkeit.
const PULSE_HALF := 0.7
const PULSE_SCALE := 1.06
const PULSE_BRIGHT := Color(1.35, 1.3, 1.15)

var session: RunSession

var _dictionary: WordDictionary
var _common: WordDictionary
var _board: BoardView3D
var _blocks: QuestBlocks
## Ebene für fliegende Buchstaben (über allem außer den Overlays).
var _fly_layer: Control
var _level_label: Label
var _coins_label: Label
var _refill_button: Button
var _swap_button: Button
var _clear_button: Button
var _hint_button: Button
var _replace_button: Button
var _solve_button: Button
var _joker_button: Button
var _shuffle_button: Button
var _magnet_button: Button
var _split_button: Button
var _scan_button: Button
var _complete_button: Button
## Welche Antipp-Hilfe gerade aktiv ist: "", "replace", "magnet".
var _tap_action: String = ""
var _give_up_button: Button
var _confirm: ColorRect
var _summary: ColorRect
var _summary_label: Label
## Nach dem Ende: Lösung ansehen, dann „Weiter“ zur Bilanz.
var _continue_button: Button
## Läuft gerade der Abschluss eines Auftrags? Dann wartet der nächste.
var _completing: bool = false
var _pending_quest: Quest
## Dauer des zuletzt gestarteten Flugs (bis der letzte Buchstabe ankommt).
var _last_flight: float = 0.0
var _sequence: Tween
var _refill_pulse: Tween
var _pulse_check_queued: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Berührungen nicht hier abfangen, sondern ans Spielfeld (_unhandled_input) durchlassen.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dictionary = WordDictionary.from_file(LANG.words_path)
	_common = WordDictionary.from_file(LANG.common_words_path)
	_build_ui()
	get_viewport().size_changed.connect(_relayout)
	new_run()


## Neuen Lauf starten (Level 1).
func new_run(seed_value: int = -1) -> void:
	if _sequence:
		_sequence.kill()
	_completing = false
	_pending_quest = null
	for c in _fly_layer.get_children():
		c.queue_free()
	session = RunSession.new(BALANCE, CURVE, LANG, _dictionary, seed_value, _common)
	session.quest_started.connect(_on_quest_started)
	session.quest_completed.connect(_on_quest_completed)
	session.coins_changed.connect(func(_c: int) -> void: _update_labels())
	session.level_changed.connect(func(_l: int) -> void: _update_labels())
	session.word_accepted.connect(_on_word_accepted)
	session.row_filled.connect(_on_row_filled)
	session.quest_reshaped.connect(func(q: Quest) -> void: _blocks.show_quest(q))
	session.scan_shown.connect(func(cells: Array[Vector2i]) -> void: _board.show_scan(cells))
	session.tile_spawned.connect(func(_c: Vector2i, _l: String) -> void: _update_labels())
	session.tile_changed.connect(func(_c: Vector2i, _l: String) -> void: _update_labels())
	session.run_ended.connect(_on_run_ended)
	session.hint_changed.connect(func(cells: Array[Vector2i]) -> void: _board.show_hint(cells))
	session.tiles_removed.connect(func(_c: Array[Vector2i]) -> void: _queue_pulse_check())
	session.quest_progress.connect(func(_q: Quest) -> void: _queue_pulse_check())
	session.quest_reshaped.connect(func(_q: Quest) -> void: _queue_pulse_check())
	_summary.visible = false
	_continue_button.visible = false
	for b in _help_buttons():
		b.visible = true
	_confirm.visible = false
	_board.setup(session)
	_relayout()
	session.start()
	_update_labels()


# --- Aufbau ---------------------------------------------------------------------

func _build_ui() -> void:
	_board = BoardView3D.new()
	add_child(_board)
	_board.cell_tapped.connect(_on_cell_tapped)
	_board.prefix_swiped.connect(_on_prefix_swiped)

	_blocks = QuestBlocks.new()
	add_child(_blocks)

	_level_label = _label(36, TEXT_DIM)
	_coins_label = _label(44, ACCENT)
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_refill_button = _button("", 26)
	_refill_button.pressed.connect(func() -> void:
		_set_replace_mode(false)
		session.refill())
	_swap_button = _button("", 26)
	_swap_button.pressed.connect(func() -> void:
		_set_replace_mode(false)
		session.swap())
	_clear_button = _button("", 26)
	_clear_button.pressed.connect(func() -> void:
		_set_replace_mode(false)
		if session.clear_useless().is_empty():
			# Keine Steine im Feld: Knopf wackelt (kostet nichts).
			_shake(_clear_button))
	_hint_button = _button("", 26)
	_hint_button.pressed.connect(_on_hint_pressed)
	_replace_button = _button("", 26)
	_replace_button.toggle_mode = true
	_replace_button.toggled.connect(func(on: bool) -> void: _set_tap_action("replace" if on else ""))
	_magnet_button = _button("", 26)
	_magnet_button.toggle_mode = true
	_magnet_button.toggled.connect(func(on: bool) -> void: _set_tap_action("magnet" if on else ""))
	_joker_button = _button("", 26)
	_joker_button.pressed.connect(func() -> void:
		_set_replace_mode(false)
		if session.joker() == RunSession.NO_CELL:
			_shake(_joker_button))
	_shuffle_button = _button("", 26)
	_shuffle_button.pressed.connect(func() -> void:
		_set_replace_mode(false)
		if session.shuffle().is_empty():
			_shake(_shuffle_button))
	_split_button = _button("", 26)
	_split_button.pressed.connect(func() -> void:
		_set_replace_mode(false)
		if not session.split():
			_shake(_split_button))
	_scan_button = _button("", 26)
	_scan_button.pressed.connect(func() -> void:
		_set_replace_mode(false)
		if session.scan().is_empty():
			_shake(_scan_button))
	_complete_button = _button("", 21)
	_complete_button.toggle_mode = true
	_complete_button.toggled.connect(func(on: bool) -> void: _set_tap_action("complete" if on else ""))
	_solve_button = _button("", 26)
	_solve_button.pressed.connect(func() -> void:
		_set_replace_mode(false)
		if not session.solve():
			_shake(_solve_button))

	_give_up_button = _button("Aufgeben", 34)
	_give_up_button.flat = true
	_give_up_button.add_theme_color_override("font_color", TEXT_DIM)
	_give_up_button.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_give_up_button.pressed.connect(func() -> void: _confirm.visible = true)

	_continue_button = _button("Weiter", 56)
	_continue_button.visible = false
	_continue_button.pressed.connect(func() -> void:
		_continue_button.visible = false
		_summary.visible = true)

	_fly_layer = Control.new()
	_fly_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fly_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fly_layer)

	# Nachfrage „Aufgeben?“
	var c := _overlay("Aufgeben?")
	_confirm = c[0]
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 40)
	(c[1] as VBoxContainer).add_child(row)
	var yes := _button("Ja", 56, row)
	yes.custom_minimum_size = Vector2(260, 130)
	yes.pressed.connect(_on_confirm_give_up)
	var no := _button("Nein", 56, row)
	no.custom_minimum_size = Vector2(260, 130)
	no.pressed.connect(func() -> void: _confirm.visible = false)

	# Bilanz
	var s := _overlay("")
	_summary = s[0]
	_summary_label = s[2]
	var again := _button("Nochmal", 64, s[1])
	again.custom_minimum_size = Vector2(520, 140)
	again.pressed.connect(func() -> void: new_run())


## Halbtransparente Ebene mit zentrierter Spalte. Gibt [Ebene, Spalte, Titel] zurück.
func _overlay(title: String) -> Array:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.visible = false
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 56)
	center.add_child(box)
	var l := Label.new()
	l.text = title
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 68)
	l.add_theme_color_override("font_color", TEXT)
	box.add_child(l)
	return [bg, box, l]


func _label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _button(text: String, size: int, parent: Node = self) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	parent.add_child(b)
	return b


## Hilfe-Knöpfe in Anzeige-Reihenfolge: von gratis bis teuer (gleicher Preis: Reihenfolge dieser Liste).
func _help_buttons() -> Array[Button]:
	var list := [
		[_refill_button, BALANCE.refill_price], [_hint_button, BALANCE.hint_price],
		[_replace_button, BALANCE.replace_price],
		[_swap_button, BALANCE.swap_price], [_clear_button, BALANCE.clear_price],
		[_joker_button, BALANCE.joker_price], [_magnet_button, BALANCE.magnet_price],
		[_split_button, BALANCE.split_price], [_shuffle_button, BALANCE.shuffle_price],
		[_complete_button, BALANCE.complete_price],
		[_scan_button, BALANCE.scan_price], [_solve_button, BALANCE.solve_price]]
	for i in list.size():
		list[i].append(i)
	list.sort_custom(func(a: Array, b: Array) -> bool:
		return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2]))
	var result: Array[Button] = []
	for e in list:
		result.append(e[0])
	return result


## Bildschirmbereich (Pixel) für das Spielfeld samt Rahmen.
func _board_area() -> Rect2:
	var s := get_viewport_rect().size
	var side := s.x * SIDE_MARGIN
	var top := s.y * TOP_AREA
	var bottom := s.y * BOTTOM_AREA
	return Rect2(side, top, s.x - 2.0 * side, s.y - top - bottom)


func _relayout() -> void:
	var s := get_viewport_rect().size
	if _board.session != null:
		_board.fit_to_screen(_board_area(), s)
	var side := s.x * SIDE_MARGIN
	var inner := s.x - 2.0 * side
	_give_up_button.position = Vector2(s.x - side * 0.5 - s.x * 0.3, s.y * 0.012)
	_give_up_button.size = Vector2(s.x * 0.3, 70)
	# Blöcke zwischen „Aufgeben“ und Spielfeld.
	var blocks_top := s.y * 0.05
	_blocks.layout(Rect2(side, blocks_top, inner, s.y * TOP_AREA - blocks_top - s.y * 0.01))

	var info_top := s.y * (1.0 - BOTTOM_AREA) + s.y * 0.01
	_level_label.position = Vector2(side, info_top + 10)
	_level_label.size = Vector2(inner * 0.55, 60)
	_coins_label.position = Vector2(side + inner * 0.55, info_top + 5)
	_coins_label.size = Vector2(inner * 0.45, 60)
	var gap := 12.0
	var buttons := _help_buttons()
	# Vorläufig (zum Testen): Knöpfe in Reihen zu je 5.
	var per_row := 5
	var bw := (inner - (per_row - 1) * gap) / per_row
	_continue_button.position = Vector2(side + inner * 0.25, info_top + 80)
	_continue_button.size = Vector2(inner * 0.5, 120)
	for i in buttons.size():
		buttons[i].position = Vector2(side + (i % per_row) * (bw + gap), info_top + 70 + (i / per_row) * 100)
		buttons[i].size = Vector2(bw, 90)
	_update_labels()


func _update_labels() -> void:
	if session == null:
		return
	_level_label.text = "Level %d · Rekord %d" % [session.level(), maxi(SaveData.best_level(), session.level())]
	_coins_label.text = "Münzen %d" % session.coins
	var price := session.refill_price()
	_refill_button.text = "Auffüllen\n%s" % ("gratis" if price == 0 else "−%d" % price)
	_refill_button.disabled = not session.can_refill()
	_swap_button.text = "Tauschen\n−%d" % BALANCE.swap_price
	_swap_button.disabled = not session.can_swap()
	_clear_button.text = "Aufräumen\n−%d" % BALANCE.clear_price
	_clear_button.disabled = not session.can_clear()
	_hint_button.text = "Tipp\n−%d" % BALANCE.hint_price
	_hint_button.disabled = not session.can_hint()
	_replace_button.text = "Ersetzen\n−%d" % BALANCE.replace_price
	_replace_button.disabled = not session.can_replace() and not _replace_button.button_pressed
	_joker_button.text = "Joker\n−%d" % BALANCE.joker_price
	_joker_button.disabled = not session.can_joker()
	_shuffle_button.text = "Mischen\n−%d" % BALANCE.shuffle_price
	_shuffle_button.disabled = not session.can_shuffle()
	_magnet_button.text = "Magnet\n−%d" % BALANCE.magnet_price
	_magnet_button.disabled = not session.can_magnet() and not _magnet_button.button_pressed
	_split_button.text = "Teilen\n−%d" % BALANCE.split_price
	_split_button.disabled = session.is_over or session.coins < BALANCE.split_price
	_complete_button.text = "Vervollständigen\n−%d" % BALANCE.complete_price
	_complete_button.disabled = not session.can_complete() and not _complete_button.button_pressed
	_scan_button.text = "Scan\n−%d" % BALANCE.scan_price
	_scan_button.disabled = not session.can_scan()
	_solve_button.text = "Lösen\n−%d" % BALANCE.solve_price
	_solve_button.disabled = not session.can_solve()
	if session.is_over:
		_set_replace_mode(false)
	_queue_pulse_check()


# --- Pulsierender Auffüllen-Knopf ----------------------------------------------------

## Prüfung einmal pro Frame bündeln (beim Auffüllen kommen mehrere Steine nacheinander).
func _queue_pulse_check() -> void:
	if _pulse_check_queued:
		return
	_pulse_check_queued = true
	_update_refill_pulse.call_deferred()


func _update_refill_pulse() -> void:
	_pulse_check_queued = false
	var want := session != null and not _completing and session.refill_suggested()
	if want and _refill_pulse == null:
		_refill_button.pivot_offset = _refill_button.size / 2.0
		_refill_pulse = create_tween().set_loops()
		_refill_pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_refill_pulse.tween_property(_refill_button, "scale", Vector2.ONE * PULSE_SCALE, PULSE_HALF)
		_refill_pulse.parallel().tween_property(_refill_button, "modulate", PULSE_BRIGHT, PULSE_HALF)
		_refill_pulse.tween_property(_refill_button, "scale", Vector2.ONE, PULSE_HALF)
		_refill_pulse.parallel().tween_property(_refill_button, "modulate", Color.WHITE, PULSE_HALF)
	elif not want and _refill_pulse != null:
		_refill_pulse.kill()
		_refill_pulse = null
		_refill_button.scale = Vector2.ONE
		_refill_button.modulate = Color.WHITE


# --- Fliegende Buchstaben ----------------------------------------------------------

## Mitte eines Steins auf dem Bildschirm (Oberseite des Hexagons).
func _tile_screen_pos(cell: Vector2i) -> Vector2:
	var top := _board.cell_position(cell) + Vector3(0, BoardView3D.THICKNESS * 0.5, 0)
	return _board.camera.unproject_position(top)


## Buchstaben eines Wegs nacheinander in eine Block-Zeile fliegen lassen.
## Gibt die Dauer zurück, bis der letzte angekommen ist.
func _fly_word(word: String, cells: Array[Vector2i], row: int) -> float:
	var size := _blocks.block_size
	for i in cells.size():
		var l := Label.new()
		l.text = word[i]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", int(size * 0.62))
		l.add_theme_color_override("font_color", QuestBlocks.LETTER)
		l.add_theme_color_override("font_outline_color", GLOW)
		l.add_theme_constant_override("outline_size", 6)
		l.size = Vector2.ONE * size
		l.pivot_offset = l.size / 2.0
		l.position = _tile_screen_pos(cells[i]) - l.size / 2.0
		l.modulate.a = 0.0
		_fly_layer.add_child(l)
		var target := _blocks.block_center(row, i) - l.size / 2.0
		var t := l.create_tween()
		t.tween_interval(i * FLY_STAGGER)
		t.tween_property(l, "modulate:a", 1.0, 0.06)
		t.set_parallel(true)
		t.tween_property(l, "position", target, FLY_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		t.tween_property(l, "scale", Vector2.ONE * 1.35, FLY_TIME * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.chain().tween_property(l, "scale", Vector2.ONE, FLY_TIME * 0.5)
		var letter := word[i]
		var index := i
		t.chain().tween_callback(func() -> void:
			_blocks.put_letter(row, index, letter)
			l.queue_free())
	return (cells.size() - 1) * FLY_STAGGER + FLY_TIME + 0.06


## Münz-Gewinn kurz neben der Münzanzeige aufsteigen lassen.
func _show_reward(amount: int) -> void:
	var l := _label(48, ACCENT)
	l.text = "+%d" % amount
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.size = _coins_label.size
	l.position = _coins_label.position - Vector2(0, 50)
	var t := l.create_tween()
	t.set_parallel(true)
	t.tween_property(l, "position:y", l.position.y - 70, 1.1)
	t.tween_property(l, "modulate:a", 0.0, 1.1).set_delay(0.4)
	t.chain().tween_callback(l.queue_free)


# --- Signale --------------------------------------------------------------------

## Antipp-Modus für „Stein ersetzen“ an/aus (der gedrückte Knopf zeigt ihn an).
func _set_replace_mode(on: bool) -> void:
	_set_tap_action("replace" if on else "")


## Modus für Ersetzen oder Magnet (Antippen) oder Vervollständigen (Wortanfang wischen);
## "" = aus. Der gedrückte Knopf zeigt ihn an.
func _set_tap_action(action: String) -> void:
	_tap_action = action
	_board.tap_mode = action == "replace" or action == "magnet"
	_board.prefix_mode = action == "complete"
	_complete_button.set_pressed_no_signal(action == "complete")
	_replace_button.set_pressed_no_signal(action == "replace")
	_magnet_button.set_pressed_no_signal(action == "magnet")


func _on_cell_tapped(cell: Vector2i) -> void:
	var action := _tap_action
	_set_tap_action("")
	match action:
		"replace":
			session.replace(cell)
		"magnet":
			if session.magnet(cell).is_empty():
				_shake(_magnet_button)


## Vervollständigen: Wortanfang gewischt. Treffer: Weg leuchtet, Modus aus. Sonst wackeln, Modus bleibt.
func _on_prefix_swiped(path: Array[Vector2i]) -> void:
	if session.complete(path).is_empty():
		_board.shake_cells(path)
	else:
		_set_tap_action("")


func _on_hint_pressed() -> void:
	_set_replace_mode(false)
	if session.hint() == RunSession.NO_CELL:
		# Kein passendes Wort im Feld: Knopf wackelt (kostet nichts).
		_shake(_hint_button)


func _shake(c: Control) -> void:
	var x := c.position.x
	var t := c.create_tween()
	for dx in [12.0, -12.0, 8.0, -8.0, 0.0]:
		t.tween_property(c, "position:x", x + dx, 0.05)


func _on_quest_started(q: Quest) -> void:
	if _completing:
		_pending_quest = q
	else:
		_blocks.show_quest(q)
	_update_labels()


func _on_word_accepted(word: String, cells: Array[Vector2i], row: int) -> void:
	_last_flight = _fly_word(word, cells, row)


func _on_quest_completed(_q: Quest, reward: int) -> void:
	_completing = true
	if reward > 0:
		_show_reward(reward)
	# Erst alle Buchstaben ankommen lassen, dann Auftrag ausblenden und den nächsten zeigen.
	if _sequence:
		_sequence.kill()
	_sequence = create_tween()
	_sequence.tween_interval(_last_flight + DONE_PAUSE)
	_sequence.tween_callback(func() -> void:
		_blocks.finish(func() -> void:
			_completing = false
			if _pending_quest and not session.is_over:
				_blocks.show_quest(_pending_quest)
			_pending_quest = null
			_queue_pulse_check()))


## Lösen ohne Wort aus dem Feld: Buchstaben ploppen nacheinander direkt in der Zeile auf.
func _on_row_filled(row: int, word: String) -> void:
	for i in word.length():
		var letter := word[i]
		var index := i
		var t := create_tween()
		t.tween_interval(FLY_TIME * 0.5 + i * FLY_STAGGER)
		t.tween_callback(func() -> void: _blocks.put_letter(row, index, letter))
	_last_flight = maxf(_last_flight, FLY_TIME * 0.5 + word.length() * FLY_STAGGER)


func _on_confirm_give_up() -> void:
	_confirm.visible = false
	session.give_up()


func _on_run_ended(level: int, _reason: String) -> void:
	var new_record := SaveData.submit_level(level)
	_summary_label.text = "Lauf beendet\n\nLevel %d erreicht\n\nRekord: Level %d%s" % [
		level, SaveData.best_level(), "\nNeuer Rekord!" if new_record else ""]
	_update_labels()
	for b in _help_buttons():
		b.visible = false
	_continue_button.visible = true
	# Lösung zeigen: Steine blinken, Buchstaben fliegen in die passende Zeile.
	var solution := session.solution()
	if session.quest != null and not solution.is_empty():
		var word := session.word_for(solution)
		_board.show_hint(solution)
		_fly_word(word, solution, session.quest.free_row_for(word))
