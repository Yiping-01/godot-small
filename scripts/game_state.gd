extends Node

signal currency_changed(amount: int)
signal inventory_changed(items: Dictionary)
signal health_potions_changed(amount: int)
signal input_lock_changed(locked: bool)
signal first_item_obtained(item_name: String)
signal map_room_changed(scene_path: String, room_id: String)

const SAVE_PATH := "user://save.cfg"
const CONTINUE_SCENE_SAVE_PATH := "user://continue_scene.cfg"
const DEFAULT_START_SCENE := "res://scenes/test_level.tscn"
const HEALTH_POTION_ITEM := "Health Potion"
const STARTING_HEALTH_POTIONS := 3
const STARTER_ITEM := "旅行者筆記"

var demo_start_fresh := true
var load_save_on_start := false

var currency: int = 0
var inventory: Dictionary = {
	STARTER_ITEM: 1,
	HEALTH_POTION_ITEM: STARTING_HEALTH_POTIONS,
}
var item_database: Dictionary = {
	HEALTH_POTION_ITEM: {
		"display_name": "生命藥水",
		"description": "按下E鍵回復生命",
	},
	STARTER_ITEM: {
		"display_name": "旅行者筆記",
		"description": "一份簡單的冒險紀錄，用來提醒你目前學過的操作。",
	},
	"粗糙護符": {
		"display_name": "粗糙護符",
		"description": "商人販售的暫時道具，目前只會收進背包。",
	},
	"生命碎片": {
		"display_name": "生命碎片",
		"description": "暫時的血量道具，之後可以改成提升最大生命。",
	},
	"破舊地圖": {
		"display_name": "破舊地圖",
		"description": "記錄附近房間配置的道具，之後可接上地圖 UI。",
	},
}
var input_locked := false
var has_shown_inventory_tutorial := false
var saved_respawn_position := Vector2.ZERO
var has_saved_respawn := false
var pending_spawn_position := Vector2.ZERO
var has_pending_spawn := false
var pending_spawn_marker_name := ""
var current_map_scene := ""
var current_map_room := ""
var map_rooms: Dictionary = {}
var visited_rooms: Dictionary = {}
var continue_scene_path := DEFAULT_START_SCENE
var continue_player_position := Vector2.ZERO
var has_continue_player_position := false
var continue_spawn_marker_name := ""
var has_continue_spawn_marker := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if demo_start_fresh:
		reset_demo_state()
		load_game()
	currency_changed.emit(currency)
	inventory_changed.emit(inventory)
	health_potions_changed.emit(get_health_potion_count())


func reset_demo_state() -> void:
	currency = 0
	currency_changed.emit(currency)

	inventory = {
		STARTER_ITEM: 1,
		HEALTH_POTION_ITEM: STARTING_HEALTH_POTIONS,
	}
	has_saved_respawn = false
	saved_respawn_position = Vector2.ZERO
	has_pending_spawn = false
	pending_spawn_position = Vector2.ZERO
	pending_spawn_marker_name = ""
	has_shown_inventory_tutorial = false
	input_locked = false
	current_map_scene = ""
	current_map_room = ""
	map_rooms.clear()
	visited_rooms.clear()
	inventory_changed.emit(inventory)
	health_potions_changed.emit(get_health_potion_count())


func set_input_locked(locked: bool) -> void:
	if input_locked == locked:
		return

	input_locked = locked
	input_lock_changed.emit(input_locked)


func add_currency(amount: int) -> void:
	currency = maxi(currency + amount, 0)
	currency_changed.emit(currency)
	save_game()


func spend_currency(amount: int) -> bool:
	if currency < amount:
		return false

	currency -= amount
	currency_changed.emit(currency)
	save_game()
	return true


func add_item(item_name: String, amount: int = 1) -> void:
	var was_empty := inventory.is_empty()
	var had_item := has_item(item_name)
	inventory[item_name] = int(inventory.get(item_name, 0)) + amount
	inventory_changed.emit(inventory)
	if item_name == HEALTH_POTION_ITEM:
		health_potions_changed.emit(get_health_potion_count())

	if was_empty or not had_item:
		first_item_obtained.emit(item_name)


func has_item(item_name: String) -> bool:
	return int(inventory.get(item_name, 0)) > 0


func get_health_potion_count() -> int:
	return int(inventory.get(HEALTH_POTION_ITEM, 0))


func add_health_potions(amount: int) -> void:
	if amount <= 0:
		return

	add_item(HEALTH_POTION_ITEM, amount)
func refill_health_potions() -> void:
	inventory[HEALTH_POTION_ITEM] = STARTING_HEALTH_POTIONS
	inventory_changed.emit(inventory)
	health_potions_changed.emit(get_health_potion_count())


func use_health_potion() -> bool:
	var amount := get_health_potion_count()
	if amount <= 0:
		return false

	amount -= 1
	if amount <= 0:
		inventory.erase(HEALTH_POTION_ITEM)
	else:
		inventory[HEALTH_POTION_ITEM] = amount

	inventory_changed.emit(inventory)
	health_potions_changed.emit(amount)
	save_game()
	return true


func get_item_display_name(item_name: String) -> String:
	var data: Dictionary = item_database.get(item_name, {})
	return String(data.get("display_name", item_name))


func get_item_description(item_name: String) -> String:
	var data: Dictionary = item_database.get(item_name, {})
	return String(data.get("description", "尚未寫入說明。"))


