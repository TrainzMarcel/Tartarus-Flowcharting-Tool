extends Control
class_name Main

#top left bar ui buttons
@export var b_drag_block : Button
@export var b_connect_block : Button
@export var b_paint_block : Button
@export var b_paint_grid : ColorPickerGrid
@export var b_delete_block : Button
@export var b_spawn_block : Button
@export var b_hide_grid : CheckBox

#top right bar ui buttons
@export var b_merge_flowchart : Button
@export var b_load_flowchart : Button
@export var b_save_flowchart : Button

#save dialog scene
@export var save_dialog : SaveLoadDialog

#background
"TODO v0.2"#make grid infinite (move with camera) and prettier
@export var grid_draw : GridDraw

#contains blocks and arrows
@export var flowchart_container : Control

#contains the (visual) selection boxes
@export var selection_container : Control

#snapping size for blocks on grid
@export var increment : int = 20

"TODO v0.2"#eventually add region array and comment array
#var region_array : Array[Control]
#existing blocks as children of flowchart_container
var block_array : Array[Control]
#existing connectors as children of flowchart_container
var connector_array : Array[Control]
#all selected blocks
var selected_blocks_array : Array[Control]
#existing selection boxes as children of selection_container
var selection_box_array : Array[Node]

#to detect if im hovering over any buttons
@export var no_drag_ui_array : Array[Control]
#since zooming requires a canvaslayer to make the ui work and
#ui in a canvaslayer does not give the correct global_position,
#i need a reference to all canvaslayers which have interactive ui in them
#to get the correct global position
@export var camera_control : CameraControl


#all flowchartbase nodes under cursor 
var hovered_block : Array[Control] = []
#last clicked block, used to keep track of what is being dragged
var dragged_block : Control

#one selection rect for hovered blocks
@export var hover_selection_box : SelectionRect
@export var scaling_handles : HandleDraw

#required for drag logic
var mouse_button_held : bool = false
#offset of every selected block from the mouse
var drag_offset : Array[Vector2] = []

#helpful bool
var is_drag_tool_selected : bool = false


#flowchart container related functions
func update_connector_array():
	connector_array.clear()
	for i in flowchart_container.get_children():
		if i is FlowChartConnector:
			connector_array.append(i)
 
"TODO v0.2"#make it possible to delete connectors with delete tool
#entails:
#adding a .hitbox_array to arrows
#using said hitboxes for selection boxes
#maybe giving flowchartbase a .hitbox_array as well
#instead of using its root control node as hitbox
#to make the code more cohesive


func update_block_array():
	block_array.clear()
	for i in flowchart_container.get_children():
		if i is FlowChartBase:
			block_array.append(i)


func hovered_block_check():
	update_block_array()
	hovered_block.clear()
	for i in block_array:
		if Rect2(i.global_position, i.size).has_point(get_global_mouse_position()):
			hovered_block.append(i)


func camera_to_global(camera_input : Vector2):
	var pos : Vector2 = (camera_input - get_viewport_rect().size * 0.5) * camera_control.zoom_opposite
	pos = pos + camera_control.global_position
	return pos


func hovered_ui_check():
	for i in no_drag_ui_array:
		if i.visible:
			var rect : Rect2 = Rect2(camera_to_global(i.global_position), i.size * camera_control.zoom_opposite)
			if rect.has_point(get_local_mouse_position()):
				return true
	return false


#selection box related functions
func unload_selection_box(linked_node : Node):
	for i in selection_box_array:
		if i.linked_node == linked_node:
			selection_box_array.erase(i)
			i.queue_free()
			break

func unload_all_selection_boxes():
	for i in selection_box_array:
		i.queue_free()
	
	selection_box_array.clear()


func instance_selection_box():
	var new : SelectionRect = SelectionRect.new()
	#no need to set an owner
	selection_container.add_child(new)
	selection_box_array.append(new)
	return new


#if drag tool is selected, prevent text edit usage
func toggle_text_editing(enable : bool):
	if block_array.size() > 0:
		if enable:
			for i in block_array:
				if is_instance_valid(i):
					#disable editing
					i.text_edit.mouse_filter = MOUSE_FILTER_IGNORE
		else:
			for i in block_array:
				if is_instance_valid(i):
					#enable editing
					i.text_edit.mouse_filter = MOUSE_FILTER_STOP


