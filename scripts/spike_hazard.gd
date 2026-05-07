extends Area2D

@export var damage: int = 1


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _damage_target(target: Node) -> void:
	var current := target
	while current != null:
		if current.has_method("take_damage"):
			current.call("take_damage", damage, global_position)
			return
		current = current.get_parent()


func _on_body_entered(body: Node2D) -> void:
	_damage_target(body)


func _on_area_entered(area: Area2D) -> void:
	_damage_target(area)
