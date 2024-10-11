extends Node2D
class_name LevelEditor

@export var mouse_boundary:Area2D
@export var world_border:WorldBorder
@export var level_content:Node2D

@export var place_tool:Button
@export var paint_tool:Button
@export var erase_tool:Button

@export var snap_button:Button
@export var snap_options:Control

@export var snap_mode:Button
@export var snap_width:SpinBox
@export var snap_height:SpinBox
var use_snap:bool = true
var snap_cell_size:Vector2i = Vector2i(6, 10)

@export var brick_container:GridContainer
@export var texture_container:Control

@export var level_name:LineEdit
@export var save_button:Button

@export var level_num:String = ""
@export var campaign_num:String
@export var campaign_path:String

@export var can_place_bricks:bool = false
var active_brick_scene:PackedScene
var active_brick:Node2D

var active_texture:Texture
var active_texture_path:String

var collision_detected:bool
var illegal_collision_detected:bool

var current_tool:String = "place"

func _ready():
	world_border.show_walls(false)

	mouse_boundary.mouse_entered.connect(on_mouse_enter_level_boundary)
	mouse_boundary.mouse_exited.connect(on_mouse_leave_level_boundary)
	mouse_boundary.input_event.connect(on_mouse_click)

	brick_container.set_active_res_signal.connect(set_active_res)
	texture_container.set_active_res_signal.connect(set_active_res)

	save_button.pressed.connect(save_level)

	place_tool.pressed.connect(set_tool.bind("place"))
	paint_tool.pressed.connect(set_tool.bind("paint"))
	erase_tool.pressed.connect(set_tool.bind("erase"))

	snap_button.pressed.connect(show_options.bind("snap"))

	snap_mode.toggled.connect(set_snap_mode)
	snap_width.value_changed.connect(set_snap_size.bind(0))
	snap_height.value_changed.connect(set_snap_size.bind(1))

func set_tool(type:String):
	if type == "place":
		current_tool = type
		brick_container.show()
		texture_container.hide()
	if type == "paint":
		current_tool = type
		set_active_res()
		brick_container.hide()
		texture_container.show()
	if type == "erase":
		current_tool = type
		set_active_res()
		brick_container.hide()
		texture_container.hide()

func _process(_delta):
	if can_place_bricks and active_brick:
		if use_snap:
			@warning_ignore("integer_division")
			var snap_to_x:float = (floori(get_global_mouse_position().x) / (snap_cell_size.x*2)) * (snap_cell_size.x*2)
			@warning_ignore("integer_division")
			var snap_to_y:float = (floori(get_global_mouse_position().y) / (snap_cell_size.y*2)) * (snap_cell_size.y*2)
			active_brick.global_position = Vector2(snap_to_x, snap_to_y)
		else:
			@warning_ignore("integer_division")
			var snap_to_x:float = floori(get_global_mouse_position().x)
			@warning_ignore("integer_division")
			var snap_to_y:float = floori(get_global_mouse_position().y)
			active_brick.global_position = Vector2(snap_to_x, snap_to_y)

func show_options(what:String):
	match what.to_lower():
		"snap":
			if not snap_options.visible: snap_options.show()
			else: snap_options.hide()
			#others.hide()

func set_snap_mode(toggle:bool):
	use_snap = toggle

func set_snap_size(amount:int, axis:int):
	snap_cell_size[axis] = amount

func set_active_res(res_path:String = ""):
	if res_path == "":
		active_brick_scene = null
		active_texture = null
		return

	res_path = res_path.trim_suffix(".remap")

	if current_tool == "place":
		active_brick_scene = load(res_path)
	if current_tool == "paint":
		active_texture = load(res_path)
		active_texture_path = res_path

func on_mouse_click(_viewport:Node, input:InputEvent, _shape_idx:int):
	if current_tool == "place":	
		if input.is_action_pressed("mouse_primary"):
			if active_brick_scene == null: return
			if illegal_collision_detected: return
			if collision_detected and not Input.is_action_pressed('shift'): return

			var new_brick:Node2D = active_brick_scene.instantiate()
			level_content.add_child(new_brick)
			new_brick.owner = level_content
			new_brick.global_position = active_brick.global_position

	if current_tool == "paint":
		if input.is_action_pressed("mouse_primary"):
			if active_texture == null: return

			var space_state = get_world_2d().direct_space_state
			var query = PhysicsPointQueryParameters2D.new()
			query.position = get_global_mouse_position()
			query.collision_mask = 4
			var result = space_state.intersect_point(query)
			
			if result.size() > 0:
				result[0].collider.get_node("Sprite2D").texture = active_texture
				result[0].collider.texture_path = active_texture_path
				result[0].collider.set_shader_color(texture_container.shader_color)
				result[0].collider.shader_color = texture_container.shader_color
		elif input.is_action_pressed("mouse_secondary"):
			pass # hue shift shader here maybe?

	if current_tool == "erase":
		if input.is_action_pressed("mouse_primary"):
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsPointQueryParameters2D.new()
			query.position = get_global_mouse_position()
			query.collision_mask = 4
			var result = space_state.intersect_point(query)
			
			if result.size() > 0:
				result[0].collider.queue_free()

