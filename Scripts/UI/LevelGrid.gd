extends Control

var LevelBoxScene = preload("uid://ct3pryubbc463");

@export var main_menu:Control;
@export var go_back_button:Button;
@export var import_level_button:Button;
@export var create_level_button:Button;
@export var play_level_button:Button;
@export var edit_level_button:Button;
@export var export_level_button:Button;
@export var delete_level_button:Button;
@export var level_list:Control;

signal go_back();
signal play_level(campaign_folder:String, folder_num:String);
signal edit_level(campaign_folder:String, folder_num:String);
signal import_level(folder_num:String);
signal create_level(folder_num:String);
signal export_level(folder_num:String);

var is_custom:bool;
var campaign_num:String;
var selected_level_num:String;
var selected_level_control:Control;

func _ready():
	if go_back_button:
		go_back_button.pressed.connect(func (): go_back.emit());
	if import_level_button:
		import_level_button.pressed.connect(_on_import_level);
	if create_level_button:
		create_level_button.pressed.connect(_on_create_level); 
	if play_level_button: play_level_button.pressed.connect(_on_play_level);
	if edit_level_button: edit_level_button.pressed.connect(_on_edit_level);
	if export_level_button: export_level_button.pressed.connect(_on_export_level);
	if delete_level_button: delete_level_button.pressed.connect(_on_delete_level);

func refresh():
	on_select_campaign(is_custom, campaign_num);
	
	play_level_button.disabled = true;
	edit_level_button.disabled = true;
	export_level_button.disabled = true;
	delete_level_button.disabled = true;

func on_select_campaign(set_custom:bool, set_campaign_num:String):
	var base_dir;
	if set_custom: base_dir = "user://Levels/";
	else: base_dir = "res://Levels/";

	is_custom = set_custom;
	campaign_num = set_campaign_num;

	if not is_custom:
		edit_level_button.hide();
		export_level_button.hide();
		delete_level_button.hide();

	for child:Node in level_list.get_children():
		child.queue_free();

	for level_num:String in DirAccess.get_directories_at(base_dir + campaign_num):
		if not FileAccess.file_exists(base_dir + campaign_num + "/" + level_num + "/data.tres"):
			continue;
		var level_data:LevelData = load(base_dir + campaign_num + "/" + level_num + "/data.tres");

		var level_box:LevelBox = LevelBoxScene.instantiate();
		level_box.get_node("LevelBox/LevelName").text = level_data.name;
		level_box.get_node("LevelBox/Thumbnail").texture = level_data.thumbnail;
		level_box.set_meta("level_num", level_num);
		level_list.add_child(level_box);
		level_box.get_child(0).focus_entered.connect(_on_level_box_focus_entered.bind(level_box));

func _on_level_box_focus_entered(origin:Control):
	selected_level_control = origin;
	selected_level_num = origin.get_meta("level_num");

	play_level_button.disabled = false;
	edit_level_button.disabled = false;
	export_level_button.disabled = false;
	delete_level_button.disabled = false;

func _on_import_level() -> void:
	import_level.emit(campaign_num);

func _on_create_level() -> void:
	create_level.emit(campaign_num);

func _on_play_level() -> void:
	if selected_level_num.is_empty(): return;
	play_level.emit(campaign_num, selected_level_num);

func _on_edit_level() -> void:
	if selected_level_num.is_empty(): return;
	edit_level.emit(campaign_num, selected_level_num);

func _on_export_level() -> void:
	if selected_level_num.is_empty(): return;
	export_level.emit(campaign_num, selected_level_num);

func _on_delete_level() -> void:
	if selected_level_num.is_empty(): return;
	var ok = main_menu.confirm_delete_level();
	if not ok: return;

	CampaignManager.remove_level(campaign_num, selected_level_num);
	selected_level_control.queue_free();
	selected_level_control = null;
	selected_level_num = "";
