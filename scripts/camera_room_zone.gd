extends Area2D
class_name CameraRoomZone

@export var limit_left: int = -10000000
@export var limit_top: int = -10000000
@export var limit_right: int = 10000000
@export var limit_bottom: int = 10000000
@export var enabled := false
@export var only_when_visible := true


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if enabled:
		call_deferred("_apply_to_overlapping_players")


func _apply_to_overlapping_players() -> void:
	for body in get_overlapping_bodies():
		_on_body_entered(body)


func _on_body_entered(body: Node2D) -> void:
	if not enabled:
		return
	if only_when_visible and not is_visible_in_tree():
		return
	if not body.is_in_group("player") or not body.has_method("set_camera_limits"):
		return

	body.set_camera_limits(limit_left, limit_top, limit_right, limit_bottom)
