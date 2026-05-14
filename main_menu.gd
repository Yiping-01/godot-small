extends Control

@onready var start_button = $StartButton
@onready var continue_button = $ContinueButton
@onready var quit_button = $QuitButton
@onready var background_video = $Background

@onready var settings_button = $SettingsButton
@onready var settings_panel = $SettingsPanel
@onready var panel_settings_button = $SettingsPanel/VBoxContainer/SettingsOptionButton
@onready var panel_sound_button = $SettingsPanel/VBoxContainer/SoundOptionButton
@onready var panel_quit_button = $SettingsPanel/VBoxContainer/QuitOptionButton
@onready var keyboard_panel = $KeyboardPanel
@onready var keyboard_back_button = $KeyboardPanel/BackButton

var menu_buttons: Array[Button] = []
var selected_menu_index := 0


func _ready():
	_play_title_music()

	background_video.finished.connect(_on_background_video_finished)
	background_video.play()

	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	settings_button.pressed.connect(_on_settings_pressed)
	panel_settings_button.pressed.connect(_on_panel_settings_pressed)
	panel_sound_button.pressed.connect(_on_panel_sound_pressed)
	panel_quit_button.pressed.connect(_on_close_settings_panel)
	keyboard_back_button.pressed.connect(_on_keyboard_back_pressed)

	settings_panel.visible = false
	keyboard_panel.visible = false
	_update_menu_button_mouse_filter()
	continue_button.disabled = not GameState.has_continue_scene()
	menu_buttons = [start_button, continue_button, quit_button]
	_setup_menu_keyboard()

func _on_start_pressed():
	if FileAccess.file_exists("user://save_game.json"):
		DirAccess.remove_absolute("user://save_game.json")

	GameState.reset_demo_state()
	GameState.clear_continue_scene()
	_play_game_music()
	get_tree().change_scene_to_file(GameState.DEFAULT_START_SCENE)

func _on_continue_pressed():
	_play_game_music()
	get_tree().change_scene_to_file(GameState.prepare_continue_scene())

func _on_quit_pressed():
	GameState.save_game()
	get_tree().quit()

func _on_settings_pressed():
	var next_visible: bool = not settings_panel.visible
	settings_panel.visible = next_visible
	keyboard_panel.visible = false
	_update_menu_button_mouse_filter()


func _on_panel_settings_pressed() -> void:
	settings_panel.visible = false
	keyboard_panel.visible = true
	_update_menu_button_mouse_filter()


func _on_keyboard_back_pressed() -> void:
	keyboard_panel.visible = false
	settings_panel.visible = true
	_update_menu_button_mouse_filter()


func _on_panel_sound_pressed() -> void:
	if AudioSettings != null and AudioSettings.has_method("_toggle_window"):
		AudioSettings.call("_toggle_window")


func _on_close_settings_panel() -> void:
	settings_panel.visible = false
	keyboard_panel.visible = false
	_update_menu_button_mouse_filter()


func _update_menu_button_mouse_filter() -> void:
	var block_main_buttons: bool = settings_panel.visible or keyboard_panel.visible
	var next_filter: int = Control.MOUSE_FILTER_IGNORE if block_main_buttons else Control.MOUSE_FILTER_STOP
	start_button.mouse_filter = next_filter
	continue_button.mouse_filter = next_filter
	quit_button.mouse_filter = next_filter


func _input(event: InputEvent) -> void:
	if settings_panel.visible or keyboard_panel.visible:
		return

	if event.is_action_pressed("ui_up"):
		_move_menu_selection(-1)
		_mark_input_handled()
	elif event.is_action_pressed("ui_down"):
		_move_menu_selection(1)
		_mark_input_handled()
	elif event.is_action_pressed("ui_accept"):
		_mark_input_handled()
		var selected_button := menu_buttons[selected_menu_index]
		if not selected_button.disabled:
			selected_button.emit_signal("pressed")


func _setup_menu_keyboard() -> void:
	for i in range(menu_buttons.size()):
		var button := menu_buttons[i]
		button.focus_mode = Control.FOCUS_ALL
		button.focus_entered.connect(_on_menu_button_focus_entered.bind(i))

	_select_first_enabled_menu_button()


func _select_first_enabled_menu_button() -> void:
	for i in range(menu_buttons.size()):
		if not menu_buttons[i].disabled:
			selected_menu_index = i
			menu_buttons[i].grab_focus()
			return


func _move_menu_selection(direction: int) -> void:
	if menu_buttons.is_empty():
		return

	var next_index := selected_menu_index
	for i in range(menu_buttons.size()):
		next_index = wrapi(next_index + direction, 0, menu_buttons.size())
		if not menu_buttons[next_index].disabled:
			selected_menu_index = next_index
			menu_buttons[selected_menu_index].grab_focus()
			return


func _on_menu_button_focus_entered(index: int) -> void:
	selected_menu_index = index


func _mark_input_handled() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()


func _on_background_video_finished():
	background_video.stream_position = 0.0
	background_video.play()

func _play_game_music() -> void:
	var music_player := get_node_or_null("/root/MusicPlayer")
	if music_player != null and music_player.has_method("play_game_music"):
		music_player.play_game_music()


func _play_title_music() -> void:
	var music_player := get_node_or_null("/root/MusicPlayer")
	if music_player != null and music_player.has_method("play_title_music"):
		music_player.play_title_music()
