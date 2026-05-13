extends CharacterBody2D

const DASH_FRAME_PATHS: Array[String] = [
	"res://assets/enemy/boss_go/bossgo_1.png",
	"res://assets/enemy/boss_go/bossgo_2.png",
	"res://assets/enemy/boss_go/bossgo_3.png",
	"res://assets/enemy/boss_go/bossgo_4.png",
]

const JUMP_FRAME_PATHS: Array[String] = [
	"res://assets/enemy/boss_jump/boss_jump1.png",
	"res://assets/enemy/boss_jump/boss_jump2.png",
	"res://assets/enemy/boss_jump/boss_jump3.png",
	"res://assets/enemy/boss_jump/boss_jump4.png",
	"res://assets/enemy/boss_jump/boss_jump5.png",
]

const THROW_FRAME_PATHS: Array[String] = [
	"res://assets/enemy/boss_throw/boss_throw1.png",
	"res://assets/enemy/boss_throw/boss_throw2.png",
	"res://assets/enemy/boss_throw/boss_throw3.png",
	"res://assets/enemy/boss_throw/boss_throw4.png",
]

@export var max_health: int = 20
@export var gravity: float = 1600.0
@export var dash_speed: float = 760.0
@export var dash_time: float = 0.42
@export var dash_animation_frame_time: float = 0.08
@export var dash_animation_flipped: bool = true
@export var windup_time: float = 0.55
@export var recover_time: float = 0.8
@export var attack_range: float = 720.0
@export var close_attack_range: float = 360.0
@export var vertical_tolerance: float = 180.0
@export var contact_damage: int = 1
@export var body_contact_damage_enabled: bool = true
@export var hurt_knockback: float = 240.0
@export var hit_stun_time: float = 0.18
@export var quake_jump_velocity: float = -620.0
@export var quake_rise_gravity: float = 650.0
@export var quake_fall_gravity: float = 1900.0
@export var jump_rise_animation_frame_time: float = 0.3
@export var jump_fall_animation_frame_time: float = 0.08
@export var quake_damage: int = 1
@export var quake_recover_time: float = 0.7
@export var quake_camera_shake_duration: float = 0.7
@export var quake_camera_shake_strength: float = 7.0
@export var min_quake_attacks_before_forced_other: int = 1
@export var max_quake_attacks_before_forced_other: int = 2
@export var min_ranged_attacks_before_forced_close: int = 1
@export var max_ranged_attacks_before_forced_close: int = 2
@export var ink_attack_windup_time: float = 0.45
@export var ink_attack_recover_time: float = 0.75
@export var throw_animation_frame_time: float = 0.09
@export var throw_animation_scale_multiplier: float = 0.81
@export var ink_projectile_speed: float = 330.0
@export var ink_projectile_min_count: int = 5
@export var ink_projectile_max_count: int = 7
@export var ink_projectile_min_batch: int = 1
@export var ink_projectile_max_batch: int = 1
@export var ink_projectile_min_height: float = -58.0
@export var ink_projectile_max_height: float = 52.0
@export var ink_projectile_min_interval: float = 1.0
@export var ink_projectile_max_interval: float = 1.25
@export var ink_projectile_min_speed_multiplier: float = 0.75
@export var ink_projectile_max_speed_multiplier: float = 1.35
@export var ink_projectile_min_wave_amplitude: float = 18.0
@export var ink_projectile_max_wave_amplitude: float = 34.0
@export var ink_projectile_min_wave_frequency: float = 3.8
@export var ink_projectile_max_wave_frequency: float = 5.4
@export var ink_projectile_scene: PackedScene = preload("res://scenes/ink_projectile.tscn")
@export var intro_effect_enabled: bool = true
@export var intro_effect_duration: float = 2.8
@export var intro_ring_start_interval: float = 0.32
@export var intro_ring_end_interval: float = 0.07
@export var intro_ring_radius: float = 72.0
@export var intro_ring_max_scale: float = 14.0
@export var intro_ring_width: float = 10.0
@export var intro_spike_count: int = 18
@export var intro_spike_inner_radius: float = 42.0
@export var intro_spike_outer_radius: float = 118.0
@export var intro_spike_angle_width: float = 0.08
@export var intro_center_glow_radius: float = 96.0
@export var intro_min_shake_strength: float = 2.0
@export var intro_max_shake_strength: float = 13.0
@export var intro_sfx: AudioStream = preload("res://scores/boss1.wav")
@export var intro_sfx_volume_db: float = 6.0
@export var ink_sfx: AudioStream = preload("res://scores/boss_attack1.wav")
@export var ink_sfx_volume_db: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var damage_area: Area2D = $DamageArea
@onready var damage_shape: CollisionShape2D = $DamageArea/CollisionShape2D

