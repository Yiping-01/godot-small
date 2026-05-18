extends Node

signal controls_changed

const SAVE_PATH := "user://input_settings.cfg"
const FALLBACK_KEYCODES := {
	"move_up": KEY_W,
	"move_down": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"jump": KEY_Z,
	"attack": KEY_X,
	"dash": KEY_C,
	"far_attack": KEY_F,
	"interact": KEY_E,
	"map": KEY_M,
	"inventory": KEY_I,
	"audio_settings": KEY_P,
}
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
	_ensure_required_bindings()


func get_actions() -> Array:
	return ACTIONS


func get_label_for_action(action: String) -> String:
	var input := InputHelper.get_keyboard_input_for_action(action)
	if input == null:
		return "-"
	return InputHelper.get_label_for_input(input)


func format_action_text(text: String) -> String:
	var formatted := text
	for item in ACTIONS:
		var action := String(item["action"])
		formatted = formatted.replace("{%s}" % action, get_label_for_action(action))

	formatted = formatted.replace("按 E", "按 %s" % get_label_for_action("interact"))
	formatted = formatted.replace("按下E", "按下%s" % get_label_for_action("interact"))
	formatted = formatted.replace("E：", "%s：" % get_label_for_action("interact"))

	formatted = formatted.replace("按 I", "按 %s" % get_label_for_action("inventory"))
	formatted = formatted.replace("I 或", "%s 或" % get_label_for_action("inventory"))

	formatted = formatted.replace("按 M", "按 %s" % get_label_for_action("map"))
	formatted = formatted.replace("M 或", "%s 或" % get_label_for_action("map"))

	formatted = formatted.replace("按 Z", "按 %s" % get_label_for_action("jump"))
	formatted = formatted.replace("按下 Z", "按下 %s" % get_label_for_action("jump"))
	formatted = formatted.replace("按下兩下 Z", "按下兩下 %s" % get_label_for_action("jump"))
	formatted = formatted.replace("Z是跳躍", "%s是跳躍" % get_label_for_action("jump"))

	formatted = formatted.replace("按 X", "按 %s" % get_label_for_action("attack"))
	formatted = formatted.replace("X是攻擊", "%s是攻擊" % get_label_for_action("attack"))

	formatted = formatted.replace("按 C", "按 %s" % get_label_for_action("dash"))
	formatted = formatted.replace("按下C", "按下%s" % get_label_for_action("dash"))
	formatted = formatted.replace("C可進行衝刺", "%s可進行衝刺" % get_label_for_action("dash"))

	formatted = formatted.replace("按 F", "按 %s" % get_label_for_action("far_attack"))
	return formatted


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


func _ensure_required_bindings() -> void:
	var changed := false
	for action in FALLBACK_KEYCODES.keys():
		if not InputMap.has_action(action):
			continue

		var keycode := FALLBACK_KEYCODES[action] as Key
		var has_fallback_key := false
		for event in InputMap.action_get_events(action):
			if event is InputEventKey and event.keycode == keycode:
				has_fallback_key = true
				break
		if has_fallback_key:
			continue

		var event := InputEventKey.new()
		event.keycode = keycode
		event.pressed = false
		InputMap.action_add_event(action, event)
		changed = true

	if changed:
		save_bindings()
		controls_changed.emit()
