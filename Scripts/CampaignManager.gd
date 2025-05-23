class_name CampaignManager
extends Object

static func check_integrity():
	Logger.write(str("Checking integrity."), "CampaignManager");
	if not DirAccess.dir_exists_absolute("user://Levels/"):
		DirAccess.make_dir_absolute("user://Levels/");
	
	var file:FileAccess = FileAccess.open("user://Levels/campaigns.json", FileAccess.READ);
	if not file:
		var writer:FileAccess = FileAccess.open("user://Levels/campaigns.json", FileAccess.WRITE);

		var campaigns:Dictionary = {};
		for dir_name:String in DirAccess.get_directories_at("user://Levels/"):
			campaigns[dir_name] = {"name": "Unnamed " + dir_name};

		writer.store_line(JSON.stringify(campaigns));
		writer.close();

static func find_next_level(campaign_path:String, level_num:int) -> int:
	for dir_name:String in DirAccess.get_directories_at(campaign_path):
		if dir_name.to_int() > level_num:
			return dir_name.to_int();
	return 0; 

static func validate_campaign(path:String) -> bool:
	Logger.write(str("Validating campaign."), "CampaignManager");
	if not path.contains(".ivc"): return false;

	var zip:ZIPReader = ZIPReader.new();
	var ok:int = zip.open(path);
	if ok != OK:
		Logger.write(str("Couldn't open ZIP: ", error_string(ok)), "CampaignManager");
		return false;

	if not zip.file_exists("campaign.json"): return false;

	var data:String = zip.read_file("campaign.json").get_string_from_utf8();
	var campaign:Dictionary = JSON.parse_string(data);

	zip.close();
	if not campaign or campaign.size() == 0 or not campaign.name or campaign.name.is_empty(): return false;
	Logger.write(str("Campaign is valid."), "CampaignManager");
	return true;

static func validate_level(path:String) -> bool:
	Logger.write(str("Validating level."), "CampaignManager");
	if not path.contains(".ivl"): return false;

	var zip:ZIPReader = ZIPReader.new();
	var ok:int = zip.open(path);
	if ok != OK:
		Logger.write(str("Couldn't open ZIP: ", error_string(ok)), "CampaignManager");
		return false;

	if not zip.file_exists("level.json"): return false;
	if not zip.file_exists("data.tres"): return false;
	zip.close();

	Logger.write(str("Level is valid."), "CampaignManager");
	return true;

static func add_campaign(name:String) -> int:
	Logger.write(str("Adding campaign ", name), "CampaignManager");
	check_integrity();
	var dir_name:int = 1;

	var file:String = FileAccess.get_file_as_string("user://Levels/campaigns.json");
	var campaigns:Dictionary = JSON.parse_string(file);

	var dirs:PackedStringArray = DirAccess.open("user://Levels/").get_directories();
	if dirs.size() > 0:
		dir_name = dirs[dirs.size() - 1].to_int() + 1;

	DirAccess.make_dir_absolute("user://Levels/" + str(dir_name));
	var campaign_num:String = str(dir_name);
	campaigns[campaign_num] = {"name": name};

	var writer:FileAccess = FileAccess.open("user://Levels/campaigns.json", FileAccess.WRITE);
	writer.store_line(JSON.stringify(campaigns));
	writer.close();

	return dir_name;

static func rename_campaign(dir_num:String, new_name:String):
	Logger.write(str("Renaming campaign ", dir_num, " to ", new_name), "CampaignManager");
	check_integrity();
	var file:String = FileAccess.get_file_as_string("user://Levels/campaigns.json");
	var campaigns:Dictionary = JSON.parse_string(file);

	campaigns[dir_num].name = new_name;

	var writer:FileAccess = FileAccess.open("user://Levels/campaigns.json", FileAccess.WRITE);
	writer.store_line(JSON.stringify(campaigns));
	writer.close();

static func remove_campaign(dir_num:String):
	Logger.write(str("Removing campaign ", dir_num), "CampaignManager");
	check_integrity();
	DirAccess.remove_absolute("user://Levels/" + dir_num);

	var file:String = FileAccess.get_file_as_string("user://Levels/campaigns.json");
	var campaigns:Dictionary = JSON.parse_string(file);

	campaigns.erase(dir_num);

	var writer:FileAccess = FileAccess.open("user://Levels/campaigns.json", FileAccess.WRITE);
	writer.store_line(JSON.stringify(campaigns));
	writer.close();