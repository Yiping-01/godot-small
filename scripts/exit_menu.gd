extends CanvasLayer

@export_file("*.tscn") var main_menu_scene := "res://scenes/MainMenu.tscn"

var exit_panel: Panel
var resume_button: Button
var settings_button: Button
var sound_button: Button
var quit_button: Button
var pause_dim: ColorRect
var settings_panel: Panel
var pause_title_label: Label
var settings_title_label: Label
var settings_back_button: Button
var reset_controls_button: Button
var waiting_label: Label
var key_buttons: Dictionary = {}
var key_action_labels: Dictionary = {}
var waiting_for_action := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_build_pause_menu()
	_build_settings_panel()
	_hide_exit_panel()
	var settings: Node = _get_input_settings()
	if settings != null:
		settings.connect("controls_changed", Callable(self, "_refresh_key_labels"))
	var localization: Node = _get_localization()
	if localization != null:
		localization.connect("language_changed", Callable(self, "_update_texts"))
	_update_texts()


func _input(event: InputEvent) -> void:
	if waiting_for_action != "":
		_capture_rebind_input(event)
		return

	if event.is_action_pressed("ui_cancel"):
		if settings_panel != null and settings_panel.visible:
			_hide_settings_panel()
		elif exit_panel.visible:
			_hide_exit_panel()
		elif _close_game_ui_window():
			pass
		else:
			_show_exit_panel()
		get_viewport().set_input_as_handled()


func _capture_rebind_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		if event.keycode == KEY_ESCAPE:
			_cancel_rebind()
			return

		var action := waiting_for_action
		waiting_for_action = ""
		var settings: Node = _get_input_settings()
		var result: int = ERR_UNAVAILABLE
		if settings != null:
			result = int(settings.call("rebind_keyboard_action", action, event))
		if result == OK:
			_show_waiting_message(_t("KEYBOARD_SAVED"))
		else:
			_show_waiting_message(_t("KEYBOARD_FAILED"))
		_refresh_key_labels()


func _build_pause_menu() -> void:
	pause_dim = ColorRect.new()
	pause_dim.name = "PauseDim"
	pause_dim.color = Color(0.0, 0.0, 0.0, 0.18)
	pause_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(pause_dim)
	move_child(pause_dim, 0)

	exit_panel = get_node_or_null("ExitPanel")
	if exit_panel == null:
		exit_panel = Panel.new()
		exit_panel.name = "ExitPanel"
		add_child(exit_panel)

	for child in exit_panel.get_children():
		child.queue_free()

	exit_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	exit_panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	exit_panel.offset_left = 0.0
	exit_panel.offset_top = 0.0
	exit_panel.offset_right = 205.0
	exit_panel.offset_bottom = 0.0

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0, 0.02, 0.025, 0.68)
	panel_style.border_color = Color(0.85, 0.82, 0.72, 0.18)
	panel_style.border_width_right = 1
	exit_panel.add_theme_stylebox_override("panel", panel_style)

	var content := VBoxContainer.new()
	content.name = "MenuContent"
	content.set_anchors_preset(Control.PRESET_TOP_LEFT)
	content.offset_left = 18.0
	content.offset_top = 126.0
	content.offset_right = 180.0
	content.offset_bottom = 360.0
	content.add_theme_constant_override("separation", 9)
	exit_panel.add_child(content)

	var title := Label.new()
	pause_title_label = title
	title.text = "暫停"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.94, 0.92, 0.86, 0.94))
	content.add_child(title)

	resume_button = _create_menu_button("繼續遊戲")
	settings_button = _create_menu_button("按鍵設定")
	sound_button = _create_menu_button("聲音")
	quit_button = _create_menu_button("回主選單")

	content.add_child(resume_button)
	content.add_child(settings_button)
	content.add_child(sound_button)
	content.add_child(quit_button)

	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	sound_button.pressed.connect(_on_sound_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _build_settings_panel() -> void:
	settings_panel = Panel.new()
	settings_panel.name = "SettingsPanel"
	settings_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	settings_panel.visible = false
	settings_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(settings_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.045, 0.055, 0.74)
	panel_style.border_color = Color(1.0, 1.0, 1.0, 0.18)
	panel_style.set_border_width_all(1)
	settings_panel.add_theme_stylebox_override("panel", panel_style)

	var content := VBoxContainer.new()
	content.name = "KeyboardContent"
	content.set_anchors_preset(Control.PRESET_CENTER)
	content.offset_left = -340.0
	content.offset_top = -250.0
	content.offset_right = 340.0
	content.offset_bottom = 250.0
	content.add_theme_constant_override("separation", 14)
	settings_panel.add_child(content)

	var title := Label.new()
	settings_title_label = title
	title.text = "按鍵設定"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.92))
	content.add_child(title)

	waiting_label = Label.new()
	waiting_label.text = "點選右側按鍵後，按下新的鍵。Esc 取消。"
	waiting_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	waiting_label.add_theme_font_size_override("font_size", 16)
	waiting_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.72))
	content.add_child(waiting_label)

	var separator := ColorRect.new()
	separator.custom_minimum_size = Vector2(600.0, 1.0)
	separator.color = Color(1.0, 1.0, 1.0, 0.36)
	content.add_child(separator)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 40)
	content.add_child(columns)

	var left_column := VBoxContainer.new()
	left_column.custom_minimum_size = Vector2(300.0, 0.0)
	left_column.add_theme_constant_override("separation", 8)
	columns.add_child(left_column)

	var right_column := VBoxContainer.new()
	right_column.custom_minimum_size = Vector2(300.0, 0.0)
	right_column.add_theme_constant_override("separation", 8)
	columns.add_child(right_column)

	var settings: Node = _get_input_settings()
	var actions: Array = [] if settings == null else settings.call("get_actions")
	for i in range(actions.size()):
		var target_column: VBoxContainer = left_column if i < 6 else right_column
		_add_key_row(target_column, String(actions[i]["label"]), String(actions[i]["action"]))

	var bottom_row := HBoxContainer.new()
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_row.add_theme_constant_override("separation", 12)
	content.add_child(bottom_row)

	reset_controls_button = _create_settings_button("恢復預設")
	reset_controls_button.pressed.connect(_on_reset_controls_pressed)
	bottom_row.add_child(reset_controls_button)

	settings_back_button = _create_settings_button("返回")
	settings_back_button.pressed.connect(_hide_settings_panel)
	bottom_row.add_child(settings_back_button)

	_refresh_key_labels()


