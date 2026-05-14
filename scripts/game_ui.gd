extends CanvasLayer

const POTION_TEXTURE := preload("res://assets/some/Health_Potion.png")
const ITEM_TEXTURE := preload("res://assets/enemy/enemy2.png")
const SKILL_TEXTURE := preload("res://assets/player/attack_far/far_1.png")
const INVENTORY_TAB_KEYS := ["INV_TAB_CHARACTER", "INV_TAB_BAG", "INV_TAB_SKILLS", "INV_TAB_MAP", "INV_TAB_SYSTEM"]
const INVENTORY_CATEGORY_KEYS := ["INV_CAT_ALL", "INV_CAT_CONSUMABLE", "INV_CAT_MATERIAL", "INV_CAT_SKILL", "INV_CAT_IMPORTANT"]
const GRID_SLOT_COUNT := 48
const EQUIPPED_SKILL_SLOT_COUNT := 4
const SKILL_LIBRARY := [
	{
		"id": "water_dash",
		"name_key": "INV_SKILL_WATER_DASH",
		"type_key": "INV_CAT_SKILL",
		"description_key": "INV_SKILL_WATER_DASH_DESC",
		"texture": "res://assets/player/attack_far/far_1.png",
	},
	{
		"id": "wall_burst",
		"name_key": "INV_SKILL_WALL_BURST",
		"type_key": "INV_CAT_SKILL",
		"description_key": "INV_SKILL_WALL_BURST_DESC",
		"texture": "res://assets/player/attack_far/far_2.png",
	},
	{
		"id": "water_shot",
		"name_key": "INV_SKILL_WATER_SHOT",
		"type_key": "INV_CAT_SKILL",
		"description_key": "INV_SKILL_WATER_SHOT_DESC",
		"texture": "res://assets/player/attack_far/far_3.png",
	},
	{
		"id": "quick_map",
		"name_key": "INV_SKILL_QUICK_MAP",
		"type_key": "INV_CAT_SKILL",
		"description_key": "INV_SKILL_QUICK_MAP_DESC",
		"texture": "res://assets/player/attack_far/far_4.png",
	},
]

@onready var prompt_label: Label = $PromptLabel
@onready var toast_label: Label = $ToastLabel
@onready var hud_currency_label: Label = $CurrencyLabel
@onready var dialogue_panel: Panel = $DialoguePanel
@onready var dialogue_name_label: Label = $DialoguePanel/VBoxContainer/NameLabel
@onready var dialogue_text_label: Label = $DialoguePanel/VBoxContainer/DialogueLabel
@onready var dialogue_hint_label: Label = $DialoguePanel/VBoxContainer/HintLabel
@onready var inventory_panel: Panel = $InventoryPanel
@onready var inventory_title_label: Label = $InventoryPanel/VBoxContainer/TitleLabel
@onready var inventory_currency_label: Label = $InventoryPanel/VBoxContainer/CurrencyLabel
@onready var shop_panel: Panel = $ShopPanel
@onready var shop_title_label: Label = $ShopPanel/VBoxContainer/TitleLabel
@onready var shop_currency_label: Label = $ShopPanel/VBoxContainer/CurrencyLabel
@onready var shop_item_buttons: Array[Button] = [
	$ShopPanel/VBoxContainer/ShopItem0,
	$ShopPanel/VBoxContainer/ShopItem1,
	$ShopPanel/VBoxContainer/ShopItem2,
]
@onready var shop_close_hint_label: Label = $ShopPanel/VBoxContainer/CloseHintLabel
@onready var map_panel: Panel = $MapPanel
@onready var map_corner_icon: TextureRect = $MapPanel/CornerIcon
@onready var map_vbox: VBoxContainer = $MapPanel/VBoxContainer
@onready var map_title_label: Label = $MapPanel/VBoxContainer/TitleLabel
@onready var map_canvas: Control = $MapPanel/VBoxContainer/MapCanvas
@onready var map_hint_label: Label = $MapPanel/VBoxContainer/HintLabel
@onready var area_title_panel: Panel = $AreaTitlePanel
@onready var area_subtitle_label: Label = $AreaTitlePanel/VBoxContainer/SubTitleLabel
@onready var area_main_title_label: Label = $AreaTitlePanel/VBoxContainer/MainTitleLabel
@onready var fade_rect: ColorRect = $FadeRect

var active_npc: Node
var dialogue_lines: Array[String] = []
var dialogue_index := 0
var shop_items: Array[Dictionary] = []
var toast_tween: Tween
var area_title_tween: Tween
var fade_tween: Tween
var map_display_mode := 0
var inventory_profile_label: Label
var inventory_grid: GridContainer
var inventory_detail_title: Label
var inventory_detail_type: Label
var inventory_detail_description: Label
var inventory_equipped_title_label: Label
var inventory_hint_label: Label
var inventory_category_buttons: Array[Button] = []
var inventory_tab_buttons: Array[Button] = []
var equipped_skill_slots: Array[Button] = []
var equipped_skills: Array[Dictionary] = []
var selected_inventory_tab_key := "INV_TAB_BAG"
var selected_inventory_category_key := "INV_CAT_ALL"

