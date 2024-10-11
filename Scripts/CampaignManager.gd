class_name CampaignManager
extends Object

static func check_integrity():
	var dir:DirAccess = DirAccess.open("user://Levels/")
	if not dir:
		DirAccess.make_dir_absolute("user://Levels/")
		dir = DirAccess.open("user://Levels/")
	
	var file:FileAccess = FileAccess.open("user://Levels/campaigns.json", FileAccess.READ)
	if not file:
		var writer:FileAccess = FileAccess.open("user://Levels/campaigns.json", FileAccess.WRITE)

		var campaigns:Array = []
		for dir_name in dir.get_directories():
			var campaign:Dictionary = {"dir": dir_name, "name": "Unnamed " + dir_name}
			campaigns.append(campaign)

		writer.store_line(JSON.stringify(campaigns))
		writer.close()

static func add_campaign(name:String):
	check_integrity()
	var dir_name:int = 1

	var file:String = FileAccess.get_file_as_string("user://Levels/campaigns.json")
	var campaigns:Array = JSON.parse_string(file)

	var dirs:PackedStringArray = DirAccess.open("user://Levels/").get_directories()
	if dirs.size() > 0:
		dir_name = dirs[dirs.size() - 1].to_int() + 1

	DirAccess.make_dir_absolute("user://Levels/" + str(dir_name))
	campaigns.append({"dir": str(dir_name), "name": name})

	var writer:FileAccess = FileAccess.open("user://Levels/campaigns.json", FileAccess.WRITE)
	writer.store_line(JSON.stringify(campaigns))
	writer.close()

static func rename_campaign(dir_num:String, new_name:String):
	check_integrity()
	var file:String = FileAccess.get_file_as_string("user://Levels/campaigns.json")
	var campaigns:Array = JSON.parse_string(file)

	var found:Array = campaigns.filter(func(campaign:Dictionary): return campaign.dir == dir_num)
	if found.size():
		var idx:int = campaigns.find(found[0])
		if idx >= 0:
			campaigns[idx].name = new_name

			var writer:FileAccess = FileAccess.open("user://Levels/campaigns.json", FileAccess.WRITE)
			writer.store_line(JSON.stringify(campaigns))
			writer.close()

static func remove_campaign(dir_num:String):
	check_integrity()
	DirAccess.remove_absolute("user://Levels/" + dir_num)

	var file:String = FileAccess.get_file_as_string("user://Levels/campaigns.json")
	var campaigns:Array = JSON.parse_string(file)

	var found:Array = campaigns.filter(func(campaign:Dictionary): return campaign.dir == dir_num)
	if found.size():
		var idx:int = campaigns.find(found[0])
		if idx >= 0:
			campaigns.remove_at(idx)

			var writer:FileAccess = FileAccess.open("user://Levels/campaigns.json", FileAccess.WRITE)
			writer.store_line(JSON.stringify(campaigns))
			writer.close()
