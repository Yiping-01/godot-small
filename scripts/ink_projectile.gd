extends Area2D
class_name InkProjectile

@export var speed: float = 420.0
@export var damage: int = 1
@export var lifetime: float = 2.2
@export var spin_speed: float = 7.0
@export var arc_gravity: float = 900.0

var velocity := Vector2.ZERO
var source: Node
var uses_arc := false


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func launch(direction: int, damage_amount: int = 1, projectile_speed: float = 420.0, source_node: Node = null) -> void:
	var launch_direction := -1 if direction < 0 else 1
	damage = damage_amount
	speed = projectile_speed
	source = source_node
	uses_arc = false
	velocity = Vector2(float(launch_direction) * speed, -24.0)


func launch_arc(direction: int, damage_amount: int = 1, projectile_speed: float = 420.0, vertical_speed: float = -360.0, gravity_amount: float = 900.0, source_node: Node = null) -> void:
	var launch_direction := -1 if direction < 0 else 1
	damage = damage_amount
	speed = projectile_speed
	arc_gravity = gravity_amount
	source = source_node
	uses_arc = true
	velocity = Vector2(float(launch_direction) * speed, vertical_speed)


func _physics_process(delta: float) -> void:
	if uses_arc:
		velocity.y += arc_gravity * delta
	global_position += velocity * delta
	rotation += spin_speed * delta * signf(velocity.x)
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	var receiver := _find_damage_receiver(area)
	if receiver == null or receiver == source:
		return

	receiver.call("take_damage", damage, global_position)
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body == source:
		return
	queue_free()


func _find_damage_receiver(target: Node) -> Node:
	var current: Node = target
	while current != null:
		if current.has_method("take_damage"):
			return current
		current = current.get_parent()
	return null