const MAP_MODE_CLOSED := 0
const MAP_MODE_MINI := 1
const MAP_MODE_FULL := 2
const MAP_PANEL_FULL_RECT := Rect2(282.0, 82.0, 716.0, 508.0)
const MAP_VBOX_FULL_RECT := Rect2(22.0, 18.0, 672.0, 470.0)
const MAP_CANVAS_FULL_SIZE := Vector2(672.0, 380.0)
const MAP_PANEL_MINI_RECT := Rect2(930.0, 72.0, 200.0, 130.0)
const MAP_VBOX_MINI_RECT := Rect2(10.0, 10.0, 226.0, 138.0)
const MAP_CANVAS_MINI_SIZE := Vector2(226.0, 138.0)
const MAP_MINI_SCALE := Vector2(0.33, 0.33)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game_ui")
	_build_inventory_window()
	_reset_equipped_skills()

	prompt_label.hide()
	toast_label.hide()
	dialogue_panel.hide()
	inventory_panel.hide()
	shop_panel.hide()
	map_panel.hide()

	area_title_panel.modulate.a = 0.0
	area_title_panel.hide()

	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	GameState.currency_changed.connect(_on_currency_changed)
	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.first_item_obtained.connect(_on_first_item_obtained)
	GameState.map_room_changed.connect(_on_map_room_changed)
	var localization: Node = _get_localization()
	if localization != null:
		localization.connect("language_changed", Callable(self, "_refresh_localized_texts"))

	for i in range(shop_item_buttons.size()):
		shop_item_buttons[i].pressed.connect(_on_shop_item_pressed.bind(i))

	_on_currency_changed(GameState.currency)
	_on_inventory_changed(GameState.inventory)
	_refresh_localized_texts()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if inventory_panel.visible or shop_panel.visible or dialogue_panel.visible or map_panel.visible:
			close_all_windows()
		elif not GameState.input_locked:
			toggle_inventory()
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("map"):
		if inventory_panel.visible or shop_panel.visible or dialogue_panel.visible:
			close_all_windows()
		elif map_panel.visible or not GameState.input_locked:
			toggle_map()
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("ui_cancel"):
		close_all_windows()
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("interact") and dialogue_panel.visible:
		_advance_dialogue()
		get_viewport().set_input_as_handled()


func show_prompt(text: String) -> void:
	if dialogue_panel.visible or shop_panel.visible or inventory_panel.visible or map_panel.visible:
		return

	prompt_label.text = _format_action_text(_tr_raw(text))
	prompt_label.show()


func hide_prompt() -> void:
	prompt_label.hide()


func open_npc_dialogue(npc: Node) -> void:
	if npc == null:
		return

	active_npc = npc
	dialogue_lines.assign(npc.dialogue_lines)
	dialogue_index = 0

	hide_prompt()
	GameState.set_input_locked(true)

	dialogue_name_label.text = _tr_raw(npc.display_name)
	dialogue_panel.show()
	_show_dialogue_line()


func toggle_inventory() -> void:
	if inventory_panel.visible:
		close_all_windows()
		return

	hide_prompt()
	GameState.set_input_locked(true)
	_update_inventory_text(GameState.inventory)
	inventory_panel.show()


func toggle_map() -> void:
	if map_display_mode == MAP_MODE_CLOSED:
		_show_mini_map()
	elif map_display_mode == MAP_MODE_MINI:
		_show_full_map()
	else:
		close_all_windows()


func _show_mini_map() -> void:
	hide_prompt()
	GameState.set_input_locked(false)
	_apply_map_layout(MAP_MODE_MINI)
	_rebuild_map()
	map_panel.show()


func _show_full_map() -> void:
	hide_prompt()
	GameState.set_input_locked(true)
	_apply_map_layout(MAP_MODE_FULL)
	_rebuild_map()
	map_panel.show()


func close_all_windows() -> void:
	dialogue_panel.hide()
	inventory_panel.hide()
	shop_panel.hide()
	map_panel.hide()
	_apply_map_layout(MAP_MODE_CLOSED)

	active_npc = null
	GameState.set_input_locked(false)


func has_open_window() -> bool:
	return dialogue_panel.visible or inventory_panel.visible or shop_panel.visible or map_panel.visible


func has_prompt() -> bool:
	return prompt_label.visible


