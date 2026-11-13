class_name WordDictionary
extends RefCounted
## Prüft, ob ein Wort gültig ist.
##
## Version 1: sortierte Liste (PackedStringArray) + binäre Suche.
## Das Speicherformat kann später ausgetauscht werden, ohne die Schnittstelle
## (contains / size) zu ändern.

var _words: PackedStringArray = PackedStringArray()


## Aus einer Liste bauen (wird bereinigt und sortiert).
static func from_words(words: PackedStringArray) -> WordDictionary:
	var d := WordDictionary.new()
	var cleaned := PackedStringArray()
	for w in words:
		var u := w.strip_edges().to_upper()
		if not u.is_empty():
			cleaned.append(u)
	cleaned.sort()
	d._words = _dedupe_sorted(cleaned)
	return d


## Aus einer Textdatei laden: ein Wort pro Zeile, Großbuchstaben, sortiert (LC_ALL=C).
## Gibt null zurück, wenn die Datei fehlt.
static func from_file(path: String) -> WordDictionary:
	if not FileAccess.file_exists(path):
		push_error("Wortliste nicht gefunden: %s" % path)
		return null
	var text := FileAccess.get_file_as_string(path)
	var lines := text.split("\n", false)
	var d := WordDictionary.new()
	if not _is_sorted(lines):
		lines.sort()
	d._words = _dedupe_sorted(lines)
	return d


func contains(word: String) -> bool:
	if word.is_empty():
		return false
	var w := word.to_upper()
	var i := _words.bsearch(w)
	return i < _words.size() and _words[i] == w


func size() -> int:
	return _words.size()


static func _is_sorted(a: PackedStringArray) -> bool:
	for i in range(1, a.size()):
		if a[i - 1] > a[i]:
			return false
	return true


static func _dedupe_sorted(a: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	for w in a:
		if out.is_empty() or out[out.size() - 1] != w:
			out.append(w)
	return out
