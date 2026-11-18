class_name Tutorial
extends RefCounted
## Tutorial beim ersten Start (spec/screens.md, „Tutorial“): zwei feste Runden auf dem 5 × 5-Feld.
## Je Runde liegt das Zielwort als Kette in der untersten Reihe, dazu ein paar andere Steine.
## Nur das Zielwort zählt; ein Finger zeigt den Weg (das macht der Spiel-Bildschirm).

## Je Runde: Zielwort, Weg (Zellen in Buchstaben-Reihenfolge) und die übrigen Steine.
const STEPS: Array[Dictionary] = [
	{
		"word": "DAS",
		"path": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
		"others": {Vector2i(0, 0): "E", Vector2i(4, 0): "N", Vector2i(0, 1): "T",
			Vector2i(1, 1): "U", Vector2i(2, 1): "R", Vector2i(3, 1): "I", Vector2i(4, 1): "L"},
	},
	{
		"word": "BAUM",
		"path": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)],
		"others": {Vector2i(0, 0): "O", Vector2i(0, 1): "S", Vector2i(1, 1): "E",
			Vector2i(2, 1): "N", Vector2i(3, 1): "I", Vector2i(4, 1): "T"},
	},
]


static func count() -> int:
	return STEPS.size()


static func word(step: int) -> String:
	return STEPS[step]["word"]


static func path(step: int) -> Array[Vector2i]:
	var p: Array[Vector2i] = []
	p.assign(STEPS[step]["path"])
	return p


## Alle Steine der Runde: Zelle → Buchstabe (Zielwort und übrige).
static func tiles(step: int) -> Dictionary:
	var t: Dictionary = (STEPS[step]["others"] as Dictionary).duplicate()
	var p := path(step)
	var w := word(step)
	for i in p.size():
		t[p[i]] = w[i]
	return t
