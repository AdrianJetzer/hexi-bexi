class_name StoryChapter
extends RefCounted
## Kapitel des Story-Modus (spec/story-mode.md): eine Kategorie mit Themenwörtern und
## Rätselsätzen. Gelesen aus res://data/story/<id>.txt, Zeilen „WORT;Rätselsatz“
## (# = Kommentar).

## Kapitel-Brett (spec/story-mode.md, „Kapitel-Brett“): BOARD_COLS × BOARD_ROWS Hexagons,
## Reihe 0 unten (leicht) bis oben (schwer). Je Reihe [Kennung, Name]; Reihen ohne Eintrag
## sind noch leer („bald“). Ein Kapitel ist spielbar, wenn seine Wortliste existiert.
const BOARD_COLS := 4
const BOARD_ROWS := 6
const BOARD := [
	[["tiere", "Tiere"], ["gemuese", "Gemüse"], ["fruechte", "Früchte"], ["kleidung", "Kleidung"]],
	[["fluesse", "Flüsse"], ["automarken", "Automarken"], ["laender", "Länder"], ["berufe", "Berufe"]],
]

var id: String = ""
var display_name: String = ""
## Themenwörter in Großbuchstaben (A–Z, Ä, Ö, Ü).
var words: PackedStringArray = PackedStringArray()
var _riddles: Dictionary = {}


## Alle spielbaren Kapitel in Brett-Reihenfolge (Reihe für Reihe, links nach rechts).
static func all() -> Array[StoryChapter]:
	var out: Array[StoryChapter] = []
	for row in BOARD:
		for c in row:
			if playable(c[0]):
				out.append(load_chapter(c[0], c[1]))
	return out


static func by_id(chapter_id: String) -> StoryChapter:
	for row in BOARD:
		for c in row:
			if c[0] == chapter_id:
				return load_chapter(c[0], c[1])
	return null


## Kennung und Name des Kapitels an Brett-Platz (Spalte, Reihe); leer = noch keins.
static func slot(col: int, row: int) -> Array:
	if row < 0 or row >= BOARD.size() or col < 0 or col >= (BOARD[row] as Array).size():
		return []
	return BOARD[row][col]


## Gibt es die Wortliste schon?
static func playable(chapter_id: String) -> bool:
	return FileAccess.file_exists("res://data/story/%s.txt" % chapter_id)


## Ist Reihe row aufgedeckt? Reihe 0 immer; sonst, sobald ein Kapitel der Reihe darunter
## geschafft ist. stars: Callable(id) -> int (beste Sterne, 0 = nicht geschafft).
static func row_open(row: int, stars: Callable) -> bool:
	if row <= 0:
		return true
	if row > BOARD.size():
		return false
	for c in BOARD[row - 1]:
		if int(stars.call(c[0])) > 0:
			return true
	return false


static func load_chapter(chapter_id: String, name: String) -> StoryChapter:
	var path := "res://data/story/%s.txt" % chapter_id
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Kapitel nicht gefunden: %s" % path)
		return null
	var ch := StoryChapter.new()
	ch.id = chapter_id
	ch.display_name = name
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var parts := line.split(";", true, 1)
		var w := parts[0].strip_edges().to_upper()
		if w.length() < 3:
			continue
		ch.words.append(w)
		ch._riddles[w] = parts[1].strip_edges() if parts.size() > 1 else ""
	return ch


## Rätselsatz zu einem Themenwort ("" = keiner).
func riddle_for(word: String) -> String:
	return _riddles.get(word.to_upper(), "")


## Themenwörter mit Länge zwischen lo und hi.
func words_between(lo: int, hi: int) -> PackedStringArray:
	var out := PackedStringArray()
	for w in words:
		if w.length() >= lo and w.length() <= hi:
			out.append(w)
	return out