func on_mouse_enter_level_boundary():
	can_place_bricks = true

	if current_tool == "place": 
		if active_brick_scene == null: return
		active_brick = active_brick_scene.instantiate()
		level_content.add_child(active_brick)

		active_brick.editor_hitbox.collision_detected.connect(set_collision_detected.bind(true))
		active_brick.editor_hitbox.collision_freed.connect(set_collision_detected.bind(false))
		active_brick.editor_hitbox.illegal_collision_detected.connect(set_illegal_collision_detected.bind(true))
		active_brick.editor_hitbox.illegal_collision_freed.connect(set_illegal_collision_detected.bind(false))
		active_brick.editor_hitbox.tree_exited.connect(reset_brick_collision_state)

func on_mouse_leave_level_boundary():
	can_place_bricks = false
	if active_brick:
		active_brick.queue_free()
		active_brick = null

func set_collision_detected(to_set:bool):
	collision_detected = to_set

func set_illegal_collision_detected(to_set:bool):
	illegal_collision_detected = to_set

func reset_brick_collision_state():
	collision_detected = false
	illegal_collision_detected = false

func load_level(level_folder:String):
	var Level:PackedScene = load(campaign_path + "/" + campaign_num + "/" + level_folder + "/level.tscn")
	var loaded_level_content = Level.instantiate()

	var level_data:LevelData = load(campaign_path + "/" + campaign_num + "/" + level_folder + "/data.tres")
	level_name.text = level_data.name

	level_content.free()

	loaded_level_content.name = "LevelContent"
	$LevelEditor.add_child(loaded_level_content, true)
	level_content = loaded_level_content

	level_num = level_folder

func save_level():
	if level_name.text.is_empty(): return

	var new_level:PackedScene = PackedScene.new()
	var level_dir:DirAccess = DirAccess.open(campaign_path + "/" + campaign_num)

	for brick in level_content.get_children():
		brick.owner = level_content

	if not level_dir:
		DirAccess.make_dir_absolute(campaign_path + "/")
		DirAccess.make_dir_absolute(campaign_path + "/" + campaign_num)
		level_dir = DirAccess.open(campaign_path + "/" + campaign_num)

	new_level.pack(level_content)

	var region = Rect2(world_border.wall_left.global_position.x, 0, world_border.wall_right.global_position.x - world_border.wall_left.global_position.x, $LevelEditor/LevelMouseBoundary/CollisionShape2D.shape.size.y)
	var screenshot:Image = get_viewport().get_texture().get_image().get_region(region)

	# Compress capture
	@warning_ignore("integer_division")
	screenshot.resize(screenshot.get_size().x / 4, screenshot.get_size().y / 4, Image.INTERPOLATE_LANCZOS) # Important !!!
	var buffer:PackedByteArray = screenshot.save_webp_to_buffer(true)
	var thumb:Image = Image.new()
	thumb.load_webp_from_buffer(buffer)

	var level_data:LevelData = LevelData.new()

	if level_num:
		var dir = campaign_path + "/" + campaign_num + "/" + level_num + "/"

		level_data = load(dir + "data.tres")
		level_data.thumbnail = ImageTexture.create_from_image(thumb)
		level_data.name = level_name.text 

		ResourceSaver.save(new_level, dir + "level.tscn")
		ResourceSaver.save(level_data, dir + "data.tres")
	else:
		var dirs = DirAccess.open(campaign_path + "/" + campaign_num).get_directories()
		if dirs.size() == 0:
			level_num = "1"
		else:
			level_num = str(dirs[dirs.size() - 1].to_int() + 1)
		
		var new_dir = campaign_path + "/" + campaign_num + "/" + level_num + "/"
		DirAccess.make_dir_absolute(new_dir)

		level_data.name = level_name.text # TODO
		level_data.thumbnail = ImageTexture.create_from_image(thumb)

		ResourceSaver.save(new_level, new_dir + "level.tscn")
		ResourceSaver.save(level_data, new_dir + "data.tres")

	go_back()

func go_back():
	var MainScene:PackedScene = load("res://Scenes/Root.tscn")
	var main_scene = MainScene.instantiate()
	add_sibling(main_scene)
	queue_free()
