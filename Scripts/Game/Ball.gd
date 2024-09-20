extends RigidBody2D

@export var damage :float = 1
@export var speed :float = 800
@export var speed_mult :float = 1

func _physics_process(delta):
	var motion:Vector2 = linear_velocity.normalized() * speed * speed_mult
	if self.freeze == true:
		return
	var collision = move_and_collide(motion * delta)

	if collision:
		var collided = collision.get_collider()
		if collided.is_in_group('Hitable'):
			linear_velocity = linear_velocity.bounce(collision.get_normal())

			if collided.has_method('hit'):
				collided.hit(self)

			if collided.is_in_group('Brick'):
				if collided.is_in_group('Rigid'):
					collided.apply_impulse(motion, collision.get_position() - collided.global_position)

		if collided.is_in_group('Paddle'):
			collided.receive_ball(self)

func die():
	queue_free()

func set_speed(mult:float):
	speed_mult = mult