class_name PigController extends PhysicsCharacterController3D

func _physics_process(delta: float):
	super._physics_process(delta)

func _ready() -> void:
	super._ready()
	get_tree().create_timer(5).timeout.connect(func(): nav.target_position = Vector3(randf() * 10, 5, randf() * 10))
