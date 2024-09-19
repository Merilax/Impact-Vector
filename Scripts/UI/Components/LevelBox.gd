extends Control

@export var buttons:HBoxContainer
@export var play_button:Button
@export var edit_button:Button

signal play_level(dir:String)
signal edit_level(dir:String)

func _ready():
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if edit_button:
		edit_button.pressed.connect(_on_edit_pressed)

func _on_focus_entered() -> void:
	if buttons:
		buttons.show()

func _on_focus_exited() -> void:
	if buttons:
		buttons.hide()

func _on_play_pressed() -> void:
	play_level.emit(get_meta("level_dir"))

func _on_edit_pressed() -> void:
	edit_level.emit(get_meta("level_dir"))
