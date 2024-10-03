extends Control
class_name GridDraw

@export var grid_size : Vector2 = Vector2.ZERO
@export var grid_spacing : Vector2 = Vector2.ONE * 5
@export var grid_thickness : int = 2
@export var grid_color : Color = Color(0, 0, 0)

func grid_update():
	queue_redraw()

func draw_grid_line(points : PackedVector2Array, thickness : int, color : Color):
	var new : Line2D = Line2D.new()
	new.points = points
	new.width = thickness
	new.default_color = color
	#new
	self.add_child(new)
	new.owner = self

func _draw():
	#draw x grid lines
	var i : int = 0
	while i <= grid_size.y:
		draw_line(Vector2(0, i), Vector2(grid_size.x, i), grid_color)
		i = i + int(grid_spacing.y)
	
	i = 0
	while i <= grid_size.x:
		draw_line(Vector2(i, 0), Vector2(i, grid_size.y), grid_color)
		i = i + int(grid_spacing.x)

func _ready():
	self.size = grid_size
	grid_update()
