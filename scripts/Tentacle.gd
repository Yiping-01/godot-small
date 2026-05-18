extends Area2D

@export var max_health := 2
@export var damage := 1
@export var touch_damage := 1
@export var attack_interval_min := 2.5
@export var attack_interval_max := 5.0
@export var attack_warning_time := 0.8
@export var attack_active_time := 0.45
@export var top_tentacle := false
@export var top_visible_time := 2.2
@export var top_hidden_time_min := 1.5
@export var top_hidden_time_max := 3.0
@export var timed_cycle_enabled := false
@export var timed_cycle_hidden_time := 5.0
@export var timed_cycle_idle_time := 8.0
@export var warning_color := Color(1.0, 0.25, 0.15, 0.45)
@export var active_color := Color(1.0, 0.1, 0.05, 0.75)
@export var attack_visual_tint := true
@export var align_attack_visual_to_visual := false
@export var hide_visual_during_attack := false

var health := 0
var manager: Node
var _dead := false
var _active := true
var _hit_targets := {}
var _touch_targets := {}
var _flash_tween: Tween
var _cycle_version := 0

@onready var visual: CanvasItem = get_node_or_null("Visual") as CanvasItem
@onready var attack_area: Area2D = get_node_or_null("AttackArea") as Area2D
@onready var attack_visual: CanvasItem = get_node_or_null("AttackWarning") as CanvasItem
@onready var fan_warning_visual: CanvasItem = get_node_or_null("FanWarning") as CanvasItem
@onready var corner_attack_visual: CanvasItem = get_node_or_null("CornerAttack") as CanvasItem
@onready var attack_shape: Node = _get_attack_collision_node()


func _ready() -> void:
	health = max_health
	collision_layer = 4
	collision_mask = 16
	if not area_entered.is_connected(_on_touch_area_entered):
		area_entered.connect(_on_touch_area_entered)
	if not area_exited.is_connected(_on_touch_area_exited):
		area_exited.connect(_on_touch_area_exited)
	if attack_area != null:
		attack_area.collision_layer = 32
		attack_area.collision_mask = 16
		attack_area.monitoring = false
		attack_area.area_entered.connect(_on_attack_area_entered)
	if attack_shape != null:
		attack_shape.set("disabled", true)
	if attack_visual != null:
		attack_visual.visible = false
	if corner_attack_visual != null:
		corner_attack_visual.visible = false
	call_deferred("_attack_loop")
	if timed_cycle_enabled:
		_set_body_visible(false)
		_start_timed_cycle()
	if top_tentacle and not timed_cycle_enabled:
		call_deferred("_top_visibility_loop")


func set_manager(new_manager: Node) -> void:
	manager = new_manager


func respawn() -> void:
	_cycle_version += 1
	health = max_health
	_dead = false
	_active = true
	_touch_targets.clear()
	_set_body_visible(not timed_cycle_enabled)
	if visual != null:
		visual.modulate = Color.WHITE
	if attack_visual != null:
		attack_visual.visible = false
	if corner_attack_visual != null:
		corner_attack_visual.visible = false
	_set_attack_enabled(false)
	if timed_cycle_enabled:
		_start_timed_cycle()


func set_active(active: bool) -> void:
	_active = active
	if not active:
		_set_attack_enabled(false)
		_hide_attack_visual()
		_hide_corner_attack_visual()
	if timed_cycle_enabled:
		if not active or _dead:
			_set_body_visible(false)
	else:
		_set_body_visible(active and not _dead)


func is_dead() -> bool:
	return _dead


func take_damage(amount: int, _from_position: Vector2 = Vector2.ZERO) -> void:
	if _dead or not _active:
		return

	health -= amount
	if health > 0:
		_flash_hit()
		return

	_die()


func _die() -> void:
	_dead = true
	_active = false
	_cycle_version += 1
	_touch_targets.clear()
	_set_attack_enabled(false)
	_hide_attack_visual()
	_hide_corner_attack_visual()
	_set_body_visible(false)
	if manager != null and manager.has_method("on_tentacle_died"):
		manager.call("on_tentacle_died", self)


func _attack_loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(randf_range(attack_interval_min, attack_interval_max)).timeout
		if _active and not _dead and visible:
			await _attack_once()


func _attack_once() -> void:
	if attack_visual == null:
		return
	_hit_targets.clear()
	_show_attack_warning()

	await get_tree().create_timer(attack_warning_time).timeout
	if _dead or not _active or not visible:
		_hide_attack_visual()
		return

	_activate_attack_visual()
	_set_attack_enabled(true)
	await get_tree().physics_frame
	_damage_current_overlaps()
	await get_tree().create_timer(attack_active_time).timeout
	_set_attack_enabled(false)
	_hide_attack_visual()


func _top_visibility_loop() -> void:
	while is_inside_tree():
		if _dead or not _active:
			await get_tree().create_timer(0.5).timeout
			continue
		visible = true
		monitorable = true
		monitoring = true
		await get_tree().create_timer(top_visible_time).timeout
		if _dead:
			continue
		_set_attack_enabled(false)
		visible = false
		monitorable = false
		monitoring = false
		await get_tree().create_timer(randf_range(top_hidden_time_min, top_hidden_time_max)).timeout


func _start_timed_cycle() -> void:
	var cycle_token := _cycle_version
	call_deferred("_timed_cycle_loop", cycle_token)


