extends Area2D
class_name MapRoomMarker

@export var room_id := ""
@export var display_name := "未命名房間"
@export var map_rect := Rect2(0, 0, 120, 70)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	call_deferred("_register_and_check")


func _register_and_check() -> void:
	var scene_path := _get_scene_path()
	GameState.register_map_room(scene_path, room_id, display_name, map_rect, _get_world_rect())
	for body in get_overlapping_bodies():
		_on_body_entered(body)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	GameState.set_current_map_room(_get_scene_path(), room_id)


func _get_scene_path() -> String:
	var scene := get_tree().current_scene
	if scene == null:
		return ""
	return scene.scene_file_path


func _get_world_rect() -> Rect2:
	var shape_node := get_node_or_null("CollisionShape2D")
	if shape_node is CollisionShape2D and shape_node.shape is RectangleShape2D:
		var rect_shape: RectangleShape2D = shape_node.shape
		var shape_size: Vector2 = rect_shape.size * shape_node.global_scale.abs()
		var center: Vector2 = shape_node.global_position
		return Rect2(center - shape_size * 0.5, shape_size)

	return Rect2(global_position, Vector2.ONE)
