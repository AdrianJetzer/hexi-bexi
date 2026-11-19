extends Control
## Spiel-Screen im Lauf-Modus (siehe spec/run-mode.md, spec/screens.md):
## Auftrag als Block-Zeilen über dem 3D-Spielfeld, gefundene Buchstaben fliegen hinein.
## Unten Level, Rekord, Münzen und die Hilfen; oben rechts „Aufgeben“.
## Grundsatz: Symbole statt Text.

const BALANCE: GameBalance = preload("res://data/balance.tres")

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
## Hinweis „Noch n Level bis zum Power-up“ links unter dem Feld (Schrift wie die Info-Zeile).
## Farben der Power-up-Quadrate: Cyan, Violett, Pink, Gold (das Power-up-Level).
const OFFER_COLORS: Array[Color] = [Color(0.3, 0.85, 1.0), Color(0.62, 0.45, 1.0),
		Color(1.0, 0.42, 0.75), Color(1.0, 0.8, 0.3)]
## Schrift der Hilfe-Knöpfe (klein: für lange Namen wie „Vervollständigen“).
const BUTTON_FONT := 33
const BUTTON_FONT_SMALL := 23
## Abstand der Knöpfe zum unteren Rand (Platz für runde Display-Ecken).
const BOTTOM_PAD := 56.0
## Schriftgröße der Info-Zeile (Level · Rekord links, Münzen rechts in Gold).
const INFO_FONT := 40
## Größe der Symbol-Knöpfe oben (Aufgeben, Einstellungen): schmal, fast quadratisch.
const ICON_BUTTON_SIZE := Vector2(88, 76)
## Abstand der oberen Knöpfe zum oberen Rand (runde Display-Ecken, Kamera-Loch).
const TOP_INSET := 36.0
## Abstand der Info-Zeile zur Oberkante des Felds (Pixel).
const INFO_GAP := 24.0

## Hilfen: Reihenfolge bei gleichem Preis, Namen auf Knöpfen und Karten, kurze Erklärung.
const HELP_ORDER: PackedStringArray = ["refill", "riddle", "hint", "replace", "shuffle", "clear", "joker",
		"shorten", "swap", "split", "complete", "magnet", "scan", "strike", "solve"]
