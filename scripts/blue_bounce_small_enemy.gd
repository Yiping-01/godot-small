extends "res://scripts/enemy.gd"

@export var respawn_scene_path := "res://scenes/blue_bounce_small_enemy.tscn"
@export var bounce_velocity := Vector2(230.0, -170.0)
@export var bounce_min := Vector2(-650.0, 90.0)
@export var bounce_max := Vector2(300.0, 370.0)
@export var blue_modulate := Color(0.45, 0.78, 1.0, 1.0)


func _ready() -> void:
	super._ready()
	lock_to_spawn_height = false
	sprite.modulate = blue_modulate


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	global_position += bounce_velocity * delta

	if global_position.x <= bounce_min.x:
		global_position.x = bounce_min.x
		bounce_velocity.x = absf(bounce_velocity.x)
	elif global_position.x >= bounce_max.x:
		global_position.x = bounce_max.x
		bounce_velocity.x = -absf(bounce_velocity.x)

	if global_position.y <= bounce_min.y:
		global_position.y = bounce_min.y
		bounce_velocity.y = absf(bounce_velocity.y)
	elif global_position.y >= bounce_max.y:
		global_position.y = bounce_max.y
		bounce_velocity.y = -absf(bounce_velocity.y)

	direction = 1 if bounce_velocity.x > 0.0 else -1
	_sync_facing()


func launch_from_split(launch_direction: int, launch_speed := 360.0, _launch_duration := 0.35) -> void:
	direction = launch_direction
	var y_direction := -1.0 if randf() < 0.5 else 1.0
	bounce_velocity = Vector2(float(launch_direction) * launch_speed, y_direction * launch_speed * 0.75)
	_sync_facing()


func _flash() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.0, 0.35, 0.35), 0.04)
	tween.tween_property(sprite, "modulate", blue_modulate, 0.12)