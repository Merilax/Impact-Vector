extends Area2D
class_name Pickup

@export var type:String
@export var falling_speed:int = 200
@export var falling_dir:Vector2 = Vector2.DOWN;

func _physics_process(delta: float):
	self.global_position += Vector2(0, falling_speed) * delta