const HELP_NAMES := {
	"refill": "Auffüllen", "riddle": "Rätsel", "hint": "Tipp", "replace": "Ersetzen", "shuffle": "Mischen",
	"clear": "Aufräumen", "joker": "Joker", "shorten": "Kürzen", "swap": "Tauschen",
	"split": "Teilen", "complete": "Vervollständigen", "magnet": "Magnet", "scan": "Scan",
	"strike": "Streichen", "solve": "Lösen",
}
const HELP_INFO := {
	"riddle": "Zeigt einen kurzen Hinweis zum gesuchten Wort.",
	"hint": "Zeigt Buchstabe für Buchstabe ein passendes Wort.",
	"replace": "Ein Stein deiner Wahl bekommt einen neuen Buchstaben.",
	"shuffle": "Alle Buchstaben werden neu verteilt.",
	"clear": "Entfernt bis zu 5 wenig hilfreiche Steine.",
	"joker": "Tipp einen Stein an: Er wird zum Joker für jeden Buchstaben.",
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
## Hilfe-Knöpfe (Stil „Kombi“): dunkles Glas, feiner Cyan-Rand, sanftes Leuchten, Glanz oben;
## Lösen mit Goldrand. Name weiß, Preis gold mit Münze, „gratis“ grün, zu teuer rot.
const BTN_BG := Color(0.06, 0.1, 0.24, 0.8)
const BTN_BG_PRESSED := Color(0.12, 0.3, 0.52, 0.95)
const BTN_EDGE := Color(0.55, 0.95, 1.0)
const BTN_EDGE_SOLVE := Color(1.0, 0.82, 0.45)
const BTN_RADIUS := 20
const BTN_TEXT := Color(0.95, 0.98, 1.0)
const BTN_GOLD := Color(1.0, 0.82, 0.45)
const BTN_FREE := Color(0.7, 1.0, 0.85)
const BTN_RED := Color(1.0, 0.45, 0.45)
const BTN_DISABLED_ALPHA := 0.55
const BTN_NAME_FONT := 36
const BTN_NAME_FONT_LONG := 27
const BTN_PRICE_FONT := 30
## Auswahl-Bildschirm (Power-up / Upgrade): Titel, Karten.
## Story: Rätsel-Overlay (Satz groß, Hinweis klein).
const RIDDLE_FONT := 54
const RIDDLE_HINT_FONT := 30
## Story: Kapitel-Brett zwischen Titel und „Modus wechseln“ (Anteile der Bildschirmhöhe).
const CHAPTER_BOARD_TOP := 0.15
const CHAPTER_BOARD_BOTTOM := 0.87
## Einstellungen: Höhe der Modus-Karten und der Knöpfe darunter (gleich groß).
const SETTINGS_CARD_HEIGHT := 170
const SETTINGS_GAP := 22
## Home-Screen: Abstand zwischen Überschrift und Knöpfen bzw. zwischen den Abschnitten.
const SETTINGS_HEADING_GAP := 40
## Dezente Knöpfe unter den Modi (Vibration, Tutorial, Schließen): grau statt cyan, ohne Leuchten.
const BTN2_BG := Color(0.08, 0.09, 0.13, 0.94)
const BTN2_BG_PRESSED := Color(0.17, 0.19, 0.26, 0.97)
const BTN2_EDGE := Color(0.6, 0.65, 0.75)
const BTN2_TEXT := Color(0.66, 0.7, 0.8)
## Tutorial: Pause nach dem Aufbau des Felds, bis der Finger erscheint (Sekunden).
const FINGER_DELAY := 0.35
const CHOICE_TITLE_FONT := 64
const CHOICE_NAME_FONT := 46
const CHOICE_INFO_FONT := 38
const CHOICE_CARD_HEIGHT := 230.0

var session: RunSession

var _dictionary: WordDictionary
var _common: WordDictionary
var _board: BoardView3D
var _blocks: QuestBlocks
## Ebene für fliegende Buchstaben (über allem außer den Overlays).
var _fly_layer: Control
## Fortschritt zum Ziel (20 Quadrate) links in der Info-Zeile.
var _ladder: LevelLadder
var _coins_label: Label
## Goldene Münze vor der Münzzahl (wie auf den Knöpfen).
var _coins_icon: Panel
var _refill_button: Button
var _swap_button: Button
var _clear_button: Button
var _hint_button: Button
var _replace_button: Button
var _solve_button: Button
var _riddle_button: Button
## Story-Modus: aktuelles Kapitel, Themen-Name oben, Rätselsatz über dem Feld, Pfad durchs All.
var _chapter: StoryChapter
var _theme_label: Label
## Story: Overlay mit dem Rätselsatz (Antippen schließt).
var _riddle: ColorRect
var _riddle_label: Label
## Story: Kapitel-Brett (eigene 3D-Welt im SubViewport) mit Titel und Knopf darüber.
var _path: ColorRect
var _path_layer: Control
var _chapter_view: SubViewport
var _chapter_board: ChapterBoard3D
var _chapter_press: Vector2i = Vector2i(-1, -1)
var _again_button: Button
var _joker_button: Button
var _shuffle_button: Button
var _magnet_button: Button
var _split_button: Button
var _shorten_button: Button
var _scan_button: Button
var _complete_button: Button
var _strike_button: Button
## Welche Antipp-Hilfe gerade aktiv ist: "", "replace", "magnet", "joker".
var _tap_action: String = ""
var _give_up_button: Button
## Spielmodus (Wortlisten, Kurve) und geladene Wortlisten (Pfad → WordDictionary, bleiben im Speicher).
var _mode: GameMode
var _word_lists: Dictionary = {}
## Einstellungen: Knopf oben rechts, Ebene mit den Modi, Nachfrage beim Wechsel mitten im Lauf.
var _settings_button: Button
var _settings: ColorRect
var _settings_modes: VBoxContainer
## Schalter „Vibration an/aus“ und „Testmodus an/aus“ in den Einstellungen.
var _vibration_button: Button
var _test_button: Button
## Menüeintrag „Testmodus“ zeigen? Aus: Knopf versteckt und Testmodus wirkungslos (spec/screens.md).
const TEST_MODE_MENU := false
var _mode_confirm: ColorRect
## Einstellungen: Vibration, Tutorial, (Test), Schließen unter den Modi.
var _settings_more: VBoxContainer
## Tutorial (spec/screens.md, „Tutorial“): läuft gerade, Modus danach, Finger, Nachfrage.
var _tutorial_active := false
var _tutorial_return := ""
var _finger: TutorialFinger
var _tutorial_confirm: ColorRect
var _swiping := false
var _pending_mode: String = ""
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
## Hilfe-ID → Knopf.
var _buttons: Dictionary = {}
## Hilfe-ID → {"name": Label, "price": Label, "coin": Panel} (Beschriftung der Knöpfe).
var _button_parts: Dictionary = {}
## Power-up-Anzeige links unter dem Feld: je Level bis zur Auswahl ein Quadrat (eigene Farben).
var _offer_hint: LevelLadder
var _offer_hint_pulse: Tween
## Zuletzt gezeigter Stand der Power-up-Quadrate (Level, Level bis zur Auswahl), um den Schritt
## zum nächsten Level zu erkennen und das Quadrat drehen zu lassen.
var _offer_seen_level: int = 0
var _offer_seen_n: int = 0
## Läuft gerade eine Dreh-Animation?
var _offer_flip: SquareFlip
## Pause nach dem Level-Abschluss, bevor sich das Quadrat dreht (Buchstaben fliegen noch).
const OFFER_FLIP_DELAY := 0.55
## Auswahl-Bildschirm für Power-ups und Upgrades.
var _choice: ColorRect
var _choice_title: Label
var _choice_cards: VBoxContainer
## Home-Screen nach kaltem Start: Der Lauf darunter ist noch unberührt, Modus wählen ohne Nachfrage.
var _home_fresh: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Berührungen nicht hier abfangen, sondern ans Spielfeld (_unhandled_input) durchlassen.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Gespeicherter Modus noch gesperrt (z. B. vor dem Update gewählt): zurück auf Einfach.
	if not SaveData.mode_unlocked(Settings.mode):
		Settings.mode = Settings.DEFAULT_MODE
	_load_mode()
	_build_ui()
	get_viewport().size_changed.connect(_relayout)
	if not Settings.tutorial_seen:
		_start_tutorial()
	else:
		new_run()
		if _is_story():
			_open_path.call_deferred()
		# Kalter Start nach dem Tutorial: erst der Home-Screen (spec/screens.md v4.40).
		_open_home_on_start.call_deferred()
	# Schwächere Handys: 3D-Auflösung automatisch senken, wenn es ruckelt.
	var guard := PerfGuard.new()
	guard.extra_viewports.append(_chapter_view)
	add_child(guard)


## Neuen Lauf starten (Level 1).
func new_run(seed_value: int = -1) -> void:
	if _sequence:
		_sequence.kill()
	_completing = false
	_pending_quest = null
	for c in _fly_layer.get_children():
		c.queue_free()
	session = RunSession.new(BALANCE, _mode.curve, _mode.language, _dictionary, seed_value, _common)
	session.free_solve = Settings.test_mode and TEST_MODE_MENU
	_finger.stop()
	if _tutorial_active:
		session.set_tutorial()
	if _is_story():
		if _chapter == null:
			_chapter = _default_chapter()
		session.set_story(_chapter)
		session.riddle_shown.connect(_on_riddle_shown)
	session.goal_reached.connect(_on_goal_reached)
	_theme_label.text = _chapter.display_name if _is_story() and _chapter != null else ""
	_riddle.visible = false
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
	session.helps_changed.connect(_relayout)
	_summary.visible = false
	_continue_button.visible = false
	_choice.visible = false
	_offer_hint.visible = true
	# Neuer Lauf: Power-up-Quadrate ohne Dreh-Animation neu aufbauen.
	if _offer_flip != null:
		_offer_flip.queue_free()
		_offer_flip = null
	_offer_hint.hidden_index = -1
	_offer_hint.current_alpha = 1.0
	_offer_seen_level = 0
	_offer_seen_n = 0
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
	_board.path_changed.connect(func(word: String) -> void:
		_blocks.preview(word)
		_swiping = word != ""
		# Beim Loslassen erst nach der Wort-Prüfung (gleiches Bild): ein richtiges Wort schließt
		# die Runde ab, dann bleibt der Finger weg.
		_update_finger.call_deferred())

	_ladder = LevelLadder.new()
	add_child(_ladder)
	_coins_label = _label(INFO_FONT, ACCENT)
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_coins_icon = _coin(30)
	add_child(_coins_icon)
	for l in [_coins_label]:
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
	_joker_button.toggle_mode = true
	_joker_button.toggled.connect(func(on: bool) -> void: _set_tap_action("joker" if on else ""))
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

	_riddle_button = _button("", BUTTON_FONT)
	_riddle_button.pressed.connect(func() -> void:
		_set_replace_mode(false)
		if session.riddle() == "":
			_shake(_riddle_button))

	_buttons = {"refill": _refill_button, "riddle": _riddle_button, "hint": _hint_button, "replace": _replace_button,
		"shuffle": _shuffle_button, "clear": _clear_button, "joker": _joker_button,
		"shorten": _shorten_button, "swap": _swap_button, "split": _split_button,
		"complete": _complete_button, "magnet": _magnet_button, "scan": _scan_button,
		"strike": _strike_button, "solve": _solve_button}
	for id in _buttons:
		_style_help_button(_buttons[id], id)
	_theme_label = _label(INFO_FONT, BTN_GOLD)
	_theme_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_theme_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_offer_hint = LevelLadder.new()
	_offer_hint.palette = OFFER_COLORS
	_offer_hint.cell_ratio = 0.9
	add_child(_offer_hint)

	# „Aufgeben“ (Kreuz) und Home-Screen (Haus): schmale Glas-Knöpfe nur mit Symbol, dezenter
	# als die Hilfe-Knöpfe; der Rand leuchtet beim Antippen auf (spec/screens.md v4.25).
	_give_up_button = _icon_button("close")
	_give_up_button.pressed.connect(func() -> void:
		# Nach dem Aufgeben fragt das Kreuz nicht nochmal, sondern führt wie „Weiter“ heim.
		if _continue_button.visible:
			_home_after_run()
		else:
			_confirm.visible = true)
	_settings_button = _icon_button("home")
	_settings_button.pressed.connect(_open_settings)

	_continue_button = _button("Weiter", 56)
	_continue_button.visible = false
	_continue_button.pressed.connect(_home_after_run)

	_finger = TutorialFinger.new()
	add_child(_finger)

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

	# Story: Kapitel-Brett (Kapitel-Auswahl)
	_path = ColorRect.new()
	_path.color = Color(0.0, 0.01, 0.04, 1.0)
	_path.set_anchors_preset(Control.PRESET_FULL_RECT)
	_path.visible = false
	_path.gui_input.connect(_on_chapter_input)
	add_child(_path)
	var container := SubViewportContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_path.add_child(container)
	_chapter_view = SubViewport.new()
	_chapter_view.own_world_3d = true
	_chapter_view.handle_input_locally = false
	container.add_child(_chapter_view)
	_chapter_board = ChapterBoard3D.new()
	_chapter_view.add_child(_chapter_board)
	_path_layer = Control.new()
	_path_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_path_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_path.add_child(_path_layer)

	# Home-Screen: Überschrift „Modus“ mit den Modi, darunter „Einstellungen“ mit Vibration,
	# Tutorial, Schließen als dezentere Knöpfe gleicher Größe (spec/screens.md v4.40).
	var st := _overlay("Modus")
	_settings = st[0]
	(st[1] as VBoxContainer).add_theme_constant_override("separation", SETTINGS_HEADING_GAP)
	_settings_modes = VBoxContainer.new()
	_settings_modes.add_theme_constant_override("separation", SETTINGS_GAP)
	(st[1] as VBoxContainer).add_child(_settings_modes)
	var more_head := Label.new()
	more_head.text = "Einstellungen"
	more_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	more_head.add_theme_font_size_override("font_size", 68)
	more_head.add_theme_color_override("font_color", TEXT)
	(st[1] as VBoxContainer).add_child(more_head)
	_settings_more = VBoxContainer.new()
	_settings_more.add_theme_constant_override("separation", SETTINGS_GAP)
	(st[1] as VBoxContainer).add_child(_settings_more)
	_vibration_button = _secondary_button("", _settings_more)
	_vibration_button.pressed.connect(func() -> void:
		Settings.vibration_on = not Settings.vibration_on
		_update_vibration_button()
		Settings.tick())
	var tut := _secondary_button("Tutorial", _settings_more)
	tut.pressed.connect(_on_tutorial_picked)
	_test_button = _secondary_button("", _settings_more)
	_test_button.visible = TEST_MODE_MENU
	_test_button.pressed.connect(func() -> void:
		Settings.test_mode = not Settings.test_mode
		if session != null:
			session.free_solve = Settings.test_mode
		_update_vibration_button()
		_update_labels())
	var close := _secondary_button("Schließen", _settings_more)
	close.pressed.connect(_close_settings)

	# Nachfrage: Modus mitten im Lauf wechseln
	var mc := _overlay("Modus wechseln und\nneu starten?")
	_mode_confirm = mc[0]
	var mrow := HBoxContainer.new()
	mrow.alignment = BoxContainer.ALIGNMENT_CENTER
	mrow.add_theme_constant_override("separation", 40)
	(mc[1] as VBoxContainer).add_child(mrow)
	var myes := _button("Ja", 56, mrow)
	myes.custom_minimum_size = Vector2(260, 130)
	myes.pressed.connect(func() -> void: _apply_mode(_pending_mode))
	var mno := _button("Nein", 56, mrow)
	mno.custom_minimum_size = Vector2(260, 130)
	mno.pressed.connect(func() -> void:
		_mode_confirm.visible = false
		_pending_mode = "")

	# Nachfrage: Tutorial mitten im Lauf starten
	var tc := _overlay("Tutorial starten?\nDer Lauf wird beendet.")
	_tutorial_confirm = tc[0]
	var trow := HBoxContainer.new()
	trow.alignment = BoxContainer.ALIGNMENT_CENTER
	trow.add_theme_constant_override("separation", 40)
	(tc[1] as VBoxContainer).add_child(trow)
	var tyes := _button("Ja", 56, trow)
	tyes.custom_minimum_size = Vector2(260, 130)
	tyes.pressed.connect(_start_tutorial)
	var tno := _button("Nein", 56, trow)
	tno.custom_minimum_size = Vector2(260, 130)
	tno.pressed.connect(func() -> void: _tutorial_confirm.visible = false)

	# Story: Rätsel (Antippen irgendwo schließt)
	var rd := _overlay("Rätsel")
	_riddle = rd[0]
	var rd_title := rd[2] as Label
	rd_title.add_theme_font_size_override("font_size", CHOICE_TITLE_FONT)
	rd_title.add_theme_color_override("font_color", BTN_GOLD)
	rd_title.add_theme_color_override("font_outline_color", Color(BTN_GOLD, 0.35))
	rd_title.add_theme_constant_override("outline_size", 10)
	_riddle_label = Label.new()
	_riddle_label.add_theme_font_size_override("font_size", RIDDLE_FONT)
	_riddle_label.add_theme_color_override("font_color", TEXT)
	_riddle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_riddle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	(rd[1] as VBoxContainer).add_child(_riddle_label)
	var rd_hint := Label.new()
	rd_hint.text = "Tippen zum Schließen"
	rd_hint.add_theme_font_size_override("font_size", RIDDLE_HINT_FONT)
	rd_hint.add_theme_color_override("font_color", TEXT_DIM)
	rd_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	(rd[1] as VBoxContainer).add_child(rd_hint)
	_riddle.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed:
			_riddle.visible = false
			_riddle.accept_event())

	# Auswahl: Power-up oder Upgrade
	var ch := _overlay("")
	_choice = ch[0]
	_choice_title = ch[2]
	_choice_title.add_theme_font_size_override("font_size", CHOICE_TITLE_FONT)
	_choice_title.add_theme_color_override("font_color", BTN_GOLD)
	_choice_title.add_theme_color_override("font_outline_color", Color(BTN_GOLD, 0.35))
	_choice_title.add_theme_constant_override("outline_size", 10)
	_choice_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	(ch[1] as VBoxContainer).add_theme_constant_override("separation", 40)
	_choice_cards = VBoxContainer.new()
	_choice_cards.add_theme_constant_override("separation", 24)
	(ch[1] as VBoxContainer).add_child(_choice_cards)

	# Bilanz
	var s := _overlay("")
	_summary = s[0]
	_summary_label = s[2]
	# „Weiter“: jeder Lauf endet auf dem Home-Screen (screens.md v4.43).
	_again_button = _button("Weiter", 64, s[1])
	_again_button.custom_minimum_size = Vector2(520, 140)
	_again_button.pressed.connect(_home_after_run)


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
	if not BALANCE.draft_enabled:
		rows = ceili((RunSession.HELP_IDS.size() + 2) / float(BUTTONS_PER_ROW_ALL))
	return rows * BUTTON_STEP + BOTTOM_PAD + 12.0


