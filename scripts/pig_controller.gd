class_name PigController extends PhysicsCharacterController3D

func _ready() -> void:
	super._ready()
	
func _physics_process(delta: float):
	super._physics_process(delta)
	if !navigating:
		linear_damp = 5
	else:
		linear_damp = 0
