extends Node2D
class_name LevelEditor

var BrickScene = preload("uid://dtkn1xk6stg0v");
var GodotIcon = preload("uid://dj47yk43bh08r");
var PathPointVisual = preload("uid://bkbhsiv24h3ro");

var saving_level:bool = false
var loading_level:bool = false
var current_build_number:int = 2;

@export_group("Nodes")
@export var mouse_boundary:Area2D;
@export var world_border:WorldBorder;
@export var level_content:Node2D;
@export var level_content_bricks:Node2D;
@export var grid_drawer:Node2D;
@export var level_content_paths:Node2D;
@export var level_content_path_visuals:Node2D;

@export_group("Controls")
@export var selector:Container;
@export var level_name:LineEdit;
@export var save_button:Button;

@export_group("Tool buttons")
@export var place_tool:Button;
@export var paint_tool:Button;
@export var select_tool:Button;
@export var erase_tool:Button;
@export var path_tool:Button;
@export var snap_options_btn:Button;
#@export var data_options_btn:Button;

@export var mode_options:Control;

@export_group("Setting controls")
@export var brick_container:GridContainer;
@export var texture_container:Control;
var use_snap:bool = true;
var snap_cell_size:Vector2i = Vector2i(6, 10);
var snap_grid_offset:Vector2i = Vector2i(0, 0);
@export var data_options_ctrl:EditorDataSettings;
var apply_on_select:bool = false;
@export var path_options_ctrl:EditorPathSettings;
@export var snap_options_ctrl:EditorSnapSettings;


var level_num:String = "";
var campaign_num:String;
var campaign_path:String;
var brick_paths:Array = [];
var brick_paths_followers:Array = [];
var brick_paths_lines:Array = [];
var brick_paths_sprites:Array = [];
var brick_paths_transformers:Dictionary = {};

var can_place_bricks:bool = false;
var selected_brick_sample:Brick;
var active_brick_sample:Brick;
var selected_base_texture_path:String;
var selected_texture_path:String;
var selected_texture_shader:Color;

var selected_brick:Brick
var selected_path:Path2D;
var selected_line:Line2D;
var dragged_point:Node2D;

var collision_detected:bool
var illegal_collision_detected:bool

var current_tool:String = "place"

func _ready():
	mouse_boundary.mouse_entered.connect(on_mouse_enter_level_boundary);
	mouse_boundary.mouse_exited.connect(on_mouse_leave_level_boundary);
	mouse_boundary.input_event.connect(on_mouse_click);

	brick_container.set_active_res_signal.connect(set_active_res);
	texture_container.set_active_res_signal.connect(set_active_res);

	save_button.pressed.connect(save_level);

	selector.sort_children.connect(brick_container._on_root_control_sort_children);
	selector.sort_children.connect(texture_container._on_root_control_sort_children)

	place_tool.pressed.connect(set_tool.bind("place"));
	select_tool.pressed.connect(set_tool.bind("select"));
	paint_tool.pressed.connect(set_tool.bind("paint"));
	erase_tool.pressed.connect(set_tool.bind("erase"));
	path_tool.pressed.connect(set_tool.bind("path"));

	snap_options_btn.pressed.connect(set_tool.bind("snap"));
	snap_options_ctrl.use_snap_control.toggled.connect(set_snap);
	snap_options_ctrl.show_snap_grid.toggled.connect(set_snap_visibility);
	snap_options_ctrl.snap_width.value_changed.connect(set_snap_size.bind(0));
	snap_options_ctrl.snap_height.value_changed.connect(set_snap_size.bind(1));
	snap_options_ctrl.x_offset.value_changed.connect(set_snap_grid_offset.bind(0));
	snap_options_ctrl.y_offset.value_changed.connect(set_snap_grid_offset.bind(1));
	snap_cell_size = Vector2i(floor(snap_options_ctrl.snap_width.value), floor(snap_options_ctrl.snap_height.value));
	snap_grid_offset = Vector2i(floor(snap_options_ctrl.x_offset.value), floor(snap_options_ctrl.y_offset.value));
	use_snap = snap_options_ctrl.use_snap_control.button_pressed;

	#mode_options.mouse_entered.connect(on_mouse_enter_options);
	#mode_options.mouse_exited.connect(on_mouse_leave_options);

	data_options_ctrl.apply_brick_data_on_select_control.toggled.connect(set_apply_on_select);
	apply_on_select = data_options_ctrl.apply_brick_data_on_select_control.button_pressed;
	data_options_ctrl.brick_x_ctrl.value_changed.connect(func(value): if selected_brick: ui_set_brick_position(selected_brick, value, selected_brick.position.y));
	data_options_ctrl.brick_y_ctrl.value_changed.connect(func(value): if selected_brick: ui_set_brick_position(selected_brick, selected_brick.position.x, value));
	data_options_ctrl.brick_rot_ctrl.value_changed.connect(func(value): if selected_brick: ui_set_brick_rotation(selected_brick, value));
	data_options_ctrl.brick_path_group_control.value_changed.connect(on_select_path_group.bind(-1));

	path_options_ctrl.create_path_button.pressed.connect(on_create_path);
	path_options_ctrl.delete_path_button.pressed.connect(on_delete_path);
	path_options_ctrl.path_number.value_changed.connect(on_select_path.bind(-1));

	grid_drawer.size = mouse_boundary.get_child(0).shape.size;
	set_snap_size(snap_cell_size.x, 0);
	set_snap_size(snap_cell_size.y, 1);

	Logger.write(str("Ready."), "LevelEditor");