func _add_key_row(parent: VBoxContainer, action_text: String, action_name: String) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(292.0, 32.0)
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)

	var action_label := Label.new()
	action_label.text = action_text
	action_label.custom_minimum_size = Vector2(142.0, 32.0)
	action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	action_label.add_theme_font_size_override("font_size", 17)
	action_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.78))
	row.add_child(action_label)
	key_action_labels[action_name] = action_label

	var key_button := _create_key_button()
	key_button.pressed.connect(_start_rebind.bind(action_name))
	row.add_child(key_button)
	key_buttons[action_name] = key_button


func _create_key_button() -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(104.0, 32.0)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.92))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.78, 1.0))
	button.add_theme_stylebox_override("normal", _key_style())
	button.add_theme_stylebox_override("hover", _button_style(Color(1.0, 1.0, 1.0, 0.13)))
	button.add_theme_stylebox_override("focus", _button_style(Color(1.0, 1.0, 1.0, 0.18)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(1.0, 1.0, 1.0, 0.22)))
	return button


func _key_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.08)
	style.border_color = Color(1.0, 1.0, 1.0, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style


func _create_settings_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(110.0, 32.0)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.92, 0.9, 0.84, 0.88))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.9, 1.0))
	button.add_theme_stylebox_override("normal", _key_style())
	button.add_theme_stylebox_override("hover", _button_style(Color(1.0, 1.0, 1.0, 0.12)))
	button.add_theme_stylebox_override("focus", _button_style(Color(1.0, 1.0, 1.0, 0.16)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(1.0, 1.0, 1.0, 0.2)))
	return button


func _create_menu_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.focus_mode = Control.FOCUS_ALL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(150.0, 25.0)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.92, 0.9, 0.84, 0.78))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.9, 1.0))
	button.add_theme_color_override("font_focus_color", Color(1.0, 0.98, 0.9, 1.0))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.0, 0.0, 0.0, 0.0)))
	button.add_theme_stylebox_override("hover", _button_style(Color(1.0, 1.0, 1.0, 0.07)))
	button.add_theme_stylebox_override("focus", _button_style(Color(1.0, 1.0, 1.0, 0.1)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(1.0, 1.0, 1.0, 0.14)))
	return button


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.content_margin_left = 2.0
	style.content_margin_right = 2.0
	style.content_margin_top = 1.0
	style.content_margin_bottom = 1.0
	return style