# Called when the node enters the scene tree for the first time.
func _ready():
	#eco friendly technology
	OS.low_processor_usage_mode = true
	update_block_array()
	update_connector_array()
	b_spawn_block.pressed.connect(on_b_spawn_block_pressed)
	b_connect_block.pressed.connect(on_b_connect_pressed)
	b_hide_grid.pressed.connect(on_b_hide_grid_pressed)
	b_save_flowchart.pressed.connect(on_b_save_flowchart_pressed)
	b_load_flowchart.pressed.connect(on_b_load_flowchart_pressed)
	b_merge_flowchart.pressed.connect(on_b_merge_flowchart_pressed)
	
	b_drag_block.pressed.connect(on_b_tool_pressed)
	b_delete_block.pressed.connect(on_b_tool_pressed)
	b_paint_block.pressed.connect(on_b_tool_pressed)
	for i in b_paint_grid.button_array:
		i.pressed.connect(on_b_tool_pressed)


#add an update in here
func on_b_spawn_block_pressed():
	var scene : PackedScene = preload("res://editor/flowchart_scenes/fc_block.tscn")
	var new : FlowChartBase = scene.instantiate()
	flowchart_container.add_child(new)
	
	new.owner = flowchart_container
	new.global_position.x = round(camera_control.global_position.x / increment) * increment
	new.global_position.y = round(camera_control.global_position.y / increment) * increment
	new.global_position = new.global_position - new.base_size * 0.5
	
	#if a drag tool is selected, prevent text edit usage
	if is_drag_tool_selected:
		new.text_edit.mouse_filter = MOUSE_FILTER_IGNORE


#hide grid if corresponding button is pressed
func on_b_hide_grid_pressed():
	grid_draw.visible = !grid_draw.visible


#set hover selection box color
func on_b_tool_pressed():
	toggle_text_editing(is_drag_tool_selected)
	if !b_drag_block.button_pressed:
		if b_delete_block.button_pressed:
			hover_selection_box.box_color = Color(0.85, 0, 0)
		elif b_paint_block.button_pressed:
			hover_selection_box.box_color = b_paint_grid.selected_color
	else:
		hover_selection_box.box_color = Color(0, 0.79, 1)
	hover_selection_box.box_update()


func on_b_connect_pressed():
	if selected_blocks_array.size() > 1:
		var scene : PackedScene = preload("res://editor/flowchart_scenes/fc_connector.tscn")
		var i : int = 0
		while i < selected_blocks_array.size() - 1:
			var new : FlowChartConnector = scene.instantiate()
			
			flowchart_container.add_child(new)
			new.owner = get_tree().root
			
			new.blk_1 = selected_blocks_array[i]
			new.blk_2 = selected_blocks_array[i + 1]
			new.owner = flowchart_container
			
			new.connector_update()
			i = i + 1
		update_connector_array()