var health := 0
var state := &"idle"
var state_timer := 0.0
var direction := -1
var hit_stun_left := 0.0
var ink_projectiles_left := 0
var ink_projectile_index := 0
var ink_next_shot_time := 0.0
var ranged_attack_count := 0
var ranged_attacks_before_forced_close := 0
var quake_attack_count := 0
var quake_attacks_before_forced_other := 0
var quake_has_left_floor := false
var default_texture: Texture2D
var default_sprite_scale := Vector2.ONE
var dash_frames: Array[Texture2D] = []
var jump_frames: Array[Texture2D] = []
var throw_frames: Array[Texture2D] = []
var dash_frame_index := 0
var dash_frame_time_left := 0.0
var jump_rise_frame_index := 0
var jump_fall_frame_index := 0
var jump_frame_time_left := 0.0
var throw_frame_index := 0
var throw_frame_time_left := 0.0
var throw_animation_active := false
var intro_time_left := 0.0
var intro_elapsed := 0.0
var intro_next_ring_time := 0.0
var intro_audio: AudioStreamPlayer
var body_contact_area: Area2D
var body_contact_shape: CollisionShape2D
var target: Node2D


func _ready() -> void:
	health = max_health
	default_texture = sprite.texture
	default_sprite_scale = sprite.scale
	_load_dash_frames()
	_load_jump_frames()
	_load_throw_frames()
	ranged_attacks_before_forced_close = _roll_ranged_attacks_before_forced_close()
	quake_attacks_before_forced_other = _roll_quake_attacks_before_forced_other()
	add_to_group("enemy")
	damage_area.area_entered.connect(_on_damage_area_entered)
	_setup_body_contact_area()
	_set_damage_area_enabled(false)
	_sync_facing()
	if intro_effect_enabled:
		_start_intro_effect()


func _physics_process(delta: float) -> void:
	target = _find_player()

	if not is_on_floor():
		velocity.y += _get_current_gravity() * delta

	if intro_time_left > 0.0:
		_update_intro_effect(delta)
		velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta)
	elif hit_stun_left > 0.0:
		hit_stun_left -= delta
		velocity.x = move_toward(velocity.x, 0.0, hurt_knockback * delta * 3.0)
	else:
		match state:
			&"windup":
				_update_windup(delta)
			&"dash":
				_update_dash(delta)
			&"recover":
				_update_recover(delta)
			&"ink_windup":
				_update_ink_windup(delta)
			&"ink_fire":
				_update_ink_fire(delta)
			&"ink_recover":
				_update_ink_recover(delta)
			&"quake_jump":
				_update_quake_jump(delta)
			&"quake_recover":
				_update_quake_recover(delta)
			_:
				_update_idle(delta)

	_update_boss_animation(delta)
	move_and_slide()
	_damage_body_contact_overlaps()


func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	health -= amount
	var push_direction := signf(global_position.x - from_position.x)
	if is_zero_approx(push_direction):
		push_direction = 1.0

	hit_stun_left = hit_stun_time
	velocity.x = push_direction * hurt_knockback
	_flash()

	if health <= 0:
		queue_free()


func _update_idle(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * 0.08)
	if not _can_dash_attack():
		return

	_begin_random_attack()


func _update_windup(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta)
	_face_target()
	state_timer -= delta
	if state_timer > 0.0:
		return

	state = &"dash"
	state_timer = dash_time
	velocity.x = direction * dash_speed
	_set_damage_area_enabled(true)
	_start_dash_animation()


func _update_dash(delta: float) -> void:
	state_timer -= delta
	velocity.x = direction * dash_speed
	if state_timer > 0.0:
		return

	_set_damage_area_enabled(false)
	_stop_dash_animation()
	state = &"recover"
	state_timer = recover_time


func _update_recover(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta * 2.0)
	state_timer -= delta
	if state_timer <= 0.0:
		if target != null:
			_begin_random_special_after_dash()
			return
		state = &"idle"


func _update_ink_windup(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta)
	_face_target()
	state_timer -= delta
	if state_timer > 0.0:
		return

	_begin_ink_fire()


