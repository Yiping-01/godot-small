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
var key_buttons: Dictionary = {}
var waiting_for_action := ""
var waiting_label: Label
var reset_controls_button: Button


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
	_build_keyboard_rebind_panel()

	settings_panel.visible = false
	keyboard_panel.visible = false
	_update_menu_button_mouse_filter()
	continue_button.disabled = not GameState.has_continue_scene()
	menu_buttons = [start_button, continue_button, quit_button]
	_setup_menu_keyboard()
	var input_settings: Node = _get_input_settings()
	if input_settings != null:
		input_settings.connect("controls_changed", Callable(self, "_refresh_key_labels"))

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
	waiting_for_action = ""
	_show_waiting_message("點選右側按鍵後，按下新的鍵。Esc 取消。")
	_refresh_key_labels()
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
	if waiting_for_action != "":
		_capture_rebind_input(event)
		return

	if keyboard_panel.visible:
		if event.is_action_pressed("ui_cancel"):
			_on_keyboard_back_pressed()
			_mark_input_handled()
		return

	if settings_panel.visible:
		if event.is_action_pressed("ui_cancel"):
			_on_close_settings_panel()
			_mark_input_handled()
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


func _capture_rebind_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_mark_input_handled()
		if event.keycode == KEY_ESCAPE:
			waiting_for_action = ""
			_show_waiting_message("已取消更改。")
			return

		var action := waiting_for_action
		waiting_for_action = ""
		var input_settings: Node = _get_input_settings()
		var result: int = ERR_UNAVAILABLE
		if input_settings != null:
			result = int(input_settings.call("rebind_keyboard_action", action, event))
		if result == OK:
			_show_waiting_message("已更新按鍵。")
		else:
			_show_waiting_message("這個按鍵不能使用。")
		_refresh_key_labels()


func _build_keyboard_rebind_panel() -> void:
	for child in keyboard_panel.get_children():
		child.visible = false

	var content := VBoxContainer.new()
	content.name = "RebindContent"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 34.0
	content.offset_top = 14.0
	content.offset_right = -34.0
	content.offset_bottom = -18.0
	content.add_theme_constant_override("separation", 10)
	keyboard_panel.add_child(content)

	var title := Label.new()
	title.text = "按鍵設定"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.92))
	content.add_child(title)

	waiting_label = Label.new()
	waiting_label.text = "點選右側按鍵後，按下新的鍵。Esc 取消。"
	waiting_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	waiting_label.add_theme_font_size_override("font_size", 15)
	waiting_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.72))
	content.add_child(waiting_label)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 40)
	content.add_child(columns)

	var left_column := VBoxContainer.new()
	left_column.custom_minimum_size = Vector2(280.0, 0.0)
	left_column.add_theme_constant_override("separation", 6)
	columns.add_child(left_column)

	var right_column := VBoxContainer.new()
	right_column.custom_minimum_size = Vector2(280.0, 0.0)
	right_column.add_theme_constant_override("separation", 6)
	columns.add_child(right_column)

	var input_settings: Node = _get_input_settings()
	var actions: Array = [] if input_settings == null else input_settings.call("get_actions")
	for i in range(actions.size()):
		var target_column: VBoxContainer = left_column if i < 6 else right_column
		_add_key_row(target_column, String(actions[i]["label"]), String(actions[i]["action"]))

	var bottom_row := HBoxContainer.new()
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_row.add_theme_constant_override("separation", 12)
	content.add_child(bottom_row)

	reset_controls_button = _create_panel_button("恢復預設")
	reset_controls_button.pressed.connect(_on_reset_controls_pressed)
	bottom_row.add_child(reset_controls_button)

	keyboard_back_button = _create_panel_button("返回")
	keyboard_back_button.pressed.connect(_on_keyboard_back_pressed)
	bottom_row.add_child(keyboard_back_button)

	_refresh_key_labels()


func _add_key_row(parent: VBoxContainer, action_text: String, action_name: String) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(270.0, 29.0)
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	var action_label := Label.new()
	action_label.text = action_text
	action_label.custom_minimum_size = Vector2(132.0, 29.0)
	action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	action_label.add_theme_font_size_override("font_size", 16)
	action_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.82))
	row.add_child(action_label)

	var key_button := _create_key_button()
	key_button.pressed.connect(_start_rebind.bind(action_name))
	row.add_child(key_button)
	key_buttons[action_name] = key_button


func _create_key_button() -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(96.0, 29.0)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.92))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.78, 1.0))
	return button


func _create_panel_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(108.0, 31.0)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_font_size_override("font_size", 15)
	return button


func _start_rebind(action_name: String) -> void:
	waiting_for_action = action_name
	_show_waiting_message("請按新的「%s」按鍵，Esc 取消。" % _get_action_display_name(action_name))


func _get_action_display_name(action_name: String) -> String:
	var input_settings: Node = _get_input_settings()
	if input_settings == null:
		return action_name
	for item in input_settings.call("get_actions"):
		if String(item["action"]) == action_name:
			return String(item["label"])
	return action_name


func _refresh_key_labels() -> void:
	for action_name in key_buttons.keys():
		var button := key_buttons[action_name] as Button
		var input_settings: Node = _get_input_settings()
		if input_settings != null:
			button.text = String(input_settings.call("get_label_for_action", String(action_name)))


func _show_waiting_message(text: String) -> void:
	if waiting_label != null:
		waiting_label.text = text


func _on_reset_controls_pressed() -> void:
	var input_settings: Node = _get_input_settings()
	if input_settings != null:
		input_settings.call("reset_to_defaults")
	_show_waiting_message("已恢復預設按鍵。")


func _get_input_settings() -> Node:
	return get_node_or_null("/root/InputSettings")


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
