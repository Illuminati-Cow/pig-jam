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
var ray_origin: Vector2
var indicator: Node3D

const RAY_LENGTH = 1000.0

func _ready():
	indicator = indicator_resource.instantiate()
	nav.path_desired_distance = 0.5
	nav.target_desired_distance = 0.5
	get_tree().root.add_child.call_deferred(indicator)
	nav.debug_enabled = true
 
func _input(event):
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
		var camera := get_viewport().get_camera_3d()
		var space_state = get_world_3d().direct_space_state
		var from = camera.project_ray_origin(ray_origin)
		var to = from + camera.project_ray_normal(ray_origin) * RAY_LENGTH
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.exclude = [self]
		var results := space_state.intersect_ray(query)
		if results:
			nav.target_position = results.position
			indicator.global_position = results.position + Vector3.UP * 0.1
			indicator.visible = true
	
	if nav.is_navigation_finished():
		indicator.visible = false
		return
		
	var next_path_position: Vector3 = nav.get_next_path_position()
	velocity = global_position.direction_to(next_path_position) * walk_speed
	move_and_slide()
	