func set_tool(type:String):
	if loading_level or saving_level: return;
	if type not in ["place", "select", "paint", "erase", "path", "snap"]: return;

	if type in ["place", "select", "paint", "erase", "path"]:
		current_tool = type.to_lower();

	brick_container.hide();
	texture_container.hide();
	data_options_ctrl.hide();
	path_options_ctrl.hide();
	snap_options_ctrl.hide();

	match type.to_lower():
		"place":
			brick_container.show();
			on_select_path(-1);
		"select":
			data_options_ctrl.show();
			on_select_path(-1);
			get_tree().call_group("PathLineVisual", "show");
		"paint":
			texture_container.show();
			on_select_path(-1);
		"erase":
			on_select_path(-1);
		"path":
			on_select_path(path_options_ctrl.path_number.value, -1);
			path_options_ctrl.show();
		"snap":
			snap_options_ctrl.show();

func _process(_delta):
	if selected_brick:
		data_options_ctrl.brick_x_ctrl.call_deferred("set_value_no_signal", selected_brick.position.x);
		data_options_ctrl.brick_y_ctrl.call_deferred("set_value_no_signal", selected_brick.position.y);
		data_options_ctrl.brick_rot_ctrl.call_deferred("set_value_no_signal", selected_brick.rotation_degrees);

	if loading_level or saving_level: return
	if can_place_bricks and active_brick_sample:
		active_brick_sample.global_position = get_mouse_position_snapped();

	if dragged_point and Input.is_action_just_released("mouse_primary"):
		#Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW);
		release_drag_point();

	if dragged_point and can_place_bricks and selected_path and selected_line:
		#Input.set_custom_mouse_cursor(null, Input.CURSOR_DRAG); Doesn't work, not a priority.
		dragged_point.global_position = get_mouse_position_snapped();
		var idx:int = dragged_point.get_meta("point_idx");
		selected_path.curve.set_point_position(idx, get_mouse_position_snapped() - level_content.global_position);
		selected_line.set_point_position(idx, get_mouse_position_snapped() - level_content.global_position);

func set_snap(flag:bool):
	use_snap = flag;

func set_snap_visibility(flag:bool):
	grid_drawer.visible = flag;
	
