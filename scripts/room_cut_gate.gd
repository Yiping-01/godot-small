extends Area2D
class_name RoomCutGate

@export var room_id := ""
@export var room_display_name := ""
@export var limit_left: int = -10000000
@export var limit_top: int = -10000000
@export var limit_right: int = 10000000
@export var limit_bottom: int = 10000000
@export var enabled := true
@export var only_when_visible := true
@export var respawn_enemies_on_enter := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not enabled:
		return
	if only_when_visible and not is_visible_in_tree():
		return
	if not body.is_in_group("player"):
		return

	# Room gates now update room state only; the camera stays attached to the player.
	if room_id != "":
		GameState.set_current_map_room(get_tree().current_scene.scene_file_path, room_id)

	if respawn_enemies_on_enter:
		var manager := get_tree().get_first_node_in_group("room_manager")
		if manager != null and manager.has_method("on_room_transition"):
			manager.on_room_transition()
