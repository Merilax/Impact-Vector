extends CharacterBody2D
class_name Ball

var damage :float = 1;
var speed :float = 700;
var last_collider_velocity:Vector2 = Vector2.ZERO;

var lost:bool = false;
var on_paddle:bool = false;
var freeze:bool = true;
var dir:Vector2 = Vector2.ZERO;
var prev_dir:Vector2 = dir;

var speed_mult :float = 1;
var size_level:int = 0;
var is_explosive:bool = false;
var is_corrosive:bool = false;
var damage_mult_from_size = 1;
var damage_add_from_explosion = 5;

@export var sprite:Sprite2D;
@export var collision_shape:CollisionShape2D;
@export var explosive_area:Area2D;
@export var particles_corrosive:GPUParticles2D;
@export var particles_explosive:GPUParticles2D;
@export var world_border:WorldBorder;

var original_sprite_scale:Vector2;
var original_hitbox_radius:float;
var diameter:float = 0;

func _ready():
	original_sprite_scale = sprite.scale;
	original_hitbox_radius = collision_shape.shape.radius;
	
	diameter = collision_shape.shape.radius;

func _physics_process(delta):
	velocity = dir.normalized() * speed * speed_mult
		
	var depenetration_test := move_and_collide(Vector2.ZERO, true);
	if depenetration_test:
		var pen_collider := depenetration_test.get_collider();

		if self.lost: return;
		if pen_collider.is_in_group("Brick"):
			last_collider_velocity = pen_collider.linear_velocity;

			var space_state := get_world_2d().direct_space_state;
			var query := PhysicsShapeQueryParameters2D.new();
			query.collide_with_areas = false;
			query.collision_mask = self.collision_mask;
			query.shape = collision_shape.shape.duplicate();

			if pen_collider.is_indestructible or not is_corrosive:
				for i in range(1, 100):
					query.transform = Transform2D(0, self.global_position + (depenetration_test.get_normal().normalized() * i));
					if space_state.intersect_shape(query, 1).size() == 0:
						self.global_position += depenetration_test.get_normal().normalized() * i;
						break;

	var collision := move_and_collide(velocity * delta, true);
	if collision:
		_on_collide(collision);
		
	if world_border:
		self.global_position.x = clampf(self.global_position.x, world_border.wall_left.global_position.x + collision_shape.shape.radius, world_border.wall_right.global_position.x - collision_shape.shape.radius);
		self.global_position.y = clampf(self.global_position.y, world_border.wall_up.global_position.y + collision_shape.shape.radius, INF);

	if self.freeze == true: return;
	self.global_position += velocity * delta;

func _on_collide(collision:KinematicCollision2D):
	var collided = collision.get_collider();
		
	if collided.is_in_group('Brick'):
		if self.lost: return;
		
		if not collided.linear_velocity.is_zero_approx() and collided.linear_velocity.normalized().dot(collision.get_normal()) < 0:
			dir += collided.linear_velocity/10; # Let the brick gently shove the ball if their directions match.
		if dir.normalized().dot(collision.get_normal()) > 0: return; # Don't act if the Ball is being pushed.
			
		if self.is_explosive: self.damage_area();
		else: collided.hit(self, get_damage());
		
		if collided.is_indestructible or not is_corrosive: bounce(collision);

		if collided.init_pushable:
			collided.apply_impulse(velocity, collision.get_position() - collided.global_position);

	if collided.is_in_group('Paddle'):
		if self.lost: return;
		collided.receive_ball(self);

	if collided.is_in_group("Wall"):
		collided.hit(self);
		bounce(collision);

func bounce(collision:KinematicCollision2D):
	if freeze: return;
	dir = dir.bounce(collision.get_normal());
	
	if abs(dir.y) < 0.05:
		dir.y = randf_range(-0.1, 0.1);
	if abs(dir.x) < 0.02:
		dir.x = randf_range(-0.02, 0.02);

func die():
	lost = true;
	collision_mask = 0;
	await get_tree().create_timer(3).timeout;
	queue_free();

func set_speed(mult:float, _change_label:bool = false):
	speed_mult = mult;

func set_size(level:int) -> void:
	if size_level < -2 or size_level > 2: return;
	if level == size_level: return;
	size_level = level;

	match size_level:
		-2: damage_mult_from_size = 0.5;
		-1: damage_mult_from_size = 1; # Don't want to punish the player too much.
		0: damage_mult_from_size = 1;
		1: damage_mult_from_size = 1.5;
		2: damage_mult_from_size = 2;

	diameter = sprite.get_rect().size.x * sprite.scale.x;
	sprite.scale = original_sprite_scale * (1 + (0.2 * size_level));
	var new_radius := original_hitbox_radius * (1 + (0.2 * size_level));
	collision_shape.shape.set_deferred("radius", new_radius);
	particles_corrosive.process_material.emission_sphere_radius = new_radius;
	particles_explosive.process_material.emission_sphere_radius = new_radius;

func set_explosive(toggle:bool):
	clear_modifiers();
	if toggle == true:
		explosive_area.monitoring = true;
		is_explosive = true;
		particles_explosive.emitting = true;
		sprite.self_modulate = Color(1,.9,.55);

func set_corrosive(toggle:bool):
	clear_modifiers();
	if toggle == true:
		is_corrosive = true;
		particles_corrosive.emitting = true;
		sprite.self_modulate = Color(.6,1,.6);

func clear_modifiers():
	is_corrosive = false;
	explosive_area.monitoring = false;
	particles_corrosive.emitting = false;

	is_explosive = false;
	particles_explosive.emitting = false;

	sprite.self_modulate = Color(1,1,1);

func get_damage() -> float:
	var calc:float = damage;
	calc *= damage_mult_from_size;
	if is_explosive: calc += damage_add_from_explosion;
	return calc;

func damage_area():
	for node:Node2D in explosive_area.get_overlapping_bodies():
		if node is Brick:
			node.hit(self, self.get_damage());
			if node.init_pushable:
				node.apply_impulse(Vector2.RIGHT.rotated(self.get_angle_to(node.global_position)) * speed * 0.8);
