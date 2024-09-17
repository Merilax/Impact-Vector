extends TextureRect

@export var scene_name:String

signal set_active_brick(Brick:PackedScene)

func on_click(event:InputEvent):
	if event.is_pressed():
		var Brick = load("res://Scenes/Game/Bricks/" + scene_name + ".tscn")
		if Brick == null: 
			set_active_brick.emit(null)
		else:
			set_active_brick.emit(Brick)