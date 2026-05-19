extends Area2D

@export var damage_to_boss := 10

var manager: Node
var _open := false
var _flash_tween: Tween

@onready var visual: CanvasItem = get_node_or_null("Visual") as CanvasItem
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	close_core()


func set_manager(new_manager: Node) -> void:
	manager = new_manager


func open_core() -> void:
	_open = true
	visible = true
	monitorable = true
	monitoring = true
	if collision_shape != null:
		collision_shape.disabled = false
	if visual != null:
		visual.visible = true
		visual.modulate = Color(1.35, 1.35, 1.35, 1.0)


func close_core() -> void:
	_open = false
	visible = false
	monitorable = false
	monitoring = false
	if collision_shape != null:
		collision_shape.disabled = true
	if visual != null:
		visual.visible = false


func take_damage(_amount: int, _from_position: Vector2 = Vector2.ZERO) -> void:
	if not _open:
		return
	if manager != null and manager.has_method("damage_boss"):
		manager.call("damage_boss", damage_to_boss)
	_flash_hit()


func _flash_hit() -> void:
	if visual == null:
		return
	if _flash_tween != null:
		_flash_tween.kill()
	visual.modulate = Color(1.45, 0.55, 0.55, 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_property(visual, "modulate", Color(1.35, 1.35, 1.35, 1.0), 0.12)
