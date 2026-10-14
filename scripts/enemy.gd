class_name Enemy
extends CharacterBody2D
## Enemy with a small finite state machine: IDLE -> CHASE -> ATTACK.

signal state_changed(old_state: State, new_state: State)
signal attacked(target: Node2D)
signal died(enemy: Enemy, points: int)

enum State { IDLE, CHASE, ATTACK }

@export var move_speed: float = 120.0
@export var detect_range: float = 650.0
@export var attack_range: float = 30.0
@export var attack_cooldown: float = 0.8
@export var attack_damage: int = 1
@export var max_health: int = 2
@export var points: int = 10
@export var radius: float = 13.0

var state: State = State.IDLE
var target: Node2D
var health: int
var _attack_cooldown_left: float = 0.0
var _hit_flash: float = 0.0


func _ready() -> void:
	health = max_health
	collision_layer = GameConfig.LAYER_ENEMIES
	collision_mask = GameConfig.LAYER_WALLS | GameConfig.LAYER_ENEMIES
	add_to_group("enemies")
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = radius
		shape.shape = circle
		add_child(shape)


## Decide the next state from distance to the target. Pure function.
func evaluate_state(distance: float, has_target: bool) -> State:
	if not has_target:
		return State.IDLE
	if distance <= attack_range:
		return State.ATTACK
	# Hysteresis: once chasing, keep chasing a bit past detect range.
	var leash := detect_range * (1.25 if state != State.IDLE else 1.0)
	if distance <= leash:
		return State.CHASE
	return State.IDLE


func set_state(new_state: State) -> void:
	if new_state == state:
		return
	var old := state
	state = new_state
	state_changed.emit(old, new_state)


func _has_live_target() -> bool:
	if target == null or not is_instance_valid(target):
		return false
	return not (target is Player and (target as Player).is_dead)


func tick(delta: float) -> void:
	_attack_cooldown_left = maxf(0.0, _attack_cooldown_left - delta)
	_hit_flash = maxf(0.0, _hit_flash - delta)
	var has_target := _has_live_target()
	var distance := global_position.distance_to(target.global_position) if has_target else INF
	set_state(evaluate_state(distance, has_target))
	match state:
		State.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, move_speed * 4.0 * delta)
		State.CHASE:
			velocity = global_position.direction_to(target.global_position) * move_speed
		State.ATTACK:
			velocity = Vector2.ZERO
			if _attack_cooldown_left <= 0.0:
				_attack_cooldown_left = attack_cooldown
				attacked.emit(target)
				if target.has_method("take_damage"):
					target.take_damage(attack_damage)


func _physics_process(delta: float) -> void:
	tick(delta)
	move_and_slide()
	queue_redraw()


func take_hit(amount: int) -> void:
	if health <= 0:
		return
	health -= amount
	_hit_flash = 0.12
	if health <= 0:
		died.emit(self, points)
		queue_free()


func _draw() -> void:
	var colors := {
		State.IDLE: Color(0.6, 0.6, 0.65),
		State.CHASE: Color(1.0, 0.55, 0.2),
		State.ATTACK: Color(1.0, 0.25, 0.3),
	}
	var c: Color = Color.WHITE if _hit_flash > 0.0 else colors[state]
	var pts := PackedVector2Array()
	for i in 4:
		pts.append(Vector2.RIGHT.rotated(TAU * i / 4.0 + PI / 4.0) * radius * 1.3)
	draw_colored_polygon(pts, c)
