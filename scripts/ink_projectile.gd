extends Area2D
class_name InkProjectile

@export var speed: float = 420.0
@export var damage: int = 1
@export var lifetime: float = 2.2
@export var spin_speed: float = 7.0

var velocity := Vector2.ZERO
var source: Node


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func launch(direction: int, damage_amount: int = 1, projectile_speed: float = 420.0, source_node: Node = null) -> void:
	var launch_direction := -1 if direction < 0 else 1
	damage = damage_amount
	speed = projectile_speed
	source = source_node
	velocity = Vector2(float(launch_direction) * speed, -24.0)


func _physics_process(delta: float) -> void:
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
