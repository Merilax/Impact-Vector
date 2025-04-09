extends CanvasLayer

@export var game_root:Node2D;

@export var escape_menu:Control;
@export var settings_menu:Control;
@export var help_menu:Control;

func _ready():
	if escape_menu:
		escape_menu.close_escape.connect(close_menu);
		escape_menu.open_settings.connect(open_settings);
		escape_menu.open_help.connect(open_help);
		escape_menu.save_and_quit.connect(save_and_quit);
	if settings_menu: settings_menu.menu_closed.connect(close_settings);
	if help_menu: help_menu.menu_closed.connect(close_help);

	if GlobalVars.has_seen_editor_help_once == false:
		open_menu();
		open_help();
		GlobalVars.has_seen_editor_help_once = true;
		SaveLoader.save_settings();

func _process(_delta):
	if Input.is_action_just_pressed("escape"):
		close_settings();
		close_help();

		if visible == false: open_menu();
		else: close_menu();
		
func open_menu():
	show();
	escape_menu.show();
	get_tree().paused = true;
	#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE;

func close_menu():
	hide();
	get_tree().paused = false;
	#Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN;

func open_settings():
	escape_menu.hide();
	settings_menu.show();
	settings_menu.refresh();

func close_settings():
	escape_menu.show();
	settings_menu.hide();

func open_help():
	escape_menu.hide();
	help_menu.show();

func close_help():
	escape_menu.show();
	help_menu.hide();

func save_and_quit():
	get_tree().paused = false;
	var MainMenu:PackedScene = load("uid://c0a7y1ep5uibb");
	var main_menu:Control = MainMenu.instantiate();

	game_root.add_sibling(main_menu);
	game_root.queue_free();
