class_name Utilities

static func pointer_raycast(camera: Camera3D, ray_origin: Vector2, ray_length: float = 1000, additional_query_parameters: PhysicsRayQueryParameters3D = null) -> Dictionary:
	var space_state = camera.get_world_3d().direct_space_state
	var from = camera.project_ray_origin(ray_origin)
	var to = from + camera.project_ray_normal(ray_origin) * ray_length
	var query := PhysicsRayQueryParameters3D.create(from, to)
	if additional_query_parameters != null:
		var temp = query
		query = additional_query_parameters
		query.to = temp.to
		query.from = temp.from
		
	return space_state.intersect_ray(query)

## Returns false if a child of the specified type is not found, or the child if found
static func has_child(node: Node, type: String, recursive=false):
	var children = node.find_children("", type, true, recursive)
	if len(children) == 0:
		return false
	return children[0] if children[0] else false
