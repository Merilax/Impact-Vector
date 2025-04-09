extends CharacterBody2D
class_name Bullet

var freeze:bool = true;
var dir:Vector2 = Vector2.UP;
@export var damage :float = 1;
@export var speed :float = 800;

func _physics_process(delta):
	var motion:Vector2 = dir.normalized() * speed;
	if self.freeze: return;

	var collision = move_and_collide(motion * delta);

	if collision:
		var collided = collision.get_collider();

		if collided.is_in_group('Brick'):
			collided.hit(self, self.damage);
			if collided.init_pushable:
				collided.apply_impulse(motion, collision.get_position() - collided.global_position);

		queue_free();

		if collided.is_in_group('Paddle'):
			#collided.receive_ball(self); # Harm enemy paddle?
			queue_free();
