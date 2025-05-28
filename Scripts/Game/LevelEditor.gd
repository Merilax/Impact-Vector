extends Node2D
class_name LevelEditor

var current_build_number:int = 3;

var BrickScene = preload("uid://dtkn1xk6stg0v");
var BrickPathScene = preload("uid://cmtfn8g03wdp8");
var SpinPathScene = preload("uid://ksq8cty5esmo");
var GodotIcon = preload("uid://dj47yk43bh08r");
var PathPointVisual = preload("uid://bkbhsiv24h3ro");

var saving_level:bool = false;
var loading_level:bool = false;
var unsaved_progress:bool = false;
var last_saved:float = Time.get_unix_time_from_system();

@export var notification_popup:AcceptDialog;
@export var confirmation_popup:ConfirmationDialog;
var confirmation_popup_result:bool;

@export_group("Nodes")
@export var mouse_boundary:Area2D;
@export var world_border:WorldBorder;
@export var grid_drawer:Node2D;
@export var level_content:Node2D;
@export var level_content_bricks:Node2D;
@export var level_content_paths:Node2D;

@export_group("Controls")
@export var selector:Container;
@export var escape_layer:CanvasLayer;

@export_group("Tool buttons")
@export var place_tool:Button;
@export var paint_tool:Button;
@export var select_tool:Button;
@export var erase_tool:Button;
@export var path_tool:Button;
@export var spinpath_tool:Button;
@export var snap_options_btn:Button;
@export var save_options_btn:Button;

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
@export var spinpath_options_ctrl:EditorSpinPathSettings;
@export var snap_options_ctrl:EditorSnapSettings;
@export var save_options_ctrl:EditorSaveSettings;

var level_num:String = "";
var campaign_num:String;
var campaign_path:String;
var brick_paths:Array[BrickPath] = [];
var spin_paths:Array[SpinPath] = [];

var can_place_bricks:bool = false;
var selected_brick_sample:Brick;
var active_brick_sample:Brick;
var selected_hitbox_path:String;
var selected_texture_path:String;
var current_texture_type:String;

var selected_brick:Brick
var selected_path:BrickPath;
var selected_spinpath:SpinPath;
var dragged_point:Node2D;

var collision_detected:bool
var illegal_collision_detected:bool

var current_tool:String = "place"

signal confirmation_popup_resolved(result:bool);

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE;

	mouse_boundary.mouse_entered.connect(on_mouse_enter_level_boundary);
	mouse_boundary.mouse_exited.connect(on_mouse_leave_level_boundary);
	mouse_boundary.input_event.connect(on_mouse_click);

	escape_layer.exit.connect(go_back);

	confirmation_popup.canceled.connect(func(): confirmation_popup_result = false; confirmation_popup_resolved.emit(false));
	confirmation_popup.confirmed.connect(func(): confirmation_popup_result = true; confirmation_popup_resolved.emit(true));

	brick_container.set_active_res_signal.connect(set_active_res);
	texture_container.set_active_res_signal.connect(set_active_res);

	save_options_btn.pressed.connect(set_tool.bind("save"));
	save_options_ctrl.save_level.connect(save_level);
	save_options_ctrl.preview_level.connect(preview_level);
	save_options_ctrl.reload_level.connect(load_level.bind(level_num));
	save_options_ctrl.exit.connect(go_back);

	place_tool.pressed.connect(set_tool.bind("place"));
	select_tool.pressed.connect(set_tool.bind("select"));
	paint_tool.pressed.connect(set_tool.bind("paint"));
	erase_tool.pressed.connect(set_tool.bind("erase"));
	path_tool.pressed.connect(set_tool.bind("path"));
	spinpath_tool.pressed.connect(set_tool.bind("spinpath"));

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
	data_options_ctrl.brick_x_ctrl.value_changed.connect(func(value): if selected_brick: set_ui_brick_position(selected_brick, value, selected_brick.position.y));
	data_options_ctrl.brick_y_ctrl.value_changed.connect(func(value): if selected_brick: set_ui_brick_position(selected_brick, selected_brick.position.x, value));
	data_options_ctrl.brick_rot_ctrl.value_changed.connect(func(value): if selected_brick: set_ui_brick_rotation(selected_brick, value));
	# data_options_ctrl.brick_health_control.value_changed.connect(func(value): if selected_brick: selected_brick.init_health = value);
	# data_options_ctrl.brick_score_control.value_changed.connect(func(value): if selected_brick: selected_brick.init_score = value);
	data_options_ctrl.brick_pushable_control.pressed.connect(func(): set_ui_brick_pushable(data_options_ctrl.brick_pushable_control.button_pressed));
	# data_options_ctrl.brick_weight_control.value_changed.connect(func(value): if selected_brick: selected_brick.init_mass = value);
	# data_options_ctrl.brick_can_collide_control.pressed.connect(func(): set_ui_brick_collider(data_options_ctrl.brick_can_collide_control.button_pressed));
	data_options_ctrl.brick_indestructible_control.pressed.connect(func(): set_ui_brick_indestructible(data_options_ctrl.brick_indestructible_control.button_pressed));
	# data_options_ctrl.brick_scoreable_control.pressed.connect(func(): set_ui_brick_scoreable(data_options_ctrl.brick_pushable_control.button_pressed));
	data_options_ctrl.brick_path_group_control.value_changed.connect(preview_path.bind(-1));
	data_options_ctrl.brick_spinpath_group_control.value_changed.connect(func(value): preview_spinpath(int(value)-1));
	data_options_ctrl.apply_ctrl.pressed.connect(func(): apply_data_options());

	path_options_ctrl.create_path_button.pressed.connect(on_create_path);
	path_options_ctrl.delete_path_button.pressed.connect(on_delete_path);
	path_options_ctrl.path_number.value_changed.connect(on_select_path.bind(-1));
	path_options_ctrl.path_speed.value_changed.connect(set_path_speed);
	path_options_ctrl.path_looped.pressed.connect(func(): set_path_looped(path_options_ctrl.path_looped.button_pressed));
	path_options_ctrl.apply_rotation.pressed.connect(func(): set_path_apply_rotation(path_options_ctrl.apply_rotation.button_pressed));
	path_options_ctrl.path_steps.value_changed.connect(func(value): set_path_steps(value));

	spinpath_options_ctrl.create_path_button.pressed.connect(on_create_spinpath);
	spinpath_options_ctrl.delete_path_button.pressed.connect(on_delete_spinpath);
	spinpath_options_ctrl.path_number.value_changed.connect(func(value): on_select_spinpath(int(value) - 1));
	spinpath_options_ctrl.path_speed.value_changed.connect(set_spinpath_speed);
	spinpath_options_ctrl.path_looped.pressed.connect(func(): set_spinpath_looped(spinpath_options_ctrl.path_looped.button_pressed));
	spinpath_options_ctrl.apply_rotation.pressed.connect(func(): set_spinpath_apply_rotation(spinpath_options_ctrl.apply_rotation.button_pressed));
	spinpath_options_ctrl.path_steps.value_changed.connect(func(value): set_spinpath_steps(int(value)));
	spinpath_options_ctrl.offset_by.value_changed.connect(func(value): set_spinpath_offset(value));
	spinpath_options_ctrl.rotate_by.value_changed.connect(func(value): set_spinpath_rotation(value));
	spinpath_options_ctrl.apply_rotation_equally.pressed.connect(func(): set_spinpath_apply_rotation_equally(spinpath_options_ctrl.apply_rotation_equally.button_pressed));

	grid_drawer.size = mouse_boundary.get_child(0).shape.size;
	set_snap_size(snap_cell_size.x, 0);
	set_snap_size(snap_cell_size.y, 1);

	Logger.write(str("Ready."), "LevelEditor");

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

	if dragged_point and can_place_bricks and selected_path:
		#Input.set_custom_mouse_cursor(null, Input.CURSOR_DRAG); Doesn't work, not a priority.
		var idx:int = dragged_point.get_meta("point_idx");
		dragged_point.global_position = get_mouse_position_snapped();
		selected_path.curve.set_point_position(idx, get_mouse_position_snapped() - level_content.global_position);
		selected_path.line.set_point_position(idx, get_mouse_position_snapped() - level_content.global_position);
		selected_path.reposition_steps();

	if dragged_point and can_place_bricks and selected_spinpath:
		#Input.set_custom_mouse_cursor(null, Input.CURSOR_DRAG); Doesn't work, not a priority.
		selected_spinpath.global_position = get_mouse_position_snapped();
		# selected_spinpath.reposition_steps();

