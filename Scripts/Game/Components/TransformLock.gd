extends Node2D
class_name TransformLock

@export var lock_global_position:bool = false;
@export var lock_global_rotation:bool = false;
@export var locked_global_position:Vector2 = Vector2.ZERO;
@export var locked_global_rotation:float = 0;

func _physics_process(_delta):
	if lock_global_position: self.global_position = locked_global_position;
	if lock_global_rotation: self.global_rotation = locked_global_rotation;