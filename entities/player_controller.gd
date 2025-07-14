class_name PlayerController
extends RigidBody3D

enum MoveMode
{
	WALK,
	RUN,
}

signal footstep(material: String)

@export_category("Movement")
@export_range(0, 10, 0.25) var walk_speed: float = 1
@export_range(0, 10, 0.25) var run_speed: float = 1
@export var acceleration: float = 1
@export var max_acceleration: float = 1
@export var backward_walk_speed_modifier: float = 0.5
@export var rotate_speed: float = 1
@export var speed_dir_curve: Curve

@export_group("Physics")
@export var ride_height: float :
	set(value):
		ride_height = value
		if groundcast:
			groundcast.target_position.y = -value
		
@export var ride_spring_strength: float
@export var ride_spring_damper: float
@export var acceleration_dir_factor: Curve


@export_group("")

@export_category("Resources")
@export
var indicator_resource: PackedScene

@export_category("Debug")
@export
var debug_path: bool:
	get:
		return nav.debug_enabled if nav else false
	set(value):
		if !is_node_ready():
			return
		nav.debug_enabled = value

@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var collider: CollisionShape3D = $CollisionShape3D
@onready var animation_player: AnimationTree = $AnimationPlayer/AnimationTree
@onready var left_foot_raycast: RayCast3D = $FootstepLeft/FootstepCastLeft
@onready var right_foot_raycast: RayCast3D = $FootstepRight/FootstepCastRight
@onready var groundcast = $GroundCast

var goal_velocity: Vector3
var raycast_this_frame: bool = false
var navigating: bool = false
var ray_origin: Vector2
var indicator: Node3D
var move_modifier:
	get:
		return move_modifier
	set(mode):
		move_modifier = walk_speed if mode == MoveMode.WALK else run_speed

func _ready():
	move_modifier = MoveMode.WALK
	indicator = indicator_resource.instantiate()
	get_tree().root.add_child.call_deferred(indicator)
	right_foot_raycast.add_exception($".")
	left_foot_raycast.add_exception($".")
	groundcast.target_position.y = -ride_height
 
func _input(event):
	if event is not InputEventMouseButton or not event.pressed:
		return
		
	match event.button_index:
		MOUSE_BUTTON_RIGHT:
			raycast_this_frame = true
			ray_origin = event.position

func _physics_process(delta: float):
	if raycast_this_frame:
		_nav_raycast()
		
	if nav.is_navigation_finished() and navigating:
		stop_navigation()
	
	var locomotion_input := Input.get_axis("walk_backward", "walk_forward")
	var rotation_input := Input.get_axis("rotate_counter-clockwise", "rotate_clockwise")
	
	if locomotion_input != 0 or rotation_input != 0 and navigating:
		stop_navigation()
	
	if navigating:
		var next_path_position: Vector3 = nav.get_next_path_position()
		var direction := global_position.direction_to(next_path_position)
		var rot_delta: float = basis.z.signed_angle_to(direction, transform.basis.y)
		rotation.y = rotate_toward(rotation.y, rotation.y + rot_delta, deg_to_rad(rotate_speed))
		locomotion_input = speed_dir_curve.sample_baked(basis.z.dot(direction))
	else:
		#velocity = basis.z * locomotion_input * walk_speed\
			#* (backward_walk_speed_modifier if locomotion_input < 0 else 1.)
		rotate_y(-rotation_input * deg_to_rad(rotate_speed))
		
	# Ride force
	groundcast.force_raycast_update()
	if groundcast.is_colliding():
		var ground_position: Vector3 = groundcast.get_collision_point()
		var ground_dist : float = ground_position.distance_to(groundcast.global_position)
		var ray_dir_vel_dot := Vector3.DOWN.dot(linear_velocity)
		var x := ground_dist - ride_height
		var spring_force := (x * ride_spring_strength) - (ray_dir_vel_dot * ride_spring_damper)
		apply_central_force(Vector3.DOWN * spring_force * mass)
		DebugDraw2D.set_text("ground_force", "%2.2f" % spring_force)
	else:
		DebugDraw2D.set_text("ground_force", "not grounded")
	# Locomotion force
	var ground_vel: Vector3 = Vector3(linear_velocity.x, 0, linear_velocity.z)
	var goal_vel: Vector3 = basis.z * locomotion_input * move_modifier
	var vel_dot: float = goal_vel.normalized().dot(ground_vel.normalized())
	var accel := acceleration_dir_factor.sample_baked(vel_dot) * acceleration
	goal_velocity = goal_velocity.move_toward(ground_vel + goal_vel, accel * delta)
	goal_velocity *=  backward_walk_speed_modifier if locomotion_input < 0 else 1
	var needed_accel := (goal_vel - ground_vel) / delta
	var max_accel := acceleration_dir_factor.sample_baked(vel_dot) * max_acceleration
	needed_accel = needed_accel.limit_length(max_accel)
	apply_central_force(needed_accel * mass)
	DebugDraw2D.set_text("ground_vel", "%2.2f" % ground_vel.length())
	DebugDraw2D.set_text("goal_vel", "%2.2f" % goal_vel.length())
	DebugDraw2D.set_text("goal_vel", "%2.2f" % goal_vel.length())
	DebugDraw2D.set_text("needed_accel", "%2.2f" % needed_accel.length())

func start_navigation(target_pos: Vector3):
	nav.target_position = target_pos
	indicator.global_position = target_pos + Vector3.UP * 0.1
	indicator.visible = true
	navigating = true

func stop_navigation():
	navigating = false
	indicator.visible = false
	
func _nav_raycast():
	raycast_this_frame = false
	var camera := get_viewport().get_camera_3d()
	var params = PhysicsRayQueryParameters3D.new()
	params.exclude = [self]
	var results := Utilities.pointer_raycast(camera, ray_origin, 1000, params)
	if results:
		start_navigation(results.position)

func do_footstep(is_left: bool) -> void:
	const DEFAULT_MATERIAL = "concrete"
	var material = DEFAULT_MATERIAL
	if is_left and left_foot_raycast.is_colliding():
		material = left_foot_raycast.get_collider().get_meta("material", DEFAULT_MATERIAL)
		footstep.emit(material.to_lower())
	elif !is_left and right_foot_raycast.is_colliding():
		material = right_foot_raycast.get_collider().get_meta("material", DEFAULT_MATERIAL)
		footstep.emit(material.to_lower())