func _input(event):
#selection handling
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#lmb down
	is_drag_tool_selected = b_drag_block.button_pressed or b_delete_block.button_pressed
	is_drag_tool_selected = is_drag_tool_selected or b_paint_block.button_pressed
	if event is InputEventMouseButton:
		if !hovered_ui_check():
			"TODO v0.2"#add release focus to stop text box focus
			#when theres no hovered ui 
			#get_viewport().gui_release_focus()
			if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				hovered_block_check()
				if hovered_block.size() == 0:
				#unfocus block text box if canvas is clicked
					var focus : Control = get_window().gui_get_focus_owner()
					if is_instance_valid(focus):
						focus.release_focus()
				
				for i in scaling_handles.handle_array:
					if i.button_pressed or i.is_hovered():
						is_drag_tool_selected = false
				
				if is_drag_tool_selected:
					mouse_button_held = true
					
				#any hovered blocks?
					if hovered_block.size() == 0:
				#no hovered blocks, then clear selection on click
						selected_blocks_array.clear()
						unload_all_selection_boxes()
					elif hovered_block.size() > 0:
				#hovered_blocks > 0 so prepare everything for dragging
						#assign dragged_block
						dragged_block = hovered_block[hovered_block.size() - 1]
			#is block already selected?
						if selected_blocks_array.has(hovered_block[hovered_block.size() - 1]):
			#yes, hovered block is already selected
						#shift held?
							if Input.is_key_pressed(KEY_SHIFT):
						#yes shift held, then remove from selection
								selected_blocks_array.erase(hovered_block[hovered_block.size() - 1])
								unload_selection_box(hovered_block[hovered_block.size() - 1])
						
			#no, hovered block is not selected yet
						else:
						#shift held?
							if Input.is_key_pressed(KEY_SHIFT):
						#yes shift held, append to selection
								selected_blocks_array.append(hovered_block[hovered_block.size() - 1])
								var box : SelectionRect = instance_selection_box()
								box.linked_node = hovered_block[hovered_block.size() - 1]
								box.box_scale = box.linked_node.size
								box.global_position = box.linked_node.global_position
								box.box_update()
							else:
						#shift not held, set hovered block as selection
								selected_blocks_array.clear()
								selected_blocks_array.append(hovered_block[hovered_block.size() - 1])
								unload_all_selection_boxes()
								var box : SelectionRect = instance_selection_box()
								box.linked_node = hovered_block[hovered_block.size() - 1]
								box.box_scale = box.linked_node.size
								box.global_position = box.linked_node.global_position
								box.box_update()
					
					"TODO v0.2"#clean up this mess
					if selected_blocks_array.size() == 1:
						scaling_handles.visible = true
						scaling_handles.global_position = selected_blocks_array[0].global_position
						scaling_handles.linked_node = selected_blocks_array[0]
						scaling_handles.handle_update()
					else:
						scaling_handles.visible = false
					
					#update all offsets on drag
					#every offset index should correspond to the block of the same index
					drag_offset.clear()
					for i in selected_blocks_array:
						drag_offset.append(i.global_position - get_global_mouse_position())
	#lmb up
			elif !event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				if is_drag_tool_selected:
					mouse_button_held = false
					dragged_block = null
		
		
		
		
#other tools
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#lmb down
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if b_delete_block.button_pressed and hovered_block.size() > 0:
				#hide scaling handles if theyre visible
				if selected_blocks_array.size() == 1:
					scaling_handles.visible = false
				
				#deleting any connectors that connect to the hovered block
				for i in connector_array:
					if !is_instance_valid(i):
						continue
					
					if hovered_block.has(i.blk_1):
						if i and !i.is_queued_for_deletion():
							hovered_block.erase(i)
							i.queue_free()
					elif hovered_block.has(i.blk_2):
						if i and !i.is_queued_for_deletion():
							hovered_block.erase(i)
							i.queue_free()
				#delete last appended block hovered block
				unload_selection_box(hovered_block[hovered_block.size() - 1])
				hovered_block[hovered_block.size() - 1].queue_free()
				update_connector_array()
			
			
			toggle_text_editing(is_drag_tool_selected)
			
			if b_paint_block.button_pressed and hovered_block.size() > 0:
				hovered_block[hovered_block.size() - 1].base_color = b_paint_grid.selected_color
				hovered_block[hovered_block.size() - 1].shape_update()
		
		
	#drag handling
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
	#mouse motion
	"TODO"#add more comments
	if event is InputEventMouseMotion:
		if !hovered_ui_check():
			if is_drag_tool_selected:
				hovered_block_check()
				if hovered_block.size() > 0:
					hover_selection_box.visible = true
					hover_selection_box.box_scale = hovered_block[hovered_block.size() - 1].size
					hover_selection_box.global_position = hovered_block[hovered_block.size() - 1].global_position
					hover_selection_box.box_update()
				else:
					hover_selection_box.visible = false
				
				if mouse_button_held and selected_blocks_array.size() > 0:
					if dragged_block != null:
						if !dragged_block.is_queued_for_deletion():
							if selected_blocks_array.has(dragged_block):
								var i : int = 0
								while i < selected_blocks_array.size():
									var dragged_position = drag_offset[i] + get_global_mouse_position()
									dragged_position.x = round(dragged_position.x / increment) * increment
									dragged_position.y = round(dragged_position.y / increment) * increment
									
									selected_blocks_array[i].global_position = dragged_position
									selection_box_array[i].global_position = dragged_position
									
									for j in connector_array:
										if !is_instance_valid(j):
											continue
										
										if j.blk_1 == selected_blocks_array[i] or j.blk_2 == selected_blocks_array[i]:
											j.connector_update()
									
									i = i + 1
								hover_selection_box.global_position = dragged_block.global_position
						
						if selected_blocks_array.size() == 1:
							scaling_handles.global_position = selected_blocks_array[0].global_position
			
			if scaling_handles.handle_held and is_instance_valid(selected_blocks_array[0]):
				var j : int = 0
				while j < scaling_handles.handle_array.size():
					if scaling_handles.handle_array[j].button_pressed:
						var blk : FlowChartBase = selected_blocks_array[0]
						
						"TODO v0.2"#clean up all the ugly scaling handles code
						#this is hacky as fuck, but it works to prevent an offset bug
						var m_snap = get_global_mouse_position()
						#if u comment the 2 below lines out u will see what i mean
						#when dragging left and upper handles
						m_snap.x = snapped(m_snap.x, increment)
						m_snap.y = snapped(m_snap.y, increment)
					#up
						if scaling_handles.direction_array[j] == Vector2.UP:
							blk.base_size.y = scaling_handles.node_prev_pos.y - m_snap.y + scaling_handles.node_prev_size.y
							blk.global_position.y = m_snap.y
					#down
						elif scaling_handles.direction_array[j] == Vector2.DOWN:
							blk.base_size.y = m_snap.y - blk.global_position.y
					#right
						elif scaling_handles.direction_array[j] == Vector2.RIGHT:
							blk.base_size.x = m_snap.x - blk.global_position.x
					#left
						else:
							blk.base_size.x = scaling_handles.node_prev_pos.x - m_snap.x + scaling_handles.node_prev_size.x
							blk.global_position.x = m_snap.x
						
						blk.base_size.x = round(blk.base_size.x / increment) * increment
						blk.base_size.y = round(blk.base_size.y / increment) * increment
						blk.global_position.x = round(blk.global_position.x / increment) * increment
						blk.global_position.y = round(blk.global_position.y / increment) * increment
						
						blk.base_size.x = max(blk.base_size.x, blk.min_size)
						blk.base_size.y = max(blk.base_size.y, blk.min_size)
						
						blk.shape_update()
						hover_selection_box.global_position = blk.global_position
						selection_box_array[0].box_scale = blk.base_size
						selection_box_array[0].global_position = blk.global_position
						scaling_handles.global_position = blk.global_position
						selection_box_array[0].box_update()
						scaling_handles.handle_update()
						
						
						for k in connector_array:
							if !is_instance_valid(k):
								continue
							
							if k.blk_1 == blk or k.blk_2 == blk:
								k.connector_update()
						
						break
					
					j = j + 1
					
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------




