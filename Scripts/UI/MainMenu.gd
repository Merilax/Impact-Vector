extends Control

@export var play_button:Button
@export var settings_button:Button
@export var exit_button:Button

@export var level_selector:GridContainer
var selected_level_path:String

signal start_game(selected_level_path)
signal open_settings_menu()

func _ready():
	if level_selector:
		level_selector.set_level.connect(set_level)

	if play_button:
		play_button.pressed.connect(play_level)
	if settings_button:
		settings_button.pressed.connect(goto_settings)
	if exit_button:
		exit_button.pressed.connect(quit)

func set_level(filepath:String):
	if FileAccess.file_exists(filepath):
		selected_level_path = filepath

func play_level():
	if selected_level_path:
		start_game.emit(selected_level_path)

func goto_settings():
	open_settings_menu.emit()

func quit():
	get_tree().quit()
