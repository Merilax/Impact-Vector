extends Control
class_name EditorBrickSample

var resource
@export var texture_rect:TextureRect

signal set_active_res(resource)

func _on_gui_input(event:InputEvent) -> void:
	if event.is_pressed(): set_active_res.emit(resource);
