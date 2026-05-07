extends Area2D
class_name CameraZone

@export var camera_offset := Vector2(80.0, -40.0)
@export var camera_zoom := Vector2(1.2, 1.2)
@export var smoothing_speed := 8.0
@export var reset_on_exit := true


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or not body.has_method("set_camera_profile"):
		return

	body.set_camera_profile(camera_offset, camera_zoom, smoothing_speed)


func _on_body_exited(body: Node2D) -> void:
	if not reset_on_exit or not body.is_in_group("player") or not body.has_method("reset_camera_profile"):
		return

	body.reset_camera_profile()
