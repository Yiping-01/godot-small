extends CanvasLayer

@export_file("*.tscn") var main_menu_scene := "res://scenes/MainMenu.tscn"

@onready var exit_panel: Panel = $ExitPanel
@onready var yes_button: Button = $ExitPanel/YesButton
@onready var no_button: Button = $ExitPanel/NoButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	exit_panel.visible = false
	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_on_no_pressed)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if exit_panel.visible:
			_hide_exit_panel()
		elif _close_game_ui_window():
			pass
		else:
			_show_exit_panel()
		get_viewport().set_input_as_handled()


func _show_exit_panel() -> void:
	exit_panel.visible = true
	get_tree().paused = true
	yes_button.grab_focus()


func _hide_exit_panel() -> void:
	exit_panel.visible = false
	get_tree().paused = false


func _close_game_ui_window() -> bool:
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui == null or not ui.has_method("has_open_window") or not ui.has_method("close_all_windows"):
		return false

	if not ui.has_open_window():
		return false

	ui.close_all_windows()
	return true


func _on_yes_pressed() -> void:
	get_tree().paused = false
	GameState.set_input_locked(false)
	GameState.save_game()
	get_tree().change_scene_to_file(main_menu_scene)


func _on_no_pressed() -> void:
	_hide_exit_panel()
