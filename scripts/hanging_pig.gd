extends RigidBody3D

@onready var _area = $JunctionCollisionArea
var _rot_tween: Tween

var active_junction: Junction
var active_pusher: RigidBody3D

func _on_area_3d_area_entered(area: Area3D) -> void:
	if area is Junction:
		active_junction = area
		#print("Active junction: %s" % active_junction.name)

func _on_area_3d_area_exited(area: Area3D) -> void:
	if area is Junction and active_junction == area:
		active_junction = null
		#print("Active junction unset")

func _process(delta: float) -> void:
	if !active_junction or !active_pusher:
		return
	var push_dir := _get_push_axis()
	change_rails(push_dir)

func change_rails(push_dir: Vector3.Axis) -> void:
	var dir = Vector3.Axis.AXIS_X if !axis_lock_linear_x else Vector3.Axis.AXIS_Y if !axis_lock_angular_y else Vector3.Axis.AXIS_Z
	if dir == push_dir:
		return
		
	match active_junction.axis:
		Junction.JunctionDirection.XZ:
			if push_dir == Vector3.Axis.AXIS_X:
				axis_lock_linear_x = false
				axis_lock_linear_z = true
			elif push_dir == Vector3.Axis.AXIS_Z:
				axis_lock_linear_z = false
				axis_lock_linear_x = true
		Junction.JunctionDirection.XY:
			if push_dir == Vector3.Axis.AXIS_X:
				axis_lock_linear_x = false
				axis_lock_linear_y = true
			elif push_dir == Vector3.Axis.AXIS_Y:
				axis_lock_linear_y = false
				axis_lock_linear_x = true
		Junction.JunctionDirection.YZ:
			if push_dir == Vector3.Axis.AXIS_Y:
				axis_lock_linear_y = false
				axis_lock_linear_z = true
			elif push_dir == Vector3.Axis.AXIS_Z:
				axis_lock_linear_z = false
				axis_lock_linear_y = true
		_:
			printerr("Axis is invalid")
			
	_snap_to_rail(push_dir)
	#var axis = ["X", "Y", "Z"]
	#print("Push Direction: %s" % axis[push_dir]) 
	if _rot_tween:
		_rot_tween.kill()
	_rot_tween = create_tween()
	_rot_tween.tween_property(
		self,
		^"rotation_degrees",
		Vector3(-90, 0, 0) if push_dir == Vector3.Axis.AXIS_X else Vector3(-90, 90, 0),
		0.15
	)
	_rot_tween.set_trans(Tween.TRANS_BOUNCE)
		
func _get_push_axis() -> Vector3.Axis:
	var ground_pos := Vector3(global_position.x, 0, global_position.z)
	var ground_pusher_pos := Vector3(active_pusher.global_position.x, 0, active_pusher.global_position.z)
	var cardinal_dir := (ground_pusher_pos.direction_to(ground_pos) + active_pusher.basis.z) / 2
	return cardinal_dir.abs().max_axis_index()

func _snap_to_rail(push_dir: Vector3.Axis) -> void:
	var x = active_junction.global_position.x if push_dir == Vector3.Axis.AXIS_Z else global_position.x
	var z = active_junction.global_position.z if push_dir == Vector3.Axis.AXIS_X else global_position.z
	global_position = Vector3(x, global_position.y, z)


func _on_body_entered(body: Node) -> void:
	if body is not RigidBody3D:
		return
	active_pusher = body
	#print("Active Pusher: %s" % active_pusher.name)

func _on_body_exited(body: Node) -> void:
	if active_pusher == body:
		active_pusher = null
		#print("Active Pusher unset")
