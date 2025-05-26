extends Node

var BrickScene = preload("uid://dtkn1xk6stg0v");

# Use in place of Brick.duplicate() in Godot 4.3+, can't duplicate nodes with dynamically added children.
func duplicate_bug_bypass(brick:Brick, as_editor:bool) -> Brick:
	var new_brick:Brick = BrickScene.instantiate();

	var temp_polygon = brick.texture_manager.texture_sprite.duplicate();
	new_brick.polygon_array = temp_polygon.polygon.duplicate();
	new_brick.polygon_texture_offset = temp_polygon.texture_offset;
	new_brick.polygon_texture_scale = temp_polygon.texture_scale;
	temp_polygon.queue_free();

	new_brick.hitbox_path = brick.hitbox_path;
	new_brick.texture_manager.texture_path = brick.texture_manager.texture_path;
	new_brick.texture_manager.shader_color_count = brick.texture_manager.shader_color_count;
	new_brick.texture_manager.shader_colors = brick.texture_manager.shader_colors.duplicate();

	new_brick.init_health = brick.init_health;
	new_brick.init_mass = brick.init_mass;
	new_brick.init_pushable = brick.init_pushable;
	new_brick.init_score = brick.init_score;
	new_brick.path_group = brick.path_group;
	new_brick.is_path_clone = brick.is_path_clone;
	new_brick.is_editor = brick.is_editor;
	
	new_brick.setup(as_editor);
	return new_brick;
