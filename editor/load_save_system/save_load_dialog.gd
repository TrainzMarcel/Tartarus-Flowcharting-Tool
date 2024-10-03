extends Control
class_name SaveLoadDialog

"TODO"#add comments describing these member vars
@export var main : Main
@export var window_header : Control
@export var save_container : Control
@export var load_container : Control

@export var timer : Timer
@export var file_display_container : Control
@export var b_close_1 : Button
@export var b_close_2 : Button
@export var b_save : Button
@export var b_load : Button
@export var save_name_edit : TextEdit
@export var load_name_edit : TextEdit
@export var b_folder_location : Button
@export var message_label : Control

var is_save_mode : bool = true
var is_merge_mode : bool = false
var double_press_to_continue = false

func _ready():
	b_folder_location.pressed.connect(on_folder_location_button_pressed)
	b_close_1.pressed.connect(on_close_button_pressed)
	b_close_2.pressed.connect(on_close_button_pressed)
	b_save.pressed.connect(on_save_button_pressed)
	b_load.pressed.connect(on_load_button_pressed)
	


func on_save_button_pressed():
	#check if name is valid
	if !(save_name_edit.text + ".csv").is_valid_filename():
		message_label.text = "[center]Invalid Filename![/center]"
		return
	
	#Are you sure you want to overwrite? Click save again.
	if FileAccess.file_exists(main.f_space + main.f_path + save_name_edit.text + ".csv") and !double_press_to_continue:
		message_label.text = "[center]Are you sure you want to overwrite? Click save again.[/center]"
		double_press_to_continue = true
		return
	elif double_press_to_continue:
		double_press_to_continue = false
	
	message_label.text = "[center]Flowchart saved successfully![/center]"
	main.save_flowchart(save_name_edit.text + ".csv")
	update_file_list()


func on_load_button_pressed():
	
	if main.block_array.size() > 0 and !double_press_to_continue and !is_merge_mode:
		message_label.text = "[center]Are you sure you want to load? This will clear the canvas.[/center]"
		double_press_to_continue = true
	elif double_press_to_continue:
		double_press_to_continue = false
	
	
	
	if !double_press_to_continue:
		if FileAccess.file_exists(main.f_space + main.f_path + load_name_edit.text + ".csv"):
			main.load_flowchart(load_name_edit.text + ".csv", !is_merge_mode)
			message_label.text = "[center]Flowchart loaded successfully![/center]"
		else:
			message_label.text = "[center]File not found.[/center]"


func show_dialog():
	save_container.visible = is_save_mode
	load_container.visible = !is_save_mode
	
	if is_save_mode:
		window_header.text = "Save flowchart..."
	else:
		window_header.text = "Load flowchart..."
	
	if is_merge_mode:
		window_header.text = "Merge flowchart..."
	
	update_file_list()
	visible = true
	main.camera_control.is_control_active = false


func hide_dialog():
	load_name_edit.clear()
	save_name_edit.clear()
	message_label.clear()
	double_press_to_continue = false
	visible = false
	main.camera_control.is_control_active = true


func update_file_list():
	for i in file_display_container.get_children():
		i.queue_free()
	
	if !DirAccess.dir_exists_absolute(main.f_space + main.f_path):
		DirAccess.make_dir_absolute(main.f_space + main.f_path)
	
	var file_names : PackedStringArray = DirAccess.get_files_at(main.f_space + main.f_path)
	
	var b_group : ButtonGroup = ButtonGroup.new()
	for i in file_names:
		var scene : PackedScene = load("res://editor/load_save_system/file_display.tscn")
		var new : Node = scene.instantiate()
		new.button.text = i
		new.button.button_group = b_group
		new.button.pressed.connect(on_button_in_file_select_pressed)
		file_display_container.add_child(new)


func on_button_in_file_select_pressed():
	for i in file_display_container.get_children():
		if i.button.button_pressed:
			save_name_edit.text = i.button.text.trim_suffix(".csv")
			load_name_edit.text = i.button.text.trim_suffix(".csv")
			break


func on_close_button_pressed():
	hide_dialog()


func on_folder_location_button_pressed():
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path(main.f_space + main.f_path))
