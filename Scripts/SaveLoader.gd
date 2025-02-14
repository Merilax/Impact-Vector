class_name SaveLoader
extends Node

static func load_settings() -> SaveSettings:
	if not FileAccess.file_exists("user://SaveSettings.tres"):
		print("No settings, creating blank save.");
		save_settings();
	var settings:SaveSettings = load("user://SaveSettings.tres");
	
	var incomplete_config:bool = false

	# VIDEO
	if settings.vsync != null:
		if DisplayServer.window_get_vsync_mode() != settings.vsync: DisplayServer.window_set_vsync_mode(settings.vsync);
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		incomplete_config = true
		settings.vsync = 0

	# AUDIO
	if settings.master_volume != null:
		AudioServer.set_bus_volume_db(0, settings.master_volume)
		if settings.master_volume <= -30:
			AudioServer.set_bus_mute(0, true)
	else:
		incomplete_config = true
		settings.master_volume = 0

	if settings.music_volume != null:
		AudioServer.set_bus_volume_db(1, settings.music_volume)
		if settings.music_volume <= -30:
			AudioServer.set_bus_mute(1, true)
	else:
		incomplete_config = true
		settings.music_volume = 0

	if settings.sfx_volume != null:
		AudioServer.set_bus_volume_db(2, settings.sfx_volume)
		if settings.sfx_volume <= -30:
			AudioServer.set_bus_mute(2, true)
	else:
		incomplete_config = true
		settings.sfx_volume = 0

	if incomplete_config:
		print("Broken settings, resaving.")
		save_settings()
	
	return settings

static func save_settings() -> bool:
	var settings:SaveSettings = SaveSettings.new()

	settings.vsync = DisplayServer.window_get_vsync_mode()

	settings.master_volume = AudioServer.get_bus_volume_db(0)
	settings.music_volume = AudioServer.get_bus_volume_db(1)
	settings.sfx_volume = AudioServer.get_bus_volume_db(2)

	ResourceSaver.save(settings, "user://SaveSettings.tres")
	return true

static func load_gamedata() -> SaveGameData:
	var game_data:SaveGameData = load("user://SaveGameData.tres")

	return game_data

static func save_gamedata(data_node) -> bool:
	var save_game_data:SaveGameData = SaveGameData.new()
	
	save_game_data.score = data_node.score
	save_game_data.lives = data_node.lives
	save_game_data.total_lives = data_node.total_lives
	save_game_data.level_path = data_node.level_dir

	ResourceSaver.save(save_game_data, "user://SaveGameData.tres")
	return true