#for now dont worry about saving and loading
#ultimately imma iterate over all the flowchart nodes in the container
#and get the crucial data to then turn it into a csv
#
#then do the opposite on load
#------------------------------------------------------

func on_b_save_flowchart_pressed():
	save_dialog.is_save_mode = true
	save_dialog.is_merge_mode = false
	save_dialog.show_dialog()

func on_b_load_flowchart_pressed():
	save_dialog.is_save_mode = false
	save_dialog.is_merge_mode = false
	save_dialog.show_dialog()

func on_b_merge_flowchart_pressed():
	save_dialog.is_save_mode = false
	save_dialog.is_merge_mode = true
	save_dialog.show_dialog()

func clear_flowchart():
	update_connector_array()
	for i in connector_array:
		i.queue_free()
	if connector_array.size() > 0:
		await connector_array[connector_array.size() - 1].tree_exited
	connector_array.clear()
	
	update_block_array()
	for i in block_array:
		i.queue_free()
	if block_array.size() > 0:
		await block_array[block_array.size() - 1].tree_exited
	block_array.clear()
	
	selected_blocks_array.clear()
	for i in selection_box_array:
		i.queue_free()
	if selection_box_array.size() > 0:
		await selection_box_array[selection_box_array.size() - 1].tree_exited
	selection_box_array.clear()

var type_delimiter : Array[String] = ["::BLOCK::", "::CONNECTOR::"]


