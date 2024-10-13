extends RigidBody2D
class_name Brick

@export var base_texture_path:String # Must be set
@export var texture_path:String # Must be set
@export var shader_color:Color = Color(1, 1, 1)

var hitbox:CollisionPolygon2D
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

var tweening_shader:bool = false
var tweening_size:bool = false

func _ready():
	set_base_sprite(base_texture_path)
		
	if shader_color:
		texture_sprite.material.set_shader_parameter("to", shader_color)

	if health_comp:
		if init_health: health_comp.health = init_health
		health_comp.health_depleted.connect(die.bind())

	if score_comp:
		if init_score: score_comp.score = init_score
		score_comp.process_score.connect(add_score.bind())

	mass = init_mass
	freeze = init_freeze

func hit(node):
	if node.is_in_group('Ball'):
		if hit_sound_comp: hit_sound_comp.play()
		if health_comp: health_comp.damage(node.damage)
		
	if node.is_in_group('Bullet'):
		health_comp.damage(node.damage)

func die():
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
	process_score.emit(score)

func get_shader_color() -> Color:
	return texture_sprite.material.get_shader_parameter("to")

func set_shader_color(color:Color):
	texture_sprite.material.set_shader_parameter("to", color)

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

# https://github.com/kevinthompson/godot-generate-polygon-from-sprite-tool/blob/main/godot4/sprite_to_collision_polygon.gd
func _create_collision_polygon():
	# Assume Sprite2D with texture and StaticBody2D exist
	var sprite = base_sprite

	# Generate Bitmap from Sprite2D
	var image = sprite.texture.get_image()
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(image)

	# Convert Bitmap to Polygons
	var polys = bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, image.get_size()), 0.1) # Last int dictates accuracy
	
	# Create CollisionPolygon2D Nodes from Polygons
	for poly in polys:
		var collision_polygon = CollisionPolygon2D.new()
		collision_polygon.polygon = _center_collision_polygon(poly, sprite)
		self.add_child(collision_polygon)
		collision_polygon.set_owner(self)
		#collision_polygon.position -= sprite.texture.get_size() / 2
		hitbox = collision_polygon

		var editor_collision_polygon = collision_polygon.duplicate()
		editor_hitbox.add_child(editor_collision_polygon)

# Fix to _create_collision_polygon() not working right on centered sprites
func _center_collision_polygon(poly:PackedVector2Array, sprite:Sprite2D):
	var adjusted_polys = []
	var regex:RegEx = RegEx.new()
	regex.compile("\\d+, \\d+")
	for match in regex.search_all(str(poly)):
		var x:int = match.get_string().split(", ", false)[0].to_int() - floor(sprite.texture.get_size().x / 2)
		var y:int = match.get_string().split(", ", false)[1].to_int() - floor(sprite.texture.get_size().y / 2)
		adjusted_polys.append(Vector2i(x, y))
	return PackedVector2Array(adjusted_polys)

func set_base_sprite(path:String):
	if path.is_empty(): return
	base_sprite.texture = load(path)
	base_texture_path = path
	_create_collision_polygon()

	if texture_path: set_texture_sprite(texture_path)
	else: set_texture_sprite(path)

func set_texture_sprite(path:String):
	if path.is_empty(): return
	if base_texture_path.is_empty(): return
	texture_sprite.texture = load(path)
	texture_path = path

	var base_x = base_sprite.texture.get_size().x * base_sprite.scale.x
	var base_y = base_sprite.texture.get_size().y * base_sprite.scale.y
	var textured_x = texture_sprite.texture.get_size().x * texture_sprite.scale.x
	var textured_y = texture_sprite.texture.get_size().y * texture_sprite.scale.y

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