func _update_ink_fire(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta)
	_face_target()
	ink_next_shot_time -= delta
	if ink_next_shot_time > 0.0:
		return

	var batch_count := randi_range(ink_projectile_min_batch, ink_projectile_max_batch)
	batch_count = mini(batch_count, ink_projectiles_left)
	for _shot in range(batch_count):
		_start_throw_animation()
		_shoot_one_ink()
		ink_projectile_index += 1
		ink_projectiles_left -= 1

	if ink_projectiles_left > 0:
		ink_next_shot_time = randf_range(ink_projectile_min_interval, ink_projectile_max_interval)
		return

	state = &"ink_recover"
	state_timer = ink_attack_recover_time


func _update_ink_recover(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta)
	state_timer -= delta
	if state_timer <= 0.0:
		_begin_random_attack()


func _update_quake_jump(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta)
	if not is_on_floor():
		quake_has_left_floor = true
	if quake_has_left_floor and is_on_floor() and velocity.y >= 0.0:
		_trigger_quake()
		state = &"quake_recover"
		state_timer = quake_recover_time


func _update_quake_recover(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta)
	state_timer -= delta
	if state_timer <= 0.0:
		_begin_random_attack()


func _begin_dash_attack() -> void:
	_reset_ranged_attack_count()
	_reset_quake_attack_count()
	_face_target()
	state = &"windup"
	state_timer = windup_time


func _begin_ink_attack() -> void:
	_reset_quake_attack_count()
	ranged_attack_count += 1
	_face_target()
	state = &"ink_windup"
	state_timer = ink_attack_windup_time


func _begin_ink_fire() -> void:
	state = &"ink_fire"
	ink_projectiles_left = randi_range(ink_projectile_min_count, ink_projectile_max_count)
	ink_projectile_index = 0
	ink_next_shot_time = 0.0


func _begin_quake_jump() -> void:
	_reset_ranged_attack_count()
	quake_attack_count += 1
	_set_damage_area_enabled(false)
	state = &"quake_jump"
	quake_has_left_floor = false
	velocity.x = 0.0
	velocity.y = quake_jump_velocity
	_start_jump_animation()


func _trigger_quake() -> void:
	if target != null and target.has_method("_start_camera_shake"):
		target.call("_start_camera_shake", quake_camera_shake_duration, quake_camera_shake_strength)
	if not _is_target_on_floor() or target == null:
		return
	if target.has_method("take_quake_damage"):
		target.call("take_quake_damage", quake_damage)
	elif target.has_method("take_damage"):
		target.call("take_damage", quake_damage, global_position)


func _is_target_on_floor() -> bool:
	if target is CharacterBody2D:
		return target.is_on_floor()
	return false


func _get_current_gravity() -> float:
	if state == &"quake_jump":
		if velocity.y < 0.0:
			return quake_rise_gravity
		return quake_fall_gravity
	return gravity


func _get_jump_animation_frame_time() -> float:
	if velocity.y < 0.0:
		return jump_rise_animation_frame_time
	return jump_fall_animation_frame_time


func _start_intro_effect() -> void:
	intro_time_left = intro_effect_duration
	intro_elapsed = 0.0
	intro_next_ring_time = 0.0
	state = &"intro"
	_make_player_face_boss()
	GameState.set_input_locked(true)
	_set_damage_area_enabled(false)
	_play_intro_sfx()


func _update_intro_effect(delta: float) -> void:
	intro_time_left -= delta
	intro_elapsed += delta
	intro_next_ring_time -= delta

	if intro_next_ring_time <= 0.0:
		_spawn_intro_ring()

	var progress := clampf(intro_elapsed / maxf(intro_effect_duration, 0.001), 0.0, 1.0)
	if intro_next_ring_time <= 0.0:
		intro_next_ring_time = lerpf(intro_ring_start_interval, intro_ring_end_interval, progress)
	var shake_strength := lerpf(intro_min_shake_strength, intro_max_shake_strength, progress)
	var player := target
	if player == null:
		player = _find_player()
	if player != null and player.has_method("_start_camera_shake"):
		player.call("_start_camera_shake", 0.18, shake_strength)

	if intro_time_left <= 0.0:
		GameState.set_input_locked(false)
		_stop_intro_sfx()
		state = &"idle"


func _make_player_face_boss() -> void:
	var player := _find_player()
	if player != null and player.has_method("face_position"):
		player.call("face_position", global_position)


