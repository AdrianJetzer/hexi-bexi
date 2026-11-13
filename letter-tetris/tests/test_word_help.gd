extends GutTest

var lang: LanguageData
var balance: GameBalance


func before_each() -> void:
	lang = load("res://data/languages/de/language.tres") as LanguageData
	balance = load("res://data/balance.tres") as GameBalance


func _level(strength: float, min_words: int) -> DifficultyLevel:
	var l := DifficultyLevel.new()
	l.help_strength = strength
	l.min_words = min_words
	return l


func test_five_levels_from_spec() -> void:
	assert_eq(balance.difficulty_levels.size(), 5)
	assert_eq(balance.default_difficulty, 1)
	var names := ["Sehr leicht", "Leicht", "Mittel", "Schwer", "Profi"]
	var mins := [8, 5, 3, 1, 0]
	for i in 5:
		var d := balance.difficulty(i + 1)
		assert_eq(d.display_name, names[i])
		assert_eq(d.min_words, mins[i])
	assert_eq(balance.difficulty(5).help_strength, 0.0)
	assert_gt(balance.difficulty(1).help_strength, balance.difficulty(4).help_strength)
	assert_eq(balance.difficulty(99), balance.difficulty(5), "wird begrenzt")


func test_forced_help_picks_the_only_useful_letter() -> void:
	var dict := WordDictionary.from_words(PackedStringArray(["TEE", "TEER"]))
	var finder := WordFinder.new(dict)
	for seed_value in 30:
		var grid := HexGrid.new()
		grid.set_letter(Vector2i(0, 0), "T")
		grid.set_letter(Vector2i(0, 1), "E")
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var picker := LetterPicker.new(lang, rng)
		assert_eq(picker.pick_for_cell(grid, Vector2i(0, 2), finder, _level(1.0, 5)), "E")


func test_no_help_behaves_like_plain_pick() -> void:
	var dict := WordDictionary.from_words(PackedStringArray(["TEE"]))
	var finder := WordFinder.new(dict)
	var seen := {}
	for seed_value in 60:
		var grid := HexGrid.new()
		grid.set_letter(Vector2i(0, 0), "T")
		grid.set_letter(Vector2i(0, 1), "E")
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		seen[LetterPicker.new(lang, rng).pick_for_cell(grid, Vector2i(0, 2), finder, _level(0.0, 0))] = true
	assert_gt(seen.size(), 5, "viele verschiedene Buchstaben")


func test_counts_are_reported() -> void:
	var dict := WordDictionary.from_words(PackedStringArray(["TEE", "TEN"]))
	var grid := HexGrid.new()
	grid.set_letter(Vector2i(0, 0), "T")
	grid.set_letter(Vector2i(0, 1), "E")
	var picker := LetterPicker.new(lang)
	picker.pick_for_cell(grid, Vector2i(0, 2), WordFinder.new(dict), _level(1.0, 0))
	assert_eq(picker.last_counts["E"], 1)
	assert_eq(picker.last_counts["N"], 1)
	assert_eq(picker.last_counts["X"], 0)


func test_easy_level_yields_more_words_than_profi() -> void:
	var words := WordDictionary.from_file(lang.words_path)
	var common := WordDictionary.from_file(lang.common_words_path)
	var counter := WordFinder.new(common, 3, 6)
	var totals := {1: 0, 5: 0}
	for level in totals:
		for seed_value in range(1, 4):
			var s := GameSession.new(balance, lang, words, seed_value, common, level)
			s.start()
			for i in 5:
				s.request_more_letters()
			totals[level] += counter.words_on_board(s.grid).size()
	gut.p("Wörter im Feld (3 Runden, je 30 Buchstaben): Stufe 1 = %d, Stufe 5 = %d" % [totals[1], totals[5]])
	assert_gt(totals[1], totals[5])
