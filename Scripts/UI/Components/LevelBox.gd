extends Control

@export var buttons:Control
@export var play_button:Button
@export var edit_button:Button
@export var delete_button:Button

signal play_level(level_num:String)
signal edit_level(level_num:String)
signal delete_level(level_num:String)

func _ready():
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if edit_button:
		edit_button.pressed.connect(_on_edit_pressed)
	if delete_button:
		delete_button.pressed.connect(_on_delete_pressed)

func _on_focus_entered() -> void:
	if buttons:
		buttons.show()

func _on_focus_exited() -> void:
	if buttons:
		buttons.hide()

func _on_play_pressed() -> void:
	play_level.emit(get_meta("folder_num"))

func _on_edit_pressed() -> void:
	edit_level.emit(get_meta("folder_num"))

func _on_delete_pressed() -> void:
	delete_level.emit(get_meta("folder_num"), self)