extends Node2D
class_name LevelEditor

var BrickScene = preload("uid://dtkn1xk6stg0v")

var saving_level:bool = false
var loading_level:bool = false
var current_build_numer:int = 1;

@export var mouse_boundary:Area2D
@export var world_border:WorldBorder
@export var level_content:Node2D
@export var grid_drawer:Node2D

@export var place_tool:Button
@export var select_tool:Button
@export var paint_tool:Button
@export var erase_tool:Button

@export var mode_options:Control

@export var snap_options_ctrl:Control
@export var snap_options_btn:Button
@export var use_snap_control:Button
@export var show_snap_grid:Button
@export var snap_width:SpinBox
@export var snap_height:SpinBox
@export var x_offset:SpinBox
@export var y_offset:SpinBox
var use_snap:bool = true
var snap_cell_size:Vector2i = Vector2i(6, 10);
var snap_grid_offset:Vector2i = Vector2i(0, 0);

@export var data_options_ctrl:Control
@export var data_options_btn:Button
@export var apply_brick_data_on_select_control:CheckButton
@export var brick_x_ctrl:SpinBox
@export var brick_y_ctrl:SpinBox
@export var brick_rot_ctrl:SpinBox
@export var brick_health_control:SpinBox
@export var brick_score_control:SpinBox
@export var brick_pushable_control:CheckBox
@export var brick_weight_control:SpinBox
@export var brick_can_collide_control:CheckBox
# @export var brick_hit_sound:Control
# @export var brick_kill_sound:Control
var apply_on_select:bool = false

@export var brick_container:GridContainer
@export var texture_container:Control

@export var level_name:LineEdit
@export var save_button:Button

var level_num:String = ""
var campaign_num:String
var campaign_path:String

var can_place_bricks:bool = false
var selected_brick_sample:Brick
var active_brick_sample:Brick
var selected_base_texture_path:String
var selected_texture_path:String
var selected_texture_shader:Color

var selected_brick:Brick

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

	place_tool.pressed.connect(set_tool.bind("place"));
	select_tool.pressed.connect(set_tool.bind("select"));
	paint_tool.pressed.connect(set_tool.bind("paint"));
	erase_tool.pressed.connect(set_tool.bind("erase"));

	snap_options_btn.pressed.connect(show_options.bind("snap"));
	use_snap_control.toggled.connect(set_snap);
	show_snap_grid.toggled.connect(set_snap_visibility);
	snap_width.value_changed.connect(set_snap_size.bind(0));
	snap_height.value_changed.connect(set_snap_size.bind(1));
	x_offset.value_changed.connect(set_snap_grid_offset.bind(0));
	y_offset.value_changed.connect(set_snap_grid_offset.bind(1));
	snap_cell_size = Vector2i(floor(snap_width.value), floor(snap_height.value));
	snap_grid_offset = Vector2i(floor(x_offset.value), floor(y_offset.value));
	use_snap = use_snap_control.button_pressed;

	mode_options.mouse_entered.connect(on_mouse_enter_options);;
	mode_options.mouse_exited.connect(on_mouse_leave_options);;

	data_options_btn.pressed.connect(show_options.bind("data"));
	apply_brick_data_on_select_control.toggled.connect(set_apply_on_select);
	apply_on_select = apply_brick_data_on_select_control.button_pressed;
	brick_x_ctrl.value_changed.connect(func(value): if selected_brick: ui_set_brick_position(selected_brick, value, selected_brick.position.y));
	brick_y_ctrl.value_changed.connect(func(value): if selected_brick: ui_set_brick_position(selected_brick, selected_brick.position.x, value));
	brick_rot_ctrl.value_changed.connect(func(value): if selected_brick: ui_set_brick_rotation(selected_brick, value));

	grid_drawer.size = mouse_boundary.get_child(0).shape.size;
	set_snap_size(snap_cell_size.x, 0);
	set_snap_size(snap_cell_size.y, 1);

func set_tool(type:String):
	if loading_level or saving_level: return
	match type.to_lower():
		"place":
			current_tool = type.to_lower()
			brick_container.show()
			texture_container.hide()
		"select":
			current_tool = type.to_lower()
			brick_container.hide()
			texture_container.hide()
		"paint":
			current_tool = type.to_lower()
			brick_container.hide()
			texture_container.show()
		"erase":
			current_tool = type.to_lower()
			brick_container.hide()
			texture_container.hide()

