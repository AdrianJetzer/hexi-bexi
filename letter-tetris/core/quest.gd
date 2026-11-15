class_name Quest
extends Resource
## Ein Auftrag im Lauf-Modus (siehe spec/run-mode.md, „Block-Zeilen“):
## 1 bis 3 Zeilen leerer Blöcke, jede mit eigener Länge. Ein Wort passt, wenn es genau so
## lang ist wie eine noch freie Zeile; es füllt dann die oberste passende Zeile.
##
## Als Ressource ist er zugleich Vorlage und laufender Auftrag: start() liefert eine Kopie
## mit leeren Zeilen.

## Länge jeder Zeile (Anzahl Blöcke), von oben nach unten.
@export var rows: PackedInt32Array = PackedInt32Array([3])
## Münzen bei Erfolg.
@export var reward: int = 100

## Eingetragene Wörter je Zeile ("" = noch frei).
var filled: PackedStringArray = PackedStringArray()


## Laufende Kopie dieser Vorlage, alle Zeilen frei.
func start() -> Quest:
	var q := duplicate() as Quest
	q.rows = rows.duplicate()
	q.filled = PackedStringArray()
	q.filled.resize(rows.size())
	return q


## Index der obersten freien Zeile mit genau dieser Wortlänge, sonst -1.
func free_row_for(word: String) -> int:
	_ensure_filled()
	for i in rows.size():
		if filled[i] == "" and rows[i] == word.length():
			return i
	return -1


## Passt dieses Wort in eine freie Zeile?
func matches(word: String) -> bool:
	return free_row_for(word) >= 0


## Wort in eine Zeile eintragen.
func fill(row: int, word: String) -> void:
	_ensure_filled()
	if row >= 0 and row < rows.size():
		filled[row] = word.to_upper()


func is_done() -> bool:
	_ensure_filled()
	for w in filled:
		if w == "":
			return false
	return true


## Längen der noch freien Zeilen (ohne Doppelte, aufsteigend).
func free_lengths() -> PackedInt32Array:
	_ensure_filled()
	var result := PackedInt32Array()
	for i in rows.size():
		if filled[i] == "" and not result.has(rows[i]):
			result.append(rows[i])
	result.sort()
	return result


## Zeile halbieren (Hilfe „Teilen“): aus n Blöcken werden ceil(n/2) + floor(n/2).
## Nur für freie Zeilen; gibt false zurück, wenn nicht möglich.
func split_row(row: int) -> bool:
	_ensure_filled()
	if row < 0 or row >= rows.size() or filled[row] != "":
		return false
	var n := rows[row]
	rows[row] = (n + 1) / 2
	rows.insert(row + 1, n / 2)
	filled.insert(row + 1, "")
	return true


## Freie Zeile um einen Block kürzen (Hilfe „Kürzen“). false, wenn gefüllt oder ungültig.
func shorten_row(row: int) -> bool:
	_ensure_filled()
	if row < 0 or row >= rows.size() or filled[row] != "" or rows[row] <= 1:
		return false
	rows[row] -= 1
	return true


## Anzahl aller Blöcke.
func block_count() -> int:
	var n := 0
	for r in rows:
		n += r
	return n


func _ensure_filled() -> void:
	if filled.size() != rows.size():
		filled.resize(rows.size())
