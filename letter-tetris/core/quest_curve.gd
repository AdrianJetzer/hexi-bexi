class_name QuestCurve
extends Resource
## Auftrags-Kurve des Lauf-Modus (siehe spec/run-mode.md, „Kurve“).
## Feste Abschnitte für die ersten Levels; danach werden Aufträge gemischt und verschärft.

## Feste Abschnitte, aufsteigend nach Level.
@export var steps: Array[QuestCurveStep] = []

@export_group("Nach der festen Kurve")
## Karten ab dem Ende der Kurve werden aus den Abschnitten ab diesem Level gemischt.
@export var mix_from_level: int = 6
## Alle so vielen Levels kommt eine Verschärfung dazu (erste direkt nach der Kurve).
@export var tighten_every: int = 5
## Längere Wörter verlangt eine Verschärfung nie.
@export var max_word_length: int = 8
## Zusätzliche Münzen je Verschärfung.
@export var tighten_reward: int = 50
## Hilfe-Stufe nach der festen Kurve.
@export var endless_help_level: int = 5


## Abschnitt für ein Level oder null (nach der festen Kurve).
func step_for(level: int) -> QuestCurveStep:
	for s in steps:
		if s.covers(level):
			return s
	return null


## Letztes Level der festen Kurve.
func last_level() -> int:
	var last := 0
	for s in steps:
		last = maxi(last, s.last_level)
	return last


## Hilfe-Stufe für ein Level.
func help_level(level: int) -> int:
	var s := step_for(level)
	return s.help_level if s else endless_help_level


## Anzahl Verschärfungen in einem Level (0 innerhalb der festen Kurve).
## Beispiel mit Kurve bis 10 und tighten_every 5: Level 11–15 → 1, 16–20 → 2 …
func tightenings(level: int) -> int:
	var beyond := level - last_level()
	if beyond <= 0:
		return 0
	return (beyond - 1) / maxi(tighten_every, 1) + 1


## Abschnitte, aus denen nach der festen Kurve gemischt wird.
func mix_steps() -> Array[QuestCurveStep]:
	var result: Array[QuestCurveStep] = []
	for s in steps:
		if s.last_level >= mix_from_level:
			result.append(s)
	return result
