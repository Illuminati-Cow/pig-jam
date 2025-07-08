class_name PlayerController
extends CharacterBody3D

@export_category("Movement")
@export
var walk_speed: float = 1

@export
var backward_walk_speed_modifier: float = 0.5

@export 
var rotate_speed: float = 1

@export
var speed_dir_curve: Curve

@export_category("Resources")
@export
var indicator_resource: PackedScene

@onready
var nav: NavigationAgent3D = $NavigationAgent3D

@onready
var animation_player: AnimationTree = $AnimationPlayer/AnimationTree

var raycast_this_frame: bool = false
var navigating: bool = false
var ray_origin: Vector2
var indicator: Node3D

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

func _physics_process(delta: float):
	if raycast_this_frame:
		raycast_this_frame = false
		var camera = get_viewport().get_camera_3d()
		var params = PhysicsRayQueryParameters3D.new()
		params.exclude = [self]
		var results := Utilities.pointer_raycast(camera, ray_origin, 1000, params)
		if results:
			start_navigation(results.position)
	
	if nav.is_navigation_finished() and navigating:
		stop_navigation()
	
	var locomotion_input := Input.get_axis("walk_backward", "walk_forward")
	var rotation_input := Input.get_axis("rotate_counter-clockwise", "rotate_clockwise")
	
	if locomotion_input != 0 || rotation_input != 0 and navigating:
		stop_navigation()
	
	if navigating:
		var next_path_position: Vector3 = nav.get_next_path_position()
		var direction := global_position.direction_to(next_path_position)
		var rot_delta: float = basis.z.signed_angle_to(direction, transform.basis.y)
		rotation.y = rotate_toward(rotation.y, rotation.y + rot_delta, deg_to_rad(rotate_speed))
		velocity = speed_dir_curve.sample_baked(basis.z.dot(direction)) * direction * walk_speed
	else:
		velocity = basis.z * locomotion_input * walk_speed\
			* (backward_walk_speed_modifier if locomotion_input < 0 else 1)
		rotate_y(-rotation_input * deg_to_rad(rotate_speed))
	
	if !is_on_floor():
		velocity += get_gravity()
	move_and_slide()

func start_navigation(target_pos: Vector3):
	velocity.x = 0
	velocity.z = 0
	nav.target_position = target_pos
	indicator.global_position = target_pos + Vector3.UP * 0.1
	indicator.visible = true
	navigating = true

func stop_navigation():
	navigating = false
	indicator.visible = false
	velocity = Vector3.ZERO
