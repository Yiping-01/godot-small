extends "res://scripts/legacy_split_enemy.gd"

@export var bounce_velocity := Vector2(170.0, -130.0)
@export var bounce_min := Vector2(-650.0, 90.0)
@export var bounce_max := Vector2(300.0, 360.0)
@export var blue_modulate := Color(0.35, 0.72, 1.0, 1.0)


func _ready() -> void:
	super._ready()
	respawn_scene_path = "res://scenes/blue_bounce_split_enemy.tscn"
	anim.modulate = blue_modulate


func _physics_process(_delta: float) -> void:
	velocity = bounce_velocity
	move_and_slide()

	if is_on_wall():
		bounce_velocity.x *= -1.0
	if is_on_floor() or is_on_ceiling():
		bounce_velocity.y *= -1.0

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
	anim.flip_h = direction > 0


func _flash_hurt() -> void:
	if hurt_tween != null:
		hurt_tween.kill()

	anim.modulate = Color(1.0, 0.2, 0.2)
	hurt_tween = create_tween()
	hurt_tween.tween_property(anim, "modulate", blue_modulate, hurt_flash_time)
