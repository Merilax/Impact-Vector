class_name CampaignManager
extends Object

const BASE_DIR := "res://Levels/";
const USER_DIR := "user://Levels/";

static func check_integrity(custom:bool = false):
	if custom:
		check_custom_integrity();
	else:
		check_base_integrity();

static func check_custom_integrity():
	LoggerFile.write(str("Checking integrity."), "CampaignManager");
	if not DirAccess.dir_exists_absolute(USER_DIR):
		DirAccess.make_dir_absolute(USER_DIR);
	
	var file:FileAccess = FileAccess.open(USER_DIR +"campaigns.json", FileAccess.READ);
	if not file:
		var writer:FileAccess = FileAccess.open(USER_DIR + "campaigns.json", FileAccess.WRITE);

		var campaigns:Dictionary = {};
		for dir_name:String in DirAccess.get_directories_at(USER_DIR):
			campaigns[dir_name] = {"name": "Unnamed " + dir_name};

		writer.store_line(JSON.stringify(campaigns));
		writer.close();

static func check_base_integrity():
	var dir:DirAccess = DirAccess.open(BASE_DIR);
	if not dir:
		DirAccess.make_dir_absolute(BASE_DIR);
		dir = DirAccess.open(BASE_DIR);
	
	var file:FileAccess = FileAccess.open(BASE_DIR + "campaigns.json", FileAccess.READ);
	if not file:
		var writer:FileAccess = FileAccess.open(BASE_DIR + "campaigns.json", FileAccess.WRITE);

		var campaigns:Array = [];
		for dir_name in dir.get_directories():
			var campaign:Dictionary = {"dir": dir_name, "name": "Unnamed " + dir_name};
			campaigns.append(campaign);

		writer.store_line(JSON.stringify(campaigns));
		writer.close();

static func find_next_level(campaign_path:String, level_num:int) -> int:
	for dir_name:String in DirAccess.get_directories_at(campaign_path):
		if dir_name.to_int() > level_num:
			return dir_name.to_int();
	return 0; 

static func validate_campaign(path:String) -> bool:
	LoggerFile.write(str("Validating campaign."), "CampaignManager");
	if not path.contains(".ivc"): return false;

	var zip:ZIPReader = ZIPReader.new();
	var ok:int = zip.open(path);
	if ok != OK:
		LoggerFile.write(str("Couldn't open ZIP: ", error_string(ok)), "CampaignManager");
		return false;

	if not zip.file_exists("campaign.json"): return false;

	var data:String = zip.read_file("campaign.json").get_string_from_utf8();
	var campaign:Dictionary = JSON.parse_string(data);

	zip.close();
	if not campaign or campaign.size() == 0 or not campaign.name or campaign.name.is_empty(): return false;
	LoggerFile.write(str("Campaign is valid."), "CampaignManager");
	return true;

static func validate_level(path:String) -> bool:
	LoggerFile.write(str("Validating level."), "CampaignManager");
	if not path.contains(".ivl"): return false;

	var zip:ZIPReader = ZIPReader.new();
	var ok:int = zip.open(path);
	if ok != OK:
		LoggerFile.write(str("Couldn't open ZIP: ", error_string(ok)), "CampaignManager");
		return false;

	if not zip.file_exists("level.json"): return false;
	if not zip.file_exists("data.tres"): return false;
	zip.close();

	LoggerFile.write(str("Level is valid."), "CampaignManager");
	return true;

static func add_campaign(name:String) -> int:
	LoggerFile.write(str("Adding campaign ", name), "CampaignManager");
	check_custom_integrity();
	var dir_name:int = 1;

	var file:String = FileAccess.get_file_as_string(USER_DIR + "campaigns.json");
	var campaigns:Dictionary = JSON.parse_string(file);

	var dirs:PackedStringArray = DirAccess.open(USER_DIR).get_directories();
	if dirs.size() > 0:
		dir_name = dirs[dirs.size() - 1].to_int() + 1;

	DirAccess.make_dir_absolute(USER_DIR + str(dir_name));
	var campaign_num:String = str(dir_name);
	campaigns[campaign_num] = {"name": name};

	var writer:FileAccess = FileAccess.open(USER_DIR + "campaigns.json", FileAccess.WRITE);
	writer.store_line(JSON.stringify(campaigns));
	writer.close();

	return dir_name;

static func rename_campaign(dir_num:String, new_name:String):
	LoggerFile.write(str("Renaming campaign ", dir_num, " to ", new_name), "CampaignManager");
	check_custom_integrity();
	var file:String = FileAccess.get_file_as_string(USER_DIR + "campaigns.json");
	var campaigns:Dictionary = JSON.parse_string(file);

	campaigns[dir_num].name = new_name;

	var writer:FileAccess = FileAccess.open(USER_DIR + "campaigns.json", FileAccess.WRITE);
	writer.store_line(JSON.stringify(campaigns));
	writer.close();

static func remove_campaign(dir_num:String):
	check_custom_integrity();

	LoggerFile.write(str("Removing campaign: ", dir_num), "CampaignManager");

	for sub_dir in DirAccess.get_directories_at(USER_DIR + dir_num):
		DirAccess.remove_absolute(USER_DIR + dir_num + "/" + sub_dir + "/level.json");
		DirAccess.remove_absolute(USER_DIR + dir_num + "/" + sub_dir + "/data.tres");
		DirAccess.remove_absolute(USER_DIR + dir_num + "/" + sub_dir);

	DirAccess.remove_absolute(USER_DIR + dir_num);

	var file:String = FileAccess.get_file_as_string(USER_DIR + "campaigns.json");
	var campaigns_dict:Dictionary = JSON.parse_string(file);

	campaigns_dict.erase(dir_num);

	var writer:FileAccess = FileAccess.open(USER_DIR + "campaigns.json", FileAccess.WRITE);
	writer.store_line(JSON.stringify(campaigns_dict));
	writer.close();

static func remove_level(campaing_num:String, level_num:String):
	LoggerFile.write("Deleting level " + level_num + " from campaign " + campaing_num, "CampaignManager");
	
	DirAccess.remove_absolute(USER_DIR + campaing_num + "/" + level_num + "/level.json");
	DirAccess.remove_absolute(USER_DIR + campaing_num + "/" + level_num + "/data.tres");
	DirAccess.remove_absolute(USER_DIR + campaing_num + "/" + level_num);