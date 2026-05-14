extends Node

signal controls_changed

const SAVE_PATH := "user://input_settings.cfg"
const ACTIONS := [
	{"action": "move_up", "label": "上"},
	{"action": "move_down", "label": "下"},
	{"action": "move_left", "label": "左"},
	{"action": "move_right", "label": "右"},
	{"action": "jump", "label": "跳躍"},
	{"action": "attack", "label": "攻擊"},
	{"action": "dash", "label": "衝刺"},
	{"action": "far_attack", "label": "遠攻"},
	{"action": "interact", "label": "互動 / 藥水"},
	{"action": "map", "label": "地圖"},
	{"action": "inventory", "label": "物品欄"},
	{"action": "audio_settings", "label": "聲音"},
]

var _loaded := false


func _ready() -> void:
	load_bindings()


func get_actions() -> Array:
	return ACTIONS


func get_label_for_action(action: String) -> String:
	var input := InputHelper.get_keyboard_input_for_action(action)
	if input == null:
		return "-"
	return InputHelper.get_label_for_input(input)


func rebind_keyboard_action(action: String, event: InputEventKey) -> Error:
	if not InputMap.has_action(action):
		return ERR_DOES_NOT_EXIST

	var next_event := event.duplicate()
	next_event.pressed = false
	next_event.echo = false
	var result: Error = InputHelper.set_keyboard_input_for_action(action, next_event, false)
	if result == OK:
		save_bindings()
		controls_changed.emit()
	return result


func reset_to_defaults() -> void:
	InputHelper.reset_all_actions()
	save_bindings()
	controls_changed.emit()


func save_bindings() -> void:
	var action_names := PackedStringArray()
	for item in ACTIONS:
		action_names.append(String(item["action"]))

	var config := ConfigFile.new()
	config.set_value("input", "bindings", InputHelper.serialize_inputs_for_actions(action_names))
	config.save(SAVE_PATH)


func load_bindings() -> void:
	if _loaded:
		return
	_loaded = true

	if not FileAccess.file_exists(SAVE_PATH):
		return

	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return

	var bindings := String(config.get_value("input", "bindings", ""))
	if bindings == "":
		return

	InputHelper.deserialize_inputs_for_actions(bindings)
	controls_changed.emit()
