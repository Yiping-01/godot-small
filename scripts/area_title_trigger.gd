extends Area2D
class_name AreaTitleTrigger

@export var main_title := "Forgotten Test Path"
@export var sub_title := "Prototype route"

var triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if triggered or not body.is_in_group("player"):
		return

	triggered = true
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null:
		ui.show_area_title(main_title, sub_title)
