extends Node2D
class_name TextureManager

@export var texture_sprite:Polygon2D;
@export var texture_path:String; # Must be set

@export var shader_color_count:int = 0;
var brick:Brick;

var shader_colors:Array[Color] = [Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 1)];
var shader_modulation:Color = Color(1,1,1,1);

@export var original_sprite_size := Vector2(0, 0);

var tweening_shader:bool = false;
var tweening_size:bool = false;

func setup():
	if not brick: return;
	texture_sprite.polygon = brick.polygon_array;
	texture_sprite.texture_offset = brick.polygon_texture_offset;
	texture_sprite.texture_scale = brick.polygon_texture_scale;

	if not load(texture_path):
		Logger.write(str("Texture path does not exist: ", texture_path), "Brick");
		return;
	set_texture_sprite(texture_path, false);
	rescale_sprite();
	self.visible = true;

	set_shader_color_count(shader_color_count);
	set_shader_color(1, shader_colors[0]);
	set_shader_color(2, shader_colors[1]);
	set_shader_color(3, shader_colors[2]);
	set_shader_color(4, shader_colors[3]);

func get_shader_brightness() -> float:
	return texture_sprite.material.get_shader_parameter("brightness");

func set_shader_brightness(value:float):
	value = clampf(value, -1, 1);
	texture_sprite.material.set_shader_parameter("brightness", value);

func get_shader_color_count() -> int:
	return texture_sprite.material.get_shader_parameter("color_count");

func set_shader_color_count(value:int):
	texture_sprite.material.set_shader_parameter("color_count", value);
	shader_color_count = value;

func get_shader_color(channel:int) -> Color:
	if channel < 1 or channel > 4: return Color(0,0,0,1);
	return texture_sprite.material.get_shader_parameter(str("target_color", channel));

func set_shader_color(channel:int, color:Color, store:bool = false):
	if channel < 1 or channel > 4: return;

	texture_sprite.material.set_shader_parameter(str("target_color", channel), color);
	if store:
		shader_colors[channel-1] = color;	

func tween_brightness(brightness:float, duration:float, reset_after:bool = false, looping:bool = false, step_delay:float = 0, loop_delay:float = 0):
	var tween:Tween = create_tween();
	var previous_brightness:float = get_shader_brightness();
	if looping: tween.set_loops();
	tween.tween_method(func(value): set_shader_brightness(value), previous_brightness, brightness, duration).set_delay(loop_delay);
	if reset_after:
		tween.tween_method(func(value): set_shader_brightness(value), brightness, previous_brightness, duration).set_delay(step_delay);

func tween_shader_shift_by(channel:int, set_color:Color, duration:float, reset_after:bool = false, looping:bool = false, step_delay:float = 0, loop_delay:float = 0):
	if shader_color_count <= 0: # Use modulate instead if texture has no custom colour support.
		tween_shader_modulation(set_color, duration, reset_after, looping, step_delay, loop_delay);
		return;
		
	if channel < 0 or channel > 4: return;
	var target_color:Color = (shader_colors[channel] + set_color).clamp();

	var tween:Tween = create_tween();
	if looping: tween.set_loops();

	if channel == 0: # All channels
		var previous_colors := shader_colors.duplicate();
		for i in range(1, 5):
			tween.tween_property(texture_sprite, str("target_color", i), target_color, duration).set_delay(loop_delay);
			if i < 4: tween.set_parallel();
		if reset_after:
			for i in range(1, 5):
				tween.tween_property(texture_sprite, str("target_color", i), previous_colors[i-1], duration).set_delay(step_delay);
				if i < 4: tween.set_parallel();
	else: # Specific channel
		var previous_color:Color = shader_colors[channel-1].clamp();
		tween.tween_property(texture_sprite, str("target_color", channel), target_color, duration).set_delay(loop_delay);
		if reset_after:
			tween.tween_property(texture_sprite, str("target_color", channel), previous_color, duration).set_delay(step_delay);

func tween_shader_color(channel:int, set_color:Color, duration:float, reset_after:bool = false, looping:bool = false, step_delay:float = 0, loop_delay:float = 0):
	if shader_color_count <= 0: # Use modulate instead if texture has no custom colour support.
		tween_shader_modulation(set_color, duration, reset_after, looping, step_delay, loop_delay);
		return;

	if channel < 0 or channel > 4: return;

	var tween:Tween = create_tween();
	if looping: tween.set_loops();

	if channel == 0: # All channels
		var previous_colors := shader_colors.duplicate();
		for i in range(1, 5):
			tween.tween_method(func(value): set_shader_color(i, value), previous_colors[i-1], set_color, duration).set_delay(loop_delay);
			if i < 4: tween.set_parallel();
		if reset_after:
			for i in range(1, 5):
				tween.tween_method(func(value): set_shader_color(i, value), set_color, previous_colors[i-1], duration).set_delay(step_delay);
				if i < 4: tween.set_parallel();
	else: # Specific channel
		var previous_color:Color = shader_colors[channel-1].clamp();
		tween.tween_method(func(value): set_shader_color(channel, value), previous_color, set_color, duration).set_delay(loop_delay);
		if reset_after:
			tween.tween_method(func(value): set_shader_color(channel, value), set_color, previous_color, duration).set_delay(step_delay);

func tween_shader_modulation(set_color:Color, duration:float, reset_after:bool = false, looping:bool = false, step_delay:float = 0, loop_delay:float = 0):
	var tween:Tween = create_tween();
	if looping: tween.set_loops();

	var previous_modulation := get_shader_modulation();
	tween.tween_method(func(value): set_shader_modulation(value), previous_modulation, set_color, duration).set_delay(loop_delay);
	if reset_after:
		tween.tween_method(func(value): set_shader_modulation(value), set_color, previous_modulation, duration).set_delay(step_delay);

func get_shader_modulation() -> Color:
	return texture_sprite.material.get_shader_parameter("modulate");

func set_shader_modulation(color:Color, store:bool = false):
	texture_sprite.material.set_shader_parameter("modulate", color);
	if store:
		shader_modulation = color;

func tween_size(new_scale:Vector2, duration:float, reset_after:bool = false, force:bool = false) -> bool:
	if tweening_size and not force: return false;
	tweening_size = true;
	
	var previous_scale:Vector2 = scale;
	var tween = create_tween();
	await tween.tween_property(brick, "scale", new_scale, duration).finished;

	if reset_after:
		tween = create_tween();
		await tween.tween_property(brick, "scale", previous_scale, duration).finished;

	tweening_size = false;
	return true;

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

	brick.polygon_texture_scale = texture_sprite.texture_scale;
	brick.polygon_texture_offset = texture_sprite.texture_offset;
