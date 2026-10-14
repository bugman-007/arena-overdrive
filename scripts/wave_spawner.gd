class_name WaveSpawner
extends Node
## Spawns escalating waves of enemies around the arena edge.

signal wave_started(wave: int, enemy_count: int)
signal enemy_spawned(enemy: Enemy)
signal wave_cleared(wave: int)

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

@export var arena_rect: Rect2 = Rect2(Vector2(48, 48), GameConfig.ARENA_SIZE - Vector2(96, 96))
@export var wave_delay: float = 2.0

var wave: int = 0
var target: Node2D
var container: Node
var alive: int = 0
var active: bool = false
var _delay_left: float = 0.0
var _rng := RandomNumberGenerator.new()


static func enemies_for_wave(n: int) -> int:
	return 3 + n * 2


static func speed_for_wave(n: int) -> float:
	return minf(110.0 + n * 12.0, 230.0)


func start(seed_value: int = -1) -> void:
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	wave = 0
	alive = 0
	active = true
	_delay_left = 0.5


func stop() -> void:
	active = false


func _process(delta: float) -> void:
	if not active or alive > 0:
		return
	_delay_left -= delta
	if _delay_left <= 0.0:
		spawn_wave()


func spawn_wave() -> void:
	wave += 1
	var count := enemies_for_wave(wave)
	wave_started.emit(wave, count)
	for i in count:
		var enemy: Enemy = ENEMY_SCENE.instantiate()
		enemy.move_speed = speed_for_wave(wave)
		enemy.max_health = 1 + wave / 3
		enemy.target = target
		enemy.position = _edge_point()
		enemy.died.connect(_on_enemy_died)
		alive += 1
		(container if container else self).add_child(enemy)
		enemy_spawned.emit(enemy)


func _edge_point() -> Vector2:
	var r := arena_rect
	match _rng.randi_range(0, 3):
		0: return Vector2(_rng.randf_range(r.position.x, r.end.x), r.position.y)
		1: return Vector2(_rng.randf_range(r.position.x, r.end.x), r.end.y)
		2: return Vector2(r.position.x, _rng.randf_range(r.position.y, r.end.y))
		_: return Vector2(r.end.x, _rng.randf_range(r.position.y, r.end.y))


func _on_enemy_died(_enemy: Enemy, _points: int) -> void:
	alive = maxi(0, alive - 1)
	if alive == 0:
		wave_cleared.emit(wave)
		_delay_left = wave_delay