# CORE

func set_tool(type:String):
	if loading_level or saving_level: return;
	if not verify_valid_path(): return;

	if type not in ["place", "select", "paint", "erase", "path", "spinpath", "snap", "save"]: return;

	if type in ["place", "select", "paint", "erase", "path", "spinpath"]:
		current_tool = type.to_lower();

	brick_container.hide();
	texture_container.hide();
	data_options_ctrl.hide();
	path_options_ctrl.hide();
	spinpath_options_ctrl.hide();
	snap_options_ctrl.hide();
	save_options_ctrl.hide();
	get_tree().call_group("PathPointVisual", "hide");
	get_tree().call_group("PathLineVisual", "hide");
	get_tree().call_group("SpinPathCenterVisual", "hide");
	get_tree().call_group("SpinPathVisual", "hide");
	if previewed_line:
		path_preview_tween.kill();
		previewed_line.default_color = Color(1,1,1);
		previewed_line = null;
	if previewed_spinpath_visuals:
		spinpath_preview_tween.kill();
		previewed_spinpath_visuals.modulate = Color(1,1,1);
		previewed_spinpath_visuals = null;

	match type.to_lower():
		"place":
			brick_container.show();
			on_select_path(-1);
			on_select_spinpath(-1);
		"select":
			data_options_ctrl.show();
			on_select_path(-1);
			on_select_spinpath(-1);
			get_tree().call_group("PathLineVisual", "show");
		"paint":
			texture_container.show();
			on_select_path(-1);
			on_select_spinpath(-1);
		"erase":
			on_select_path(-1);
			on_select_spinpath(-1);
		"path":
			on_select_spinpath(-1);
			on_select_path(path_options_ctrl.path_number.value, -1);
			path_options_ctrl.show();
		"spinpath":
			on_select_path(-1);
			on_select_spinpath(int(spinpath_options_ctrl.path_number.value) -1);
			spinpath_options_ctrl.show();
		"snap":
			snap_options_ctrl.show();
		"save":
			save_options_ctrl.show();
			on_select_path(-1);
			on_select_spinpath(-1);

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
		return;

	if current_tool == "place":
		if selected_brick_sample:
			selected_brick_sample.queue_free();
		# if selected_brick:
		# 	selected_brick.queue_free();
		
		var brick:Brick = BrickScene.instantiate();

		var temp_polygon:Polygon2D = load(res.polygon_path).instantiate();
		brick.polygon_array = temp_polygon.polygon.duplicate();
		brick.polygon_texture_offset = temp_polygon.texture_offset;
		brick.polygon_texture_scale = temp_polygon.texture_scale;
		temp_polygon.queue_free();

		brick.hitbox_path = res.hitbox_path;
		brick.texture_manager.texture_path = res.texture_path;
		brick.setup(true);

		selected_texture_path = res.texture_path;
		selected_brick_sample = brick;
		selected_brick = brick;
		# selected_brick.texture_type = res.texture_type;

	if current_tool == "paint":
		selected_texture_path = res.texture_path;
		current_texture_type = res.texture_type;

# SNAP

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

# PATH

func on_create_path():
	if not verify_valid_path(): return;
	unsaved_progress = true;
	
	var path:BrickPath = BrickPathScene.instantiate();
	level_content_paths.add_child(path);
	path.owner = level_content;
	brick_paths.append(path);

	var remote_offset := Node2D.new();
	remote_offset.name = str("RemoteOffsetPath", brick_paths.size() - 1);
	level_content_bricks.add_child(remote_offset, true);
	remote_offset.owner = level_content;

	path.transform_target = remote_offset;

	var step_offset := Node2D.new();
	step_offset.name = str("StepOffset0");
	remote_offset.add_child(step_offset, true);
	step_offset.owner = level_content;

	path.setup_steps();

	path_options_ctrl.path_number.max_value += 1;
	data_options_ctrl.brick_path_group_control.max_value += 1;
	path_options_ctrl.path_number.set_value_no_signal(brick_paths.size());

	on_select_path(brick_paths.size() - 1);

func on_delete_path():
	if brick_paths.size() == 0: return;
	if not selected_path: return;
	unsaved_progress = true;

	var idx:int = floor(path_options_ctrl.path_number.value) - 1;
	if idx < 0:
		on_select_path(-1);
		return;

	for brick:Brick in brick_paths[idx].transform_target.get_child(0).get_children():
		brick.path_group = -1;
		brick.reparent(level_content_bricks);

	brick_paths[idx].transform_target.queue_free();
	brick_paths[idx].queue_free();
	brick_paths.remove_at(idx);

	for i:int in range(0, brick_paths.size()):
		if i < idx: continue;
		brick_paths[i].transform_target.name = str("RemoteOffsetPath", i);
		for step_offset:Node2D in brick_paths[i].transform_target.get_children(): # Expensive, might disbale 'path_group' in cloned nodes altogether
			for brick:Brick in step_offset.get_children():
				brick.path_group = i;

	path_options_ctrl.path_number.max_value -= 1;
	data_options_ctrl.brick_path_group_control.max_value -= 1;
	path_options_ctrl.path_number.set_value_no_signal(idx);

	if path_options_ctrl.path_number.value <= 0: on_select_path(-1);
	else: on_select_path(path_options_ctrl.path_number.value, -1);
	
func on_select_path(value:float, offset:int = 0):
	var idx:int = clampi(floor(value + offset), -1, brick_paths.size() - 1);

	if selected_path and not verify_valid_path():
		path_options_ctrl.path_number.set_value_no_signal(brick_paths.find(selected_path) + 1);
		return;

	get_tree().call_group("PathPointVisual", "hide");
	get_tree().call_group("PathLineVisual", "hide");

	if idx < 0:
		selected_path = null;
		return;

	selected_path = brick_paths[idx];
	selected_path.line.show();
	selected_path.points_node.show();

	path_options_ctrl.path_speed.set_value_no_signal(selected_path.speed);
	path_options_ctrl.path_looped.set_pressed_no_signal(selected_path.looped);
	path_options_ctrl.apply_rotation.set_pressed_no_signal(selected_path.apply_rotation);
	path_options_ctrl.path_steps.set_value_no_signal(selected_path.steps);

