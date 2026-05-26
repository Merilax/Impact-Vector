extends CharacterBody2D
class_name Paddle

@export var hit_sound_comp:AudioStreamPlayer2D;
@export var magnet_sound:AudioStreamPlayer2D;
@export var ball_container:Node2D;

@export var target_ball_container:Node2D;
@export var world_border:WorldBorder;

@export var turret_comp_left:TurretComponent;
@export var turret_comp_right:TurretComponent;

var facing_dir:Vector2 = Vector2.UP;
var follow_mouse:bool = false;
var last_mouse_pos:Vector2;
var last_paddle_pos:Vector2;
var paddle_velocity:Vector2 = Vector2.ZERO;

var team:String;
var is_bot:bool = false;
var target_ball:Ball;

var magnetised:bool = false;
var single_use_magnet:bool = false;
var width:float = 0;
var balls:Array = [];
var magnet_power:int = 0; 
var size_level:int = 0;

var active_turrets:bool = false;

@onready var pickup_area:Area2D = $PickupArea;
@onready var pickup_hitbox:CollisionShape2D = $'PickupArea/CollisionShape2D';
@onready var hitbox_area:Area2D = $Hitbox;
@onready var hitbox:CollisionShape2D = $Hitbox/CollisionShape2D;
@onready var particles_base:GPUParticles2D = $Sprites/Base/PaddleBaseParticles;
@onready var sprites:Node2D = $Sprites;
@onready var sprite_base:Sprite2D = $Sprites/Base;
@onready var sprite_corner_left:Sprite2D = $"Sprites/Corner L";
@onready var sprite_corner_right:Sprite2D = $"Sprites/Corner R";
@onready var sprite_engine_left:Node2D = $"Sprites/Corner L/Engine L";
@onready var sprite_engine_right:Node2D = $"Sprites/Corner R/Engine R";

# var left_engine_tween:Tween;
# var right_engine_tween:Tween;	

var active_scale_tweens:Array = [];
var original_corner_position:Vector2;
var original_sprite_scale:Vector2;
var original_base_width:float = 0;
var original_hitbox_width:float = 0;
var original_pickup_width:float = 0;

signal caught_pickup(type:String, paddle:Paddle);
signal spawn_bullet(pos:Vector2, dir:float);
signal request_new_ball_target();

func _ready():
	last_mouse_pos = DisplayServer.mouse_get_position();
	last_paddle_pos = self.global_position;

	original_sprite_scale = sprites.scale;
	original_corner_position = sprite_corner_right.position;
	original_base_width = sprite_base.get_rect().size.x;
	original_hitbox_width = hitbox.shape.get_rect().size.x;
	original_pickup_width = pickup_hitbox.shape.get_rect().size.x;
	width = original_hitbox_width;

	if turret_comp_left and turret_comp_right and not is_bot:
		turret_comp_left.spawn_bullet.connect(_on_turret_fire);
		turret_comp_left.expire.connect(_on_turret_expire);
		turret_comp_right.spawn_bullet.connect(_on_turret_fire);
		turret_comp_right.expire.connect(_on_turret_expire);

	hitbox_area.body_entered.connect(receive_ball);
	if not is_bot:
		pickup_area.body_entered.connect(_on_body_entered_pickup_area);
		pickup_area.area_entered.connect(_on_area_entered_pickup_area);
		follow_mouse = true;

	if is_bot:
		get_tree().create_timer(20).timeout.connect(die);

	# left_engine_tween = self.create_tween().tween_property(sprite_engine_left, "rotation", 1, .1).set_trans(Tween.TRANS_SINE).ease(Tween.EASE_IN_OUT);

func _unhandled_input(event: InputEvent) -> void:
	if is_bot: return;
	if follow_mouse and event is InputEventMouseMotion:
		var viewport_transform: Transform2D = get_tree().root.get_final_transform();
		var motion: Vector2 = event.xformed_by(viewport_transform).relative;

		motion *= 1; # Mouse sensitivity

		if is_zero_approx(motion.x): return;
		self.global_position.x += motion.x;

