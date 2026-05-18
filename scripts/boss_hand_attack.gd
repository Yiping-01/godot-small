extends Node2D

@export var damage := 1
@export var min_attack_interval := 5.0
@export var max_attack_interval := 10.0
@export var initial_attack_delay := 3.8
@export var warn_time := 0.85
@export var fall_time := 0.18
@export var hit_time := 0.16
@export var recover_time := 0.45
@export var start_position := Vector2(690.0, 560.0)
@export var warning_offset := Vector2.ZERO
@export var attack_y := 606.0
@export var ground_y := 606.0
@export var slam_damage_position := Vector2(-34.0, 20.0)
@export var min_x := 170.0
@export var max_x := 1030.0
@export var sweep_y := 690.0
@export var sweep_start_x := 120.0
@export var sweep_end_x := 1080.0
@export var sweep_warn_time := 0.75
@export var sweep_time := 2.2
@export var sweep_animation_speed_scale := 0.3
@export var sweep_sprite_scale_multiplier := 0.6
@export var sweep_damage_scale_multiplier := 0.4
@export var sweep_damage_position := Vector2(-34.0, 20.0)

@onready var hand_sprite: AnimatedSprite2D = $HandSprite
@onready var attack_out_sprite: AnimatedSprite2D = get_node_or_null("AttackOutSprite") as AnimatedSprite2D
@onready var damage_area: Area2D = $DamageArea
@onready var damage_shape: CollisionShape2D = $DamageArea/CollisionShape2D

var _is_attacking := false
var _attacks_stopped := false
var _next_attack_is_sweep := false
var _hit_targets := {}
var _hand_base_scale := Vector2.ONE
var _damage_area_base_scale := Vector2.ONE
var _damage_area_base_position := Vector2.ZERO


func _ready() -> void:
	_hand_base_scale = hand_sprite.scale
	_damage_area_base_scale = damage_area.scale
	_damage_area_base_position = damage_area.position
	damage_area.area_entered.connect(_on_damage_area_entered)
	_set_damage_enabled(false)
	hand_sprite.visible = false
	hand_sprite.play("slam")
	if attack_out_sprite != null:
		attack_out_sprite.visible = false
		attack_out_sprite.play("out")
	call_deferred("_attack_loop")


func _attack_loop() -> void:
	if initial_attack_delay > 0.0:
		await get_tree().create_timer(initial_attack_delay).timeout

	while is_inside_tree() and not _attacks_stopped:
		await get_tree().create_timer(randf_range(min_attack_interval, max_attack_interval)).timeout
		if _attacks_stopped:
			break
		if _next_attack_is_sweep:
			await _sweep_once()
		else:
			await _slam_once()
		_next_attack_is_sweep = not _next_attack_is_sweep


