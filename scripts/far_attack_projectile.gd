extends Area2D

var direction := 1
var speed := 640.0
var damage := 1
var lifetime := 0.55
var hit_radius := 22.0
var hit_targets := {}


func setup(sprite_frames: SpriteFrames, attack_direction: int, attack_speed: float, attack_damage: int, duration: float, radius: float, effect_scale: Vector2) -> void:
	direction = attack_direction
	speed = attack_speed
	damage = attack_damage
	lifetime = duration
	hit_radius = radius

	collision_layer = 8
	collision_mask = 4
	monitoring = true
	monitorable = false

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = hit_radius
	shape.shape = circle
	add_child(shape)

	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = sprite_frames
	sprite.animation = &"fly"
	sprite.scale = effect_scale
	sprite.flip_h = direction < 0
	add_child(sprite)
	sprite.play(&"fly")

	body_entered.connect(_on_target_entered)
	area_entered.connect(_on_target_entered)


func _physics_process(delta: float) -> void:
	position.x += float(direction) * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_target_entered(target: Node) -> void:
	var receiver := _find_damage_receiver(target)
	if receiver == null or hit_targets.has(receiver.get_instance_id()):
		return

	hit_targets[receiver.get_instance_id()] = true
	receiver.call("take_damage", damage, global_position)
	queue_free()


func _find_damage_receiver(target: Node) -> Node:
	var current := target
	while current != null:
		if current.has_method("take_damage"):
			return current
		current = current.get_parent()
	return null
