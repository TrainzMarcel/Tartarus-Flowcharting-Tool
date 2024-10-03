extends Control
class_name FlowChartBase

#dependencies-------------------------------------------------------------------
enum Shape {rectangle}#beveled, big_beveled, diamond
var text_edit : TextEdit
#enum Mode {block}#region, comment

#base settings------------------------------------------------------------------
@export var outline_thickness : Color = Color.BLACK
@export var outline_color : Color = Color.BLACK
var outline : Line2D
var polygon : Polygon2D
var min_size : int = 40
var padding : int = 2


#base save data-----------------------------------------------------------------
#position
#text edit.text
@export var base_color : Color = Color.WHITE

#in future
@export var base_size : Vector2 = Vector2(120, 80)
@export var base_shape : Shape = Shape.rectangle

#var base_mode : Mode = Mode.block
# Called when the node enters the scene tree for the first time.
func _ready():
	polygon = get_node("Polygon2D")
	polygon.antialiased = true
	outline = get_node("Line2D")
	text_edit = get_node("TextEdit")
	
	shape_update()

#for regions and comments
func mode_update():
	#shape_update()
	pass

func shape_update():
	#hitbox (critical)
	self.size = base_size
	
	#text edit
	text_edit.visible = true
	text_edit.size.x = self.size.x / text_edit.scale.x - padding * 2
	text_edit.size.y = self.size.y / text_edit.scale.y - padding * 2
	text_edit.position.x = padding
	text_edit.position.y = padding
	
	#cosmetic stuff
	if base_shape == Shape.rectangle:
		
		outline.end_cap_mode = Line2D.LINE_CAP_BOX
		outline.default_color = outline_color
		outline.width = 2
		
		var vertices : PackedVector2Array = PackedVector2Array()
		vertices.append(Vector2(0, 0))
		vertices.append(Vector2(base_size.x, 0))
		vertices.append(Vector2(base_size.x, base_size.y))
		vertices.append(Vector2(0, base_size.y))
		outline.points = vertices
		outline.add_point(Vector2(0, 0))
		polygon.polygon = vertices
		polygon.color = base_color
