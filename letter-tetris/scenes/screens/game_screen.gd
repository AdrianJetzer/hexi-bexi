extends Control
## Spiel-Screen im Lauf-Modus (siehe spec/run-mode.md, spec/screens.md):
## 3D-Spielfeld mit 2D-Oberfläche (Wort oben, Auftrag, Level, Münzen, Nachfüllen,
## Aufgeben), Auftragswahl als Ebene über dem Spiel, Bilanz am Ende.

const BALANCE: GameBalance = preload("res://data/balance.tres")
const CURVE: QuestCurve = preload("res://data/quest_curve.tres")
const LANG: LanguageData = preload("res://data/languages/de/language.tres")

const TEXT := Color(0.85, 0.92, 1.0)
const TEXT_DIM := Color(0.6, 0.66, 0.85)
const ACCENT := Color(1.0, 0.84, 0.6)
const GLOW := Color(0.55, 0.95, 1.0)

## Anteile der Bildschirmhöhe/-breite für die Bereiche.
const SIDE_MARGIN := 0.06
const TOP_AREA := 0.11
const BOTTOM_AREA := 0.19
## Pause, bevor nach einem erfüllten Auftrag die neuen Karten erscheinen (Sekunden).
const CARDS_DELAY := 1.3

var session: RunSession

var _dictionary: WordDictionary
var _common: WordDictionary
var _board: BoardView3D
var _word_label: Label
var _quest_label: Label
var _progress_label: Label
var _level_label: Label
var _coins_label: Label
var _refill_button: Button
var _give_up_button: Button
var _confirm: ColorRect
var _cards: ColorRect
var _cards_title: Label
var _card_buttons: Array[Button] = []
var _summary: ColorRect
var _summary_label: Label
var _flash_tween: Tween
var _cards_tween: Tween


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
	if _cards_tween:
		_cards_tween.kill()
	session = RunSession.new(BALANCE, CURVE, LANG, _dictionary, seed_value, _common)
	session.quest_offered.connect(_on_quest_offered)
	session.quest_started.connect(_on_quest_started)
	session.quest_progress.connect(func(_q: Quest) -> void: _update_labels())
	session.quest_completed.connect(_on_quest_completed)
	session.coins_changed.connect(func(_c: int) -> void: _update_labels())
	session.level_changed.connect(func(_l: int) -> void: _update_labels())
	session.word_accepted.connect(_on_word_accepted)
	session.word_rejected.connect(_on_word_rejected)
	session.tile_spawned.connect(func(_c: Vector2i, _l: String) -> void: _update_labels())
	session.run_ended.connect(_on_run_ended)
	_summary.visible = false
	_confirm.visible = false
	_cards.visible = false
	_word_label.text = ""
	_board.setup(session)
	session.start()
	_relayout()


# --- Aufbau ---------------------------------------------------------------------

func _build_ui() -> void:
	_board = BoardView3D.new()
	add_child(_board)
	_board.path_changed.connect(_on_path_changed)

	_word_label = _label(64, TEXT)
	_word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_word_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_quest_label = _label(42, ACCENT)
	_quest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_progress_label = _label(36, GLOW)
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_label = _label(36, TEXT_DIM)
	_coins_label = _label(44, ACCENT)
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_refill_button = _button("", 38)
	_refill_button.pressed.connect(func() -> void: session.refill())

	_give_up_button = _button("Aufgeben", 34)
	_give_up_button.flat = true
	_give_up_button.add_theme_color_override("font_color", TEXT_DIM)
	_give_up_button.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_give_up_button.pressed.connect(func() -> void: _confirm.visible = true)

	# Auftragswahl
	var k := _overlay("")
	_cards = k[0]
	_cards_title = k[2]
	for i in 2:
		var b := _button("", 40, k[1])
		b.custom_minimum_size = Vector2(820, 260)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var index := i
		b.pressed.connect(func() -> void: session.choose_quest(index))
		_card_buttons.append(b)

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
	_word_label.position = Vector2(0, s.y * 0.035)
	_word_label.size = Vector2(s.x, s.y * TOP_AREA - s.y * 0.035)
	_give_up_button.position = Vector2(s.x - side * 0.5 - s.x * 0.3, s.y * 0.012)
	_give_up_button.size = Vector2(s.x * 0.3, 70)

	var info_top := s.y * (1.0 - BOTTOM_AREA) + s.y * 0.01
	_quest_label.position = Vector2(side, info_top)
	_quest_label.size = Vector2(inner, 60)
	_progress_label.position = Vector2(side, info_top + 62)
	_progress_label.size = Vector2(inner, 50)
	_level_label.position = Vector2(side, info_top + 130)
	_level_label.size = Vector2(inner * 0.55, 60)
	_coins_label.position = Vector2(side + inner * 0.55, info_top + 125)
	_coins_label.size = Vector2(inner * 0.45, 60)
	_refill_button.position = Vector2(side + inner * 0.2, info_top + 200)
	_refill_button.size = Vector2(inner * 0.6, 95)
	_update_labels()


