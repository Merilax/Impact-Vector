extends Control

@export var play_button:Button
@export var level_selector:GridContainer
var selected_level_path:String

func _ready():
	if level_selector:
		level_selector.set_level.connect(set_level)

	if play_button:
		play_button.pressed.connect(play_level)

func set_level(filepath:String):
	if FileAccess.file_exists(filepath):
		selected_level_path = filepath

func play_level():
	if selected_level_path:
		var GameScene:PackedScene = load("res://Scenes/Level.tscn")
		var game:Node2D = GameScene.instantiate()
		game.current_level_path = selected_level_path
		replace_by(game)
