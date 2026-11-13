extends Node
## Rekord im Lauf-Modus (höchstes erreichtes Level), lokal gespeichert (user://save.cfg).
## Als Autoload „SaveData“ überall verfügbar. Später erweiterbar um Online-Ranglisten.

const PATH := "user://save.cfg"

## Höchstes erreichtes Level (0 = noch keiner).
var _best_level: int = 0


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		_best_level = int(cfg.get_value("run", "best_level", 0))


## Rekord: höchstes erreichtes Level (0 = noch keiner).
func best_level() -> int:
	return _best_level


## Erreichtes Level eines beendeten Laufs melden. Gibt true zurück, wenn es ein neuer Rekord ist.
func submit_level(level: int) -> bool:
	if level <= _best_level:
		return false
	_best_level = level
	_save()
	return true


## Rekord löschen (Einstellungen → „Rekord zurücksetzen“).
func reset_record() -> void:
	_best_level = 0
	_save()


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("run", "best_level", _best_level)
	cfg.save(PATH)
