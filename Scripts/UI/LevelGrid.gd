extends GridContainer

var LevelBoxScene = preload("uid://ct3pryubbc463")

signal play_level(folder_num:String)
signal edit_level(folder_num:String)
signal delete_level(folder_num:String, origin:Control)

func on_select_campaign(campaign_path:String, campaign_num:String):
	for child:Node in get_children():
		child.queue_free()

	var dir:DirAccess = DirAccess.open(campaign_path + "/" + campaign_num)
	
	for folder_num:String in dir.get_directories():
		var level_data:LevelData = load(campaign_path + "/" + campaign_num + "/" + folder_num + "/data.tres")

		var level_box:LevelBox = LevelBoxScene.instantiate()
		level_box.get_node("LevelBox/LevelName").text = level_data.name
		level_box.get_node("LevelBox/Thumbnail").texture = level_data.thumbnail
		level_box.set_meta("folder_num", folder_num)
		add_child(level_box)

		if campaign_path.contains("res://"):
			level_box.edit_button.hide()
			level_box.delete_button.hide()
		
		level_box.play_level.connect(_on_play_level)
		level_box.edit_level.connect(_on_edit_level)
		level_box.delete_level.connect(_on_delete_level)

func _on_play_level(folder_num:String) -> void:
	play_level.emit(folder_num)

func _on_edit_level(folder_num:String) -> void:
	edit_level.emit(folder_num)

func _on_delete_level(folder_num:String, origin:Control) -> void:
	delete_level.emit(folder_num, origin)
