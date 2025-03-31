extends Control

@export var main_menu:Control;
@export var settings_menu:Control;

func _ready():
	main_menu.start_game.connect(play_level);
	main_menu.open_editor.connect(open_editor);
	main_menu.open_settings_menu.connect(open_settings);
	settings_menu.menu_closed.connect(close_settings);

	$Background.retrigger();

	SaveLoader.load_settings();
	MusicPlayer.set_track_type("MainMenu");

	Logger.write("Impact Vector ready.", "Root");

func play_level(campaign_path, campaign_num, level_num, savedata):
	Logger.write(str("Instantiating Level: ", campaign_path, campaign_num, "/", level_num), "Root");

	var GameScene:PackedScene = load("uid://la6hglf0tura");
	var game:Game = GameScene.instantiate();
	game.level_num = level_num;
	game.campaign_path = campaign_path;
	game.campaign_num = campaign_num;
	game.save_state = savedata;
	add_sibling(game);
	MusicPlayer.set_track_type("InGame");
	self.queue_free();

	Logger.write("Finished loading Level.", "Root");

func open_editor(campaign_path:String, campaign_num:String, level_num:String = ""):
	Logger.write(str("Instantiating LevelEditor: ", campaign_path, campaign_num, "/", level_num), "Root");

	var LevelEditorScene:PackedScene = load("uid://bhtapwwblyog3");
	var editor:LevelEditor = LevelEditorScene.instantiate();
	editor.campaign_path = campaign_path;
	editor.campaign_num = campaign_num;
	add_sibling(editor);
	if level_num:
		editor.load_level(level_num);
	self.queue_free();

	Logger.write(str("Finished loading LevelEditor: ", campaign_path, campaign_num, "/", level_num), "Root");

func open_settings():
	main_menu.hide();
	settings_menu.refresh();
	settings_menu.show();

func close_settings():
	main_menu.show();
	settings_menu.hide();
