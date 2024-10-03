@tool
extends Polygon2D
class_name DebugVector2D

@export var unit_vector : bool = false

@export var arrow_size : int = 50:
	set(value):
		arrow_size = value
		polygon = [Vector2(0,-arrow_size), Vector2(arrow_size,0), Vector2(0,arrow_size)]

@export var poly_color : Color = Color.WHITE:
	set(value):
		poly_color = value
		color = value

@export var input_vector : Vector2 = Vector2.RIGHT:
	set(value):
		input_vector = value
		rotation = atan2(input_vector.y, input_vector.x)
		if unit_vector:
			scale.x = input_vector.length()
		else:
			scale.x = input_vector.length() / arrow_size

@export var origin_position : Vector2 = Vector2.ZERO:
	set(value):
		if !is_inside_tree():
			return
		origin_position = value
		global_position = origin_position

# Called when the script is instantiated for the first time.
func _init():
	polygon = [Vector2(0,-50), Vector2(50,0), Vector2(0,50)]
