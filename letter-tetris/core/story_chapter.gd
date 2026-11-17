class_name StoryChapter
extends RefCounted
## Kapitel des Story-Modus (spec/story-mode.md): eine Kategorie mit Themenwörtern und
## Rätselsätzen. Gelesen aus res://data/story/<id>.txt, Zeilen „WORT;Rätselsatz“
## (# = Kommentar).

## Reihenfolge der Kapitel auf dem Pfad: [Kennung, Name].
const CHAPTERS := [["tiere", "Tiere"], ["gemuese", "Gemüse"], ["fruechte", "Früchte"]]

var id: String = ""
var display_name: String = ""
## Themenwörter in Großbuchstaben (A–Z, Ä, Ö, Ü).
var words: PackedStringArray = PackedStringArray()
var _riddles: Dictionary = {}


## Alle Kapitel in Pfad-Reihenfolge.
static func all() -> Array[StoryChapter]:
	var out: Array[StoryChapter] = []
	for c in CHAPTERS:
		var ch := load_chapter(c[0], c[1])
		if ch != null:
			out.append(ch)
	return out


static func by_id(chapter_id: String) -> StoryChapter:
	for c in CHAPTERS:
		if c[0] == chapter_id:
			return load_chapter(c[0], c[1])
	return null


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
