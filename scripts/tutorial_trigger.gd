extends Area2D
class_name TutorialTrigger

@export_multiline var tutorial_text := "教學提示"
@export var enabled := true
@export var display_time := 2.8
@export var one_shot := true
@export var hide_when_exit := true

var triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if not enabled:
		return
	if not is_visible_in_tree():
		return
	if one_shot and triggered:
		return
	if not body.is_in_group("player"):
		return

	triggered = true
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null:
		if ui.has_method("is_area_title_visible"):
			while ui.is_area_title_visible():
				await get_tree().process_frame
		ui.show_tutorial(tutorial_text, display_time)


func _on_body_exited(body: Node2D) -> void:
	if not hide_when_exit or not body.is_in_group("player"):
		return

	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null and ui.has_method("hide_tutorial"):
		ui.hide_tutorial()
