extends Control

@export var window_mode_setting:OptionButton
@export var resolution_setting:OptionButton
@export var borderless_setting:CheckButton
@export var vsync_setting:CheckButton # Creates major mouse delay

@export var master_volume_setting:HBoxContainer
@export var music_volume_setting:HBoxContainer
@export var sfx_volume_setting:HBoxContainer

@export var save_button:Button

signal menu_closed()

func _ready():
	if window_mode_setting:
		window_mode_setting.item_selected.connect(set_window_mode)
	if borderless_setting:
		borderless_setting.toggled.connect(set_borderless)
	if resolution_setting:
		resolution_setting.item_selected.connect(set_resolution)
	if vsync_setting:
		vsync_setting.toggled.connect(set_vsync)

	if master_volume_setting:
		master_volume_setting.value_changed.connect(on_set_audio_bus_volume)
	if music_volume_setting:
		music_volume_setting.value_changed.connect(on_set_audio_bus_volume)
	if sfx_volume_setting:
		sfx_volume_setting.value_changed.connect(on_set_audio_bus_volume)

	if save_button:
		save_button.pressed.connect(save_and_back)

func refresh():
	var settings:SaveSettings = SaveLoader.new().load_settings()

	if vsync_setting:
		vsync_setting.set_pressed_no_signal(settings.vsync)

	if master_volume_setting:
		var volume_percent = ((settings.master_volume * 100) / 30) + 100
		master_volume_setting.range_slider.value = volume_percent
	if music_volume_setting:
		var volume_percent = ((settings.music_volume * 100) / 30) + 100
		music_volume_setting.range_slider.value = volume_percent
	if sfx_volume_setting:
		var volume_percent = ((settings.sfx_volume * 100) / 30) + 100
		sfx_volume_setting.range_slider.value = volume_percent

func set_window_mode(option:int):
	match option:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func set_borderless(to_set:bool):
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, to_set)

func set_resolution(option:int):
	match option:
		0:
			get_window().size = Vector2i(1920, 1080)
		1:
			get_window().size = Vector2i(1600, 900)
		2:
			get_window().size = Vector2i(1366, 768)
		3:
			get_window().size = Vector2i(1280, 720)

func set_vsync(to_enable:bool):
	if to_enable:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func on_set_audio_bus_volume(bus:String, volume_percent:float) -> bool:
	var slider_range = 100  
	var db_range = 30
	var volume_db = ((volume_percent * db_range) / slider_range) - 30
	
	var bus_idx:int = -1
	match bus.to_lower():
		"master":
			bus_idx = 0
		"music":
			bus_idx = 1
		"sfx":
			bus_idx = 2
			
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, volume_db)
		if volume_db == -db_range:
			AudioServer.set_bus_mute(bus_idx, true)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
		return true
	else:
		return false
	
func save_and_back():
	SaveLoader.new().save_settings()
	menu_closed.emit()
	hide()
