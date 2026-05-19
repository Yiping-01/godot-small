extends Area2D

@export var max_health := 3
@export var weak_point_min_y := -220.0
@export var weak_point_max_y := -120.0
@export var left_weak_point_min_y := -120.0
@export var left_weak_point_max_y := -50.0
@export var left_wire_global_x := 420.0
@export var right_weak_point_min_y := -380.0
@export var right_weak_point_max_y := -280.0
@export var right_wire_global_x := 860.0
@export var weak_point_x_range := 4.0

var health := 0
var manager: Node
var _destroyed := false
var _flash_tween: Tween

@onready var visual: CanvasItem = get_node_or_null("Visual") as CanvasItem
@onready var core_line: CanvasItem = get_node_or_null("CoreLine") as CanvasItem
@onready var weak_point: Area2D = get_node_or_null("WeakPoint") as Area2D
@onready var weak_point_visual: CanvasItem = get_node_or_null("WeakPoint/Sprite2D") as CanvasItem


func _ready() -> void:
	health = max_health
	collision_layer = 0
	collision_mask = 0
	if weak_point != null:
		weak_point.collision_layer = 4
		weak_point.collision_mask = 0
		call_deferred("_randomize_weak_point_position")
	if visual is AnimatedSprite2D:
		var wire_sprite := visual as AnimatedSprite2D
		wire_sprite.frame = 0
		wire_sprite.play("build")


func set_manager(new_manager: Node) -> void:
	manager = new_manager


func _randomize_weak_point_position() -> void:
	if weak_point == null:
		return
	var min_y := weak_point_min_y
	var max_y := weak_point_max_y
	if global_position.x <= left_wire_global_x:
		min_y = left_weak_point_min_y
		max_y = left_weak_point_max_y
	elif global_position.x >= right_wire_global_x:
		min_y = right_weak_point_min_y
		max_y = right_weak_point_max_y
	weak_point.position = Vector2(
		randf_range(-weak_point_x_range, weak_point_x_range),
		randf_range(min_y, max_y)
	)


func take_damage(amount: int, _from_position: Vector2 = Vector2.ZERO) -> void:
	if _destroyed:
		return

	health -= amount
	if health > 0:
		_flash_hit()
		return

	_destroy()


func _destroy() -> void:
	if _destroyed:
		return

	_destroyed = true
	if manager != null and manager.has_method("on_wire_destroyed"):
		manager.call("on_wire_destroyed", self)
	queue_free()


func _flash_hit() -> void:
	if visual == null:
		return
	if _flash_tween != null:
		_flash_tween.kill()
	visual.modulate = Color(1.0, 0.35, 0.35)
	if weak_point_visual != null:
		weak_point_visual.modulate = Color(1.0, 0.35, 0.35)
	if core_line != null:
		core_line.modulate = Color.WHITE * 2.0
	_flash_tween = create_tween()
	_flash_tween.tween_property(visual, "modulate", Color.WHITE, 0.12)
	if weak_point_visual != null:
		_flash_tween.parallel().tween_property(weak_point_visual, "modulate", Color.WHITE, 0.12)
	if core_line != null:
		_flash_tween.parallel().tween_property(core_line, "modulate", Color.WHITE, 0.12)
