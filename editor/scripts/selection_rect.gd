@tool
extends Line2D
class_name SelectionRect

@export var update : bool = false:
	set(_value):
		update = false
		box_update()
@export var box_scale : Vector2
@export var box_thickness : int = 5
@export var box_color : Color = Color(0.0, 0.6, 1.0)
#reference to node that this selection box is surrounding
"TODO"#make second mode for surrounding arrows(maybe)
var linked_node : Control

func box_update():
	var box_points : PackedVector2Array = PackedVector2Array()
	box_points.append(Vector2(0, 0))
	box_points.append(Vector2(box_scale.x, 0))
	box_points.append(Vector2(box_scale.x, box_scale.y))
	box_points.append(Vector2(0, box_scale.y))
	box_points.append(Vector2(0, 0))
	clear_points()
	end_cap_mode = Line2D.LINE_CAP_BOX
	width = box_thickness
	default_color = box_color
	points = box_points
