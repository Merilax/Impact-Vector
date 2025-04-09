extends CanvasLayer
class_name EscapeLayer

@export var game_root:Game

@export var escape_menu:Control
@export var settings_menu:Control

var forbid_unescape:bool = false;

signal menu_closed();

func _ready():
	if escape_menu:
		escape_menu.close_escape.connect(close_menu);
		escape_menu.open_settings.connect(open_settings);
		escape_menu.save_and_quit.connect(save_and_quit);
	if settings_menu: settings_menu.menu_closed.connect(close_settings);

	get_window().focus_exited.connect(func(): open_menu());

func _process(_delta):
	if Input.is_action_just_pressed("escape"):
		if self.visible: close_menu();
		else: open_menu();
		
func open_menu():
	close_settings();

	show();
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE;
	get_tree().paused = true;

func close_menu():
	hide();
	if forbid_unescape: return;
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN;
	menu_closed.emit();
	get_tree().paused = false;

func open_settings():
	escape_menu.hide()
	settings_menu.show()
	settings_menu.refresh()

func close_settings():
	escape_menu.show()
	settings_menu.hide()

func save_and_quit():
	get_tree().paused = false;

	await game_root.save_gamedata(); # TODO Warn and ask.

	var MainMenu:PackedScene = load("uid://c0a7y1ep5uibb");
	var main_menu:Control = MainMenu.instantiate();

	game_root.add_sibling(main_menu);
	game_root.queue_free();
