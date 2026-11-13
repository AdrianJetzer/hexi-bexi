class_name Spawner
extends RefCounted
## Takt und Platzwahl für neue Hexagons (reine Logik).
##
## tick(delta) zählt die Spielzeit und meldet, wie viele neue Hexagons fällig sind.
## spawn_into(grid) setzt ein neues Hexagon auf einen erlaubten Platz.

var elapsed: float = 0.0

## Wort-Hilfe (optional): Wortsucher für geläufige Wörter und Schwierigkeitsstufe.
var finder: WordFinder
var difficulty: DifficultyLevel

var _balance: GameBalance
var _picker: LetterPicker
var _rng: RandomNumberGenerator
var _until_next: float


func _init(balance: GameBalance, picker: LetterPicker, rng: RandomNumberGenerator = null) -> void:
	_balance = balance
	_picker = picker
	_rng = rng if rng != null else RandomNumberGenerator.new()
	_until_next = current_interval()


## Aktuelle Tempo-Stufe (1 = Start).
func level() -> int:
	return _balance.level_at(elapsed)


## Aktueller Takt in Sekunden.
func current_interval() -> float:
	return _balance.interval_for_level(level())


## Sekunden bis zum nächsten neuen Hexagon.
func time_until_next() -> float:
	return _until_next


## Spielzeit weiterzählen. Gibt die Anzahl fälliger neuer Hexagons zurück.
func tick(delta: float) -> int:
	if delta <= 0.0:
		return 0
	elapsed += delta
	_until_next -= delta
	var due := 0
	while _until_next <= 0.0:
		due += 1
		_until_next += current_interval()
	return due


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


func _board_letters(grid: HexGrid) -> PackedStringArray:
	var letters := PackedStringArray()
	for cell in grid.all_cells():
		if grid.is_occupied(cell):
			letters.append(grid.get_letter(cell))
	return letters
