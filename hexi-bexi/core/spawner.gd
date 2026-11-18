class_name Spawner
extends RefCounted
## Platzwahl und Buchstabenwahl für neue Hexagons (reine Logik, ohne Zeit).
##
## spawn_into(grid) setzt ein neues Hexagon auf einen erlaubten Platz.

## Wort-Hilfe (optional): Wortsucher für geläufige Wörter und Schwierigkeitsstufe.
var finder: WordFinder
var difficulty: DifficultyLevel

var _picker: LetterPicker
var _rng: RandomNumberGenerator


func _init(picker: LetterPicker, rng: RandomNumberGenerator = null) -> void:
	_picker = picker
	_rng = rng if rng != null else RandomNumberGenerator.new()


## Erlaubten Platz wählen: zufällig unter den Kandidaten des Rasters.
## Gibt Vector2i(-1, -1) zurück, wenn kein Platz frei ist.
func choose_cell(grid: HexGrid) -> Vector2i:
	var candidates := grid.spawn_candidates()
	if candidates.is_empty():
		return Vector2i(-1, -1)
	return candidates[_rng.randi_range(0, candidates.size() - 1)]


## Ein neues Hexagon ins Raster setzen.
## Gibt {"cell": Vector2i, "letter": String} zurück, oder {} wenn das Feld voll ist.
func spawn_into(grid: HexGrid) -> Dictionary:
	var cell := choose_cell(grid)
	if cell.x < 0:
		return {}
	var letter := _picker.pick_for_cell(grid, cell, finder, difficulty)
	grid.set_letter(cell, letter)
	return {"cell": cell, "letter": letter}
