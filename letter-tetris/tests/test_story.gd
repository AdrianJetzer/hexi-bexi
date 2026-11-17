extends GutTest
## Story-Modus (spec/story-mode.md).

var balance: GameBalance
var curve: QuestCurve
var lang: LanguageData
var dict: WordDictionary
var run: RunSession


func before_each() -> void:
	balance = (load("res://data/balance.tres") as GameBalance).duplicate() as GameBalance
	balance.grid_rows = 6
	curve = load("res://data/quest_curve.tres") as QuestCurve
	lang = load("res://data/languages/de/language.tres") as LanguageData
	dict = WordDictionary.from_words(PackedStringArray(["HAUS", "STERN", "TISCH", "BIRNE", "APFEL"]))
	run = RunSession.new(balance, curve, lang, dict, 7)
	run.set_story(StoryChapter.by_id("fruechte"))
	watch_signals(run)
	run.start()


func test_chapters_have_enough_words_and_riddles() -> void:
	var chapters := StoryChapter.all()
	assert_gt(chapters.size(), 2)
	for ch in chapters:
		assert_gt(ch.words.size(), 49, ch.id)
		for w in ch.words:
			assert_between(w.length(), 3, 8, "%s: %s" % [ch.id, w])
			for i in w.length():
				assert_true(lang.alphabet.has(w[i]), "%s: Buchstabe in %s" % [ch.id, w])
			assert_ne(ch.riddle_for(w), "", "Rätsel für %s" % w)


func test_quest_is_one_row_with_hidden_theme_word() -> void:
	assert_ne(run.story_target, "")
	assert_eq(run.quest.rows, PackedInt32Array([run.story_target.length()]))
	var only := WordDictionary.from_words(PackedStringArray([run.story_target]))
	var found := WordFinder.new(only).find_paths(run.grid, 3, 8, func(_w: String) -> bool: return true, 1)
	assert_eq(found.size(), 1, "das gesuchte Wort liegt als Weg im Feld")


func test_only_theme_words_count() -> void:
	var n := run.story_target.length()
	run.grid.clear_all()
	# Ein echtes Wort gleicher Länge, das keine Frucht ist, zählt nicht.
	var other := "TISCH" if n == 5 else "HAUS"
	var cells: Array[Vector2i] = []
	for i in other.length():
		var c := Vector2i(0, i)
		run.grid.set_letter(c, other[i])
		cells.append(c)
	assert_false(run.submit_path(cells))
	# Eine andere Frucht passender Länge zählt.
	var fruit := ""
	for w in run.story.words:
		if w.length() == n and w != run.story_target:
			fruit = w
			break
	if fruit == "":
		fruit = run.story_target
	run.grid.clear_all()
	cells.clear()
	for i in fruit.length():
		var c := Vector2i(1, i)
		run.grid.set_letter(c, fruit[i])
		cells.append(c)
	assert_true(run.submit_path(cells), "andere Frucht gleicher Länge: " + fruit)


func test_riddle_help() -> void:
	assert_true(run.has_help("riddle"))
	assert_false(run.has_help("refill"), "kein Auffüllen im Story-Modus")
	assert_false(run.can_refill())
	run.coins = 0
	assert_true(run.can_riddle(), "gratis")
	var text := run.riddle()
	assert_eq(text, run.story.riddle_for(run.story_target))
	assert_ne(text, "")
	assert_eq(run.spent, 0, "zählt nicht als gekaufte Hilfe")
	assert_signal_emitted(run, "riddle_shown")
	assert_eq(run.riddle(), text, "beliebig oft")
	assert_eq(run.current_riddle(), text)
	assert_eq(run.stars(), 3)


func test_goal_completes_chapter_with_stars() -> void:
	for i in balance.goal_level - 1:
		run._complete_quest()
		if not run.offer.is_empty():
			run.choose(run.offer["options"][0])
	assert_eq(run.level(), balance.goal_level)
	assert_false(run.is_over)
	assert_eq(run.levels_until_offer(), 0, "nach Level 20 keine Auswahl mehr")
	run._complete_quest()
	assert_true(run.is_over)
	assert_signal_emitted_with_parameters(run, "goal_reached", [3])