func on_select_path_group(value:float, offset:int = 0, force_select:bool = false):
	var idx:int = floor(value + offset);

	if not selected_brick: return;
	if selected_brick.is_path_clone and idx >= 0:
		data_options_ctrl.brick_path_group_control.set_value_no_signal(selected_brick.path_group - 1);
		return;
	if selected_brick.path_group == idx: return;

	# Enabling apply on select and then changing the path group SpinBox
	# would trigger this method on the currently selected brick, so it must be filtered.
	if apply_on_select and not force_select: return;
	unsaved_progress = true;

	var remote_offset:Node2D = brick_paths[idx].transform_target;
	selected_brick.path_group = idx;

	if idx < 0:
		selected_brick.reparent(level_content_bricks);

	if idx >= 0:
		selected_brick.reparent(remote_offset.get_child(0));
		selected_brick.path_group = idx;

		for i:int in range(0, remote_offset.get_child_count()):
			if i == 0: continue;
			var new_brick := UtilsNode.duplicate_bug_bypass(selected_brick, true);
			remote_offset.get_child(i).add_child(new_brick, true);
			new_brick.is_path_clone = true;
			new_brick.position = selected_brick.position;
			new_brick.owner = level_content;

func set_path_speed(value:float):
	if selected_path:
		selected_path.speed = value;
		unsaved_progress = true;

func set_path_looped(apply:bool):
	if not selected_path: return;
	selected_path.looped = apply;
	selected_path.reposition_steps();
	unsaved_progress = true;

func set_path_apply_rotation(apply:bool):
	if not selected_path: return;
	if apply:
		selected_path.apply_rotation = true;
		for follower in selected_path.follower_array:
			follower.get_child(0).rotation = 0;
	else:
		selected_path.apply_rotation = false;
		for follower in selected_path.follower_array:
			follower.get_child(0).global_rotation = 0;
	unsaved_progress = true;

func set_path_steps(value:float):
	if not selected_path: return;
	verify_valid_path();
	var steps:int = floor(value);

	if selected_path.steps == steps: return;

	unsaved_progress = true;
	var remote_offset:Node2D = selected_path.transform_target;
	var first_step_offset:Node2D = remote_offset.get_child(0);

	for i:int in range(0, remote_offset.get_child_count()):
		if i == 0: continue;
		if i < steps: continue; 
		remote_offset.get_child(i).queue_free();

	await get_tree().process_frame;
	for i:int in range(0, steps):
		if i == 0: continue;
		if i < selected_path.steps: continue; 		
		var step_offset := Node2D.new();
		step_offset.name = str("StepOffset", i);
		remote_offset.add_child(step_offset, true);
		step_offset.owner = level_content;
		step_offset.global_position = first_step_offset.global_position;

		for brick:Brick in first_step_offset.get_children():
			var new_brick := UtilsNode.duplicate_bug_bypass(brick, true);
			new_brick.is_path_clone = true;
			step_offset.add_child(new_brick);
			new_brick.owner = level_content;
			new_brick.position = brick.position;

	selected_path.steps = steps;
	selected_path.setup_steps();

func verify_valid_path() -> bool:
	if selected_path and selected_path.curve.point_count < 2:
		notification_popup.dialog_text = "The selected path is not valid.\nPlease add at least two points to it, or delete it.";
		notification_popup.show();
		return false;
	return true;

var previewed_line:Line2D;
var path_preview_tween:Tween;
func preview_path(value:float, offset:int = 0):
	if previewed_line:
		path_preview_tween.kill();
		previewed_line.default_color = Color(1,1,1);
		previewed_line = null;

	var idx:int = floor(value + offset);
	if idx < 0: return;

	previewed_line = brick_paths[idx].line;
	path_preview_tween = previewed_line.create_tween().set_trans(Tween.TRANS_SINE).set_loops();
	path_preview_tween.tween_property(previewed_line, "default_color", Color(0,0,0), 0.5).from_current();
	path_preview_tween.tween_property(previewed_line, "default_color", previewed_line.default_color, 0.5);

# SPIN_PATH

func on_create_spinpath():
	unsaved_progress = true;

	var spinpath:SpinPath = SpinPathScene.instantiate();
	level_content_paths.add_child(spinpath, true);
	spinpath.owner = level_content;
	spin_paths.append(spinpath);
	spinpath.global_position = Vector2(get_viewport_rect().size.x / 2, get_viewport_rect().size.y / 2);

	var remote_offset := Node2D.new();
	remote_offset.name = str("RemoteOffsetSpinPath", spin_paths.size() - 1);
	level_content_bricks.add_child(remote_offset, true);
	remote_offset.global_position = spinpath.global_position;
	remote_offset.owner = level_content;

	spinpath.transform_target = remote_offset;

	var step_offset := Node2D.new();
	step_offset.name = str("StepOffset0");
	remote_offset.add_child(step_offset, true);
	step_offset.position = Vector2.ZERO;
	step_offset.owner = level_content;

	spinpath.setup();
	spinpath.adjust_steps();
	spinpath.setup_visuals();

	spinpath_options_ctrl.path_number.max_value += 1;
	data_options_ctrl.brick_spinpath_group_control.max_value += 1;
	spinpath_options_ctrl.path_number.set_value_no_signal(spin_paths.size());

	on_select_spinpath(spin_paths.size() - 1);

func on_delete_spinpath():
	if spin_paths.size() == 0: return;
	if not selected_spinpath: return;
	unsaved_progress = true;

	var idx:int = int(spinpath_options_ctrl.path_number.value) - 1;
	if idx < 0:
		on_select_spinpath(-1);
		return;

	for brick:Brick in spin_paths[idx].transform_target.get_child(0).get_children():
		brick.spin_group = -1;
		brick.reparent(level_content_bricks);

	spin_paths[idx].transform_target.queue_free();
	spin_paths[idx].queue_free();
	spin_paths.remove_at(idx);

	for i:int in range(spin_paths.size()):
		if i < idx: continue;
		spin_paths[i].transform_target.name = str("RemoteOffsetSpinPath", i);
		for step_offset:Node2D in spin_paths[i].transform_target.get_children(): # Expensive, might disbale 'path_group' in cloned nodes altogether
			for brick:Brick in step_offset.get_children():
				brick.spin_group = i;

	spinpath_options_ctrl.path_number.max_value -= 1;
	data_options_ctrl.brick_spinpath_group_control.max_value -= 1;
	spinpath_options_ctrl.path_number.set_value_no_signal(idx);

	if spinpath_options_ctrl.path_number.value <= 0: on_select_spinpath(-1);
	else: on_select_spinpath(int(path_options_ctrl.path_number.value) - 1);

func on_select_spinpath(value:int):
	get_tree().call_group("SpinPathCenterVisual", "hide");
	get_tree().call_group("SpinPathVisual", "show");
	
	if value < 0:
		selected_spinpath = null;
		return;

	selected_spinpath = spin_paths[value];
	print(selected_spinpath.transform_target.name);
	selected_spinpath.visuals_center_node.show();
	selected_spinpath.visuals_node.show();

	spinpath_options_ctrl.path_speed.set_value_no_signal(selected_spinpath.speed);
	spinpath_options_ctrl.path_looped.set_pressed_no_signal(selected_spinpath.looped);
	spinpath_options_ctrl.apply_rotation.set_pressed_no_signal(selected_spinpath.apply_rotation);
	spinpath_options_ctrl.path_steps.set_value_no_signal(selected_spinpath.steps);
	spinpath_options_ctrl.rotate_by.set_value_no_signal(selected_spinpath.rotate_by);
	spinpath_options_ctrl.offset_by.set_value_no_signal(selected_spinpath.rotation_degrees);
	spinpath_options_ctrl.apply_rotation_equally.set_pressed_no_signal(selected_spinpath.apply_rotation_equally);