func set_snap_size(amount:int, axis:int):
	snap_cell_size[axis] = amount# * 2;
	if axis == 0: grid_drawer.cell_width = amount# * 2;
	elif axis == 1: grid_drawer.cell_height = amount# * 2;
	grid_drawer.queue_redraw();

func set_snap_grid_offset(amount:int, axis:int):
	snap_grid_offset[axis] = amount# * 2;
	if axis == 0: grid_drawer.offset_x = amount# * 2;
	elif axis == 1: grid_drawer.offset_y = amount# * 2;
	grid_drawer.queue_redraw();

func set_apply_on_select(toggled_on:bool):
	apply_on_select = toggled_on
	if toggled_on:
		data_options_ctrl.brick_x_ctrl.editable = false
		data_options_ctrl.brick_y_ctrl.editable = false
		data_options_ctrl.brick_rot_ctrl.editable = false
	else:
		#data_options_ctrl.brick_x_ctrl.editable = true # Fix UI move issue first
		#data_options_ctrl.brick_y_ctrl.editable = true
		data_options_ctrl.brick_rot_ctrl.editable = true

func set_active_res(res = null):
	if res == null:
		selected_brick_sample = null;
		active_brick_sample = null;
		selected_texture_path = "";
		selected_texture_shader = Color(1, 1, 1, 1);
		texture_container.shader_color = Color(1, 1, 1, 1);
		return;

	if current_tool == "place":
		if selected_brick_sample:
			selected_brick_sample.queue_free();
			selected_brick_sample = null;
		
		var brick:Brick = BrickScene.instantiate();
		var temp_hitbox:Node2D = res.hitbox.instantiate();
		brick.hitbox = temp_hitbox;
		brick.add_child(temp_hitbox, true);
		temp_hitbox.owner = brick;
		brick.base_texture_path = res.texture_path;
		brick.setup(true);

		selected_base_texture_path = res.texture_path;
		selected_texture_path = "";
		selected_brick_sample = brick;
		selected_brick = brick;
		selected_texture_shader = Color(1, 1, 1, 1);

	if current_tool == "paint":
		selected_texture_path = res.trim_suffix(".remap");
		selected_texture_shader = Color(1, 1, 1, 1);

func on_create_path():
	var path := Path2D.new();
	path.curve = Curve2D.new();
	brick_paths.append(path);
	level_content_paths.add_child(path);
	path.owner = level_content;

	var path_follow := PathFollow2D.new();
	path_follow.rotates = false;
	path_follow.loop = false; # TODO parametrize
	brick_paths_followers.append(path_follow);
	path.add_child(path_follow);
	path_follow.owner = level_content;

	var line := Line2D.new();
	line.add_to_group("PathLineVisual");
	brick_paths_lines.append(line);
	level_content_path_visuals.add_child(line);
	line.owner = level_content;

	brick_paths_sprites.append([]);

	path_options_ctrl.path_number.max_value += 1;
	data_options_ctrl.brick_path_group_control.max_value += 1;
	path_options_ctrl.path_number.set_value_no_signal(brick_paths.size());

	on_select_path(brick_paths.size() - 1);

func on_delete_path():
	if brick_paths.size() == 0: return;
	var idx = floor(path_options_ctrl.path_number.value) - 1;
	if idx < 0: return;

	for point in brick_paths_sprites[idx]: point.queue_free();
	brick_paths_sprites.remove_at(idx);
	brick_paths_followers.remove_at(idx);
	path_options_ctrl.path_number.set_value_no_signal(idx);

	reallocate_path_groups(idx);

	path_options_ctrl.path_number.max_value -= 1;
	data_options_ctrl.brick_path_group_control.max_value -= 1;

	if path_options_ctrl.path_number.value <= 0: on_select_path(-1);
	else: on_select_path(path_options_ctrl.path_number.value, -1);

	brick_paths[idx].queue_free();
	brick_paths.remove_at(idx);
	brick_paths_lines[idx].queue_free();
	brick_paths_lines.remove_at(idx);

