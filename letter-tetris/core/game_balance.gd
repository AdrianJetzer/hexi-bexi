class_name GameBalance
extends Resource
## Alle einstellbaren Spielwerte (siehe spec/game-rules.md). Keine Werte fest im Code.

@export_group("Raster")
@export var grid_cols: int = 6
@export var grid_rows: int = 9

@export_group("Runde")
## Anzahl Reihen, die zu Beginn gefüllt sind.
@export var start_rows: int = 2
## Mindestlänge eines Wortes.
@export var min_word_length: int = 3

@export_group("Tempo")
## Sekunden zwischen zwei neuen Hexagons zu Beginn.
@export var spawn_interval_start: float = 3.0
## Alle so viele Sekunden wird der Takt kürzer.
@export var speedup_every: float = 30.0
## Faktor pro Verkürzung (0.9 = 10 % kürzer).
@export var speedup_factor: float = 0.9
## Kürzester Takt in Sekunden.
@export var spawn_interval_min: float = 0.8

@export_group("Punkte")
## Punkte = points_factor · n · (n − 1).
@export var points_factor: int = 5


@export_group("Schwierigkeit (Wort-Hilfe)")
## Stufen 1 (leicht) bis 5 (Profi), siehe spec/game-rules.md.
@export var difficulty_levels: Array[DifficultyLevel] = []
## Stufe beim ersten Start (1-basiert).
@export var default_difficulty: int = 1
## Längste Wortlänge, die die Wort-Hilfe berücksichtigt (wegen Rechenzeit).
@export var help_max_word_length: int = 6


## Stufe 1..n; außerhalb des Bereichs wird begrenzt. null, wenn keine Stufen definiert sind.
func difficulty(level: int) -> DifficultyLevel:
	if difficulty_levels.is_empty():
		return null
	return difficulty_levels[clampi(level, 1, difficulty_levels.size()) - 1]


## Takt (Sekunden) für eine Tempo-Stufe (Stufe 1 = Start).
func interval_for_level(level: int) -> float:
	var raw := spawn_interval_start * pow(speedup_factor, maxi(level, 1) - 1)
	return maxf(raw, spawn_interval_min)


## Höchste Tempo-Stufe: die erste, bei der der kürzeste Takt erreicht ist.
func max_level() -> int:
	var level := 1
	while interval_for_level(level) > spawn_interval_min and level < 1000:
		level += 1
	return level


## Tempo-Stufe nach so vielen Sekunden Spielzeit.
func level_at(elapsed: float) -> int:
	var level := 1 + int(floor(maxf(elapsed, 0.0) / speedup_every))
	return mini(level, max_level())
