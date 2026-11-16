class_name QuestGenerator
extends RefCounted
## Erzeugt den Auftrag für ein Level (siehe spec/run-mode.md): aus der festen Kurve,
## danach durch zufälliges Aufteilen des Block-Budgets auf 1 bis 3 Zeilen; Atempausen
## (jedes 5. Level ab 11) haben nur eine kurze Zeile.
## Der Lauf startet den Auftrag mit Quest.start().

var curve: QuestCurve
var _rng: RandomNumberGenerator


func _init(p_curve: QuestCurve, rng: RandomNumberGenerator = null) -> void:
	curve = p_curve
	_rng = rng if rng else RandomNumberGenerator.new()


func quest_for(level: int) -> Quest:
	var q := Quest.new()
	if curve.is_break(level):
		# Atempause: eine kurze Zeile
		q.rows = PackedInt32Array([curve.break_rows[_rng.randi_range(0, curve.break_rows.size() - 1)]])
	else:
		var fixed := curve.rows_for(level)
		q.rows = fixed.duplicate() if not fixed.is_empty() else split_budget(curve.budget(level))
	q.reward = curve.reward(level)
	return q


## Budget zufällig auf Zeilen verteilen: 1 bis rows_max Zeilen, je row_min bis row_max Blöcke.
func split_budget(total: int) -> PackedInt32Array:
	var lo := maxi(1, ceili(float(total) / curve.row_max))
	var hi := mini(curve.rows_max, total / curve.row_min)
	if hi < lo:
		# Budget passt nicht in die Grenzen: möglichst nah dran.
		hi = lo
	var count := _rng.randi_range(lo, hi)
	var rows := PackedInt32Array()
	rows.resize(count)
	rows.fill(curve.row_min)
	var rest := total - count * curve.row_min
	while rest > 0:
		var open: Array[int] = []
		for i in count:
			if rows[i] < curve.row_max:
				open.append(i)
		if open.is_empty():
			break
		var i: int = open[_rng.randi_range(0, open.size() - 1)]
		rows[i] += 1
		rest -= 1
	return rows