func _slam_once() -> void:
	if _is_attacking or _attacks_stopped:
		return

	_is_attacking = true
	_hit_targets.clear()
	damage_area.position = slam_damage_position
	damage_area.scale = _damage_area_base_scale

	var warning_position := _get_target_position()
	var impact_position := Vector2(warning_position.x, ground_y)
	global_position = warning_position + warning_offset
	hand_sprite.visible = true
	hand_sprite.frame = 0
	hand_sprite.stop()

	await get_tree().create_timer(warn_time).timeout
	if _attacks_stopped:
		_finish_stopped_attack()
		return

	hand_sprite.play("slam")
	hand_sprite.speed_scale = 1.0
	if attack_out_sprite != null:
		attack_out_sprite.visible = true
		attack_out_sprite.frame = 0
		attack_out_sprite.play("out")

	_set_damage_enabled(true)
	await get_tree().physics_frame
	_damage_current_overlaps()
	var tween := create_tween()
	tween.tween_property(self, "global_position", impact_position, fall_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	while tween.is_running():
		await get_tree().physics_frame
		if _attacks_stopped:
			_finish_stopped_attack()
			return
		_damage_current_overlaps()
	if _attacks_stopped:
		_finish_stopped_attack()
		return

	hand_sprite.frame = 2
	_damage_current_overlaps()
	_start_camera_shake()
	await get_tree().create_timer(hit_time).timeout
	_set_damage_enabled(false)

	var recover_tween := create_tween()
	recover_tween.tween_property(self, "modulate:a", 0.0, recover_time * 0.6)
	await recover_tween.finished

	hand_sprite.visible = false
	if attack_out_sprite != null:
		attack_out_sprite.visible = false
	damage_area.position = _damage_area_base_position
	damage_area.scale = _damage_area_base_scale
	modulate.a = 1.0
	_is_attacking = false


func _sweep_once() -> void:
	if _is_attacking or _attacks_stopped:
		return

	_is_attacking = true
	_hit_targets.clear()
	global_position = Vector2(sweep_start_x, sweep_y)
	hand_sprite.visible = true
	hand_sprite.flip_h = true
	hand_sprite.scale = _hand_base_scale * sweep_sprite_scale_multiplier
	damage_area.position = sweep_damage_position
	damage_area.scale = _damage_area_base_scale * sweep_damage_scale_multiplier
	hand_sprite.frame = 0
	hand_sprite.speed_scale = sweep_animation_speed_scale
	hand_sprite.play("slam")

	await get_tree().create_timer(sweep_warn_time).timeout
	if _attacks_stopped:
		_finish_stopped_attack()
		return

	_set_damage_enabled(true)
	await get_tree().physics_frame
	_damage_current_overlaps()

	var tween := create_tween()
	tween.tween_property(self, "global_position", Vector2(sweep_end_x, sweep_y), sweep_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	while tween.is_running():
		await get_tree().physics_frame
		if _attacks_stopped:
			_finish_stopped_attack()
			return
		_damage_current_overlaps()

	_damage_current_overlaps()
	_set_damage_enabled(false)
	_start_camera_shake()

	var recover_tween := create_tween()
	recover_tween.tween_property(self, "modulate:a", 0.0, recover_time * 0.6)
	await recover_tween.finished

	hand_sprite.visible = false
	hand_sprite.flip_h = false
	hand_sprite.scale = _hand_base_scale
	damage_area.scale = _damage_area_base_scale
	hand_sprite.speed_scale = 1.0
	modulate.a = 1.0
	_is_attacking = false


func stop_attacks() -> void:
	_attacks_stopped = true
	_finish_stopped_attack()


func _finish_stopped_attack() -> void:
	_set_damage_enabled(false)
	hand_sprite.visible = false
	hand_sprite.flip_h = false
	hand_sprite.scale = _hand_base_scale
	damage_area.scale = _damage_area_base_scale
	hand_sprite.speed_scale = 1.0
	if attack_out_sprite != null:
		attack_out_sprite.visible = false
	modulate.a = 1.0
	_is_attacking = false


func _get_target_position() -> Vector2:
	return Vector2(_get_target_x(), attack_y)


func _get_target_x() -> float:
	var player := get_tree().get_first_node_in_group("player")
	if player is Node2D:
		return clampf(player.global_position.x, min_x, max_x)
	return clampf(global_position.x, min_x, max_x)


func _set_damage_enabled(enabled: bool) -> void:
	damage_area.set_deferred("monitoring", enabled)
	damage_shape.set_deferred("disabled", not enabled)


func _on_damage_area_entered(area: Area2D) -> void:
	if not _is_attacking:
		return

	_damage_target(area)


func _damage_current_overlaps() -> void:
	for area in damage_area.get_overlapping_areas():
		_damage_target(area)

	var player := get_tree().get_first_node_in_group("player")
	if player is Node2D:
		for area in damage_area.get_overlapping_areas():
			if area == player or area.is_ancestor_of(player) or player.is_ancestor_of(area):
				_damage_target(area)
				return


func _damage_target(target: Node) -> void:
	var receiver := _find_damage_receiver(target)
	if receiver == null:
		return

	var instance_id := int(receiver.get_instance_id())
	if _hit_targets.has(instance_id):
		return

	_hit_targets[instance_id] = true
	receiver.call("take_damage", damage, global_position)


func _find_damage_receiver(target: Node) -> Node:
	var current := target
	while current != null:
		if current.has_method("take_damage"):
			return current
		current = current.get_parent()
	return null


func _start_camera_shake() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("_start_camera_shake"):
		player.call("_start_camera_shake", 0.28, 10.0)
