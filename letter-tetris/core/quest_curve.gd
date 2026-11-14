class_name QuestCurve
extends Resource
## Auftrags-Kurve des Lauf-Modus (siehe spec/run-mode.md, „Kurve“):
## feste Block-Zeilen für die ersten Levels, danach ein Block-Budget, das zufällig auf
## Zeilen verteilt wird.

## Zeilen je Level, Index 0 = Level 1 (z. B. [3, 4] = ein Wort mit 3 und eines mit 4).
@export var level_rows: Array[PackedInt32Array] = []
## Hilfe-Stufe je Level (Index 0 = Level 1), 1 = sehr stark … 5 = keine.
@export var level_help: PackedInt32Array = PackedInt32Array()

@export_group("Nach der festen Kurve (Block-Budget)")
## Blöcke im ersten Level nach der festen Kurve.
@export var budget_start: int = 12
## Alle so vielen Levels ein Block mehr.
@export var budget_every: int = 5
@export var budget_max: int = 24
@export var row_min: int = 3
@export var row_max: int = 8
@export var rows_max: int = 3
## Hilfe-Stufe nach der festen Kurve.
@export var endless_help_level: int = 5

@export_group("Belohnung")
## Münzen = reward_base + reward_per_level × Level.
@export var reward_base: int = 100
@export var reward_per_level: int = 0


## Letztes Level der festen Kurve.
func last_level() -> int:
	return level_rows.size()


## Feste Zeilen für ein Level, leer nach der festen Kurve.
func rows_for(level: int) -> PackedInt32Array:
	if level >= 1 and level <= level_rows.size():
		return level_rows[level - 1]
	return PackedInt32Array()


## Hilfe-Stufe für ein Level.
func help_level(level: int) -> int:
	if level >= 1 and level <= level_help.size():
		return level_help[level - 1]
	return endless_help_level


## Block-Budget nach der festen Kurve (0 innerhalb der festen Kurve).
## Beispiel mit Kurve bis 10: Level 11–15 → 12, 16–20 → 13 …
func budget(level: int) -> int:
	var beyond := level - last_level()
	if beyond <= 0:
		return 0
	var steps := (beyond - 1) / maxi(budget_every, 1)
	return mini(budget_start + steps, mini(budget_max, rows_max * row_max))


func reward(level: int) -> int:
	return reward_base + reward_per_level * level
