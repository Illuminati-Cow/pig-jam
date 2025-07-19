class_name PigController extends PhysicsCharacterController3D

signal spotted_player

func _ready() -> void:
	super._ready()
	$Vision/RayCast3D.add_exception($".")
	
func _physics_process(delta: float):
	super._physics_process(delta)
	if !navigating:
		linear_damp = 5
	else:
		linear_damp = 0
		#apply_rotation(delta, nav.get_next_path_position())

func apply_rotation(delta: float):
	var turn_intensity_factor : float = 1.0  # Controls how much tilt is applied
	var acceleration_tilt_intensity_factor: float = 1.0
	var max_roll : float = 20.0  # Maximum roll in degrees for realistic tilt
	# Smooth rotation towards target (Y-axis rotation)
	var direction = (nav.get_next_path_position() - global_transform.origin).normalized()
	var target_angle = Vector3.BACK.signed_angle_to(direction, basis.y)
	var smoothed_rotation = lerp_angle(rotation.y, target_angle, rotate_speed * delta)
	rotation.y = smoothed_rotation

	# Apply Z-axis tilt based on turn rate (body momentum tilt)
	var turn_angle = abs(smoothed_rotation - rotation.y)  # Calculate turn angle
	var roll_amount = clamp(turn_angle * turn_intensity_factor, -max_roll, max_roll)  # Limit roll

	# Apply the Z-axis tilt (roll) to the character's body
	rotation.z = lerp_angle(rotation.z, rotation.z + roll_amount, rotate_speed * delta)
	rotation.y = lerp_angle(rotation.y, rotation.y + roll_amount / 2, rotate_speed * delta)
