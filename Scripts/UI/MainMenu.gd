extends Control

@export var play_button:Button
@export var settings_button:Button
@export var exit_button:Button

var campaign_folder:String
var campaign_path:String

@export var campaign_selector:VBoxContainer
@export var level_selector:VBoxContainer
@export var level_grid:GridContainer

@export var back_to_campaigns_button:Button
@export var create_level_button:Button

signal start_game(campaign:String, level_path:String)
signal open_editor(campaign:String, level_path:String)
signal open_settings_menu()

func _ready():
	if campaign_selector:
		campaign_selector.select_campaign.connect(select_campaign)
		campaign_selector.edit_campaign.connect(edit_campaign)
		campaign_selector.delete_campaign.connect(delete_campaign)

	if level_grid:
		level_grid.play_level.connect(play_level)
		level_grid.edit_level.connect(edit_level)
		level_grid.delete_level.connect(delete_level)

	if back_to_campaigns_button:
		back_to_campaigns_button.pressed.connect(to_campaign_selector)
	if create_level_button:
		create_level_button.pressed.connect(create_level)

	if settings_button:
		settings_button.pressed.connect(goto_settings)
	if exit_button:
		exit_button.pressed.connect(quit)

func to_campaign_selector():
	level_selector.hide()
	campaign_selector.show()

func to_level_selector():
	campaign_selector.hide()
	level_selector.show()

func select_campaign(campaign_folder_path:String, campaign_num:String):
	campaign_path = campaign_folder_path
	campaign_folder = campaign_num
	to_level_selector()
	if campaign_folder_path.contains("res://"):
		create_level_button.hide()
	else: create_level_button.show()
	level_grid.on_select_campaign(campaign_path, campaign_folder)

func edit_campaign(_campaign_folder_path:String, campaign_num:String, new_name:String):
	CampaignManager.rename_campaign(campaign_num, new_name)

func delete_campaign(campaign_folder_path:String, campaign_num:String, origin:Control):
	if campaign_folder_path.contains("res://"): return

	# TODO Warn user
	for sub_dir in DirAccess.open(campaign_folder_path + "/" + campaign_num).get_directories():
		DirAccess.remove_absolute(campaign_folder_path + "/" + campaign_num + "/" + sub_dir + "/level.tscn")
		DirAccess.remove_absolute(campaign_folder_path + "/" + campaign_num + "/" + sub_dir + "/data.tres")
		DirAccess.remove_absolute(campaign_folder_path + "/" + campaign_num + "/" + sub_dir)
	
	DirAccess.remove_absolute(campaign_folder_path + "/" + campaign_num)
	CampaignManager.remove_campaign(campaign_num)
	origin.queue_free()

func create_level():
	open_editor.emit(campaign_path, campaign_folder)

func play_level(level_num:String):
	if campaign_path.contains("res://"):
		start_game.emit(campaign_path, campaign_folder, level_num)
	else:
		if FileAccess.file_exists(campaign_path + "/campaigns.json") and FileAccess.file_exists(campaign_path + "/" + campaign_folder + "/" + level_num + "/level.tscn"):
			start_game.emit(campaign_path, campaign_folder, level_num)

func edit_level(level_num:String):
	if FileAccess.file_exists(campaign_path + "/" + campaign_folder + "/" + level_num + "/level.tscn"):
		open_editor.emit(campaign_path, campaign_folder, level_num)

func delete_level(level_num:String, origin:Control):
	origin.queue_free()
	DirAccess.remove_absolute(campaign_path + "/" + campaign_folder + "/" + level_num + "/level.tscn")
	DirAccess.remove_absolute(campaign_path + "/" + campaign_folder + "/" + level_num + "/data.tres")
	DirAccess.remove_absolute(campaign_path + "/" + campaign_folder + "/" + level_num)

func goto_settings():
	open_settings_menu.emit()

func quit():
	get_tree().quit()
