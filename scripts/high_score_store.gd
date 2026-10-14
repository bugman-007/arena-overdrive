class_name HighScoreStore
extends RefCounted
## Persists the best score to user:// with ConfigFile.

const SECTION := "scores"
const KEY := "high_score"

var path: String


func _init(save_path: String = "user://highscore.cfg") -> void:
	path = save_path


func load_high_score() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return 0
	var value: Variant = cfg.get_value(SECTION, KEY, 0)
	return maxi(0, int(value)) if (value is int or value is float) else 0


func save_high_score(value: int) -> Error:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, KEY, value)
	return cfg.save(path)


## Saves only if `score` beats the stored value. Returns true if it was a new record.
func submit(score: int) -> bool:
	if score > load_high_score():
		save_high_score(score)
		return true
	return false
