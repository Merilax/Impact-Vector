extends VBoxContainer
class_name EditorSaveSettings

@export var level_name:LineEdit;
@export var save_btn:Button;
@export var play_btn:Button;
@export var load_btn:Button;
@export var exit_btn:Button;

signal save_level();
signal preview_level();
signal reload_level();
signal exit();

func _ready():
	if save_btn: save_btn.pressed.connect(_on_save_pressed);
	if play_btn: play_btn.pressed.connect(_on_play_pressed);
	if load_btn: load_btn.pressed.connect(_on_load_pressed);
	if exit_btn: exit_btn.pressed.connect(_on_exit_pressed);

func _on_save_pressed():
	save_level.emit();

func _on_play_pressed():
	preview_level.emit();

func _on_load_pressed():
	reload_level.emit();

func _on_exit_pressed():
	exit.emit();
