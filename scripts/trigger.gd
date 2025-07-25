@tool
class_name Trigger
extends Area3D

signal triggered(body: Node3D)

@export var one_shot := false
@export var groups: Array[StringName] = []

var fired := false

func _ready():
	if !is_inside_tree() or self == get_tree().edited_scene_root or !Engine.is_editor_hint():
		return
		
	if !Utilities.has_child(self, "CollisionShape3D"):
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

func _on_body_entered(body: Node3D):
	if one_shot and fired:
		return
		
	for group in body.get_groups():
		if group in groups:
			triggered.emit(body)
			fired = true
			print("Triggered " + name)
			break