func _timed_cycle_loop(cycle_token: int) -> void:
	while is_inside_tree():
		if cycle_token != _cycle_version or _dead:
			return
		if not _active:
			_set_body_visible(false)
			await get_tree().create_timer(0.5).timeout
			continue

		_set_body_visible(false)
		await get_tree().create_timer(timed_cycle_hidden_time).timeout
		if cycle_token != _cycle_version or _dead:
			return
		if not _active:
			continue

		_set_body_visible(true)
		await get_tree().create_timer(timed_cycle_idle_time).timeout
		if cycle_token != _cycle_version or _dead:
			return
		if _active and visible:
			if corner_attack_visual != null:
				await _corner_attack_once()
			else:
				await _attack_once()
		if cycle_token != _cycle_version or _dead:
			return

		_set_attack_enabled(false)
		_hide_attack_visual()
		_hide_corner_attack_visual()
		_set_body_visible(false)
		await get_tree().create_timer(timed_cycle_hidden_time).timeout


func _set_attack_enabled(enabled: bool) -> void:
	if attack_area != null:
		attack_area.set_deferred("monitoring", enabled)
	if attack_shape != null:
		attack_shape.set_deferred("disabled", not enabled)


func _set_body_visible(body_visible: bool) -> void:
	visible = body_visible
	monitorable = body_visible
	monitoring = body_visible


func _on_attack_area_entered(area: Area2D) -> void:
	if _dead or not _active:
		return
	_damage_target(area)


func _on_touch_area_entered(area: Area2D) -> void:
	if _dead or not _active:
		return
	var receiver := _find_damage_receiver(area)
	if receiver == null:
		return
	var instance_id := int(receiver.get_instance_id())
	if _touch_targets.has(instance_id):
		return
	_touch_targets[instance_id] = true
	receiver.call("take_damage", touch_damage, global_position)


func _on_touch_area_exited(area: Area2D) -> void:
	var receiver := _find_damage_receiver(area)
	if receiver == null:
		return
	_touch_targets.erase(int(receiver.get_instance_id()))


func _damage_current_overlaps() -> void:
	if attack_area == null:
		return
	for area in attack_area.get_overlapping_areas():
		_damage_target(area)


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


func _flash_hit() -> void:
	if visual == null:
		return
	if _flash_tween != null:
		_flash_tween.kill()
	visual.modulate = Color.WHITE * 2.0
	_flash_tween = create_tween()
	_flash_tween.tween_property(visual, "modulate", Color.WHITE, 0.12)


func _get_attack_collision_node() -> Node:
	var shape := get_node_or_null("AttackArea/CollisionShape2D")
	if shape != null:
		return shape
	return get_node_or_null("AttackArea/CollisionPolygon2D")


func _show_attack_warning() -> void:
	if fan_warning_visual != null:
		fan_warning_visual.visible = true
		fan_warning_visual.modulate = warning_color
	if attack_visual == null:
		return
	attack_visual.visible = true
	attack_visual.modulate = warning_color if attack_visual_tint else Color.WHITE
	if attack_visual is AnimatedSprite2D:
		var warning_sprite := attack_visual as AnimatedSprite2D
		warning_sprite.stop()
		warning_sprite.frame = 0


func _activate_attack_visual() -> void:
	if fan_warning_visual != null:
		fan_warning_visual.visible = true
		fan_warning_visual.modulate = active_color
	if attack_visual == null:
		return
	attack_visual.modulate = active_color if attack_visual_tint else Color.WHITE
	if attack_visual is AnimatedSprite2D:
		var active_sprite := attack_visual as AnimatedSprite2D
		active_sprite.frame = 0
		active_sprite.play("attack")


func _hide_attack_visual() -> void:
	if fan_warning_visual != null:
		fan_warning_visual.visible = false
	if attack_visual == null:
		return
	if attack_visual is AnimatedSprite2D:
		var hidden_sprite := attack_visual as AnimatedSprite2D
		hidden_sprite.stop()
	attack_visual.visible = false


func _align_attack_visual() -> void:
	if not align_attack_visual_to_visual:
		return
	if visual == null or attack_visual == null:
		return
	if visual is Node2D and attack_visual is Node2D:
		var visual_node := visual as Node2D
		var attack_node := attack_visual as Node2D
		attack_node.position = visual_node.position
		attack_node.rotation = visual_node.rotation
		attack_node.scale = visual_node.scale


func _corner_attack_once() -> void:
	if corner_attack_visual == null:
		return
	_align_corner_attack_visual()
	if hide_visual_during_attack and visual != null:
		visual.visible = false
	corner_attack_visual.visible = true
	corner_attack_visual.modulate = Color.WHITE
	if corner_attack_visual is AnimatedSprite2D:
		var corner_sprite := corner_attack_visual as AnimatedSprite2D
		corner_sprite.frame = 0
		corner_sprite.play("attack")
	await get_tree().create_timer(attack_active_time).timeout
	_hide_corner_attack_visual()


func _hide_corner_attack_visual() -> void:
	if corner_attack_visual != null:
		if corner_attack_visual is AnimatedSprite2D:
			var corner_sprite := corner_attack_visual as AnimatedSprite2D
			corner_sprite.stop()
		corner_attack_visual.visible = false
	if hide_visual_during_attack and visual != null and visible and not _dead:
		visual.visible = true


func _align_corner_attack_visual() -> void:
	if not align_attack_visual_to_visual:
		return
	if visual == null or corner_attack_visual == null:
		return
	if visual is Node2D and corner_attack_visual is Node2D:
		var visual_node := visual as Node2D
		var corner_node := corner_attack_visual as Node2D
		corner_node.position = visual_node.position
		corner_node.rotation = visual_node.rotation
		corner_node.scale = visual_node.scale
