extends Node
class_name FileManager

static func clear_temp(folder:String = ""):
	Logger.write("Clearing temporary folder.", "FileManager");

	if folder == "res://": return;
	if folder == "user://": return;
	if folder == "user://Levels": return;
	if not DirAccess.dir_exists_absolute(folder): return;
	# Clear all files
	for file in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder + "/" + file);

	# Continue deeper into the folder tree.
	for subfolder:String in DirAccess.get_directories_at(folder):
		clear_temp(folder + '/' + subfolder);

	DirAccess.remove_absolute(folder);

static func add_level(campaign_num:String, level:PackedScene, level_data:LevelData, replace_existing:bool = false, level_num:String = "1") -> bool:
	Logger.write("Adding level " + level_num + " to campaign " + campaign_num + ", replace " + str(replace_existing), "FileManager");
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
		Logger.write("Level Scene save error." + error_string(err), "FileManager");
		return false;
	err = ResourceSaver.save(level_data, new_dir + "data.tres");
	if err != OK:
		Logger.write("Level data save error." + error_string(err), "FileManager");
		return false;

	return true;

static func replace_level(path:String, level:PackedScene, level_data:LevelData) -> bool:
	Logger.write("Replacing level at " + path, "FileManager");
	if not DirAccess.dir_exists_absolute(path): return false;
	if not FileAccess.file_exists(path + "level.tscn"): return false;
	if not FileAccess.file_exists(path + "data.tres"): return false;

	var err := ResourceSaver.save(level, path + "level.tscn");
	if err != OK:
		Logger.write("Level Scene save error: " + error_string(err), "FileManager");
		return false;
	err = ResourceSaver.save(level_data, path + "data.tres");
	if err != OK:
		Logger.write("Level data save error: " + error_string(err), "FileManager");
		return false;

	return true;

static func import_any(from:String, campaign_num:String = "") -> bool:
	if CampaignManager.validate_campaign(from): import_campaign(from);
	elif CampaignManager.validate_level(from): import_level(from, campaign_num);
	else: return false;

	return true;

static func import_level(from:String, campaign_num:String, level_num:String = "1", clear_temp_after:bool = true, extract:bool = true) -> bool:
	Logger.write(str("Importing level from ", from, ", campaign ", campaign_num, ", level ", level_num), "FileManager");
	CampaignManager.check_integrity();
	if clear_temp_after:
		clear_temp("user://Temp/");
		DirAccess.make_dir_absolute("user://Temp/");
	
	if extract:
		var writer:FileAccess;
		var zip:ZIPReader = ZIPReader.new();
		if not CampaignManager.validate_level(from): return false;
		var ok = zip.open(from);
		if ok != OK:
			Logger.write(str("Couldn't open ZIP: ", error_string(ok)), "FileManager");
			return false;

		var level:PackedByteArray = zip.read_file("level.tscn");
		writer = FileAccess.open("user://Temp/level.tscn", FileAccess.WRITE);
		writer.store_buffer(level);
		writer.close();

		var level_data:PackedByteArray = zip.read_file("data.tres");
		writer = FileAccess.open("user://Temp/data.tres", FileAccess.WRITE);
		writer.store_buffer(level_data);
		writer.close();

		from = "user://Temp/";

	var dirs:PackedStringArray = DirAccess.get_directories_at("user://Levels/" + campaign_num);
	if dirs.size() > 0:
		level_num = str(dirs[dirs.size() - 1].to_int() + 1);

	var to_path:String = "user://Levels/" + campaign_num + "/" + level_num + "/";

	if DirAccess.make_dir_absolute(to_path) != OK: return false;
	DirAccess.copy_absolute(from + "level.tscn", to_path + "level.tscn");
	DirAccess.copy_absolute(from + "data.tres", to_path + "data.tres");

	if clear_temp_after: clear_temp("user://Temp/");
	Logger.write(str("Import OK."), "FileManager");
	return true;

