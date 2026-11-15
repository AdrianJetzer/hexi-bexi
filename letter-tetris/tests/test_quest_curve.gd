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
	# Jeder feste Auftrag zweimal; Level 15 und 20 sind Atempausen (eigener Test).
	var expected := {
		1: [3], 2: [3], 3: [4], 4: [4], 5: [3, 3], 6: [3, 3], 7: [3, 4], 8: [3, 4],
		9: [5], 10: [5], 11: [4, 4], 12: [4, 4], 13: [3, 3, 4], 14: [3, 3, 4],
		16: [4, 5], 17: [6], 18: [6], 19: [3, 4, 5]}
	for level in expected:
		assert_eq(_gen().quest_for(level).rows, PackedInt32Array(expected[level]), "Level %d" % level)


func test_breaks_every_fifth_level_from_eleven() -> void:
	var g := _gen(3)
	for level in [15, 20, 25, 30, 100]:
		assert_true(curve.is_break(level), "Level %d" % level)
		var rows := g.quest_for(level).rows
		assert_eq(rows.size(), 1, "eine Zeile in Level %d" % level)
		assert_between(rows[0], 3, 4)
	for level in [5, 10, 11, 21, 24]:
		assert_false(curve.is_break(level), "Level %d" % level)


func test_reward_fixed() -> void:
	for level in [1, 10, 20, 50]:
		assert_eq(_gen().quest_for(level).reward, 50, "fest 50 je Level")


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
