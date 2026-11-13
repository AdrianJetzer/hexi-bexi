extends GutTest

var curve: QuestCurve


func before_each() -> void:
	curve = load("res://data/quest_curve.tres") as QuestCurve


func _gen(seed_value: int = 1) -> QuestGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return QuestGenerator.new(curve, rng)


# --- Kurve aus der Spec ----------------------------------------------------------

func test_curve_file_loads() -> void:
	assert_not_null(curve)
	assert_eq(curve.last_level(), 10)


func test_level_1_cards_from_spec() -> void:
	var cards := _gen().offer(1)
	assert_eq(cards.size(), 2)
	assert_eq(cards[0].kind, Quest.Kind.LENGTH)
	assert_eq(cards[0].word_length, 3)
	assert_eq(cards[0].reward, 100)
	assert_eq(cards[1].word_length, 4)
	assert_eq(cards[1].reward, 150)


func test_specific_word_is_safe_card() -> void:
	var expected := {4: [4, 100], 6: [5, 150], 7: [5, 150], 8: [6, 150], 10: [6, 150]}
	for level in expected:
		var cards := _gen().offer(level)
		assert_eq(cards[0].kind, Quest.Kind.SPECIFIC_WORD, "Level %d sicher" % level)
		assert_eq(cards[0].word_length, expected[level][0])
		assert_eq(cards[0].reward, expected[level][1])
		assert_eq(cards[1].kind, Quest.Kind.LENGTH, "Level %d riskant" % level)


func test_level_4_risky_is_longer_word() -> void:
	var risky := _gen().offer(4)[1]
	assert_eq(risky.word_length, 5)
	assert_eq(risky.reward, 200)


func test_level_5_safe_without_refill() -> void:
	var safe := _gen().offer(5)[0]
	assert_true(safe.no_refill)
	assert_eq(safe.word_length, 5)


func test_levels_6_and_7_risky_move_limited_card() -> void:
	for level in [6, 7]:
		var risky := _gen().offer(level)[1]
		assert_eq(risky.word_length, 4)
		assert_eq(risky.count, 3)
		assert_eq(risky.max_moves, 4)
		assert_eq(risky.reward, 250)


func test_help_level_follows_curve() -> void:
	var expected := {1: 1, 2: 1, 3: 2, 4: 2, 5: 3, 6: 3, 7: 3, 8: 4, 10: 4, 11: 5, 40: 5}
	for level in expected:
		assert_eq(curve.help_level(level), expected[level], "Level %d" % level)


func test_offer_returns_copies() -> void:
	var cards := _gen().offer(1)
	cards[0].word_length = 99
	assert_eq(_gen().offer(1)[0].word_length, 3, "Vorlage in der Kurve unverändert")


# --- Ab Level 11 -----------------------------------------------------------------

func test_tightenings_every_five_levels() -> void:
	var expected := {10: 0, 11: 1, 15: 1, 16: 2, 20: 2, 21: 3, 26: 4}
	for level in expected:
		assert_eq(curve.tightenings(level), expected[level], "Level %d" % level)


func test_mixed_cards_come_from_levels_6_to_10() -> void:
	var safe_lengths := {}
	var g := _gen(42)
	for i in 60:
		var cards := g.offer(11)
		assert_eq(cards.size(), 2)
		# Eine Verschärfung: Länge +1 gegenüber der Vorlage.
		safe_lengths[cards[0].word_length] = true
		assert_true(cards[0].reward >= 200, "Belohnung +50")
	# Sichere Vorlagen aus Level 6–7 (Länge 5) und 8–10 (Länge 6), jeweils +1.
	assert_eq(safe_lengths.keys().size(), 2)
	assert_true(safe_lengths.has(6))
	assert_true(safe_lengths.has(7))


func test_tightening_rotates_length_count_moves() -> void:
	var g := _gen()
	var q := Quest.new()
	q.word_length = 4
	q.count = 3
	q.max_moves = 4
	q.reward = 150
	g._tighten(q, 3)
	assert_eq(q.word_length, 5, "Länge +1")
	assert_eq(q.count, 4, "Anzahl +1")
	assert_eq(q.max_moves, 4, "Zuglimit −1, aber nie unter der Anzahl")
	assert_eq(q.reward, 300, "3 × 50")


func test_tightening_caps_length() -> void:
	var g := _gen()
	var q := Quest.new()
	q.word_length = 8
	g._tighten(q, 4)
	assert_eq(q.word_length, 8)


func test_tightening_specific_word_skips_count() -> void:
	var g := _gen()
	var q := Quest.new()
	q.kind = Quest.Kind.SPECIFIC_WORD
	q.word_length = 6
	g._tighten(q, 2)
	assert_eq(q.word_length, 7)
	assert_eq(q.count, 1)


func test_empty_curve_offers_nothing() -> void:
	var g := QuestGenerator.new(QuestCurve.new())
	assert_eq(g.offer(1).size(), 0)
	assert_eq(g.offer(20).size(), 0)
