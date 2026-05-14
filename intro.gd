extends Control

@onready var text_label: Label = $TextLabel
@onready var prompt_label: Label = $PromptLabel
@onready var timer: Timer = $Timer

var full_text := "有一位神秘的精靈，在這裡悄悄地出現了......"
var current_index := 0
var prompt_time := 0.0

func _ready() -> void:
	_play_title_music()

	full_text = _t("INTRO_TEXT")
	text_label.text = ""
	prompt_label.text = _t("INTRO_PROMPT")
	prompt_label.modulate.a = 0.0
	timer.wait_time = 0.055
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _process(delta: float) -> void:
	prompt_time += delta
	prompt_label.modulate.a = 0.45 + sin(prompt_time * 2.6) * 0.35

func _on_timer_timeout() -> void:
	if current_index < full_text.length():
		text_label.text += full_text[current_index]
		current_index += 1
	else:
		timer.stop()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _play_title_music() -> void:
	var music_player := get_node_or_null("/root/MusicPlayer")
	if music_player != null and music_player.has_method("play_title_music"):
		music_player.play_title_music()


func _t(key: String) -> String:
	var localization: Node = get_node_or_null("/root/Localization")
	if localization != null and localization.has_method("text"):
		return String(localization.call("text", key))
	return key
