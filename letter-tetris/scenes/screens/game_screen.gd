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

## Seitenrand (Anteil der Spaltenbreite).
const SIDE_MARGIN := 0.03
## Das Spiel ist fürs Hochformat gebaut: Auf breiten Bildschirmen (PC, Tablet quer) liegt alles
## in einer mittigen Spalte, höchstens so breit wie Höhe · MAX_COLUMN_ASPECT.
const MAX_COLUMN_ASPECT := 0.6
## Oben: Oberkante der Block-Zeilen (unter „Aufgeben“) und Abstand zum Spielfeld (Pixel).
## Der Bereich hat immer Platz für QuestBlocks.MAX_ROWS Zeilen mit MAX_COLS Blöcken.
const BLOCKS_TOP := 100.0
const BLOCKS_GAP_BELOW := 24.0
## Info-Zeile (über dem Spielfeld) und Hilfe-Knöpfe unten (Pixel).
const INFO_HEIGHT := 64.0
const BUTTON_HEIGHT := 155.0
const BUTTON_STEP := 168.0
## Mit Roguelike-Draft höchstens 6 Knöpfe: 2 Reihen zu 3. Ohne Draft (Test-Modus) alle in Reihen zu 5.
const BUTTONS_PER_ROW := 3
const BUTTON_ROWS := 2
const BUTTONS_PER_ROW_ALL := 5
## Hinweis „Noch n Level bis zum Power-up“ über den Knöpfen.
const OFFER_HINT_HEIGHT := 52.0
const OFFER_HINT_FONT := 32
## Schrift der Hilfe-Knöpfe (klein: für lange Namen wie „Vervollständigen“).
const BUTTON_FONT := 33
const BUTTON_FONT_SMALL := 23
const BOTTOM_PAD := 24.0
## Schriftgröße der Info-Zeile (Level · Rekord links, Münzen rechts in Gold).
const INFO_FONT := 40

## Hilfen: Reihenfolge bei gleichem Preis, Namen auf Knöpfen und Karten, kurze Erklärung.
const HELP_ORDER: PackedStringArray = ["refill", "hint", "replace", "shuffle", "clear", "joker",
		"shorten", "swap", "split", "complete", "magnet", "scan", "strike", "solve"]
const HELP_NAMES := {
	"refill": "Auffüllen", "hint": "Tipp", "replace": "Ersetzen", "shuffle": "Mischen",
	"clear": "Aufräumen", "joker": "Joker", "shorten": "Kürzen", "swap": "Tauschen",
	"split": "Teilen", "complete": "Vervollständigen", "magnet": "Magnet", "scan": "Scan",
	"strike": "Streichen", "solve": "Lösen",
}
const HELP_INFO := {
	"hint": "Zeigt Buchstabe für Buchstabe ein passendes Wort.",
	"replace": "Ein Stein deiner Wahl bekommt einen neuen Buchstaben.",
	"shuffle": "Alle Buchstaben werden neu verteilt.",
	"clear": "Entfernt bis zu 5 wenig hilfreiche Steine.",
	"joker": "Ein Stein wird zum Joker für jeden Buchstaben.",
	"shorten": "Die längste Zeile verliert einen Block.",
	"swap": "5 Steine neu – legt ein Wort, wenn du feststeckst.",
	"split": "Halbiert die längste Zeile (ab 6 Blöcken).",
	"complete": "Wisch einen Wortanfang, das Spiel zeigt den Rest.",
	"magnet": "Tipp einen Stein an: Um ihn herum entsteht ein Wort.",
	"scan": "Zeigt die Steine eines Worts für die längste Zeile.",
	"strike": "Die längste freie Zeile fällt weg.",
	"solve": "Löst den ganzen Auftrag (ohne Belohnung).",
}