func on_select_path(value:float, offset:int = 0):
	var idx:int = floor(value + offset);

	get_tree().call_group("PathPointVisual", "hide");
	get_tree().call_group("PathLineVisual", "hide");

	if idx < 0:
		selected_path = null;
		selected_line = null;
		return;

	selected_path = brick_paths[idx];
	selected_line = brick_paths_lines[idx];
	brick_paths_lines[idx].show();
	for point in brick_paths_sprites[idx]:
		point.show();

func reallocate_path_groups(deleted_idx:int):
	for brick:Brick in get_tree().get_nodes_in_group("Brick"):
		if brick.path_group == deleted_idx:
			brick.path_group = -1;
			brick.reparent(level_content_bricks);
			var transformer:RemoteTransform2D = brick_paths_transformers.find_key(brick);
			if transformer:
				brick_paths_transformers.erase(transformer);
				transformer.queue_free();
		if brick.path_group > deleted_idx:
			brick.path_group -= 1;

func release_drag_point():
	if not dragged_point or not selected_path: return;
	dragged_point = null;

func on_select_path_group(value:float, offset:int = 0, force_select:bool = false):
	var idx:int = floor(value + offset);

	# Enabling apply on select and then changing the path group SpinBox
	# would trigger this method on the currently selected brick, so it must be filtered.
	if apply_on_select and not force_select: return;

	if idx < 0 and selected_brick:
		var to_remove:RemoteTransform2D = brick_paths_transformers.find_key(selected_brick);
		brick_paths_transformers.erase(to_remove);
		to_remove.get_child(0).get_child(0).reparent(level_content_bricks); # Get offset node and then the Brick inside it.
		to_remove.queue_free();
		return;

	var remote_transform := RemoteTransform2D.new();
	brick_paths_followers[idx].add_child(remote_transform);
	remote_transform.global_position = get_mouse_position_snapped();
	remote_transform.update_scale = false;
	remote_transform.update_rotation = false;
	remote_transform.owner = level_content;

	var remote_offset:Node2D = Node2D.new();
	remote_transform.add_child(remote_offset);
	remote_offset.owner = level_content;
	brick_paths_transformers[remote_transform] = remote_offset;

	remote_transform.remote_path = get_path_to(selected_brick);

	selected_brick.reparent(remote_offset);
	selected_brick.path_group = idx; # TODO remove previous transform !!!

