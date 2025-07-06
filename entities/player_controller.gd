class_name PlayerController
extends CharacterBody3D

@export
var walk_speed: float = 1

@export 
var rotate_speed: float = 1

@export
var indicator_resource: PackedScene


@onready
var nav: NavigationAgent3D = $NavigationAgent3D

var raycast_this_frame: bool = false
var movement_was_input: bool = false
var ray_origin: Vector2
var indicator: Node3D

func _ready():
	indicator = indicator_resource.instantiate()
	nav.path_desired_distance = 0.5
	nav.target_desired_distance = 0.5
	get_tree().root.add_child.call_deferred(indicator)
	nav.debug_enabled = true
 
func _input(event):
	movement_was_input = true
	if event.is_action("rotate_clockwise"):
		rotate_y(rotate_speed)
	elif event.is_action("rotate_counter-clockwise"):
		rotate_y(-rotate_speed)
	elif event.is_action("walk_forward"):
		velocity.z = walk_speed
	elif event.is_action("walk_backward"):
		velocity.z = -walk_speed
	else:
		movement_was_input = false
		
	if event is not InputEventMouseButton or not event.pressed:
		return
		
	match event.button_index:
		MOUSE_BUTTON_RIGHT:
			raycast_this_frame = true
			ray_origin = event.position
			print(ray_origin)

func _physics_process(delta: float):
	if raycast_this_frame:
		raycast_this_frame = false
		var camera = get_viewport().get_camera_3d()
		var params = PhysicsRayQueryParameters3D.new()
		params.exclude = [self]
		var results := Utilities.pointer_raycast(camera, ray_origin, 1000, params)
		if results:
			nav.target_position = results.position
			indicator.global_position = results.position + Vector3.UP * 0.1
			indicator.visible = true
	
	# FIX, ONLY RESET IF NAVIGATING AND THEN INPUT
	if nav.is_navigation_finished():
		indicator.visible = false
		nav.target_position = position
		movement_was_input = false
		velocity = Vector3.ZERO
	else:
		var next_path_position: Vector3 = nav.get_next_path_position()
		velocity = global_position.direction_to(next_path_position) * walk_speed
	
	move_and_slide()