func _process(_delta):
	paddle_velocity = self.global_position - last_paddle_pos;
		
	animate_engines();

	if Input.is_action_pressed("mouse_primary") and not is_bot:
		if magnetised or single_use_magnet:
			release_magnet();

		if turret_comp_left: turret_comp_left.fire();
		if turret_comp_right: turret_comp_right.fire();

	if is_bot:
		if is_instance_valid(target_ball):
			if target_ball.lost == false:
				self.global_position.x = target_ball.global_position.x;
		else: request_new_ball_target.emit();
	
	last_paddle_pos = self.global_position;

func _physics_process(_delta):
	if world_border:
		self.global_position.x = clampf(self.position.x, world_border.wall_left.global_position.x + width/2, world_border.wall_right.global_position.x - width/2);

func _on_turret_fire(pos:Vector2, dir:float):
	if is_bot: return;
	spawn_bullet.emit(pos, dir);

func _on_turret_expire():
	active_turrets = false;

func _on_body_entered_pickup_area(node:Node2D):
	if is_bot: return;
	if node.is_in_group("Brick"):
		node.die();
		
func _on_area_entered_pickup_area(node:Area2D):
	if is_bot: return;
	if node.is_in_group('PickUp'):
		caught_pickup.emit(node.type, self);
		node.queue_free();

func calculate_bounce_vector(node) -> Vector2:
	var x_diff = node.global_position.x - self.global_position.x;
	var calc_x = clampf(x_diff / (width/1.5), -0.75, 0.75); # No 90º bounces
	var calc_y = 1 - abs(calc_x);
	return Vector2(calc_x, -calc_y).normalized();

func receive_ball(ball:Node2D, centered:bool = false):
	if ball is not Ball: return;
	if ball.on_paddle: return;
	if signf(ball.velocity.y) == signf(facing_dir.y): return;

	if (magnetised or single_use_magnet) and balls.size() < magnet_power:

		ball.freeze = true;
		ball.dir = Vector2.ZERO;
		ball.reparent(ball_container);
		# ball.call_deferred("reparent", ball_container);
		ball.on_paddle = true;
		#ball.position.y = -((sprite.get_rect().size.y * sprite.scale.y) / 2) - ((ball.sprite.get_rect().size.y * ball.sprite.scale.y));# - original_sprite_position.y
		ball.position.y = - (sprite_base.get_rect().size.y * sprite_base.scale.y / 2); # - (ball.sprite.get_rect().size.y * ball.sprite.scale.y);
		if centered: ball.position.x = 0;

		balls.append(ball);
		if magnet_sound and not centered:
			magnet_sound.play();
	else:
		ball.dir = calculate_bounce_vector(ball);

		if hit_sound_comp: hit_sound_comp.play();
		
		var tween:Tween = create_tween().set_trans(Tween.TRANS_SINE);
		tween.set_ease(Tween.EASE_OUT).tween_property(sprites, "position:y", 7, 0.1);
		tween.set_ease(Tween.EASE_IN).tween_property(sprites, "position:y", 0, 0.1);

func reposition_magnetised_balls():
	for ball:Ball in balls:
		if ball.lost: continue;
		# ball.position.y = - (sprite_base.get_rect().size.y * sprite_base.scale.y) - (ball.sprite.get_rect().size.y * ball.sprite.scale.y);
		ball.position.y = - (sprite_base.get_rect().size.y * sprite_base.scale.y / 2);

func release_magnet():
	single_use_magnet = false;
	for ball:Ball in balls:
		ball.on_paddle = false;
		ball.call_deferred("reparent", target_ball_container);
		# ball.launch_ball(calculate_bounce_vector(ball));
		ball.dir = calculate_bounce_vector(ball);
		ball.freeze = false;
	balls.clear();