func on_mouse_click(_viewport:Node, input:InputEvent, _shape_idx:int):
	if loading_level or saving_level: return
	if current_tool == "place":

		if input.is_action_pressed("mouse_primary"):
			if selected_brick_sample == null or active_brick_sample == null: return;
			if illegal_collision_detected: return;
			if collision_detected and not Input.is_action_pressed('shift'): return;

			var new_brick:Brick
			if selected_brick: new_brick = duplicate_bug_bypass(selected_brick);
			else: new_brick = duplicate_bug_bypass(selected_brick_sample);#selected_brick_sample.duplicate();#BrickScene.instantiate();
			#new_brick.set_base_sprite(selected_texture_path);
			level_content_bricks.add_child(new_brick);

			new_brick.editor_hitbox.illegal_collision_detected.connect(func(): illegal_collision_detected = true);
			new_brick.editor_hitbox.illegal_collision_freed.connect(func(): illegal_collision_detected = false);

			new_brick.owner = level_content;
			new_brick.global_position = active_brick_sample.global_position;
			
			new_brick.health_comp.health = floor(data_options_ctrl.brick_health_control.value);
			new_brick.score_comp.score = floor(data_options_ctrl.brick_score_control.value);
			new_brick.freeze = not data_options_ctrl.brick_pushable_control.button_pressed;
			new_brick.mass = data_options_ctrl.brick_weight_control.value;

			selected_brick = new_brick;
			refresh_brick_data_controls(selected_brick);
		return;

	if current_tool == "select":
		if input.is_action_pressed("mouse_primary"):
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsPointQueryParameters2D.new()
			query.position = get_global_mouse_position()
			query.collision_mask = 4 # bits
			var result = space_state.intersect_point(query)
			
			if result.size() > 0:
				selected_brick = result[0].collider;
				selected_brick_sample = duplicate_bug_bypass(selected_brick); # Make a "Use selected" button instead.

				if apply_on_select:
					selected_brick.init_health = floor(data_options_ctrl.brick_health_control.value);
					selected_brick.init_score = floor(data_options_ctrl.brick_score_control.value);
					selected_brick.init_freeze = not data_options_ctrl.brick_pushable_control.button_pressed;
					selected_brick.init_mass = floor(data_options_ctrl.brick_weight_control.value);
					selected_brick.path_group = floor(data_options_ctrl.brick_path_group_control.value) - 1;
					on_select_path_group(floor(data_options_ctrl.brick_path_group_control.value) - 1, 0, true);
					if data_options_ctrl.brick_can_collide_control.button_pressed:
						selected_brick.collision_mask = 12;
					else:
						selected_brick.collision_mask = 8;
					
					#selected_brick.tween_shader_color(Color(1, 1, 1, 0), 0.2, true) # Bad, current shader ignores Alpha
					selected_brick.tween_size(Vector2(0.7, 0.7), 0.1, true);
				else:
					refresh_brick_data_controls(selected_brick);

				selected_texture_shader = selected_brick.shader_color;
				if selected_brick.texture_path: selected_texture_path = selected_brick.texture_path;
		#if Input.is_action_pressed("mouse_primary"):
		return;

	if current_tool == "paint":
		if input.is_action_pressed("mouse_primary"):
			if selected_texture_path.is_empty(): return
			
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsPointQueryParameters2D.new()
			query.position = get_global_mouse_position()
			query.collision_mask = 4
			var result = space_state.intersect_point(query)
			
			if result.size() > 0:
				result[0].collider.set_texture_sprite(selected_texture_path);
				result[0].collider.set_shader_color(texture_container.shader_color, true);
				selected_texture_shader = texture_container.shader_color;
		elif input.is_action_just_pressed("mouse_secondary"):
			return # hue shift shader here maybe?
		return;

	if current_tool == "erase":
		if input.is_action_pressed("mouse_primary"):
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsPointQueryParameters2D.new()
			query.position = get_global_mouse_position()
			query.collision_mask = 4
			var result = space_state.intersect_point(query)
			
			if result.size() > 0:
				selected_brick = null
				result[0].collider.queue_free()
		return;

	if current_tool == "path":
		# Drag point
		if input.is_action_pressed("mouse_primary") and selected_path and can_place_bricks:
			if Input.is_action_pressed("shift"):
				# Start point drag
				var space_state = get_world_2d().direct_space_state
				var query = PhysicsPointQueryParameters2D.new();
				query.position = get_global_mouse_position();
				query.collision_mask = 2048; # bits
				var result = space_state.intersect_point(query);

				if result.size() > 0:
					dragged_point = result[0].collider;
			else:
				# Add point
				var mouse_pos:Vector2 = get_mouse_position_snapped();
				selected_path.curve.add_point(mouse_pos - level_content.global_position);
				selected_line.add_point(mouse_pos - level_content.global_position);

				var point:Node2D = PathPointVisual.instantiate();
				point.set_meta("point_idx", selected_path.curve.point_count - 1);
				brick_paths_sprites[path_options_ctrl.path_number.value - 1].append(point);
				level_content_path_visuals.add_child(point);
				point.global_position = mouse_pos;
				point.owner = level_content;	
			return;			

		# Delete point
		if input.is_action_pressed("mouse_secondary") and selected_path:
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsPointQueryParameters2D.new();
			query.position = get_global_mouse_position();
			query.collision_mask = 2048; # bits
			var result = space_state.intersect_point(query);

			if result.size() > 0:
				var remove_idx:int = result[0].collider.get_meta("point_idx");
				
				for i:int in range(remove_idx + 1, selected_path.curve.point_count):
					brick_paths_sprites[path_options_ctrl.path_number.value - 1][i].set_meta("point_idx", i - 1);
					
				brick_paths_sprites[path_options_ctrl.path_number.value - 1].remove_at(remove_idx);
				selected_path.curve.remove_point(remove_idx);
				selected_line.remove_point(remove_idx);
				result[0].collider.queue_free();

				if selected_path.curve.point_count == 0:
					on_delete_path();
			return;

