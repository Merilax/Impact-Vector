extends CharacterBody2D
class_name Ball

var lost:bool = false
var freeze:bool = true
var dir:Vector2 = Vector2.ZERO
@export var damage :float = 1
@export var speed :float = 750
@export var speed_mult :float = 1

#signal reset_stuck_timer(free_timer:bool)

func _physics_process(delta):
	if self.freeze == true:
		return
	var motion:Vector2 = dir.normalized() * speed * speed_mult
	
	var collision = move_and_collide(motion * delta)

	if collision:
		var collided = collision.get_collider()
		if collided.is_in_group('Hitable'):
			dir = dir.bounce(collision.get_normal())

			# Unstuck ball (can't do on X because paddle can bounce the ball vertically)
			if abs(dir.y) < 0.05:
				dir.y = randf_range(-0.1, 0.1)
				
			if collided.has_method('hit'):
				collided.hit(self)

			if collided.is_in_group('Brick'):
				#reset_stuck_timer.emit(false)
				if collided.is_in_group('Rigid'):
					collided.apply_impulse(motion, collision.get_position() - collided.global_position)

		if collided.is_in_group('Paddle'):
			collided.receive_ball(self)
			#reset_stuck_timer.emit(true)

func die():
	lost = true
	queue_free()

func set_speed(mult:float, _change_label:bool = false):
	speed_mult = mult