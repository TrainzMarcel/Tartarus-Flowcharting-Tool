@tool
extends Control
"TODO"#handledraw is a bad name for what has become scaling handles
class_name HandleDraw

@export var handle_array : Array[Button]
@export var handle_offset : int = 0
var direction_array : Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT]
var handle_held : bool = false
var linked_node : Control
var node_prev_size : Vector2
var node_prev_pos : Vector2

func _ready():
	for i in handle_array:
		i.button_down.connect(on_handle_button_down)
		i.button_up.connect(on_handle_button_up)

func on_handle_button_down():
	handle_held = true
	if is_instance_valid(linked_node):
		node_prev_pos = linked_node.global_position
		node_prev_size = linked_node.size

func on_handle_button_up():
	handle_held = false

func handle_update():
	var i : int = 0
	var node : Control = linked_node
	#positioning handles
	while i < handle_array.size():
		var handle_center = -handle_array[i].size * 0.5
		var node_center = node.size * 0.5
		handle_array[i].position = (direction_array[i] * handle_offset) + handle_center + direction_array[i] * node_center + node_center
		
		
		
		
		i = i + 1
	
	