func show_area_title(main_title: String, sub_title: String) -> void:
	area_main_title_label.text = _tr_raw(main_title)
	area_subtitle_label.text = _tr_raw(sub_title)
	area_title_panel.show()

	if area_title_tween != null:
		area_title_tween.kill()

	area_title_panel.modulate.a = 0.0
	area_title_tween = create_tween()
	area_title_tween.tween_property(area_title_panel, "modulate:a", 1.0, 0.45)
	area_title_tween.tween_interval(2.0)
	area_title_tween.tween_property(area_title_panel, "modulate:a", 0.0, 0.55)
	area_title_tween.tween_callback(area_title_panel.hide)


func show_toast(text: String, duration: float = 2.0) -> void:
	toast_label.text = _format_action_text(_tr_raw(text))
	toast_label.show()

	if toast_tween != null:
		toast_tween.kill()

	toast_label.modulate.a = 1.0
	toast_tween = create_tween()
	toast_tween.tween_interval(duration)
	toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.35)
	toast_tween.tween_callback(toast_label.hide)


func show_tutorial(text: String, duration: float = 2.8) -> void:
	show_toast(text, duration)

func is_area_title_visible() -> bool:
	return area_title_panel.visible



func hide_tutorial() -> void:
	if toast_tween != null:
		toast_tween.kill()

	toast_label.hide()


func fade_out(duration: float = 0.25) -> void:
	await _fade_to(1.0, duration)


func fade_in(duration: float = 0.25) -> void:
	await _fade_to(0.0, duration)


func _fade_to(alpha: float, duration: float) -> void:
	if fade_tween != null:
		fade_tween.kill()

	fade_tween = create_tween()
	fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(fade_rect, "modulate:a", alpha, duration)

	await fade_tween.finished


func _show_dialogue_line() -> void:
	dialogue_text_label.text = "..." if dialogue_lines.is_empty() else _format_action_text(_tr_raw(dialogue_lines[dialogue_index]))

	var can_open_shop: bool = active_npc != null and active_npc.opens_shop and dialogue_index >= dialogue_lines.size() - 1

	if can_open_shop:
		dialogue_hint_label.text = _format_action_text(_t("DIALOGUE_SHOP_HINT"))
	else:
		dialogue_hint_label.text = _format_action_text(_t("DIALOGUE_NEXT_HINT"))


func _advance_dialogue() -> void:
	if active_npc == null:
		close_all_windows()
		return

	if dialogue_index < dialogue_lines.size() - 1:
		dialogue_index += 1
		_show_dialogue_line()
		return

	if active_npc.opens_shop:
		_open_shop(active_npc)
	else:
		close_all_windows()


func _open_shop(npc: Node) -> void:
	dialogue_panel.hide()

	if npc.has_method("get_shop_items"):
		shop_items.assign(npc.get_shop_items())
	else:
		shop_items.assign(npc.shop_items)
	shop_title_label.text = _t("SHOP_TITLE") % _tr_raw(npc.display_name)

	shop_panel.show()

	GameState.has_shown_inventory_tutorial = true
	show_toast(_t("SHOP_INVENTORY_HINT"), 3.0)

	_update_shop()


func _update_shop() -> void:
	shop_currency_label.text = _t("CURRENCY_AMOUNT") % GameState.currency

	for i in range(shop_item_buttons.size()):
		var button := shop_item_buttons[i]

		if i >= shop_items.size():
			button.hide()
			continue

		var item := shop_items[i]
		var item_name := String(item["name"])
		var price := int(item["price"])
		var description := String(item["description"])
		var owned := GameState.has_item(item_name)
		var status_text: String = _t("SHOP_OWNED") if owned else ""
		if GameState.is_health_potion_item(item_name):
			owned = GameState.has_bought_scene_health_potion()
			if not GameState.can_add_health_potion():
				owned = true
				status_text = _t("SHOP_LIMIT")
			elif owned:
				status_text = _t("SHOP_OWNED")
		elif GameState.is_rough_charm_item(item_name):
			owned = GameState.has_bought_scene_rough_charm()
			status_text = _t("SHOP_OWNED") if owned else ""

		button.show()
		button.disabled = owned
		button.text = _t("SHOP_ITEM_LINE") % [
			GameState.get_item_display_name(item_name),
			price,
			status_text,
			_tr_raw(description),
		]

	shop_close_hint_label.text = _format_action_text(_t("SHOP_HINT"))


func _rebuild_map() -> void:
	for child in map_canvas.get_children():
		child.queue_free()

	var scene_path := ""
	var scene := get_tree().current_scene

	if scene != null:
		scene_path = scene.scene_file_path

	var rooms := GameState.get_map_rooms(scene_path)

	map_title_label.text = _t("MAP_TITLE")
	map_hint_label.text = _format_action_text(_t("MAP_HINT"))

	if rooms.is_empty():
		_add_map_empty_label()
		return

	for room_id in rooms.keys():
		var data: Dictionary = rooms[room_id]
		var room_rect: Rect2 = data.get("rect", Rect2(0, 0, 80, 52))
		var visited := GameState.is_room_visited(scene_path, String(room_id))
		var is_current := scene_path == GameState.current_map_scene and String(room_id) == GameState.current_map_room

		_add_map_room(
			String(room_id),
			_tr_raw(String(data.get("display_name", room_id))),
			room_rect,
			visited,
			is_current
		)

	_add_player_map_marker(rooms)


