extends Control

@export var return_button:Button;
@export var settings_button:Button;
@export var help_button:Button;
@export var save_and_quit_button:Button;

signal close_escape();
signal open_settings();
signal open_help();
signal save_and_quit();

func _ready():
	if return_button: return_button.pressed.connect(return_to_game);
	if settings_button: settings_button.pressed.connect(goto_settings);
	if help_button: help_button.pressed.connect(goto_help);
	if save_and_quit_button: save_and_quit_button.pressed.connect(save);

func return_to_game():
	close_escape.emit();

func goto_settings():
	open_settings.emit();

func goto_help():
	open_help.emit();
	
func save():
	save_and_quit.emit();