## Flug eines Buchstabens vom Stein in den Block (Sekunden) und Abstand zwischen Buchstaben.
const FLY_TIME := 0.5
const FLY_STAGGER := 0.07
## Kurze Pause nach dem letzten Buchstaben, bevor ein gelöster Auftrag verschwindet.
const DONE_PAUSE := 0.35
## Pulsieren des Auffüllen-Knopfs, wenn kein gültiges Wort passt: Dauer je halbem Puls, Größe, Helligkeit.
const PULSE_HALF := 0.7
const PULSE_BRIGHT := Color(1.35, 1.3, 1.15)
## Auffüllen-Hinweis: Schrift blinkt dezent zwischen Weiß und dunklem Weiß (je halbe Sekunde).
const BLINK_HALF := 0.5
const BLINK_BRIGHT := Color(1.0, 1.0, 1.0)
const BLINK_DIM := Color(0.5, 0.52, 0.6)

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
var _shorten_button: Button
var _scan_button: Button
var _complete_button: Button
var _strike_button: Button
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
## Hilfe-ID → Knopf.
var _buttons: Dictionary = {}
var _offer_hint: Label
var _offer_hint_pulse: Tween
## Auswahl-Bildschirm für Power-ups und Upgrades.
var _choice: ColorRect
var _choice_title: Label
var _choice_cards: VBoxContainer


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
	session.helps_changed.connect(_relayout)
	_summary.visible = false
	_continue_button.visible = false
	_choice.visible = false
	_offer_hint.visible = true
	_confirm.visible = false
	_board.setup(session)
	_relayout()
	session.start()
	_relayout()


# --- Aufbau ---------------------------------------------------------------------

func _build_ui() -> void:
	_board = BoardView3D.new()
	add_child(_board)
	_board.cell_tapped.connect(_on_cell_tapped)
	_board.prefix_swiped.connect(_on_prefix_swiped)

	_blocks = QuestBlocks.new()
	add_child(_blocks)

	_level_label = _label(INFO_FONT, TEXT_DIM)
	_coins_label = _label(INFO_FONT, ACCENT)
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for l in [_level_label, _coins_label]:
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_refill_button = _button("", BUTTON_FONT)
	_refill_button.pressed.connect(func() -> void:
		_set_replace_mode(false)
		session.refill())
	_swap_button = _button("", BUTTON_FONT)
	_swap_button.pressed.connect(func() -> void:
		_set_replace_mode(false)
		session.swap())
	_clear_button = _button("", BUTTON_FONT)
	_clear_button.pressed.connect(func() -> void:
		_set_replace_mode(false)
		if session.clear_useless().is_empty():
			# Keine Steine im Feld: Knopf wackelt (kostet nichts).
			_shake(_clear_button))
	_hint_button = _button("", BUTTON_FONT)
	_hint_button.pressed.connect(_on_hint_pressed)
	_replace_button = _button("", BUTTON_FONT)
	_replace_button.toggle_mode = true
	_replace_button.toggled.connect(func(on: bool) -> void: _set_tap_action("replace" if on else ""))
	_magnet_button = _button("", BUTTON_FONT)
	_magnet_button.toggle_mode = true
	_magnet_button.toggled.connect(func(on: bool) -> void: _set_tap_action("magnet" if on else ""))
	_joker_button = _button("", BUTTON_FONT)
	_joker_button.pressed.connect(func() -> void:
		_set_replace_mode(false)
		if session.joker() == RunSession.NO_CELL:
			_shake(_joker_button))
	_shuffle_button = _button("", BUTTON_FONT)
	_shuffle_button.pressed.connect(func() -> void:
		_set_replace_mode(false)
		if session.shuffle().is_empty():
			_shake(_shuffle_button))
	_shorten_button = _button("", BUTTON_FONT)
	_shorten_button.pressed.connect(func() -> void:
		_set_replace_mode(false)
		if not session.shorten():
			_shake(_shorten_button))
	_split_button = _button("", BUTTON_FONT)
	_split_button.pressed.connect(func() -> void:
		_set_replace_mode(false)
		if not session.split():
			_shake(_split_button))
	_scan_button = _button("", BUTTON_FONT)
	_scan_button.pressed.connect(func() -> void:
		_set_replace_mode(false)
		if session.scan().is_empty():
			_shake(_scan_button))
	_complete_button = _button("", BUTTON_FONT_SMALL)
	_complete_button.toggle_mode = true
	_complete_button.toggled.connect(func(on: bool) -> void: _set_tap_action("complete" if on else ""))
	_strike_button = _button("", BUTTON_FONT)
	_strike_button.pressed.connect(func() -> void:
		_set_replace_mode(false)
		if not session.strike():
			_shake(_strike_button))
	_solve_button = _button("", BUTTON_FONT)
	_solve_button.pressed.connect(func() -> void:
		_set_replace_mode(false)
		if not session.solve():
			_shake(_solve_button))

	_buttons = {"refill": _refill_button, "hint": _hint_button, "replace": _replace_button,
		"shuffle": _shuffle_button, "clear": _clear_button, "joker": _joker_button,
		"shorten": _shorten_button, "swap": _swap_button, "split": _split_button,
		"complete": _complete_button, "magnet": _magnet_button, "scan": _scan_button,
		"strike": _strike_button, "solve": _solve_button}
	_offer_hint = _label(OFFER_HINT_FONT, TEXT_DIM)
	_offer_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_offer_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

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

	# Auswahl: Power-up oder Upgrade
	var ch := _overlay("")
	_choice = ch[0]
	_choice_title = ch[2]
	_choice_title.add_theme_font_size_override("font_size", 52)
	_choice_title.add_theme_color_override("font_color", ACCENT)
	(ch[1] as VBoxContainer).add_theme_constant_override("separation", 40)
	_choice_cards = VBoxContainer.new()
	_choice_cards.add_theme_constant_override("separation", 24)
	(ch[1] as VBoxContainer).add_child(_choice_cards)

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


