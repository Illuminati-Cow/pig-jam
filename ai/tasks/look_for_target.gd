@tool
extends BTAction
## Observes using vision and proximity-based detection [br]
## Returns [code]SUCCESS[/code] when a target is observed

## Blackboard variable that stores the target position (Vector2)
@export var target_position_var := &"target_pos"
@export var target_var := &"target"
@export var vision_cast_var := &"vision"
@export var hearing_cast_var := &"hearing"
@export var los_cast_var := &"los"

var hearing: ShapeCast3D
var vision: ShapeCast3D
var los: RayCast3D

func _setup() -> void:
	hearing = blackboard.get_var(hearing_cast_var)
	vision = blackboard.get_var(vision_cast_var)
	los = blackboard.get_var(los_cast_var)
	assert(hearing)
	assert(vision)
	assert(los)
	los.add_exception(scene_root)

func _generate_name() -> String:
	return "SenseTargetPosition position %s ➜%s" % [
		LimboUtility.decorate_var(target_var),
		LimboUtility.decorate_var(target_position_var)
	]

func _tick(_delta: float) -> Status:
	var hearing_collisions := _get_collisions(hearing)
	DebugDraw2D.set_text("hearing_results", hearing_collisions)
	if hearing_collisions.any(func(e): return e is PlayerController):
		var player = hearing_collisions[hearing_collisions.find_custom(func(e): return e is PlayerController)]
		blackboard.set_var(target_position_var, player.global_position)
		return SUCCESS
	var vision_collisions := _get_collisions(vision)
	DebugDraw2D.set_text("vision_results", vision_collisions)
	if vision_collisions.any(func(e): return e is PlayerController):
		var player = vision_collisions[vision_collisions.find_custom(func(e): return e is PlayerController)]
		los.target_position =  los.to_local(player.global_position) + Vector3.UP
		los.force_raycast_update()
		if los.is_colliding() and los.get_collider() is PlayerController:
			blackboard.set_var(target_position_var, player.global_position)
			return SUCCESS
	return FAILURE

func _get_collisions(cast: ShapeCast3D) -> Array:
	var out := []
	if !cast.is_colliding():
		return out
	var count := cast.get_collision_count()
	for i in range(count):
		out.append(cast.get_collider(i))
	return out
