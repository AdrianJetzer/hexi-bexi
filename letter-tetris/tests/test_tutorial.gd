extends GutTest

var run: RunSession


func before_each() -> void:
	var balance := (load("res://data/balance.tres") as GameBalance).duplicate() as GameBalance
	var curve := load("res://data/quest_curve.tres") as QuestCurve
	var lang := load("res://data/languages/de/language.tres") as LanguageData
	var dict := WordDictionary.from_words(PackedStringArray(["DAS", "BAUM", "TUR", "SAD"]))
	run = RunSession.new(balance, curve, lang, dict, 1)
	run.set_tutorial()
	watch_signals(run)
	run.start()


func test_paths_are_valid_chains_on_the_board() -> void:
	for step in Tutorial.count():
		var p := Tutorial.path(step)
		assert_eq(p.size(), Tutorial.word(step).length())
		for i in range(1, p.size()):
			assert_true(run.grid.are_neighbors(p[i - 1], p[i]), "Runde %d: Nachbarn" % step)


func test_first_round_board_and_quest() -> void:
	assert_eq(run.quest.rows, PackedInt32Array([3]))
	assert_eq(run.word_for(run.tutorial_path()), "DAS")
	assert_eq(run.coins, 0)
	assert_eq(run.owned.size(), 0, "keine Hilfen im Tutorial")


func test_only_target_word_counts() -> void:
	var p := run.tutorial_path()
	var reversed: Array[Vector2i] = [p[2], p[1], p[0]]
	assert_false(run.submit_path(reversed), "SAD ist zwar im Wörterbuch, zählt aber nicht")
	assert_true(run.submit_path(p))


func test_two_rounds_then_finished() -> void:
	assert_true(run.submit_path(run.tutorial_path()))
	assert_signal_not_emitted(run, "tutorial_finished")
	assert_eq(run.tutorial_step(), 1)
	assert_eq(run.quest.rows, PackedInt32Array([4]))
	assert_eq(run.word_for(run.tutorial_path()), "BAUM")
	assert_true(run.submit_path(run.tutorial_path()))
	assert_signal_emitted(run, "tutorial_finished")
	assert_true(run.is_over)
	assert_eq(run.tutorial_path().size(), 0)


func test_no_refill_in_tutorial() -> void:
	var tiles := run.grid.size() - run.grid.free_count()
	assert_true(run.submit_path(run.tutorial_path()))
	assert_eq(run.grid.size() - run.grid.free_count(), Tutorial.tiles(1).size(),
			"zweite Runde: genau ihr festes Feld, nichts nachgefüllt")
	assert_eq(tiles, Tutorial.tiles(0).size())