func on_select_spinpath_group(idx:int, force_select:bool = false):
	if not selected_brick: return;
	if selected_brick.is_path_clone and idx >= 0:
		data_options_ctrl.brick_spinpath_group_control.set_value_no_signal(selected_brick.spin_group - 1);
		return;
	if selected_brick.spin_group == idx: return;

	# Enabling apply on select and then changing the path group SpinBox
	# would trigger this method on the currently selected brick, so it must be filtered.
	if apply_on_select and not force_select: return;
	unsaved_progress = true;

	var remote_offset:Node2D = spin_paths[idx].transform_target;
	selected_brick.spin_group = idx;

	if idx < 0:
		selected_brick.reparent(level_content_bricks);

	if idx >= 0:
		selected_brick.reparent(remote_offset.get_child(0));
		selected_brick.spin_group = idx;
		for brick in spin_paths[idx].add_and_position_brick(selected_brick):
			brick.owner = level_content;
	
	spin_paths[idx].update_transforms();

func set_spinpath_speed(value:float):
	if selected_spinpath:
		selected_spinpath.speed = value;
		unsaved_progress = true;

func set_spinpath_looped(apply:bool):
	if not selected_spinpath: return;
	unsaved_progress = true;
	selected_spinpath.looped = apply;
	selected_spinpath.reposition_steps();
	selected_spinpath.setup_visuals();

func set_spinpath_apply_rotation(apply:bool):
	if not selected_spinpath: return;
	unsaved_progress = true;

	selected_spinpath.apply_rotation = apply;
	selected_spinpath.update_transforms();
	
func set_spinpath_steps(steps:int):
	if not selected_spinpath: return;
	if selected_spinpath.steps == steps: return;

	unsaved_progress = true;
	var remote_offset:Node2D = selected_spinpath.transform_target;
	var first_step_offset:Node2D = remote_offset.get_child(0);

	for i:int in range(remote_offset.get_child_count()):
		if i == 0: continue;
		if i < steps: continue; 
		remote_offset.get_child(i).queue_free();

	await get_tree().process_frame;
	for i:int in range(steps):
		if i == 0: continue;
		if i < selected_spinpath.steps: continue; 		
		var step_offset := Node2D.new();
		step_offset.name = str("StepOffset", i);
		remote_offset.add_child(step_offset, true);
		step_offset.owner = level_content;
		step_offset.global_position = first_step_offset.global_position;

	selected_spinpath.steps = steps;
	for brick in selected_spinpath.adjust_steps(): brick.owner = level_content;
	selected_spinpath.setup_visuals();

func set_spinpath_offset(value:float):
	if not selected_spinpath: return;
	unsaved_progress = true;
	selected_spinpath.rotation_degrees = value;
	selected_spinpath.reposition_steps();

func set_spinpath_rotation(value:float):
	if not selected_spinpath: return;
	unsaved_progress = true;
	selected_spinpath.rotate_by = value;
	selected_spinpath.reposition_steps();
	selected_spinpath.setup_visuals();

func set_spinpath_apply_rotation_equally(apply:bool):
	if not selected_spinpath: return;
	unsaved_progress = true;
	selected_spinpath.apply_rotation_equally = apply;
	selected_spinpath.reposition_steps();
	selected_spinpath.setup_visuals();

var previewed_spinpath_visuals:Node2D;
var spinpath_preview_tween:Tween;
func preview_spinpath(idx:int):
	if previewed_spinpath_visuals:
		spinpath_preview_tween.kill();
		previewed_spinpath_visuals.modulate = Color(1,1,1);
		previewed_spinpath_visuals = null;

	if idx < 0: return;

	previewed_spinpath_visuals = spin_paths[idx].visuals_node;
	spinpath_preview_tween = previewed_spinpath_visuals.create_tween().set_trans(Tween.TRANS_SINE).set_loops();
	spinpath_preview_tween.tween_property(previewed_spinpath_visuals, "modulate", Color(0,0,0), 0.5);
	spinpath_preview_tween.tween_property(previewed_spinpath_visuals, "modulate", Color(1,1,1), 0.5);

# BRICK DATA

func refresh_brick_data_controls(brick:Brick):
	data_options_ctrl.brick_x_ctrl.set_value_no_signal(brick.position.x);
	data_options_ctrl.brick_y_ctrl.set_value_no_signal(brick.position.y);
	data_options_ctrl.brick_rot_ctrl.set_value_no_signal(brick.rotation_degrees);
	data_options_ctrl.brick_health_control.set_value_no_signal(brick.init_health);
	data_options_ctrl.brick_score_control.set_value_no_signal(brick.init_score);
	data_options_ctrl.brick_pushable_control.set_pressed_no_signal(brick.init_pushable);
	data_options_ctrl.brick_scoreable_control.set_pressed_no_signal(brick.scoreable);
	data_options_ctrl.brick_indestructible_control.set_pressed_no_signal(brick.is_indestructible);
	data_options_ctrl.brick_weight_control.set_value_no_signal(brick.init_mass);
	data_options_ctrl.brick_path_group_control.set_value_no_signal(brick.path_group + 1);
	data_options_ctrl.brick_can_collide_control.set_pressed_no_signal(brick.can_collide);

	data_options_ctrl.brick_path_group_control.editable = true;
	data_options_ctrl.brick_pushable_control.disabled = false;
	data_options_ctrl.brick_can_collide_control.disabled = false;
	data_options_ctrl.brick_scoreable_control.disabled = false;

	if brick.init_pushable:
		data_options_ctrl.brick_path_group_control.editable = false;

	if brick.is_indestructible:
		data_options_ctrl.brick_scoreable_control.set_pressed_no_signal(false);
		data_options_ctrl.brick_scoreable_control.disabled = true;
		data_options_ctrl.brick_pushable_control.set_pressed_no_signal(false);
		data_options_ctrl.brick_pushable_control.disabled = true;
		data_options_ctrl.brick_can_collide_control.set_pressed_no_signal(true);
		data_options_ctrl.brick_can_collide_control.disabled = true;

	preview_path(data_options_ctrl.brick_path_group_control.value, -1);

func set_ui_brick_position(brick:Brick, x:float, y:float) -> bool:
	# Needs collision logic rework
	unsaved_progress = true;
	var rollback:Vector2 = brick.position;

	brick.position = Vector2(x, y);
	await get_tree().physics_frame;
	await get_tree().process_frame;

	if illegal_collision_detected: # Brick gets stuck because it leaves the wall collision after this function executes, resetting the brick back inside the wall.
		brick.position = rollback;
		return false;
	return true;

func set_ui_brick_rotation(brick:Brick, rot:float) -> bool:
	unsaved_progress = true;
	var rollback:float = brick.rotation_degrees;

	brick.rotation_degrees = rot;

	if illegal_collision_detected:
		brick.rotation_degrees = rollback;
		return false;
	return true;

func set_brick_pushable(brick:Brick, can_be_pushed:bool):
	unsaved_progress = true;
	brick.init_pushable = can_be_pushed;
	if can_be_pushed:
		on_select_path_group(-1);

func set_ui_brick_pushable(can_be_pushed:bool):
	unsaved_progress = true;
	if can_be_pushed:
		data_options_ctrl.brick_path_group_control.set_value_no_signal(0);
		data_options_ctrl.brick_path_group_control.editable = false;
		preview_path(-1);
	else:
		if not data_options_ctrl.brick_indestructible_control.button_pressed:
			data_options_ctrl.brick_path_group_control.editable = true;