## Sichtbare Hilfe-Knöpfe (freigeschaltete) in Anzeige-Reihenfolge: von gratis bis teuer
## (aktueller Preis; gleicher Preis: Reihenfolge von HELP_ORDER).
func _help_buttons() -> Array[Button]:
	var ids: Array = []
	for id in HELP_ORDER:
		if session == null or session.has_help(id):
			ids.append(id)
	ids.sort_custom(func(a: String, b: String) -> bool:
		var pa := _help_price(a)
		var pb := _help_price(b)
		return pa < pb or (pa == pb and HELP_ORDER.find(a) < HELP_ORDER.find(b)))
	var result: Array[Button] = []
	for id in ids:
		result.append(_buttons[id])
	return result


func _help_price(id: String) -> int:
	return session.price(id) if session != null else int(BALANCE.get(id + "_price"))


func _per_row() -> int:
	return BUTTONS_PER_ROW if BALANCE.draft_enabled else BUTTONS_PER_ROW_ALL


## Spalte (x, Breite) für alle Inhalte: im Hochformat der ganze Bildschirm, sonst mittig.
func _column(s: Vector2) -> Vector2:
	var w := minf(s.x, s.y * MAX_COLUMN_ASPECT)
	return Vector2((s.x - w) / 2.0, w)


## Höhe des oberen Bereichs: „Aufgeben“, Platz für 3 Block-Zeilen in voller Blockgröße und die Info-Zeile.
func _top_height(s: Vector2) -> float:
	var inner := _column(s).y * (1.0 - 2.0 * SIDE_MARGIN)
	var b := inner / (QuestBlocks.MAX_COLS + (QuestBlocks.MAX_COLS - 1) * QuestBlocks.GAP)
	var rows := QuestBlocks.MAX_ROWS
	return BLOCKS_TOP + b * (rows + (rows - 1) * QuestBlocks.GAP) + BLOCKS_GAP_BELOW + INFO_HEIGHT


## Höhe des unteren Bereichs: Hinweis und alle Reihen Hilfe-Knöpfe.
func _bottom_height() -> float:
	var rows := BUTTON_ROWS
	var hint := OFFER_HINT_HEIGHT
	if not BALANCE.draft_enabled:
		rows = ceili((RunSession.HELP_IDS.size() + 2) / float(BUTTONS_PER_ROW_ALL))
		hint = 0.0
	return hint + rows * BUTTON_STEP + BOTTOM_PAD + 12.0


