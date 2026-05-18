extends Node2D

@export var damage := 1
@export var warning_time := 1.0
@export var active_time := 0.35

var _hit_targets := {}

@onready var warning_visual: CanvasItem = get_node_or_null("WarningVisual") as CanvasItem
@onready var lightning_visual: CanvasItem = get_node_or_null("LightningVisual") as CanvasItem
@onready var damage_area: Area2D = get_node_or_null("DamageArea") as Area2D
@onready var damage_shape: CollisionShape2D = get_node_or_null("DamageArea/CollisionShape2D") as CollisionShape2D


func _ready() -> void:
	if warning_visual != null:
		warning_visual.visible = true
	if lightning_visual != null:
		lightning_visual.visible = false
	if damage_area != null:
		damage_area.collision_layer = 32
		damage_area.collision_mask = 16
		damage_area.monitoring = false
		damage_area.area_entered.connect(_on_damage_area_entered)
	if damage_shape != null:
		damage_shape.disabled = true
	call_deferred("_strike")


func _strike() -> void:
	await get_tree().create_timer(warning_time).timeout
	if warning_visual != null:
		warning_visual.visible = false
	if lightning_visual != null:
		lightning_visual.visible = true

	_set_damage_enabled(true)
	await get_tree().physics_frame
	_damage_current_overlaps()
	await get_tree().create_timer(active_time).timeout
	_set_damage_enabled(false)
	queue_free()


func _set_damage_enabled(enabled: bool) -> void:
	if damage_area != null:
		damage_area.set_deferred("monitoring", enabled)
	if damage_shape != null:
		damage_shape.set_deferred("disabled", not enabled)


func _on_damage_area_entered(area: Area2D) -> void:
	_damage_target(area)


func _damage_current_overlaps() -> void:
	if damage_area == null:
		return
	for area in damage_area.get_overlapping_areas():
		_damage_target(area)


func _damage_target(target: Node) -> void:
	var receiver := _find_damage_receiver(target)
	if receiver == null:
		return
	var instance_id := int(receiver.get_instance_id())
	if _hit_targets.has(instance_id):
		return
	_hit_targets[instance_id] = true
	receiver.call("take_damage", damage, global_position)


func _find_damage_receiver(target: Node) -> Node:
	var current := target
	while current != null:
		if current.has_method("take_damage"):
			return current
		current = current.get_parent()
	return null