## Bildschirmbereich (Pixel) für das Spielfeld samt Rand.
func _board_area() -> Rect2:
	var s := get_viewport_rect().size
	var col := _column(s)
	var side := col.x + col.y * SIDE_MARGIN
	var top := _top_height(s)
	return Rect2(side, top, col.y * (1.0 - 2.0 * SIDE_MARGIN), s.y - top - _bottom_height())


## Platz des Einstellungen-Knopfs oben rechts (im Spiel und auf dem Kapitel-Brett gleich).
func _settings_button_pos(s: Vector2) -> Vector2:
	var col := _column(s)
	var margin := col.y * SIDE_MARGIN
	return Vector2(col.x + col.y - margin - ICON_BUTTON_SIZE.x, s.y * 0.012 + TOP_INSET)


func _relayout() -> void:
	var s := get_viewport_rect().size
	if _board.session != null:
		_board.fit_to_screen(_board_area(), s)
	if _path.visible:
		_fit_chapter_board()
	var col := _column(s)
	var margin := col.y * SIDE_MARGIN
	var side := col.x + margin
	var inner := col.y - 2.0 * margin
	_give_up_button.size = ICON_BUTTON_SIZE
	var top_y := s.y * 0.012 + TOP_INSET
	_give_up_button.position = Vector2(side, top_y)
	_settings_button.size = ICON_BUTTON_SIZE
	_settings_button.position = _settings_button_pos(s)
	# Blöcke zwischen „Aufgeben“ und Spielfeld (immer Platz für 3 Zeilen).
	var info_y := _top_height(s) - INFO_HEIGHT
	_blocks.layout(Rect2(side, BLOCKS_TOP, inner, info_y - BLOCKS_TOP - BLOCKS_GAP_BELOW))
	# Info-Zeile dicht über die Oberkante des Felds (das Feld sitzt mittig in seinem Bereich).
	if _board.session != null:
		info_y = maxf(info_y, _board.screen_top() - INFO_HEIGHT - INFO_GAP)

	_theme_label.position = Vector2(side + inner * 0.3, top_y + (ICON_BUTTON_SIZE.y - INFO_HEIGHT) * 0.5)
	_theme_label.size = Vector2(inner * 0.4, INFO_HEIGHT)
	_riddle_label.custom_minimum_size = Vector2(inner * 0.86, 0)
	# Info-Zeile direkt über dem Spielfeld: Leiter (Fortschritt) links, Münzen rechts.
	_ladder.position = Vector2(side, info_y)
	_ladder.size = Vector2(inner * 0.66, INFO_HEIGHT)
	_coins_label.position = Vector2(side + inner * 0.6, info_y)
	_coins_label.size = Vector2(inner * 0.4, INFO_HEIGHT)
	# Unten: die Knöpfe. Die Power-up-Quadrate stehen links, mittig zwischen Feld und Knöpfen.
	var info_top := s.y - _bottom_height() + 12.0
	var buttons_top := info_top
	var hint_y := info_top - INFO_HEIGHT
	if _board.session != null:
		var mid := (_board.screen_bottom() + buttons_top) * 0.5
		hint_y = minf(mid - INFO_HEIGHT * 0.5, buttons_top - INFO_HEIGHT)
	_offer_hint.position = Vector2(side, hint_y)
	_offer_hint.size = Vector2(inner, INFO_HEIGHT)
	var gap := 12.0
	var buttons := _help_buttons()
	var per_row := _per_row()
	var bw := (inner - (per_row - 1) * gap) / per_row
	_continue_button.position = Vector2(side + inner * 0.25, info_top + 10)
	_continue_button.size = Vector2(inner * 0.5, 120)
	for b in _buttons.values():
		b.visible = false
	for i in buttons.size():
		buttons[i].visible = not _continue_button.visible and not _summary.visible \
				and not (session != null and session.tutorial)
		buttons[i].position = Vector2(side + (i % per_row) * (bw + gap),
				buttons_top + (i / per_row) * BUTTON_STEP)
		buttons[i].size = Vector2(bw, BUTTON_HEIGHT)
		buttons[i].pivot_offset = buttons[i].size / 2.0
	_update_labels()


