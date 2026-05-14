extends CharacterBody2D
class_name TestEnemy

@export var max_health: int = 2
@export var patrol_speed: float = 120.0
@export var gravity: float = 1600.0
@export var max_fall_speed: float = 600.0
@export var hurt_knockback: float = 220.0
@export var hit_stun_time: float = 0.25
@export var death_delay: float = 0.35
@export var contact_damage: int = 1
@export var coin_drop_amount: int = 3
@export var coin_scene: PackedScene = preload("res://scenes/coin_pickup.tscn")
@export var patrol_distance: float = 120.0
@export var lock_to_spawn_height: bool = true
@export var spawn_protection_time: float = 0.45

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var damage_area: Area2D = $DamageArea
@onready var hit_effect: AnimatedSprite2D = $HitEffect
@onready var damage_audio: AudioStreamPlayer2D = $DamageAudio
@onready var death_audio: AudioStreamPlayer2D = $DeathAudio
@onready var left_floor_ray: RayCast2D = $LeftFloorRay
@onready var right_floor_ray: RayCast2D = $RightFloorRay

var health := 0
var direction := -1
var hit_stun_left := 0.0
var is_dead := false
var start_position := Vector2.ZERO
var can_take_damage := true
var split_launch_velocity := Vector2.ZERO
var split_launch_time_left := 0.0
var split_launch_duration := 0.0


func _ready() -> void:
	health = max_health
	is_dead = false
	hit_stun_left = 0.0
	velocity = Vector2.ZERO
	start_position = global_position
	visible = true
	collision_layer = 4
	add_to_group("enemy")
	damage_area.area_entered.connect(_on_damage_area_entered)
	hit_effect.animation_finished.connect(_on_hit_effect_animation_finished)
	hit_effect.visible = false
	sprite.visible = true
	sprite.modulate = Color.WHITE
	collision_shape.disabled = false
	hurtbox.monitoring = true
	hurtbox.monitorable = true
	damage_area.monitoring = true
	damage_area.monitorable = true
	sprite.play("walk")
	_sync_facing()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if lock_to_spawn_height:
		_update_locked_height_patrol(delta)
		return
	elif not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)

	if hit_stun_left > 0.0:
		hit_stun_left -= delta
		velocity.x = move_toward(velocity.x, 0.0, hurt_knockback * delta * 3.0)
	else:
		_turn_around_at_patrol_edge()
		velocity.x = direction * patrol_speed

	move_and_slide()
	_keep_inside_patrol_range()

	if is_on_wall():
		_flip()


func _update_locked_height_patrol(delta: float) -> void:
	var next_position := global_position
	next_position.y = start_position.y
	velocity.y = 0.0

	if split_launch_time_left > 0.0:
		split_launch_time_left -= delta
		next_position.x += split_launch_velocity.x * delta
		split_launch_velocity.x = move_toward(split_launch_velocity.x, 0.0, hurt_knockback * delta * 2.0)
		_update_split_launch_arc()
	elif hit_stun_left > 0.0:
		hit_stun_left -= delta
		velocity.x = move_toward(velocity.x, 0.0, hurt_knockback * delta * 3.0)
	else:
		sprite.position.y = 0.0
		_turn_around_at_patrol_edge()
		velocity.x = direction * patrol_speed

	if split_launch_time_left <= 0.0:
		next_position.x += velocity.x * delta
	global_position = next_position
	_keep_inside_patrol_range()


func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead or not can_take_damage:
		return

	health -= amount

	var push_direction := signf(global_position.x - from_position.x)
	if is_zero_approx(push_direction):
		push_direction = 1.0

	velocity.x = push_direction * hurt_knockback
	velocity.y = minf(velocity.y, -80.0)
	hit_stun_left = hit_stun_time
	_play_audio(damage_audio)
	_play_hit_effect()
	_flash()

	if health <= 0:
		_die()


func _flash() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.0, 0.35, 0.35), 0.04)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)


func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 1
	collision_shape.set_deferred("disabled", true)
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	damage_area.set_deferred("monitoring", false)
	damage_area.set_deferred("monitorable", false)
	_play_audio(death_audio)
	sprite.modulate = Color(1.0, 0.35, 0.28, 0.9)
	call_deferred("_drop_coins")

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 0.0, death_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "scale", sprite.scale * 0.82, death_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	queue_free()


func _drop_coins() -> void:
	if coin_scene == null:
		GameState.add_currency(coin_drop_amount)
		return

	var parent := get_parent()
	if parent == null:
		return

	for i in range(coin_drop_amount):
		var coin := coin_scene.instantiate()
		parent.add_child(coin)
		if coin.has_method("launch_from"):
			coin.call("launch_from", global_position)
		elif coin is Node2D:
			coin.global_position = global_position


func _flip() -> void:
	direction *= -1
	_sync_facing()


func set_direction(new_direction: int) -> void:
	direction = new_direction
	_sync_facing()


func launch_from_split(launch_direction: int, launch_speed := 360.0, launch_duration := 0.35) -> void:
	direction = launch_direction
	split_launch_velocity = Vector2(float(launch_direction) * launch_speed, 0.0)
	split_launch_duration = launch_duration
	split_launch_time_left = launch_duration
	hit_stun_left = maxf(hit_stun_left, launch_duration)
	_sync_facing()
	_update_split_launch_arc()


func start_spawn_protection() -> void:
	can_take_damage = false
	if is_inside_tree():
		_finish_spawn_protection_after_delay()
	else:
		call_deferred("_finish_spawn_protection_after_delay")


func _finish_spawn_protection_after_delay() -> void:
	await get_tree().create_timer(spawn_protection_time).timeout
	can_take_damage = true


func _update_split_launch_arc() -> void:
	if split_launch_duration <= 0.0:
		sprite.position.y = 0.0
		return

	var progress := 1.0 - clampf(split_launch_time_left / split_launch_duration, 0.0, 1.0)
	sprite.position.y = -sin(progress * PI) * 28.0


func _turn_around_at_patrol_edge() -> void:
	var left_edge := start_position.x - patrol_distance
	var right_edge := start_position.x + patrol_distance

	if global_position.x <= left_edge:
		direction = 1
	elif global_position.x >= right_edge:
		direction = -1

	_sync_facing()


func _keep_inside_patrol_range() -> void:
	var left_edge := start_position.x - patrol_distance
	var right_edge := start_position.x + patrol_distance

	if global_position.x < left_edge:
		global_position.x = left_edge
		velocity.x = maxf(velocity.x, 0.0)
	elif global_position.x > right_edge:
		global_position.x = right_edge
		velocity.x = minf(velocity.x, 0.0)


func _has_floor_ahead() -> bool:
	var ray := left_floor_ray if direction < 0 else right_floor_ray
	return ray.is_colliding()


func _sync_facing() -> void:
	sprite.flip_h = direction > 0


func _play_hit_effect() -> void:
	hit_effect.visible = true
	hit_effect.rotation = randf_range(-0.25, 0.25)
	hit_effect.play("hit")


func _play_audio(audio: AudioStreamPlayer2D) -> void:
	if audio != null and audio.stream != null:
		audio.play()


func _on_damage_area_entered(area: Area2D) -> void:
	if is_dead:
		return

	var receiver: Node = _find_damage_receiver(area)
	if receiver == null:
		return

	receiver.call("take_damage", contact_damage, global_position)


func _find_damage_receiver(target: Node) -> Node:
	var current: Node = target
	while current != null:
		if current.has_method("take_damage"):
			return current
		current = current.get_parent()
	return null


func _on_hit_effect_animation_finished() -> void:
	hit_effect.visible = false
