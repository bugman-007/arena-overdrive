extends GutTest

const EnemyScene := preload("res://scenes/enemy.tscn")
var enemy: Enemy
var dummy: Node2D


func before_each() -> void:
	enemy = EnemyScene.instantiate()
	add_child_autofree(enemy)
	dummy = Node2D.new()
	add_child_autofree(dummy)


func test_starts_idle() -> void:
	assert_eq(enemy.state, Enemy.State.IDLE)


func test_idle_without_target() -> void:
	enemy.tick(0.016)
	assert_eq(enemy.state, Enemy.State.IDLE)


func test_idle_when_target_out_of_range() -> void:
	enemy.target = dummy
	dummy.global_position = enemy.global_position + Vector2(enemy.detect_range + 50, 0)
	enemy.tick(0.016)
	assert_eq(enemy.state, Enemy.State.IDLE)


func test_chases_when_target_detected() -> void:
	enemy.target = dummy
	dummy.global_position = enemy.global_position + Vector2(200, 0)
	enemy.tick(0.016)
	assert_eq(enemy.state, Enemy.State.CHASE)
	assert_gt(enemy.velocity.x, 0.0, "should move toward target")


func test_attacks_when_in_range() -> void:
	enemy.target = dummy
	dummy.global_position = enemy.global_position + Vector2(10, 0)
	enemy.tick(0.016)
	assert_eq(enemy.state, Enemy.State.ATTACK)
	assert_eq(enemy.velocity, Vector2.ZERO)


func test_full_transition_sequence_emits_signals() -> void:
	watch_signals(enemy)
	enemy.target = dummy
	dummy.global_position = enemy.global_position + Vector2(300, 0)
	enemy.tick(0.016)
	dummy.global_position = enemy.global_position + Vector2(5, 0)
	enemy.tick(0.016)
	dummy.global_position = enemy.global_position + Vector2(5000, 0)
	enemy.tick(0.016)
	assert_signal_emit_count(enemy, "state_changed", 3)
	assert_signal_emitted_with_parameters(enemy, "state_changed", [Enemy.State.ATTACK, Enemy.State.IDLE])


func test_chase_has_hysteresis() -> void:
	enemy.state = Enemy.State.CHASE
	assert_eq(enemy.evaluate_state(enemy.detect_range * 1.1, true), Enemy.State.CHASE)
	enemy.state = Enemy.State.IDLE
	assert_eq(enemy.evaluate_state(enemy.detect_range * 1.1, true), Enemy.State.IDLE)


func test_attack_damages_player_and_respects_cooldown() -> void:
	var player: Player = preload("res://scenes/player.tscn").instantiate()
	add_child_autofree(player)
	player.invulnerability_time = 0.0
	enemy.target = player
	player.global_position = enemy.global_position + Vector2(10, 0)
	enemy.tick(0.016)
	enemy.tick(0.016)
	assert_eq(player.health, player.max_health - 1, "only one hit inside cooldown")
	enemy.tick(enemy.attack_cooldown)
	assert_eq(player.health, player.max_health - 2)


func test_dead_player_is_not_a_target() -> void:
	var player: Player = preload("res://scenes/player.tscn").instantiate()
	add_child_autofree(player)
	player.is_dead = true
	enemy.target = player
	player.global_position = enemy.global_position + Vector2(10, 0)
	enemy.tick(0.016)
	assert_eq(enemy.state, Enemy.State.IDLE)


func test_dies_and_reports_points() -> void:
	watch_signals(enemy)
	enemy.take_hit(enemy.max_health)
	assert_signal_emitted_with_parameters(enemy, "died", [enemy, enemy.points])
