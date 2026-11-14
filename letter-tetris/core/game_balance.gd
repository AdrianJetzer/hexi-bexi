class_name GameBalance
extends Resource
## Alle einstellbaren Spielwerte (siehe spec/game-rules.md). Keine Werte fest im Code.

@export_group("Raster")
@export var grid_cols: int = 5
@export var grid_rows: int = 9

@export_group("Lauf")
## Hexagons zu Beginn eines Laufs.
@export var run_start_tiles: int = 10
## Münzen zu Beginn eines Laufs.
@export var start_coins: int = 0
## Mindestlänge eines Worts (immer, unabhängig vom Level).
@export var min_length: int = 3
## Hilfe „Auffüllen“: so viele Hexagons für so viele Münzen (fester Preis).
@export var refill_count: int = 5
@export var refill_price: int = 100
## Nach einem gefundenen Wort kommen automatisch (Wortlänge − dieser Wert) neue Hexagons
## (nicht bei Aufträgen „ohne Nachziehen“).
@export var auto_refill_less: int = 1
## Hilfe „Tauschen“: so viele zufällige Steine bekommen neue Buchstaben.
@export var swap_count: int = 5
@export var swap_price: int = 50
## Hilfe „Aufräumen“: bis zu so viele nutzlose Steine entfernen, für so viele Münzen.
@export var clear_count: int = 5
@export var clear_price: int = 100
## Hilfe „Tipp“: Preis je gezeigtem Buchstaben.
@export var hint_price: int = 100
## Hilfe „Lösen“: ganzen Auftrag lösen (ohne Belohnung).
@export var solve_price: int = 500
## Hilfe „Stein ersetzen“.
@export var replace_price: int = 100

@export_group("Hilfe-Stufen (Wort-Hilfe)")
## Stufen 1 (sehr starke Hilfe) bis 5 (keine), siehe spec/game-rules.md.
## Welche Stufe gilt, legt das Level über die Auftrags-Kurve fest.
@export var difficulty_levels: Array[DifficultyLevel] = []
## Längste Wortlänge, die die Wort-Hilfe berücksichtigt (wegen Rechenzeit).
@export var help_max_word_length: int = 8


## Stufe 1..n; außerhalb des Bereichs wird begrenzt. null, wenn keine Stufen definiert sind.
func difficulty(level: int) -> DifficultyLevel:
	if difficulty_levels.is_empty():
		return null
	return difficulty_levels[clampi(level, 1, difficulty_levels.size()) - 1]

