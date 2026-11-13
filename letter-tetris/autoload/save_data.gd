extends Node
## Rekorde pro Schwierigkeitsstufe, lokal gespeichert (user://save.cfg).
## Als Autoload „SaveData“ überall verfügbar. Später erweiterbar um Online-Ranglisten.

const PATH := "user://save.cfg"

var _records: Dictionary = {}   # Stufe (int) -> Punkte (int)


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		for key in cfg.get_section_keys("records") if cfg.has_section("records") else []:
			_records[int(key)] = int(cfg.get_value("records", key, 0))


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
	_save()


func _save() -> void:
	var cfg := ConfigFile.new()
	for level in _records:
		cfg.set_value("records", str(level), _records[level])
	cfg.save(PATH)
