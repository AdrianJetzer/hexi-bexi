extends Node
## Rekorde und Sterne, lokal gespeichert (user://save.cfg). Als Autoload „SaveData“ überall
## verfügbar. Später erweiterbar um Online-Ranglisten.
##
## Lauf (einfach / mittel / schwierig): je Modus die meisten übrigen Münzen eines geschafften
## Laufs (Rekord) und die besten Sterne. Story: je Kapitel die besten Sterne.
## Mode- und Kapitel-Kennungen sind verschieden, daher teilen sie sich die Sterne-Tabelle.

const PATH := "user://save.cfg"

## Modus-Kennung → meiste übrige Münzen nach Level 20.
var _coins: Dictionary = {}
## Modus- oder Kapitel-Kennung → beste Sterne (0 = noch nicht geschafft).
var _stars: Dictionary = {}


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK and cfg.has_section("run"):
		for key in cfg.get_section_keys("run"):
			if key.begins_with("stars_"):
				_stars[key.substr(6)] = int(cfg.get_value("run", key))
			elif key.begins_with("coins_"):
				_coins[key.substr(6)] = int(cfg.get_value("run", key))
			# Alte Rekorde „best_…“ (höchstes Level) gelten nicht mehr: das Ziel ist jetzt Level 20.


## Rekord im Modus (leer = aktueller Modus): meiste übrige Münzen; 0 = noch keiner.
func best_coins(mode: String = "") -> int:
	return int(_coins.get(_mode(mode), 0))


## Beste Sterne eines Modus (leer = aktueller); 0 = noch nicht geschafft.
func mode_stars(mode: String = "") -> int:
	return int(_stars.get(_mode(mode), 0))


## Freischalten (spec/screens.md v4.45): Mittel erst nach mindestens einem Stern in Einfach,
## Schwer erst nach mindestens einem Stern in Mittel. Story ist immer offen.
const UNLOCK_AFTER := {"de_medium": "de_easy", "de_hard": "de_medium"}


## Ist der Modus spielbar? stars: Callable(mode) -> int (beste Sterne).
static func unlocked(mode: String, stars: Callable) -> bool:
	if not UNLOCK_AFTER.has(mode):
		return true
	return int(stars.call(UNLOCK_AFTER[mode])) >= 1


## Modus, der vorher mit mindestens einem Stern geschafft sein muss ("" = immer offen).
static func unlock_requirement(mode: String) -> String:
	return UNLOCK_AFTER.get(mode, "")


## Ist der Modus mit den gespeicherten Sternen spielbar?
func mode_unlocked(mode: String) -> bool:
	return unlocked(mode, mode_stars)


## Geschafften Lauf melden (übrige Münzen, Sterne). Gibt true zurück bei neuem Münz-Rekord.
func submit_run(coins: int, stars: int, mode: String = "") -> bool:
	var id := _mode(mode)
	var record := coins > best_coins(id)
	if record:
		_coins[id] = coins
	if stars > mode_stars(id):
		_stars[id] = stars
	_save()
	return record


## Rekord löschen (alle Modi und Kapitel).
func reset_record() -> void:
	_coins.clear()
	_stars.clear()
	_save()


## Story-Modus: beste Sterne eines Kapitels (0 = noch nicht geschafft).
func story_stars(chapter_id: String) -> int:
	return int(_stars.get(chapter_id, 0))


## Story-Modus: geschafftes Kapitel melden (behält die beste Wertung). true = verbessert.
func submit_story(chapter_id: String, stars: int) -> bool:
	if stars <= story_stars(chapter_id):
		return false
	_stars[chapter_id] = stars
	_save()
	return true


func _mode(mode: String) -> String:
	return mode if mode != "" else Settings.mode


func _save() -> void:
	var cfg := ConfigFile.new()
	for id in _coins:
		cfg.set_value("run", "coins_" + id, _coins[id])
	for id in _stars:
		cfg.set_value("run", "stars_" + id, _stars[id])
	cfg.save(PATH)
