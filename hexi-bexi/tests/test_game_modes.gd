extends GutTest
## Spielmodi einfach / mittel / schwierig (spec/run-mode.md, „Modi“).


func _mode(id: String) -> GameMode:
	return load("res://data/modes/%s.tres" % id) as GameMode


func test_three_modes_load() -> void:
	for id in ["de_easy", "de_medium", "de_hard"]:
		var m := _mode(id)
		assert_not_null(m, id)
		assert_eq(m.id, id)
		assert_not_null(m.curve, id)
		assert_not_null(WordDictionary.from_file(m.valid_words_path()), id)
		assert_not_null(WordDictionary.from_file(m.suggestion_words_path()), id)
		assert_eq(m.curve.reward(7), 100, "100 Münzen in allen Modi")


func test_row_lengths_per_mode() -> void:
	var expected := {"de_easy": 5, "de_medium": 6, "de_hard": 8}
	for id in expected:
		var curve := _mode(id).curve
		assert_eq(curve.row_max, expected[id], id)
		var gen := QuestGenerator.new(curve)
		for level in range(1, 120):
			for r in gen.quest_for(level).rows:
				assert_true(r <= expected[id], "%s Level %d: Zeile %d" % [id, level, r])


func test_easy_mode_uses_kids_words_only() -> void:
	var m := _mode("de_easy")
	var kids := WordDictionary.from_file(m.suggestion_words_path())
	var valid := WordDictionary.from_file(m.valid_words_path())
	assert_between(kids.size(), 2500, 3500)
	assert_between(valid.size(), kids.size(), kids.size() + 1500)
	for w in ["HAUS", "KATZE", "HUND", "BAUM", "BALL"]:
		assert_true(kids.contains(w), w)
		assert_true(valid.contains(w), w)
	# Kleine Wörter zählen, werden aber nicht vorgeschlagen.
	for w in ["ICH", "SIE", "DER", "UND", "MIT", "IST"]:
		assert_true(valid.contains(w), w)
	for w in ["ICH", "SIE", "DER", "WIR"]:
		assert_false(kids.contains(w), "kein Vorschlag: " + w)
	for w in ["THEE", "ABIRRTE", "ANUS", "STERNE"]:
		assert_false(valid.contains(w), w)


func test_medium_and_hard_accept_all_words() -> void:
	var lang := load("res://data/languages/de/language.tres") as LanguageData
	for id in ["de_medium", "de_hard"]:
		assert_eq(_mode(id).valid_words_path(), lang.words_path, id)


func test_easy_help_always_strong() -> void:
	var curve := _mode("de_easy").curve
	for level in [1, 10, 20, 50, 200]:
		assert_eq(curve.help_level(level), 1, "Level %d" % level)
