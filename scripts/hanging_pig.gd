extends RigidBody3D

@onready var _area = $Area3D
func _on_area_3d_area_entered(area: Area3D) -> void:
	if "intersection" in area.name.to_lower():
		axis_lock_linear_x = true
		axis_lock_linear_z = false
		create_tween().tween_property(self, ^"global_position", area.global_position, 0.1)
		area.set_deferred(&"monitorable", false)
