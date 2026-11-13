extends GutTest


func _length_quest(length: int, count: int = 1, max_moves: int = 0) -> Quest:
	var q := Quest.new()
	q.kind = Quest.Kind.LENGTH
	q.word_length = length
	q.count = count
	q.max_moves = max_moves
	return q.start()


func _word_quest(target: String, max_moves: int = 0) -> Quest:
	var q := Quest.new()
	q.kind = Quest.Kind.SPECIFIC_WORD
	q.word_length = target.length()
	q.max_moves = max_moves
	return q.start(target)


# --- Wortlänge ---------------------------------------------------------------

func test_length_counts_at_least() -> void:
	var q := _length_quest(5)
	assert_false(q.matches("HAUS"), "zu kurz")
	assert_true(q.matches("HAUSE"), "genau 5")
	assert_true(q.matches("HIMMEL"), "länger zählt auch")


func test_single_word_completes() -> void:
	var q := _length_quest(3)
	assert_false(q.is_done())
	assert_true(q.register("AST"))
	assert_true(q.is_done())


func test_count_needs_several_words() -> void:
	var q := _length_quest(4, 3)
	q.register("HAUS")
	q.register("BAUM")
	assert_false(q.is_done())
	assert_eq(q.found, 2)
	q.register("MAUS")
	assert_true(q.is_done())


func test_non_matching_word_is_move_without_progress() -> void:
	var q := _length_quest(5)
	assert_false(q.register("AST"))
	assert_eq(q.moves, 1)
	assert_eq(q.found, 0)


# --- Bestimmtes Wort -------------------------------------------------------------

func test_specific_word_only_target_counts() -> void:
	var q := _word_quest("himmel")
	assert_eq(q.target, "HIMMEL")
	assert_false(q.matches("HAMMEL"))
	assert_false(q.matches("HIMMELS"), "längeres Wort zählt nicht")
	assert_true(q.matches("HIMMEL"))
	q.register("HIMMEL")
	assert_true(q.is_done())


func test_specific_word_without_target_never_matches() -> void:
	var q := Quest.new()
	q.kind = Quest.Kind.SPECIFIC_WORD
	assert_false(q.start().matches(""))


# --- Zuglimit ------------------------------------------------------------------

func test_no_limit_never_fails() -> void:
	var q := _length_quest(8)
	for i in 50:
		q.register("AST")
	assert_false(q.is_failed())
	assert_eq(q.moves_left(), -1)


func test_fails_when_moves_used_up() -> void:
	var q := _length_quest(4, 3, 4)
	q.register("HAUS")
	q.register("AST")
	q.register("BAUM")
	assert_eq(q.moves_left(), 1)
	assert_false(q.is_failed())
	q.register("OHR")
	assert_true(q.is_failed())
	assert_eq(q.moves_left(), 0)


func test_done_on_last_move_is_not_failed() -> void:
	var q := _length_quest(4, 2, 2)
	q.register("HAUS")
	q.register("BAUM")
	assert_true(q.is_done())
	assert_false(q.is_failed())


func test_nothing_changes_after_end() -> void:
	var q := _length_quest(3)
	q.register("AST")
	assert_false(q.register("OHR"))
	assert_eq(q.moves, 1)
	assert_eq(q.found, 1)


func test_miss_costs_move_only() -> void:
	var q := _length_quest(4, 1, 2)
	q.register_miss()
	assert_eq(q.moves, 1)
	assert_eq(q.found, 0)
	q.register_miss()
	assert_true(q.is_failed())
	q.register_miss()
	assert_eq(q.moves, 2, "nach dem Scheitern zählt nichts mehr")


# --- Vorlage ------------------------------------------------------------------

func test_start_copies_template() -> void:
	var template := Quest.new()
	template.word_length = 4
	template.count = 2
	template.reward = 250
	template.no_refill = true
	var a := template.start()
	a.register("HAUS")
	var b := template.start()
	assert_eq(b.found, 0, "neue Kopie beginnt bei 0")
	assert_eq(template.found, 0, "Vorlage bleibt unverändert")
	assert_eq(b.reward, 250)
	assert_true(b.no_refill)
