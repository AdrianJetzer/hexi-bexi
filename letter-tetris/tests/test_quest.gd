extends GutTest


func _quest(rows: Array) -> Quest:
	var q := Quest.new()
	q.rows = PackedInt32Array(rows)
	return q.start()


func test_word_must_match_length_exactly() -> void:
	var q := _quest([4])
	assert_false(q.matches("AST"), "zu kurz")
	assert_true(q.matches("HAUS"))
	assert_false(q.matches("HAUSE"), "zu lang")


func test_word_fills_topmost_free_row_of_its_length() -> void:
	var q := _quest([3, 4, 3])
	assert_eq(q.free_row_for("AST"), 0)
	q.fill(0, "ast")
	assert_eq(q.filled[0], "AST")
	assert_eq(q.free_row_for("OHR"), 2, "nächste freie 3er-Zeile")
	assert_eq(q.free_row_for("HAUS"), 1)
	assert_eq(q.free_row_for("STERN"), -1, "keine 5er-Zeile")


func test_done_when_all_rows_filled() -> void:
	var q := _quest([3, 4])
	q.fill(q.free_row_for("AST"), "AST")
	assert_false(q.is_done())
	assert_false(q.matches("OHR"), "3er-Zeile schon voll")
	q.fill(q.free_row_for("HAUS"), "HAUS")
	assert_true(q.is_done())


func test_free_lengths() -> void:
	var q := _quest([4, 3, 4, 5])
	assert_eq(q.free_lengths(), PackedInt32Array([3, 4, 5]))
	q.fill(1, "AST")
	assert_eq(q.free_lengths(), PackedInt32Array([4, 5]))
	assert_eq(q.block_count(), 16)


func test_start_copies_template() -> void:
	var template := Quest.new()
	template.rows = PackedInt32Array([3, 4])
	template.reward = 150
	var a := template.start()
	a.fill(0, "AST")
	var b := template.start()
	assert_eq(b.filled[0], "", "neue Kopie ist leer")
	assert_eq(b.reward, 150)
	a.rows[0] = 9
	assert_eq(template.rows[0], 3, "Vorlage bleibt unverändert")
