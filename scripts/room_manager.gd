extends Node2D
class_name RoomManager

@export var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
@export var respawn_on_room_transition := true

var enemy_spawns: Array[Dictionary] = []


func _ready() -> void:
	add_to_group("room_manager")
	_record_enemy_spawns()
	call_deferred("_record_enemy_spawns_if_empty")


func _record_enemy_spawns() -> void:
	enemy_spawns.clear()
	for enemy in _find_scene_enemies():
		if enemy is Node2D:
			var max_health_value: Variant = enemy.get("max_health")
			var patrol_value: Variant = enemy.get("patrol_speed")
			var speed_value: Variant = enemy.get("speed")
			var patrol_distance_value: Variant = enemy.get("patrol_distance")
			var hp_value: Variant = enemy.get("hp")
			var behavior_mode_value: Variant = enemy.get("behavior_mode")
			var bounce_velocity_value: Variant = enemy.get("bounce_velocity")
			var bounce_min_value: Variant = enemy.get("bounce_min")
			var bounce_max_value: Variant = enemy.get("bounce_max")
			var respawn_scene_path_value: Variant = enemy.get("respawn_scene_path")
			var scene_path := String(respawn_scene_path_value) if respawn_scene_path_value != null else enemy.scene_file_path
			if scene_path == "":
				scene_path = enemy_scene.resource_path
			enemy_spawns.append({
				"parent": enemy.get_parent(),
				"position": enemy.global_position,
				"scale": enemy.scale,
				"scene_path": scene_path,
				"max_health": int(max_health_value) if max_health_value != null else 1,
				"patrol_speed": float(patrol_value) if patrol_value != null else 120.0,
				"speed": float(speed_value) if speed_value != null else 120.0,
				"patrol_distance": float(patrol_distance_value) if patrol_distance_value != null else 120.0,
				"hp": int(hp_value) if hp_value != null else 1,
				"behavior_mode": String(behavior_mode_value) if behavior_mode_value != null else "",
				"bounce_velocity": bounce_velocity_value,
				"bounce_min": bounce_min_value,
				"bounce_max": bounce_max_value,
			})


func _record_enemy_spawns_if_empty() -> void:
	if enemy_spawns.is_empty():
		_record_enemy_spawns()


func _find_scene_enemies() -> Array[Node]:
	var enemies: Array[Node] = []
	_collect_scene_enemies(self, enemies)
	return enemies


func _collect_scene_enemies(node: Node, enemies: Array[Node]) -> void:
	for child in node.get_children():
		if _is_respawnable_enemy(child):
			enemies.append(child)
		_collect_scene_enemies(child, enemies)


func _is_respawnable_enemy(node: Node) -> bool:
	if node.is_in_group("enemy"):
		return true

	var scene_path := node.scene_file_path
	if scene_path in [
		"res://scenes/enemy.tscn",
		"res://scenes/enemy2.tscn",
		"res://scenes/legacy_split_enemy.tscn",
		"res://scenes/blue_bounce_split_enemy.tscn",
		"res://scenes/blue_bounce_small_enemy.tscn",
		"res://scenes/squid_monster.tscn",
	]:
		return true

	var script: Variant = node.get_script()
	if script is Script:
		var script_path: String = script.resource_path
		return script_path in [
			"res://scripts/enemy.gd",
			"res://scripts/enemy2.gd",
			"res://scripts/legacy_split_enemy.gd",
			"res://scripts/blue_bounce_split_enemy.gd",
			"res://scripts/blue_bounce_small_enemy.gd",
			"res://scripts/squid_monster.gd",
		]

	return false


func respawn_enemies() -> void:
	if enemy_spawns.is_empty():
		_record_enemy_spawns()
	if enemy_spawns.is_empty():
		return

	for enemy in _find_scene_enemies():
		if is_instance_valid(enemy):
			enemy.queue_free()

	await get_tree().process_frame

	for spawn in enemy_spawns:
		var parent: Node = spawn["parent"]
		if parent == null or not is_instance_valid(parent):
			parent = self

		var spawn_scene := enemy_scene
		var scene_path := String(spawn.get("scene_path", ""))
		if scene_path != "":
			var loaded_scene := load(scene_path)
			if loaded_scene is PackedScene:
				spawn_scene = loaded_scene

		var enemy := spawn_scene.instantiate()
		if enemy.get("max_health") != null:
			enemy.set("max_health", int(spawn["max_health"]))
		if enemy.get("patrol_speed") != null:
			enemy.set("patrol_speed", float(spawn["patrol_speed"]))
		if enemy.get("speed") != null:
			enemy.set("speed", float(spawn["speed"]))
		if enemy.get("patrol_distance") != null:
			enemy.set("patrol_distance", float(spawn["patrol_distance"]))
		if enemy.get("hp") != null:
			enemy.set("hp", int(spawn["hp"]))
		if enemy.get("behavior_mode") != null and String(spawn["behavior_mode"]) != "":
			enemy.set("behavior_mode", String(spawn["behavior_mode"]))
		if enemy.get("bounce_velocity") != null and spawn["bounce_velocity"] is Vector2:
			enemy.set("bounce_velocity", spawn["bounce_velocity"])
		if enemy.get("bounce_min") != null and spawn["bounce_min"] is Vector2:
			enemy.set("bounce_min", spawn["bounce_min"])
		if enemy.get("bounce_max") != null and spawn["bounce_max"] is Vector2:
			enemy.set("bounce_max", spawn["bounce_max"])
		if enemy is Node2D:
			var spawn_position: Vector2 = spawn["position"]
			enemy.scale = spawn["scale"]
			if parent is Node2D:
				enemy.position = parent.to_local(spawn_position)
			else:
				enemy.global_position = spawn_position
		parent.add_child(enemy)


func on_room_transition() -> void:
	if respawn_on_room_transition:
		respawn_enemies()
