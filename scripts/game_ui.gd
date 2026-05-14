extends CanvasLayer

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
@onready var inventory_list: VBoxContainer = $InventoryPanel/VBoxContainer/InventoryScroll/InventoryList
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


func _update_inventory_text(items: Dictionary) -> void:
	for child in inventory_list.get_children():
		child.queue_free()

	if items.is_empty():
		_add_inventory_empty_row()
		return

	for item_name in items.keys():
		_add_inventory_row(String(item_name), int(items[item_name]))


func _add_inventory_empty_row() -> void:
	var label := Label.new()
	label.text = _t("INVENTORY_EMPTY")
	label.add_theme_font_size_override("font_size", 18)

	inventory_list.add_child(label)


func _add_inventory_row(item_name: String, amount: int) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 72)
	row.add_theme_constant_override("separation", 10)

	var icon_slot := CenterContainer.new()
	icon_slot.custom_minimum_size = Vector2(56, 56)
	row.add_child(icon_slot)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(45, 45)

	if GameState.is_health_potion_item(item_name):
		icon.texture = preload("res://assets/some/Health_Potion.png")
	else:
		icon.texture = preload("res://assets/enemy/enemy2.png")

	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	icon_slot.add_child(icon)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.text = "%s x%d" % [GameState.get_item_display_name(item_name), amount]

	var desc_label := Label.new()
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.text = GameState.get_item_description(item_name)

	text_box.add_child(name_label)
	text_box.add_child(desc_label)

	row.add_child(text_box)
	inventory_list.add_child(row)