func _apply_map_layout(mode: int) -> void:
	map_display_mode = mode
	map_canvas.scale = Vector2.ONE
	map_canvas.clip_contents = false
	map_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if mode == MAP_MODE_MINI:
		_set_control_rect(map_panel, MAP_PANEL_MINI_RECT)
		_set_control_rect(map_vbox, MAP_VBOX_MINI_RECT)
		map_corner_icon.hide()
		map_title_label.hide()
		map_hint_label.hide()
		map_canvas.custom_minimum_size = MAP_CANVAS_MINI_SIZE
		map_canvas.scale = MAP_MINI_SCALE
		map_canvas.clip_contents = true
		return

	_set_control_rect(map_panel, MAP_PANEL_FULL_RECT)
	_set_control_rect(map_vbox, MAP_VBOX_FULL_RECT)
	map_corner_icon.show()
	map_title_label.show()
	map_hint_label.show()
	map_canvas.custom_minimum_size = MAP_CANVAS_FULL_SIZE


func _set_control_rect(control: Control, rect: Rect2) -> void:
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y


func _add_map_empty_label() -> void:
	var label := Label.new()
	label.text = _t("MAP_EMPTY")
	label.add_theme_font_size_override("font_size", 12 if map_display_mode == MAP_MODE_MINI else 18)
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	label.clip_text = true
	label.position = Vector2(8, 8) if map_display_mode == MAP_MODE_MINI else Vector2(20, 20)
	label.size = Vector2(280, 70) if map_display_mode == MAP_MODE_MINI else Vector2(360, 40)

	map_canvas.add_child(label)


func _add_map_room(room_id: String, display_name: String, room_rect: Rect2, visited: bool, is_current: bool) -> void:
	var room := ColorRect.new()
	room.name = "MapRoom_%s" % room_id
	room.position = room_rect.position
	room.size = room_rect.size

	if visited:
		room.color = Color(0.18, 0.25, 0.30, 0.9)
	else:
		room.color = Color(0.07, 0.08, 0.10, 0.75)

	if is_current:
		room.color = Color(0.95, 0.72, 0.24, 0.95)

	map_canvas.add_child(room)

	var label := Label.new()
	label.text = display_name
	label.add_theme_font_size_override("font_size", 13)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = room_rect.position
	label.size = room_rect.size

	map_canvas.add_child(label)

func _add_player_map_marker(rooms: Dictionary) -> void:
	if GameState.current_map_room == "":
		return

	if not rooms.has(GameState.current_map_room):
		return

	var player := get_tree().get_first_node_in_group("player")

	if not player is Node2D:
		return

	var data: Dictionary = rooms[GameState.current_map_room]
	var room_rect: Rect2 = data.get("rect", Rect2())
	var world_rect: Rect2 = data.get("world_rect", Rect2())

	if room_rect.size == Vector2.ZERO or world_rect.size == Vector2.ZERO:
		return

	var player_position: Vector2 = player.global_position

	var x_ratio := inverse_lerp(world_rect.position.x, world_rect.end.x, player_position.x)
	var y_ratio := inverse_lerp(world_rect.position.y, world_rect.end.y, player_position.y)

	x_ratio = clampf(x_ratio, 0.0, 1.0)
	y_ratio = clampf(y_ratio, 0.0, 1.0)

	var marker := ColorRect.new()
	marker.name = "PlayerMapMarker"
	marker.color = Color(0.15, 1.0, 0.95, 1.0)
	marker.size = Vector2(12, 12)
	marker.position = room_rect.position + Vector2(
		room_rect.size.x * x_ratio,
		room_rect.size.y * y_ratio
	) - marker.size * 0.5

	map_canvas.add_child(marker)


func _on_shop_item_pressed(index: int) -> void:
	if index >= shop_items.size():
		return

	var item := shop_items[index]
	var item_name := String(item["name"])
	var price := int(item["price"])
	var is_health_potion := GameState.is_health_potion_item(item_name)
	var is_rough_charm := GameState.is_rough_charm_item(item_name)
	var purchase_item_name := GameState.HEALTH_POSITION_ITEM if is_health_potion else item_name

	if is_health_potion and GameState.has_bought_scene_health_potion():
		show_toast(_t("SHOP_ALREADY_HAVE") % GameState.get_item_display_name(purchase_item_name))
		return

	if is_health_potion and not GameState.can_add_health_potion():
		show_toast(_t("SHOP_POTION_LIMIT"))
		return

	if is_rough_charm and GameState.has_bought_scene_rough_charm():
		show_toast(_t("SHOP_ALREADY_HAVE") % GameState.get_item_display_name(item_name))
		return

	if not is_health_potion and not is_rough_charm and GameState.has_item(item_name):
		show_toast(_t("SHOP_ALREADY_HAVE") % GameState.get_item_display_name(item_name))
		return

	if not GameState.spend_currency(price):
		show_toast(_t("SHOP_NOT_ENOUGH_MONEY"))
		return

	if is_health_potion:
		GameState.add_health_potions(1)
		GameState.mark_scene_health_potion_bought()
	elif is_rough_charm:
		GameState.add_item(item_name)
		GameState.mark_scene_rough_charm_bought()
	else:
		GameState.add_item(item_name)
	GameState.save_game()

	show_toast(_t("SHOP_GOT_ITEM") % GameState.get_item_display_name(purchase_item_name))
	_update_shop()