func test_stars_by_spending() -> void:
	run.spent = 0
	assert_eq(run.stars(), 3)
	run.spent = 50
	assert_eq(run.stars(), 2)
	run.spent = balance.two_star_spend + 1
	assert_eq(run.stars(), 1)


func test_words_get_longer() -> void:
	var lengths := []
	for i in balance.goal_level - 1:
		lengths.append(run.story_target.length())
		run._complete_quest()
		if not run.offer.is_empty():
			run.choose(run.offer["options"][0])
	var early := 0.0
	var late := 0.0
	for i in 5:
		early += lengths[i]
		late += lengths[lengths.size() - 1 - i]
	assert_gt(late, early, "späte Wörter sind länger")


func test_fixed_helps_from_start() -> void:
	for id in ["riddle", "hint", "clear", "scan", "solve"]:
		assert_true(run.has_help(id), "Story hat %s von Anfang an" % id)
	for id in ["refill", "replace", "shuffle", "joker", "shorten", "swap", "split", "complete", "magnet", "strike"]:
		assert_false(run.has_help(id), "Story ohne %s" % id)


func test_no_draft_in_story() -> void:
	assert_eq(run.levels_until_offer(), 0, "kein Hinweis auf Power-ups")
	for i in 19:
		run._complete_quest()
		assert_true(run.offer.is_empty(), "keine Auswahl nach Level %d" % (i + 1))
	assert_eq(run.owned.size(), 4, "Hilfen bleiben gleich")


func _open_ids(stars: Callable) -> Array:
	var out := []
	for row in StoryChapter.BOARD_ROWS:
		for col in StoryChapter.BOARD_COLS:
			if StoryChapter.cell_open(Vector2i(col, row), stars):
				out.append(StoryChapter.slot(col, row)[0])
	out.sort()
	return out


func test_board_starts_with_animals_and_vegetables() -> void:
	var none := func(_id: String) -> int: return 0
	assert_eq(_open_ids(none), ["gemuese", "tiere"])


func test_board_vegetables_open_neighbors() -> void:
	var g := func(id: String) -> int: return 1 if id == "gemuese" else 0
	assert_eq(_open_ids(g), ["automarken", "fruechte", "gemuese", "kleidung", "tiere"])


func test_board_animals_open_neighbors() -> void:
	var t := func(id: String) -> int: return 2 if id == "tiere" else 0
	assert_eq(_open_ids(t), ["berufe", "fruechte", "gemuese", "tiere"])


func test_board_slots() -> void:
	assert_eq(StoryChapter.slot(0, 0), ["kleidung", "Kleidung"])
	assert_eq(StoryChapter.slot(3, 0), ["tiere", "Tiere"])
	assert_eq(StoryChapter.slot(3, 1)[0], "berufe")
	assert_eq(StoryChapter.slot(0, 4), [], "obere Reihen noch leer")
	assert_true(StoryChapter.playable("tiere"))
	for row in StoryChapter.BOARD:
		for c in row:
			assert_true(StoryChapter.playable(c[0]), "Wortliste für %s" % c[0])
	assert_eq(StoryChapter.all().size(), 8, "erste Version: 2 Reihen à 4 Kapitel")


func test_no_word_twice_in_a_run() -> void:
	var seen := {}
	for i in 20:
		assert_false(seen.has(run.story_target), "Ziel %s doppelt" % run.story_target)
		seen[run.story_target] = true
		run._complete_quest()


func test_found_word_does_not_count_again() -> void:
	# Ein anderes Themenwort passender Länge finden, dann darf es später nicht mehr zählen.
	var n := run.story_target.length()
	var other := ""
	for w in run.story.words:
		if w.length() == n and w != run.story_target:
			other = w
			break
	assert_ne(other, "")
	run._used_targets[other] = true
	run._complete_quest()
	assert_false(run._theme.contains(other), "gefundenes Wort zählt nicht mehr")
	assert_true(run._theme.contains(run.story_target), "neues Ziel zählt")


func test_test_mode_solve_is_free() -> void:
	assert_eq(run.price("solve"), balance.solve_price)
	run.free_solve = true
	assert_eq(run.price("solve"), 0, "Testmodus: Lösen gratis")
	run.coins = 0
	var before := run.spent
	assert_true(run.solve(), "auch ohne Münzen")
	assert_eq(run.spent, before, "nichts ausgegeben")
