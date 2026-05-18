extends Area2D

@export var max_health := 10
@export var visual_path: NodePath
@export var pause_duration_after_cord_cut := 3.0
@export var death_fade_duration := 1.0

var health := 0
var _flash_tween: Tween
var _pause_token := 0
var _defeated := false


func _ready() -> void:
	health = max_health
	add_to_group("boss_bg_target")
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)


func take_damage(amount: int, _from_position: Vector2 = Vector2.ZERO) -> void:
	if _defeated or not monitorable:
		return

	health -= amount
	if health > 0:
		_flash_hit()
		return

	_defeated = true
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)
	_stop_boss_hand_attacks()
	_fade_out_visual()


func pause_after_cord_cut() -> void:
	if _defeated:
		return

	var visual := _get_visual()
	if visual is AnimatedSprite2D:
		_pause_token += 1
		var current_token := _pause_token
		if visual.sprite_frames != null and visual.sprite_frames.has_animation(&"stunned"):
			visual.play(&"stunned")
		else:
			visual.pause()
		set_deferred("monitorable", true)
		set_deferred("monitoring", true)
		await get_tree().create_timer(pause_duration_after_cord_cut).timeout
		if current_token == _pause_token and is_instance_valid(visual) and not _defeated:
			if visual.sprite_frames != null and visual.sprite_frames.has_animation(&"attack"):
				visual.play(&"attack")
			else:
				visual.play()
			set_deferred("monitorable", false)
			set_deferred("monitoring", false)


func _flash_hit() -> void:
	if _flash_tween != null:
		_flash_tween.kill()

	_set_visual_modulate(Color(1.0, 0.35, 0.35, 1.0))
	_flash_tween = create_tween()
	_flash_tween.tween_interval(0.04)
	_flash_tween.tween_method(_set_visual_modulate, Color(1.0, 0.35, 0.35, 1.0), Color.WHITE, 0.12)


func _stop_visual() -> void:
	var visual := _get_visual()
	if visual is AnimatedSprite2D:
		visual.stop()


func _hide_visual() -> void:
	var visual := _get_visual()
	if visual is AnimatedSprite2D:
		visual.stop()
	if visual is CanvasItem:
		visual.visible = false


func _fade_out_visual() -> void:
	var visual := _get_visual()
	if visual is AnimatedSprite2D:
		visual.stop()
	if not visual is CanvasItem:
		return

	if _flash_tween != null:
		_flash_tween.kill()

	var canvas_item := visual as CanvasItem
	canvas_item.modulate = Color.WHITE
	var tween := create_tween()
	tween.tween_property(canvas_item, "modulate:a", 0.0, death_fade_duration)
	tween.tween_callback(_hide_visual)


func _stop_boss_hand_attacks() -> void:
	var parent := get_parent()
	if parent == null:
		return

	var hand_attack := parent.get_node_or_null("BossHandAttack")
	if hand_attack != null and hand_attack.has_method("stop_attacks"):
		hand_attack.call("stop_attacks")


func _set_visual_modulate(color: Color) -> void:
	var visual := _get_visual()
	if visual is CanvasItem:
		visual.modulate = color


func _get_visual() -> Node:
	return get_node_or_null(visual_path)