func load_flowchart(save_name : String, pre_clear : bool):
	var prev_block_amount : int = block_array.size()
	if pre_clear:
		#this would not wait for the blocks to delete
		#and itd cause annoying bugs otherwise
		"TODO"#put this and saving and loading on another thread
		await clear_flowchart()
	
	var file = FileAccess.open(f_space + f_path + save_name, FileAccess.READ)
	var content : PackedStringArray
	var mode : int = 0
	
	if !is_instance_valid(file):
		return
	
	while file.get_position() < file.get_length():
		content = file.get_csv_line()
		
		#if theres a delimiter like ::CONNECTOR::, change mode
		if content.size() == 1:
			if content[0] == type_delimiter[0]:
				mode = 0
				continue
			elif content[0] == type_delimiter[1]:
				#make sure block_array is up to date when instancing connectors
				#especially to get the correct indices for them
				update_block_array()
				mode = 1
				continue
		
		
		#decode block
		if mode == 0:
			var scene : PackedScene = preload("res://editor/flowchart_scenes/fc_block.tscn")
			var new : FlowChartBase = scene.instantiate()
			var count = content.size()
			flowchart_container.add_child(new)
			new.owner = flowchart_container
			
			#position
			#these ifs make it possible to read older save files
			if count > 1:
				new.global_position.x = float(content[0])
				new.global_position.y = float(content[1])
			
			#text
			if count > 2:
				new.text_edit.text = content[2]
			
			#color
			if count > 5:
				new.base_color.r8 = int(content[3])
				new.base_color.g8 = int(content[4])
				new.base_color.b8 = int(content[5])
			
			#size
			if count > 7:
				new.base_size.x = int(content[6])
				new.base_size.y = int(content[7])
			
			new.shape_update()
		
		#decode connector
		elif mode == 1:
			var scene : PackedScene = preload("res://editor/flowchart_scenes/fc_connector.tscn")
			var new : FlowChartConnector = scene.instantiate()
			var count = content.size()
			
			flowchart_container.add_child(new)
			new.owner = flowchart_container
			
			#setting which blocks to connect to
			if count > 1:
				if !pre_clear:
					new.blk_1 = block_array[int(content[0]) + prev_block_amount]
					new.blk_2 = block_array[int(content[1]) + prev_block_amount]
				else:
					new.blk_1 = block_array[int(content[0])]
					new.blk_2 = block_array[int(content[1])]
			
			
			#setting direction property
			#(more about this property in the comments of connector.gd)
			if count > 2:
				if content[2] == "0":
					new.direction = Vector2.UP
				elif content[2] == "1":
					new.direction = Vector2.RIGHT
				elif content[2] == "2":
					new.direction = Vector2.DOWN
				elif content[2] == "3":
					new.direction = Vector2.LEFT
			
			new.connector_update()
	
	file.close()
	update_connector_array()


var f_space : String = "user://"
var f_path : String = "saved_flowcharts/"

#please check if path is valid, if name is valid and if flowchart has any contents
func save_flowchart(save_name : String):
	var file = FileAccess.open(f_space + f_path + save_name, FileAccess.WRITE)
	var i : int = 0
	
	update_block_array()
	#::BLOCK::
	file.store_csv_line([type_delimiter[0]])
	while i < block_array.size():
		var block : FlowChartBase = block_array[i]
		var line : PackedStringArray = PackedStringArray()
		
		#!!do not change the order of these or we lose backward compatibility with older version saves!!#
		#position
		line.append(str(block.position.x))
		line.append(str(block.position.y))
		#text
		line.append(str(block.text_edit.text))
		#color
		line.append(str(block.base_color.r8))
		line.append(str(block.base_color.g8))
		line.append(str(block.base_color.b8))
		#size
		line.append(str(block.base_size.x))
		line.append(str(block.base_size.y))
		file.store_csv_line(line)
		i = i + 1
	
	
	update_connector_array()
	#::CONNECTOR::
	file.store_csv_line([type_delimiter[1]])
	i = 0
	while i < connector_array.size():
		var con : FlowChartConnector = connector_array[i]
		var line : PackedStringArray = PackedStringArray()
		
		#indices of connected blocks
		line.append(str(block_array.find(con.blk_1)))
		line.append(str(block_array.find(con.blk_2)))
		
		#direction
		match con.direction:
			Vector2.UP:
				line.append("0")
			Vector2.RIGHT:
				line.append("1")
			Vector2.DOWN:
				line.append("2")
			Vector2.LEFT:
				line.append("3")
		file.store_csv_line(line)
		
		i = i + 1
	
	selected_blocks_array.clear()
	for j in selection_box_array:
		j.queue_free()
	selection_box_array.clear()
	
	file.close()
