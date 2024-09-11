extends Area2D
class_name Pickup

@export var type:String
@export var falling_speed:int = 150
signal trigger_pickup(type:String)

func _process(delta: float):
	position += Vector2(0, falling_speed) * delta

func send_signal():
	trigger_pickup.emit(type)
	queue_free()