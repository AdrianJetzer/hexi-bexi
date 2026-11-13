class_name GameBalance
extends Resource
## Alle einstellbaren Spielwerte (siehe spec/game-rules.md). Keine Werte fest im Code.

@export_group("Raster")
@export var grid_cols: int = 5
@export var grid_rows: int = 9

@export_group("Runde")
## Anzahl Hexagons zu Beginn einer Runde.
@export var start_tiles: int = 15

@export_group("Level")
## Punkte für Level 2.
@export var first_threshold: int = 100
## Jeder weitere Schritt ist um diesen Faktor größer (1.5 = +50 %).
@export var threshold_growth: float = 1.5
## Neue Hexagons pro Level-Up.
@export var tiles_per_level: int = 10
## Mindestlänge eines Wortes je Level (Index 0 = Level 1); danach gilt der letzte Wert.
@export var min_length_by_level: PackedInt32Array = PackedInt32Array([3, 3, 4, 4, 5])

@export_group("Knopf „Neue Buchstaben“")
@export var refill_tiles: int = 3
@export var refill_cost: int = 20

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


## Punkte, ab denen ein Level erreicht ist (Level 1 = 0).
## Schritt k = first_threshold · growth^(k−1), aufsummiert, abgerundet.
func threshold(level: int) -> int:
	var total := 0.0
	for k in range(1, level):
		total += first_threshold * pow(threshold_growth, k - 1)
	return int(floor(total))


## Mindestlänge eines Wortes in einem Level.
func min_word_length(level: int) -> int:
	if min_length_by_level.is_empty():
		return 3
	return min_length_by_level[clampi(level, 1, min_length_by_level.size()) - 1]
