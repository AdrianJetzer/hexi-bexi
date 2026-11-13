class_name Quest
extends Resource
## Ein Auftrag im Lauf-Modus (siehe spec/run-mode.md).
##
## Als Ressource ist er zugleich Vorlage (in der Auftrags-Kurve) und laufender Auftrag:
## Für eine Runde wird die Vorlage mit start() kopiert; die Kopie zählt Fortschritt und Züge.

enum Kind {
	## Wörter mit mindestens word_length Buchstaben finden (count Stück).
	LENGTH,
	## Ein bestimmtes Wort finden (target, wird beim Säen festgelegt).
	SPECIFIC_WORD,
}

@export var kind: Kind = Kind.LENGTH
## LENGTH: Mindestlänge der Wörter. SPECIFIC_WORD: Länge des Zielworts.
@export var word_length: int = 3
## Wie viele passende Wörter gefunden werden müssen.
@export var count: int = 1
## Höchstzahl der Züge (0 = kein Limit). Verfehlt → Lauf endet.
@export var max_moves: int = 0
## Im Level ist „Nachfüllen“ gesperrt.
@export var no_refill: bool = false
## Münzen bei Erfolg.
@export var reward: int = 100

## Zielwort (nur SPECIFIC_WORD), in Großbuchstaben.
var target: String = ""
## Gefundene passende Wörter.
var found: int = 0
## Gemachte Züge (jedes angenommene Wort).
var moves: int = 0


## Laufende Kopie dieser Vorlage, Fortschritt auf 0.
func start(p_target: String = "") -> Quest:
	var q := duplicate() as Quest
	q.target = p_target.to_upper()
	q.found = 0
	q.moves = 0
	return q


## Zählt dieses Wort für den Auftrag?
func matches(word: String) -> bool:
	match kind:
		Kind.LENGTH:
			return word.length() >= word_length
		Kind.SPECIFIC_WORD:
			return target != "" and word.to_upper() == target
	return false


## Ein angenommenes Wort melden: zählt als Zug, bei Treffer als Fortschritt.
## Gibt zurück, ob das Wort für den Auftrag gezählt hat.
## Nach Erfolg oder Scheitern ändert sich nichts mehr.
func register(word: String) -> bool:
	if is_done() or is_failed():
		return false
	moves += 1
	if matches(word):
		found += 1
		return true
	return false


func is_done() -> bool:
	return found >= count


## Zuglimit aufgebraucht, ohne dass der Auftrag erfüllt ist.
func is_failed() -> bool:
	return max_moves > 0 and moves >= max_moves and not is_done()


## Verbleibende Züge (-1 = kein Limit).
func moves_left() -> int:
	return -1 if max_moves <= 0 else maxi(max_moves - moves, 0)
