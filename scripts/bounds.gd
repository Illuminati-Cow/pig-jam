@tool
extends Node3D

@export_tool_button("Toggle Bounds")
var button = toggle_bounds

func toggle_bounds():
	visible = !visible
