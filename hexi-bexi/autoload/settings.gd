extends Node
## Einstellungen des Spielers, lokal gespeichert (user://settings.cfg).
## Als Autoload „Settings“ überall verfügbar.

signal changed

const PATH := "user://settings.cfg"
## Vibrations-Tick: Dauer in ms und Stärke (0–1).
const TICK_MS := 15
const TICK_STRENGTH := 0.45

## Kein Ton und keine Musik (spec/look-and-sound.md v3): nur Vibration.
## Kurzer Vibrations-Tick beim Verbinden der Buchstaben (spec/screens.md, „Einstellungen“).
var vibration_on: bool = true:
	set(value):
		vibration_on = value
		_save()
		changed.emit()

## Testmodus: „Lösen“ kostet nichts (zum schnellen Durchspielen beim Testen).
var test_mode: bool = false:
	set(value):
		test_mode = value
		_save()
		changed.emit()

## Tutorial schon gesehen? Sonst läuft es beim Start (spec/screens.md, „Tutorial“).
var tutorial_seen: bool = false:
	set(value):
		tutorial_seen = value
		_save()

## Spielmodus (Kennung, siehe GameMode / data/modes/). Neu installiert: einfach (v4.38, nach
## dem Tutorial geht es in Einfach weiter).
const DEFAULT_MODE := "de_easy"
const MODES: PackedStringArray = ["de_easy", "de_medium", "de_hard", "story"]
const STORY_MODE := "story"
var mode: String = DEFAULT_MODE:
	set(value):
		mode = value if MODES.has(value) else DEFAULT_MODE
		_save()
		changed.emit()

var _loading: bool = false


func _ready() -> void:
	_load()


func _load() -> void:
	_loading = true
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		vibration_on = cfg.get_value("audio", "vibration_on", true)
		test_mode = cfg.get_value("game", "test_mode", false)
		mode = cfg.get_value("game", "mode", DEFAULT_MODE)
		tutorial_seen = cfg.get_value("game", "tutorial_seen", false)
	_loading = false


func _save() -> void:
	if _loading:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "vibration_on", vibration_on)
	cfg.set_value("game", "mode", mode)
	cfg.set_value("game", "test_mode", test_mode)
	cfg.set_value("game", "tutorial_seen", tutorial_seen)
	cfg.save(PATH)


## Der aktuelle Spielmodus als Daten.
func game_mode() -> GameMode:
	return load_mode(mode)


static func load_mode(id: String) -> GameMode:
	return load("res://data/modes/%s.tres" % id) as GameMode


## Kurzer, leichter Tick (Android/iOS; am Desktop wirkungslos). Nur wenn Vibration an ist.
func tick() -> void:
	if vibration_on:
		Input.vibrate_handheld(TICK_MS, TICK_STRENGTH)