func set_brick_indestructible(brick:Brick, is_indestructible:bool):
	unsaved_progress = true;
	brick.is_indestructible = is_indestructible;
	if is_indestructible:
		brick.scoreable = false;
		brick.init_pushable = false;
		brick.can_collide = true;

func set_ui_brick_indestructible(is_indestructible:bool):
	unsaved_progress = true;
	if is_indestructible:
		data_options_ctrl.brick_scoreable_control.set_pressed_no_signal(false);
		data_options_ctrl.brick_scoreable_control.disabled = true;
		data_options_ctrl.brick_pushable_control.set_pressed_no_signal(false);
		data_options_ctrl.brick_pushable_control.disabled = true;
		data_options_ctrl.brick_can_collide_control.set_pressed_no_signal(true);
		data_options_ctrl.brick_can_collide_control.disabled = true;
	else:
		data_options_ctrl.brick_scoreable_control.disabled = false;
		data_options_ctrl.brick_pushable_control.disabled = false;
		data_options_ctrl.brick_can_collide_control.disabled = false;
		if not data_options_ctrl.brick_pushable_control.button_pressed:
			data_options_ctrl.brick_path_group_control.editable = true;

func reset_brick_collision_state():
	collision_detected = false
	illegal_collision_detected = false

func apply_data_options() -> bool:
	if not selected_brick: return false;

	selected_brick.init_health = data_options_ctrl.brick_health_control.value;
	selected_brick.init_mass = data_options_ctrl.brick_weight_control.value;
	selected_brick.init_score = data_options_ctrl.brick_score_control.value;
	selected_brick.scoreable = data_options_ctrl.brick_scoreable_control.button_pressed;
	selected_brick.can_collide = data_options_ctrl.brick_can_collide_control.button_pressed;
	set_brick_pushable(selected_brick, data_options_ctrl.brick_pushable_control.button_pressed);
	set_brick_indestructible(selected_brick, data_options_ctrl.brick_indestructible_control.button_pressed);
	on_select_path_group(data_options_ctrl.brick_path_group_control.value, -1, false);
	on_select_spinpath_group(int(data_options_ctrl.brick_spinpath_group_control.value) -1, false);

	unsaved_progress = true;
	return true;

# MOUSE

func on_mouse_click(_viewport:Node, input:InputEvent, _shape_idx:int):
	if loading_level or saving_level: return;
	if current_tool == "place":

		if input.is_action_pressed("mouse_primary"):
			if selected_brick_sample == null or active_brick_sample == null: return;
			if illegal_collision_detected: return;
			if collision_detected and not Input.is_action_pressed('shift'): return;

			var new_brick:Brick
			if selected_brick: new_brick = UtilsNode.duplicate_bug_bypass(selected_brick, true);
			else: new_brick = UtilsNode.duplicate_bug_bypass(selected_brick_sample, true);
			level_content_bricks.add_child(new_brick, true);

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
			unsaved_progress = true;
		return;

	if current_tool == "select":
		if input.is_action_pressed("mouse_primary"):
			var space_state := get_world_2d().direct_space_state
			var query := PhysicsPointQueryParameters2D.new()
			query.position = get_global_mouse_position()
			query.collision_mask = 4 # bits
			var result := space_state.intersect_point(query)
			
			if result.size() > 0:
				selected_brick = result[0].collider;
				selected_brick_sample = UtilsNode.duplicate_bug_bypass(selected_brick, true); # Make a "Use selected" button instead.

				if apply_on_select:
					selected_brick.init_health = data_options_ctrl.brick_health_control.value;
					selected_brick.init_score = data_options_ctrl.brick_score_control.value;
					selected_brick.init_mass = data_options_ctrl.brick_weight_control.value;
					selected_brick.can_collide = data_options_ctrl.brick_can_collide_control.button_pressed;
					set_brick_pushable(selected_brick, data_options_ctrl.brick_pushable_control.button_pressed);
					set_brick_indestructible(selected_brick, data_options_ctrl.brick_indestructible_control.button_pressed);
					on_select_path_group(data_options_ctrl.brick_path_group_control.value, - 1, true);

					#selected_brick.tween_shader_color(Color(1, 1, 1, 0), 0.2, true) # Bad, current shader ignores Alpha
					selected_brick.texture_manager.tween_size(Vector2(0.7, 0.7), 0.1, true);
				else:
					refresh_brick_data_controls(selected_brick);

				texture_container.set_shader_color(0, selected_brick.texture_manager.shader_colors[0]);
				texture_container.set_shader_color(1, selected_brick.texture_manager.shader_colors[1]);
				texture_container.set_shader_color(2, selected_brick.texture_manager.shader_colors[2]);
				texture_container.set_shader_color(3, selected_brick.texture_manager.shader_colors[3]);
				if selected_brick.texture_manager.texture_path: selected_texture_path = selected_brick.texture_manager.texture_path;
				unsaved_progress = true;
		#if Input.is_action_pressed("mouse_primary"):
		return;

	if current_tool == "paint":
		if input.is_action_pressed("mouse_primary"):
			var space_state = get_world_2d().direct_space_state;
			var query = PhysicsPointQueryParameters2D.new();
			query.position = get_global_mouse_position();
			query.collision_mask = 4;
			var result = space_state.intersect_point(query);
			
			if result.size() > 0:
				if current_texture_type != result[0].collider.texture_type: return;
				result[0].collider.texture_manager.set_texture_sprite(selected_texture_path, true);
				result[0].collider.texture_manager.set_shader_color_count(texture_container.shader_color_count);
				result[0].collider.texture_manager.set_shader_color(1, texture_container.shader_colors[0], true);
				result[0].collider.texture_manager.set_shader_color(2, texture_container.shader_colors[1], true);
				result[0].collider.texture_manager.set_shader_color(3, texture_container.shader_colors[2], true);
				result[0].collider.texture_manager.set_shader_color(4, texture_container.shader_colors[3], true);
				unsaved_progress = true;
		return;

	if current_tool == "erase":
		if input.is_action_pressed("mouse_primary"):
			var space_state = get_world_2d().direct_space_state;
			var query = PhysicsPointQueryParameters2D.new();
			query.position = get_global_mouse_position();
			query.collision_mask = 4;
			var result = space_state.intersect_point(query);
			
			if result.size() > 0:
				selected_brick = null;
				result[0].collider.queue_free();
				unsaved_progress = true;
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
					unsaved_progress = true;
			else:
				# Add point
				var mouse_pos:Vector2 = get_mouse_position_snapped();
				selected_path.curve.add_point(mouse_pos - level_content.global_position);
				selected_path.line.add_point(mouse_pos - level_content.global_position);

				var point:Node2D = PathPointVisual.instantiate();
				point.set_meta("point_idx", selected_path.curve.point_count - 1);
				selected_path.points_node.add_child(point);
				point.global_position = mouse_pos;
				point.owner = selected_path;

				if selected_path.curve.point_count >= 2:
					selected_path.reposition_steps();
					selected_path.transform_target.global_position = selected_path.curve.get_point_position(0);
				unsaved_progress = true;
			return;			

		# Delete point
		if input.is_action_pressed("mouse_secondary") and selected_path:
			if selected_path.curve.point_count <= 2: return;

			var space_state = get_world_2d().direct_space_state
			var query = PhysicsPointQueryParameters2D.new();
			query.position = get_global_mouse_position();
			query.collision_mask = 2048; # bits
			var result = space_state.intersect_point(query);

			if result.size() > 0:
				var remove_idx:int = result[0].collider.get_meta("point_idx");
				
				for point:Node2D in selected_path.points_node.get_children():
					var idx:int = point.get_meta("point_idx");
					if idx < remove_idx: continue;
					if idx == remove_idx: point.queue_free();
					if idx > remove_idx: point.set_meta("point_idx", point.get_meta("point_idx") - 1);
				
				selected_path.curve.remove_point(remove_idx);
				selected_path.line.remove_point(remove_idx);
				result[0].collider.queue_free();
				selected_path.reposition_steps();

				# if selected_path.curve.point_count == 0:
					# on_delete_path();
			return;

	if current_tool == "spinpath":
		# Drag point
		if input.is_action_pressed("mouse_primary") and selected_spinpath and can_place_bricks:
			if Input.is_action_pressed("shift"):
				# Start point drag
				var space_state = get_world_2d().direct_space_state
				var query = PhysicsPointQueryParameters2D.new();
				query.position = get_global_mouse_position();
				query.collision_mask = 2048; # bits
				var result = space_state.intersect_point(query);

				if result.size() > 0:
					dragged_point = result[0].collider;
					unsaved_progress = true;

