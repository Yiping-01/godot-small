extends Node2D
class_name RestBench

@export_multiline var prompt_text := "按 E 坐下休息"
@export var seated_text := "生命已回滿。按 E 起身"
@export var seat_offset := Vector2(0.0, -34.0)
@export var stand_offset := Vector2(72.0, -36.0)

var player_nearby: PlayerController
var seated_player: PlayerController


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$InteractArea.body_entered.connect(_on_body_entered)
	$InteractArea.body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return

	if seated_player != null:
		_stand_up()
		get_viewport().set_input_as_handled()
		return

	if player_nearby != null and not GameState.input_locked:
		_sit_down()
		get_viewport().set_input_as_handled()


func _sit_down() -> void:
	seated_player = player_nearby
	player_nearby = null
	GameState.set_input_locked(true)
	seated_player.heal_to_full()
	seated_player.set_respawn_position(global_position + seat_offset)
	GameState.save_continue_scene(get_tree().current_scene.scene_file_path, global_position + seat_offset, true)
	seated_player.sit_on_bench(global_position + seat_offset, 1)

	var manager := get_tree().get_first_node_in_group("room_manager")
	if manager != null and manager.has_method("respawn_enemies"):
		await manager.respawn_enemies()

	GameState.save_game()

	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null:
		ui.show_prompt(seated_text)
		ui.show_toast("你坐在長椅上休息。生命回滿，敵人重生。", 2.0)

	get_tree().paused = true


func _stand_up() -> void:
	get_tree().paused = false
	seated_player.stand_from_bench(global_position + stand_offset)
	seated_player = null
	GameState.set_input_locked(false)

	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null:
		ui.hide_prompt()


func _on_body_entered(body: Node2D) -> void:
	if seated_player != null or not body.is_in_group("player"):
		return

	player_nearby = body as PlayerController
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null:
		ui.show_prompt(prompt_text)


func _on_body_exited(body: Node2D) -> void:
	if body != player_nearby:
		return

	player_nearby = null
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null and seated_player == null:
		ui.hide_prompt()
