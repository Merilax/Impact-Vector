class_name SaveLoader
extends Node

func _ready():
	load_settings()

func load_settings() -> SaveSettings:
	return _on_load_settings()

func save_settings() -> SaveSettings:
	return _on_save_settings()

func load_gamedata():
	_on_load_gamedata()

func save_gamedata():
	_on_save_gamedata()

func _on_save_settings() -> SaveSettings:
	var settings:SaveSettings = SaveSettings.new()

	settings.vsync = DisplayServer.window_get_vsync_mode()

	settings.master_volume = AudioServer.get_bus_volume_db(0)
	settings.music_volume = AudioServer.get_bus_volume_db(1)
	settings.sfx_volume = AudioServer.get_bus_volume_db(2)

	ResourceSaver.save(settings, "user://SaveSettings.tres")
	return settings

func _on_load_settings() -> SaveSettings:
	var settings:SaveSettings = load("user://SaveSettings.tres")
	if not settings:
		print("No settings")
		save_settings()
	
	var incomplete_config:bool = false

	# VIDEO
	if settings.vsync != null:
		DisplayServer.window_set_vsync_mode(settings.vsync)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		incomplete_config = true

	# AUDIO
	if settings.master_volume != null:
		AudioServer.set_bus_volume_db(0, settings.master_volume)
		if settings.master_volume <= -30:
			AudioServer.set_bus_mute(0, true)
	else: incomplete_config = true

	if settings.music_volume != null:
		AudioServer.set_bus_volume_db(1, settings.music_volume)
		if settings.music_volume <= -30:
			AudioServer.set_bus_mute(1, true)
	else: incomplete_config = true

	if settings.sfx_volume != null:
		AudioServer.set_bus_volume_db(2, settings.sfx_volume)
		if settings.sfx_volume <= -30:
			AudioServer.set_bus_mute(2, true)
	else: incomplete_config = true

	if incomplete_config:
		print("Broken settings")
		settings = save_settings()
	
	return settings

func _on_save_gamedata():
	var save_game_data:SaveGameData = SaveGameData.new()
	var game_data:Array = []
	get_tree().call_group("SaveData", "on_save", game_data)

	save_game_data.save_data = game_data
	ResourceSaver.save(save_game_data, "user://SaveGameData.tres")

func _on_load_gamedata():
	get_tree().call_group("SaveData", "on_before_load")
	
	#TODO Loader loop
