extends CharacterBody2D
class_name Enemy2

@export_enum("melee", "ranged") var behavior_mode := "melee"
@export var max_health: int = 3
@export var patrol_speed: float = 55.0
@export var gravity: float = 1600.0
@export var max_fall_speed: float = 620.0
@export var hurt_knockback: float = 260.0
@export var hit_stun_time: float = 0.24
@export var death_delay: float = 0.35
@export var contact_damage: int = 1
@export var detection_range: float = 620.0
@export var melee_range: float = 310.0
@export var ranged_range: float = 680.0
@export var vertical_tolerance: float = 150.0
@export var attack_cooldown: float = 1.35
@export var attack_windup_time: float = 0.34
@export var attack_recovery_time: float = 0.65
@export var dash_speed: float = 720.0
@export var dash_time: float = 0.28
@export var ink_projectile_speed: float = 430.0
@export var ink_projectile_scene: PackedScene = preload("res://scenes/ink_projectile.tscn")
@export var coin_drop_amount: int = 4
@export var coin_scene: PackedScene = preload("res://scenes/coin_pickup.tscn")

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var damage_area: Area2D = $DamageArea
@onready var damage_shape: CollisionShape2D = $DamageArea/CollisionShape2D
@onready var hit_effect: AnimatedSprite2D = $HitEffect
@onready var damage_audio: AudioStreamPlayer2D = $DamageAudio
@onready var death_audio: AudioStreamPlayer2D = $DeathAudio
@onready var left_floor_ray: RayCast2D = $LeftFloorRay
@onready var right_floor_ray: RayCast2D = $RightFloorRay

var health := 0
var direction := -1
var dash_direction := -1
var state := &"idle"
var state_timer := 0.0
var attack_cooldown_left := 0.0
var hit_stun_left := 0.0
var is_dead := false
var damage_area_offset_x := 0.0
var target: Node2D


func _ready() -> void:
	health = max_health
	add_to_group("enemy")
	damage_area_offset_x = absf(damage_area.position.x)
	damage_area.area_entered.connect(_on_damage_area_entered)
	hit_effect.animation_finished.connect(_on_hit_effect_animation_finished)
	hit_effect.visible = false
	_set_damage_area_enabled(false)
	_sync_facing()
	sprite.play("walk")


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	target = _find_player()
	attack_cooldown_left = maxf(attack_cooldown_left - delta, 0.0)

	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)

	if hit_stun_left > 0.0:
		hit_stun_left -= delta
		velocity.x = move_toward(velocity.x, 0.0, hurt_knockback * delta * 3.0)
	else:
		match state:
			&"windup":
				_update_windup(delta)
			&"dash":
				_update_dash(delta)
			&"recovery":
				_update_recovery(delta)
			_:
				_update_idle(delta)

	move_and_slide()
	_update_walk_animation()

	if state == &"idle" and (is_on_wall() or (is_on_floor() and not _has_floor_ahead())):
		_flip()


func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return

	health -= amount
	var push_direction := signf(global_position.x - from_position.x)
	if is_zero_approx(push_direction):
		push_direction = 1.0

	_cancel_attack()
	velocity.x = push_direction * hurt_knockback
	velocity.y = minf(velocity.y, -80.0)
	hit_stun_left = hit_stun_time
	_play_audio(damage_audio)
	_play_hit_effect()
	_flash()

	if health <= 0:
		_die()


func _update_idle(delta: float) -> void:
	if _can_attack_target():
		_face_target()
		velocity.x = move_toward(velocity.x, 0.0, patrol_speed * delta * 6.0)
		if attack_cooldown_left <= 0.0:
			_begin_attack()
		return

	velocity.x = direction * patrol_speed


func _update_windup(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta)
	_face_target()
	state_timer -= delta
	if state_timer > 0.0:
		return

	if behavior_mode == "ranged":
		_shoot_ink()
		_enter_recovery()
	else:
		_start_dash()


func _update_dash(delta: float) -> void:
	state_timer -= delta
	velocity.x = float(dash_direction) * dash_speed
	if state_timer > 0.0:
		return

	_set_damage_area_enabled(false)
	_enter_recovery()


