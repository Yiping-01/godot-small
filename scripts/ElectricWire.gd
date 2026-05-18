extends Area2D

@export var max_health := 3
@export var countdown_time := 60.0
@export var lightning_offset := Vector2.ZERO

var health := 0
var manager: Node
var _destroyed := false
var _flash_tween: Tween

@onready var visual: CanvasItem = get_node_or_null("Visual") as CanvasItem
@onready var core_line: CanvasItem = get_node_or_null("CoreLine") as CanvasItem


func _ready() -> void:
	health = max_health
	collision_layer = 4
	collision_mask = 0
	call_deferred("_countdown")


func set_manager(new_manager: Node) -> void:
	manager = new_manager


func take_damage(amount: int, _from_position: Vector2 = Vector2.ZERO) -> void:
	if _destroyed:
		return

	health -= amount
	if health > 0:
		_flash_hit()
		return

	_destroyed = true
	queue_free()


func _countdown() -> void:
	await get_tree().create_timer(countdown_time).timeout
	if _destroyed:
		return

	_destroyed = true
	var boss_manager := _find_boss_manager()
	if boss_manager != null:
		boss_manager.call("trigger_lightning", global_position + lightning_offset)
	queue_free()


func _flash_hit() -> void:
	if visual == null:
		return
	if _flash_tween != null:
		_flash_tween.kill()
	visual.modulate = Color(1.0, 0.35, 0.35)
	if core_line != null:
		core_line.modulate = Color.WHITE * 2.0
	_flash_tween = create_tween()
	_flash_tween.tween_property(visual, "modulate", Color.WHITE, 0.12)
	if core_line != null:
		_flash_tween.parallel().tween_property(core_line, "modulate", Color.WHITE, 0.12)


func _find_boss_manager() -> Node:
	if manager != null and manager.has_method("trigger_lightning"):
		return manager

	var current := get_parent()
	while current != null:
		if current.has_method("trigger_lightning"):
			return current
		current = current.get_parent()
	return null
