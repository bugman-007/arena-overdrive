extends GutTest

var scores: ScoreManager


func before_each() -> void:
	scores = ScoreManager.new()


func test_starts_at_zero() -> void:
	assert_eq(scores.score, 0)
	assert_eq(scores.multiplier, 1)


func test_kill_adds_points() -> void:
	assert_eq(scores.add_kill(10), 10)
	assert_eq(scores.score, 10)


func test_combo_multiplier_grows_and_caps() -> void:
	var gained: Array[int] = []
	for i in 6:
		gained.append(scores.add_kill(10))
	assert_eq(gained, [10, 20, 30, 40, 40, 40] as Array[int])
	assert_eq(scores.multiplier, ScoreManager.MAX_MULTIPLIER)


func test_combo_resets_after_window() -> void:
	scores.add_kill(10)
	scores.add_kill(10)
	scores.tick(ScoreManager.COMBO_WINDOW + 0.1)
	assert_eq(scores.multiplier, 1)
	assert_eq(scores.add_kill(10), 10)


func test_bonus_does_not_affect_combo() -> void:
	scores.add_bonus(25)
	assert_eq(scores.score, 25)
	assert_eq(scores.multiplier, 1)


func test_score_changed_signal() -> void:
	watch_signals(scores)
	scores.add_kill(10)
	assert_signal_emitted_with_parameters(scores, "score_changed", [10])


func test_reset() -> void:
	scores.add_kill(10)
	scores.reset()
	assert_eq(scores.score, 0)
	assert_eq(scores.multiplier, 1)


func test_wave_scaling() -> void:
	assert_eq(WaveSpawner.enemies_for_wave(1), 5)
	assert_eq(WaveSpawner.enemies_for_wave(3), 9)
	assert_lt(WaveSpawner.speed_for_wave(1), WaveSpawner.speed_for_wave(5))
	assert_eq(WaveSpawner.speed_for_wave(100), 230.0)


func test_score_pickup_awards_bonus_and_health_pickup_heals() -> void:
	var player: Player = preload("res://scenes/player.tscn").instantiate()
	add_child_autofree(player)
	player.invulnerability_time = 0.0
	player.take_damage(2)
	var heal: Pickup = preload("res://scenes/pickup.tscn").instantiate()
	heal.kind = Pickup.Kind.HEALTH
	heal.value = 1
	add_child_autofree(heal)
	heal.apply_to(player)
	assert_eq(player.health, player.max_health - 1)
