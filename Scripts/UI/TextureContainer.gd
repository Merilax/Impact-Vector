extends Control
class_name EditorTextureContainer

var BrickRect = preload("uid://c47txkxxgap4t");

# @export var texture_grid:GridContainer;
@export_group("Nodes")
@export var color_picker:ColorPicker;
@export var color_previews:HBoxContainer;
@export var color_picker_save_btn:Button;

@export_group("Categories")
@export var selector:OptionButton;
@export var quad_grid:GridContainer;
@export var circle_grid:GridContainer;

var shader_color_count:int = 1;
var selected_channel:int = 0; # 0-based, but shader params are 1-based.

var shader_colors:Array[Color] = [Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 1)];

var bricks:Array = [];
var grid_array:Array[Dictionary] = [];
var current_texture_type:String;

signal set_active_res_signal(res:Dictionary);
signal _on_color_channel_changed(channel:int, color:Color);
signal _on_color_recent(color:Color);
signal _on_color_saved(color:Color);

func _ready() -> void:
	grid_array = [
		{"control": quad_grid, "type": "Quadrangle"},
		{"control": circle_grid, "type": "Circle"}
	];
	current_texture_type = grid_array[0].type;

	selector.item_selected.connect(show_menu);

	for item in grid_array:
		
		for dir_num in DirAccess.get_directories_at("res://Assets/Visuals/BrickTextures/" + item.type):
			var file_array := DirAccess.get_files_at("res://Assets/Visuals/BrickTextures/" + item.type + '/' + dir_num);
			var filtered_array := Array(file_array.duplicate()).filter(func(string): return string.containsn(".import")); # There's no duplicates without .import

			for filename:String in filtered_array:
				var brick_rect:EditorBrickSample = BrickRect.instantiate();
				brick_rect.resource = {
					"texture_path": str("res://Assets/Visuals/BrickTextures/", item.type, '/', dir_num, '/', filename.trim_suffix(".import")),
					"texture_type": item.type,
					"color_count": int(dir_num)
				};
				brick_rect.set_shader_color_count(int(dir_num));
				brick_rect.texture_rect.texture = load(str("res://Assets/Visuals/BrickTextures/", item.type, '/', dir_num, '/', filename.trim_suffix(".import")));

				item.control.add_child(brick_rect);
				bricks.append(brick_rect);
				brick_rect.set_active_res.connect(set_active_res);
				_on_color_channel_changed.connect(brick_rect.set_shader_color);

	color_picker.color_changed.connect(_on_color_changed);
	color_picker_save_btn.gui_input.connect(save_color);

	for i in range(color_previews.get_child_count()):
		color_previews.get_child(i).gui_input.connect(_on_gui_input.bind(i));

func show_menu(idx:int):
	for item in grid_array:
		item.control.hide();
	current_texture_type = grid_array[idx].type;
	grid_array[idx].control.show();

func set_active_res(res):
	set_active_res_signal.emit(res);
	shader_color_count = res.color_count;
	selected_channel = 0;

	for i in range(color_previews.get_child_count()):
		if i < shader_color_count: color_previews.get_child(i).show();
		else: color_previews.get_child(i).hide();

	for i in range(color_previews.get_child_count()):
		if i < shader_color_count: color_previews.get_child(i).show();
		else: color_previews.get_child(i).hide();

	if shader_color_count <= 0:
		color_picker.hide();
		color_previews.hide();
	else:
		color_picker.show();
		color_previews.show();
	
	for i in range(0,4):
		color_previews.get_child(i).color = shader_colors[i];

func _on_gui_input(input:InputEvent, channel:int):
	if input is InputEventMouseButton:
		if input.is_action_pressed("mouse_primary") or input.is_action_pressed("mouse_secondary"):
			set_selected_channel(channel);

func set_selected_channel(channel:int):
	selected_channel = channel;
	color_picker.color = shader_colors[channel];

func set_shader_color(channel:int, color:Color):
	# texture_button.material.set_shader_parameter(str("target_color", channel + 1), color);
	shader_colors[channel] = color;

func save_color(event:InputEvent):
	if event is InputEventMouseButton:
		if event.is_action_pressed("mouse_primary"):
			_on_color_saved.emit(shader_colors[selected_channel]);

func set_color_from_swatch(color:Color):
	# texture_button.material.set_shader_parameter(str("target_color", selected_channel + 1), color);
	shader_colors[selected_channel] = color;
	color_picker.color = color;
	color_previews.get_child(selected_channel).color = color;
	_on_color_channel_changed.emit(selected_channel, color);

func _on_color_changed(color:Color):
	# texture_button.material.set_shader_parameter(str("target_color", selected_channel + 1), color);
	shader_colors[selected_channel] = color;
	color_previews.get_child(selected_channel).color = color;
	_on_color_channel_changed.emit(selected_channel, color);
	_on_color_recent.emit(shader_colors[selected_channel]);
