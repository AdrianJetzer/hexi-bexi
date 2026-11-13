class_name WordDictionary
extends RefCounted
## Prüft, ob ein Wort gültig ist.
##
## Speicherformat „LTW1“ (kompakt, ca. so groß wie die reine Buchstabenmenge):
##   "LTW1" | max_len (u32) | Anzahl je Länge 1..max_len (u32) | Wörter nach Länge
##   gruppiert, je Gruppe sortiert, ASCII ohne Trennzeichen.
## Suche: binäre Suche innerhalb der Gruppe mit passender Länge.
## Erzeugt wird die Datei von tools/dictionary/pack_words.py.

const MAGIC := "LTW1"

var _data: PackedByteArray = PackedByteArray()
var _counts: PackedInt32Array = PackedInt32Array()   # Index = Länge
var _offsets: PackedInt64Array = PackedInt64Array()  # Index = Länge
var _size: int = 0


## Aus einer Liste bauen (für Tests und kleine Listen).
static func from_words(words: PackedStringArray) -> WordDictionary:
	var by_len := {}
	for w in words:
		var u := w.strip_edges().to_upper()
		if u.is_empty():
			continue
		if not by_len.has(u.length()):
			by_len[u.length()] = {}
		by_len[u.length()][u] = true
	var max_len := 0
	for n in by_len:
		max_len = maxi(max_len, n)
	var buf := PackedByteArray()
	buf.append_array(MAGIC.to_ascii_buffer())
	buf.append_array(_u32(max_len))
	for n in range(1, max_len + 1):
		buf.append_array(_u32(by_len[n].size() if by_len.has(n) else 0))
	for n in range(1, max_len + 1):
		if not by_len.has(n):
			continue
		var group := PackedStringArray(by_len[n].keys())
		group.sort()
		for w in group:
			buf.append_array(w.to_ascii_buffer())
	return from_bytes(buf)


## Aus einer gepackten Datei laden. Gibt null zurück, wenn sie fehlt oder ungültig ist.
static func from_file(path: String) -> WordDictionary:
	if not FileAccess.file_exists(path):
		push_error("Wortliste nicht gefunden: %s" % path)
		return null
	return from_bytes(FileAccess.get_file_as_bytes(path))


static func from_bytes(bytes: PackedByteArray) -> WordDictionary:
	if bytes.size() < 8 or bytes.slice(0, 4).get_string_from_ascii() != MAGIC:
		push_error("Wortliste hat kein gültiges Format")
		return null
	var d := WordDictionary.new()
	var max_len := bytes.decode_u32(4)
	d._counts.resize(max_len + 1)
	d._offsets.resize(max_len + 1)
	var pos := 8 + 4 * max_len
	for n in range(1, max_len + 1):
		var count := bytes.decode_u32(8 + 4 * (n - 1))
		d._counts[n] = count
		d._offsets[n] = pos
		pos += count * n
		d._size += count
	if pos != bytes.size():
		push_error("Wortliste ist beschädigt (Größe passt nicht)")
		return null
	d._data = bytes
	return d


func contains(word: String) -> bool:
	var w := word.to_upper()
	var n := w.length()
	if n == 0 or n >= _counts.size() or _counts[n] == 0:
		return false
	var lo := 0
	var hi := _counts[n] - 1
	var base := _offsets[n]
	while lo <= hi:
		var mid := (lo + hi) >> 1
		var start := base + mid * n
		var candidate := _data.slice(start, start + n).get_string_from_ascii()
		if candidate == w:
			return true
		if candidate < w:
			lo = mid + 1
		else:
			hi = mid - 1
	return false


## Gibt es mindestens ein Wort, das mit prefix beginnt (das Wort selbst eingeschlossen)?
func has_prefix(prefix: String) -> bool:
	var p := prefix.to_upper()
	var n := p.length()
	if n == 0:
		return _size > 0
	for length in range(n, _counts.size()):
		if _counts[length] == 0:
			continue
		var i := _lower_bound(length, p)
		if i < _counts[length]:
			var start := _offsets[length] + i * length
			if _data.slice(start, start + n).get_string_from_ascii() == p:
				return true
	return false


## Anzahl Wörter mit genau dieser Länge.
func count_of_length(length: int) -> int:
	if length <= 0 or length >= _counts.size():
		return 0
	return _counts[length]


## Das index-te Wort (alphabetisch) mit dieser Länge, z. B. für eine Zufallsauswahl.
func word_at(length: int, index: int) -> String:
	if index < 0 or index >= count_of_length(length):
		return ""
	var start := _offsets[length] + index * length
	return _data.slice(start, start + length).get_string_from_ascii()


## Längste gespeicherte Wortlänge.
func max_length() -> int:
	return _counts.size() - 1


func size() -> int:
	return _size


## Erster Index in der Gruppe „length“, dessen Anfang (Länge von p) ≥ p ist.
func _lower_bound(length: int, p: String) -> int:
	var n := p.length()
	var lo := 0
	var hi := _counts[length]
	var base := _offsets[length]
	while lo < hi:
		var mid := (lo + hi) >> 1
		var start := base + mid * length
		var head := _data.slice(start, start + n).get_string_from_ascii()
		if head < p:
			lo = mid + 1
		else:
			hi = mid
	return lo


## Gepackte Bytes (z. B. zum Vergleich mit der Datei aus pack_words.py).
func to_bytes() -> PackedByteArray:
	return _data


static func _u32(v: int) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(4)
	b.encode_u32(0, v)
	return b