func _on_currency_changed(amount: int) -> void:
	hud_currency_label.text = _t("CURRENCY_AMOUNT") % amount
	inventory_currency_label.text = _t("CURRENCY_AMOUNT") % amount
	shop_currency_label.text = _t("CURRENCY_AMOUNT") % amount


func _on_inventory_changed(items: Dictionary) -> void:
	_update_inventory_text(items)
	_update_shop()


func _on_first_item_obtained(_item_name: String) -> void:
	if GameState.has_shown_inventory_tutorial:
		return

	GameState.has_shown_inventory_tutorial = true
	show_toast(_t("INVENTORY_FIRST_HINT"), 3.2)


func _format_action_text(text: String) -> String:
	var input_settings: Node = get_node_or_null("/root/InputSettings")
	if input_settings == null:
		return text
	return String(input_settings.call("format_action_text", text))


func _t(key: String) -> String:
	var localization: Node = _get_localization()
	if localization != null and localization.has_method("text"):
		return String(localization.call("text", key))
	return key


func _tr_raw(text: String) -> String:
	var localization: Node = _get_localization()
	if localization != null and localization.has_method("translate_raw"):
		return String(localization.call("translate_raw", text))
	return text


func _get_localization() -> Node:
	return get_node_or_null("/root/Localization")


func _refresh_localized_texts() -> void:
	inventory_title_label.text = _t("INVENTORY_TITLE")
	map_title_label.text = _t("MAP_TITLE")
	map_hint_label.text = _format_action_text(_t("MAP_HINT"))
	_on_currency_changed(GameState.currency)
	if dialogue_panel.visible:
		if active_npc != null:
			dialogue_name_label.text = _tr_raw(active_npc.display_name)
		_show_dialogue_line()
	if inventory_panel.visible:
		_update_inventory_text(GameState.inventory)
	if shop_panel.visible:
		_update_shop()
	if map_panel.visible:
		_rebuild_map()


func _on_map_room_changed(_scene_path: String, _room_id: String) -> void:
	if map_panel.visible:
		_rebuild_map()


