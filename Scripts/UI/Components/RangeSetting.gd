extends HBoxContainer
class_name RangeSetting

@export var range_slider:Slider
@export var range_value_label:Label
@export var max_value:float = 100;
@export var min_value:float = 0;

signal value_changed(value:float)

func _ready():
	range_slider.min_value = min_value;
	range_slider.max_value = max_value;

func _on_value_changed(value:float) -> void:
	if range_value_label:
		range_value_label.text = str(value) + '%'

func _on_drag_ended(value_changed_flag:bool) -> void:
	if value_changed_flag:
		var value:float = range_slider.value
		value_changed.emit(value)