func on_mouse_enter_level_boundary():
	can_place_bricks = true

	if current_tool == "place": 
		if selected_brick:
			active_brick_sample = duplicate_bug_bypass(selected_brick);#selected_brick.duplicate();
		elif selected_brick_sample:
			active_brick_sample = duplicate_bug_bypass(selected_brick_sample);#selected_brick_sample.duplicate();#BrickScene.instantiate();
		else: return;

		level_content.add_child(active_brick_sample);
		#active_brick_sample.set_base_sprite(selected_base_texture_path);

		active_brick_sample.editor_hitbox.collision_detected.connect(func(): collision_detected = true);
		active_brick_sample.editor_hitbox.collision_freed.connect(func(): collision_detected = false);
		active_brick_sample.editor_hitbox.illegal_collision_detected.connect(func(): illegal_collision_detected = true);
		active_brick_sample.editor_hitbox.illegal_collision_freed.connect(func(): illegal_collision_detected = false);
		active_brick_sample.editor_hitbox.tree_exited.connect(reset_brick_collision_state);

func on_mouse_leave_level_boundary():
	can_place_bricks = false;
	if active_brick_sample:
		active_brick_sample.queue_free();
		active_brick_sample = null;
	if dragged_point:
		release_drag_point();

var tween_options:Tween
func on_mouse_enter_options():
	var target_pos:float = get_viewport_rect().size.y - mode_options.size.y;

	if tween_options: tween_options.kill();
	tween_options = get_tree().create_tween();
	tween_options.tween_property(mode_options, "position", Vector2(mode_options.position.x, target_pos), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE);
	
func on_mouse_leave_options():
	if tween_options: tween_options.kill();
	tween_options = get_tree().create_tween();
	tween_options.tween_property(mode_options, "position", Vector2(mode_options.position.x, 996), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE);

func get_mouse_position_snapped() -> Vector2:
	var snap_to_x:float;
	var snap_to_y:float;
	if use_snap:
		@warning_ignore("integer_division")
		snap_to_x = (floori(get_global_mouse_position().x) / (snap_cell_size.x)) * (snap_cell_size.x) + 3;
		@warning_ignore("integer_division")
		snap_to_y = (floori(get_global_mouse_position().y) / (snap_cell_size.y)) * (snap_cell_size.y);
	else:
		@warning_ignore("integer_division")
		snap_to_x = floori(get_global_mouse_position().x);
		@warning_ignore("integer_division")
		snap_to_y = floori(get_global_mouse_position().y);
	return Vector2(snap_to_x, snap_to_y);

func refresh_brick_data_controls(brick:Brick):
	data_options_ctrl.brick_x_ctrl.set_value_no_signal(brick.position.x);
	data_options_ctrl.brick_y_ctrl.set_value_no_signal(brick.position.y);
	data_options_ctrl.brick_rot_ctrl.set_value_no_signal(brick.rotation_degrees);
	data_options_ctrl.brick_health_control.set_value_no_signal(brick.init_health);
	data_options_ctrl.brick_score_control.set_value_no_signal(brick.init_score);
	data_options_ctrl.brick_pushable_control.set_pressed_no_signal(not brick.init_freeze);
	data_options_ctrl.brick_weight_control.set_value_no_signal(brick.init_mass);
	data_options_ctrl.brick_path_group_control.set_value_no_signal(brick.path_group + 1);
	if brick.collision_mask == 8:
		data_options_ctrl.brick_can_collide_control.set_pressed_no_signal(false);
	elif brick.collision_mask == 12:
		data_options_ctrl.brick_can_collide_control.set_pressed_no_signal(true);

