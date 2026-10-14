class_name Pickup
extends Area2D
## Collectible dropped by enemies. Heals or awards bonus points.

signal collected(pickup: Pickup, player: Player)

enum Kind { HEALTH, SCORE }

@export var kind: Kind = Kind.SCORE
@export var value: int = 25
@export var lifetime: float = 10.0

var _age: float = 0.0


func _ready() -> void:
	collision_layer = GameConfig.LAYER_PICKUPS
	collision_mask = GameConfig.LAYER_PLAYER
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = 12.0
		shape.shape = circle
		add_child(shape)
	body_entered.connect(_on_body_entered)


func apply_to(player: Player) -> void:
	if kind == Kind.HEALTH:
		player.heal(value)
	collected.emit(self, player)
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not (body as Player).is_dead:
		apply_to(body as Player)


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var pulse := 1.0 + 0.15 * sin(_age * 6.0)
	if kind == Kind.HEALTH:
		var c := Color(0.35, 1.0, 0.45)
		draw_rect(Rect2(Vector2(-3, -9) * pulse, Vector2(6, 18) * pulse), c)
		draw_rect(Rect2(Vector2(-9, -3) * pulse, Vector2(18, 6) * pulse), c)
	else:
		draw_circle(Vector2.ZERO, 8.0 * pulse, Color(1.0, 0.85, 0.2))
