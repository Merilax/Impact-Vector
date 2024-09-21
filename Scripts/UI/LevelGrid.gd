extends GridContainer

var LevelBox = preload("res://Scenes/UI/LevelBox.tscn")

signal play_level(folder_num:String)
signal edit_level(folder_num:String)

func _ready() -> void:
	var dir:DirAccess = DirAccess.open("user://Levels/Default")
	if not dir:
		DirAccess.make_dir_absolute("user://Levels")
		DirAccess.make_dir_absolute("user://Levels/Default")
	if not FileAccess.file_exists("user://Levels/Default/campaign.json"):
		CampaignManager.create_campaign("user://Levels/Default", "Default")

	var campaign:Dictionary = CampaignManager.load_campaign_data("user://Levels/Default/campaign.json")

	for folder_num:String in campaign.levels:
		var level_data:LevelData = load("user://Levels/Default/" + folder_num + "/data.tres")

		var level_box:MarginContainer = LevelBox.instantiate()
		level_box.get_node("LevelBox/LevelName").text = level_data.name
		level_box.get_node("LevelBox/Thumbnail").texture = level_data.thumbnail
		level_box.set_meta("folder_num", folder_num)
		add_child(level_box)

		level_box.play_level.connect(_on_play_level)
		level_box.edit_level.connect(_on_edit_level)

func _on_play_level(folder_num:String) -> void:
	play_level.emit(folder_num)

func _on_edit_level(folder_num:String) -> void:
	edit_level.emit(folder_num)
