extends GutTest
## Freischalten der Modi (spec/screens.md v4.45).

const SaveDataScript := preload("res://autoload/save_data.gd")


func _stars(table: Dictionary) -> Callable:
	return func(id: String) -> int: return int(table.get(id, 0))


func test_easy_and_story_always_open() -> void:
	var none := _stars({})
	assert_true(SaveDataScript.unlocked("de_easy", none))
	assert_true(SaveDataScript.unlocked("story", none))


func test_medium_and_hard_locked_at_start() -> void:
	var none := _stars({})
	assert_false(SaveDataScript.unlocked("de_medium", none))
	assert_false(SaveDataScript.unlocked("de_hard", none))


func test_one_star_in_easy_opens_medium_only() -> void:
	var s := _stars({"de_easy": 1})
	assert_true(SaveDataScript.unlocked("de_medium", s))
	assert_false(SaveDataScript.unlocked("de_hard", s))


func test_one_star_in_medium_opens_hard() -> void:
	assert_true(SaveDataScript.unlocked("de_hard", _stars({"de_easy": 3, "de_medium": 1})))


func test_requirement_names_previous_mode() -> void:
	assert_eq(SaveDataScript.unlock_requirement("de_medium"), "de_easy")
	assert_eq(SaveDataScript.unlock_requirement("de_hard"), "de_medium")
	assert_eq(SaveDataScript.unlock_requirement("de_easy"), "")
