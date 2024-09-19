extends GridContainer

var LevelBox = preload("res://Scenes/UI/LevelBox.tscn")

signal play_level(dir:String)
signal edit_level(dir:String)

func _ready() -> void:
	var dir:DirAccess = DirAccess.open("user://Levels/Standard")
	
	if not dir:
		DirAccess.make_dir_absolute("user://Levels")
		DirAccess.make_dir_absolute("user://Levels/Standard")
		dir = DirAccess.open("user://Levels/Standard")
 
	for folder_num:String in dir.get_directories():
		var level_data:LevelData = load("user://Levels/Standard/" + folder_num + "/data.tres")

		var level_box:MarginContainer = LevelBox.instantiate()
		level_box.get_node("LevelBox/LevelName").text = level_data.name
		#var thumb = Image.load_from_file(level_data.dir + "data.tres")
		level_box.get_node("LevelBox/Thumbnail").texture = level_data.thumbnail
		level_box.set_meta("level_dir", level_data.dir)
		add_child(level_box)

		level_box.play_level.connect(_on_play_level)
		level_box.edit_level.connect(_on_edit_level)

func _on_play_level(dir:String) -> void:
	play_level.emit(dir)

func _on_edit_level(dir:String) -> void:
	edit_level.emit(dir)