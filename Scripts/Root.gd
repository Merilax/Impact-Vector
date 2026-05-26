extends Control

@export var main_menu:Control;
@export var settings_menu:Control;

func _ready():
	main_menu.start_game.connect(play_level);
	main_menu.open_editor.connect(open_editor);

	$Background.retrigger();

	SaveLoader.load_settings();
	MusicPlayer.set_track_type("MainMenu");

	await get_tree().process_frame;
	
	LoggerFile.write("Impact Vector ready.", "Root");

func play_level(custom:bool, campaign_num, level_num, savedata):
	LoggerFile.write(str("Instantiating Level: ", campaign_num, "/", level_num), "Root");

	var GameScene:PackedScene = load("uid://la6hglf0tura");
	var game:Game = GameScene.instantiate();
	game.level_num = level_num;
	game.campaign_is_custom = custom;
	game.campaign_num = campaign_num;
	game.save_state = savedata;
	add_sibling(game);
	MusicPlayer.set_track_type("InGame");
	self.queue_free();

	LoggerFile.write("Finished loading Level.", "Root");

func open_editor(campaign_num:String, level_num:String = ""):
	LoggerFile.write(str("Instantiating LevelEditor: ", campaign_num, "/", level_num), "Root");

	var LevelEditorScene:PackedScene = load("uid://bhtapwwblyog3");
	var editor:LevelEditor = LevelEditorScene.instantiate();
	editor.campaign_num = campaign_num;
	add_sibling(editor);
	if level_num:
		editor.load_level(level_num);
	self.queue_free();

	LoggerFile.write(str("Finished loading LevelEditor: ", campaign_num, "/", level_num), "Root");

func open_settings():
	main_menu.hide();
	settings_menu.refresh();
	settings_menu.show();

func close_settings():
	main_menu.show();
	settings_menu.hide();
