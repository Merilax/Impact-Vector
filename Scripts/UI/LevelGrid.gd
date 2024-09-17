extends GridContainer

var LevelPanel = preload("res://Scenes/UI/LevelPanel.tscn")

signal set_level(filepath:String)

func _ready() -> void:
	var levels:PackedStringArray = DirAccess.open("res://Levels/Standard").get_files()

	for level_filename:String in levels:
		var level_panel:PanelContainer = LevelPanel.instantiate()
		level_panel.set_meta('level_path', "res://Levels/Standard/" + level_filename) # TODO: Manage Campaigns
		level_panel.get_node("LevelName").text = level_filename.replace('_', ' ').trim_suffix(".tscn")
		add_child(level_panel)

		level_panel.gui_input.connect(on_level_select.bind(level_panel.get_meta("level_path")))

func on_level_select(event:InputEvent, filepath:String):
	if event.is_action_pressed("mouse_primary"):
		set_level.emit(filepath)

