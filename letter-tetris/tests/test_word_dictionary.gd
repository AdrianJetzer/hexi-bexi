extends GutTest

## Erzeugt mit: python3 -I tools/dictionary/pack_words.py tests/data/words_sample.txt tests/data/words_sample.bin
const SAMPLE_TXT := "res://tests/data/words_sample.txt"
const SAMPLE_BIN := "res://tests/data/words_sample.bin"

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
	for w in ["STER", "STERNEN", "HAUSE", "XYZ", "", "A", "SEHRSEHRLANGESWORT"]:
		assert_false(dict.contains(w), w)


func test_duplicates_removed() -> void:
	assert_eq(dict.size(), 5)


func test_boundaries_of_each_length_group() -> void:
	var d := WordDictionary.from_words(PackedStringArray(["AAL", "MAL", "ZOO", "AXT", "ZZZZ", "AAAA"]))
	for w in ["AAL", "ZOO", "AXT", "MAL", "AAAA", "ZZZZ"]:
		assert_true(d.contains(w), w)
	for w in ["AAK", "ZOP", "AAAB", "ZZZY"]:
		assert_false(d.contains(w), w)


func test_many_words_all_found() -> void:
	var words := PackedStringArray()
	for a in ["A", "E", "I", "O", "U"]:
		for b in ["B", "D", "K", "M", "S", "T"]:
			for c in ["A", "N", "R", "X"]:
				words.append(a + b + c)
				words.append(b + a + c + a)
	var d := WordDictionary.from_words(words)
	for w in words:
		assert_true(d.contains(w), w)
	assert_false(d.contains("QQQ"))


func test_load_packed_file() -> void:
	var d := WordDictionary.from_file(SAMPLE_BIN)
	assert_not_null(d)
	assert_eq(d.size(), 12)
	assert_true(d.contains("STERN"))
	assert_true(d.contains("KFZ"))
	assert_false(d.contains("NICHTDA"))


func test_python_and_gdscript_pack_identically() -> void:
	var lines := FileAccess.get_file_as_string(SAMPLE_TXT).split("\n", false)
	var built := WordDictionary.from_words(lines).to_bytes()
	assert_eq(built, FileAccess.get_file_as_bytes(SAMPLE_BIN))


func test_has_prefix() -> void:
	for p in ["S", "ST", "STE", "STER", "STERN", "STERNE", "ber", "U", "HAU"]:
		assert_true(dict.has_prefix(p), p)
	for p in ["X", "STERNEN", "SZ", "HAUSE", "BERLINER", "USAA"]:
		assert_false(dict.has_prefix(p), p)


func test_has_prefix_matches_brute_force() -> void:
	var words := PackedStringArray(["AAL", "AALE", "ABER", "ABT", "BAD", "BADEN", "ZOO", "ZOOS", "ZUG"])
	var d := WordDictionary.from_words(words)
	for a in ["A", "B", "Z", "Q"]:
		for b in ["", "A", "B", "O", "U", "D"]:
			for c in ["", "L", "E", "O", "T", "G"]:
				var p: String = a + b + c
				var expected := false
				for w in words:
					if w.begins_with(p):
						expected = true
				assert_eq(d.has_prefix(p), expected, p)


func test_real_german_dictionary() -> void:
	var lang := load("res://data/languages/de/language.tres") as LanguageData
	var d := WordDictionary.from_file(lang.words_path)
	assert_not_null(d)
	assert_gt(d.size(), 500000)
	for w in ["STERN", "STERNE", "RANNTE", "GROSSEN", "STRASSE", "MUSS", "DASS", "BERLIN", "ANNA", "USA", "KFZ", "HAUS"]:
		assert_true(d.contains(w), w)
	for w in ["XQZT", "STERNX", "QQQ", "AB"]:
		assert_false(d.contains(w), w)


func test_missing_file_returns_null() -> void:
	assert_null(WordDictionary.from_file("res://tests/data/gibt_es_nicht.bin"))
	assert_push_error("Wortliste nicht gefunden")


func test_wrong_format_returns_null() -> void:
	assert_null(WordDictionary.from_bytes("HALLO WELT".to_ascii_buffer()))
	assert_push_error("kein gültiges Format")


func test_truncated_data_returns_null() -> void:
	var bytes := FileAccess.get_file_as_bytes(SAMPLE_BIN)
	assert_null(WordDictionary.from_bytes(bytes.slice(0, bytes.size() - 3)))
	assert_push_error("beschädigt")
