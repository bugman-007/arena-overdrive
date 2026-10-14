class_name ScoreManager
extends RefCounted
## Tracks score with a kill-combo multiplier.

signal score_changed(score: int)
signal combo_changed(multiplier: int)

const COMBO_WINDOW := 2.0
const MAX_MULTIPLIER := 4

var score: int = 0
var multiplier: int = 1
var _combo_timer: float = 0.0


func add_kill(base_points: int) -> int:
	var gained := base_points * multiplier
	score += gained
	_combo_timer = COMBO_WINDOW
	if multiplier < MAX_MULTIPLIER:
		multiplier += 1
		combo_changed.emit(multiplier)
	score_changed.emit(score)
	return gained


func add_bonus(points: int) -> void:
	score += points
	score_changed.emit(score)


func tick(delta: float) -> void:
	if _combo_timer <= 0.0:
		return
	_combo_timer -= delta
	if _combo_timer <= 0.0 and multiplier != 1:
		multiplier = 1
		combo_changed.emit(multiplier)


func reset() -> void:
	score = 0
	multiplier = 1
	_combo_timer = 0.0
	score_changed.emit(score)
	combo_changed.emit(multiplier)