func _spawn_intro_ring() -> void:
	var burst := Node2D.new()
	burst.name = "IntroBurst"
	burst.z_index = 200
	add_child(burst)

	var glow := Polygon2D.new()
	glow.name = "CenterGlow"
	glow.color = Color(1.0, 0.96, 0.82, 0.06)
	glow.polygon = _build_circle_polygon(intro_center_glow_radius, 48)
	glow.z_index = 198
	burst.add_child(glow)

	_add_intro_spikes(burst)

	var ring := Line2D.new()
	ring.name = "IntroRing"
	ring.closed = true
	ring.width = intro_ring_width
	ring.default_color = Color(1.0, 1.0, 1.0, 0.24)
	ring.gradient = _build_intro_ring_gradient()
	ring.z_index = 200
	ring.points = _build_ring_points(intro_ring_radius, 128)
	burst.add_child(ring)

	var tween := create_tween()
	burst.scale = Vector2(0.12, 0.12)
	tween.set_parallel(true)
	tween.tween_property(burst, "scale", Vector2.ONE * intro_ring_max_scale, 0.72)
	tween.tween_property(burst, "modulate:a", 0.0, 0.72)
	tween.set_parallel(false)
	tween.tween_callback(burst.queue_free)


func _build_ring_points(radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(point_count):
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _add_intro_spikes(parent: Node2D) -> void:
	var count := maxi(3, intro_spike_count)
	for index in range(count):
		var angle := TAU * float(index) / float(count)
		var half_width := intro_spike_angle_width * randf_range(0.75, 1.2)
		var inner_radius := intro_spike_inner_radius * randf_range(0.85, 1.15)
		var outer_radius := intro_spike_outer_radius * randf_range(0.85, 1.2)
		var spike := Polygon2D.new()
		spike.name = "IntroSpike"
		spike.color = Color(1.0, 1.0, 1.0, 0.08)
		spike.z_index = 199
		spike.polygon = PackedVector2Array([
			Vector2(cos(angle - half_width), sin(angle - half_width)) * inner_radius,
			Vector2(cos(angle), sin(angle)) * outer_radius,
			Vector2(cos(angle + half_width), sin(angle + half_width)) * inner_radius,
		])
		parent.add_child(spike)


func _build_circle_polygon(radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(point_count):
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _play_intro_sfx() -> void:
	if intro_sfx == null:
		return
	if intro_audio == null:
		intro_audio = AudioStreamPlayer.new()
		intro_audio.name = "IntroAudio"
		add_child(intro_audio)
	intro_audio.stream = intro_sfx
	intro_audio.bus = "SFX"
	intro_audio.volume_db = intro_sfx_volume_db
	intro_audio.play()


func _stop_intro_sfx() -> void:
	if intro_audio != null and intro_audio.playing:
		intro_audio.stop()


func _play_ink_sfx() -> void:
	if ink_sfx == null:
		return

	var audio := AudioStreamPlayer.new()
	audio.name = "InkAudio"
	audio.stream = ink_sfx
	audio.bus = "SFX"
	audio.volume_db = ink_sfx_volume_db
	audio.finished.connect(audio.queue_free)
	add_child(audio)
	audio.play()


func _build_intro_ring_gradient() -> Gradient:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.18, 0.42, 0.7, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.0),
		Color(1.0, 1.0, 1.0, 0.22),
		Color(0.86, 0.96, 1.0, 0.08),
		Color(1.0, 1.0, 1.0, 0.18),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	return gradient


func _begin_random_special_after_dash() -> void:
	if _must_use_non_quake_attack():
		_begin_ink_attack()
		return

	if _must_use_close_attack() or _is_target_close():
		_begin_quake_jump()
	else:
		_begin_ink_attack()


func _begin_random_attack() -> void:
	if target == null or not _can_dash_attack():
		state = &"idle"
		return

	if _must_use_non_quake_attack():
		if _is_target_close():
			_begin_dash_attack()
		else:
			_begin_ink_attack()
		return

	if _must_use_close_attack() or _is_target_close():
		if randf() < 0.5:
			_begin_dash_attack()
		else:
			_begin_quake_jump()
	else:
		_begin_ink_attack()


func _must_use_close_attack() -> bool:
	return ranged_attack_count >= ranged_attacks_before_forced_close


func _must_use_non_quake_attack() -> bool:
	return quake_attack_count >= quake_attacks_before_forced_other


func _reset_ranged_attack_count() -> void:
	ranged_attack_count = 0
	ranged_attacks_before_forced_close = _roll_ranged_attacks_before_forced_close()


func _reset_quake_attack_count() -> void:
	quake_attack_count = 0
	quake_attacks_before_forced_other = _roll_quake_attacks_before_forced_other()


func _roll_ranged_attacks_before_forced_close() -> int:
	return randi_range(min_ranged_attacks_before_forced_close, max_ranged_attacks_before_forced_close)


func _roll_quake_attacks_before_forced_other() -> int:
	return randi_range(min_quake_attacks_before_forced_other, max_quake_attacks_before_forced_other)


func _is_target_close() -> bool:
	if target == null:
		return false
	return absf(target.global_position.x - global_position.x) <= close_attack_range


func _shoot_one_ink() -> void:
	if ink_projectile_scene == null:
		return

	var parent := get_parent()
	if parent == null:
		return

	var projectile := ink_projectile_scene.instantiate()
	parent.add_child(projectile)
	if projectile is Node2D:
		var random_height := randf_range(ink_projectile_min_height, ink_projectile_max_height)
		projectile.global_position = global_position + Vector2(74.0 * direction, random_height)
	var speed_multiplier := randf_range(ink_projectile_min_speed_multiplier, ink_projectile_max_speed_multiplier)
	var projectile_speed := ink_projectile_speed * speed_multiplier
	if projectile.has_method("launch_wave"):
		var wave_amplitude := randf_range(ink_projectile_min_wave_amplitude, ink_projectile_max_wave_amplitude)
		var wave_frequency := randf_range(ink_projectile_min_wave_frequency, ink_projectile_max_wave_frequency)
		var wave_phase := randf_range(0.0, TAU)
		projectile.call("launch_wave", direction, contact_damage, projectile_speed, wave_amplitude, wave_frequency, wave_phase, self)
	_play_ink_sfx()


func _can_dash_attack() -> bool:
	if target == null:
		return false

	var offset := target.global_position - global_position
	return absf(offset.x) <= attack_range and absf(offset.y) <= vertical_tolerance


func _find_player() -> Node2D:
	var player := get_tree().get_first_node_in_group("player")
	if player is Node2D:
		return player

	var scene := get_tree().current_scene
	if scene == null:
		return null

	player = scene.find_child("Player", true, false)
	if player is Node2D:
		return player
	return null


func _face_target() -> void:
	if target == null:
		return

	var new_direction := signf(target.global_position.x - global_position.x)
	if is_zero_approx(new_direction):
		return

	direction = int(new_direction)
	_sync_facing()


func _sync_facing() -> void:
	_apply_sprite_facing()
	damage_area.position.x = 64.0 * direction


func _apply_sprite_facing() -> void:
	sprite.flip_h = direction > 0
	if state == &"dash" and dash_animation_flipped:
		sprite.flip_h = not sprite.flip_h


func _start_dash_animation() -> void:
	sprite.scale = default_sprite_scale
	dash_frame_index = 0
	dash_frame_time_left = dash_animation_frame_time
	_apply_sprite_facing()
	if not dash_frames.is_empty():
		sprite.texture = dash_frames[dash_frame_index]


func _stop_dash_animation() -> void:
	if default_texture != null:
		sprite.texture = default_texture
	_apply_sprite_facing()


func _update_boss_animation(delta: float) -> void:
	if state == &"dash":
		_update_dash_animation(delta)
		return
	if state == &"quake_jump" or state == &"quake_recover":
		_update_jump_animation(delta)
		return
	if state == &"ink_fire" and throw_animation_active:
		_update_throw_animation(delta)
		return

	if sprite.texture != default_texture:
		_stop_special_animation()


func _update_dash_animation(delta: float) -> void:
	if dash_frames.is_empty():
		return

	dash_frame_time_left -= delta
	if dash_frame_time_left > 0.0:
		return

	dash_frame_time_left = dash_animation_frame_time
	dash_frame_index = (dash_frame_index + 1) % dash_frames.size()
	sprite.texture = dash_frames[dash_frame_index]


func _start_jump_animation() -> void:
	sprite.scale = default_sprite_scale
	jump_rise_frame_index = 0
	jump_fall_frame_index = 3
	jump_frame_time_left = _get_jump_animation_frame_time()
	_apply_sprite_facing()
	if not jump_frames.is_empty():
		sprite.texture = jump_frames[jump_rise_frame_index]


func _update_jump_animation(delta: float) -> void:
	if jump_frames.is_empty():
		return

	jump_frame_time_left -= delta
	if jump_frame_time_left > 0.0:
		return

	jump_frame_time_left = _get_jump_animation_frame_time()
	if velocity.y < 0.0:
		jump_rise_frame_index = mini(jump_rise_frame_index + 1, mini(2, jump_frames.size() - 1))
		sprite.texture = jump_frames[jump_rise_frame_index]
	else:
		if jump_frames.size() < 5:
			sprite.texture = jump_frames[jump_frames.size() - 1]
			return
		jump_fall_frame_index = mini(jump_fall_frame_index + 1, 4)
		sprite.texture = jump_frames[jump_fall_frame_index]


func _stop_special_animation() -> void:
	sprite.scale = default_sprite_scale
	if default_texture != null:
		sprite.texture = default_texture
	throw_animation_active = false
	_apply_sprite_facing()


func _load_dash_frames() -> void:
	dash_frames.clear()
	for path in DASH_FRAME_PATHS:
		var texture := load(path)
		if texture is Texture2D:
			dash_frames.append(texture)


func _load_jump_frames() -> void:
	jump_frames.clear()
	for path in JUMP_FRAME_PATHS:
		var texture := load(path)
		if texture is Texture2D:
			jump_frames.append(texture)


func _start_throw_animation() -> void:
	throw_animation_active = true
	sprite.scale = default_sprite_scale * throw_animation_scale_multiplier
	throw_frame_index = 0
	throw_frame_time_left = throw_animation_frame_time
	_apply_sprite_facing()
	if not throw_frames.is_empty():
		sprite.texture = throw_frames[throw_frame_index]


func _update_throw_animation(delta: float) -> void:
	if throw_frames.is_empty():
		throw_animation_active = false
		return

	throw_frame_time_left -= delta
	if throw_frame_time_left > 0.0:
		return

	throw_frame_time_left = throw_animation_frame_time
	throw_frame_index += 1
	if throw_frame_index >= throw_frames.size():
		throw_animation_active = false
		return
	sprite.texture = throw_frames[throw_frame_index]


func _load_throw_frames() -> void:
	throw_frames.clear()
	for path in THROW_FRAME_PATHS:
		var texture := load(path)
		if texture is Texture2D:
			throw_frames.append(texture)


func _set_damage_area_enabled(enabled: bool) -> void:
	damage_area.set_deferred("monitoring", enabled)
	damage_shape.set_deferred("disabled", not enabled)


func _setup_body_contact_area() -> void:
	if not body_contact_damage_enabled or collision_shape == null or collision_shape.shape == null:
		return

	body_contact_area = Area2D.new()
	body_contact_area.name = "BodyContactArea"
	body_contact_area.collision_layer = 32
	body_contact_area.collision_mask = 16
	body_contact_area.monitoring = true
	body_contact_area.monitorable = false
	body_contact_area.area_entered.connect(_on_body_contact_area_entered)
	add_child(body_contact_area)

	body_contact_shape = CollisionShape2D.new()
	body_contact_shape.shape = collision_shape.shape
	body_contact_shape.position = collision_shape.position
	body_contact_shape.rotation = collision_shape.rotation
	body_contact_shape.scale = collision_shape.scale
	body_contact_area.add_child(body_contact_shape)


func _damage_body_contact_overlaps() -> void:
	if intro_time_left > 0.0 or body_contact_area == null:
		return

	for area in body_contact_area.get_overlapping_areas():
		_damage_contact_target(area)


func _on_body_contact_area_entered(area: Area2D) -> void:
	if intro_time_left > 0.0:
		return
	_damage_contact_target(area)


func _damage_contact_target(target_area: Area2D) -> void:
	var receiver := _find_damage_receiver(target_area)
	if receiver == null or receiver == self:
		return

	receiver.call("take_damage", contact_damage, global_position)


func _on_damage_area_entered(area: Area2D) -> void:
	if state != &"dash":
		return

	_damage_contact_target(area)



func _find_damage_receiver(target_node: Node) -> Node:
	var current: Node = target_node
	while current != null:
		if current.has_method("take_damage"):
			return current
		current = current.get_parent()
	return null


func _flash(color: Color = Color(1.0, 0.25, 0.25), hold_time: float = 0.05, fade_time: float = 0.12) -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", color, hold_time)
	tween.tween_property(sprite, "modulate", Color.WHITE, fade_time)
