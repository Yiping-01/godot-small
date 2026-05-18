extends Node2D

signal boss_health_changed(current: int, maximum: int)
signal boss_defeated

@export var max_health := 100
@export var phase_two_threshold := 60
@export var core_open_duration := 6.0
@export var tentacle_respawn_delay := 1.2
@export var wire_spawn_min_delay := 5.0
@export var wire_spawn_max_delay := 9.0
@export var debug_start_phase_two := false
@export var electric_wire_scene: PackedScene
@export var lightning_area_scene: PackedScene
@export var tentacles_path: NodePath
@export var boss_core_path: NodePath
@export var wire_spawn_points_path: NodePath
@export var lightning_spawn_points_path: NodePath

var health := 0
var phase := 1
var boss_dead := false
var core_open := false
var _wire_loop_running := false

@onready var tentacles_root: Node = get_node_or_null(tentacles_path)
@onready var boss_core: Node = get_node_or_null(boss_core_path)
@onready var wire_spawn_points: Node = get_node_or_null(wire_spawn_points_path)
@onready var lightning_spawn_points: Node = get_node_or_null(lightning_spawn_points_path)


func _ready() -> void:
	health = max_health
	_connect_tentacles()
	if boss_core != null and boss_core.has_method("set_manager"):
		boss_core.call("set_manager", self)
	if boss_core != null and boss_core.has_method("close_core"):
		boss_core.call("close_core")
	_respawn_tentacles()
	boss_health_changed.emit(health, max_health)
	if debug_start_phase_two:
		call_deferred("_enter_phase_two")


func on_tentacle_died(_tentacle: Node) -> void:
	if boss_dead or core_open:
		return
	if _all_tentacles_dead():
		await get_tree().create_timer(tentacle_respawn_delay).timeout
		if not boss_dead:
			_open_core()


func damage_boss(amount: int) -> void:
	if boss_dead or not core_open:
		return

	health = maxi(health - amount, 0)
	boss_health_changed.emit(health, max_health)
	if health <= 0:
		_die()
		return

	if phase == 1 and health <= phase_two_threshold:
		_enter_phase_two()


func trigger_lightning(strike_position: Vector2 = Vector2.ZERO) -> void:
	if boss_dead or lightning_area_scene == null:
		return

	var lightning: Node = lightning_area_scene.instantiate()
	add_child(lightning)
	if lightning is Node2D:
		if strike_position == Vector2.ZERO:
			strike_position = _pick_spawn_position(lightning_spawn_points)
		(lightning as Node2D).global_position = strike_position


func _open_core() -> void:
	core_open = true
	_set_tentacles_active(false)
	if boss_core != null and boss_core.has_method("open_core"):
		boss_core.call("open_core")

	await get_tree().create_timer(core_open_duration).timeout
	if not boss_dead:
		_close_core_and_respawn()


func _close_core_and_respawn() -> void:
	core_open = false
	if boss_core != null and boss_core.has_method("close_core"):
		boss_core.call("close_core")
	_respawn_tentacles()


func _respawn_tentacles() -> void:
	if tentacles_root == null:
		return
	for child in tentacles_root.get_children():
		if child.has_method("set_manager"):
			child.call("set_manager", self)
		if child.has_method("respawn"):
			child.call("respawn")


func _set_tentacles_active(active: bool) -> void:
	if tentacles_root == null:
		return
	for child in tentacles_root.get_children():
		if child.has_method("set_active"):
			child.call("set_active", active)


func _connect_tentacles() -> void:
	if tentacles_root == null:
		return
	for child in tentacles_root.get_children():
		if child.has_method("set_manager"):
			child.call("set_manager", self)


func _all_tentacles_dead() -> bool:
	if tentacles_root == null:
		return true
	for child in tentacles_root.get_children():
		if child.has_method("is_dead") and not bool(child.call("is_dead")):
			return false
	return true


func _enter_phase_two() -> void:
	phase = 2
	_spawn_wire()
	if not _wire_loop_running:
		_wire_loop_running = true
		call_deferred("_wire_spawn_loop")


func _wire_spawn_loop() -> void:
	while is_inside_tree() and not boss_dead and phase >= 2:
		await get_tree().create_timer(randf_range(wire_spawn_min_delay, wire_spawn_max_delay)).timeout
		if boss_dead or phase < 2:
			break
		_spawn_wire()


func _spawn_wire() -> void:
	if electric_wire_scene == null:
		return
	var wire: Node = electric_wire_scene.instantiate()
	if wire.has_method("set_manager"):
		wire.call("set_manager", self)
	add_child(wire)
	if wire is Node2D:
		var spawn_point := _pick_spawn_point(wire_spawn_points)
		if spawn_point != null:
			(wire as Node2D).global_position = spawn_point.global_position
			(wire as Node2D).global_rotation = spawn_point.global_rotation
		else:
			(wire as Node2D).global_position = global_position


func _pick_spawn_position(points_root: Node) -> Vector2:
	if points_root == null or points_root.get_child_count() == 0:
		return global_position
	var candidates: Array = points_root.get_children()
	var point: Node = candidates.pick_random()
	if point is Node2D:
		return (point as Node2D).global_position
	return global_position


func _pick_spawn_point(points_root: Node) -> Node2D:
	if points_root == null or points_root.get_child_count() == 0:
		return null
	var candidates: Array = points_root.get_children()
	var picked_node: Node = candidates.pick_random()
	if picked_node is Node2D:
		return picked_node as Node2D
	return null


func _die() -> void:
	boss_dead = true
	core_open = false
	_set_tentacles_active(false)
	if boss_core != null and boss_core.has_method("close_core"):
		boss_core.call("close_core")
	boss_defeated.emit()
