extends Camera2D
class_name CameraControl

@export var zoom_sensitivity : float = 0.1
@export var slerp_weight : float = 0.2
@export var zoom_display : RichTextLabel
@export var min_zoom : float = 0.2
@export var max_zoom : float = 6
@export var is_control_active : bool = true

var zoom_target : Vector2
var mouse_button_held : bool = false
var zoom_opposite : Vector2 = Vector2.ONE

func _ready():
	zoom_target = zoom
	zoom_sensitivity = zoom_sensitivity + 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
	

func _input(event):
	if event is InputEventMouseButton and is_control_active:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if !(zoom * zoom_sensitivity).x > max_zoom:
				zoom = zoom * zoom_sensitivity
				zoom_opposite = zoom_opposite / zoom_sensitivity
				zoom_display.text = str(round(zoom.x * 10) / 10) + "x"
			"TODO"#set global position so when zoom happens,
			#global mouse position doesnt change
			#see if slerp looks nice
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if !(zoom / zoom_sensitivity).x < min_zoom:
				zoom = zoom / zoom_sensitivity
				zoom_opposite = zoom_opposite * zoom_sensitivity
				zoom_display.text = str(round(zoom.x * 10) / 10) + "x"
		
		
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				mouse_button_held = true
			else:
				mouse_button_held = false
	
	if event is InputEventMouseMotion and is_control_active:
		if mouse_button_held:
			global_position = global_position - event.relative / zoom
			#global_position.x = snapped(global_position.x, 1)
			#global_position.y = snapped(global_position.y, 1)
	
	
	
	
	
