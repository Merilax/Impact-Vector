extends Control

@export var play_button:Button
@export var editor_button:Button
@export var settings_button:Button
@export var exit_button:Button

@export var campaign_folder:String = "Default"
@export var level_selector:GridContainer

signal start_game(campaign:String, level_path:String)
signal open_editor(campaign:String, level_path:String)
signal open_settings_menu()

func _ready():
	if level_selector:
		level_selector.play_level.connect(play_level)
		level_selector.edit_level.connect(edit_level)
		level_selector.delete_level.connect(delete_level)

	if editor_button:
		editor_button.pressed.connect(edit_level)

	if settings_button:
		settings_button.pressed.connect(goto_settings)
	if exit_button:
		exit_button.pressed.connect(quit)

func play_level(level_num:String):
	if FileAccess.file_exists("user://Levels/" + campaign_folder + "/campaign.json") and FileAccess.file_exists("user://Levels/" + campaign_folder + "/" + level_num + "/level.tscn"):
		start_game.emit(campaign_folder, level_num)

func edit_level(level_num:String = ""):
	if level_num.is_empty():
		open_editor.emit()
	elif FileAccess.file_exists("user://Levels/" + campaign_folder + "/" + level_num + "/level.tscn"):
		open_editor.emit(campaign_folder, level_num)

func delete_level(level_num:String, origin:Control):
	if CampaignManager.remove_campaign_level("user://Levels/" + campaign_folder + "/campaign.json", level_num):
		origin.queue_free()
		DirAccess.remove_absolute("user://Levels/" + campaign_folder + "/" + level_num + "/level.tscn")
		DirAccess.remove_absolute("user://Levels/" + campaign_folder + "/" + level_num + "/data.tres")
		DirAccess.remove_absolute("user://Levels/" + campaign_folder + "/" + level_num)

func goto_settings():
	open_settings_menu.emit()

func goto_editor():
	open_editor.emit()

func quit():
	get_tree().quit()
