extends Control
## Spiel-Screen: 3D-Spielfeld mit 2D-Oberfläche (Wort-Anzeige, Infobereich, Game-Over).

const BALANCE: GameBalance = preload("res://data/balance.tres")
const LANG: LanguageData = preload("res://data/languages/de/language.tres")

const TEXT := Color(0.85, 0.92, 1.0)
const TEXT_DIM := Color(0.6, 0.66, 0.85)
const ACCENT := Color(1.0, 0.84, 0.6)

## Anteile der Bildschirmhöhe/-breite für die Bereiche.
const SIDE_MARGIN := 0.06
const TOP_AREA := 0.11
const BOTTOM_AREA := 0.15

var session: GameSession

var _dictionary: WordDictionary
var _common: WordDictionary
## Vorläufig: Stufe im Spiel umschalten (zieht später in die Einstellungen um).
var _difficulty_button: Button
var _board: BoardView3D
var _word_label: Label
var _score_label: Label
var _record_label: Label
var _last_label: Label
var _level_label: Label
var _overlay: ColorRect
var _overlay_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Berührungen nicht hier abfangen, sondern ans Spielfeld (_unhandled_input) durchlassen.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dictionary = WordDictionary.from_file(LANG.words_path)
	_common = WordDictionary.from_file(LANG.common_words_path)
	_build_ui()
	get_viewport().size_changed.connect(_relayout)
	new_round()


func _process(delta: float) -> void:
	if session != null:
		session.update(delta)


func _notification(what: int) -> void:
	if session == null:
		return
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			session.pause()
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			session.resume()


## Neue Runde starten.
func new_round(seed_value: int = -1) -> void:
	session = GameSession.new(BALANCE, LANG, _dictionary, seed_value, _common, Settings.difficulty)
	session.score_changed.connect(_on_score_changed)
	session.level_changed.connect(_on_level_changed)
	session.word_accepted.connect(_on_word_accepted)
	session.game_over.connect(_on_game_over)
	_overlay.visible = false
	_last_label.text = ""
	_board.setup(session)
	session.start()
	_relayout()


# --- Aufbau ---------------------------------------------------------------------

func _build_ui() -> void:
	_board = BoardView3D.new()
	add_child(_board)
	_board.path_changed.connect(func(w: String) -> void: _word_label.text = w)

	_word_label = _label(64, TEXT)
	_word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_word_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_score_label = _label(56, TEXT)
	_record_label = _label(56, ACCENT)
	_last_label = _label(38, TEXT_DIM)
	_level_label = _label(38, TEXT_DIM)
	_record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_difficulty_button = Button.new()
	_difficulty_button.add_theme_font_size_override("font_size", 34)
	_difficulty_button.flat = true
	_difficulty_button.add_theme_color_override("font_color", TEXT_DIM)
	_difficulty_button.pressed.connect(_next_difficulty)
	add_child(_difficulty_button)

	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.7)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	add_child(_overlay)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 48)
	center.add_child(box)
	_overlay_label = Label.new()
	_overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_label.add_theme_font_size_override("font_size", 72)
	_overlay_label.add_theme_color_override("font_color", TEXT)
	box.add_child(_overlay_label)
	var again := Button.new()
	again.text = "Nochmal"
	again.add_theme_font_size_override("font_size", 64)
	again.custom_minimum_size = Vector2(520, 140)
	again.pressed.connect(func() -> void: new_round())
	box.add_child(again)


func _label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


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
	_word_label.position = Vector2(0, s.y * 0.02)
	_word_label.size = Vector2(s.x, s.y * TOP_AREA - s.y * 0.02)
	var info_top := s.y * (1.0 - BOTTOM_AREA) + s.y * 0.025
	var half := (s.x - 2.0 * side) / 2.0
	_score_label.position = Vector2(side, info_top)
	_score_label.size = Vector2(half, 80)
	_record_label.position = Vector2(side + half, info_top)
	_record_label.size = Vector2(half, 80)
	_last_label.position = Vector2(side, info_top + 90)
	_last_label.size = Vector2(half, 60)
	_level_label.position = Vector2(side + half, info_top + 90)
	_level_label.size = Vector2(half, 60)
	_difficulty_button.position = Vector2(side * 0.5, s.y * 0.02)
	_difficulty_button.size = Vector2(s.x * 0.36, s.y * 0.05)
	_update_labels()


func _update_labels() -> void:
	if session == null:
		return
	_score_label.text = "Punkte %d" % session.score
	_record_label.text = "Rekord %d" % maxi(SaveData.record(session.difficulty), session.score)
	_level_label.text = "Tempo %d" % session.level()
	var d := BALANCE.difficulty(session.difficulty)
	_difficulty_button.text = "%s %s ▸" % [_stars(session.difficulty), d.display_name if d else ""]


# --- Signale --------------------------------------------------------------------

func _on_score_changed(_score: int) -> void:
	_update_labels()


func _on_level_changed(_level: int) -> void:
	_update_labels()


func _on_word_accepted(word: String, _cells: Array[Vector2i], points: int) -> void:
	_last_label.text = "%s +%d" % [word, points]


func _on_game_over(final_score: int) -> void:
	var new_record := SaveData.submit_score(session.difficulty, final_score)
	_overlay_label.text = "Spiel vorbei\n%d Punkte%s" % [final_score, "\nNeuer Rekord!" if new_record else ""]
	_overlay.visible = true
	_update_labels()


## Vorläufig: nächste Stufe wählen (1 → 2 → … → 5 → 1) und neu starten.
func _next_difficulty() -> void:
	var n := BALANCE.difficulty_levels.size()
	Settings.difficulty = Settings.difficulty % n + 1
	new_round()


func _stars(level: int) -> String:
	var n := BALANCE.difficulty_levels.size()
	return "★".repeat(level) + "☆".repeat(maxi(n - level, 0))
