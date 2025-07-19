@tool
extends BTAction

@export var target_var := &"target"
@export var nav_var: BBNode
## Desired distance from target before considering task a success
@export var desired_distance_var: BBFloat
## Max distance from target before considering task a failure
@export var max_distance_var: BBFloat
## Minimum distance from target before the agent will begin running
@export var run_distance_threshold_var: BBFloat

var target: RigidBody3D
var nav: NavigationAgent3D
var desired_distance_squared: float
var max_distance_squared: float
var run_distance_threshold_squared: float
var ready_to_pathfind: bool

func _generate_name() -> String:
	return "PursueTarget %s" % [
		LimboUtility.decorate_var(target_var)
	]

func _setup():
	nav = nav_var.get_value(scene_root, blackboard)
	desired_distance_squared = desired_distance_var.get_value(scene_root, blackboard, 0.5) ** 2
	max_distance_squared = max_distance_var.get_value(scene_root, blackboard, 20) ** 2
	run_distance_threshold_squared = run_distance_threshold_var.get_value(scene_root, blackboard) ** 2
	ready_to_pathfind = true
	assert(nav)
	
func _tick(delta):
	target = blackboard.get_var(target_var)
	var dist_sq = target.global_position.distance_squared_to(agent.global_position)
	DebugDraw2D.set_text("target_dist_sq", dist_sq)
	if dist_sq <= desired_distance_squared:
		agent.stop_navigation()
		return SUCCESS
	if dist_sq > max_distance_squared:
		agent.stop_navigation()
		return FAILURE
	
	if run_distance_threshold_squared < dist_sq:
		agent.move_modifier = PhysicsCharacterController3D.MoveMode.RUN
	else:
		agent.move_modifier = PhysicsCharacterController3D.MoveMode.WALK
		
	
	if !ready_to_pathfind:
		return RUNNING
	ready_to_pathfind = false
	scene_root.get_tree().create_timer(0.1, false).timeout.connect(func(): ready_to_pathfind = true)
	if target.global_position != nav.target_position:
		var lead_target := target.global_position + target.linear_velocity
		agent.start_navigation(lead_target)
	return RUNNING
