extends Node
class_name FileManager

static func add_level(campaign_num:String, level:PackedScene, level_data:LevelData, replace_existing:bool = false, level_num:String = "1") -> bool:
	CampaignManager.check_integrity();

	var path:String = "user://Levels/" + campaign_num + "/";
	if not DirAccess.dir_exists_absolute(path): return false;

	if replace_existing:
		return replace_level(path + level_num + "/", level, level_data);

	var dirs = DirAccess.get_directories_at(path);
	if dirs.size() != 0:
		level_num = str(dirs[dirs.size() - 1].to_int() + 1);

	var new_dir = path + level_num + "/";
	DirAccess.make_dir_absolute(new_dir);

	var err := ResourceSaver.save(level, new_dir + "level.tscn");
	if err != OK:
		print("Level Scene save error: " + error_string(err));
		ResourceSaver.save(level, new_dir + "level.tscn");
	err = ResourceSaver.save(level_data, new_dir + "data.tres");
	if err != OK:
		print("Level data save error: " + error_string(err));
		ResourceSaver.save(level_data, new_dir + "data.tres");

	return true;

static func replace_level(path:String, level:PackedScene, level_data:LevelData) -> bool:
	if not DirAccess.dir_exists_absolute(path): return false;
	if not FileAccess.file_exists(path + "level.tscn"): return false;
	if not FileAccess.file_exists(path + "data.tres"): return false;

	var err := ResourceSaver.save(level, path + "level.tscn");
	if err != OK:
		print("Level Scene save error: " + error_string(err));
		ResourceSaver.save(level, path + "level.tscn");
	err = ResourceSaver.save(level_data, path + "data.tres");
	if err != OK:
		print("Level data save error: " + error_string(err));
		ResourceSaver.save(level_data, path + "data.tres");

	return true;

static func import_any(from:String, campaign_num:String = "") -> bool:
	if from.substr(from.length()-1) != '/': from += '/';

	if CampaignManager.validate_campaign(from): import_campaign(from);
	elif CampaignManager.validate_level(from): import_level(from, campaign_num);
	else: return false;

	return true;

static func import_level(from:String, campaign_num:String, level_num:String = "1") -> bool:
	CampaignManager.check_integrity();
	if from.substr(from.length()-1) != '/': from += '/';

	var dirs:PackedStringArray = DirAccess.get_directories_at("user://Levels/" + campaign_num);
	if dirs.size() > 0:
		level_num = str(dirs[dirs.size() - 1].to_int() + 1);

	var to_path:String = "user://Levels/" + campaign_num + "/" + level_num + "/";

	if not CampaignManager.validate_level(from): return false;
	if DirAccess.make_dir_absolute(to_path) != OK: return false;

	DirAccess.copy_absolute(from + "level.tscn", to_path + "level.tscn");
	DirAccess.copy_absolute(from + "data.tres", to_path + "data.tres");

	return true;

static func export_level(from:String, to:String) -> bool:
	CampaignManager.check_integrity();
	if from.substr(from.length()-1) != '/': from += '/';
	if to.substr(to.length()-1) != '/': to += '/';

	if not DirAccess.dir_exists_absolute(from): return false;
	if not FileAccess.file_exists(from + "level.tscn"): return false;
	if not FileAccess.file_exists(from + "data.tres"): return false;

	if not DirAccess.dir_exists_absolute(to): return false;

	var data:LevelData = load(from + "data.tres");
	var foldername:String = data.name.validate_filename() + ' ' + str(randi() % 99999999 + 1); # Purely to reduce the chance of two filenames being the same, should the user not clean up afterwards.
	var to_copy:String = to + "/" + foldername + "/";
	if DirAccess.make_dir_absolute(to_copy) != OK: return false;
	DirAccess.copy_absolute(from + "level.tscn", to_copy + "level.tscn");
	DirAccess.copy_absolute(from + "data.tres", to_copy + "data.tres");

	return true;

static func import_campaign(from:String) -> bool:
	CampaignManager.check_integrity();
	if from.substr(from.length()-1) != '/': from += '/';
	var data:String = FileAccess.get_file_as_string(from + "campaign.json");
	var campaign:Dictionary = JSON.parse_string(data);

	if not campaign or campaign.size() == 0 or not campaign.name or campaign.name.is_empty(): return false;

	var campaign_num:int = CampaignManager.add_campaign(campaign.name);
	var i:int = 1;
	for level_path:String in DirAccess.get_directories_at(from):
		import_level(from + level_path, str(campaign_num), str(i));
		i+=1;

	return true;

static func export_campaign(to:String, from:String) -> bool:
	CampaignManager.check_integrity();
	if from.substr(from.length()-1) != '/': from += '/';
	if to.substr(to.length()-1) != '/': to += '/';

	var file:String = FileAccess.get_file_as_string("user://Levels/campaigns.json");
	var campaigns:Dictionary = JSON.parse_string(file);
	var regex = RegEx.new();
	regex.compile("(\\w|\\d|://)+");
	var temp:Array[RegExMatch] = regex.search_all(from);
	var campaign_num:String = temp[temp.size() - 1].get_string();
	var data = campaigns[campaign_num];

	var foldername:String = data.name.validate_filename() + ' ' + str(randi() % 99999999 + 1); # Purely to reduce the chance of two filenames being the same, should the user not clean up afterwards.
	if DirAccess.make_dir_absolute(to + foldername) != OK: return false;
	var to_copy:String = to + foldername + "/";
	var writer:FileAccess = FileAccess.open(to_copy + "campaign.json", FileAccess.WRITE);
	writer.store_line(JSON.stringify({"name": data.name}));
	writer.close();

	var i:int = 1;
	for level_path in DirAccess.get_directories_at(from):
		DirAccess.make_dir_absolute(to_copy + str(i));
		DirAccess.copy_absolute(from + level_path + "/level.tscn", to_copy + str(i) + "/level.tscn");
		DirAccess.copy_absolute(from + level_path + "/data.tres", to_copy + str(i) + "/data.tres");
		i += 1;

	return true;
