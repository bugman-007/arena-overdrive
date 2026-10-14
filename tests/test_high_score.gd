extends GutTest

const PATH := "user://test_highscore.cfg"
var store: HighScoreStore


func before_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	store = HighScoreStore.new(PATH)


func after_all() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func test_missing_file_returns_zero() -> void:
	assert_eq(store.load_high_score(), 0)


func test_save_then_load_roundtrip() -> void:
	assert_eq(store.save_high_score(1234), OK)
	assert_eq(HighScoreStore.new(PATH).load_high_score(), 1234)


func test_submit_only_saves_new_records() -> void:
	assert_true(store.submit(500))
	assert_false(store.submit(300))
	assert_eq(store.load_high_score(), 500)
	assert_true(store.submit(900))
	assert_eq(store.load_high_score(), 900)


func test_corrupt_value_falls_back_to_zero() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(HighScoreStore.SECTION, HighScoreStore.KEY, "not a number")
	cfg.save(PATH)
	assert_eq(store.load_high_score(), 0)
