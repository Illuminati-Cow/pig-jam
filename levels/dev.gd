extends Node3D


func _ready():
	var player: PlayerController = $Player

func _on_player_foo():
	print_debug("Signal Received")
	pass # Replace with function body.
