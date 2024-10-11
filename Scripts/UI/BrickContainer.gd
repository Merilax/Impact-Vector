extends GridContainer

var BrickRect = preload("res://Scenes/UI/Components/BrickSample.tscn")

signal set_active_res_signal(brick_scene:PackedScene)

func _ready() -> void:
	var file_array:PackedStringArray = DirAccess.get_files_at("res://Scenes/Game/Bricks/")
	var filtered_array:Array = Array(file_array.duplicate()).filter(func(string): return not string.containsn(".import"))

	for FilePath:String in filtered_array:
		var brick_rect:EditorBrickSample = BrickRect.instantiate()
		brick_rect.resource_path = "res://Scenes/Game/Bricks/" + FilePath
		brick_rect.texture_rect.texture = load("res://Assets/Visuals/BrickTextures/BaseTypes/" + FilePath.trim_suffix(".remap").trim_suffix(".tscn") + ".png")

		add_child(brick_rect)
		brick_rect.set_active_res.connect(set_active_res)

func set_active_res(res):
	set_active_res_signal.emit(res)
