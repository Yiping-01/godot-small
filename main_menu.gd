extends Control

@onready var start_button = $StartButton
@onready var continue_button = $ContinueButton
@onready var quit_button = $QuitButton
@onready var background_video = $Background

@onready var settings_button = $SettingsButton
@onready var settings_panel = $SettingsPanel
@onready var volume_slider = $SettingsPanel/HSlider
@onready var back_button = $SettingsPanel/Button

func _ready():
	background_video.finished.connect(_on_background_video_finished)
	background_video.play()

	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	settings_button.pressed.connect(_on_settings_pressed)
	back_button.pressed.connect(_on_back_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)

	settings_panel.visible = false
	continue_button.disabled = not GameState.has_continue_scene()

func _on_start_pressed():
	if FileAccess.file_exists("user://save_game.json"):
		DirAccess.remove_absolute("user://save_game.json")

	GameState.reset_demo_state()
	GameState.clear_continue_scene()
	_play_game_music()
	get_tree().change_scene_to_file(GameState.DEFAULT_START_SCENE)

func _on_continue_pressed():
	_play_game_music()
	get_tree().change_scene_to_file(GameState.prepare_continue_scene())

func _on_quit_pressed():
	GameState.save_game()
	get_tree().quit()

func _on_settings_pressed():
	settings_panel.visible = true

func _on_back_pressed():
	settings_panel.visible = false

func _on_volume_changed(value):
	AudioServer.set_bus_volume_db(0, linear_to_db(value))

func _on_background_video_finished():
	background_video.stream_position = 0.0
	background_video.play()

func _play_game_music() -> void:
	var music_player := get_node_or_null("/root/MusicPlayer")
	if music_player != null and music_player.has_method("play_game_music"):
		music_player.play_game_music()