func _build_inventory_window() -> void:
	for child in inventory_panel.get_children():
		child.queue_free()

	inventory_tab_buttons.clear()
	inventory_category_buttons.clear()
	equipped_skill_slots.clear()

	_set_control_rect(inventory_panel, Rect2(76.0, 54.0, 1060.0, 548.0))
	inventory_panel.add_theme_stylebox_override("panel", _make_style(Color(0.025, 0.03, 0.04, 0.94), Color(0.58, 0.72, 0.84, 0.85), 2, 4))

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 14.0
	root.offset_top = 12.0
	root.offset_right = -14.0
	root.offset_bottom = -12.0
	root.add_theme_constant_override("separation", 8)
	inventory_panel.add_child(root)

	var tabs := HBoxContainer.new()
	tabs.custom_minimum_size = Vector2(0, 36)
	tabs.add_theme_constant_override("separation", 6)
	root.add_child(tabs)
	for tab_key in INVENTORY_TAB_KEYS:
		var tab_button := _make_tab_button(_t(tab_key))
		tab_button.set_meta("locale_key", tab_key)
		tab_button.pressed.connect(_select_inventory_tab.bind(tab_key))
		tabs.add_child(tab_button)
		inventory_tab_buttons.append(tab_button)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root.add_child(body)

	var profile_panel := VBoxContainer.new()
	profile_panel.custom_minimum_size = Vector2(230, 0)
	profile_panel.add_theme_constant_override("separation", 8)
	body.add_child(profile_panel)

	inventory_title_label = Label.new()
	inventory_title_label.text = _t("INV_TAB_CHARACTER")
	inventory_title_label.add_theme_font_size_override("font_size", 24)
	profile_panel.add_child(inventory_title_label)

	inventory_profile_label = Label.new()
	inventory_profile_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_profile_label.add_theme_font_size_override("font_size", 16)
	inventory_profile_label.clip_text = true
	inventory_profile_label.custom_minimum_size = Vector2(0, 196)
	profile_panel.add_child(inventory_profile_label)

	inventory_equipped_title_label = Label.new()
	inventory_equipped_title_label.text = _t("INV_EQUIPPED_SKILLS")
	inventory_equipped_title_label.add_theme_font_size_override("font_size", 17)
	profile_panel.add_child(inventory_equipped_title_label)

	var equipped_grid := GridContainer.new()
	equipped_grid.columns = 2
	equipped_grid.add_theme_constant_override("h_separation", 8)
	equipped_grid.add_theme_constant_override("v_separation", 8)
	profile_panel.add_child(equipped_grid)
	for i in range(EQUIPPED_SKILL_SLOT_COUNT):
		var slot := _make_slot_button(_t("INV_SKILL_SLOT") % (i + 1), Vector2(100, 58))
		slot.pressed.connect(_clear_equipped_skill.bind(i))
		equipped_grid.add_child(slot)
		equipped_skill_slots.append(slot)

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 8)
	body.add_child(center)

	var category_row := HBoxContainer.new()
	category_row.custom_minimum_size = Vector2(0, 34)
	category_row.add_theme_constant_override("separation", 6)
	center.add_child(category_row)
	for category_key in INVENTORY_CATEGORY_KEYS:
		var category_button := _make_tab_button(_t(category_key))
		category_button.set_meta("locale_key", category_key)
		category_button.pressed.connect(_select_inventory_category.bind(category_key))
		category_row.add_child(category_button)
		inventory_category_buttons.append(category_button)

	inventory_grid = GridContainer.new()
	inventory_grid.columns = 8
	inventory_grid.add_theme_constant_override("h_separation", 6)
	inventory_grid.add_theme_constant_override("v_separation", 6)
	center.add_child(inventory_grid)

	var right_panel := VBoxContainer.new()
	right_panel.custom_minimum_size = Vector2(245, 0)
	right_panel.add_theme_constant_override("separation", 8)
	body.add_child(right_panel)

	inventory_currency_label = Label.new()
	inventory_currency_label.add_theme_font_size_override("font_size", 17)
	right_panel.add_child(inventory_currency_label)

	inventory_detail_title = Label.new()
	inventory_detail_title.add_theme_font_size_override("font_size", 22)
	right_panel.add_child(inventory_detail_title)

	inventory_detail_type = Label.new()
	inventory_detail_type.add_theme_font_size_override("font_size", 15)
	right_panel.add_child(inventory_detail_type)

	inventory_detail_description = Label.new()
	inventory_detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_detail_description.add_theme_font_size_override("font_size", 15)
	inventory_detail_description.clip_text = true
	right_panel.add_child(inventory_detail_description)

	inventory_hint_label = Label.new()
	inventory_hint_label.text = _format_action_text(_t("INV_HINT"))
	inventory_hint_label.add_theme_font_size_override("font_size", 14)
	inventory_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_panel.add_child(inventory_hint_label)


func _reset_equipped_skills() -> void:
	equipped_skills.clear()
	for _i in range(EQUIPPED_SKILL_SLOT_COUNT):
		equipped_skills.append({})


func _select_inventory_tab(tab_key: String) -> void:
	selected_inventory_tab_key = tab_key
	if tab_key == "INV_TAB_MAP":
		close_all_windows()
		_show_full_map()
		return
	_update_inventory_text(GameState.inventory)


func _select_inventory_category(category_key: String) -> void:
	selected_inventory_category_key = category_key
	_update_inventory_text(GameState.inventory)


func _update_inventory_text(items: Dictionary) -> void:
	if inventory_grid == null:
		return

	_refresh_inventory_header()
	_refresh_inventory_buttons()
	_refresh_equipped_skill_slots()
	_rebuild_inventory_grid(items)


func _refresh_inventory_header() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var hp_text := "?"
	var max_hp_text := "?"
	if player != null:
		hp_text = "%s" % player.current_health
		max_hp_text = "%s" % player.max_health

	inventory_title_label.text = _t(selected_inventory_tab_key)
	if inventory_equipped_title_label != null:
		inventory_equipped_title_label.text = _t("INV_EQUIPPED_SKILLS")
	if inventory_hint_label != null:
		inventory_hint_label.text = _format_action_text(_t("INV_HINT"))
	inventory_profile_label.text = _t("INV_PROFILE_TEXT") % [
		hp_text,
		max_hp_text,
		GameState.currency,
		EQUIPPED_SKILL_SLOT_COUNT,
	]
	inventory_currency_label.text = _t("CURRENCY_AMOUNT") % GameState.currency
	inventory_detail_title.text = _t(selected_inventory_tab_key)
	inventory_detail_type.text = _t("INV_SELECT_ITEM")
	inventory_detail_description.text = _t("INV_DEFAULT_DESC")


