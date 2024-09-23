class_name CampaignManager
extends Object

static func create_campaign(folderpath, name):
	var dict:Dictionary = {"name": name, "levels": []}
	var json = JSON.stringify(dict)
	var writer:FileAccess = FileAccess.open(folderpath + "/campaign.json", FileAccess.WRITE)
	writer.store_line(json)
	writer.close()

static func load_campaign_data(json_path) -> Dictionary:
	var json_file = FileAccess.get_file_as_string(json_path)
	var dict:Dictionary = JSON.parse_string(json_file)
	
	# Sanitize removed levels
	var aux:Array = []
	for level_num in dict.levels:
		if not FileAccess.file_exists("user://Levels/" + dict.name + "/" + str(level_num) + "/level.tscn"):
			aux.append(level_num)
	for i in aux.size():
		dict.levels.erase(aux[i])
	
	var writer:FileAccess = FileAccess.open(json_path, FileAccess.WRITE)
	writer.store_line(JSON.stringify(dict))
	writer.close()

	return dict

static func add_campaign_level(json_path:String, folder_number:String):
	var dict:Dictionary = {"name": "Default", "levels": []}

	if FileAccess.file_exists(json_path):
		var json_file:String = FileAccess.get_file_as_string(json_path)
		dict = JSON.parse_string(json_file)

	dict.levels.append(folder_number)

	var json = JSON.stringify(dict)
	var writer:FileAccess = FileAccess.open(json_path, FileAccess.WRITE)
	writer.store_line(json)
	writer.close()

static func remove_campaign_level(json_path:String, folder_number:String) -> bool:
	if not FileAccess.file_exists(json_path): return false

	var json_file:String = FileAccess.get_file_as_string(json_path)
	var dict:Dictionary = JSON.parse_string(json_file)

	dict.levels.erase(folder_number)

	var json = JSON.stringify(dict)
	var writer:FileAccess = FileAccess.open(json_path, FileAccess.WRITE)
	writer.store_line(json)
	writer.close()

	return true