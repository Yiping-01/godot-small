extends Area2D


func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	var wire := get_parent()
	if wire != null and wire.has_method("take_damage"):
		wire.call("take_damage", amount, from_position)
