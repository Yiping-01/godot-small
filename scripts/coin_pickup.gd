extends RigidBody2D

@export var value: int = 1
@export var max_horizontal_speed: float = 360.0
@export var min_up_speed: float = 420.0
@export var max_up_speed: float = 620.0
@export var pickup_delay: float = 0.25

@onready var pickup_area: Area2D = $PickupArea

var can_pickup := false


func _ready() -> void:
	gravity_scale = 1.25
	linear_damp = 0.35
	angular_damp = 1.5
	pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	await get_tree().create_timer(pickup_delay).timeout
	can_pickup = true


func launch_from(spawn_position: Vector2) -> void:
	global_position = spawn_position
	var horizontal := randf_range(-max_horizontal_speed, max_horizontal_speed)
	var upward := -randf_range(min_up_speed, max_up_speed)
	linear_velocity = Vector2(horizontal, upward)
	angular_velocity = randf_range(-8.0, 8.0)


func _on_pickup_area_body_entered(body: Node2D) -> void:
	if not can_pickup or not body.is_in_group("player"):
		return

	GameState.add_currency(value)
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null:
		var localization: Node = get_node_or_null("/root/Localization")
		var text: String = "取得金錢 +%d"
		if localization != null and localization.has_method("text"):
			text = String(localization.call("text", "TOAST_COIN"))
		ui.show_toast(text % value)
	queue_free()
