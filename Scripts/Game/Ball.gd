extends CharacterBody2D
class_name Ball

var lost:bool = false;
var on_paddle:bool = false;
var freeze:bool = true;
var dir:Vector2 = Vector2.ZERO;
@export var damage :float = 1;
@export var speed :float = 700;
@export var speed_mult :float = 1;
@export var sprite:Sprite2D;
@export var collision_shape:CollisionShape2D;
var size_level:int = 0;

#signal reset_stuck_timer(free_timer:bool)
var original_sprite_scale:Vector2;
var original_hitbox_radius:float;

func _ready():
	original_sprite_scale = sprite.scale;
	original_hitbox_radius = collision_shape.shape.radius;

func _physics_process(delta):
	if self.freeze == true:
		return
	var motion:Vector2 = dir.normalized() * speed * speed_mult
	
	var collision = move_and_collide(motion * delta);

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
	lost = true;
	queue_free();

func set_speed(mult:float, _change_label:bool = false):
	speed_mult = mult;

func set_size(level:int) -> void:
	if size_level < -2 or size_level > 2: return;
	if level == size_level: return;
	size_level = level;

	match size_level:
		-2: damage = 0.5;
		-1: damage = 1; # Don't want to punish the player too much.
		0: damage = 1;
		1: damage = 1.5;
		2: damage = 2;

	sprite.scale = original_sprite_scale * (1 + (0.2 * size_level));
	collision_shape.shape.set_deferred("radius", original_hitbox_radius * (1 + (0.2 * size_level)));
