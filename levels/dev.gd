extends Node3D

func _ready() -> void:
	play_ambience()
	
func play_ambience() -> void:
	var tracks = [preload("res://audio/ambience/Track_1.wav")]
	while true:
		var track: AudioStream= tracks.pick_random()
		var sound := SoundManager.play_ambient_sound(track, 10)
		await sound.finished
