extends VBoxContainer

var CampaignBoxScene = preload("uid://cvlx80hocybuo");

@export var create_campaign_button:Button;
@export var create_campaign_lineedit:LineEdit;

signal select_campaign(campaign_folder:String, folder_name:String);
signal edit_campaign(campaign_folder:String, folder_name:String, new_name:String);
signal export_campaign(campaign_folder:String, folder_name:String);
signal delete_campaign(campaign_folder:String, folder_name:String);

@export var base_campaigns_box:Control;
@export var custom_campaigns_box:Control;

func _ready() -> void:
	if create_campaign_button:
		create_campaign_button.pressed.connect(create_campaign);

	refresh();
    
func refresh():
	for child:Node in base_campaigns_box.get_children():
		child.queue_free();
	for child:Node in custom_campaigns_box.get_children():
		child.queue_free();

	# Base campaigns

	BaseCampaignManager.check_integrity()
	var base_json:String = FileAccess.get_file_as_string("res://Levels/campaigns.json");
	var base_campaigns:Dictionary = JSON.parse_string(base_json);

	for campaign in base_campaigns.keys():
		var campaign_box:CampaignBox = CampaignBoxScene.instantiate();
		campaign_box.get_node("HBoxContainer/Name").text = base_campaigns[campaign].name;
		campaign_box.set_meta("folder_path", "res://Levels/");
		campaign_box.set_meta("folder_num", campaign);
		base_campaigns_box.add_child(campaign_box);

		campaign_box.select_campaign.connect(_on_select_campaign);
		campaign_box.edit_button.hide();
		campaign_box.export_button.hide();
		campaign_box.delete_button.hide();

    # Custom campaigns

	CampaignManager.check_integrity()
	var custom_json:String = FileAccess.get_file_as_string("user://Levels/campaigns.json");
	var custom_campaigns:Dictionary = JSON.parse_string(custom_json);

	for campaign in custom_campaigns.keys():
		var campaign_box:CampaignBox = CampaignBoxScene.instantiate();
		campaign_box.get_node("HBoxContainer/Name").text = custom_campaigns[campaign].name;
		campaign_box.set_meta("folder_path", "user://Levels/");
		campaign_box.set_meta("folder_num", campaign);
		custom_campaigns_box.add_child(campaign_box)

		campaign_box.select_campaign.connect(_on_select_campaign);
		campaign_box.edit_campaign.connect(_on_edit_campaign);
		campaign_box.export_campaign.connect(_on_export_campaign);
		campaign_box.delete_campaign.connect(_on_delete_campaign);

func create_campaign():
	if not create_campaign_lineedit.text.is_empty():
		CampaignManager.add_campaign(create_campaign_lineedit.text);
		refresh();

func _on_select_campaign(campaign_folder:String, folder_num:String) -> void:
	select_campaign.emit(campaign_folder, folder_num);

func _on_edit_campaign(campaign_folder:String, folder_num:String, new_name:String) -> void:
	edit_campaign.emit(campaign_folder, folder_num, new_name);

func _on_export_campaign(campaign_folder:String, folder_num:String) -> void:
	export_campaign.emit(campaign_folder, folder_num);

func _on_delete_campaign(campaign_folder:String, folder_num:String, origin:Control) -> void:
	delete_campaign.emit(campaign_folder, folder_num, origin);
