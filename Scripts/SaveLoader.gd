class_name SaveLoader
extends Node

static func load_settings() -> SaveSettings:
	Logger.write("Loading settings.", "SaveLoader");
	var settings:SaveSettings;
	var incomplete_config:bool = false;

	if FileAccess.file_exists("user://SaveSettings.tres"):
		settings = load("user://SaveSettings.tres");
	else:
		Logger.write("No settings, creating blank save.", "SaveLoader");
		settings = SaveSettings.new();
		incomplete_config = true;

	# GAME
	if settings.arm_speed_multiplier != null and settings.arm_speed_multiplier != 0:
		GlobalVars.arm_speed_multiplier = settings.arm_speed_multiplier;
	else:
		settings.arm_speed_multiplier = 1;
		GlobalVars.arm_speed_multiplier = settings.arm_speed_multiplier;
		incomplete_config = true;

	# VIDEO
	if settings.vsync != null:
		if DisplayServer.window_get_vsync_mode() != settings.vsync: DisplayServer.window_set_vsync_mode(settings.vsync);
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED);
		incomplete_config = true;
		settings.vsync = 0;

	# AUDIO
	if settings.master_volume != null:
		AudioServer.set_bus_volume_db(0, settings.master_volume);
		if settings.master_volume <= -30:
			AudioServer.set_bus_mute(0, true);
	else:
		incomplete_config = true;
		settings.master_volume = 0;

	if settings.music_volume != null:
		AudioServer.set_bus_volume_db(1, settings.music_volume);
		if settings.music_volume <= -30:
			AudioServer.set_bus_mute(1, true);
	else:
		incomplete_config = true;
		settings.music_volume = 0;

	if settings.sfx_volume != null:
		AudioServer.set_bus_volume_db(2, settings.sfx_volume);
		if settings.sfx_volume <= -30:
			AudioServer.set_bus_mute(2, true);
	else:
		incomplete_config = true;
		settings.sfx_volume = 0;

	if incomplete_config:
		Logger.write("Broken settings, resaving.", "SaveLoader");
		save_settings();
	
	return settings;

static func save_settings() -> bool:
	Logger.write("Saving settings.", "SaveLoader");
	var settings:SaveSettings = SaveSettings.new();

	settings.arm_speed_multiplier = GlobalVars.arm_speed_multiplier;

	settings.vsync = DisplayServer.window_get_vsync_mode();

	settings.master_volume = AudioServer.get_bus_volume_db(0);
	settings.music_volume = AudioServer.get_bus_volume_db(1);
	settings.sfx_volume = AudioServer.get_bus_volume_db(2);

	ResourceSaver.save(settings, "user://SaveSettings.tres");
	return true;

static func load_gamedata() -> SaveGameData:
	Logger.write("Loading SaveGameData.", "SaveLoader");
	var game_data:SaveGameData = load("user://SaveGameData.tres");

	return game_data;

static func save_gamedata(data_node) -> bool:
	Logger.write("Saving SaveGameData.", "SaveLoader");
	var save_game_data:SaveGameData = SaveGameData.new();
	
	save_game_data.score = data_node.score;
	save_game_data.lives = data_node.lives;
	save_game_data.total_lives = data_node.total_lives;
	save_game_data.level_path = data_node.level_dir;

	ResourceSaver.save(save_game_data, "user://SaveGameData.tres");
	return true;