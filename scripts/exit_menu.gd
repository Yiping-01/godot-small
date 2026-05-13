extends CanvasLayer

@export_file("*.tscn") var main_menu_scene := "res://scenes/MainMenu.tscn"

var exit_panel: Panel
var resume_button: Button
var settings_button: Button
var sound_button: Button
var quit_button: Button
var pause_dim: ColorRect
var settings_panel: Panel
var settings_back_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_build_pause_menu()
	_build_settings_panel()
	_hide_exit_panel()


func _input(event: InputEvent) -> void:
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

	var right_line := ColorRect.new()
	right_line.name = "RightLine"
	right_line.color = Color(0.82, 0.78, 0.66, 0.36)
	right_line.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	right_line.offset_left = -18.0
	right_line.offset_top = 118.0
	right_line.offset_right = -17.0
	right_line.offset_bottom = -118.0
	exit_panel.add_child(right_line)

	var top_diamond := Label.new()
	top_diamond.text = "*"
	top_diamond.add_theme_font_size_override("font_size", 10)
	top_diamond.add_theme_color_override("font_color", Color(0.82, 0.78, 0.66, 0.36))
	top_diamond.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_diamond.offset_left = -23.0
	top_diamond.offset_top = 108.0
	top_diamond.offset_right = -9.0
	top_diamond.offset_bottom = 124.0
	exit_panel.add_child(top_diamond)

	var bottom_diamond := Label.new()
	bottom_diamond.text = "*"
	bottom_diamond.add_theme_font_size_override("font_size", 10)
	bottom_diamond.add_theme_color_override("font_color", Color(0.82, 0.78, 0.66, 0.36))
	bottom_diamond.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	bottom_diamond.offset_left = -23.0
	bottom_diamond.offset_top = -124.0
	bottom_diamond.offset_right = -9.0
	bottom_diamond.offset_bottom = -108.0
	exit_panel.add_child(bottom_diamond)

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
	title.text = "暫停"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.94, 0.92, 0.86, 0.94))
	content.add_child(title)

	resume_button = _create_menu_button("返回遊戲")
	settings_button = _create_menu_button("設置")
	sound_button = _create_menu_button("聲音")
	quit_button = _create_menu_button("離開")

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
	panel_style.bg_color = Color(0.03, 0.045, 0.055, 0.72)
	panel_style.border_color = Color(1.0, 1.0, 1.0, 0.18)
	panel_style.set_border_width_all(1)
	settings_panel.add_theme_stylebox_override("panel", panel_style)

	var content := VBoxContainer.new()
	content.name = "KeyboardContent"
	content.set_anchors_preset(Control.PRESET_CENTER)
	content.offset_left = -310.0
	content.offset_top = -220.0
	content.offset_right = 310.0
	content.offset_bottom = 220.0
	content.add_theme_constant_override("separation", 16)
	settings_panel.add_child(content)

	var title := Label.new()
	title.text = "鍵盤"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.92))
	content.add_child(title)

	var separator := ColorRect.new()
	separator.custom_minimum_size = Vector2(520.0, 1.0)
	separator.color = Color(1.0, 1.0, 1.0, 0.36)
	content.add_child(separator)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 64)
	content.add_child(columns)

	var left_column := VBoxContainer.new()
	left_column.custom_minimum_size = Vector2(260.0, 0.0)
	left_column.add_theme_constant_override("separation", 10)
	columns.add_child(left_column)

	var right_column := VBoxContainer.new()
	right_column.custom_minimum_size = Vector2(260.0, 0.0)
	right_column.add_theme_constant_override("separation", 10)
	columns.add_child(right_column)

	_add_key_row(left_column, "上", "W / ↑")
	_add_key_row(left_column, "下", "S / ↓")
	_add_key_row(left_column, "左", "A / ←")
	_add_key_row(left_column, "右", "D / →")
	_add_key_row(left_column, "跳躍", "Z")
	_add_key_row(left_column, "攻擊", "X")

	_add_key_row(right_column, "衝刺", "C")
	_add_key_row(right_column, "水槍", "F")
	_add_key_row(right_column, "互動 / 使用藥水", "E")
	_add_key_row(right_column, "地圖", "M")
	_add_key_row(right_column, "物品欄", "I")
	_add_key_row(right_column, "聲音", "P")

	var back_row := HBoxContainer.new()
	back_row.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(back_row)

	settings_back_button = _create_settings_back_button()
	settings_back_button.pressed.connect(_hide_settings_panel)
	back_row.add_child(settings_back_button)


func _add_key_row(parent: VBoxContainer, action_text: String, key_text: String) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(240.0, 30.0)
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)

	var action_label := Label.new()
	action_label.text = action_text
	action_label.custom_minimum_size = Vector2(122.0, 30.0)
	action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	action_label.add_theme_font_size_override("font_size", 17)
	action_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.78))
	row.add_child(action_label)

	var key_panel := Panel.new()
	key_panel.custom_minimum_size = Vector2(78.0, 30.0)
	key_panel.add_theme_stylebox_override("panel", _key_style())
	row.add_child(key_panel)

	var key_label := Label.new()
	key_label.text = key_text
	key_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key_label.add_theme_font_size_override("font_size", 15)
	key_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.92))
	key_panel.add_child(key_label)


func _key_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.08)
	style.border_color = Color(1.0, 1.0, 1.0, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style


func _create_settings_back_button() -> Button:
	var button := Button.new()
	button.text = "返回"
	button.custom_minimum_size = Vector2(88.0, 30.0)
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
	button.custom_minimum_size = Vector2(140.0, 25.0)
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


func _show_exit_panel() -> void:
	pause_dim.visible = true
	exit_panel.visible = true
	if settings_panel != null:
		settings_panel.visible = false
	get_tree().paused = true
	resume_button.grab_focus()


func _hide_exit_panel() -> void:
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
	settings_back_button.grab_focus()


func _hide_settings_panel() -> void:
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
