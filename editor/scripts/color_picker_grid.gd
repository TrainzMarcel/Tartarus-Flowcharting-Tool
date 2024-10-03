extends Panel
class_name ColorPickerGrid

@export var color_array : Array[Color]
var button_array : Array[Button]
var selected_color : Color

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in get_node("MarginContainer/VBoxContainer").get_children():
		button_array.append_array(i.get_children())
	
	var i : int = 0
	var b_group : ButtonGroup = ButtonGroup.new()
	
	while i < button_array.size():
		button_array[i].button_group = b_group
		button_array[i].modulate = color_array[i]
		button_array[i].pressed.connect(on_button_pressed)
		
		i = i + 1


func on_button_pressed():
	var i : int = 0
	
	while i < button_array.size():
		if button_array[i].button_pressed:
			selected_color = button_array[i].modulate
		
		i = i + 1