func ui_set_brick_position(brick:Brick, x:float, y:float) -> bool:
	# Needs collision logic rework
	var rollback:Vector2 = brick.position

	brick.position = Vector2(x, y)
	print(brick.position)
	await get_tree().physics_frame
	await get_tree().process_frame
	print(brick.position)

	if illegal_collision_detected: # Brick gets stuck because it leaves the wall collision after this function executes, resetting the brick back inside the wall.
		brick.position = rollback
		print("err")
		return false
	print("ok")
	return true

func ui_set_brick_rotation(brick:Brick, rot:float) -> bool:
	var rollback:float = brick.rotation_degrees

	brick.rotation_degrees = rot

	if illegal_collision_detected:
		brick.rotation_degrees = rollback
		return false
	return true

func reset_brick_collision_state():
	collision_detected = false
	illegal_collision_detected = false

func load_level(level_folder:String):
	Logger.write(str("Loading level from ", level_folder), "LevelEditor");
	loading_level = true
	var Level:PackedScene = load(campaign_path + "/" + campaign_num + "/" + level_folder + "/level.tscn")
	var loaded_level_content = Level.instantiate()

	var level_data:LevelData = load(campaign_path + "/" + campaign_num + "/" + level_folder + "/data.tres")
	level_name.text = level_data.name

	level_content.free()

	loaded_level_content.name = "LevelContent";
	$LevelEditor.add_child(loaded_level_content, true);
	level_content = loaded_level_content;
	level_content_bricks = level_content.find_child("Bricks");
	level_content_paths = level_content.find_child("BrickPaths").find_child("Paths");
	level_content_path_visuals = level_content.find_child("BrickPaths").find_child("Visuals");

	Logger.write(str("Initializing Bricks."), "LevelEditor");
	for brick in level_content_bricks.get_children():
		brick.setup(true);

	level_num = level_folder
	loading_level = false

func save_level():
	if level_name.text.is_empty():
		level_name.call_deferred("grab_focus");
		return;
	Logger.write(str("Saving level."), "LevelEditor");
	saving_level = true;

	var new_level:PackedScene = PackedScene.new();

	level_content_bricks.owner = level_content;
	level_content.find_child("BrickPaths").owner = level_content;
	level_content_paths.owner = level_content;
	level_content_path_visuals.owner = level_content;
	for brick:Brick in get_tree().get_nodes_in_group("Brick"):
		brick.owner = level_content;
		brick.hitbox.owner = level_content;
	
	Logger.write(str("Packing Scene."), "LevelEditor");
	new_level.pack(level_content);

	level_content_path_visuals.hide();
	#mode_options.hide();
	set_snap_visibility(false);
	await get_tree().create_timer(0.25).timeout; # Give the UI time to hide.

	var region = Rect2(world_border.wall_left.global_position.x, 0, world_border.wall_right.global_position.x - world_border.wall_left.global_position.x, $LevelEditor/LevelMouseBoundary/CollisionShape2D.shape.size.y)
	var screenshot:Image = get_viewport().get_texture().get_image().get_region(region)

	# Compress capture
	@warning_ignore("integer_division")
	screenshot.resize(screenshot.get_size().x / 4, screenshot.get_size().y / 4, Image.INTERPOLATE_LANCZOS) # Important !!!
	var buffer:PackedByteArray = screenshot.save_webp_to_buffer(true)
	var thumb:Image = Image.new()
	thumb.load_webp_from_buffer(buffer)

	var level_data:LevelData = LevelData.new();

	if level_num:
		Logger.write(str("Replacing level ", level_num), "LevelEditor");
		var dir = campaign_path + "/" + campaign_num + "/" + level_num + "/";

		level_data = load(dir + "data.tres"); # Load existing data.
		level_data.thumbnail = ImageTexture.create_from_image(thumb);
		level_data.name = level_name.text 
		if level_data.build_number != current_build_number:
			upgrade_version(level_data);
		level_data.build_number = current_build_number;
		
		FileManager.add_level(campaign_num, new_level, level_data, true, level_num);
	else:
		level_data.name = level_name.text;
		level_data.thumbnail = ImageTexture.create_from_image(thumb);
		level_data.build_number = current_build_number;

		FileManager.add_level(campaign_num, new_level, level_data);

	go_back();
	#saving_level = false

