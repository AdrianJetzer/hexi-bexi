extends Node
## Einstellungen des Spielers, lokal gespeichert (user://settings.cfg).
## Als Autoload „Settings“ überall verfügbar.

signal changed

const PATH := "user://settings.cfg"

var sound_on: bool = true:
	set(value):
		sound_on = value
		_save()
		changed.emit()
var music_on: bool = true:
	set(value):
		music_on = value
		_save()
		changed.emit()

## Spielmodus (Kennung, siehe GameMode / data/modes/). Neu installiert: mittel.
const DEFAULT_MODE := "de_medium"
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
		sound_on = cfg.get_value("audio", "sound_on", true)
		music_on = cfg.get_value("audio", "music_on", true)
		mode = cfg.get_value("game", "mode", DEFAULT_MODE)
	_loading = false


func _save() -> void:
	if _loading:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "sound_on", sound_on)
	cfg.set_value("audio", "music_on", music_on)
	cfg.set_value("game", "mode", mode)
	cfg.save(PATH)


## Der aktuelle Spielmodus als Daten.
func game_mode() -> GameMode:
	return load_mode(mode)


static func load_mode(id: String) -> GameMode:
	return load("res://data/modes/%s.tres" % id) as GameMode