func on_mouse_enter_level_boundary():
	if loading_level or saving_level:
		can_place_bricks = false;
		return;
	can_place_bricks = true

	if current_tool == "place": 
		if selected_brick:
			active_brick_sample = UtilsNode.duplicate_bug_bypass(selected_brick, true);#selected_brick.duplicate();
		elif selected_brick_sample:
			active_brick_sample = UtilsNode.duplicate_bug_bypass(selected_brick_sample, true);#selected_brick_sample.duplicate();#BrickScene.instantiate();
		else: return;

		level_content.add_child(active_brick_sample);
		#active_brick_sample.set_base_sprite(selected_base_texture_path);

		active_brick_sample.editor_hitbox.collision_detected.connect(func(): collision_detected = true);
		active_brick_sample.editor_hitbox.collision_freed.connect(func(): collision_detected = false);
		active_brick_sample.editor_hitbox.illegal_collision_detected.connect(func(): illegal_collision_detected = true);
		active_brick_sample.editor_hitbox.illegal_collision_freed.connect(func(): illegal_collision_detected = false);
		active_brick_sample.editor_hitbox.tree_exited.connect(reset_brick_collision_state);

func on_mouse_leave_level_boundary():
	if loading_level or saving_level:
		can_place_bricks = false;
		return;

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
		snap_to_x = (floori(get_global_mouse_position().x) / (snap_cell_size.x)) * (snap_cell_size.x);
		@warning_ignore("integer_division")
		snap_to_y = (floori(get_global_mouse_position().y) / (snap_cell_size.y)) * (snap_cell_size.y);
	else:
		@warning_ignore("integer_division")
		snap_to_x = floori(get_global_mouse_position().x);
		@warning_ignore("integer_division")
		snap_to_y = floori(get_global_mouse_position().y);
	return Vector2(snap_to_x, snap_to_y);

func release_drag_point():
	if not dragged_point or (not selected_path and not selected_spinpath): return;
	dragged_point = null;
	unsaved_progress = true;

# SAVE / LOAD

func load_level(level_folder:String) -> bool:
	if not FileAccess.file_exists(campaign_path + "/" + campaign_num + "/" + level_folder + "/level.json"): return false;
	if unsaved_progress:
		var time_from_last_saved:float = Time.get_unix_time_from_system() - last_saved;
		confirmation_popup.dialog_text = "Unsaved progress will be lost.\nLast saved: {m} minutes and {s} seconds ago.".format({
			"m": int(time_from_last_saved / 60),
			"s": int(time_from_last_saved) % 60
		});
		confirmation_popup.show();
		await self.confirmation_popup_resolved;
		if confirmation_popup_result == false: return false;

	Logger.write(str("Loading level from ", level_folder), "LevelEditor");
	loading_level = true;

	for node in level_content_bricks.get_children(): node.queue_free();
	for node in level_content_paths.get_children(): node.queue_free();
	await get_tree().process_frame;

	var level_data:LevelData = load(campaign_path + "/" + campaign_num + "/" + level_folder + "/data.tres");
	save_options_ctrl.level_name.text = level_data.name;

	var reader := FileAccess.open(campaign_path + "/" + campaign_num + "/" + level_folder + "/level.json", FileAccess.READ);
	var level_dict = JSON.parse_string(reader.get_as_text());
	reader.close();

	if level_data.build_number < current_build_number:
		unsaved_progress = true;
		var directory := str(campaign_path, campaign_num, "/", level_num);
		var upgrade_successful := Utils.upgrade_level_version(level_data, level_dict, current_build_number, directory);
		if not upgrade_successful: go_back(true); # TODO Notify broken level 

	build_level_content_from_dictionary(level_dict);
	
	level_num = level_folder;
	loading_level = false;
	return true;

func save_level() -> bool:
	if not verify_valid_path(): return false;
	if save_options_ctrl.level_name.text.is_empty():
		save_options_ctrl.level_name.call_deferred("grab_focus");
		saving_level = false;
		return false;

	if unsaved_progress:
		var time_from_last_saved:float = Time.get_unix_time_from_system() - last_saved;
		confirmation_popup.dialog_text = "You are about to overwrite previous save data.\nLast saved: {m} minutes and {s} seconds ago.\nContinue?".format({
			"m": int(time_from_last_saved / 60),
			"s": int(time_from_last_saved) % 60
		});
		confirmation_popup.show();
		await self.confirmation_popup_resolved;
		if confirmation_popup_result == false:
			saving_level = false;
			return false;

	Logger.write(str("Saving level."), "LevelEditor");
	saving_level = true;

	on_select_path(-1);
	on_select_spinpath(-1);

	var scoreable_bricks:int = 0;
	for brick:Brick in get_tree().get_nodes_in_group("Brick"):
		if brick.scoreable: scoreable_bricks += 1;
	if scoreable_bricks <= 0:
		notification_popup.dialog_text = "The level must contain at least one scoreable brick.";
		notification_popup.show();
		saving_level = false;
		return false;

	Logger.write(str("Generating level dictionary."), "LevelEditor");
	var new_level := get_dictionary_from_level_content();
	new_level["last_saved"] = str(Time.get_unix_time_from_system());
	last_saved = Time.get_unix_time_from_system();

	set_snap_visibility(false);
	get_tree().call_group("SpinPathVisual", "hide");
	get_tree().call_group("SpinPathCenterVisual", "hide");
	get_tree().call_group("PathLineVisual", "hide");
	get_tree().call_group("PathPointVisual", "hide");
	await get_tree().create_timer(0.25).timeout; # Give the UI time to hide.

	var region = Rect2(world_border.wall_left.global_position.x, 0, world_border.wall_right.global_position.x - world_border.wall_left.global_position.x, $LevelEditor/LevelMouseBoundary/CollisionShape2D.shape.size.y);
	var screenshot:Image = get_viewport().get_texture().get_image().get_region(region);

	# Compress capture
	@warning_ignore("integer_division")
	screenshot.resize(screenshot.get_size().x / 4, screenshot.get_size().y / 4, Image.INTERPOLATE_LANCZOS) # Important !!!
	var buffer:PackedByteArray = screenshot.save_webp_to_buffer(true);
	var thumb:Image = Image.new();
	thumb.load_webp_from_buffer(buffer);

	var level_data:LevelData = LevelData.new();

	if level_num:
		Logger.write(str("Replacing level ", level_num), "LevelEditor");
		var dir = campaign_path + "/" + campaign_num + "/" + level_num + "/";

		level_data = load(dir + "data.tres"); # Load existing data.
		level_data.thumbnail = ImageTexture.create_from_image(thumb);
		level_data.name = save_options_ctrl.level_name.text;
		level_data.build_number = current_build_number;
		
		FileManager.add_level(campaign_num, new_level, level_data, true, level_num);
	else:
		level_data.name = save_options_ctrl.level_name.text;
		level_data.thumbnail = ImageTexture.create_from_image(thumb);
		level_data.build_number = current_build_number;

		level_num = FileManager.add_level(campaign_num, new_level, level_data);

	unsaved_progress = false;
	saving_level = false;
	return true;