func _refresh_inventory_buttons() -> void:
	for button in inventory_tab_buttons:
		var tab_key := String(button.get_meta("locale_key", ""))
		button.text = _t(tab_key)
		button.button_pressed = tab_key == selected_inventory_tab_key
	for button in inventory_category_buttons:
		var category_key := String(button.get_meta("locale_key", ""))
		button.text = _t(category_key)
		button.button_pressed = category_key == selected_inventory_category_key
		button.visible = selected_inventory_tab_key == "INV_TAB_BAG"


func _refresh_equipped_skill_slots() -> void:
	for i in range(equipped_skill_slots.size()):
		var slot := equipped_skill_slots[i]
		var skill: Dictionary = equipped_skills[i]
		if skill.is_empty():
			slot.text = _t("INV_SKILL_SLOT_EMPTY") % (i + 1)
			slot.icon = null
		else:
			slot.text = _t("INV_SKILL_SLOT_EQUIPPED") % [i + 1, _entry_name(skill)]
			slot.icon = _load_texture(String(skill["texture"]), SKILL_TEXTURE)


func _rebuild_inventory_grid(items: Dictionary) -> void:
	for child in inventory_grid.get_children():
		child.queue_free()

	if selected_inventory_tab_key == "INV_TAB_SKILLS":
		inventory_grid.columns = 1
		inventory_grid.add_child(_make_skill_tree_panel())
		return

	inventory_grid.columns = 8
	var entries := _get_inventory_entries(items)
	for i in range(GRID_SLOT_COUNT):
		if i < entries.size():
			var entry: Dictionary = entries[i]
			inventory_grid.add_child(_make_inventory_cell(entry))
		else:
			inventory_grid.add_child(_make_empty_cell())


func _get_inventory_entries(items: Dictionary) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if selected_inventory_tab_key == "INV_TAB_CHARACTER":
		entries.append({"name_key": "INV_CHARACTER_DATA", "type_key": "INV_TAB_CHARACTER", "description": inventory_profile_label.text, "kind": "info", "texture": ""})
		entries.append({"name_key": "INV_FUTURE_STATS", "type_key": "INV_TAB_CHARACTER", "description_key": "INV_FUTURE_STATS_DESC", "kind": "info", "texture": ""})
	elif selected_inventory_tab_key == "INV_TAB_SKILLS":
		for skill in SKILL_LIBRARY:
			entries.append(skill.duplicate(true).merged({"kind": "skill"}))
	elif selected_inventory_tab_key == "INV_TAB_BAG":
		for item_name in items.keys():
			var raw_name := String(item_name)
			var item_type_key := _get_item_type_key(raw_name)
			if selected_inventory_category_key != "INV_CAT_ALL" and selected_inventory_category_key != item_type_key:
				continue
			entries.append({
				"name": GameState.get_item_display_name(raw_name),
				"raw_name": raw_name,
				"amount": int(items[item_name]),
				"type_key": item_type_key,
				"description": GameState.get_item_description(raw_name),
				"kind": "item",
				"texture": "res://assets/some/Health_Potion.png" if GameState.is_health_potion_item(raw_name) else "res://assets/enemy/enemy2.png",
			})
	elif selected_inventory_tab_key == "INV_TAB_SYSTEM":
		entries.append({"name_key": "INV_CONTROLS", "type_key": "INV_TAB_SYSTEM", "description_key": "INV_CONTROLS_DESC", "kind": "info", "texture": ""})

	return entries


