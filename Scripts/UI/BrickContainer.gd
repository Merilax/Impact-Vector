extends GridContainer

var BrickRect = preload("uid://c47txkxxgap4t");
var BrickScene = preload("uid://dtkn1xk6stg0v");

signal set_active_res_signal(res:Dictionary);

func _ready() -> void:
	# for dir_num in DirAccess.get_directories_at("res://Assets/Visuals/BrickTextures/BaseTypes/"):
	var file_array:PackedStringArray = DirAccess.get_files_at("res://Assets/Visuals/BrickTextures/BaseTypes");
	var filtered_array:Array = Array(file_array.duplicate()).filter(func(string): return string.containsn(".import")); # There's no duplicates without .import
	for filename:String in filtered_array:
		var brick_rect:EditorBrickSample = BrickRect.instantiate();
		brick_rect.texture_rect.texture = load("res://Assets/Visuals/BrickTextures/BaseTypes/" + filename.trim_suffix(".import"));
		brick_rect.resource = {
			"hitbox_path": str("res://Scenes/Game/Components/Hitboxes/", filename.trim_suffix(".import").trim_suffix(".png"), ".tscn"),
			"texture_path": str("res://Assets/Visuals/BrickTextures/BaseTypes/", filename.trim_suffix(".import")),
			"polygon_path": str("res://Scenes/Game/Components/Polygons/", filename.trim_suffix(".import").trim_suffix(".png"), ".tscn"),
			# "color_count": int(dir_num)
		};
		self.add_child(brick_rect);	
		brick_rect.set_active_res.connect(set_active_res);

func set_active_res(res):
	set_active_res_signal.emit(res);

func _on_root_control_sort_children():
	for brick_rect:EditorBrickSample in self.get_children():
		brick_rect.texture_rect.custom_minimum_size.x = self.size.x / self.columns;