func _update_labels() -> void:
	if session == null:
		return
	_ladder.visible = BALANCE.goal_level > 0
	_ladder.steps = maxi(BALANCE.goal_level, 1)
	_ladder.done = session.level() - 1 + (1 if session.completed else 0)
	_ladder.show_current = not session.is_over
	_coins_label.text = str(session.coins)
	_place_coin_icon()
	for id in _buttons:
		var p := session.price(id)
		var parts: Dictionary = _button_parts[id]
		var affordable := p <= session.coins
		(parts["price"] as Label).text = "gratis" if p == 0 else str(p)
		(parts["price"] as Label).add_theme_color_override("font_color",
				BTN_FREE if p == 0 else (BTN_GOLD if affordable else BTN_RED))
		(parts["coin"] as Panel).visible = p > 0
		(parts["coin"] as Panel).modulate.a = 1.0 if affordable else 0.4
	_refill_button.disabled = not session.can_refill()
	_swap_button.disabled = not session.can_swap()
	_clear_button.disabled = not session.can_clear()
	_hint_button.disabled = not session.can_hint()
	_replace_button.disabled = not session.can_replace() and not _replace_button.button_pressed
	_joker_button.disabled = not session.can_joker() and not _joker_button.button_pressed
	_shuffle_button.disabled = not session.can_shuffle()
	_magnet_button.disabled = not session.can_magnet() and not _magnet_button.button_pressed
	# Kürzen, Teilen, Streichen: nur Geld prüfen; passt die Lage nicht, wackelt der Knopf.
	for id in ["shorten", "split", "strike"]:
		_buttons[id].disabled = session.is_over or session.coins < session.price(id)
	_complete_button.disabled = not session.can_complete() and not _complete_button.button_pressed
	_scan_button.disabled = not session.can_scan()
	_solve_button.disabled = not session.can_solve()
	_riddle_button.disabled = not session.can_riddle()
	for b: Button in _buttons.values():
		b.modulate.a = BTN_DISABLED_ALPHA if b.disabled else 1.0
	_update_offer_hint()
	if session.is_over:
		_set_replace_mode(false)
	# Tutorial: nur Auftrag und Feld (keine Leiter, Münzen, Aufgeben).
	var tut := session.tutorial
	_ladder.visible = _ladder.visible and not tut
	_coins_label.visible = not tut
	_coins_icon.visible = not tut
	_give_up_button.visible = not tut


