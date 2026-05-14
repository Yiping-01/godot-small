extends CanvasLayer

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

var music_volume := 1.0
var sfx_volume := 1.0

var window_root: Control
var title_label: Label
var music_label: Label
var sfx_label: Label
var music_slider: HSlider
var sfx_slider: HSlider
var close_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 200
	_ensure_audio_bus(MUSIC_BUS)
	_ensure_audio_bus(SFX_BUS)
	_apply_bus_volume(MUSIC_BUS, music_volume)
	_apply_bus_volume(SFX_BUS, sfx_volume)
	_build_window()
	var localization: Node = _get_localization()
	if localization != null:
		localization.connect("language_changed", Callable(self, "_update_labels"))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("audio_settings"):
		_toggle_window()
		get_viewport().set_input_as_handled()


func _ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return

	AudioServer.add_bus()
	var bus_index := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, "Master")


func _build_window() -> void:
	window_root = Control.new()
	window_root.name = "AudioSettingsWindow"
	window_root.visible = false
	window_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(window_root)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.25)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	window_root.add_child(dim)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320.0, 190.0)
	panel.position = Vector2(480, 220)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.09, 0.11, 0.94)
	panel_style.border_color = Color(0.7, 0.7, 0.7, 0.45)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", panel_style)
	window_root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	content.add_child(title_label)

	music_label = Label.new()
	content.add_child(music_label)

	music_slider = _create_slider(music_volume)
	music_slider.value_changed.connect(_on_music_volume_changed)
	content.add_child(music_slider)

	sfx_label = Label.new()
	content.add_child(sfx_label)

	sfx_slider = _create_slider(sfx_volume)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	content.add_child(sfx_slider)

	close_button = Button.new()
	close_button.pressed.connect(_hide_window)
	content.add_child(close_button)

	_update_labels()


func _create_slider(value: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = round(value * 100.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return slider


func _toggle_window() -> void:
	window_root.visible = not window_root.visible


func _hide_window() -> void:
	window_root.visible = false


func _on_music_volume_changed(value: float) -> void:
	music_volume = value / 100.0
	_apply_bus_volume(MUSIC_BUS, music_volume)
	_update_labels()


func _on_sfx_volume_changed(value: float) -> void:
	sfx_volume = value / 100.0
	_apply_bus_volume(SFX_BUS, sfx_volume)
	_update_labels()


func _apply_bus_volume(bus_name: String, volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return

	AudioServer.set_bus_volume_db(bus_index, linear_to_db(max(volume, 0.001)))
	AudioServer.set_bus_mute(bus_index, volume <= 0.0)


func _update_labels() -> void:
	if title_label != null:
		title_label.text = _t("AUDIO_TITLE")
	if close_button != null:
		close_button.text = _t("MENU_CLOSE")
	music_label.text = _t("AUDIO_MUSIC") % roundi(music_volume * 100.0)
	sfx_label.text = _t("AUDIO_SFX") % roundi(sfx_volume * 100.0)


func _t(key: String) -> String:
	var localization: Node = _get_localization()
	if localization != null and localization.has_method("text"):
		return String(localization.call("text", key))
	return key


func _get_localization() -> Node:
	return get_node_or_null("/root/Localization")