func _update_labels() -> void:
	if session == null:
		return
	var q := session.quest
	if q != null:
		_quest_label.text = describe(q, true)
		_progress_label.text = _progress_text(q)
	else:
		_quest_label.text = ""
		_progress_label.text = ""
	_level_label.text = "Level %d · Rekord %d" % [session.level(), maxi(SaveData.best_level(), session.level())]
	_coins_label.text = "Münzen %d" % session.coins
	_refill_button.text = "+%d Steine  −%d" % [BALANCE.refill_count, BALANCE.refill_price]
	_refill_button.disabled = not session.can_refill()


## Auftrag als Text. started: Zielwort ist bekannt (laufender Auftrag).
static func describe(q: Quest, started: bool) -> String:
	var t := ""
	match q.kind:
		Quest.Kind.SPECIFIC_WORD:
			if started and q.target != "":
				t = "Finde das Wort %s" % q.target
			else:
				t = "Finde ein bestimmtes Wort mit %d Buchstaben" % q.word_length
		_:
			if q.count == 1:
				t = "Finde ein Wort mit mind. %d Buchstaben" % q.word_length
			else:
				t = "Finde %d Wörter mit mind. %d Buchstaben" % [q.count, q.word_length]
	if q.max_moves > 0:
		t += " in höchstens %d Zügen" % q.max_moves
	if q.no_refill:
		t += ", ohne Nachfüllen"
	return t


func _progress_text(q: Quest) -> String:
	var parts: Array[String] = []
	if q.count > 1:
		parts.append("%d von %d" % [q.found, q.count])
	if q.max_moves > 0:
		parts.append("noch %d Züge" % q.moves_left())
	return " · ".join(parts)


## Kurz einen Text oben anzeigen, danach ausblenden.
func _flash(text: String, color: Color, hold: float = 1.6) -> void:
	_set_word_text(text, color)
	_flash_tween = create_tween()
	_flash_tween.tween_interval(hold)
	_flash_tween.tween_property(_word_label, "modulate:a", 0.0, 0.4)


func _set_word_text(text: String, color: Color) -> void:
	if _flash_tween:
		_flash_tween.kill()
	_word_label.modulate.a = 1.0
	_word_label.text = text
	_word_label.add_theme_color_override("font_color", color)


# --- Signale --------------------------------------------------------------------

func _on_path_changed(word: String) -> void:
	# Leer = Wischen beendet; eine laufende Meldung bleibt dann stehen.
	if word != "":
		_set_word_text(word, TEXT)
	elif not (_flash_tween and _flash_tween.is_running()):
		_word_label.text = ""


func _on_quest_offered(cards: Array[Quest]) -> void:
	_cards_title.text = "Level %d\nWähle deinen Auftrag" % session.level()
	var names := ["Sicher", "Riskant"]
	for i in _card_buttons.size():
		var b := _card_buttons[i]
		b.visible = i < cards.size()
		if b.visible:
			b.text = "%s\n%s\n+%d Münzen" % [names[i], describe(cards[i], false), cards[i].reward]
	if _cards_tween:
		_cards_tween.kill()
	if session.level() == 1:
		_cards.visible = true
	else:
		# Erst die Erfolgsmeldung und das Verschwinden des Worts zeigen.
		_cards_tween = create_tween()
		_cards_tween.tween_interval(CARDS_DELAY)
		_cards_tween.tween_callback(func() -> void: _cards.visible = not session.is_over)
	_update_labels()


func _on_quest_started(q: Quest) -> void:
	_cards.visible = false
	_update_labels()
	if q.kind == Quest.Kind.SPECIFIC_WORD and q.target != "":
		_flash("Finde: %s" % q.target, ACCENT, 2.2)


func _on_quest_completed(_q: Quest, reward: int) -> void:
	_flash("Geschafft!  +%d Münzen" % reward, GLOW, 1.0)


func _on_word_accepted(word: String, _cells: Array[Vector2i], counted: bool) -> void:
	if session.quest != null and not counted:
		_flash("%s – zählt nicht für den Auftrag" % word, TEXT_DIM, 1.2)


func _on_word_rejected(_cells: Array[Vector2i], reason: String) -> void:
	if reason == RunSession.REASON_TOO_SHORT:
		_flash("Mindestens %d Buchstaben" % BALANCE.min_length, TEXT_DIM, 1.0)


func _on_confirm_give_up() -> void:
	_confirm.visible = false
	session.give_up()


func _on_run_ended(level: int, reason: String) -> void:
	_cards.visible = false
	var new_record := SaveData.submit_level(level)
	var why := "Züge aufgebraucht" if reason == RunSession.REASON_OUT_OF_MOVES else "Lauf beendet"
	_summary_label.text = "%s\n\nLevel %d erreicht\n\nRekord: Level %d%s" % [
		why, level, SaveData.best_level(), "\nNeuer Rekord!" if new_record else ""]
	_summary.visible = true
	_update_labels()