func preview_level():
	if unsaved_progress or not FileAccess.file_exists(campaign_path + "/" + campaign_num + "/" + level_num + "/level.json"):
		var time_from_last_saved:float = Time.get_unix_time_from_system() - last_saved;
		confirmation_popup.dialog_text = "The level must be saved before previewing.\nContinue?".format({
			"m": int(time_from_last_saved / 60),
			"s": int(time_from_last_saved) % 60
		});
		confirmation_popup.show();
		await self.confirmation_popup_resolved;
		if confirmation_popup_result == false:
			return;
			
	var save_success := await save_level();
	if not save_success: return;

	Logger.write(str("Instantiating Level preview: ", campaign_path, campaign_num, "/", level_num), "LevelEditor");

	var GameScene:PackedScene = load("uid://la6hglf0tura");
	var game:Game = GameScene.instantiate();
	game.level_num = level_num;
	game.campaign_path = campaign_path;
	game.campaign_num = campaign_num;
	game.return_to_editor = true;
	game.skip_animations = true;
	add_sibling(game, true);
	MusicPlayer.set_track_type("InGame");
	self.queue_free();

	Logger.write("Finished loading Level.", "LevelEditor");

func go_back(force:bool = false):
	if unsaved_progress and not force:
		var time_from_last_saved:float = Time.get_unix_time_from_system() - last_saved;
		confirmation_popup.dialog_text = "Unsaved progress will be lost.\nLast saved: {m} minutes and {s} seconds ago.".format({
			"m": int(time_from_last_saved / 60),
			"s": int(time_from_last_saved) % 60
		});
		confirmation_popup.show();
		await self.confirmation_popup_resolved;
		if confirmation_popup_result == false: return;
	
	Logger.write(str("Exiting editor."), "LevelEditor");
	var MainScene:PackedScene = load("uid://c0a7y1ep5uibb");
	var main_scene = MainScene.instantiate();
	add_sibling(main_scene, true);
	queue_free();

# UTILS

func build_level_content_from_dictionary(level_dict:Dictionary) -> bool:
	for item:Dictionary in level_dict.paths:
		var path:BrickPath = BrickPathScene.instantiate();
		path.speed = item.speed;
		path.looped = item.looped;
		path.apply_rotation = item.apply_rotation;
		path.steps = item.steps;

		for i:int in range(item.points.size()):
			var point:Dictionary = item.points[i];
			var p_pos = Vector2(point.pos.x, point.pos.y);
			var p_in = Vector2.ZERO;
			var p_out = Vector2.ZERO;
			if i > 0: p_in = Vector2(point.in.x, point.in.y);
			if i < item.points.size() - 1: p_out = Vector2(point.out.x, point.out.y);

			path.curve.add_point(p_pos, p_in, p_out);

		var remote_offset := Node2D.new();
		remote_offset.name = item.transform_target;
		level_content_bricks.add_child(remote_offset, true);
		remote_offset.owner = level_content;

		path.transform_target = remote_offset;

		for i:int in range(item.steps):
			var step_offset := Node2D.new();
			step_offset.name = str("StepOffset", i);
			remote_offset.add_child(step_offset, true);
			step_offset.owner = level_content;

		level_content_paths.add_child(path, true);
		brick_paths.append(path);
		path_options_ctrl.path_number.max_value += 1;
		data_options_ctrl.brick_path_group_control.max_value += 1;
		path.setup_steps();

		for i:int in range(item.steps):
			remote_offset.get_child(i).position = Vector2(item.step_positions[i].x, item.step_positions[i].y);
	on_select_path(-1);
	
	for item:Dictionary in level_dict.spinpaths:
		var spinpath:SpinPath = SpinPathScene.instantiate();
		spinpath.speed = item.speed;
		spinpath.looped = item.looped;
		spinpath.apply_rotation = item.apply_rotation;
		spinpath.steps = item.steps;
		spinpath.apply_rotation_equally = item.apply_rotation_equally;
		spinpath.rotate_by = item.rotate_by;

		level_content_paths.add_child(spinpath, true);
		spinpath.position = Vector2(item.position.x, item.position.y);
		spinpath.rotation_degrees = item.rotation_degrees;

		spinpath_options_ctrl.path_number.max_value += 1;
		data_options_ctrl.brick_spinpath_group_control.max_value += 1;
		spin_paths.append(spinpath);

		var remote_offset := Node2D.new();
		remote_offset.name = item.transform_target;
		level_content_bricks.add_child(remote_offset, true);
		remote_offset.owner = level_content;
		spinpath.transform_target = remote_offset;

		for i in range(item.steps):
			var step_offset := Node2D.new();
			step_offset.name = str("StepOffset", i);
			remote_offset.add_child(step_offset, true);
			step_offset.owner = level_content;

	get_tree().call_group("SpinPath", "setup");

	for item:Dictionary in level_dict.bricks:
		var brick:Brick = BrickScene.instantiate();

		brick.hitbox_path = item.hitbox_path;
		brick.texture_manager.texture_path = item.texture_path;
		brick.texture_manager.original_sprite_size = Vector2(item.original_sprite_size.x, item.original_sprite_size.y);
		brick.texture_manager.shader_colors = [Color(item.shader_colors[0]), Color(item.shader_colors[1]), Color(item.shader_colors[2]), Color(item.shader_colors[3])];
		brick.texture_manager.shader_color_count = item.shader_color_count;
		brick.texture_manager.shader_modulation = item.shader_modulation;
		brick.init_health = item.init_health;
		brick.init_score = item.init_score;
		brick.init_pushable = item.init_pushable;
		brick.init_mass = item.init_mass;
		brick.can_collide = item.can_collide;
		brick.scoreable = item.scoreable;
		brick.is_indestructible = item.is_indestructible;
		brick.polygon_array = Utils.compose_vector2_array(item.polygon_array);
		brick.polygon_texture_offset = Vector2(item.polygon_texture_offset.x, item.polygon_texture_offset.y);
		brick.polygon_texture_scale = Vector2(item.polygon_texture_scale.x, item.polygon_texture_scale.y);
		brick.is_path_clone = item.is_path_clone;
		brick.path_group = item.path_group as int;
		brick.spin_group = item.spin_group as int;
		
		level_content_bricks.add_child(brick, true);
		brick.owner = level_content;
		brick.scale = Vector2(item.scale.x, item.scale.y);
		
		if brick.path_group >= 0:
			var step_offset = level_content_bricks.find_child(str("RemoteOffsetPath", brick.path_group)).get_child(item.path_step as int);
			brick.reparent(step_offset);
			
		if brick.spin_group >= 0:
			var step_offset = level_content_bricks.find_child(str("RemoteOffsetSpinPath", brick.spin_group)).get_child(item.spin_step as int);
			brick.reparent(step_offset);
			spin_paths[brick.spin_group].bricks.append({"brick": brick, "step": item.spin_step as int});
		
		brick.position = Vector2(item.position.x, item.position.y);
		brick.rotation_degrees = item.rotation_degrees;
		brick.setup(true);

	get_tree().call_group("SpinPath", "setup_transforms");
	on_select_spinpath(-1);

	return true;