func _process(_delta):
	if selected_brick:
		brick_x_ctrl.call_deferred("set_value_no_signal", selected_brick.position.x)
		brick_y_ctrl.call_deferred("set_value_no_signal", selected_brick.position.y)
		brick_rot_ctrl.call_deferred("set_value_no_signal", selected_brick.rotation_degrees)

	if loading_level or saving_level: return
	if can_place_bricks and active_brick_sample:
		var snap_to_x:float;
		var snap_to_y:float;
		if use_snap:
			@warning_ignore("integer_division")
			snap_to_x = (floori(get_global_mouse_position().x) / (snap_cell_size.x)) * (snap_cell_size.x) + 3;
			@warning_ignore("integer_division")
			snap_to_y = (floori(get_global_mouse_position().y) / (snap_cell_size.y)) * (snap_cell_size.y);
			active_brick_sample.global_position = Vector2(snap_to_x, snap_to_y);
		else:
			@warning_ignore("integer_division")
			snap_to_x = floori(get_global_mouse_position().x);
			@warning_ignore("integer_division")
			snap_to_y = floori(get_global_mouse_position().y);
		active_brick_sample.global_position = Vector2(snap_to_x, snap_to_y);

func show_options(what:String):
	if loading_level or saving_level: return
	match what.to_lower():
		"snap":
			data_options_ctrl.hide();
			snap_options_ctrl.show();
		"data":
			snap_options_ctrl.hide();
			data_options_ctrl.show();

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
		brick_x_ctrl.editable = false
		brick_y_ctrl.editable = false
		brick_rot_ctrl.editable = false
	else:
		#brick_x_ctrl.editable = true # Fix UI move issue first
		#brick_y_ctrl.editable = true
		brick_rot_ctrl.editable = true

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

func on_mouse_click(_viewport:Node, input:InputEvent, _shape_idx:int):
	if loading_level or saving_level: return
	if current_tool == "place":	
		if input.is_action_pressed("mouse_primary"):
			if selected_brick_sample == null or active_brick_sample == null: return
			if illegal_collision_detected: return
			if collision_detected and not Input.is_action_pressed('shift'): return

			var new_brick:Brick
			if selected_brick: new_brick = duplicate_bug_bypass(selected_brick);
			else: new_brick = duplicate_bug_bypass(selected_brick_sample);#selected_brick_sample.duplicate();#BrickScene.instantiate()
			#new_brick.set_base_sprite(selected_texture_path)
			level_content.add_child(new_brick)

			new_brick.editor_hitbox.illegal_collision_detected.connect(func(): illegal_collision_detected = true)
			new_brick.editor_hitbox.illegal_collision_freed.connect(func(): illegal_collision_detected = false)

			new_brick.owner = level_content
			new_brick.global_position = active_brick_sample.global_position
			
			new_brick.health_comp.health = floor(brick_health_control.value)
			new_brick.score_comp.score = floor(brick_score_control.value)
			new_brick.freeze = not brick_pushable_control.button_pressed
			new_brick.mass = brick_weight_control.value

			selected_brick = new_brick
			refresh_brick_data_controls(selected_brick)

	if current_tool == "select":
		if input.is_action_pressed("mouse_primary"):
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsPointQueryParameters2D.new()
			query.position = get_global_mouse_position()
			query.collision_mask = 4
			var result = space_state.intersect_point(query)
			
			if result.size() > 0:
				selected_brick = result[0].collider;
				selected_brick_sample = duplicate_bug_bypass(result[0].collider); # Make a "Use selected" button instead.

				if apply_on_select:
					result[0].collider.init_health = brick_health_control.value;
					result[0].collider.init_score = brick_score_control.value;
					result[0].collider.init_freeze = not brick_pushable_control.button_pressed;
					result[0].collider.init_mass = brick_weight_control.value;
					if brick_can_collide_control.button_pressed:
						result[0].collider.collision_mask = 12;
					else:
						result[0].collider.collision_mask = 8;
					
					#result[0].collider.tween_shader_color(Color(1, 1, 1, 0), 0.2, true) # Bad, current shader ignores Alpha
					result[0].collider.tween_size(Vector2(0.7, 0.7), 0.1, true);
				else:
					refresh_brick_data_controls(selected_brick);

				selected_texture_shader = result[0].collider.shader_color;
				if result[0].collider.texture_path: selected_texture_path = result[0].collider.texture_path;

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
		elif input.is_action_pressed("mouse_secondary"):
			return # hue shift shader here maybe?

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

