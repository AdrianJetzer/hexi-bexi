extends GutTest

const SAMPLE_PATH := "res://tests/data/words_sample.txt"

var dict: WordDictionary


func before_each() -> void:
	dict = WordDictionary.from_words(PackedStringArray(["stern", "STERNE", "Haus", "USA", "berlin", "Stern"]))


func test_contains_known_words() -> void:
	for w in ["STERN", "STERNE", "HAUS", "USA", "BERLIN"]:
		assert_true(dict.contains(w), w)


func test_case_insensitive() -> void:
	assert_true(dict.contains("stern"))
	assert_true(dict.contains("Berlin"))


func test_unknown_words() -> void:
	for w in ["STER", "STERNEN", "HAUSE", "XYZ", ""]:
		assert_false(dict.contains(w), w)


func test_duplicates_removed() -> void:
	assert_eq(dict.size(), 5)


func test_boundaries_of_sorted_list() -> void:
	var d := WordDictionary.from_words(PackedStringArray(["AAL", "MOND", "ZOO"]))
	assert_true(d.contains("AAL"))
	assert_true(d.contains("ZOO"))
	assert_false(d.contains("AA"))
	assert_false(d.contains("ZOOS"))


func test_load_from_file() -> void:
	var d := WordDictionary.from_file(SAMPLE_PATH)
	assert_not_null(d)
	assert_eq(d.size(), 12)
	assert_true(d.contains("STERN"))
	assert_true(d.contains("KFZ"))
	assert_false(d.contains("NICHTDA"))


func test_missing_file_returns_null() -> void:
	assert_null(WordDictionary.from_file("res://tests/data/gibt_es_nicht.txt"))
	assert_push_error("Wortliste nicht gefunden")
