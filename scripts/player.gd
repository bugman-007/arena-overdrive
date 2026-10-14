class_name Player
extends CharacterBody2D
## Player character: 8-way movement, a cooldown-gated dash, and health.

signal health_changed(current: int, maximum: int)
signal dashed
signal died
signal attacked(origin: Vector2, reach: float)

@export var move_speed: float = 260.0
@export var dash_speed: float = 760.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.9
@export var max_health: int = 5
@export var invulnerability_time: float = 0.6
@export var radius: float = 14.0
@export var attack_reach: float = 64.0
@export var attack_cooldown: float = 0.3

var health: int
var facing: Vector2 = Vector2.RIGHT
var is_dashing: bool = false
var is_dead: bool = false
var _dash_time_left: float = 0.0
var _dash_cooldown_left: float = 0.0
var _invuln_left: float = 0.0
var _attack_cooldown_left: float = 0.0
var _attack_flash: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO
## When set (e.g. in tests or the demo bot), overrides keyboard input.
var input_override: Variant = null


func _ready() -> void:
	health = max_health
	collision_layer = GameConfig.LAYER_PLAYER
	collision_mask = GameConfig.LAYER_WALLS
	add_to_group("player")
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = radius
		shape.shape = circle
		add_child(shape)


func get_input_direction() -> Vector2:
	if input_override != null:
		return (input_override as Vector2).limit_length(1.0)
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func can_dash() -> bool:
	return not is_dead and not is_dashing and _dash_cooldown_left <= 0.0


func try_dash(direction: Vector2) -> bool:
	if not can_dash():
		return false
	_dash_direction = direction.normalized() if direction != Vector2.ZERO else facing
	is_dashing = true
	_dash_time_left = dash_duration
	_dash_cooldown_left = dash_cooldown
	dashed.emit()
	return true


func get_dash_cooldown_left() -> float:
	return _dash_cooldown_left


## Pure-ish step used by _physics_process and by tests.
func step(delta: float, direction: Vector2) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return
	_dash_cooldown_left = maxf(0.0, _dash_cooldown_left - delta)
	_invuln_left = maxf(0.0, _invuln_left - delta)
	_attack_cooldown_left = maxf(0.0, _attack_cooldown_left - delta)
	_attack_flash = maxf(0.0, _attack_flash - delta)
	if direction != Vector2.ZERO:
		facing = direction.normalized()
	if is_dashing:
		velocity = _dash_direction * dash_speed
		_dash_time_left -= delta
		if _dash_time_left <= 0.0:
			is_dashing = false
	else:
		velocity = direction * move_speed


func _physics_process(delta: float) -> void:
	var direction := get_input_direction()
	if input_override == null and Input.is_action_just_pressed("dash"):
		try_dash(direction)
	if input_override == null and Input.is_action_pressed("attack"):
		try_attack()
	step(delta, direction)
	move_and_slide()
	queue_redraw()


func try_attack() -> bool:
	if is_dead or _attack_cooldown_left > 0.0:
		return false
	_attack_cooldown_left = attack_cooldown
	_attack_flash = 0.12
	attacked.emit(global_position, attack_reach)
	return true


func take_damage(amount: int) -> bool:
	if is_dead or is_dashing or _invuln_left > 0.0 or amount <= 0:
		return false
	health = maxi(0, health - amount)
	_invuln_left = invulnerability_time
	health_changed.emit(health, max_health)
	if health == 0:
		is_dead = true
		died.emit()
	return true


func heal(amount: int) -> void:
	if is_dead:
		return
	health = mini(max_health, health + amount)
	health_changed.emit(health, max_health)


func _draw() -> void:
	var blink := _invuln_left > 0.0 and int(_invuln_left * 20.0) % 2 == 0
	var body_color := Color(0.35, 0.85, 1.0) if not is_dashing else Color(1, 1, 1)
	if blink:
		body_color.a = 0.35
	if _attack_flash > 0.0:
		draw_arc(Vector2.ZERO, attack_reach, 0.0, TAU, 48, Color(1, 1, 1, _attack_flash * 6.0), 3.0)
	draw_circle(Vector2.ZERO, radius, body_color)
	draw_line(Vector2.ZERO, facing * (radius + 8.0), Color(1, 1, 1, 0.9), 3.0)
	if _dash_cooldown_left > 0.0:
		var pct := 1.0 - _dash_cooldown_left / dash_cooldown
		draw_arc(Vector2.ZERO, radius + 5.0, -PI / 2.0, -PI / 2.0 + TAU * pct, 24, Color(0.35, 0.85, 1.0, 0.6), 2.0)
