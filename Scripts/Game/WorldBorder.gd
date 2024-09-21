extends Node2D
class_name WorldBorder

@export var wall_right:Node2D
@export var wall_left:Node2D
@export var wall_up:Node2D

func show_walls(_set_visible:bool): # dev func
    wall_left.get_node("Sprite2D").visible = _set_visible
    wall_right.get_node("Sprite2D").visible = _set_visible