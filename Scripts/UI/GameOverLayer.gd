extends CanvasLayer

@export var game_root:Node2D
@export var game_over_header:Label
@export var final_score:Label
@export var total_lives:Label
@export var return_button:Button

func _ready():
	if game_root: game_root.game_over_signal.connect(finalise)
	if return_button: return_button.pressed.connect(back_to_main)

func finalise(game_won:bool):
	get_tree().paused = true
	if game_won:
		game_over_header.text = "Game Won"
	final_score.text = str(game_root.score)
	total_lives.text = str(game_root.total_lives)
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func back_to_main():
	get_tree().paused = false
	var MainMenu:PackedScene = load("res://Scenes/Root.tscn")
	var main_menu:Control = MainMenu.instantiate()

	game_root.add_sibling(main_menu)
	game_root.queue_free()