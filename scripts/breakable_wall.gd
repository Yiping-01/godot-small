extends StaticBody2D

@export var max_health: int = 3
@onready var visual: Polygon2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox

var health := 0
var broken := false


func _ready() -> void:
	health = max_health


func take_damage(amount: int, _from_position: Vector2 = Vector2.ZERO) -> void:
	if broken:
		return

	health -= amount
	_flash()
	if health <= 0:
		_break()


func _flash() -> void:
	var tween := create_tween()
	tween.tween_property(visual, "color", Color(0.95, 0.78, 0.42), 0.04)
	tween.tween_property(visual, "color", Color(0.28, 0.2, 0.16), 0.12)


func _break() -> void:
	broken = true
	collision_shape.set_deferred("disabled", true)
	hurtbox.monitorable = false
	hurtbox.monitoring = false
	visible = false
