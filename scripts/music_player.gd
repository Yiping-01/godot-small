extends Node

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

var game_music := preload("res://scores/game_music.wav")
var game_music_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_bus(MUSIC_BUS)
	_ensure_audio_bus(SFX_BUS)
	_ensure_game_music_player()


func _ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return

	AudioServer.add_bus()
	var bus_index := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, "Master")


func _ensure_game_music_player() -> void:
	if game_music_player != null:
		return

	game_music_player = AudioStreamPlayer.new()
	game_music_player.name = "GameMusicPlayer"
	game_music_player.stream = game_music
	game_music_player.bus = MUSIC_BUS
	game_music_player.volume_db = 0.0
	game_music_player.finished.connect(_on_game_music_finished)
	add_child(game_music_player)


func play_game_music() -> void:
	_ensure_game_music_player()

	if game_music_player.playing:
		return

	game_music_player.play()


func stop_game_music() -> void:
	if game_music_player != null:
		game_music_player.stop()


func _on_game_music_finished() -> void:
	play_game_music()