func _make_skill_tree_panel() -> Control:
	var panel := Control.new()
	panel.custom_minimum_size = Vector2(600, 360)

	var ring := Panel.new()
	ring.position = Vector2(118, 18)
	ring.size = Vector2(360, 320)
	ring.add_theme_stylebox_override("panel", _make_style(Color(0.025, 0.018, 0.022, 0.72), Color(0.62, 0.14, 0.17, 0.85), 2, 4))
	panel.add_child(ring)

	var title := Label.new()
	title.text = _t("INV_SKILL_TREE")
	title.position = Vector2(246, 30)
	title.size = Vector2(104, 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	panel.add_child(title)

	var center := Button.new()
	center.text = _t("INV_SKILL_CORE_LOCKED")
	center.position = Vector2(254, 148)
	center.custom_minimum_size = Vector2(88, 64)
	center.size = Vector2(88, 64)
	center.disabled = true
	center.add_theme_font_size_override("font_size", 13)
	center.add_theme_stylebox_override("disabled", _make_style(Color(0.12, 0.025, 0.035, 0.96), Color(0.85, 0.25, 0.28, 1.0), 2, 4))
	panel.add_child(center)

	var positions := [
		Vector2(254, 68),
		Vector2(378, 126),
		Vector2(330, 246),
		Vector2(178, 246),
		Vector2(130, 126),
	]
	for i in range(min(SKILL_LIBRARY.size(), positions.size())):
		var skill: Dictionary = SKILL_LIBRARY[i]
		var skill_button := _make_skill_node_button(skill)
		skill_button.position = positions[i]
		skill_button.pressed.connect(_on_inventory_entry_pressed.bind(skill.duplicate(true).merged({"kind": "skill"})))
		panel.add_child(skill_button)

	return panel


func _make_skill_node_button(skill: Dictionary) -> Button:
	var button := Button.new()
	button.text = _entry_name(skill)
	button.icon = _load_texture(String(skill.get("texture", "")), SKILL_TEXTURE)
	button.custom_minimum_size = Vector2(90, 58)
	button.size = Vector2(90, 58)
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.clip_text = true
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_stylebox_override("normal", _make_style(Color(0.035, 0.02, 0.024, 0.94), Color(0.45, 0.12, 0.15, 0.95), 2, 4))
	button.add_theme_stylebox_override("hover", _make_style(Color(0.08, 0.035, 0.04, 0.98), Color(0.86, 0.28, 0.3, 1.0), 2, 4))
	button.add_theme_stylebox_override("pressed", _make_style(Color(0.14, 0.04, 0.045, 1.0), Color(0.95, 0.42, 0.34, 1.0), 2, 4))
	return button


func _get_item_type_key(item_name: String) -> String:
	if GameState.is_health_potion_item(item_name):
		return "INV_CAT_CONSUMABLE"
	if GameState.is_rough_charm_item(item_name):
		return "INV_CAT_IMPORTANT"
	if item_name.to_lower().contains("skill"):
		return "INV_CAT_SKILL"
	return "INV_CAT_MATERIAL"


func _make_inventory_cell(entry: Dictionary) -> Button:
	var button := _make_slot_button("", Vector2(58, 58))
	button.text = "%s\nx%d" % [_entry_name(entry), int(entry.get("amount", 1))] if entry.get("kind", "item") == "item" else _entry_name(entry)
	button.icon = _load_texture(String(entry.get("texture", "")), SKILL_TEXTURE if entry.get("kind") == "skill" else ITEM_TEXTURE)
	button.add_theme_font_size_override("font_size", 12)
	button.pressed.connect(_on_inventory_entry_pressed.bind(entry))
	return button


func _make_empty_cell() -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(58, 58)
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.01, 0.012, 0.016, 0.55), Color(0.28, 0.34, 0.38, 0.55), 1, 2))
	return panel


func _on_inventory_entry_pressed(entry: Dictionary) -> void:
	inventory_detail_title.text = _entry_name(entry)
	inventory_detail_type.text = _entry_type(entry)
	inventory_detail_description.text = _entry_description(entry)
	if entry.get("kind") == "skill":
		_equip_skill(entry)


func _equip_skill(skill: Dictionary) -> void:
	var target_index := 0
	for i in range(equipped_skills.size()):
		if equipped_skills[i].is_empty():
			target_index = i
			break
	equipped_skills[target_index] = skill.duplicate(true)
	_refresh_equipped_skill_slots()


func _clear_equipped_skill(index: int) -> void:
	if index < 0 or index >= equipped_skills.size():
		return
	equipped_skills[index] = {}
	_refresh_equipped_skill_slots()


func _make_tab_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(100, 32)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_stylebox_override("normal", _make_style(Color(0.04, 0.05, 0.065, 0.9), Color(0.26, 0.34, 0.42, 0.9), 1, 2))
	button.add_theme_stylebox_override("pressed", _make_style(Color(0.12, 0.025, 0.035, 0.95), Color(0.82, 0.22, 0.24, 1.0), 2, 2))
	return button


func _make_slot_button(text: String, min_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.clip_text = true
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_stylebox_override("normal", _make_style(Color(0.01, 0.012, 0.016, 0.85), Color(0.33, 0.39, 0.45, 0.9), 2, 2))
	button.add_theme_stylebox_override("hover", _make_style(Color(0.045, 0.06, 0.075, 0.95), Color(0.78, 0.88, 0.95, 1.0), 2, 2))
	button.add_theme_stylebox_override("pressed", _make_style(Color(0.1, 0.035, 0.045, 0.96), Color(0.85, 0.25, 0.28, 1.0), 2, 2))
	return button


func _entry_name(entry: Dictionary) -> String:
	if entry.has("name_key"):
		return _t(String(entry["name_key"]))
	return _tr_raw(String(entry.get("name", "")))


func _entry_type(entry: Dictionary) -> String:
	if entry.has("type_key"):
		return _t(String(entry["type_key"]))
	return _tr_raw(String(entry.get("type", "Item")))


func _entry_description(entry: Dictionary) -> String:
	if entry.has("description_key"):
		return _t(String(entry["description_key"]))
	return _tr_raw(String(entry.get("description", "")))


func _make_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _load_texture(path: String, fallback: Texture2D) -> Texture2D:
	if path == "":
		return fallback
	var texture := load(path)
	return texture if texture is Texture2D else fallback