func set_respawn_position(position: Vector2) -> void:
	saved_respawn_position = position
	has_saved_respawn = true


func get_respawn_position(default_position: Vector2) -> Vector2:
	if has_pending_spawn:
		has_pending_spawn = false
		return pending_spawn_position
	if not demo_start_fresh and load_save_on_start and has_saved_respawn:
		return saved_respawn_position
	return default_position


func set_pending_spawn_position(position: Vector2) -> void:
	pending_spawn_position = position
	has_pending_spawn = true
	pending_spawn_marker_name = ""


func set_pending_spawn_marker(marker_name: String) -> void:
	pending_spawn_marker_name = marker_name
	has_pending_spawn = false


func consume_pending_spawn_marker() -> String:
	var marker_name := pending_spawn_marker_name
	pending_spawn_marker_name = ""
	return marker_name


func register_map_room(scene_path: String, room_id: String, display_name: String, map_rect: Rect2, world_rect := Rect2()) -> void:
	if scene_path == "" or room_id == "":
		return

	if not map_rooms.has(scene_path):
		map_rooms[scene_path] = {}

	map_rooms[scene_path][room_id] = {
		"display_name": display_name,
		"rect": map_rect,
		"world_rect": world_rect,
	}


func set_current_map_room(scene_path: String, room_id: String) -> void:
	if scene_path == "" or room_id == "":
		return

	current_map_scene = scene_path
	current_map_room = room_id
	if not visited_rooms.has(scene_path):
		visited_rooms[scene_path] = {}
	visited_rooms[scene_path][room_id] = true
	map_room_changed.emit(scene_path, room_id)


func get_map_rooms(scene_path: String) -> Dictionary:
	return map_rooms.get(scene_path, {})


func is_room_visited(scene_path: String, room_id: String) -> bool:
	return bool(visited_rooms.get(scene_path, {}).get(room_id, false))


func save_game() -> void:
	

	var config := ConfigFile.new()
	config.set_value("player", "currency", currency)
	config.set_value("player", "inventory", inventory)
	config.set_value("player", "has_respawn", has_saved_respawn)
	config.set_value("player", "respawn_position", saved_respawn_position)
	config.save(SAVE_PATH)


func save_continue_scene(scene_path: String, player_position := Vector2.ZERO, has_player_position := false, spawn_marker_name := "") -> void:
	if scene_path == "":
		return

	continue_scene_path = scene_path
	continue_player_position = player_position
	has_continue_player_position = has_player_position
	continue_spawn_marker_name = spawn_marker_name
	has_continue_spawn_marker = spawn_marker_name != ""
	var config := ConfigFile.new()
	config.set_value("continue", "scene_path", continue_scene_path)
	config.set_value("continue", "has_player_position", has_continue_player_position)
	config.set_value("continue", "player_position", continue_player_position)
	config.set_value("continue", "has_spawn_marker", has_continue_spawn_marker)
	config.set_value("continue", "spawn_marker_name", continue_spawn_marker_name)
	config.save(CONTINUE_SCENE_SAVE_PATH)


func load_continue_scene_path() -> String:
	var config := ConfigFile.new()
	var error := config.load(CONTINUE_SCENE_SAVE_PATH)
	if error != OK:
		return DEFAULT_START_SCENE

	continue_scene_path = String(config.get_value("continue", "scene_path", DEFAULT_START_SCENE))
	has_continue_player_position = bool(config.get_value("continue", "has_player_position", false))
	has_continue_spawn_marker = bool(config.get_value("continue", "has_spawn_marker", false))
	continue_spawn_marker_name = String(config.get_value("continue", "spawn_marker_name", ""))
	var loaded_position: Variant = config.get_value("continue", "player_position", Vector2.ZERO)
	if loaded_position is Vector2:
		continue_player_position = loaded_position
	else:
		has_continue_player_position = false

	if continue_scene_path == "":
		continue_scene_path = DEFAULT_START_SCENE
	return continue_scene_path


func prepare_continue_scene() -> String:
	var scene_path := load_continue_scene_path()
	if has_continue_spawn_marker and continue_spawn_marker_name != "":
		set_pending_spawn_marker(continue_spawn_marker_name)
	elif has_continue_player_position:
		set_pending_spawn_position(continue_player_position)
	return scene_path


func has_continue_scene() -> bool:
	return FileAccess.file_exists(CONTINUE_SCENE_SAVE_PATH)


func clear_continue_scene() -> void:
	continue_scene_path = DEFAULT_START_SCENE
	continue_player_position = Vector2.ZERO
	has_continue_player_position = false
	continue_spawn_marker_name = ""
	has_continue_spawn_marker = false
	has_pending_spawn = false
	pending_spawn_position = Vector2.ZERO
	pending_spawn_marker_name = ""
	if FileAccess.file_exists(CONTINUE_SCENE_SAVE_PATH):
		DirAccess.remove_absolute(CONTINUE_SCENE_SAVE_PATH)


func load_game() -> void:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error != OK:
		return

	currency = int(config.get_value("player", "currency", currency))
	var loaded_inventory: Variant = config.get_value("player", "inventory", inventory)
	if loaded_inventory is Dictionary:
		inventory = loaded_inventory

	has_saved_respawn = bool(config.get_value("player", "has_respawn", false))
	var loaded_position: Variant = config.get_value("player", "respawn_position", Vector2.ZERO)
	if loaded_position is Vector2:
		saved_respawn_position = loaded_position