func go_back():
	Logger.write(str("Exiting editor."), "LevelEditor");
	var MainScene:PackedScene = load("uid://c0a7y1ep5uibb")
	var main_scene = MainScene.instantiate()
	add_sibling(main_scene)
	queue_free()

# Use in place of Brick.duplicate() in Godot 4.3, can't duplicate nodes with dynamically added children.
func duplicate_bug_bypass(brick:Brick) -> Brick:
	#var new_brick:Brick = brick.duplicate( DUPLICATE_GROUPS | DUPLICATE_SCRIPTS | DUPLICATE_SIGNALS );
	#for child in brick.get_children():
	#	print(child)
	#	new_brick.add_child(child.duplicate());
	var new_brick:Brick = BrickScene.instantiate();
	var new_hitbox = brick.hitbox.duplicate();
	new_brick.hitbox = new_hitbox;
	new_brick.add_child(new_hitbox, true);
	new_hitbox.owner = new_brick;
	new_brick.base_texture_path = brick.base_texture_path;
	if selected_texture_path: new_brick.texture_path = selected_texture_path;
	if selected_texture_shader: new_brick.shader_color = selected_texture_shader;
	new_brick.setup(true);
	return new_brick;

func upgrade_version(data:LevelData):
	var from_version:int = data.build_number;
	if from_version >= current_build_number:
		var err = ResourceSaver.save(data, campaign_path + campaign_num + "/" + level_num + "/data.tres");
		if err != OK:
			print("Level data save error: " + error_string(err));
			ResourceSaver.save(data, campaign_path + campaign_num + "/" + level_num + "/data.tres");

		var modified_level_content:PackedScene = PackedScene.new();
		modified_level_content.pack(level_content);
		err = ResourceSaver.save(modified_level_content, campaign_path + campaign_num + "/" + level_num + "/level.tscn");
		if err != OK:
			print("Level scene save error: " + error_string(err));
			ResourceSaver.save(modified_level_content, campaign_path + campaign_num + "/" + level_num + "/level.tscn");
		return;

	match from_version:
		# Default pre-release
		1:
			# Add Bricks container and reparent bricks from LevelContent
			var new_level_content_bricks := Node2D.new();
			new_level_content_bricks.name = "Bricks";
			level_content.add_child(new_level_content_bricks, true);
			new_level_content_bricks.owner = level_content;

			for node:Brick in get_tree().get_nodes_in_group("Brick"):
				node.reparent(new_level_content_bricks);

			# Add BrickPaths container
			var new_level_content_brick_paths := Node2D.new();
			new_level_content_brick_paths.name = "BrickPaths";
			level_content.add_child(new_level_content_brick_paths, true);
			new_level_content_brick_paths.owner = level_content;

			# Add Paths container
			var new_level_content_paths := Node2D.new();
			new_level_content_paths.name = "Paths";
			new_level_content_brick_paths.add_child(new_level_content_paths, true);
			new_level_content_paths.owner = level_content;

			# Add Visuals container
			var new_level_content_path_visuals := Node2D.new();
			new_level_content_path_visuals.name = "Visuals";
			new_level_content_brick_paths.add_child(new_level_content_path_visuals, true);
			new_level_content_path_visuals.owner = level_content;
			
	data.build_number += 1;
	Logger.write(str("Upgraded to build ", data.build_number, ", checking for further steps."), "LevelEditor");
	upgrade_version(data);
