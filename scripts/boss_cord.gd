extends Area2D

@export var health := 10
@export var visual_path: NodePath

var _is_cut := false
var _flash_tween: Tween


func take_damage(amount: int, _from_position: Vector2 = Vector2.ZERO) -> void:
	if _is_cut:
		return

	health -= amount
	if health > 0:
		_flash_hit()
		return

	_is_cut = true
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)
	_pause_background_boss()

	_clear_visuals()

	queue_free()


func _flash_hit() -> void:
	if _flash_tween != null:
		_flash_tween.kill()

	var visuals := _get_visuals()
	for visual in visuals:
		visual.modulate = Color(1.0, 0.35, 0.35)

	_flash_tween = create_tween()
	_flash_tween.tween_interval(0.04)
	_flash_tween.tween_method(_set_visuals_modulate.bind(visuals), Color(1.0, 0.35, 0.35), Color.WHITE, 0.12)


func _set_visuals_modulate(color: Color, visuals: Array[CanvasItem]) -> void:
	for visual in visuals:
		if is_instance_valid(visual):
			visual.modulate = color


func _clear_visuals() -> void:
	for visual in _get_visuals():
		visual.queue_free()


func _pause_background_boss() -> void:
	var boss_bg := get_tree().get_first_node_in_group("boss_bg_target")
	if boss_bg != null and boss_bg.has_method("pause_after_cord_cut"):
		boss_bg.call("pause_after_cord_cut")


func _get_visuals() -> Array[CanvasItem]:
	var visuals: Array[CanvasItem] = []

	var visual := get_node_or_null(visual_path)
	if visual is CanvasItem:
		visuals.append(visual)

	var parent := get_parent()
	if parent == null:
		return visuals

	var prefix := name.trim_suffix("Hitbox")
	for child in parent.get_children():
		if child == self:
			continue
		if child.name.begins_with(prefix) and child is CanvasItem and not visuals.has(child):
			visuals.append(child)

	return visuals
