extends Control
## Spiel-Screen im ruhigen Level-Modus: 3D-Spielfeld mit 2D-Oberfläche
## (Wort-Anzeige, Infobereich mit Level und Knopf „Neue Buchstaben“, Beenden, Bilanz).

const BALANCE: GameBalance = preload("res://data/balance.tres")
const LANG: LanguageData = preload("res://data/languages/de/language.tres")

const TEXT := Color(0.85, 0.92, 1.0)
const TEXT_DIM := Color(0.6, 0.66, 0.85)
const ACCENT := Color(1.0, 0.84, 0.6)
const GLOW := Color(0.55, 0.95, 1.0)

## Anteile der Bildschirmhöhe/-breite für die Bereiche.
const SIDE_MARGIN := 0.06
const TOP_AREA := 0.11
const BOTTOM_AREA := 0.17

var session: GameSession

var _dictionary: WordDictionary
var _common: WordDictionary
var _board: BoardView3D
var _word_label: Label
var _score_label: Label
var _record_label: Label
var _last_label: Label
var _level_label: Label
var _refill_button: Button
var _end_button: Button
## Vorläufig: Stufe im Spiel umschalten (zieht später in die Einstellungen um).
var _difficulty_button: Button
var _confirm: ColorRect
var _summary: ColorRect
var _summary_label: Label
var _flash_tween: Tween


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Berührungen nicht hier abfangen, sondern ans Spielfeld (_unhandled_input) durchlassen.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dictionary = WordDictionary.from_file(LANG.words_path)
	_common = WordDictionary.from_file(LANG.common_words_path)
	_build_ui()
	get_viewport().size_changed.connect(_relayout)
	new_round()


## Neue Runde starten.
func new_round(seed_value: int = -1) -> void:
	session = GameSession.new(BALANCE, LANG, _dictionary, seed_value, _common, Settings.difficulty)
	session.score_changed.connect(_on_score_changed)
	session.level_changed.connect(_on_level_changed)
	session.word_accepted.connect(_on_word_accepted)
	session.round_ended.connect(_on_round_ended)
	_summary.visible = false
	_confirm.visible = false
	_last_label.text = ""
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

	_score_label = _label(56, TEXT)
	_record_label = _label(56, ACCENT)
	_last_label = _label(38, TEXT_DIM)
	_level_label = _label(38, GLOW)
	_record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_refill_button = _button("Neue Buchstaben  −%d" % BALANCE.refill_cost, 40)
	_refill_button.pressed.connect(func() -> void: session.request_more_letters())

	_end_button = _button("Beenden", 34)
	_end_button.flat = true
	_end_button.add_theme_color_override("font_color", TEXT_DIM)
	_end_button.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_end_button.pressed.connect(func() -> void: _confirm.visible = true)

	_difficulty_button = _button("", 34)
	_difficulty_button.flat = true
	_difficulty_button.add_theme_color_override("font_color", TEXT_DIM)
	_difficulty_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_difficulty_button.pressed.connect(_next_difficulty)

	# Nachfrage „Runde beenden?“
	var c := _overlay("Runde beenden?")
	_confirm = c[0]
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 40)
	(c[1] as VBoxContainer).add_child(row)
	var yes := _button("Ja", 56, row)
	yes.custom_minimum_size = Vector2(260, 130)
	yes.pressed.connect(_on_confirm_end)
	var no := _button("Nein", 56, row)
	no.custom_minimum_size = Vector2(260, 130)
	no.pressed.connect(func() -> void: _confirm.visible = false)

	# Bilanz
	var s := _overlay("")
	_summary = s[0]
	_summary_label = s[2]
	var again := _button("Nochmal", 64, s[1])
	again.custom_minimum_size = Vector2(520, 140)
	again.pressed.connect(func() -> void: new_round())


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
	_difficulty_button.position = Vector2(side * 0.5, s.y * 0.012)
	_difficulty_button.size = Vector2(s.x * 0.45, 70)
	_end_button.position = Vector2(s.x - side * 0.5 - s.x * 0.3, s.y * 0.012)
	_end_button.size = Vector2(s.x * 0.3, 70)

	var info_top := s.y * (1.0 - BOTTOM_AREA) + s.y * 0.02
	var half := inner / 2.0
	_score_label.position = Vector2(side, info_top)
	_score_label.size = Vector2(half, 80)
	_record_label.position = Vector2(side + half, info_top)
	_record_label.size = Vector2(half, 80)
	_last_label.position = Vector2(side, info_top + 85)
	_last_label.size = Vector2(half, 60)
	_level_label.position = Vector2(side + half * 0.6, info_top + 85)
	_level_label.size = Vector2(half * 1.4, 60)
	_refill_button.position = Vector2(side + inner * 0.2, info_top + 160)
	_refill_button.size = Vector2(inner * 0.6, 100)
	_update_labels()


