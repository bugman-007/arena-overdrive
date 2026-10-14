extends GutTest

const PlayerScene := preload("res://scenes/player.tscn")
var player: Player


func before_each() -> void:
	player = PlayerScene.instantiate()
	add_child_autofree(player)


func test_moves_at_move_speed_in_input_direction() -> void:
	player.step(0.016, Vector2.RIGHT)
	assert_eq(player.velocity, Vector2.RIGHT * player.move_speed)


func test_diagonal_input_is_clamped_to_unit_length() -> void:
	player.input_override = Vector2(1, 1)
	assert_almost_eq(player.get_input_direction().length(), 1.0, 0.001)


func test_no_input_means_no_velocity() -> void:
	player.step(0.016, Vector2.ZERO)
	assert_eq(player.velocity, Vector2.ZERO)


func test_dash_boosts_velocity_then_ends() -> void:
	assert_true(player.try_dash(Vector2.UP))
	player.step(0.016, Vector2.UP)
	assert_almost_eq(player.velocity.length(), player.dash_speed, 0.01)
	player.step(player.dash_duration, Vector2.UP)
	player.step(0.016, Vector2.UP)
	assert_false(player.is_dashing)
	assert_almost_eq(player.velocity.length(), player.move_speed, 0.01)


func test_dash_uses_facing_when_no_input() -> void:
	player.step(0.016, Vector2.LEFT)
	player.try_dash(Vector2.ZERO)
	player.step(0.016, Vector2.ZERO)
	assert_almost_eq(player.velocity.x, -player.dash_speed, 0.01)


func test_dash_is_blocked_during_cooldown() -> void:
	assert_true(player.try_dash(Vector2.RIGHT))
	player.step(player.dash_duration + 0.01, Vector2.RIGHT)
	assert_false(player.try_dash(Vector2.RIGHT), "cooldown should block a second dash")
	assert_gt(player.get_dash_cooldown_left(), 0.0)


func test_dash_available_again_after_cooldown() -> void:
	player.try_dash(Vector2.RIGHT)
	var t := 0.0
	while t < player.dash_cooldown + 0.05:
		player.step(0.05, Vector2.ZERO)
		t += 0.05
	assert_true(player.can_dash())
	assert_true(player.try_dash(Vector2.RIGHT))


func test_dash_emits_signal() -> void:
	watch_signals(player)
	player.try_dash(Vector2.RIGHT)
	assert_signal_emitted(player, "dashed")


func test_damage_reduces_health_and_grants_iframes() -> void:
	assert_true(player.take_damage(1))
	assert_eq(player.health, player.max_health - 1)
	assert_false(player.take_damage(1), "invulnerable right after a hit")


func test_dashing_player_ignores_damage() -> void:
	player.try_dash(Vector2.RIGHT)
	assert_false(player.take_damage(1))


func test_dies_at_zero_health() -> void:
	watch_signals(player)
	player.invulnerability_time = 0.0
	for i in player.max_health:
		player.take_damage(1)
	assert_true(player.is_dead)
	assert_signal_emitted(player, "died")


func test_heal_is_capped_at_max() -> void:
	player.invulnerability_time = 0.0
	player.take_damage(2)
	player.heal(10)
	assert_eq(player.health, player.max_health)


func test_attack_respects_cooldown() -> void:
	watch_signals(player)
	assert_true(player.try_attack())
	assert_false(player.try_attack())
	player.step(player.attack_cooldown + 0.01, Vector2.ZERO)
	assert_true(player.try_attack())
	assert_signal_emit_count(player, "attacked", 2)
