extends GridContainer

var bricks:Array = []

signal set_active_brick_scene(brick_scene:PackedScene)

func _ready() -> void:
	for FilePath:String in DirAccess.get_files_at("res://Scenes/UI/Bricks/"):
		var BrickRect:PackedScene = load("res://Scenes/UI/Bricks/" + FilePath.trim_suffix(".remap"))
		bricks.append(BrickRect)

		var panel = PanelContainer.new()
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(panel)

		var margin = MarginContainer.new()
		margin.add_theme_constant_override('margin_left', 20)
		margin.add_theme_constant_override('margin_top', 20)
		margin.add_theme_constant_override('margin_right', 20)
		margin.add_theme_constant_override('margin_bottom', 20)
		
		panel.add_child(margin)

		var brick_rect:TextureRect = BrickRect.instantiate()
		margin.add_child(brick_rect)
		panel.gui_input.connect(brick_rect.on_click)
		brick_rect.set_active_brick.connect(set_active_brick)

func set_active_brick(brick_scene:PackedScene):
	set_active_brick_scene.emit(brick_scene)
