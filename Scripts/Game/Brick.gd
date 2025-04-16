extends RigidBody2D
class_name Brick

@export_group("Nodes")
@export var hitbox:Node2D;
@export var texture_sprite:Polygon2D;
@export var health_comp:HealthComponent;
@export var score_comp:ScoreComponent;
@export var hit_sound_comp:AudioStreamPlayer2D;
@export var destroy_sound_comp:AudioStreamPlayer2D;
@export var pickup_comp:PickupComponent;
@export var editor_hitbox:EditorHitboxComponent;

@export_group("Data")
@export var hitbox_path:String; # Must be set
@export var texture_path:String; # Must be set
@export var shader_color:Color = Color(1, 1, 1, 1);
@export var init_health:float = 1;
@export var init_score:float = 10;
@export var init_pushable:bool = false;
@export var init_mass:float = 5;
@export var can_collide:bool = false;
@export var scoreable:bool = true;
@export var is_indestructible:bool = false;
@export var is_path_clone:bool = false;
@export var path_group:int = -1;
@export var is_editor:bool = true;

@export var polygon_array:PackedVector2Array;
@export var polygon_texture_offset:Vector2;
@export var polygon_texture_scale:Vector2;

@export var texture_type:String;

var tweening_shader:bool = false;
var tweening_size:bool = false;

@export var original_sprite_size := Vector2(0, 0);

signal process_score(score:int);
signal spawn_pickup(global_position:Vector2, type:String, texture:String);
signal brick_destroyed(brick:Brick);

func setup(as_editable:bool = true):
	texture_sprite.polygon = polygon_array;
	texture_sprite.texture_offset = polygon_texture_offset;
	texture_sprite.texture_scale = polygon_texture_scale;

	if not load(texture_path):
		Logger.write(str("Texture path does not exist: ", texture_path), "Brick");
		return;
	set_texture_sprite(texture_path, false);
	rescale_sprite();
	self.visible = true;

	freeze = not init_pushable;
	mass = init_mass;

	var hitbox_scene = load(hitbox_path);
	if not hitbox_scene:
		Logger.write(str("Hitbox path does not exist: ", hitbox_path), "Brick");
		return;
	var hitbox_node = hitbox_scene.instantiate();
	self.add_child(hitbox_node, true);
	hitbox_node.owner = self;
	hitbox = hitbox_node;
	texture_type = hitbox.get_meta("texture_type");

	if shader_color:
		texture_sprite.material.set_shader_parameter("to", shader_color);

	if can_collide:
		self.collision_mask = 12;
	else:
		self.collision_mask = 8;

	is_editor = as_editable;
	if is_editor: setup_as_editable();
	else: setup_as_playable();

func setup_as_playable():
	self.hitbox.disabled = false;
	if editor_hitbox: editor_hitbox.queue_free();

	if health_comp:
		if init_health: health_comp.health = init_health;
		health_comp.health_depleted.connect(die.bind());

	if score_comp:
		if init_score: score_comp.score = floor(init_score);
		score_comp.process_score.connect(add_score.bind());

	await get_tree().create_timer(randf_range(0, 1)).timeout;
	#tween_shader_shift_by(Color(-.1, -.1, -.1, 0), .3, true, true, 0, 1.5);
	tween_brightness(-.2, .3, true, true, 0, 0.5);

func setup_as_editable():
	self.editor_hitbox.add_child(self.hitbox.duplicate());

func hit(node:Node2D = null, amount:float = 0):
	if is_editor: return;
	if node:
		if node.is_in_group('Ball'):
			if hit_sound_comp: hit_sound_comp.play();
			if is_indestructible: return;
			if node.is_corrosive:
				die();
				return;
			if health_comp: health_comp.damage(amount);
			
		if node.is_in_group('Bullet'):
			if hit_sound_comp: hit_sound_comp.play();
			if is_indestructible: return;
			if health_comp: health_comp.damage(amount);
	# else:
	# 	if not is_indestructible and (amount != 0) and health_comp: health_comp.damage(amount);

func die():
	if is_editor: return;
	hitbox.disabled = true;
	texture_sprite.hide();
	if score_comp: score_comp.emit_score();
	brick_destroyed.emit(self);

	if pickup_comp:
		spawn_pickup.emit(self.global_position, pickup_comp.pickup_type, pickup_comp.pickup_sprite);

	if destroy_sound_comp and hit_sound_comp: # Stop hit sound and play kill sound
		hit_sound_comp.stop();
		destroy_sound_comp.play();
		await destroy_sound_comp.finished;
	elif destroy_sound_comp: # Without hit sound, just play kill sound
		destroy_sound_comp.play();
		await destroy_sound_comp.finished;
	elif hit_sound_comp: # Without kill sound, default to hit sound
		await hit_sound_comp.finished;

	self.queue_free();