static func export_level(to:String, from:String) -> bool:
	Logger.write(str("Exporting level from ", from), "FileManager");
	CampaignManager.check_integrity();
	if from.substr(from.length()-1) != '/': from += '/';
	if to.substr(to.length()-1) != '/': to += '/';

	if not DirAccess.dir_exists_absolute(from): return false;
	if not FileAccess.file_exists(from + "level.tscn"): return false;
	if not FileAccess.file_exists(from + "data.tres"): return false;

	if not DirAccess.dir_exists_absolute(to): return false;

	var data:LevelData = load(from + "data.tres");
	var foldername:String = data.name.validate_filename() + ' ' + str(randi() % 99999999 + 1); # Purely to reduce the chance of two filenames being the same, should the user not clean up afterwards.
	var to_copy:String = to + "/" + foldername;

	var zip:ZIPPacker = ZIPPacker.new();
	var ok = zip.open(to_copy + ".ivl")
	if ok != OK:
		Logger.write(str("Couldn't open ZIP: ", error_string(ok)), "FileManager");
		return false;
	zip.start_file("level.tscn");
	zip.write_file(FileAccess.get_file_as_bytes(from + "level.tscn"));
	zip.close_file();
	zip.start_file("data.tres");
	zip.write_file(FileAccess.get_file_as_bytes(from + "data.tres"));
	zip.close_file();
	zip.close();

	Logger.write(str("Export OK"), "FileManager");
	return true;

static func import_campaign(from:String) -> bool:
	Logger.write(str("Importing campaign from ", from), "FileManager");
	CampaignManager.check_integrity();
	clear_temp("user://Temp/");
	DirAccess.make_dir_absolute("user://Temp/");
	
	var zip:ZIPReader = ZIPReader.new();
	var ok:int = zip.open(from);
	if ok != OK:
		Logger.write(str("Couldn't open ZIP: ", error_string(ok)), "FileManager");
		return false;
	var data:String = zip.read_file("campaign.json").get_string_from_utf8();
	var campaign:Dictionary = JSON.parse_string(data);

	if not campaign or campaign.size() == 0 or not campaign.name or campaign.name.is_empty(): return false;

	var campaign_num:int = CampaignManager.add_campaign(campaign.name);
	
	for i in range(1, campaign.level_count + 1):
		
		DirAccess.make_dir_absolute("user://Temp/" + str(i));
		var writer:FileAccess;

		var level:PackedByteArray = zip.read_file("Levels/" + str(i) + "/level.tscn");
		writer = FileAccess.open("user://Temp/" + str(i) + "/level.tscn", FileAccess.WRITE);
		writer.store_buffer(level);
		writer.close();

		var level_data:PackedByteArray = zip.read_file("Levels/" + str(i) + "/data.tres");
		writer = FileAccess.open("user://Temp/" + str(i) + "/data.tres", FileAccess.WRITE);
		writer.store_buffer(level_data);
		writer.close();

		if not import_level("user://Temp/" + str(i) + "/", str(campaign_num), str(i), false, false): return false;

	clear_temp("user://Temp/");
	Logger.write(str("Import OK"), "FileManager");
	return true;

static func export_campaign(to:String, from:String) -> bool:
	Logger.write(str("Exporting campaign from ", from), "FileManager");
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
	var to_copy:String = to + foldername;

	var zip:ZIPPacker = ZIPPacker.new();
	var ok:int = zip.open(to_copy + ".ivc");
	if ok != OK:
		Logger.write(str("Couldn't open ZIP: ", error_string(ok)), "FileManager");
		return false;

	var i:int = 1;
	for level_path in DirAccess.get_directories_at(from):
		zip.start_file("Levels/" + str(i) + "/level.tscn");
		zip.write_file(FileAccess.get_file_as_bytes(from + level_path + "/level.tscn"));
		zip.close_file();
		zip.start_file("Levels/" + str(i) + "/data.tres");
		zip.write_file(FileAccess.get_file_as_bytes(from + level_path + "/data.tres"));
		zip.close_file();
		i += 1;
	
	zip.start_file("campaign.json");
	zip.write_file(JSON.stringify({"name": data.name, "level_count": i-1}).to_utf8_buffer());
	zip.close_file();
	zip.close();

	Logger.write(str("Export OK"), "FileManager");
	return true;
