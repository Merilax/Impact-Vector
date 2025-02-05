extends CanvasLayer

@export var game_root:Node2D

@export var escape_menu:Control
@export var settings_menu:Control

func _ready():
	if escape_menu:
		escape_menu.close_escape.connect(return_to_game)
		escape_menu.open_settings.connect(open_settings)
		escape_menu.save_and_quit.connect(save_and_quit)
	if settings_menu: settings_menu.menu_closed.connect(close_settings)

func _process(_delta):
	if Input.is_action_just_pressed("escape"):
		close_settings()

		if visible == false:
			show()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().paused = true
		else:
			hide()
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
			get_tree().paused = false
		
func return_to_game():
	hide()
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	get_tree().paused = false

func open_settings():
	escape_menu.hide()
	settings_menu.show()
	settings_menu.refresh()

func close_settings():
	escape_menu.show()
	settings_menu.hide()

func save_and_quit():
	get_tree().paused = false
	var MainMenu:PackedScene = load("uid://c0a7y1ep5uibb")
	var main_menu:Control = MainMenu.instantiate()

	game_root.add_sibling(main_menu)
	game_root.queue_free()
