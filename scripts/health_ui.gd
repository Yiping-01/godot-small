extends CanvasLayer

const HEART_TEXTURE := preload("res://assets/Temporary_Art/Hearts/PNG/basic/heart.png")
const HEART_FRAME_TEXTURE := preload("res://assets/Temporary_Art/Hearts/PNG/basic/border.png")
const POTION_TEXTURE := preload("res://assets/some/Health_Potion.png")

@onready var label: Label = $HealthLabel
@onready var health_pips: HBoxContainer = $HealthPips

var hearts: Array[Control] = []
var potion_count_label: Label
var skill_tooltip: Panel


func _ready() -> void:
	_build_potion_counter()
	_build_boss_skill_slots()
	GameState.health_potions_changed.connect(_on_health_potions_changed)
	_on_health_potions_changed(GameState.get_health_potion_count())

	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		label.text = "HP: ? / ?"
		return

	player.health_changed.connect(_on_health_changed)
	player.died.connect(_on_player_died)
	player.respawned.connect(_on_player_respawned)
	_build_health_pips(player.max_health)
	_on_health_changed(player.current_health, player.max_health)


func _on_health_changed(current_health: float, max_health: int) -> void:
	if hearts.size() != max_health:
		_build_health_pips(max_health)

	var health_text := ""
	if is_equal_approx(current_health, float(int(current_health))):
		health_text = "%d" % int(current_health)
	else:
		health_text = "%.1f" % current_health

	label.text = "HP: %s / %d" % [health_text, max_health]
	for i in range(hearts.size()):
		var fill := clampf(current_health - float(i), 0.0, 1.0)
		hearts[i].offset_right = 34.0 * fill


func _on_health_potions_changed(amount: int) -> void:
	if potion_count_label != null:
		potion_count_label.text = "x%d" % amount


func _on_player_died() -> void:
	label.text += "  DEAD"


func _on_player_respawned() -> void:
	label.modulate = Color.WHITE


func _build_health_pips(max_health: int) -> void:
	for child in health_pips.get_children():
		child.queue_free()

	hearts.clear()
	for i in range(max_health):
		var slot := Control.new()
		slot.custom_minimum_size = Vector2(34, 34)

		var frame := TextureRect.new()
		frame.texture = HEART_FRAME_TEXTURE
		frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		frame.set_anchors_preset(Control.PRESET_FULL_RECT)

		var empty_heart := TextureRect.new()
		empty_heart.texture = HEART_TEXTURE
		empty_heart.modulate = Color(0.35, 0.35, 0.35, 0.35)
		empty_heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		empty_heart.set_anchors_preset(Control.PRESET_FULL_RECT)

		var heart_clip := Control.new()
		heart_clip.clip_contents = true
		heart_clip.offset_left = 0.0
		heart_clip.offset_top = 0.0
		heart_clip.offset_right = 34.0
		heart_clip.offset_bottom = 34.0

		var heart := TextureRect.new()
		heart.texture = HEART_TEXTURE
		heart.position = Vector2.ZERO
		heart.size = Vector2(34, 34)
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		slot.add_child(frame)
		slot.add_child(empty_heart)
		heart_clip.add_child(heart)
		slot.add_child(heart_clip)
		health_pips.add_child(slot)
		hearts.append(heart_clip)


func _build_potion_counter() -> void:
	var row := HBoxContainer.new()
	row.name = "HealthPotionCounter"
	row.add_theme_constant_override("separation", 4)
	row.offset_left = 22.0
	row.offset_top = 84.0
	row.offset_right = 120.0
	row.offset_bottom = 118.0

	var icon := TextureRect.new()
	icon.texture = POTION_TEXTURE
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)

	potion_count_label = Label.new()
	potion_count_label.text = "x0"
	potion_count_label.add_theme_font_size_override("font_size", 18)
	row.add_child(potion_count_label)
	add_child(row)


func _build_boss_skill_slots() -> void:
	var row := HBoxContainer.new()
	row.name = "BossSkillSlots"
	row.add_theme_constant_override("separation", 10)
	row.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	row.offset_left = 22.0
	row.offset_top = -66.0
	row.offset_right = 126.0
	row.offset_bottom = -22.0

	for i in range(2):
		var slot := Panel.new()
		slot.name = "BossSkillSlot%d" % (i + 1)
		slot.custom_minimum_size = Vector2(50, 50)

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.02, 0.03, 0.04, 0.35)
		style.border_color = Color(0.86, 0.92, 1.0, 0.78)
		style.set_border_width_all(3)
		style.set_corner_radius_all(22)
		slot.add_theme_stylebox_override("panel", style)
		slot.mouse_entered.connect(_show_skill_tooltip.bind(slot))
		slot.mouse_exited.connect(_hide_skill_tooltip)

		row.add_child(slot)

	add_child(row)
	_build_skill_tooltip()


func _build_skill_tooltip() -> void:
	skill_tooltip = Panel.new()
	skill_tooltip.name = "SkillTooltip"
	skill_tooltip.custom_minimum_size = Vector2(128, 34)
	skill_tooltip.size = Vector2(128, 34)
	skill_tooltip.hide()

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.72)
	style.border_color = Color(0.55, 0.55, 0.55, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	skill_tooltip.add_theme_stylebox_override("panel", style)

	var tooltip_label := Label.new()
	tooltip_label.text = "技能尚未取得"
	tooltip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tooltip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tooltip_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	tooltip_label.add_theme_font_size_override("font_size", 14)
	skill_tooltip.add_child(tooltip_label)

	add_child(skill_tooltip)


func _show_skill_tooltip(slot: Control) -> void:
	if skill_tooltip == null:
		return

	skill_tooltip.position = slot.get_global_rect().position + Vector2(
		slot.size.x * 0.5 - skill_tooltip.size.x * 0.5,
		-skill_tooltip.size.y - 8.0
	)
	skill_tooltip.show()


func _hide_skill_tooltip() -> void:
	if skill_tooltip != null:
		skill_tooltip.hide()
