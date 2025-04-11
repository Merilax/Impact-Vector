extends GridContainer

var BrickRect = preload("uid://c47txkxxgap4t");
var BrickScene = preload("uid://dtkn1xk6stg0v");

signal set_active_res_signal(res:Dictionary);

func _ready() -> void:
	var file_array:PackedStringArray = DirAccess.get_files_at("res://Assets/Visuals/BrickTextures/BaseTypes/");
	var filtered_array:Array = Array(file_array.duplicate()).filter(func(string): return string.containsn(".import")); # There's no duplicates without .import

	for filename:String in filtered_array:
		var brick_rect:EditorBrickSample = BrickRect.instantiate();
		brick_rect.texture_rect.texture = load("res://Assets/Visuals/BrickTextures/BaseTypes/" + filename.trim_suffix(".import"));
		
		var hitbox:PackedScene = load("res://Scenes/Game/Components/Hitboxes/" + filename.trim_suffix(".import").trim_suffix(".png") + ".tscn");
		var polygon:PackedScene = load("res://Scenes/Game/Components/Polygons/" + filename.trim_suffix(".import").trim_suffix(".png") + ".tscn");
		var temp_hitbox = hitbox.instantiate();
		var texture_type = temp_hitbox.get_meta("texture_type");
		temp_hitbox.queue_free();
		
		brick_rect.resource = {
			"hitbox": hitbox,
			"polygon": polygon,
			"texture_uid": ResourceLoader.get_resource_uid("res://Assets/Visuals/BrickTextures/BaseTypes/" + filename.trim_suffix(".import")),
			"texture_type": texture_type
		};
		self.add_child(brick_rect);	
		brick_rect.set_active_res.connect(set_active_res);

func set_active_res(res_path):
	set_active_res_signal.emit(res_path);

func _on_root_control_sort_children():
	for brick_rect:EditorBrickSample in self.get_children():
		brick_rect.texture_rect.custom_minimum_size.x = self.size.x / self.columns;
