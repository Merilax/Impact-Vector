extends Control

@export var vsync_setting:CheckButton

@export var master_volume_setting:HBoxContainer
@export var music_volume_setting:HBoxContainer
@export var sfx_volume_setting:HBoxContainer

@export var save_button:Button

signal menu_closed()

func _ready():
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
	# TODO: Remember settings
	menu_closed.emit()
	hide()