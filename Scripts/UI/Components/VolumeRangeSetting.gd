extends HBoxContainer
class_name VolumeRangeSetting

@export var range_slider:Slider
@export var range_value_label:Label

signal value_changed(value:float)

func _on_value_changed(value:float) -> void:
	if range_value_label:
		range_value_label.text = str(roundi(value)) + '%'

func _on_drag_ended(value_changed_flag:bool) -> void:
	if value_changed_flag:
		var value:float = range_slider.value
		value_changed.emit(value)