extends GutTest

var curve: QuestCurve


func before_each() -> void:
	curve = load("res://data/quest_curve.tres") as QuestCurve


func _gen(seed_value: int = 1) -> QuestGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return QuestGenerator.new(curve, rng)


func test_curve_from_spec() -> void:
	assert_not_null(curve)
	assert_eq(curve.last_level(), 20)
	# Schwer: jedes Level ein eigener Auftrag, bis 4 + 8 in Level 20 (run-mode.md v3.40).
	var expected := {
		1: [3], 2: [4], 3: [3, 3], 4: [5], 5: [3, 4], 6: [6], 7: [4, 4], 8: [3, 5],
		9: [3, 3, 3], 10: [7], 11: [4, 5], 12: [3, 3, 4], 13: [3, 6], 14: [5, 5],
		15: [8], 16: [4, 6], 17: [3, 4, 4], 18: [5, 6], 19: [4, 7], 20: [4, 8]}
	for level in expected:
		assert_eq(_gen().quest_for(level).rows, PackedInt32Array(expected[level]), "Level %d" % level)


func test_hard_has_no_breaks() -> void:
	for level in [5, 10, 15, 20, 25, 30]:
		assert_false(curve.is_break(level), "Level %d" % level)


func test_breaks_every_fifth_level_from_eleven() -> void:
	curve = load("res://data/quest_curve_medium.tres") as QuestCurve
	var g := _gen(3)
	for level in [15, 20]:
		assert_true(curve.is_break(level), "Level %d" % level)
		var rows := g.quest_for(level).rows
		assert_eq(rows.size(), 1, "eine Zeile in Level %d" % level)
		assert_between(rows[0], 3, 4)
	for level in [5, 10, 11, 16]:
		assert_false(curve.is_break(level), "Level %d" % level)


func test_reward_fixed() -> void:
	for level in [1, 10, 20, 50]:
		assert_eq(_gen().quest_for(level).reward, 100, "fest 100 je Level")


func test_help_level_follows_curve() -> void:
	var expected := {1: 1, 4: 1, 5: 2, 8: 2, 9: 3, 14: 3, 15: 4, 20: 4, 21: 5, 80: 5}
	for level in expected:
		assert_eq(curve.help_level(level), expected[level], "Level %d" % level)


func test_budget_after_curve() -> void:
	var expected := {20: 0, 21: 12, 30: 12, 31: 13, 41: 14, 500: 24}
	for level in expected:
		assert_eq(curve.budget(level), expected[level], "Level %d" % level)


func test_budget_split_respects_limits() -> void:
	var g := _gen(42)
	var counts := {}
	for budget in range(12, 25):
		for i in 30:
			var rows := g.split_budget(budget)
			var total := 0
			for r in rows:
				assert_between(r, 3, 8)
				total += r
			assert_between(rows.size(), 1, 3)
			assert_eq(total, budget)
			counts[rows.size()] = true
	assert_true(counts.has(2) and counts.has(3), "verschiedene Zeilenzahlen")


func test_endless_quests_vary() -> void:
	var g := _gen(7)
	var seen := {}
	for i in 30:
		seen[str(g.quest_for(21).rows)] = true
	assert_gt(seen.size(), 5, "abwechslungsreich")


func test_quest_for_returns_fresh_copies() -> void:
	var q := _gen().quest_for(5)
	q.rows[0] = 9
	assert_eq(_gen().quest_for(5).rows[0], 3, "Kurve unverändert")
