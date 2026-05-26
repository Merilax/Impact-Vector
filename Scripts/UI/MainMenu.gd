extends Control

@export var continue_button:Button;
@export var base_campaigns_button:Button;
@export var custom_campaigns_button:Button;
@export var settings_button:Button;
@export var exit_button:Button;

# var campaign_folder:String;
# var campaign_path:String;

@export var base_campaigns:Control;
@export var custom_campaigns:Control;
@export var campaign_levels:Control;
@export var settings_menu:Control;

@export var create_level_button:Button;
@export var import_campaign_button:Button;
@export var import_level_button:Button;

@export var file_dialog:FileDialog;
var file_dialog_path:String;
@export var notification_popup:AcceptDialog;
@export var confirmation_popup:ConfirmationDialog;

signal start_game(campaign_path:String, campaign_folder:String, level_num:String, savedata:SaveGameData);
signal open_editor(campaign_path:String, campaign_folder:String, level_num:String);
signal fd_processed();
signal file_management_finished(ok:bool);
signal confirmation_popup_processed(ok:bool);

var last_campaign_type_is_custom:bool;
var confirmation_popup_result:bool;

func _ready():
	if base_campaigns_button:
		base_campaigns_button.pressed.connect(view_campaigns.bind(false));
	if custom_campaigns_button:
		custom_campaigns_button.pressed.connect(view_campaigns.bind(true));

	if base_campaigns:
		base_campaigns.select_campaign.connect(select_campaign);

	if custom_campaigns:
		custom_campaigns.import_campaign.connect(import_campaign);
		custom_campaigns.select_campaign.connect(select_campaign);
		if file_dialog: custom_campaigns.export_campaign.connect(export_campaign);

	if campaign_levels:
		campaign_levels.go_back.connect(return_from_campaign_levels);
		campaign_levels.create_level.connect(create_level);
		campaign_levels.play_level.connect(play_level);
		campaign_levels.edit_level.connect(edit_level);
		if file_dialog:
			campaign_levels.import_level.connect(import_level);
			campaign_levels.export_level.connect(export_level);

	if settings_menu:
		settings_menu.menu_closed.connect(close_settings);

	if create_level_button:
		create_level_button.pressed.connect(create_level);
	if import_campaign_button and file_dialog:
		import_campaign_button.pressed.connect(import_campaign);
	if import_level_button and file_dialog:
		import_level_button.pressed.connect(import_level);

	if continue_button:
		continue_button.pressed.connect(continue_game);
	if settings_button:
		settings_button.pressed.connect(open_settings);
	if exit_button:
		exit_button.pressed.connect(quit);

	if file_dialog:
		file_dialog.dir_selected.connect(_on_fd_confirmed);
		file_dialog.file_selected.connect(_on_fd_confirmed);
		file_dialog.canceled.connect(_on_fd_canceled);

	if confirmation_popup:
		confirmation_popup.canceled.connect(func(): confirmation_popup_processed.emit(false));
		confirmation_popup.confirmed.connect(func(): confirmation_popup_processed.emit(true));

	# Check for a saved game.
	if FileAccess.file_exists("user://SaveGameData.tres"):
		continue_button.disabled = false;

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE;
	LoggerFile.write("Ready.", "MainMenu");

func close_settings():
	settings_menu.hide();
	SaveLoader.load_settings();

func open_settings():
	campaign_levels.hide();
	base_campaigns.hide();
	custom_campaigns.hide();
	settings_menu.refresh();
	settings_menu.show();

func view_campaigns(custom:bool = false):
	settings_menu.hide();
	campaign_levels.hide();
	base_campaigns.hide();
	custom_campaigns.hide();
	
	last_campaign_type_is_custom = custom;

	if not custom:
		base_campaigns.show();
		base_campaigns.refresh();
	else:
		custom_campaigns.show();
		custom_campaigns.refresh();

func return_from_campaign_levels():
	view_campaigns(last_campaign_type_is_custom);

func select_campaign(campaign_num:String):
	if not last_campaign_type_is_custom:
		create_level_button.hide();
		import_level_button.hide();
		last_campaign_type_is_custom = false;
	else:
		create_level_button.show();
		import_level_button.show();
		last_campaign_type_is_custom = true;

	campaign_levels.on_select_campaign(last_campaign_type_is_custom, campaign_num);

	base_campaigns.hide();
	custom_campaigns.hide();
	campaign_levels.show();

func confirm_delete_campaign() -> bool:
	notification_popup.dialog_text = "Are you sure you want to delete this campaign?";
	notification_popup.show();
	
	return await self.confirmation_popup_processed;

