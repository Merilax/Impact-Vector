extends Node2D

@export var level_content:Node2D

@export var dir:String = ""

@export var can_place_bricks:bool = false
var active_brick_scene:PackedScene
var active_brick:Node2D

var collision_detected:bool
var illegal_collision_detected:bool

func _ready():
	$LevelMouseBoundary.mouse_entered.connect(on_mouse_enter_level_boundary)
	$LevelMouseBoundary.mouse_exited.connect(on_mouse_leave_level_boundary)
	$LevelMouseBoundary.input_event.connect(on_mouse_click)
	$EditorUI/Container/MarginContainer/BrickContainer.set_active_brick_scene.connect(set_active_brick)

	find_child('SaveBtn').pressed.connect(save_level)

func _process(_delta):
	if can_place_bricks and active_brick:
		active_brick.position = get_global_mouse_position()

func set_active_brick(Brick:PackedScene):
	if Brick == null: 
		active_brick_scene = null
	else:
		active_brick_scene = Brick

func on_mouse_enter_level_boundary():
	can_place_bricks = true

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

func on_mouse_click(_viewport:Node, input:InputEvent, _shape_idx:int):
	if input.is_action_pressed("mouse_primary"):
		if illegal_collision_detected: return
		if collision_detected and not Input.is_action_pressed('shift'): return
		
		if active_brick_scene == null: return

		var new_brick:Node2D = active_brick_scene.instantiate()
		$LevelContent.add_child(new_brick)
		new_brick.owner = $LevelContent
		new_brick.global_position = get_global_mouse_position()

func set_collision_detected(to_set:bool):
	collision_detected = to_set

func set_illegal_collision_detected(to_set:bool):
	illegal_collision_detected = to_set

func reset_brick_collision_state():
	collision_detected = false
	illegal_collision_detected = false

func load_level(level_dir):
	var Level:PackedScene = load(level_dir + "level.tscn")
	var loaded_level_content = Level.instantiate()

	level_content.free()

	loaded_level_content.name = "LevelContent"
	add_child(loaded_level_content, true)
	level_content = loaded_level_content

	dir = level_dir

func save_level():
	var new_level:PackedScene = PackedScene.new()
	var level_dir:DirAccess = DirAccess.open("user://Levels/Standard")

	for brick in level_content.get_children():
		brick.owner = level_content

	if not level_dir:
		DirAccess.make_dir_absolute("user://Levels")
		DirAccess.make_dir_absolute("user://Levels/Standard")
		level_dir = DirAccess.open("user://Levels/Standard")

	if dir:
		new_level.pack(level_content)
		ResourceSaver.save(new_level, dir)

		var region = Rect2($WorldBorder/WallL.global_position.x, 0, $WorldBorder/WallR.global_position.x - $WorldBorder/WallL.global_position.x, get_viewport_rect().size.y)
		var screenshot:Image = get_viewport().get_texture().get_image().get_region(region)

		# Compress capture
		screenshot.save_webp(dir + "thumb.webp", true, 0.5)
		var thumb:Image = Image.load_from_file(dir + "thumb.webp")

		var level_data:LevelData = load(dir + "data.tres")
		level_data.dir = dir
		#level_data.name = TODO name edit
		level_data.thumbnail = ImageTexture.create_from_image(thumb)

		ResourceSaver.save(level_data, dir + "data.tres")

	else:
		var level_num:int = level_dir.get_directories().size() + 1
		
		var new_dir = "user://Levels/Standard/" + str(level_num) + "/"
		DirAccess.make_dir_absolute(new_dir)

		new_level.pack(level_content)
		ResourceSaver.save(new_level, new_dir + "level.tscn")

		var region = Rect2($WorldBorder/WallL.global_position.x, 0, $WorldBorder/WallR.global_position.x - $WorldBorder/WallL.global_position.x, get_viewport_rect().size.y)
		var screenshot:Image = get_viewport().get_texture().get_image().get_region(region)

		screenshot.save_webp(new_dir + "thumb.webp", true, 0.5)
		var thumb:Image = Image.load_from_file(new_dir + "thumb.webp")

		var level_data:LevelData = LevelData.new()
		level_data.dir = new_dir
		level_data.name = "Standard " + str(level_num)
		level_data.thumbnail = ImageTexture.create_from_image(thumb)

		ResourceSaver.save(level_data, new_dir + "data.tres")

	go_back()
	
func go_back():
	var MainScene:PackedScene = load("res://Scenes/Root.tscn")
	var main_scene = MainScene.instantiate()
	add_sibling(main_scene)
	self.queue_free()
