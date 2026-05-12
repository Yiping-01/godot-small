extends CharacterBody2D

@export var max_health: int = 20
@export var gravity: float = 1600.0
@export var dash_speed: float = 760.0
@export var dash_time: float = 0.42
@export var windup_time: float = 0.55
@export var recover_time: float = 0.8
@export var attack_range: float = 720.0
@export var close_attack_range: float = 360.0
@export var vertical_tolerance: float = 180.0
@export var contact_damage: int = 1
@export var hurt_knockback: float = 240.0
@export var hit_stun_time: float = 0.18
@export var quake_jump_velocity: float = -820.0
@export var quake_gravity: float = 1050.0
@export var quake_damage: int = 1
@export var quake_recover_time: float = 0.7
@export var quake_camera_shake_duration: float = 0.7
@export var quake_camera_shake_strength: float = 7.0
@export var ink_attack_windup_time: float = 0.45
@export var ink_attack_recover_time: float = 0.75
@export var ink_projectile_speed: float = 430.0
@export var ink_projectile_min_count: int = 8
@export var ink_projectile_max_count: int = 10
@export var ink_projectile_min_batch: int = 1
@export var ink_projectile_max_batch: int = 3
@export var ink_projectile_min_height: float = -58.0
@export var ink_projectile_max_height: float = 52.0
@export var ink_projectile_min_interval: float = 0.3
@export var ink_projectile_max_interval: float = 0.5
@export var ink_projectile_min_speed_multiplier: float = 0.75
@export var ink_projectile_max_speed_multiplier: float = 1.35
@export var ink_projectile_straight_chance: float = 0.45
@export var ink_projectile_min_arc_vertical_speed: float = -760.0
@export var ink_projectile_max_arc_vertical_speed: float = -540.0
@export var ink_projectile_arc_gravity: float = 900.0
@export var ink_projectile_scene: PackedScene = preload("res://scenes/ink_projectile.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var damage_area: Area2D = $DamageArea
@onready var damage_shape: CollisionShape2D = $DamageArea/CollisionShape2D

var health := 0
var state := &"idle"
var state_timer := 0.0
var direction := -1
var hit_stun_left := 0.0
var ink_projectiles_left := 0
var ink_projectile_index := 0
var ink_next_shot_time := 0.0
var quake_has_left_floor := false
var target: Node2D


func _ready() -> void:
	health = max_health
	add_to_group("enemy")
	damage_area.area_entered.connect(_on_damage_area_entered)
	_set_damage_area_enabled(false)
	_sync_facing()


func _physics_process(delta: float) -> void:
	target = _find_player()

	if not is_on_floor():
		velocity.y += _get_current_gravity() * delta

	if hit_stun_left > 0.0:
		hit_stun_left -= delta
		velocity.x = move_toward(velocity.x, 0.0, hurt_knockback * delta * 3.0)
	else:
		match state:
			&"windup":
				_update_windup(delta)
			&"dash":
				_update_dash(delta)
			&"recover":
				_update_recover(delta)
			&"ink_windup":
				_update_ink_windup(delta)
			&"ink_fire":
				_update_ink_fire(delta)
			&"ink_recover":
				_update_ink_recover(delta)
			&"quake_jump":
				_update_quake_jump(delta)
			&"quake_recover":
				_update_quake_recover(delta)
			_:
				_update_idle(delta)

	move_and_slide()


func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	health -= amount
	var push_direction := signf(global_position.x - from_position.x)
	if is_zero_approx(push_direction):
		push_direction = 1.0

	hit_stun_left = hit_stun_time
	velocity.x = push_direction * hurt_knockback
	_flash()

	if health <= 0:
		queue_free()


func _update_idle(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * 0.08)
	if not _can_dash_attack():
		return

	_begin_dash_attack()


func _update_windup(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta)
	_face_target()
	state_timer -= delta
	if state_timer > 0.0:
		return

	state = &"dash"
	state_timer = dash_time
	velocity.x = direction * dash_speed
	_set_damage_area_enabled(true)


func _update_dash(delta: float) -> void:
	state_timer -= delta
	velocity.x = direction * dash_speed
	if state_timer > 0.0:
		return

	_set_damage_area_enabled(false)
	state = &"recover"
	state_timer = recover_time


func _update_recover(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta * 2.0)
	state_timer -= delta
	if state_timer <= 0.0:
		if target != null:
			_begin_random_special_after_dash()
			return
		state = &"idle"


func _update_ink_windup(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta)
	_face_target()
	state_timer -= delta
	if state_timer > 0.0:
		return

	_begin_ink_fire()


func _update_ink_fire(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta)
	_face_target()
	ink_next_shot_time -= delta
	if ink_next_shot_time > 0.0:
		return

	var batch_count := randi_range(ink_projectile_min_batch, ink_projectile_max_batch)
	batch_count = mini(batch_count, ink_projectiles_left)
	for _shot in range(batch_count):
		_shoot_one_ink()
		ink_projectile_index += 1
		ink_projectiles_left -= 1

	if ink_projectiles_left > 0:
		ink_next_shot_time = randf_range(ink_projectile_min_interval, ink_projectile_max_interval)
		return

	state = &"ink_recover"
	state_timer = ink_attack_recover_time


func _update_ink_recover(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta)
	state_timer -= delta
	if state_timer <= 0.0:
		_begin_random_attack()


func _update_quake_jump(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta)
	if not is_on_floor():
		quake_has_left_floor = true
	if quake_has_left_floor and is_on_floor() and velocity.y >= 0.0:
		_trigger_quake()
		state = &"quake_recover"
		state_timer = quake_recover_time


func _update_quake_recover(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta)
	state_timer -= delta
	if state_timer <= 0.0:
		_begin_random_attack()


func _begin_dash_attack() -> void:
	_face_target()
	state = &"windup"
	state_timer = windup_time


func _begin_ink_attack() -> void:
	_face_target()
	state = &"ink_windup"
	state_timer = ink_attack_windup_time


func _begin_ink_fire() -> void:
	state = &"ink_fire"
	ink_projectiles_left = randi_range(ink_projectile_min_count, ink_projectile_max_count)
	ink_projectile_index = 0
	ink_next_shot_time = 0.0


func _begin_quake_jump() -> void:
	_set_damage_area_enabled(false)
	state = &"quake_jump"
	quake_has_left_floor = false
	velocity.x = 0.0
	velocity.y = quake_jump_velocity


func _trigger_quake() -> void:
	if target != null and target.has_method("_start_camera_shake"):
		target.call("_start_camera_shake", quake_camera_shake_duration, quake_camera_shake_strength)
	if not _is_target_on_floor() or target == null:
		return
	if target.has_method("take_quake_damage"):
		target.call("take_quake_damage", quake_damage)
	elif target.has_method("take_damage"):
		target.call("take_damage", quake_damage, global_position)


func _is_target_on_floor() -> bool:
	if target is CharacterBody2D:
		return target.is_on_floor()
	return false


func _get_current_gravity() -> float:
	if state == &"quake_jump":
		return quake_gravity
	return gravity


func _begin_random_special_after_dash() -> void:
	if _is_target_close():
		_begin_quake_jump()
	else:
		_begin_ink_attack()


func _begin_random_attack() -> void:
	if target == null or not _can_dash_attack():
		state = &"idle"
		return

	if _is_target_close():
		if randf() < 0.5:
			_begin_dash_attack()
		else:
			_begin_quake_jump()
	else:
		_begin_ink_attack()


func _is_target_close() -> bool:
	if target == null:
		return false
	return absf(target.global_position.x - global_position.x) <= close_attack_range


func _shoot_one_ink() -> void:
	if ink_projectile_scene == null:
		return

	var parent := get_parent()
	if parent == null:
		return

	var projectile := ink_projectile_scene.instantiate()
	parent.add_child(projectile)
	if projectile is Node2D:
		var random_height := randf_range(ink_projectile_min_height, ink_projectile_max_height)
		projectile.global_position = global_position + Vector2(74.0 * direction, random_height)
	var speed_multiplier := randf_range(ink_projectile_min_speed_multiplier, ink_projectile_max_speed_multiplier)
	var projectile_speed := ink_projectile_speed * speed_multiplier
	if randf() < ink_projectile_straight_chance and projectile.has_method("launch"):
		projectile.call("launch", direction, contact_damage, projectile_speed, self)
	elif projectile.has_method("launch_arc"):
		var vertical_speed := randf_range(ink_projectile_min_arc_vertical_speed, ink_projectile_max_arc_vertical_speed)
		projectile.call("launch_arc", direction, contact_damage, projectile_speed, vertical_speed, ink_projectile_arc_gravity, self)


func _can_dash_attack() -> bool:
	if target == null:
		return false

	var offset := target.global_position - global_position
	return absf(offset.x) <= attack_range and absf(offset.y) <= vertical_tolerance


func _find_player() -> Node2D:
	var player := get_tree().get_first_node_in_group("player")
	if player is Node2D:
		return player

	var scene := get_tree().current_scene
	if scene == null:
		return null

	player = scene.find_child("Player", true, false)
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


func _sync_facing() -> void:
	sprite.flip_h = direction > 0
	damage_area.position.x = 64.0 * direction


func _set_damage_area_enabled(enabled: bool) -> void:
	damage_area.set_deferred("monitoring", enabled)
	damage_shape.set_deferred("disabled", not enabled)


func _on_damage_area_entered(area: Area2D) -> void:
	if state != &"dash":
		return

	var receiver := _find_damage_receiver(area)
	if receiver == null or receiver == self:
		return

	receiver.call("take_damage", contact_damage, global_position)


func _find_damage_receiver(target_node: Node) -> Node:
	var current: Node = target_node
	while current != null:
		if current.has_method("take_damage"):
			return current
		current = current.get_parent()
	return null


func _flash(color: Color = Color(1.0, 0.25, 0.25), hold_time: float = 0.05, fade_time: float = 0.12) -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", color, hold_time)
	tween.tween_property(sprite, "modulate", Color.WHITE, fade_time)