func add_magnet(single_use:bool = false) -> int:
	if is_bot: return magnet_power;
	if magnetised:
		magnet_power += 1;
	else:
		reset_powers();
		if single_use: single_use_magnet = true;
		else: magnetised = true;
		magnet_power = 1;
	return magnet_power;

func adjust_size(level:int) -> void:
	active_scale_tweens.clear();

	size_level = level;

	var scalar := 1 + (0.25 * level);

	var base_size_diff := original_base_width - (original_base_width * scalar);
	# var hitbox_width_diff := original_hitbox_width - (original_hitbox_width + base_size_diff);

	var scale_base_tween = self.create_tween().tween_property(sprite_base, "scale:x", 1 * scalar, .2);
	var move_corner_left_tween = self.create_tween().tween_property(sprite_corner_left, "position:x", -original_corner_position.x + (base_size_diff / 2), .2);
	var move_corner_right_tween = self.create_tween().tween_property(sprite_corner_right, "position:x", original_corner_position.x - (base_size_diff / 2), .2);

	var scale_hitbox = self.create_tween().tween_property(self.hitbox.shape, "size:x", original_hitbox_width - (base_size_diff * sprites.scale.x), .2);
	var scale_pickup = self.create_tween().tween_property(self.pickup_hitbox.shape, "size:x", original_pickup_width - (base_size_diff * sprites.scale.x), .2);

	active_scale_tweens.append(scale_base_tween);
	active_scale_tweens.append(move_corner_left_tween);
	active_scale_tweens.append(move_corner_right_tween);
	active_scale_tweens.append(scale_hitbox);
	active_scale_tweens.append(scale_pickup);

	width = original_hitbox_width - (base_size_diff * sprites.scale.x);

	for ball:Ball in balls:
		var move_ball = self.create_tween().tween_property(ball, "position:x", ball.position.x * scalar, .2);
		active_scale_tweens.append(move_ball);

func activate_turrets():
	if is_bot: return;
	if magnetised or single_use_magnet:
		release_magnet();
	reset_powers();
	turret_comp_left.activate();
	turret_comp_right.activate();

func reset_powers():
	if is_bot: return;
	active_turrets = false;
	turret_comp_left.deactivate();
	turret_comp_right.deactivate();

	if magnetised or single_use_magnet:
		release_magnet();
	magnetised = false;
	single_use_magnet = false;

func animate_engines():
	var target_angle = lerp_angle(deg_to_rad(0), deg_to_rad(90), clampf(remap(paddle_velocity.x, -10, 20, 0, 1), 0, 1));
	sprite_engine_left.rotation = target_angle;

	var target_velocity_param = clampf(remap(paddle_velocity.x, -10, 20, 0, 1500), 0, 1500);
	sprite_engine_left.get_child(0).process_material.set_param_min(ParticleProcessMaterial.PARAM_INITIAL_LINEAR_VELOCITY, target_velocity_param);
	sprite_engine_left.get_child(0).process_material.set_param_max(ParticleProcessMaterial.PARAM_INITIAL_LINEAR_VELOCITY, target_velocity_param);

	target_angle = lerp_angle(deg_to_rad(90), deg_to_rad(0), clampf(remap(paddle_velocity.x, -20, 10, 0, 1), 0, 1))
	sprite_engine_right.rotation = target_angle;

	target_velocity_param = clampf(remap(paddle_velocity.x, -20, 10, 1500, 0), 0, 1500)
	sprite_engine_right.get_child(0).process_material.set_param_min(ParticleProcessMaterial.PARAM_INITIAL_LINEAR_VELOCITY, target_velocity_param);
	sprite_engine_right.get_child(0).process_material.set_param_max(ParticleProcessMaterial.PARAM_INITIAL_LINEAR_VELOCITY, target_velocity_param);

func die():
	follow_mouse = false;

	active_scale_tweens.clear();

	if magnetised or single_use_magnet:
		release_magnet();
	
	queue_free();
