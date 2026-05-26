extends VBoxContainer

var CampaignBoxScene = preload("uid://cvlx80hocybuo");

@export var is_custom:bool = false;

@export var main_menu:Control;
@export var campaign_list:VBoxContainer;

@export var custom_campaigns_buttons:Control;
@export var import_campaign_button:Button;
@export var create_campaign_button:Button;
@export var create_campaign_lineedit:LineEdit;

signal import_campaign();
signal select_campaign(folder_name:String);
signal export_campaign(folder_name:String);

func _ready() -> void:
	if is_custom:
		custom_campaigns_buttons.show();

		if import_campaign_button:
			import_campaign_button.pressed.connect(func (): import_campaign.emit());
		if create_campaign_button:
			create_campaign_button.pressed.connect(create_campaign);
	
	refresh();
    
func refresh():
	CampaignManager.check_integrity(is_custom);

	for child:Node in campaign_list.get_children():
		child.queue_free();

	var dir_path:String;
	if is_custom:
		dir_path = "user://Levels/";
	else:
		dir_path = "res://Levels/";
		
	var json:String = FileAccess.get_file_as_string(dir_path + "campaigns.json");
	var campaigns_dict:Dictionary = JSON.parse_string(json);

	for campaign in campaigns_dict.keys():
		var campaign_box:CampaignBox = CampaignBoxScene.instantiate();
		campaign_box.get_node("HBoxContainer/Name").text = campaigns_dict[campaign].name;
		campaign_box.set_meta("folder_num", campaign);
		campaign_list.add_child(campaign_box);

		campaign_box.select_campaign.connect(_on_select_campaign);
		campaign_box.edit_campaign.connect(_on_edit_campaign);
		campaign_box.export_campaign.connect(_on_export_campaign);
		campaign_box.delete_campaign.connect(_on_delete_campaign);

func create_campaign():
	if not create_campaign_lineedit.text.is_empty():
		CampaignManager.add_campaign(create_campaign_lineedit.text);
		refresh();

func _on_select_campaign(folder_num:String) -> void:
	select_campaign.emit(folder_num);

func _on_edit_campaign(folder_num:String, new_name:String) -> void:
	CampaignManager.rename_campaign(folder_num, new_name);

func _on_export_campaign(folder_num:String) -> void:
	export_campaign.emit(folder_num);

func _on_delete_campaign(folder_num:String, origin:Control) -> void:
	var ok = main_menu.confirm_delete_campaign();
	if not ok: return;

	CampaignManager.remove_campaign(folder_num);
	origin.queue_free();
