extends GutTest

var lang: LanguageData


func before_each() -> void:
	lang = load("res://data/languages/de/language.tres") as LanguageData


func _picker(seed_value: int) -> LetterPicker:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return LetterPicker.new(lang, rng)


func test_german_language_data_is_valid() -> void:
	assert_not_null(lang)
	assert_true(lang.is_valid())
	assert_eq(lang.alphabet.size(), 26)
	assert_eq(lang.code, "de")
	for l in lang.alphabet:
		assert_true(l.length() == 1 and l >= "A" and l <= "Z", "nur A–Z: %s" % l)


func test_picks_only_alphabet_letters() -> void:
	var p := _picker(1)
	for i in 500:
		assert_has(lang.alphabet, p.pick(PackedStringArray()))


func test_same_seed_same_letters() -> void:
	var a := _picker(7)
	var b := _picker(7)
	for i in 50:
		assert_eq(a.pick(PackedStringArray()), b.pick(PackedStringArray()))


func test_distribution_follows_weights() -> void:
	var p := _picker(3)
	var counts := {}
	var n := 20000
	for i in n:
		var l := p.pick(PackedStringArray())
		counts[l] = counts.get(l, 0) + 1
	# E ist mit Abstand am häufigsten (ca. 17 %), Q praktisch nie.
	assert_almost_eq(float(counts.get("E", 0)) / n, 0.174, 0.02)
	assert_lt(counts.get("Q", 0), 20)
	assert_gt(counts.get("E", 0), counts.get("N", 0))


func test_vowel_forced_when_board_has_too_few_vowels() -> void:
	var p := _picker(11)
	var board := PackedStringArray(["S", "T", "R", "N", "L", "K"])
	for i in 200:
		assert_true(lang.is_vowel(p.pick(board)))


func test_consonant_forced_when_board_has_too_many_vowels() -> void:
	var p := _picker(12)
	var board := PackedStringArray(["A", "E", "I", "O", "U", "E"])
	for i in 200:
		assert_false(lang.is_vowel(p.pick(board)))


func test_no_balancing_with_few_letters() -> void:
	var p := _picker(13)
	var board := PackedStringArray(["S", "T", "R"])  # unter balance_min_letters
	var consonants := 0
	for i in 500:
		if not lang.is_vowel(p.pick(board)):
			consonants += 1
	assert_gt(consonants, 0)


func test_balanced_board_gets_mixed_letters() -> void:
	var p := _picker(14)
	var board := PackedStringArray(["S", "T", "E", "R", "N", "A"])  # 33 % Vokale
	var vowels := 0
	for i in 1000:
		if lang.is_vowel(p.pick(board)):
			vowels += 1
	assert_between(vowels, 200, 600)
