class_name QuestCurveStep
extends Resource
## Ein Abschnitt der Auftrags-Kurve: für Level first_level..last_level je eine sichere
## und eine riskante Auftragskarte plus die Hilfe-Stufe (siehe spec/run-mode.md, „Kurve“).

@export var first_level: int = 1
@export var last_level: int = 1
## Karte A (sicher).
@export var safe: Quest
## Karte B (riskant).
@export var risky: Quest
## Hilfe-Stufe 1 (sehr stark) bis 5 (keine), Index in GameBalance.difficulty_levels.
@export var help_level: int = 1


func covers(level: int) -> bool:
	return level >= first_level and level <= last_level
