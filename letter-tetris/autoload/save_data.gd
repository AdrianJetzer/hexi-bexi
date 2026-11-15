extends Node
## Rekord im Lauf-Modus (höchstes erreichtes Level) je Spielmodus, lokal gespeichert
## (user://save.cfg). Als Autoload „SaveData“ überall verfügbar. Später erweiterbar um
## Online-Ranglisten.

const PATH := "user://save.cfg"
## Alter Rekord (vor den Modi) zählt für „schwierig“, das bisherige Spiel.
const LEGACY_MODE := "de_hard"

## Modus-Kennung → höchstes erreichtes Level.
var _best: Dictionary = {}


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		for key in cfg.get_section_keys("run") if cfg.has_section("run") else []:
			if key == "best_level":
				_best[LEGACY_MODE] = maxi(int(_best.get(LEGACY_MODE, 0)), int(cfg.get_value("run", key)))
			elif key.begins_with("best_"):
				var id: String = key.substr(5)
				_best[id] = maxi(int(_best.get(id, 0)), int(cfg.get_value("run", key)))


## Rekord im Modus (leer = aktueller Modus aus den Einstellungen); 0 = noch keiner.
func best_level(mode: String = "") -> int:
	return int(_best.get(_mode(mode), 0))


## Erreichtes Level eines beendeten Laufs melden. Gibt true zurück, wenn es ein neuer Rekord ist.
func submit_level(level: int, mode: String = "") -> bool:
	var id := _mode(mode)
	if level <= best_level(id):
		return false
	_best[id] = level
	_save()
	return true


## Rekord löschen (alle Modi).
func reset_record() -> void:
	_best.clear()
	_save()


func _mode(mode: String) -> String:
	return mode if mode != "" else Settings.mode


func _save() -> void:
	var cfg := ConfigFile.new()
	for id in _best:
		cfg.set_value("run", "best_" + id, _best[id])
	cfg.save(PATH)
