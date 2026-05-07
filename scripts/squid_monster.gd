extends CharacterBody2D

const GRAVITY := 900.0
const STATE_IDLE := 0
const STATE_MOVE_ABOVE := 1
const STATE_SLAM := 2
const STATE_RETURN := 3
const STATE_COOLDOWN := 4

@export var detect_range := 300.0
@export var hp := 4
@export var damage := 2
@export var cooldown_time := 2.0
@export var move_above_speed := 520.0
@export var return_speed := 620.0
@export var slam_speed := 900.0
@export var above_player_height := 180.0
@export var hurt_flash_time := 0.15
@export var patrol_speed := 80.0
@export var patrol_distance := 180.0

@onready var attack_area: Area2D = $AttackArea
@onready var hurt_box: Area2D = $HurtBox
@onready var sprite: Sprite2D = $Sprite2D

var player: Node2D
var can_attack := true
var has_hit_player := false
var state := STATE_IDLE
var home_position := Vector2.ZERO
var patrol_direction := -1
var start_position := Vector2.ZERO
var slam_target_position := Vector2.ZERO
var hurt_tween: Tween


func _ready() -> void:
	home_position = global_position
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player") as Node2D
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	hurt_box.area_entered.connect(_on_hurt_box_area_entered)
	attack_area.monitoring = false


func _physics_process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D

	if state == STATE_IDLE and not is_on_floor():
		velocity.y += GRAVITY * delta

	if player != null and can_attack and state == STATE_IDLE:
		var distance := global_position.distance_to(player.global_position)
		if distance <= detect_range:
			start_slam_attack()

	match state:
		STATE_IDLE:
			_update_idle()
		STATE_MOVE_ABOVE:
			_update_move_above(delta)
		STATE_SLAM:
			_update_slam(delta)
		STATE_RETURN:
			_update_return(delta)

	if state == STATE_IDLE:
		move_and_slide()


func _update_idle() -> void:
	var left_edge := home_position.x - patrol_distance
	var right_edge := home_position.x + patrol_distance

	if global_position.x <= left_edge:
		patrol_direction = 1
	elif global_position.x >= right_edge:
		patrol_direction = -1

	velocity.x = patrol_direction * patrol_speed
	sprite.flip_h = patrol_direction < 0

	if is_on_wall():
		patrol_direction *= -1
		sprite.flip_h = patrol_direction < 0


func start_slam_attack() -> void:
	if player == null:
		return

	state = STATE_MOVE_ABOVE
	can_attack = false
	has_hit_player = false
	start_position = global_position
	slam_target_position = Vector2(player.global_position.x, player.global_position.y - above_player_height)
	attack_area.set_deferred("monitoring", false)
	sprite.flip_h = player.global_position.x < global_position.x


func _update_move_above(delta: float) -> void:
	velocity = Vector2.ZERO
	global_position = global_position.move_toward(slam_target_position, move_above_speed * delta)

	if global_position.distance_to(slam_target_position) <= 8.0:
		global_position = slam_target_position
		state = STATE_SLAM
		attack_area.set_deferred("monitoring", true)


func _update_slam(delta: float) -> void:
	velocity = Vector2.ZERO
	global_position.y += slam_speed * delta
	_damage_overlapping_players()

	if global_position.y >= start_position.y:
		global_position.y = start_position.y
		start_return()


func start_return() -> void:
	state = STATE_RETURN
	velocity = Vector2.ZERO
	attack_area.set_deferred("monitoring", false)


func _update_return(delta: float) -> void:
	velocity = Vector2.ZERO
	global_position = global_position.move_toward(start_position, return_speed * delta)

	if global_position.distance_to(start_position) <= 8.0:
		global_position = start_position
		velocity = Vector2.ZERO
		start_cooldown()


func start_cooldown() -> void:
	state = STATE_COOLDOWN
	velocity = Vector2.ZERO

	await get_tree().create_timer(cooldown_time).timeout
	can_attack = true
	state = STATE_IDLE


func _on_attack_area_body_entered(body: Node2D) -> void:
	if state != STATE_SLAM or has_hit_player:
		return

	if body.is_in_group("player"):
		has_hit_player = true
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)


func _damage_overlapping_players() -> void:
	if has_hit_player:
		return

	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			has_hit_player = true
			if body.has_method("take_damage"):
				body.take_damage(damage, global_position)
			return


func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.name == "AttackArea" or area.name == "UpAttackArea" or area.name == "DownAttackArea" or area.name == "ChargeAttackArea":
		var attacker := area.get_parent()
		var attacker_position := global_position
		if attacker is Node2D:
			attacker_position = attacker.global_position
		take_damage(1, attacker_position)


func take_damage(amount: int, _attacker_position := Vector2.ZERO) -> void:
	hp -= amount
	_flash_hurt()

	if hp <= 0:
		queue_free()


func _flash_hurt() -> void:
	if hurt_tween != null:
		hurt_tween.kill()

	sprite.modulate = Color(1.0, 0.2, 0.2)
	hurt_tween = create_tween()
	hurt_tween.tween_property(sprite, "modulate", Color.WHITE, hurt_flash_time)
