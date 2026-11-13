class_name QuestGenerator
extends RefCounted
## Bietet pro Level zwei Auftragskarten an (sicher, riskant), siehe spec/run-mode.md.
## Die Karten sind Vorlagen; der Lauf startet die gewählte mit Quest.start().

var curve: QuestCurve
var _rng: RandomNumberGenerator


func _init(p_curve: QuestCurve, rng: RandomNumberGenerator = null) -> void:
	curve = p_curve
	_rng = rng if rng else RandomNumberGenerator.new()


## [sichere Karte, riskante Karte] für ein Level. Leer, wenn die Kurve leer ist.
func offer(level: int) -> Array[Quest]:
	var result: Array[Quest] = []
	var step := curve.step_for(level)
	if step:
		result.append(step.safe.duplicate() as Quest)
		result.append(step.risky.duplicate() as Quest)
		return result
	var pool := curve.mix_steps()
	if pool.is_empty():
		return result
	var safe := pool[_rng.randi_range(0, pool.size() - 1)].safe.duplicate() as Quest
	var risky := pool[_rng.randi_range(0, pool.size() - 1)].risky.duplicate() as Quest
	var n := curve.tightenings(level)
	_tighten(safe, n)
	_tighten(risky, n)
	result.append(safe)
	result.append(risky)
	return result


## n Verschärfungen reihum: Länge +1, Anzahl +1, Zuglimit −1.
## Passt eine Verschärfung nicht zum Auftrag, entfällt sie (die Belohnung steigt trotzdem).
func _tighten(q: Quest, n: int) -> void:
	for i in n:
		match i % 3:
			0:
				q.word_length = mini(q.word_length + 1, curve.max_word_length)
			1:
				if q.kind == Quest.Kind.LENGTH:
					q.count += 1
			2:
				if q.max_moves > 0:
					q.max_moves -= 1
		# Mindestens so viele Züge wie verlangte Wörter.
		if q.max_moves > 0:
			q.max_moves = maxi(q.max_moves, q.count)
		q.reward += curve.tighten_reward
