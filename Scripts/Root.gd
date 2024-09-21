extends Control

@onready var main_menu:Control = $PanelContainer/MarginContainer/MainMenu
@onready var settings_menu:Control = $PanelContainer/MarginContainer/SettingMenu

func _ready():
	main_menu.start_game.connect(play_level)
	main_menu.open_editor.connect(open_editor)
	main_menu.open_settings_menu.connect(open_settings)
	settings_menu.menu_closed.connect(close_settings)

	SaveLoader.new().load_settings()
	MusicPlayer.set_track_type("MainMenu")

func play_level(campaign, level_num):
	var GameScene:PackedScene = load("res://Scenes/Game/Level.tscn")
	var game:Node2D = GameScene.instantiate()
	game.level_num = level_num
	game.campaign_name = campaign
	add_sibling(game)
	MusicPlayer.set_track_type("InGame")
	self.queue_free()

func open_editor(campaign:String = "Default", level_num:String = ""):
	var LevelEditorScene:PackedScene = load("res://Scenes/Game/LevelEditor.tscn")
	var editor:LevelEditor = LevelEditorScene.instantiate()
	add_sibling(editor)
	if level_num:
		editor.load_level(campaign, level_num)
	self.queue_free()

func open_settings():
	main_menu.hide()
	settings_menu.refresh()
	settings_menu.show()

func close_settings():
	main_menu.show()
	settings_menu.hide()
