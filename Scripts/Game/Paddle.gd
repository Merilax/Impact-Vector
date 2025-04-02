extends CharacterBody2D
class_name Paddle

@export var hit_sound_comp:AudioStreamPlayer2D;
@export var magnet_sound:AudioStreamPlayer2D;
@export var turrets_comp:TurretsComponent;

@export var world_border:WorldBorder;
@export var ball_container:Node2D;

var follow_mouse:bool = false;

var magnetised:bool = false;
var single_use_magnet:bool = false;
var width:float = 0;
var balls:Array = [];
var magnet_power:int = 0; 
var size_level:int = 0;

var active_turrets:bool = false;

@onready var pickup_area:Area2D = $PickupArea;
@onready var pickup_hitbox:CollisionPolygon2D = $'PickupArea/PickupHitbox';
@onready var hitbox:CollisionPolygon2D = $Hitbox;
@onready var sprite:Sprite2D = $Sprite2D;
var original_sprite_position:Vector2;

signal spawn_bullet(pos:Vector2, dir:float);

func _ready():
	pickup_area.body_entered.connect(_on_body_entered_pickup_area);
	pickup_area.area_entered.connect(_on_area_entered_pickup_area);
	width = sprite.get_rect().size.x * sprite.scale.x;

	original_sprite_position = sprite.position;

	if turrets_comp:
		turrets_comp.spawn_bullet.connect(_on_turrets_fire);
		turrets_comp.expire.connect(_on_turrets_expire);

func _process(_delta):
	if Input.is_action_pressed("mouse_primary"):
		if magnetised or single_use_magnet:
			release_magnet()

		if turrets_comp:
			turrets_comp.fire()

func _physics_process(_delta):
	if follow_mouse:
		self.position.x = get_global_mouse_position().x;
	if world_border:
		self.position.x = clampf(self.position.x, world_border.wall_left.global_position.x + width/2, world_border.wall_right.global_position.x - width/2);

func _on_turrets_fire(pos:Vector2, dir:float):
	spawn_bullet.emit(pos, dir)

func _on_turrets_expire():
	active_turrets = false

func _on_body_entered_pickup_area(_node:Node2D):
	pass
		
func _on_area_entered_pickup_area(node:Area2D):
	if node.is_in_group('PickUp'):
		node.send_signal()

func calculate_bounce_vector(node) -> Vector2:
	var x_diff = node.global_position.x - self.global_position.x
	var calc_x = clampf(x_diff / (width/1.5), -0.75, 0.75) # No 90º bounces
	var calc_y = 1 - abs(calc_x)
	return Vector2(calc_x, -calc_y).normalized()

func receive_ball(ball:Ball, centered:bool = false):
	if (magnetised or single_use_magnet) and balls.size() < magnet_power:
		ball.freeze = true;
		ball.dir = Vector2.ZERO;
		ball.reparent(sprite);
		ball.on_paddle = true;
		# ball.position.y = ;
		ball.position.y = -((sprite.get_rect().size.y * sprite.scale.y) / 2) - ((ball.sprite.get_rect().size.y * ball.sprite.scale.y));# - original_sprite_position.y
		if centered: ball.position.x = 0;

		balls.append(ball);
		if magnet_sound and not centered:
			magnet_sound.play();
	else:
		ball.dir = calculate_bounce_vector(ball);

		if hit_sound_comp: hit_sound_comp.play();
		
		var tween:Tween = create_tween().set_trans(Tween.TRANS_SINE);
		tween.set_ease(Tween.EASE_OUT).tween_property(sprite, "position:y", 10, 0.1);
		tween.set_ease(Tween.EASE_IN).tween_property(sprite, "position:y", 0, 0.1);

func release_magnet():
	single_use_magnet = false;
	for ball:Ball in balls:
		ball.on_paddle = false;
		ball.call_deferred("reparent", ball_container);
		ball.dir = calculate_bounce_vector(ball);
		ball.freeze = false;
	balls.clear();

func add_magnet(single_use:bool = false) -> int:
	if magnetised:
		magnet_power += 1;
	else:
		reset_powers();
		if single_use: single_use_magnet = true;
		else: magnetised = true;
		magnet_power = 1;
	return magnet_power;

func adjust_size(expand:bool) -> void:
	var sprite_scale_amount:float = 0;
	var hitbox_amount:Vector2 = Vector2(1, 1);

	if expand:
		if size_level >= 3: return;
		sprite_scale_amount = 1.1;
		hitbox_amount = Vector2(1.1, 1);
		size_level += 1;
	else:
		if size_level <= -3: return;
		sprite_scale_amount = 0.9;
		hitbox_amount = Vector2(0.9, 1);
		size_level -= 1;

	sprite.scale.x *= sprite_scale_amount;
	width = sprite.get_rect().size.x * sprite.scale.x;

	var mod_hitbox:PackedVector2Array = hitbox.polygon.duplicate();
	for i:int in range(0, mod_hitbox.size()):
		mod_hitbox[i] *= hitbox_amount;
	hitbox.set_deferred("polygon", mod_hitbox);

	var mod_pickup_hitbox:PackedVector2Array = pickup_hitbox.polygon.duplicate();
	for i:int in range(0, mod_pickup_hitbox.size()):
		mod_pickup_hitbox[i] *= hitbox_amount;
	pickup_hitbox.set_deferred("polygon", mod_pickup_hitbox);

func activate_turrets():
	if magnetised or single_use_magnet:
		release_magnet()
	reset_powers()
	turrets_comp.activate()

func reset_powers():
	active_turrets = false
	turrets_comp.deactivate()

	if magnetised or single_use_magnet:
		release_magnet()
	magnetised = false
	single_use_magnet = false

func die():
	follow_mouse = false;
	if magnetised or single_use_magnet:
		release_magnet();
	queue_free();
