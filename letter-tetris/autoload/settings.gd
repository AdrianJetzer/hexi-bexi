extends Node
## Einstellungen des Spielers, lokal gespeichert (user://settings.cfg).
## Als Autoload „Settings“ überall verfügbar.

signal changed

const PATH := "user://settings.cfg"
const BALANCE: GameBalance = preload("res://data/balance.tres")

## Schwierigkeitsstufe 1..5 (gilt ab der nächsten Runde).
var difficulty: int = 3:
	set(value):
		difficulty = clampi(value, 1, maxi(BALANCE.difficulty_levels.size(), 1))
		_save()
		changed.emit()
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

var _loading: bool = false


func _ready() -> void:
	_load()


func _load() -> void:
	_loading = true
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		difficulty = cfg.get_value("game", "difficulty", BALANCE.default_difficulty)
		sound_on = cfg.get_value("audio", "sound_on", true)
		music_on = cfg.get_value("audio", "music_on", true)
	else:
		difficulty = BALANCE.default_difficulty
	_loading = false


func _save() -> void:
	if _loading:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("game", "difficulty", difficulty)
	cfg.set_value("audio", "sound_on", sound_on)
	cfg.set_value("audio", "music_on", music_on)
	cfg.save(PATH)
