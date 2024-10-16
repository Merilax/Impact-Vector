extends GridContainer

var BrickRect = preload("res://Scenes/UI/Components/BrickSample.tscn")

signal set_active_res_signal(texture_path:String)

func _ready() -> void:
	#var file_array:PackedStringArray = DirAccess.get_files_at("res://Scenes/Game/Bricks/")
	#var filtered_array:Array = Array(file_array.duplicate()).filter(func(string): return not string.containsn(".import"))
	var file_array:PackedStringArray = DirAccess.get_files_at("res://Assets/Visuals/BrickTextures/BaseTypes/")
	var filtered_array:Array = Array(file_array.duplicate()).filter(func(string): return string.containsn(".import")) # There's no duplicates without .import

	for FilePath:String in filtered_array:
		var brick_rect:EditorBrickSample = BrickRect.instantiate()
		brick_rect.resource_path = "res://Assets/Visuals/BrickTextures/BaseTypes/" + FilePath.trim_suffix(".import")
		brick_rect.texture_rect.texture = load("res://Assets/Visuals/BrickTextures/BaseTypes/" + FilePath.trim_suffix(".import"))

		add_child(brick_rect)
		brick_rect.set_active_res.connect(set_active_res)

func set_active_res(res_path):
	set_active_res_signal.emit(res_path)