func _update_recovery(delta: float) -> void:
	state_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, patrol_speed * delta * 5.0)
	if state_timer <= 0.0:
		state = &"idle"


func _begin_attack() -> void:
	state = &"windup"
	state_timer = attack_windup_time
	attack_cooldown_left = attack_cooldown
	_set_damage_area_enabled(false)
	_flash(Color(0.55, 0.88, 1.0), 0.08, 0.2)


func _start_dash() -> void:
	state = &"dash"
	state_timer = dash_time
	dash_direction = direction
	_set_damage_area_enabled(true)
	sprite.play("attack")
	velocity.x = float(dash_direction) * dash_speed


func _enter_recovery() -> void:
	state = &"recovery"
	state_timer = attack_recovery_time
	_set_damage_area_enabled(false)


func _cancel_attack() -> void:
	if state == &"dash":
		_set_damage_area_enabled(false)
	state = &"idle"
	state_timer = 0.0


func _shoot_ink() -> void:
	if ink_projectile_scene == null:
		return

	var projectile := ink_projectile_scene.instantiate()
	var parent := get_parent()
	if parent == null:
		return

	parent.add_child(projectile)
	if projectile is Node2D:
		projectile.global_position = global_position + Vector2(42.0 * direction, -10.0)
	if projectile.has_method("launch"):
		projectile.call("launch", direction, contact_damage, ink_projectile_speed, self)


func _can_attack_target() -> bool:
	if target == null:
		return false

	var offset := target.global_position - global_position
	if absf(offset.y) > vertical_tolerance:
		return false

	var distance := absf(offset.x)
	if behavior_mode == "ranged":
		return distance <= ranged_range and distance >= melee_range * 0.45
	return distance <= melee_range


func _find_player() -> Node2D:
	if target != null and is_instance_valid(target):
		return target

	var player := get_tree().get_first_node_in_group("player")
	if player is Node2D:
		return player
	return null


func _face_target() -> void:
	if target == null:
		return

	var new_direction := signf(target.global_position.x - global_position.x)
	if is_zero_approx(new_direction):
		return

	direction = int(new_direction)
	_sync_facing()


func _flip() -> void:
	direction *= -1
	_sync_facing()


func _has_floor_ahead() -> bool:
	var ray := left_floor_ray if direction < 0 else right_floor_ray
	return ray.is_colliding()


func _sync_facing() -> void:
	sprite.flip_h = direction > 0
	damage_area.position.x = damage_area_offset_x * direction


func _update_walk_animation() -> void:
	if is_dead:
		return
	if state == &"dash":
		if sprite.animation != &"attack":
			sprite.play("attack")
		return

	if absf(velocity.x) > 5.0:
		if sprite.animation != &"walk" or not sprite.is_playing():
			sprite.play("walk")
	else:
		sprite.stop()
		sprite.frame = 0


func _set_damage_area_enabled(enabled: bool) -> void:
	damage_area.set_deferred("monitoring", enabled)
	damage_shape.set_deferred("disabled", not enabled)


func _flash(color: Color = Color(1.0, 0.35, 0.35), hold_time: float = 0.04, recover_time: float = 0.12) -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", color, hold_time)
	tween.tween_property(sprite, "modulate", Color.WHITE, recover_time)


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


func _play_hit_effect() -> void:
	hit_effect.visible = true
	hit_effect.rotation = randf_range(-0.25, 0.25)
	hit_effect.play("hit")


func _play_audio(audio: AudioStreamPlayer2D) -> void:
	if audio != null and audio.stream != null:
		audio.play()


func _on_damage_area_entered(area: Area2D) -> void:
	if is_dead or state != &"dash":
		return

	var receiver := _find_damage_receiver(area)
	if receiver == null:
		return

	receiver.call("take_damage", contact_damage, global_position)


func _find_damage_receiver(target_node: Node) -> Node:
	var current: Node = target_node
	while current != null:
		if current.has_method("take_damage"):
			return current
		current = current.get_parent()
	return null


func _on_hit_effect_animation_finished() -> void:
	hit_effect.visible = false
