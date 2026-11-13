extends Node
## Rekorde pro Schwierigkeitsstufe, lokal gespeichert (user://save.cfg).
## Als Autoload „SaveData“ überall verfügbar. Später erweiterbar um Online-Ranglisten.

const PATH := "user://save.cfg"

var _records: Dictionary = {}   # Stufe (int) -> Punkte (int)  (alter Level-Modus)
## Lauf-Modus: höchstes erreichtes Level.
var _best_level: int = 0


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		for key in cfg.get_section_keys("records") if cfg.has_section("records") else []:
			_records[int(key)] = int(cfg.get_value("records", key, 0))
		_best_level = int(cfg.get_value("run", "best_level", 0))


## Rekord im Lauf-Modus: höchstes erreichtes Level (0 = noch keiner).
func best_level() -> int:
	return _best_level


## Erreichtes Level eines beendeten Laufs melden. Gibt true zurück, wenn es ein neuer Rekord ist.
func submit_level(level: int) -> bool:
	if level <= _best_level:
		return false
	_best_level = level
	_save()
	return true


func record(level: int) -> int:
	return _records.get(level, 0)


## Punkte einer beendeten Runde melden. Gibt true zurück, wenn es ein neuer Rekord ist.
func submit_score(level: int, score: int) -> bool:
	if score <= record(level):
		return false
	_records[level] = score
	_save()
	return true


## Alle Rekorde löschen (Einstellungen → „Rekord zurücksetzen“).
func reset_records() -> void:
	_records.clear()
	_best_level = 0
	_save()


func _save() -> void:
	var cfg := ConfigFile.new()
	for level in _records:
		cfg.set_value("records", str(level), _records[level])
	cfg.set_value("run", "best_level", _best_level)
	cfg.save(PATH)
