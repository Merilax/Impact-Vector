extends Control
class_name EditorBrickSample

var resource;
var shader_color_count:int = 0;
@export var texture_rect:TextureRect;

signal set_active_res(resource);

func _on_gui_input(event:InputEvent) -> void:
	if event.is_pressed(): set_active_res.emit(resource);

func set_shader_color_count(count:int) -> void:
	texture_rect.material.set_shader_parameter("color_count", count);
	shader_color_count = count;

func set_shader_color(channel:int, color:Color) -> void:
	if self.shader_color_count == 0 and channel == 0:
		texture_rect.material.set_shader_parameter("modulate", color);
	else:
		texture_rect.material.set_shader_parameter(str("target_color", channel + 1), color);