func confirm_delete_level() -> bool:
	notification_popup.dialog_text = "Are you sure you want to delete this level?";
	notification_popup.show();
	
	return await self.confirmation_popup_processed;

func create_level(campaign_folder:String):
	LoggerFile.write("Creating new level.", "MainMenu");
	open_editor.emit(campaign_folder);

func continue_game():
	LoggerFile.write("Continuing existing game.", "MainMenu");
	var save_state:SaveGameData = load("user://SaveGameData.tres");
	
	# var regex = RegEx.new();
	# regex.compile("(\\w|\\d|://)+");
	# var paths:Array[RegExMatch] = regex.search_all(save_state.level_path);
	
	play_level(save_state.campaign_num, save_state.level_num, save_state);

func play_level(campaign_num:String, level_num:String, savedata:SaveGameData = null):
	var base_dir;

	if savedata:
		last_campaign_type_is_custom = savedata.campaign_is_custom;
		
	if last_campaign_type_is_custom:
		base_dir = "user://Levels/";
	else:
		base_dir = "res://Levels/";

	LoggerFile.write("Playing level " + level_num + " from campaign " + campaign_num, "MainMenu");
	
	if last_campaign_type_is_custom and not FileAccess.file_exists(base_dir + campaign_num + "/" + level_num + "/level.json"):
		return;

	start_game.emit(last_campaign_type_is_custom, campaign_num, level_num, savedata);

func edit_level(campaign_num:String, level_num:String):
	LoggerFile.write("Editing level: " + level_num, "MainMenu");
	if FileAccess.file_exists("user://Levels/" + campaign_num + "/" + level_num + "/level.json"):
		open_editor.emit(campaign_num, level_num);

func import_campaign():
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE;
	file_dialog.filters = PackedStringArray(["*.ivc"]);
	file_dialog.show();
	await self.fd_processed;

	if file_dialog_path.is_empty(): return;
	var ok = FileManager.import_any(file_dialog_path);
	custom_campaigns.refresh();
	if ok:
		notification_popup.dialog_text = "Campaign imported successfuly.";
	else:
		notification_popup.dialog_text = "An error ocurred while importing a campaign.";
	notification_popup.show();
	file_management_finished.emit(ok);

func import_level(from_campaign_num:String):
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE;
	file_dialog.filters = PackedStringArray(["*.ivl"]);
	file_dialog.show();
	await self.fd_processed;

	if file_dialog_path.is_empty(): return;
	var ok = FileManager.import_any(file_dialog_path, from_campaign_num);
	campaign_levels.refresh();
	if ok:
		notification_popup.dialog_text = "Level imported successfuly.";
	else:
		notification_popup.dialog_text = "An error ocurred while importing a level.";
	notification_popup.show();
	file_management_finished.emit(ok);

func export_campaign(from_campaign_num:String):
	var base_dir;
	if last_campaign_type_is_custom: base_dir = "user://Levels/";
	else: base_dir = "res://Levels/";

	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR;
	file_dialog.filters = PackedStringArray();
	file_dialog.show();
	await self.fd_processed;

	if file_dialog_path.is_empty(): return;
	var ok = FileManager.export_campaign(file_dialog_path, base_dir + from_campaign_num + '/');
	if ok:
		notification_popup.dialog_text = "Campaign exported successfuly.";
	else:
		notification_popup.dialog_text = "An error ocurred while exporting a campaign.";
	notification_popup.show();
	file_management_finished.emit(ok);

func export_level(from_campaign_num:String, from_level_num:String):
	var base_dir;
	if last_campaign_type_is_custom: base_dir = "user://Levels/";
	else: base_dir = "res://Levels/";
	
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR;
	file_dialog.filters = PackedStringArray();
	file_dialog.show();
	await self.fd_processed;

	if file_dialog_path.is_empty(): return;
	var ok = FileManager.export_level(file_dialog_path, base_dir + from_campaign_num + "/" + from_level_num + "/");
	if ok:
		notification_popup.dialog_text = "Level exported successfuly.";
	else:
		notification_popup.dialog_text = "An error ocurred while exporting a level.";
	notification_popup.show();
	file_management_finished.emit(ok);

func _on_fd_confirmed(path:String):
	file_dialog.hide();
	file_dialog_path = path;
	fd_processed.emit();

func _on_fd_canceled():
	file_dialog.hide();
	file_dialog_path = "";
	fd_processed.emit();

func quit():
	LoggerFile.write(str("Quitting game @ ", Time.get_datetime_string_from_system(false, true)), "MainMenu");
	get_tree().quit();
