@tool
extends BTAction

@export var target_pos_var := &"target_pos"
@export var nav_var: BBNode

var target_pos: Vector3
var nav: NavigationAgent3D

func _generate_name() -> String:
	return "WalkToPosition %s" % [
		LimboUtility.decorate_var(target_pos_var)
	]

func _setup():
	target_pos = blackboard.get_var(target_pos_var)
	nav = nav_var.get_value(scene_root, blackboard) as NavigationAgent3D
	
func _tick(delta):
	target_pos = blackboard.get_var(target_pos_var)
	if target_pos != nav.target_position:
		agent.start_navigation(target_pos)
	if nav.is_navigation_finished():
		return SUCCESS
	return RUNNING
