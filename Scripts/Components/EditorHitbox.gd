extends Area2D
class_name EditorHitboxComponent

var collisions:Array = []
var is_in_wall:bool

signal collision_detected()
signal collision_freed()
signal illegal_collision_detected()
signal illegal_collision_freed()

func _ready():
	monitoring = true
	body_entered.connect(on_body_entered)
	body_exited.connect(on_body_exited)

func on_body_entered(body:Node2D):
	if body == get_parent(): return
	collisions.append(body)

	if not is_in_wall:
		if collides_with_illegal_group(body):
			illegal_collision_detected.emit()
			is_in_wall = true

	if collisions.size() <= 1:
		collision_detected.emit()

func on_body_exited(body:Node2D):
	if body == get_parent(): return
	collisions.erase(body)

	if is_in_wall:
		if collisions.filter(collides_with_illegal_group).size() == 0:
			illegal_collision_freed.emit()
			is_in_wall = false

	if collisions.size() == 0:
		collision_freed.emit()

func collides_with_illegal_group(node:Node2D) -> bool:
	if node.is_in_group('Wall'): return true
	if node.is_in_group('Paddle'): return true
	return false