func get_dictionary_from_level_content() -> Dictionary:
	var level_dict:Dictionary = {"paths": [], "spinpaths": [], "bricks": []};
	for node:Node2D in level_content_paths.get_children():
		if node is BrickPath:
			var point_collection := [];
			for j:int in range(node.curve.point_count):
				var point = {};
				point.pos = {"x": node.curve.get_point_position(j).x, "y": node.curve.get_point_position(j).y};
				if j > 0: point.in = {"x": node.curve.get_point_in(j).x, "y": node.curve.get_point_in(j).y};
				if j < node.curve.point_count - 1: point.out = {"x": node.curve.get_point_out(j).x, "y": node.curve.get_point_out(j).y};
				point_collection.append(point);

			var step_offset_position_collection := [];
			for j:int in range(node.steps):
				var step_offset:Node2D = node.transform_target.get_child(j);
				var step_pos = {"x": step_offset.position.x, "y": step_offset.position.y};
				step_offset_position_collection.append(step_pos);

			level_dict.paths.append({
				"speed": node.speed,
				"looped": node.looped,
				"apply_rotation": node.apply_rotation,
				"steps": node.steps,
				"transform_target": node.transform_target.name,
				"points": point_collection,
				"step_positions": step_offset_position_collection,
			});

			for j:int in range(node.steps):
				var step_offset:Node2D = node.transform_target.get_child(j);
				for brick:Brick in step_offset.get_children():
					level_dict.bricks.append({
						"position": {"x": brick.position.x, "y": brick.position.y},
						"rotation_degrees": brick.rotation_degrees,
						"scale": {"x": brick.scale.x, "y": brick.scale.y},
						"hitbox_path": brick.hitbox_path,
						"texture_path": brick.texture_manager.texture_path,
						"original_sprite_size": {"x": brick.texture_manager.original_sprite_size.x, "y": brick.texture_manager.original_sprite_size.y},
						"shader_colors": [brick.texture_manager.shader_colors[0].to_html(), brick.texture_manager.shader_colors[1].to_html(), brick.texture_manager.shader_colors[2].to_html(), brick.texture_manager.shader_colors[3].to_html()],#brick.shader_color.to_html(),
						"shader_color_count": brick.texture_manager.shader_color_count,
						"shader_modulation": brick.texture_manager.shader_modulation,
						"init_health": brick.init_health,
						"init_score": brick.init_score,
						"init_pushable": brick.init_pushable,
						"init_mass": brick.init_mass,
						"can_collide": brick.can_collide,
						"scoreable": brick.scoreable,
						"is_indestructible": brick.is_indestructible,
						"polygon_array": Utils.decompose_vector2_array(brick.polygon_array),
						"polygon_texture_offset": {"x": brick.polygon_texture_offset.x, "y": brick.polygon_texture_offset.y},
						"polygon_texture_scale": {"x": brick.polygon_texture_scale.x, "y": brick.polygon_texture_scale.y},
						"is_path_clone": brick.is_path_clone,
						"path_group": brick.path_group,
						"path_step": j,
						"spin_group": -1,
						"spin_step": 0,
					});

		if node is SpinPath:
			level_dict.spinpaths.append({
				"position": {"x": node.position.x, "y": node.position.y},
				"rotation_degrees": node.rotation_degrees,
				"speed": node.speed,
				"looped": node.looped,
				"apply_rotation": node.apply_rotation,
				"steps": node.steps,
				"transform_target": node.transform_target.name,
				"apply_rotation_equally": node.apply_rotation_equally,
				"rotate_by": node.rotate_by,
			});

			for j:int in range(node.steps):
				var step_offset:Node2D = node.transform_target.get_child(j);
				for brick:Brick in step_offset.get_children():
					level_dict.bricks.append({
						"position": {"x": brick.position.x, "y": brick.position.y},
						"rotation_degrees": brick.rotation_degrees,
						"scale": {"x": brick.scale.x, "y": brick.scale.y},
						"hitbox_path": brick.hitbox_path,
						"texture_path": brick.texture_manager.texture_path,
						"original_sprite_size": {"x": brick.texture_manager.original_sprite_size.x, "y": brick.texture_manager.original_sprite_size.y},
						"shader_colors": [brick.texture_manager.shader_colors[0].to_html(), brick.texture_manager.shader_colors[1].to_html(), brick.texture_manager.shader_colors[2].to_html(), brick.texture_manager.shader_colors[3].to_html()],#brick.shader_color.to_html(),
						"shader_color_count": brick.texture_manager.shader_color_count,
						"shader_modulation": brick.texture_manager.shader_modulation,
						"init_health": brick.init_health,
						"init_score": brick.init_score,
						"init_pushable": brick.init_pushable,
						"init_mass": brick.init_mass,
						"can_collide": brick.can_collide,
						"scoreable": brick.scoreable,
						"is_indestructible": brick.is_indestructible,
						"polygon_array": Utils.decompose_vector2_array(brick.polygon_array),
						"polygon_texture_offset": {"x": brick.polygon_texture_offset.x, "y": brick.polygon_texture_offset.y},
						"polygon_texture_scale": {"x": brick.polygon_texture_scale.x, "y": brick.polygon_texture_scale.y},
						"is_path_clone": brick.is_path_clone,
						"path_group": -1,
						"path_step": 0,
						"spin_group": brick.spin_group,
						"spin_step": j,
					});

	for node in level_content_bricks.get_children():
		if node is Brick:
			level_dict.bricks.append({
				"position": {"x": node.position.x, "y": node.position.y},
				"rotation_degrees": node.rotation_degrees,
				"scale": {"x": node.scale.x, "y": node.scale.y},
				"hitbox_path": node.hitbox_path,
				"texture_path": node.texture_manager.texture_path,
				"original_sprite_size": {"x": node.texture_manager.original_sprite_size.x, "y": node.texture_manager.original_sprite_size.y},
 				"shader_colors": [node.texture_manager.shader_colors[0].to_html(), node.texture_manager.shader_colors[1].to_html(), node.texture_manager.shader_colors[2].to_html(), node.texture_manager.shader_colors[3].to_html()],
				"shader_color_count": node.texture_manager.shader_color_count,
				"shader_modulation": node.texture_manager.shader_modulation,
				"init_health": node.init_health,
				"init_score": node.init_score,
				"init_pushable": node.init_pushable,
				"init_mass": node.init_mass,
				"can_collide": node.can_collide,
				"scoreable": node.scoreable,
				"is_indestructible": node.is_indestructible,
				"polygon_array": Utils.decompose_vector2_array(node.polygon_array),
				"polygon_texture_offset": {"x": node.polygon_texture_offset.x, "y": node.polygon_texture_offset.y},
				"polygon_texture_scale": {"x": node.polygon_texture_scale.x, "y": node.polygon_texture_scale.y},
				"is_path_clone": false,
				"path_group": -1,
				"path_step": 0,
				"spin_group": -1,
				"spin_step": 0
			});

	return level_dict;
