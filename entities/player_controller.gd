class_name PlayerController extends PhysicsCharacterController3D

signal footstep(material: String)
signal died

@export_category("Resources")
@export var indicator_resource: PackedScene

@onready var left_foot_raycast: RayCast3D = $FootstepLeft/FootstepCastLeft
@onready var right_foot_raycast: RayCast3D = $FootstepRight/FootstepCastRight

var raycast_this_frame: bool = false
var ray_origin: Vector2
var indicator: Node3D
var input_disabled: bool = false

func _ready():
	super._ready()
	indicator = indicator_resource.instantiate()
	get_tree().root.add_child.call_deferred(indicator)
	right_foot_raycast.add_exception($".")
	left_foot_raycast.add_exception($".")
	assert(speed_dir_curve)
	assert(acceleration_dir_factor)
	debug_path = debug_path
 
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
	
	apply_ride_force()
	
	if input_disabled:
		return
	
	var locomotion_input := Input.get_axis("walk_backward", "walk_forward")
	var rotation_input := Input.get_axis("rotate_counter-clockwise", "rotate_clockwise")
	
	if locomotion_input != 0 or rotation_input != 0 and navigating:
		stop_navigation()
	
	if navigating:
		var next_path_position: Vector3 = nav.get_next_path_position()
		var direction := global_position.direction_to(next_path_position)
		locomotion_input = speed_dir_curve.sample_baked(basis.z.dot(direction))
		apply_rotation(delta)
	else:
		rotate_y(-rotation_input * deg_to_rad(rotate_speed))
	
	apply_locomotion_force(locomotion_input)

func start_navigation(target_pos: Vector3):
	if Engine.is_editor_hint() and Input.is_physical_key_pressed(KEY_SHIFT):
		global_position = target_pos
		return
	nav.target_position = target_pos
	indicator.global_position = target_pos + Vector3.UP * 0.1
	indicator.visible = true
	navigating = true

func stop_navigation():
	navigating = false
	indicator.visible = false

func kill():
	input_disabled = true
	died.emit()

func do_footstep(is_left: bool) -> void:
	const DEFAULT_MATERIAL = "concrete"
	var material = DEFAULT_MATERIAL
	if is_left and left_foot_raycast.is_colliding():
		material = left_foot_raycast.get_collider().get_meta("material", DEFAULT_MATERIAL)
		footstep.emit(material.to_lower())
	elif !is_left and right_foot_raycast.is_colliding():
		material = right_foot_raycast.get_collider().get_meta("material", DEFAULT_MATERIAL)
		footstep.emit(material.to_lower())

func apply_ride_force() -> void:
	groundcast.force_raycast_update()
	if groundcast.is_colliding():
		var ground_position: Vector3 = groundcast.get_collision_point()
		var ground_dist : float = ground_position.distance_to(groundcast.global_position)
		var ray_dir_vel_dot := Vector3.DOWN.dot(linear_velocity)
		var x := ground_dist - ride_height
		var spring_force := (x * ride_spring_strength) - (ray_dir_vel_dot * ride_spring_damper)
		apply_central_force(Vector3.DOWN * spring_force * mass)
		#DebugDraw2D.set_text("ground_force", "%2.2f" % spring_force)
	#else:
		#DebugDraw2D.set_text("ground_force", "not grounded")

func apply_locomotion_force(locomotion_input: float) -> void:
	var ground_vel: Vector3 = Vector3(linear_velocity.x, 0, linear_velocity.z)
	var goal_vel: Vector3 = basis.z * locomotion_input * move_modifier
	var vel_dot: float = goal_vel.normalized().dot(ground_vel.normalized())
	var accel := acceleration_dir_factor.sample_baked(vel_dot) * acceleration
	goal_velocity = goal_velocity.move_toward(ground_vel + goal_vel, accel * (1.0 / Engine.physics_ticks_per_second))
	goal_velocity *= backward_walk_speed_modifier if locomotion_input < 0 else 1.0
	var needed_accel := (goal_vel - ground_vel) / (1.0 / Engine.physics_ticks_per_second)
	var max_accel := acceleration_dir_factor.sample_baked(vel_dot) * max_acceleration
	needed_accel = needed_accel.limit_length(max_accel)
	apply_central_force(needed_accel * mass)
	nav.velocity = linear_velocity
	#DebugDraw2D.set_text("ground_vel", "%2.2f" % ground_vel.length())
	#DebugDraw2D.set_text("goal_vel", "%2.2f" % goal_vel.length())
	#DebugDraw2D.set_text("goal_vel", "%2.2f" % goal_vel.length())
	#DebugDraw2D.set_text("needed_accel", "%2.2f" % needed_accel.length())

func set_ragdoll(active: bool) -> void:
	var simulator: PhysicalBoneSimulator3D = $CharacterModel/rig_001/Skeleton3D/PhysicalBoneSimulator3D
	simulator.active = active
	collider.disabled = active
	input_disabled = active
	$AnimationPlayer/AnimationTree.active = !active
	if active:
		simulator.physical_bones_start_simulation()
	else:
		simulator.physical_bones_stop_simulation()

func _nav_raycast():
	raycast_this_frame = false
	var camera := get_viewport().get_camera_3d()
	var params = PhysicsRayQueryParameters3D.new()
	params.exclude = [self]
	params.collision_mask = 1 << 1
	var results := Utilities.pointer_raycast(camera, ray_origin, 1000, params)
	if results:
		start_navigation(results.position)