func add_score(score:int):
	if is_editor: return
	process_score.emit(score)

func get_shader_brightness() -> float:
	return texture_sprite.material.get_shader_parameter("brightness");

func set_shader_brightness(value:float):
	value = clampf(value, -1, 1);
	texture_sprite.material.set_shader_parameter("brightness", value);

func get_texture_shader_color() -> Color:
	return texture_sprite.material.get_shader_parameter("to")

func set_texture_shader_color(color:Color, force:bool = false):
	texture_sprite.material.set_shader_parameter("to", color);
	if force: shader_color = color;

func tween_brightness(brightness:float, duration:float, reset_after:bool = false, looping:bool = false, step_delay:float = 0, loop_delay:float = 0):
	var tween:Tween = create_tween();
	var previous_brightness:float = get_shader_brightness();
	if looping: tween.set_loops();
	tween.tween_method(func(value): set_shader_brightness(value), previous_brightness, brightness, duration).set_delay(loop_delay);
	if reset_after:
		tween.tween_method(func(value): set_shader_brightness(value), brightness, previous_brightness, duration).set_delay(step_delay);

func tween_shader_shift_by(set_color:Color, duration:float, reset_after:bool = false, looping:bool = false, step_delay:float = 0, loop_delay:float = 0):
	var previous_color:Color = shader_color.clamp();
	var target_color:Color = shader_color + set_color;
	target_color = target_color.clamp();
	var tween:Tween = create_tween();
	if looping: tween.set_loops();
	#tween.tween_method(func(value): set_base_shader_color(value), previous_color, target_color, duration).set_delay(loop_delay);
	tween.tween_property(self, "shader_color", target_color, duration).set_delay(loop_delay);
	if reset_after:
		#tween.tween_method(func(value): set_base_shader_color(value), target_color, previous_color, duration).set_delay(step_delay);
		tween.tween_property(self, "shader_color", previous_color, duration).set_delay(step_delay);

func tween_shader_color(set_color:Color, duration:float, reset_after:bool = false, looping:bool = false, step_delay:float = 0, loop_delay:float = 0):
	var previous_color:Color = shader_color.clamp();#get_texture_shader_color();
	var tween:Tween = create_tween();
	if looping: tween.set_loops();
	tween.tween_method(func(value): set_texture_shader_color(value), previous_color, set_color, duration).set_delay(loop_delay);
	if reset_after:
		tween.tween_method(func(value): set_texture_shader_color(value), set_color, previous_color, duration).set_delay(step_delay);

func tween_size(new_scale:Vector2, duration:float, reset_after:bool = false, force:bool = false) -> bool:
	if tweening_size and not force: return false
	tweening_size = true
	
	var previous_scale:Vector2 = scale
	var tween = create_tween()
	await tween.tween_property(self, "scale", new_scale, duration).finished

	if reset_after:
		tween = create_tween()
		await tween.tween_property(self, "scale", previous_scale, duration).finished

	tweening_size = false
	return true

func set_texture_sprite(path:String, rescale:bool = false):
	var texture = load(path);
	if not texture:
		Logger.write(str("Texture path does not exist: ", path), "Brick");
		return;
	texture_sprite.texture = texture;
	texture_path = path;

	if not original_sprite_size:
		original_sprite_size = texture_sprite.texture.get_size();

	if rescale: rescale_sprite();
	texture_sprite.show();

func rescale_sprite():
	var textured_x = texture_sprite.texture.get_size().x;
	var textured_y = texture_sprite.texture.get_size().y;

	# Scale texture sprite to base sprite, covered, keeping aspect ratio
	# Scale up
	if original_sprite_size.x > textured_x:
		texture_sprite.texture_scale.x = textured_x / original_sprite_size.x * 2;
	if original_sprite_size.y > textured_y:
		texture_sprite.texture_scale.y = textured_y / original_sprite_size.y * 2;
	# Scale down
	if textured_x > original_sprite_size.x:
		texture_sprite.texture_scale.x = textured_x / original_sprite_size.x * 2;
	if textured_y > original_sprite_size.y:
		texture_sprite.texture_scale.y = textured_y / original_sprite_size.y * 2;
	# Reset scale
	if textured_x == original_sprite_size.x:
		texture_sprite.texture_scale.x = 2;
	if textured_y == original_sprite_size.y:
		texture_sprite.texture_scale.y = 2;
	# Recenter
	# texture_sprite.texture_offset.x = texture_sprite.texture.get_size().x / 2 / texture_sprite.texture_scale.x;
	# texture_sprite.texture_offset.y = texture_sprite.texture.get_size().y / 2 / texture_sprite.texture_scale.y;

	polygon_texture_scale = texture_sprite.texture_scale;
	polygon_texture_offset = texture_sprite.texture_offset;
	
