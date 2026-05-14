extends CharacterBody2D

@export var hp := 3
@export var damage := 1
@export var speed := 80.0
@export var patrol_distance := 120.0
@export var knockback_force := 350.0
@export var knockback_friction := 1600.0
@export var hurt_flash_time := 0.15
@export var death_fade_time := 0.45
@export var can_split := false
@export var small_enemy_scene: PackedScene
@export var small_enemy_scene_path := "res://scenes/enemy.tscn"
@export var respawn_scene_path := "res://scenes/legacy_split_enemy.tscn"
@export var spawn_protection_time := 0.35

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var direction := -1
var start_position := Vector2.ZERO
var knockback_velocity := Vector2.ZERO
var hurt_tween: Tween
var can_take_damage := true
var is_dead := false


func _ready() -> void:
	start_position = global_position
	add_to_group("enemy")
	anim.play("walk")
	anim.flip_h = direction > 0
	$HurtBox.area_entered.connect(_on_hurtbox_area_entered)
	$HurtBox.body_entered.connect(_on_hurtbox_body_entered)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if knockback_velocity.length() > 5.0:
		velocity.x = knockback_velocity.x
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	else:
		_turn_around_at_patrol_edge()
		velocity.x = direction * speed

	move_and_slide()
	_keep_inside_patrol_range()

	if is_on_wall():
		_turn_around()


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if not can_take_damage:
		return

	if area.name == "AttackArea" or area.name == "UpAttackArea" or area.name == "DownAttackArea" or area.name == "ChargeAttackArea":
		var attacker := area.get_parent()
		if attacker is Node2D:
			take_damage(1, attacker.global_position)


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage, global_position)


func take_damage(amount: int, attacker_position: Vector2) -> void:
	if is_dead or not can_take_damage:
		return

	hp -= amount

	if global_position.x > attacker_position.x:
		knockback_velocity = Vector2(knockback_force, 0.0)
	else:
		knockback_velocity = Vector2(-knockback_force, 0.0)

	_flash_hurt()

	if hp <= 0:
		_die()


func _die() -> void:
	is_dead = true
	can_take_damage = false
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 1
	if has_node("HurtBox"):
		$HurtBox.set_deferred("monitoring", false)
		$HurtBox.set_deferred("monitorable", false)

	if can_split:
		call_deferred("split")

	await _fade_out_death(anim, death_fade_time)
	queue_free()


func _fade_out_death(target: CanvasItem, duration: float) -> void:
	if target == null:
		return

	target.material = null
	target.modulate = Color(1.0, 0.35, 0.28, 0.9)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(target, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(target, "scale", target.scale * 0.82, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished


func split() -> void:
	var parent := get_parent()
	if parent == null:
		return

	var scene := small_enemy_scene
	if scene == null:
		scene = load(small_enemy_scene_path)

	if scene == null:
		return

	var launch_directions := [-1, 1, 1]
	for i in range(3):
		var small := scene.instantiate()
		var launch_direction: int = launch_directions[i]
		if i == 1:
			launch_direction = -direction
		var spawn_position := global_position + Vector2(float(launch_direction) * randf_range(34.0, 74.0), randf_range(-34.0, -12.0))
		if small is Node2D:
			if parent is Node2D:
				small.position = (parent as Node2D).to_local(spawn_position)
			else:
				small.global_position = spawn_position

		parent.add_child(small)
		if small.has_method("start_spawn_protection"):
			small.start_spawn_protection()
		if small.has_method("launch_from_split"):
			small.launch_from_split(launch_direction, randf_range(320.0, 430.0), 0.38)
		elif small.has_method("set_direction"):
			small.set_direction(launch_direction)


func start_spawn_protection() -> void:
	can_take_damage = false


func finish_spawn_protection() -> void:
	await get_tree().create_timer(spawn_protection_time).timeout
	can_take_damage = true


func set_direction(new_direction: int) -> void:
	direction = new_direction
	if anim != null:
		anim.flip_h = direction > 0


func _turn_around_at_patrol_edge() -> void:
	var left_edge := start_position.x - patrol_distance
	var right_edge := start_position.x + patrol_distance

	if global_position.x <= left_edge:
		direction = 1
	elif global_position.x >= right_edge:
		direction = -1

	anim.flip_h = direction > 0


func _turn_around() -> void:
	direction *= -1
	anim.flip_h = direction > 0


func _keep_inside_patrol_range() -> void:
	var left_edge := start_position.x - patrol_distance
	var right_edge := start_position.x + patrol_distance

	if global_position.x < left_edge:
		global_position.x = left_edge
		knockback_velocity.x = maxf(knockback_velocity.x, 0.0)
	elif global_position.x > right_edge:
		global_position.x = right_edge
		knockback_velocity.x = minf(knockback_velocity.x, 0.0)


func _flash_hurt() -> void:
	if hurt_tween != null:
		hurt_tween.kill()

	anim.modulate = Color(1.0, 0.2, 0.2)
	hurt_tween = create_tween()
	hurt_tween.tween_property(anim, "modulate", Color.WHITE, hurt_flash_time)