func on_mouse_enter_level_boundary():
	can_place_bricks = true

	if current_tool == "place": 
		if selected_brick:
			active_brick_sample = duplicate_bug_bypass(selected_brick);#selected_brick.duplicate();
		elif selected_brick_sample:
			active_brick_sample = duplicate_bug_bypass(selected_brick_sample);#selected_brick_sample.duplicate();#BrickScene.instantiate()
		else: return;

		level_content.add_child(active_brick_sample)
		#active_brick_sample.set_base_sprite(selected_base_texture_path)

		active_brick_sample.editor_hitbox.collision_detected.connect(func(): collision_detected = true)
		active_brick_sample.editor_hitbox.collision_freed.connect(func(): collision_detected = false)
		active_brick_sample.editor_hitbox.illegal_collision_detected.connect(func(): illegal_collision_detected = true)
		active_brick_sample.editor_hitbox.illegal_collision_freed.connect(func(): illegal_collision_detected = false)
		active_brick_sample.editor_hitbox.tree_exited.connect(reset_brick_collision_state)

func on_mouse_leave_level_boundary():
	can_place_bricks = false
	if active_brick_sample:
		active_brick_sample.queue_free()
		active_brick_sample = null

var tween_options:Tween
func on_mouse_enter_options():
	var offset:float = mode_options.anchor_bottom * get_viewport_rect().size.y - mode_options.position.y;
	var target_pos:float = mode_options.position.y - mode_options.size.y + offset;

	if tween_options: tween_options.kill();
	tween_options = get_tree().create_tween();
	tween_options.tween_property(mode_options, "position", Vector2(mode_options.position.x, target_pos), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE);
	
func on_mouse_leave_options():
	if tween_options: tween_options.kill();
	tween_options = get_tree().create_tween();
	tween_options.tween_property(mode_options, "position", Vector2(mode_options.position.x, 1000), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE);

func refresh_brick_data_controls(brick:Brick):
	brick_x_ctrl.set_value_no_signal(brick.position.x)
	brick_y_ctrl.set_value_no_signal(brick.position.y)
	brick_rot_ctrl.set_value_no_signal(brick.rotation_degrees)
	brick_health_control.set_value_no_signal(brick.init_health)
	brick_score_control.set_value_no_signal(brick.init_score)
	brick_pushable_control.set_pressed_no_signal(not brick.init_freeze)
	brick_weight_control.set_value_no_signal(brick.init_mass)
	if brick.collision_mask == 8:
		brick_can_collide_control.set_pressed_no_signal(false);
	elif brick.collision_mask == 12:
		brick_can_collide_control.set_pressed_no_signal(true);

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
	loading_level = true
	var Level:PackedScene = load(campaign_path + "/" + campaign_num + "/" + level_folder + "/level.tscn")
	var loaded_level_content = Level.instantiate()

	var level_data:LevelData = load(campaign_path + "/" + campaign_num + "/" + level_folder + "/data.tres")
	level_name.text = level_data.name

	level_content.free()

	loaded_level_content.name = "LevelContent"
	$LevelEditor.add_child(loaded_level_content, true)
	level_content = loaded_level_content

	for brick in level_content.get_children():
		brick.setup(true);

	level_num = level_folder
	loading_level = false

func save_level():
	if level_name.text.is_empty():
		level_name.call_deferred("grab_focus");
		return;
	saving_level = true;

	var new_level:PackedScene = PackedScene.new();

	for brick in level_content.get_children():
		brick.owner = level_content;

	for brick:Brick in level_content.get_children():
		brick.hitbox.owner = level_content;
	
	new_level.pack(level_content);

	mode_options.hide();
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
		var dir = campaign_path + "/" + campaign_num + "/" + level_num + "/";

		level_data = load(dir + "data.tres"); # Load existing data.
		level_data.thumbnail = ImageTexture.create_from_image(thumb);
		level_data.name = level_name.text 
		if level_data.build_number != current_build_numer:
			upgrade_version(level_data.build_number);
		level_data.build_number = current_build_numer;
		
		FileManager.add_level(campaign_num, new_level, level_data, true, level_num);
	else:
		level_data.name = level_name.text;
		level_data.thumbnail = ImageTexture.create_from_image(thumb);
		level_data.build_number = current_build_numer;

		FileManager.add_level(campaign_num, new_level, level_data);

	go_back();
	#saving_level = false

func go_back():
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

func upgrade_version(from_version:int):
	match from_version:
		1: # Default pre-release.
			pass;
