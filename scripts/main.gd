extends Node2D
## Game controller: wires player, spawner, scoring, pickups, HUD and persistence via signals.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const PICKUP_SCENE := preload("res://scenes/pickup.tscn")
const HUD_SCENE := preload("res://scenes/hud.tscn")

var player: Player
var spawner: WaveSpawner
var hud: Hud
var scores := ScoreManager.new()
var store := HighScoreStore.new()
var high_score: int = 0
var game_over: bool = false
var _world: Node2D
var _rng := RandomNumberGenerator.new()
# Demo/screenshot mode (see README): --demo --screenshot=<dir>
var _demo: bool = false
var _shot_dir: String = ""
var _shot_times: Array[float] = [8.0, 22.0, 40.0]
var _elapsed: float = 0.0


func _ready() -> void:
	InputSetup.ensure_actions()
	_parse_args()
	_build_walls()
	_world = Node2D.new()
	_world.name = "World"
	add_child(_world)
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	hud.restart_requested.connect(restart)
	spawner = WaveSpawner.new()
	spawner.name = "WaveSpawner"
	add_child(spawner)
	spawner.wave_started.connect(_on_wave_started)
	spawner.enemy_spawned.connect(_on_enemy_spawned)
	scores.score_changed.connect(hud.set_score)
	scores.combo_changed.connect(hud.set_combo)
	high_score = store.load_high_score()
	start_run()


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--demo":
			_demo = true
		elif arg.begins_with("--screenshot="):
			_shot_dir = arg.get_slice("=", 1)
			_demo = true


func start_run() -> void:
	for child in _world.get_children():
		child.queue_free()
	game_over = false
	scores.reset()
	player = PLAYER_SCENE.instantiate()
	player.position = GameConfig.ARENA_SIZE / 2.0
	_world.add_child(player)
	player.health_changed.connect(hud.set_health)
	player.attacked.connect(_on_player_attacked)
	player.died.connect(_on_player_died)
	hud.set_health(player.max_health, player.max_health)
	hud.set_best(high_score)
	hud.set_wave(0)
	hud.hide_game_over()
	spawner.target = player
	spawner.container = _world
	spawner.start(42 if _demo else -1)


func restart() -> void:
	start_run()


func _build_walls() -> void:
	var size := GameConfig.ARENA_SIZE
	var t := GameConfig.WALL_THICKNESS
	var rects := [
		Rect2(0, 0, size.x, t), Rect2(0, size.y - t, size.x, t),
		Rect2(0, 0, t, size.y), Rect2(size.x - t, 0, t, size.y),
	]
	for r: Rect2 in rects:
		var body := StaticBody2D.new()
		body.collision_layer = GameConfig.LAYER_WALLS
		body.collision_mask = 0
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = r.size
		shape.shape = box
		body.position = r.get_center()
		body.add_child(shape)
		add_child(body)


func _draw() -> void:
	var size := GameConfig.ARENA_SIZE
	var t := GameConfig.WALL_THICKNESS
	for x in range(int(t), int(size.x - t), 64):
		draw_line(Vector2(x, t), Vector2(x, size.y - t), Color(1, 1, 1, 0.04))
	for y in range(int(t), int(size.y - t), 64):
		draw_line(Vector2(t, y), Vector2(size.x - t, y), Color(1, 1, 1, 0.04))
	var wall := Color(0.2, 0.24, 0.32)
	draw_rect(Rect2(0, 0, size.x, t), wall)
	draw_rect(Rect2(0, size.y - t, size.x, t), wall)
	draw_rect(Rect2(0, 0, t, size.y), wall)
	draw_rect(Rect2(size.x - t, 0, t, size.y), wall)


func _process(delta: float) -> void:
	scores.tick(delta)
	if _demo:
		_drive_demo(delta)


func _on_wave_started(wave: int, count: int) -> void:
	hud.set_wave(wave)
	hud.show_banner("WAVE %d  ·  %d enemies" % [wave, count])


func _on_enemy_spawned(enemy: Enemy) -> void:
	enemy.died.connect(_on_enemy_died)


func _on_player_attacked(origin: Vector2, reach: float) -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and not enemy.is_queued_for_deletion() and enemy.global_position.distance_to(origin) <= reach:
			enemy.take_hit(1)


func _on_enemy_died(enemy: Enemy, points: int) -> void:
	scores.add_kill(points)
	if _rng.randf() < GameConfig.PICKUP_DROP_CHANCE:
		_spawn_pickup.call_deferred(enemy.global_position)


func _spawn_pickup(at: Vector2) -> void:
	var pickup: Pickup = PICKUP_SCENE.instantiate()
	pickup.kind = Pickup.Kind.HEALTH if _rng.randf() < 0.4 else Pickup.Kind.SCORE
	pickup.value = 1 if pickup.kind == Pickup.Kind.HEALTH else 25
	pickup.position = at
	pickup.collected.connect(_on_pickup_collected)
	_world.add_child(pickup)


func _on_pickup_collected(pickup: Pickup, _p: Player) -> void:
	if pickup.kind == Pickup.Kind.SCORE:
		scores.add_bonus(pickup.value)


func _on_player_died() -> void:
	game_over = true
	spawner.stop()
	var record := store.submit(scores.score)
	if record:
		high_score = scores.score
	hud.set_best(high_score)
	hud.show_game_over(scores.score, high_score, record, spawner.wave)


## Simple autopilot used for screenshots and smoke runs: kite enemies and attack.
func _drive_demo(delta: float) -> void:
	_elapsed += delta
	if is_instance_valid(player) and not player.is_dead:
		var nearest: Enemy = null
		var best := INF
		for node in get_tree().get_nodes_in_group("enemies"):
			var d := player.global_position.distance_to((node as Node2D).global_position)
			if d < best:
				best = d
				nearest = node
		var orbit := Vector2.RIGHT.rotated(_elapsed * 0.9) * 180.0 + GameConfig.ARENA_SIZE / 2.0
		var dir := player.global_position.direction_to(orbit)
		if nearest:
			var toward := player.global_position.direction_to(nearest.global_position)
			dir = toward if best > 55.0 else (dir - toward).normalized()
		player.input_override = dir
		if nearest and best < player.attack_reach:
			player.try_attack()
		if nearest and best < 40.0:
			player.try_dash(dir)
	if _shot_dir != "" and not _shot_times.is_empty() and _elapsed >= _shot_times[0]:
		_shot_times.pop_front()
		var img := get_viewport().get_texture().get_image()
		var n := 3 - _shot_times.size()
		img.save_png("%s/screenshot_%d.png" % [_shot_dir, n])
		print("Saved screenshot %d" % n)
		if _shot_times.is_empty():
			get_tree().quit()
