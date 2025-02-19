extends RigidBody2D
class_name Brick

@export var base_texture_path:String # Must be set
@export var texture_path:String # Must be set
@export var shader_color:Color = Color(1, 1, 1, 1)

@export var hitbox:Node2D
@export var base_sprite:Sprite2D
@export var texture_sprite:Sprite2D
@export var health_comp:HealthComponent
@export var score_comp:ScoreComponent
@export var hit_sound_comp:AudioStreamPlayer2D
@export var destroy_sound_comp:AudioStreamPlayer2D
@export var pickup_comp:PickupComponent
@export var editor_hitbox:EditorHitboxComponent

signal process_score(score:int)
signal spawn_pickup(global_position:Vector2, type:String, texture:String)
signal brick_destroyed()

@export var init_health:int = 1
@export var init_score:int = 10
@export var init_freeze:bool = true
@export var init_mass:int = 5

@export var is_editor:bool = true

var tweening_shader:bool = false
var tweening_size:bool = false

func setup(as_editable:bool = true):
	self.visible = true
	set_base_sprite(base_texture_path)

	freeze = init_freeze
	mass = init_mass

	if shader_color:
		texture_sprite.material.set_shader_parameter("to", shader_color)

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
		if init_score: score_comp.score = init_score;
		score_comp.process_score.connect(add_score.bind());

func setup_as_editable():
	self.editor_hitbox.add_child(self.hitbox.duplicate());

func hit(node):
	if is_editor: return
	if node.is_in_group('Ball'):
		if hit_sound_comp: hit_sound_comp.play()
		if health_comp: health_comp.damage(node.damage)
		
	if node.is_in_group('Bullet'):
		health_comp.damage(node.damage)

func die():
	if is_editor: return
	hitbox.disabled = true
	texture_sprite.hide()
	if score_comp: score_comp.emit_score()
	brick_destroyed.emit()

	if pickup_comp:
		spawn_pickup.emit(self.global_position, pickup_comp.pickup_type, pickup_comp.pickup_sprite)

	if destroy_sound_comp and hit_sound_comp: # Stop hit sound and play kill sound
		hit_sound_comp.stop()
		destroy_sound_comp.play()
		await destroy_sound_comp.finished
	elif destroy_sound_comp: # Without hit sound, just play kill sound
		destroy_sound_comp.play()
		await destroy_sound_comp.finished
	elif hit_sound_comp: # Without kill sound, default to hit sound
		await hit_sound_comp.finished

	self.queue_free()

func add_score(score:int):
	if is_editor: return
	process_score.emit(score)

func get_shader_color() -> Color:
	return texture_sprite.material.get_shader_parameter("to")

func set_shader_color(color:Color, force:bool = false):
	texture_sprite.material.set_shader_parameter("to", color);
	if force: shader_color = color;

func tween_shader_color(set_color:Color, duration:float, reset_after:bool = false, force:bool = false) -> bool:
	if tweening_shader and not force: return false
	tweening_shader = true
	
	var previous_color = get_shader_color()
	var tween = create_tween()
	await tween.tween_method(func(value): set_shader_color(value), previous_color, set_color, duration).finished

	if reset_after:
		tween = create_tween()
		await tween.tween_method(func(value): set_shader_color(value), set_color, previous_color, duration).finished

	tweening_shader = false
	return true

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

func set_base_sprite(path:String):
	if path.is_empty(): return
	base_sprite.texture = load(path)
	base_texture_path = path

	if texture_path: set_texture_sprite(texture_path)
	else: set_texture_sprite(path)

func set_texture_sprite(path:String):
	if path.is_empty(): return
	if base_texture_path.is_empty(): return
	texture_sprite.texture = load(path)
	texture_path = path
	texture_sprite.show();

	var base_x = base_sprite.texture.get_size().x #* base_sprite.scale.x
	var base_y = base_sprite.texture.get_size().y #* base_sprite.scale.y
	var textured_x = texture_sprite.texture.get_size().x #* texture_sprite.scale.x
	var textured_y = texture_sprite.texture.get_size().y #* texture_sprite.scale.y

	# Scale texture sprite to base sprite, covered, keeping aspect ratio
	# Scale up
	if base_x > textured_x or base_y > textured_y:
		if base_x > textured_x:
			texture_sprite.scale *= base_x / textured_x
		elif base_y > textured_y:
			texture_sprite.scale *= base_y / textured_y
	# Scale down
	if textured_x > base_x and textured_y > base_y:
		if textured_x > base_x:
			texture_sprite.scale *= textured_x / base_x
		elif textured_y > base_y:
			texture_sprite.scale *= textured_y / base_y
