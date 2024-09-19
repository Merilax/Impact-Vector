extends Control

@export var play_button:Button
@export var editor_button:Button
@export var settings_button:Button
@export var exit_button:Button

@export var level_selector:GridContainer

signal start_game(level_path:String)
signal open_editor(level_path:String)
signal open_settings_menu()

func _ready():
	if level_selector:
		level_selector.play_level.connect(play_level)
		level_selector.edit_level.connect(edit_level)

	if editor_button:
		editor_button.pressed.connect(edit_level)

	if settings_button:
		settings_button.pressed.connect(goto_settings)
	if exit_button:
		exit_button.pressed.connect(quit)

func play_level(level_dir:String):
	if FileAccess.file_exists(level_dir + "level.tscn"):
		start_game.emit(level_dir)

func edit_level(level_dir:String = ""):
	if FileAccess.file_exists(level_dir + "level.tscn"):
		open_editor.emit(level_dir)
	else:
		open_editor.emit()

func goto_settings():
	open_settings_menu.emit()

func goto_editor():
	open_editor.emit()

func quit():
	get_tree().quit()
