extends Control

var BrickRect = preload("uid://c47txkxxgap4t")

@export var texture_grid:GridContainer
@export var texture_button:TextureButton
@export var color_picker:ColorPicker

@export var shader_color:Color = Color(1, 1, 1)

signal set_active_res_signal(texture_path:String)

func _ready() -> void:
	var file_array:PackedStringArray = DirAccess.get_files_at("res://Assets/Visuals/BrickTextures/")
	var filtered_array:Array = Array(file_array.duplicate()).filter(func(string): return string.containsn(".import")) # There's no duplicates without .import
	
	for FilePath:String in filtered_array:
		var brick_rect:EditorBrickSample = BrickRect.instantiate()
		brick_rect.resource = "res://Assets/Visuals/BrickTextures/" + FilePath.trim_suffix(".import")
		brick_rect.texture_rect.texture = load("res://Assets/Visuals/BrickTextures/" + FilePath.trim_suffix(".import"))

		texture_grid.add_child(brick_rect)
		brick_rect.set_active_res.connect(set_active_res)

	texture_button.toggled.connect(show_color_picker)
	color_picker.color_changed.connect(_on_color_changed)

func set_active_res(res_path):
	set_active_res_signal.emit(res_path)
	texture_button.texture_normal = load(res_path)

func show_color_picker(toggled:bool):
	color_picker.visible = toggled

func _on_color_changed(color:Color):
	texture_button.material.set_shader_parameter("to", color)
	shader_color = color

func _on_root_control_sort_children():
	for brick_rect:EditorBrickSample in texture_grid.get_children():
		brick_rect.texture_rect.custom_minimum_size.x = texture_grid.size.x / texture_grid.columns;