# --- Hilfe-Knöpfe gestalten ------------------------------------------------------------

## Goldene Münze (Kreis mit hellem Rand).
func _coin(size: float) -> Panel:
	var coin := Panel.new()
	coin.custom_minimum_size = Vector2(size, size)
	coin.size = Vector2(size, size)
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cs := StyleBoxFlat.new()
	cs.bg_color = BTN_GOLD
	cs.border_color = Color(1, 0.95, 0.7, 0.9)
	cs.set_border_width_all(2)
	cs.set_corner_radius_all(int(size / 2.0))
	coin.add_theme_stylebox_override("panel", cs)
	return coin


## Münze links neben die (rechtsbündige) Münzzahl setzen.
func _place_coin_icon() -> void:
	var font := _coins_label.get_theme_font("font")
	var fs := _coins_label.get_theme_font_size("font_size")
	var w := font.get_string_size(_coins_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var right := _coins_label.position.x + _coins_label.size.x
	_coins_icon.position = Vector2(right - w - _coins_icon.size.x - 12.0,
			_coins_label.position.y + (_coins_label.size.y - _coins_icon.size.y) / 2.0)


## Schmaler Glas-Knopf nur mit Symbol (oben links/rechts).
func _icon_button(kind: String, parent: Node = self) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	var normal := _btn_box(BTN_BG, BTN_EDGE, 0.35, 0.12, 6)
	var pressed := _btn_box(BTN_BG_PRESSED, BTN_EDGE, 1.0, 0.6, 18)
	for st in ["normal", "hover", "focus", "disabled"]:
		b.add_theme_stylebox_override(st, normal)
	for st in ["pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, pressed)
	var icon := GlyphIcon.new()
	icon.kind = kind
	icon.color = Color(BTN_TEXT, 0.8)
	b.add_child(icon)
	b.button_down.connect(func() -> void: icon.color = BTN_TEXT)
	b.button_up.connect(func() -> void: icon.color = Color(BTN_TEXT, 0.8))
	parent.add_child(b)
	return b


## Dezenter Knopf für die Einstellungen (ordnet sich den Modus-Karten unter).
func _secondary_button(text: String, parent: Node) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 34)
	b.add_theme_stylebox_override("normal", _btn_box(BTN2_BG, BTN2_EDGE, 0.35, 0.0, 0))
	b.add_theme_stylebox_override("hover", _btn_box(BTN2_BG, BTN2_EDGE, 0.5, 0.0, 0))
	b.add_theme_stylebox_override("pressed", _btn_box(BTN2_BG_PRESSED, BTN2_EDGE, 0.6, 0.0, 0))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_focus_color"]:
		b.add_theme_color_override(c, BTN2_TEXT)
	b.add_theme_color_override("font_pressed_color", TEXT)
	parent.add_child(b)
	return b


func _btn_box(bg: Color, edge: Color, edge_alpha: float, glow_alpha: float, glow: int) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.border_color = Color(edge, edge_alpha)
	b.set_border_width_all(2)
	b.set_corner_radius_all(BTN_RADIUS)
	b.corner_detail = 12
	b.shadow_color = Color(edge, glow_alpha)
	b.shadow_size = glow
	return b


## Stil „Kombi“ und Beschriftung (Name, Münze, Preis) für einen Hilfe-Knopf.
func _style_help_button(b: Button, id: String, register: bool = true) -> void:
	var edge := BTN_EDGE_SOLVE if id == "solve" else BTN_EDGE
	var normal := _btn_box(BTN_BG, edge, 0.8, 0.3, 12)
	var pressed := _btn_box(BTN_BG_PRESSED, edge, 1.0, 0.6, 20)
	for st in ["normal", "hover", "focus", "disabled"]:
		b.add_theme_stylebox_override(st, normal)
	for st in ["pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, pressed)
	b.text = ""
	# Glanz: heller Verlauf in der oberen Hälfte
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.16))
	g.set_color(1, Color(1, 1, 1, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_to = Vector2(0, 1)
	tex.width = 8
	tex.height = 64
	var shine_style := StyleBoxTexture.new()
	shine_style.texture = tex
	var shine := Panel.new()
	shine.add_theme_stylebox_override("panel", shine_style)
	shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shine.set_anchors_preset(Control.PRESET_FULL_RECT)
	shine.anchor_bottom = 0.5
	shine.offset_left = 4
	shine.offset_right = -4
	shine.offset_top = 3
	b.add_child(shine)
	# Name und Preis
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	var name := Label.new()
	name.text = HELP_NAMES[id]
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_size_override("font_size",
			BTN_NAME_FONT_LONG if name.text.length() > 12 else BTN_NAME_FONT)
	name.add_theme_color_override("font_color", BTN_TEXT)
	box.add_child(name)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	var coin := Panel.new()
	coin.custom_minimum_size = Vector2(22, 22)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cs := StyleBoxFlat.new()
	cs.bg_color = BTN_GOLD
	cs.border_color = Color(1, 0.95, 0.7, 0.9)
	cs.set_border_width_all(2)
	cs.set_corner_radius_all(11)
	coin.add_theme_stylebox_override("panel", cs)
	row.add_child(coin)
	var price := Label.new()
	price.add_theme_font_size_override("font_size", BTN_PRICE_FONT)
	row.add_child(price)
	if register:
		_button_parts[id] = {"name": name, "price": price, "coin": coin}
	else:
		price.text = "gratis"
		price.add_theme_color_override("font_color", BTN_FREE)
		coin.visible = false


# --- Story-Modus ------------------------------------------------------------------------

func _is_story() -> bool:
	return _mode != null and _mode.id == Settings.STORY_MODE


## Erstes aufgedecktes, noch nicht geschafftes Kapitel (sonst das erste Start-Kapitel).
func _default_chapter() -> StoryChapter:
	for row in StoryChapter.BOARD_ROWS:
		for col in StoryChapter.BOARD_COLS:
			var slot := StoryChapter.slot(col, row)
			if StoryChapter.cell_open(Vector2i(col, row), SaveData.story_stars) \
					and StoryChapter.playable(slot[0]) and SaveData.story_stars(slot[0]) == 0:
				return StoryChapter.by_id(slot[0])
	return StoryChapter.by_id(StoryChapter.START[0])


func _on_riddle_shown(text: String) -> void:
	if text == "":
		_riddle.visible = false
		return
	_set_replace_mode(false)
	_riddle_label.text = "„%s“" % text
	_riddle.visible = true


## Story: Rätsel zu Beginn des Levels automatisch zeigen (nicht über der Power-up-Auswahl).
func _auto_riddle() -> void:
	if _is_story() and session != null and not session.is_over and not _choice.visible:
		session.riddle()


func _on_goal_reached(stars: int) -> void:
	if session.story != null:
		SaveData.submit_story(session.story.id, stars)
		_summary_label.text = "Kapitel geschafft!\n\n%s\n%s" % [session.story.display_name, _stars_text(stars)]
	else:
		var record := SaveData.submit_run(session.coins, stars)
		_summary_label.text = "Geschafft!\n\n%s\n\n%d Münzen übrig\nRekord: %d%s" % [
			_stars_text(stars), session.coins, SaveData.best_coins(), "\nNeuer Rekord!" if record else ""]
	_update_labels()
	for b in _help_buttons():
		b.visible = false
	_offer_hint.visible = false
	# Erst die letzten Buchstaben ankommen lassen, dann die Bilanz zeigen.
	var t := create_tween()
	t.tween_interval(_last_flight + 1.0)
	t.tween_callback(func() -> void:
		_summary.visible = true
		_relayout())


func _stars_text(stars: int) -> String:
	return "★".repeat(stars) + "☆".repeat(3 - stars)


func _start_chapter(chapter: StoryChapter) -> void:
	_chapter = chapter
	_close_path()
	new_run()
	_auto_riddle()


## Kapitel-Brett zeigen: 3D-Hexagons (aufgedeckt / verdeckt), darüber Titel, darunter
## „Modus wechseln“ (spec/story-mode.md, „Kapitel-Brett“).
func _open_path() -> void:
	_set_tap_action("")
	for c in _path_layer.get_children():
		c.queue_free()
	var s := get_viewport_rect().size
	var col := _column(s)
	var title := Label.new()
	title.text = "Story"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", CHOICE_TITLE_FONT)
	title.add_theme_color_override("font_color", BTN_GOLD)
	title.add_theme_color_override("font_outline_color", Color(BTN_GOLD, 0.35))
	title.add_theme_constant_override("outline_size", 10)
	title.position = Vector2(col.x, s.y * 0.05)
	title.size = Vector2(col.y, 90)
	_path_layer.add_child(title)
	# Einstellungen: derselbe Symbol-Knopf an derselben Stelle wie im Spiel (Konsistenz).
	var menu := _icon_button("home", _path_layer)
	menu.size = ICON_BUTTON_SIZE
	menu.position = _settings_button_pos(s)
	menu.pressed.connect(_open_settings)
	_chapter_board.build(SaveData.story_stars)
	_path.visible = true
	_board.visible = false
	_fit_chapter_board()


func _close_path() -> void:
	_path.visible = false
	_board.visible = true


func _fit_chapter_board() -> void:
	var s := get_viewport_rect().size
	var col := _column(s)
	var margin := col.y * SIDE_MARGIN
	var top := s.y * CHAPTER_BOARD_TOP
	var area := Rect2(col.x + margin, top, col.y - 2.0 * margin, s.y * CHAPTER_BOARD_BOTTOM - top)
	_chapter_board.fit(area, s)


## Antippen eines Kapitel-Steins: aufgedeckt und spielbar → Kapitel starten, sonst wackeln.
func _on_chapter_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var cell: Vector2i = _chapter_board.cell_at_screen(event.position)
	if event.pressed:
		_chapter_press = cell
		return
	if cell != _chapter_press or cell.x < 0:
		return
	var slot := StoryChapter.slot(cell.x, cell.y)
	if StoryChapter.cell_open(cell, SaveData.story_stars) and StoryChapter.playable(slot[0]):
		Settings.tick()
		_start_chapter(StoryChapter.by_id(slot[0]))
	elif _chapter_board.tiles.has(cell):
		_chapter_board.tiles[cell].shake()


# --- Modi und Einstellungen ------------------------------------------------------------

## Aktuellen Modus aus den Einstellungen laden (Wortlisten bleiben zwischengespeichert).
func _load_mode() -> void:
	_mode = Settings.game_mode()
	_dictionary = _word_list(_mode.valid_words_path())
	_common = _word_list(_mode.suggestion_words_path())


func _word_list(path: String) -> WordDictionary:
	if not _word_lists.has(path):
		_word_lists[path] = WordDictionary.from_file(path)
	return _word_lists[path]


## Einstellungen öffnen: Modi als Karten (Name, Sterne), der aktuelle mit Goldrand.
func _open_settings() -> void:
	_set_tap_action("")
	for c in _settings_modes.get_children():
		c.queue_free()
	var w := _column(get_viewport_rect().size).y * 0.86
	for id in Settings.MODES:
		var m := Settings.load_mode(id)
		var card := Button.new()
		card.custom_minimum_size = Vector2(w, SETTINGS_CARD_HEIGHT)
		card.add_theme_font_size_override("font_size", 34)
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# Nur der Name; darunter die besten Sterne (Story: Sterne je Kapitel auf dem Pfad).
		card.text = m.display_name if id == Settings.STORY_MODE \
				else "%s\n%s" % [m.display_name, _stars_text(SaveData.mode_stars(id))]
		var current: bool = id == Settings.mode
		if not SaveData.mode_unlocked(id):
			# Gesperrt (v4.45): abgedunkelt, Antippen tut nichts, darunter die Bedingung.
			var need := Settings.load_mode(SaveData.unlock_requirement(id))
			card.text = "%s\nab ★ in %s" % [m.display_name, need.display_name]
			card.disabled = true
			card.modulate.a = BTN_DISABLED_ALPHA
			card.add_theme_stylebox_override("disabled", _btn_box(BTN_BG, BTN_EDGE, 0.4, 0.1, 8))
			card.add_theme_color_override("font_disabled_color", BTN_TEXT)
			_settings_modes.add_child(card)
			continue
		var edge := BTN_EDGE_SOLVE if current else BTN_EDGE
		card.add_theme_stylebox_override("normal", _btn_box(BTN_BG, edge, 0.9 if current else 0.6, 0.35 if current else 0.2, 12))
		card.add_theme_stylebox_override("hover", _btn_box(BTN_BG, edge, 1.0, 0.4, 14))
		card.add_theme_stylebox_override("pressed", _btn_box(BTN_BG_PRESSED, edge, 1.0, 0.6, 20))
		card.add_theme_color_override("font_color", BTN_GOLD if current else BTN_TEXT)
		var chosen: String = id
		card.pressed.connect(func() -> void: _on_mode_picked(chosen))
		_settings_modes.add_child(card)
	for b in _settings_more.get_children():
		(b as Control).custom_minimum_size = Vector2(w, SETTINGS_CARD_HEIGHT)
	_update_vibration_button()
	# Über allem (auch über Power-up-Auswahl und Bilanz), die Nachfragen darüber.
	move_child(_settings, -1)
	move_child(_mode_confirm, -1)
	move_child(_tutorial_confirm, -1)
	_settings.visible = true


## Android-Zurück (Taste oder Geste, spec/screens.md v4.42): immer einen Schritt Richtung
## Home-Screen. Nachfragen wie „Nein“, im Spiel öffnet es den Home-Screen, auf dem Home-Screen
## geht die App in den Hintergrund (der Lauf bleibt im Speicher).
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back()


func _on_back() -> void:
	if _mode_confirm.visible:
		_mode_confirm.visible = false
		_pending_mode = ""
	elif _tutorial_confirm.visible:
		_tutorial_confirm.visible = false
	elif _confirm.visible:
		_confirm.visible = false
	elif _riddle.visible:
		_riddle.visible = false
	elif _settings.visible:
		_to_background()
	else:
		_open_settings()


## App in den Hintergrund schicken wie die Home-Taste (Android: Activity.moveTaskToBack).
## Geht das nicht, beendet sich die App wie früher bei Zurück.
func _to_background() -> void:
	if OS.get_name() != "Android":
		return
	if Engine.has_singleton("AndroidRuntime"):
		var activity = Engine.get_singleton("AndroidRuntime").getActivity()
		if activity != null and activity.moveTaskToBack(true):
			return
	get_tree().quit()


func _open_home_on_start() -> void:
	_open_settings()
	_home_fresh = true


func _close_settings() -> void:
	_settings.visible = false
	_home_fresh = false


func _update_vibration_button() -> void:
	_vibration_button.text = "Vibration: an" if Settings.vibration_on else "Vibration: aus"
	_test_button.text = "Testmodus: an (Lösen gratis)" if Settings.test_mode else "Testmodus: aus"


func _on_mode_picked(id: String) -> void:
	# Denselben Modus nochmal gewählt: wie ein Moduswechsel (Nachfrage, dann Neustart bzw. in der
	# Story zurück aufs Brett). Nur auf dem Kapitel-Brett selbst schließen sich die Einstellungen.
	if id == Settings.mode and _is_story() and _path.visible:
		_close_settings()
		return
	if _home_fresh:
		# Nach kaltem Start ist noch nichts gespielt: aktueller Modus = einfach ins Spiel.
		if id == Settings.mode:
			_close_settings()
		else:
			_apply_mode(id)
		return
	if session != null and not session.is_over:
		_pending_mode = id
		_mode_confirm.visible = true
	else:
		_apply_mode(id)


## Modus wechseln und neu starten.
func _apply_mode(id: String) -> void:
	_mode_confirm.visible = false
	_close_settings()
	_pending_mode = ""
	if id == "":
		return
	if _tutorial_active:
		# Tutorial verlassen (fertig oder per Moduswahl abgebrochen): gilt als gesehen.
		_tutorial_active = false
		Settings.tutorial_seen = true
	Settings.mode = id
	_load_mode()
	_chapter = null
	new_run()
	if _is_story():
		_open_path()
	else:
		_close_path()


# --- Tutorial ---------------------------------------------------------------------------

## Menü-Eintrag „Tutorial“: mitten im Lauf erst nachfragen.
func _on_tutorial_picked() -> void:
	if session != null and not session.is_over and not session.tutorial and not _path.visible \
			and not _home_fresh:
		_tutorial_confirm.visible = true
	else:
		_start_tutorial()


## Tutorial starten (Modus Einfach); danach geht es im vorher gewählten Modus weiter.
func _start_tutorial() -> void:
	_tutorial_confirm.visible = false
	_close_settings()
	if not _tutorial_active:
		_tutorial_return = Settings.mode
	_tutorial_active = true
	_mode = Settings.load_mode("de_easy")
	_dictionary = _word_list(_mode.valid_words_path())
	_common = _word_list(_mode.suggestion_words_path())
	_chapter = null
	_close_path()
	new_run()
	_finger_soon()


## Finger erst zeigen, wenn das Feld fertig aufgebaut ist (alle Steine gedreht), plus kurze Pause.
func _finger_soon() -> void:
	get_tree().create_timer(_board.settle_time() + FINGER_DELAY).timeout.connect(_update_finger)


## Finger zeigen, solange eine Tutorial-Runde läuft und man nicht selbst wischt.
func _update_finger() -> void:
	var want := _tutorial_active and session != null and not _completing and not _swiping \
			and not session.tutorial_path().is_empty()
	if not want:
		_finger.stop()
		return
	if _board.settle_time() > 0.0:
		if not _finger.is_playing():
			_finger_soon()  # Feld baut sich noch auf: danach nochmal
		return
	var pts := PackedVector2Array()
	for cell in session.tutorial_path():
		pts.append(_tile_screen_pos(cell))
	if _finger.is_playing() and _finger.points() == pts:
		return  # zeigt schon diesen Weg
	_finger.play(pts)


# --- Power-ups und Upgrades -----------------------------------------------------------

## „Noch n Level bis zum Power-up/Upgrade“; bei 1 Level leuchtet der Hinweis.
func _update_offer_hint() -> void:
	# Kein Text (spec/screens.md v4.22): je Level bis zum Power-up ein Quadrat; geschaffte Level
	# leuchten, das laufende ist umrandet. Ohne anstehende Auswahl (Story, nach dem letzten
	# Power-up) verschwindet die Anzeige; den Weg zum Ziel zeigt die Leiter.
	# Ein geschafftes Level dreht sein Quadrat mit Funken und Rauch (v4.24).
	if _offer_flip != null:
		return  # die Animation ruft am Ende wieder auf
	if session.tutorial:
		_offer_hint.visible = false
		return
	var n := session.levels_until_offer() if BALANCE.draft_enabled else 0
	var every := BALANCE.draft_every
	var level := session.level()
	var pending := not session.offer.is_empty()
	if level == _offer_seen_level + 1 and _offer_seen_n > 0 and _offer_hint.visible:
		var idx := every - _offer_seen_n
		_offer_seen_level = level
		_offer_seen_n = n
		_flip_offer_square(idx, every)
		return
	_offer_seen_level = level
	_offer_seen_n = n
	_offer_hint.visible = (n > 0 or pending) and not session.is_over
	if pending:
		_offer_hint.steps = every
		_offer_hint.done = every
		_offer_hint.show_current = false
	elif n > 0:
		_offer_hint.steps = every
		_offer_hint.done = every - n
		_offer_hint.show_current = true
	_set_offer_pulse(n == 1 and not pending)


func _set_offer_pulse(on: bool) -> void:
	if on and _offer_hint_pulse == null:
		_offer_hint_pulse = create_tween().set_loops()
		_offer_hint_pulse.tween_property(_offer_hint, "modulate", PULSE_BRIGHT, PULSE_HALF)
		_offer_hint_pulse.tween_property(_offer_hint, "modulate", Color.WHITE, PULSE_HALF)
	elif not on and _offer_hint_pulse != null:
		_offer_hint_pulse.kill()
		_offer_hint_pulse = null
		_offer_hint.modulate = Color.WHITE


## Quadrat idx (das Level, das gerade geschafft wurde) dreht sich zu seiner Farbe; danach wird das
## nächste Quadrat „ready“ (Umrandung leuchtet auf). Beim letzten (Gold) bleiben alle vier
## gefüllt, bis die Power-up-Auswahl erledigt ist.
func _flip_offer_square(idx: int, every: int) -> void:
	_set_offer_pulse(false)
	_offer_hint.steps = every
	_offer_hint.done = idx
	_offer_hint.show_current = true  # bis die Drehung beginnt, bleibt das Quadrat sichtbar
	_offer_flip = SquareFlip.new()
	_offer_flip.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_offer_flip)
	var r := _offer_hint.cell_rect(idx)
	r.position += _offer_hint.position
	var color := _offer_hint.color_at(idx)
	var flip := _offer_flip
	var t := create_tween()
	t.tween_interval(OFFER_FLIP_DELAY)
	t.tween_callback(func() -> void:
		_offer_hint.show_current = false
		_offer_hint.hidden_index = idx
		flip.play(r, color))
	flip.finished.connect(func() -> void:
		_offer_hint.hidden_index = -1
		_offer_hint.done = idx + 1
		_offer_flip = null
		var last := idx + 1 >= every
		if not last and session != null and not session.is_over:
			# nächstes Quadrat leuchtet sanft als „ready“ auf
			_offer_hint.current_alpha = 0.0
			_offer_hint.show_current = true
			var fade := create_tween()
			fade.tween_property(_offer_hint, "current_alpha", 1.0, 0.45)
		_update_offer_hint())


## Liegt eine Auswahl an, Karten zeigen (nach der Abschluss-Animation des Auftrags).
func _show_choice() -> void:
	if session == null or session.offer.is_empty() or session.is_over:
		return
	_set_tap_action("")
	for c in _choice_cards.get_children():
		c.queue_free()
	var upgrade: bool = session.offer["kind"] == "upgrade"
	_choice_title.text = "Welche Hilfe wird günstiger?" if upgrade else "Wähle eine Hilfe"
	var w := _column(get_viewport_rect().size).y * 0.86
	_choice_title.custom_minimum_size = Vector2(w, 0)
	for id in session.offer["options"]:
		var p := session.price(id)
		var price_text := ("%d → %d" % [p, session.upgraded_price(id)]) if upgrade else str(p)
		var chosen: String = id
		var card := _choice_card(id, price_text, w)
		card.pressed.connect(func() -> void:
			session.choose(chosen)
			_choice.visible = false
			_relayout()
			_auto_riddle())
		_choice_cards.add_child(card)
	_choice.visible = true


## Karte für die Auswahl im Stil der Hilfe-Knöpfe: oben Name · Münze · Preis, darunter die Erklärung.
func _choice_card(id: String, price_text: String, width: float) -> Button:
	var edge := BTN_EDGE_SOLVE if id == "solve" else BTN_EDGE
	var card := Button.new()
	card.custom_minimum_size = Vector2(width, CHOICE_CARD_HEIGHT)
	card.add_theme_stylebox_override("normal", _btn_box(BTN_BG, edge, 0.85, 0.35, 14))
	card.add_theme_stylebox_override("hover", _btn_box(BTN_BG, edge, 1.0, 0.45, 16))
	card.add_theme_stylebox_override("pressed", _btn_box(BTN_BG_PRESSED, edge, 1.0, 0.65, 22))
	card.add_theme_stylebox_override("focus", _btn_box(BTN_BG, edge, 0.85, 0.35, 14))
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 28
	box.offset_right = -28
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	var name := Label.new()
	name.text = HELP_NAMES[id]
	name.add_theme_font_size_override("font_size", CHOICE_NAME_FONT)
	name.add_theme_color_override("font_color", BTN_TEXT)
	row.add_child(name)
	var coin := _coin(30)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(coin)
	var price := Label.new()
	price.text = price_text
	price.add_theme_font_size_override("font_size", CHOICE_NAME_FONT)
	price.add_theme_color_override("font_color", BTN_GOLD)
	row.add_child(price)
	var info := Label.new()
	info.text = HELP_INFO[id]
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("font_size", CHOICE_INFO_FONT)
	info.add_theme_color_override("font_color", Color(BTN_TEXT, 0.85))
	box.add_child(info)
	return card


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
	# Unter Auswahl- und Einstellungs-Ebenen (Flug-Ebene liegt darunter).
	l.reparent(_fly_layer)
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
	_board.tap_mode = action == "replace" or action == "magnet" or action == "joker"
	_board.prefix_mode = action == "complete"
	_complete_button.set_pressed_no_signal(action == "complete")
	_replace_button.set_pressed_no_signal(action == "replace")
	_magnet_button.set_pressed_no_signal(action == "magnet")
	_joker_button.set_pressed_no_signal(action == "joker")


func _on_cell_tapped(cell: Vector2i) -> void:
	var action := _tap_action
	_set_tap_action("")
	match action:
		"replace":
			session.replace(cell)
		"magnet":
			if session.magnet(cell).is_empty():
				_shake(_magnet_button)
		"joker":
			if session.joker(cell) == RunSession.NO_CELL:
				_board.shake_cells([cell])  # schon Joker oder kein Stein: kostet nichts


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
	_finger.stop()
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
			if _tutorial_active and session.completed:
				_apply_mode(_tutorial_return)  # Tutorial geschafft: normal weiter
				# Danach der Home-Screen, damit Neue sehen, was es gibt (v4.45).
				_open_home_on_start()
				return
			if _pending_quest and not session.is_over:
				_blocks.show_quest(_pending_quest)
			_pending_quest = null
			# Tutorial: Finger erst, wenn die Buchstaben oben sind und die neuen Steine liegen.
			_finger_soon()
			_show_choice()
			_auto_riddle()))


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


## Lauf vorbei (nach dem Aufgeben „Weiter“ oder Kreuz, nach „Geschafft!“ „Weiter“): auf den
## Home-Screen, darunter läuft schon ein neuer Lauf bzw. liegt das Kapitel-Brett, wie nach einem
## kalten Start (screens.md v4.41, v4.43).
func _home_after_run() -> void:
	_continue_button.visible = false
	_summary.visible = false
	if _is_story():
		_open_path()
	else:
		new_run()
	_open_home_on_start()


func _on_run_ended(_level: int, _reason: String) -> void:
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
	else:
		# Kein schönes Wort im Feld: ein schönes Wort ploppt direkt in die Zeile.
		var fb := session.solution_fallback()
		if not fb.is_empty():
			_on_row_filled(fb["row"], fb["word"])
