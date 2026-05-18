extends Node2D

@export var effect_duration: float = 2.8
@export var ring_start_interval: float = 0.32
@export var ring_end_interval: float = 0.07
@export var ring_radius: float = 72.0
@export var ring_max_scale: float = 14.0
@export var ring_width: float = 10.0
@export var spike_count: int = 18
@export var spike_inner_radius: float = 42.0
@export var spike_outer_radius: float = 118.0
@export var spike_angle_width: float = 0.08
@export var center_glow_radius: float = 96.0
@export var min_shake_strength: float = 2.0
@export var max_shake_strength: float = 13.0
@export var intro_sfx: AudioStream = preload("res://scores/boss1.wav")
@export var intro_sfx_volume_db: float = 6.0

var _time_left := 0.0
var _elapsed := 0.0
var _next_ring_time := 0.0
var _audio: AudioStreamPlayer


func _ready() -> void:
	_start_effect()


func _process(delta: float) -> void:
	if _time_left <= 0.0:
		return

	_time_left -= delta
	_elapsed += delta
	_next_ring_time -= delta

	if _next_ring_time <= 0.0:
		_spawn_ring()

	var progress := clampf(_elapsed / maxf(effect_duration, 0.001), 0.0, 1.0)
	if _next_ring_time <= 0.0:
		_next_ring_time = lerpf(ring_start_interval, ring_end_interval, progress)

	var shake_strength := lerpf(min_shake_strength, max_shake_strength, progress)
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("_start_camera_shake"):
		player.call("_start_camera_shake", 0.18, shake_strength)

	if _time_left <= 0.0:
		GameState.set_input_locked(false)
		_stop_sfx()


func _start_effect() -> void:
	_time_left = effect_duration
	_elapsed = 0.0
	_next_ring_time = 0.0
	call_deferred("_make_player_face_intro")
	GameState.set_input_locked(true)
	_play_sfx()


func _exit_tree() -> void:
	if _time_left > 0.0:
		GameState.set_input_locked(false)


func _make_player_face_intro() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("face_position"):
		player.call("face_position", global_position)


func _spawn_ring() -> void:
	var burst := Node2D.new()
	burst.name = "IntroBurst"
	burst.z_index = 200
	add_child(burst)

	var glow := Polygon2D.new()
	glow.name = "CenterGlow"
	glow.color = Color(1.0, 0.96, 0.82, 0.06)
	glow.polygon = _build_circle_polygon(center_glow_radius, 48)
	glow.z_index = 198
	burst.add_child(glow)

	_add_spikes(burst)

	var ring := Line2D.new()
	ring.name = "IntroRing"
	ring.closed = true
	ring.width = ring_width
	ring.default_color = Color(1.0, 1.0, 1.0, 0.24)
	ring.gradient = _build_ring_gradient()
	ring.z_index = 200
	ring.points = _build_ring_points(ring_radius, 128)
	burst.add_child(ring)

	var tween := create_tween()
	burst.scale = Vector2(0.12, 0.12)
	tween.set_parallel(true)
	tween.tween_property(burst, "scale", Vector2.ONE * ring_max_scale, 0.72)
	tween.tween_property(burst, "modulate:a", 0.0, 0.72)
	tween.set_parallel(false)
	tween.tween_callback(burst.queue_free)


func _build_ring_points(radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(point_count):
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _add_spikes(parent: Node2D) -> void:
	var count := maxi(3, spike_count)
	for index in range(count):
		var angle := TAU * float(index) / float(count)
		var half_width := spike_angle_width * randf_range(0.75, 1.2)
		var inner_radius := spike_inner_radius * randf_range(0.85, 1.15)
		var outer_radius := spike_outer_radius * randf_range(0.85, 1.2)
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


func _build_ring_gradient() -> Gradient:
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


func _play_sfx() -> void:
	if intro_sfx == null:
		return
	if _audio == null:
		_audio = AudioStreamPlayer.new()
		_audio.name = "IntroAudio"
		add_child(_audio)
	_audio.stream = intro_sfx
	_audio.bus = "SFX"
	_audio.volume_db = intro_sfx_volume_db
	_audio.play()


func _stop_sfx() -> void:
	if _audio != null and _audio.playing:
		_audio.stop()
