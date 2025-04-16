extends Control

var BrickRect = preload("uid://c47txkxxgap4t");

# @export var texture_grid:GridContainer;
@export var texture_button:TextureButton;
@export var color_picker:ColorPicker;

@export var shader_color:Color = Color(1, 1, 1);

@export_group("Categories")
@export var selector:OptionButton;
@export var quad_grid:GridContainer;
@export var circle_grid:GridContainer;

var grid_array:Array[Dictionary] = [];
var current_texture_type:String;

signal set_active_res_signal(res:Dictionary);

func _ready() -> void:
	grid_array = [
		{"control": quad_grid, "type": "Quadrangle"},
		{"control": circle_grid, "type": "Circle"}
	];
	current_texture_type = grid_array[0].type;

	selector.item_selected.connect(show_menu);

	for item in grid_array:
		var file_array := DirAccess.get_files_at("res://Assets/Visuals/BrickTextures/" + item.type);
		var filtered_array := Array(file_array.duplicate()).filter(func(string): return string.containsn(".import")); # There's no duplicates without .import
		
		for filename:String in filtered_array:
			var brick_rect:EditorBrickSample = BrickRect.instantiate();
			brick_rect.resource = {
				"texture_path": str("res://Assets/Visuals/BrickTextures/", item.type, '/', filename.trim_suffix(".import")),
				"texture_type": item.type
			};
			brick_rect.texture_rect.texture = load(str("res://Assets/Visuals/BrickTextures/", item.type, '/', filename.trim_suffix(".import")));

			item.control.add_child(brick_rect);
			brick_rect.set_active_res.connect(set_active_res);

	texture_button.toggled.connect(show_color_picker);
	color_picker.color_changed.connect(_on_color_changed);

func show_menu(idx:int):
	for item in grid_array:
		item.control.hide();
	current_texture_type = grid_array[idx].type;
	grid_array[idx].control.show();

func set_active_res(res):
	set_active_res_signal.emit(res);
	texture_button.texture_normal = load(res.texture_path);

func show_color_picker(toggled:bool):
	color_picker.visible = toggled;

func _on_color_changed(color:Color):
	texture_button.material.set_shader_parameter("to", color);
	shader_color = color;
