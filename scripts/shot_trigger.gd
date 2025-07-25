@tool
class_name  ShotTrigger
extends Area3D

@export_range(0, 50)
var shot_priority: int = 1

@onready
var _fired_timer:= $Timer
var _fired_once: bool = false
@export
var one_shot: bool = false:
	set(value):
		one_shot = value
		notify_property_list_changed()
var linked_shot: ShotTrigger

var _camera: PhantomCamera3D
@export
var camera: PhantomCamera3D:
	get:
		return _camera
	set(value):
		_camera = value
		update_configuration_warnings()

@export
var active: bool:
	get:
		return monitoring
	set(value):
		set_deferred(&"monitoring", value)
		if !Engine.is_editor_hint() and camera:
			print(camera.name + " " + name + " is now %s" % ("active" if active else "inactive"))
		if !value and _fired_timer:
			_fired_timer.stop()

#var _host: PhantomCameraHost
#@export
#var camera_host: PhantomCameraHost:
	#get:
		#return _host
	#set(value):
		#_host = value
		#update_configuration_warnings()

func _ready() -> void:
	if !is_inside_tree() or self == get_tree().edited_scene_root or !Engine.is_editor_hint():
		return
	if find_children("*", "CollisionShape3D", false):
		return
	#var host_manager = Engine.get_singleton("PhantomCameraManager")
	#camera_host = host_manager.phantom_camera_hosts[0] if len(host_manager._phantom_camera_host_list) > 0 else null
	var root = get_tree().edited_scene_root
	top_level = true
	var undo_redo := UndoRedo.new()
	undo_redo.create_action("Add CollisionShape3D to ShotTrigger")
	var collision_shape := CollisionShape3D.new()
	undo_redo.add_do_reference(collision_shape)
	root.add_child(collision_shape, true)
	collision_shape.owner = root
	collision_shape.reparent(self)
	collision_shape.shape = BoxShape3D.new()
	undo_redo.commit_action()
	
	if get_parent() is PhantomCamera3D:
		camera = get_parent()
		if position == Vector3.ZERO:
			position = get_parent().position

func _on_body_entered(body: Node3D) -> void:
	if body is not PlayerController:
		return
	camera.visible = true
	camera.priority = shot_priority
	if one_shot:
		_fired_timer.start()
		_fired_timer.timeout.connect(func (): _fired_once = true)

func _on_body_exited(body: Node3D) -> void:
	if body is not PlayerController:
		return
	if !linked_shot or linked_shot.camera != camera:
		camera.priority = 0
		camera.visible = false
	_fired_timer.stop()
	if _fired_once and one_shot:
		active = false
		if linked_shot:
			linked_shot.active = true

func _get_configuration_warnings():
	if !is_inside_tree() or is_inside_tree() and self == get_tree().edited_scene_root:
		return
	var errors = []
	#if camera_host == null:
		#errors.append("PhantomCameraHost not found in scene")
	if camera == null:
		errors.append("PhantomCamera must be set")
	return errors

func _get_property_list() -> Array[Dictionary]:
	var ret : Array[Dictionary] = []
	if one_shot:
		ret.append({
				"name": &"linked_shot",
				"type": TYPE_OBJECT,
				"hint": PROPERTY_HINT_NODE_TYPE,
				"hint_string": "ShotTrigger",
				"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
				})
		if linked_shot and is_instance_valid(linked_shot):
			linked_shot.active = false
		else:
			linked_shot = null
	return ret