func _update_labels() -> void:
	if session == null:
		return
	_score_label.text = "Punkte %d" % session.score
	_record_label.text = "Rekord %d" % maxi(SaveData.record(session.difficulty), session.score)
	var missing := maxi(session.next_level_score() - session.score, 0)
	_level_label.text = "Level %d · noch %d" % [session.level(), missing]
	var d := BALANCE.difficulty(session.difficulty)
	_difficulty_button.text = "%s %s ▸" % [_stars(session.difficulty), d.display_name if d else ""]
	_refill_button.disabled = session.is_over or session.grid.free_count() == 0


## Kurz einen Text oben anzeigen (z. B. „Level 2!“), danach ausblenden.
func _flash(text: String, color: Color) -> void:
	_set_word_text(text, color)
	_flash_tween = create_tween()
	_flash_tween.tween_interval(1.6)
	_flash_tween.tween_property(_word_label, "modulate:a", 0.0, 0.4)


func _set_word_text(text: String, color: Color) -> void:
	if _flash_tween:
		_flash_tween.kill()
	_word_label.modulate.a = 1.0
	_word_label.text = text
	_word_label.add_theme_color_override("font_color", color)


# --- Signale --------------------------------------------------------------------

func _on_path_changed(word: String) -> void:
	# Leer = Wischen beendet; eine laufende Level-Meldung bleibt dann stehen.
	if word != "":
		_set_word_text(word, TEXT)
	elif not (_flash_tween and _flash_tween.is_running()):
		_word_label.text = ""


func _on_score_changed(_score: int) -> void:
	_update_labels()


func _on_level_changed(level: int) -> void:
	_update_labels()
	if level > 1:
		var text := "Level %d!" % level
		# Nur erwähnen, wenn die Mindestlänge gerade gestiegen ist.
		if BALANCE.min_word_length(level) > BALANCE.min_word_length(level - 1):
			text += "  Ab jetzt %d Buchstaben" % session.min_word_length()
		_flash(text, GLOW)


func _on_word_accepted(word: String, _cells: Array[Vector2i], points: int) -> void:
	_last_label.text = "%s +%d" % [word, points]


func _on_confirm_end() -> void:
	_confirm.visible = false
	session.end_round()


func _on_round_ended(final_score: int, final_level: int) -> void:
	var new_record := SaveData.submit_score(session.difficulty, final_score)
	var rec := SaveData.record(session.difficulty)
	_summary_label.text = "Runde beendet\n\n%d Punkte\nLevel %d\n\nRekord %d%s" % [
		final_score, final_level, rec, "\nNeuer Rekord!" if new_record else ""]
	_summary.visible = true
	_update_labels()


## Vorläufig: nächste Stufe wählen (1 → 2 → … → 5 → 1) und neu starten.
func _next_difficulty() -> void:
	var n := BALANCE.difficulty_levels.size()
	Settings.difficulty = Settings.difficulty % n + 1
	new_round()


func _stars(level: int) -> String:
	var n := BALANCE.difficulty_levels.size()
	return "★".repeat(level) + "☆".repeat(maxi(n - level, 0))