## Bildschirmbereich (Pixel) für das Spielfeld samt Rand.
func _board_area() -> Rect2:
	var s := get_viewport_rect().size
	var col := _column(s)
	var side := col.x + col.y * SIDE_MARGIN
	var top := _top_height(s)
	return Rect2(side, top, col.y * (1.0 - 2.0 * SIDE_MARGIN), s.y - top - _bottom_height())


func _relayout() -> void:
	var s := get_viewport_rect().size
	if _board.session != null:
		_board.fit_to_screen(_board_area(), s)
	var col := _column(s)
	var margin := col.y * SIDE_MARGIN
	var side := col.x + margin
	var inner := col.y - 2.0 * margin
	_give_up_button.position = Vector2(col.x + col.y - margin * 0.5 - col.y * 0.3, s.y * 0.012)
	_give_up_button.size = Vector2(col.y * 0.3, 70)
	# Blöcke zwischen „Aufgeben“ und Spielfeld (immer Platz für 3 Zeilen).
	var info_y := _top_height(s) - INFO_HEIGHT
	_blocks.layout(Rect2(side, BLOCKS_TOP, inner, info_y - BLOCKS_TOP - BLOCKS_GAP_BELOW))

	# Info-Zeile direkt über dem Spielfeld: Level · Rekord links, Münzen rechts.
	_level_label.position = Vector2(side, info_y)
	_level_label.size = Vector2(inner * 0.6, INFO_HEIGHT)
	_coins_label.position = Vector2(side + inner * 0.6, info_y)
	_coins_label.size = Vector2(inner * 0.4, INFO_HEIGHT)
	var hint_h := OFFER_HINT_HEIGHT if BALANCE.draft_enabled else 0.0
	# Unten: nur der Hinweis „Noch n Level …“ und die Knöpfe.
	var info_top := s.y - _bottom_height() + 12.0
	_offer_hint.position = Vector2(side, info_top)
	_offer_hint.size = Vector2(inner, hint_h)
	var buttons_top := info_top + hint_h
	var gap := 12.0
	var buttons := _help_buttons()
	var per_row := _per_row()
	var bw := (inner - (per_row - 1) * gap) / per_row
	_continue_button.position = Vector2(side + inner * 0.25, info_top + 10)
	_continue_button.size = Vector2(inner * 0.5, 120)
	for b in _buttons.values():
		b.visible = false
	for i in buttons.size():
		buttons[i].visible = not _continue_button.visible and not _summary.visible
		buttons[i].position = Vector2(side + (i % per_row) * (bw + gap),
				buttons_top + (i / per_row) * BUTTON_STEP)
		buttons[i].size = Vector2(bw, BUTTON_HEIGHT)
		buttons[i].pivot_offset = buttons[i].size / 2.0
	_update_labels()


func _update_labels() -> void:
	if session == null:
		return
	_level_label.text = "Level %d · Rekord %d" % [session.level(), maxi(SaveData.best_level(), session.level())]
	_coins_label.text = "Münzen %d" % session.coins
	for id in _buttons:
		var b: Button = _buttons[id]
		var p := session.price(id)
		b.text = "%s\n%s" % [HELP_NAMES[id], "gratis" if p == 0 else "−%d" % p]
	_refill_button.disabled = not session.can_refill()
	_swap_button.disabled = not session.can_swap()
	_clear_button.disabled = not session.can_clear()
	_hint_button.disabled = not session.can_hint()
	_replace_button.disabled = not session.can_replace() and not _replace_button.button_pressed
	_joker_button.disabled = not session.can_joker()
	_shuffle_button.disabled = not session.can_shuffle()
	_magnet_button.disabled = not session.can_magnet() and not _magnet_button.button_pressed
	# Kürzen, Teilen, Streichen: nur Geld prüfen; passt die Lage nicht, wackelt der Knopf.
	for id in ["shorten", "split", "strike"]:
		_buttons[id].disabled = session.is_over or session.coins < session.price(id)
	_complete_button.disabled = not session.can_complete() and not _complete_button.button_pressed
	_scan_button.disabled = not session.can_scan()
	_solve_button.disabled = not session.can_solve()
	_update_offer_hint()
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
		var set_color := func(c: Color) -> void:
			_refill_button.add_theme_color_override("font_color", c)
			_refill_button.add_theme_color_override("font_hover_color", c)
		_refill_pulse = create_tween().set_loops()
		_refill_pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_refill_pulse.tween_method(set_color, BLINK_BRIGHT, BLINK_DIM, BLINK_HALF)
		_refill_pulse.tween_method(set_color, BLINK_DIM, BLINK_BRIGHT, BLINK_HALF)
	elif not want and _refill_pulse != null:
		_refill_pulse.kill()
		_refill_pulse = null
		_refill_button.remove_theme_color_override("font_color")
		_refill_button.remove_theme_color_override("font_hover_color")


