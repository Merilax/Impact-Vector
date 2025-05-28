extends RigidBody2D
class_name Brick

@export_group("Nodes")
@export var hitbox:Node2D;
@export var texture_manager:TextureManager;
@export var health_comp:HealthComponent;
@export var score_comp:ScoreComponent;
@export var hit_sound_comp:AudioStreamPlayer2D;
@export var destroy_sound_comp:AudioStreamPlayer2D;
@export var pickup_comp:PickupComponent;
@export var editor_hitbox:EditorHitboxComponent;

@export_group("Data")
@export var hitbox_path:String; # Must be set
@export var init_health:float = 1;
@export var init_score:float = 10;
@export var init_pushable:bool = false;
@export var init_mass:float = 5;
@export var can_collide:bool = false;
@export var scoreable:bool = true;
@export var is_indestructible:bool = false;
@export var is_path_clone:bool = false;
@export var path_group:int = -1;
@export var spin_group:int = -1;
@export var is_editor:bool = true;

@export var polygon_array:PackedVector2Array;
@export var polygon_texture_offset:Vector2;
@export var polygon_texture_scale:Vector2;

@export var texture_type:String;

signal process_score(score:int);
signal spawn_pickup(global_position:Vector2, type:String, texture:String);
signal brick_destroyed(brick:Brick);

func setup(as_editable:bool = true):
	texture_manager.brick = self;
	texture_manager.setup(); 

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
	texture_manager.tween_brightness(-.2, .3, true, true, 0, 0.5);

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
	self.collision_layer = 0;
	self.collision_mask = 0;
	texture_manager.texture_sprite.hide();
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
