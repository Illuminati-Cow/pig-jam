@tool
class_name Junction extends Area3D

enum JunctionDirection
{
	XZ,
	XY,
	YZ
}
## Axes which the junction connects
@export var axis: JunctionDirection = JunctionDirection.XZ
