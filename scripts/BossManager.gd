extends Node2D

signal boss_health_changed(current: int, maximum: int)
signal boss_defeated

@export var max_health := 100
@export var phase_two_threshold := 60
@export var core_open_duration := 6.0
@export var tentacle_respawn_delay := 1.2
@export var wire_round_count := 3
@export var wire_round_time := 15.0
@export var wire_round_cooldown := 3.0
@export var lightning_strike_count := 3
@export var lightning_strike_interval := 0.8
@export var debug_start_phase_two := false
@export var electric_wire_scene: PackedScene
@export var lightning_area_scene: PackedScene
@export var tentacles_path: NodePath
@export var boss_core_path: NodePath
@export var boss_body_path: NodePath
@export var wire_spawn_points_path: NodePath
@export var lightning_spawn_points_path: NodePath

var health := 0
var phase := 1
var boss_dead := false
var core_open := false
var active_wires: Array[Node] = []
var wire_round_running := false
var phase_two_started := false

@onready var tentacles_root: Node = get_node_or_null(tentacles_path)
@onready var boss_core: Node = get_node_or_null(boss_core_path)
@onready var boss_body: CanvasItem = get_node_or_null(boss_body_path) as CanvasItem
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
	print("Boss HP: %d / %d" % [health, max_health])
	boss_health_changed.emit(health, max_health)
	if health <= 0:
		_die()
		return

	if phase == 1 and health <= phase_two_threshold:
		_enter_phase_two()


func trigger_lightning(strike_position: Variant = null) -> void:
	if boss_dead or lightning_area_scene == null:
		return

	var lightning: Node = lightning_area_scene.instantiate()
	add_child(lightning)
	if lightning is Node2D:
		var target_position := _pick_spawn_position(lightning_spawn_points)
		if strike_position is Vector2:
			target_position = strike_position
		(lightning as Node2D).global_position = target_position


func _open_core() -> void:
	core_open = true
	_set_tentacles_active(false)
	_set_boss_body_core_open(true)
	if boss_core != null and boss_core.has_method("open_core"):
		boss_core.call("open_core")

	await get_tree().create_timer(core_open_duration).timeout
	if not boss_dead:
		_close_core_and_respawn()


func _close_core_and_respawn() -> void:
	core_open = false
	_set_boss_body_core_open(false)
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


func _set_boss_body_core_open(is_core_open: bool) -> void:
	if boss_body != null:
		if is_core_open:
			boss_body.modulate = Color(0.45, 0.45, 0.45, 0.65)
		else:
			boss_body.modulate = Color(1.0, 1.0, 1.0, 0.75)
	if boss_body is AnimatedSprite2D:
		var boss_sprite := boss_body as AnimatedSprite2D
		if is_core_open:
			boss_sprite.play("core_open")
		else:
			boss_sprite.play("idle")


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
	if phase_two_started:
		return
	phase = 2
	phase_two_started = true
	print("Boss phase 2 started")
	call_deferred("_start_wire_round_loop")


func _start_wire_round_loop() -> void:
	while is_inside_tree() and phase_two_started and not boss_dead:
		await _run_wire_round()
		if boss_dead:
			return
		await get_tree().create_timer(wire_round_cooldown).timeout


func _run_wire_round() -> void:
	if boss_dead or electric_wire_scene == null:
		return

	wire_round_running = true
	active_wires.clear()
	_spawn_wire_round()

	var elapsed := 0.0
	while elapsed < wire_round_time and not boss_dead:
		_clean_active_wires()
		if active_wires.is_empty():
			print("Wire round cleared")
			wire_round_running = false
			return
		var wait_time := minf(0.1, wire_round_time - elapsed)
		await get_tree().create_timer(wait_time).timeout
		elapsed += wait_time

	if boss_dead:
		return

	_clean_active_wires()
	if not active_wires.is_empty():
		for wire in active_wires:
			if is_instance_valid(wire):
				wire.queue_free()
		active_wires.clear()
		await _start_lightning_sequence()

	wire_round_running = false


func _spawn_wire_round() -> void:
	if electric_wire_scene == null:
		return
	var points := _get_spawn_points(wire_spawn_points)
	points.shuffle()
	var count: int = mini(wire_round_count, points.size())

	for i in range(count):
		var spawn_point := points[i]
		var wire: Node = electric_wire_scene.instantiate()
		if wire.has_method("set_manager"):
			wire.call("set_manager", self)
		add_child(wire)
		active_wires.append(wire)
		if wire is Node2D:
			(wire as Node2D).global_position = spawn_point.global_position
			(wire as Node2D).global_rotation = spawn_point.global_rotation


func on_wire_destroyed(wire: Node) -> void:
	active_wires.erase(wire)
	if wire_round_running and active_wires.is_empty():
		print("Wire round cleared")
		wire_round_running = false


func _start_lightning_sequence() -> void:
	if boss_dead:
		return
	for i in range(lightning_strike_count):
		if boss_dead:
			return
		trigger_lightning()
		await get_tree().create_timer(lightning_strike_interval).timeout


func _clean_active_wires() -> void:
	var remaining_wires: Array[Node] = []
	for wire in active_wires:
		if is_instance_valid(wire):
			remaining_wires.append(wire)
	active_wires = remaining_wires


func _get_spawn_points(points_root: Node) -> Array[Node2D]:
	var points: Array[Node2D] = []
	if points_root == null:
		return points
	for child in points_root.get_children():
		if child is Node2D:
			points.append(child as Node2D)
	return points


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
	phase_two_started = false
	wire_round_running = false
	core_open = false
	for wire in active_wires:
		if is_instance_valid(wire):
			wire.queue_free()
	active_wires.clear()
	_set_tentacles_active(false)
	if boss_core != null and boss_core.has_method("close_core"):
		boss_core.call("close_core")
	if boss_body != null:
		boss_body.visible = false
	boss_defeated.emit()
