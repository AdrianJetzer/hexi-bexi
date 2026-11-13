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
	assert_eq(curve.last_level(), 10)
	var expected := {
		1: [3], 2: [4], 3: [3, 3], 4: [3, 4], 5: [5],
		6: [4, 4], 7: [3, 3, 4], 8: [4, 5], 9: [6], 10: [3, 4, 5]}
	for level in expected:
		assert_eq(_gen().quest_for(level).rows, PackedInt32Array(expected[level]), "Level %d" % level)


func test_reward_grows_with_level() -> void:
	assert_eq(_gen().quest_for(1).reward, 110)
	assert_eq(_gen().quest_for(10).reward, 200)
	assert_eq(_gen().quest_for(20).reward, 300)


func test_help_level_follows_curve() -> void:
	var expected := {1: 1, 2: 1, 3: 2, 4: 2, 5: 3, 7: 3, 8: 4, 10: 4, 11: 5, 40: 5}
	for level in expected:
		assert_eq(curve.help_level(level), expected[level], "Level %d" % level)


func test_budget_after_curve() -> void:
	var expected := {10: 0, 11: 12, 15: 12, 16: 13, 21: 14, 200: 24}
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
		seen[str(g.quest_for(11).rows)] = true
	assert_gt(seen.size(), 5, "abwechslungsreich")


func test_quest_for_returns_fresh_copies() -> void:
	var q := _gen().quest_for(3)
	q.rows[0] = 9
	assert_eq(_gen().quest_for(3).rows[0], 3, "Kurve unverändert")
