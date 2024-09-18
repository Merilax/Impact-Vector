extends Control

@onready var main_menu:Control = $PanelContainer/MarginContainer/MainMenu
@onready var settings_menu:Control = $PanelContainer/MarginContainer/SettingMenu

func _ready():
	main_menu.start_game.connect(play_level)
	main_menu.open_settings_menu.connect(open_settings)
	settings_menu.menu_closed.connect(close_settings)

func open_settings():
	main_menu.hide()
	settings_menu.refresh()
	settings_menu.show()

func close_settings():
	main_menu.show()
	settings_menu.hide()

func play_level(selected_level_path):
	var GameScene:PackedScene = load("res://Scenes/Game/Level.tscn")
	var game:Node2D = GameScene.instantiate()
	game.current_level_path = selected_level_path
	add_sibling(game)
	self.queue_free()