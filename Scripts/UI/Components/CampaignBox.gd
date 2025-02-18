extends Control
class_name CampaignBox

@export var select_button:Button;
@export var edit_button:Button;
@export var export_button:Button;
@export var delete_button:Button;

@export var name_label:Label;
@export var name_lineedit:LineEdit;

var editing_name:bool = false;

signal select_campaign(campaign_folder:String, campaign_num:String);
signal edit_campaign(campaign_folder:String, campaign_num:String, new_name:String);
signal export_campaign(campaign_folder:String, campaign_num:String);
signal delete_campaign(campaign_folder:String, campaign_num:String);

func _ready():
	if select_button:
		select_button.pressed.connect(_on_select_pressed);
	if edit_button:
		edit_button.pressed.connect(edit_name);
	if export_button:
		export_button.pressed.connect(_on_export_campaign);
	if delete_button:
		delete_button.pressed.connect(_on_delete_pressed);

func edit_name():
	if not editing_name:
		name_lineedit.text = name_label.text
		name_label.hide()
		name_lineedit.show()

		select_button.hide()
		delete_button.hide()

		editing_name = true
	else:
		name_label.text = name_lineedit.text
		name_label.show()
		name_lineedit.hide()

		edit_campaign.emit(get_meta("folder_path"), get_meta("folder_num"), name_label.text)

		select_button.show()
		delete_button.show()
		editing_name = false

func _on_export_campaign() -> void:
	export_campaign.emit(get_meta("folder_path"), get_meta("folder_num"));

func _on_select_pressed() -> void:
	select_campaign.emit(get_meta("folder_path"), get_meta("folder_num"));

func _on_delete_pressed() -> void:
	delete_campaign.emit(get_meta("folder_path"), get_meta("folder_num"), self);