# --- Power-ups und Upgrades -----------------------------------------------------------

## „Noch n Level bis zum Power-up/Upgrade“; bei 1 Level leuchtet der Hinweis.
func _update_offer_hint() -> void:
	var n := session.levels_until_offer() if BALANCE.draft_enabled else 0
	var kind := session.next_offer_kind()
	if n <= 0:
		_offer_hint.text = ""
	else:
		var what := "Power-up" if kind == "powerup" else "Upgrade"
		_offer_hint.text = ("Noch 1 Level bis zum %s" % what) if n == 1 else ("Noch %d Level bis zum %s" % [n, what])
	var glow := n == 1
	if glow and _offer_hint_pulse == null:
		_offer_hint.add_theme_color_override("font_color", ACCENT)
		_offer_hint_pulse = create_tween().set_loops()
		_offer_hint_pulse.tween_property(_offer_hint, "modulate", PULSE_BRIGHT, PULSE_HALF)
		_offer_hint_pulse.tween_property(_offer_hint, "modulate", Color.WHITE, PULSE_HALF)
	elif not glow and _offer_hint_pulse != null:
		_offer_hint_pulse.kill()
		_offer_hint_pulse = null
		_offer_hint.modulate = Color.WHITE
		_offer_hint.add_theme_color_override("font_color", TEXT_DIM)


## Liegt eine Auswahl an, Karten zeigen (nach der Abschluss-Animation des Auftrags).
func _show_choice() -> void:
	if session == null or session.offer.is_empty() or session.is_over:
		return
	_set_tap_action("")
	for c in _choice_cards.get_children():
		c.queue_free()
	var upgrade: bool = session.offer["kind"] == "upgrade"
	_choice_title.text = "Upgrade\nWelche Hilfe wird günstiger?" if upgrade else "Power-up\nWähle eine Hilfe"
	var w := _column(get_viewport_rect().size).y * 0.86
	for id in session.offer["options"]:
		var card := Button.new()
		card.custom_minimum_size = Vector2(w, 190)
		card.add_theme_font_size_override("font_size", 34)
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var p := session.price(id)
		var price_text := ("%d → %d" % [p, session.upgraded_price(id)]) if upgrade else str(p)
		card.text = "%s  ·  %s\n%s" % [HELP_NAMES[id], price_text, HELP_INFO[id]]
		var chosen: String = id
		card.pressed.connect(func() -> void:
			session.choose(chosen)
			_choice.visible = false
			_relayout())
		_choice_cards.add_child(card)
	_choice.visible = true


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
			_queue_pulse_check()
			_show_choice()))


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
	_offer_hint.visible = false
	_continue_button.visible = true
	# Lösung zeigen: Steine blinken, Buchstaben fliegen in die passende Zeile.
	var solution := session.solution()
	if session.quest != null and not solution.is_empty():
		var word := session.word_for(solution)
		_board.show_hint(solution)
		_fly_word(word, solution, session.quest.free_row_for(word))
