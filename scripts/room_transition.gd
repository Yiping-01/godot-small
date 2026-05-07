extends Area2D
class_name RoomTransition

@export var target_scene: String = ""
@export var target_position := Vector2.ZERO
@export var target_spawn_marker_name := ""
@export var loading_time := 0.7
@export_multiline var message := "移動到下一張地圖..."
@export var enabled := true
@export var only_when_visible := true
@export var require_interact := false
@export var prompt_text := "按 E 進入下一個區域"

var triggered := false
var player_nearby: Node2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if not require_interact or triggered or player_nearby == null:
		return
	if not event.is_action_pressed("interact"):
		return
	if GameState.input_locked:
		return

	get_viewport().set_input_as_handled()
	triggered = true
	_load_next_map()


func _on_body_entered(body: Node2D) -> void:
	if triggered or not _can_trigger() or not body.is_in_group("player"):
		return

	player_nearby = body
	if require_interact:
		var ui := get_tree().get_first_node_in_group("game_ui")
		if ui != null and ui.has_method("show_prompt"):
			ui.show_prompt(prompt_text)
		return

	triggered = true
	_load_next_map()


func _on_body_exited(body: Node2D) -> void:
	if body != player_nearby:
		return

	player_nearby = null
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null and ui.has_method("hide_prompt"):
		ui.hide_prompt()


func _can_trigger() -> bool:
	if not enabled:
		return false
	if only_when_visible and not is_visible_in_tree():
		return false
	return true


func _load_next_map() -> void:
	if target_scene == "":
		triggered = false
		return

	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null and ui.has_method("hide_prompt"):
		ui.hide_prompt()

	GameState.set_input_locked(true)

	if ui != null:
		ui.show_toast(message, 1.2)
		await ui.fade_out(0.45)

	await get_tree().create_timer(loading_time).timeout

	if target_spawn_marker_name != "":
		GameState.set_pending_spawn_marker(target_spawn_marker_name)
		GameState.save_continue_scene(target_scene, Vector2.ZERO, false, target_spawn_marker_name)
	else:
		GameState.set_pending_spawn_position(target_position)
		GameState.save_continue_scene(target_scene, target_position, true)

	GameState.save_game()

	# 通知目前房間：玩家離開房間了，可以重置敵人資料
	get_tree().call_group("room_manager", "on_room_transition")

	GameState.set_input_locked(false)
	get_tree().change_scene_to_file(target_scene)