func _start_rebind(action_name: String) -> void:
	waiting_for_action = action_name
	_show_waiting_message(_t("KEYBOARD_PRESS_NEW") % _get_action_display_name(action_name))


func _cancel_rebind() -> void:
	waiting_for_action = ""
	_show_waiting_message(_t("KEYBOARD_CANCELLED"))


func _show_waiting_message(text: String) -> void:
	if waiting_label != null:
		waiting_label.text = text


func _get_action_display_name(action_name: String) -> String:
	var settings: Node = _get_input_settings()
	if settings == null:
		return action_name
	for item in settings.call("get_actions"):
		if String(item["action"]) == action_name:
			return _get_localized_action_name(action_name)
	return action_name


func _refresh_key_labels() -> void:
	for action_name in key_buttons.keys():
		var button := key_buttons[action_name] as Button
		var settings: Node = _get_input_settings()
		if settings != null:
			button.text = String(settings.call("get_label_for_action", String(action_name)))


func _on_reset_controls_pressed() -> void:
	var settings: Node = _get_input_settings()
	if settings != null:
		settings.call("reset_to_defaults")
	_show_waiting_message(_t("KEYBOARD_RESET_DONE"))


func _get_input_settings() -> Node:
	return get_node_or_null("/root/InputSettings")


func _get_localization() -> Node:
	return get_node_or_null("/root/Localization")


func _t(key: String) -> String:
	var localization: Node = _get_localization()
	if localization != null and localization.has_method("text"):
		return String(localization.call("text", key))
	return key


func _get_localized_action_name(action_name: String) -> String:
	return _t("ACTION_%s" % action_name.to_upper())


func _update_texts() -> void:
	if pause_title_label != null:
		pause_title_label.text = _t("PAUSE_TITLE")
	if resume_button != null:
		resume_button.text = _t("PAUSE_RESUME")
	if settings_button != null:
		settings_button.text = _t("PAUSE_SETTINGS")
	if sound_button != null:
		sound_button.text = _t("PAUSE_SOUND")
	if quit_button != null:
		quit_button.text = _t("PAUSE_MAIN_MENU")
	if settings_title_label != null:
		settings_title_label.text = _t("PAUSE_SETTINGS")
	if reset_controls_button != null:
		reset_controls_button.text = _t("KEYBOARD_RESET")
	if settings_back_button != null:
		settings_back_button.text = _t("MENU_BACK")
	if waiting_label != null and waiting_for_action == "":
		waiting_label.text = _t("KEYBOARD_WAITING")
	for action_name in key_action_labels.keys():
		var label: Label = key_action_labels[action_name] as Label
		if label != null:
			label.text = _get_localized_action_name(String(action_name))


func _show_exit_panel() -> void:
	pause_dim.visible = true
	exit_panel.visible = true
	if settings_panel != null:
		settings_panel.visible = false
	get_tree().paused = true
	resume_button.grab_focus()


func _hide_exit_panel() -> void:
	waiting_for_action = ""
	if pause_dim != null:
		pause_dim.visible = false
	if exit_panel != null:
		exit_panel.visible = false
	if settings_panel != null:
		settings_panel.visible = false
	get_tree().paused = false


func _show_settings_panel() -> void:
	pause_dim.visible = false
	exit_panel.visible = false
	settings_panel.visible = true
	get_tree().paused = true
	_show_waiting_message(_t("KEYBOARD_WAITING"))
	_refresh_key_labels()
	settings_back_button.grab_focus()


func _hide_settings_panel() -> void:
	waiting_for_action = ""
	settings_panel.visible = false
	pause_dim.visible = true
	exit_panel.visible = true
	get_tree().paused = true
	settings_button.grab_focus()


func _close_game_ui_window() -> bool:
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui == null or not ui.has_method("has_open_window") or not ui.has_method("close_all_windows"):
		return false

	if not ui.has_open_window():
		return false

	ui.close_all_windows()
	return true


func _on_resume_pressed() -> void:
	_hide_exit_panel()


func _on_settings_pressed() -> void:
	_show_settings_panel()


func _on_sound_pressed() -> void:
	if AudioSettings != null and AudioSettings.has_method("_toggle_window"):
		AudioSettings.call("_toggle_window")


func _on_quit_pressed() -> void:
	get_tree().paused = false
	GameState.set_input_locked(false)
	GameState.save_game()
	get_tree().change_scene_to_file(main_menu_scene)


func _show_toast(text: String) -> void:
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null and ui.has_method("show_toast"):
		ui.show_toast(text)
