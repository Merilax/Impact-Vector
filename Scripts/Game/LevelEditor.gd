extends Node2D

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

	for brick in $LevelContent.get_children():
		brick.owner = $LevelContent

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

	$LevelContent.add_child(active_brick)

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
	print("Collision " + str(to_set))

func set_illegal_collision_detected(to_set:bool):
	illegal_collision_detected = to_set
	print("Illegal Collision " + str(to_set))

func reset_brick_collision_state():
	collision_detected = false
	illegal_collision_detected = false
	
	print("Reset")

func save_level():
	var new_level:PackedScene = PackedScene.new()
	var level_dir:DirAccess = DirAccess.open("res://Levels")
		
	if level_dir:
		var num:int = level_dir.get_files().size() + 1
		new_level.pack($LevelContent)
		ResourceSaver.save(new_level, "res://Levels/Standard_" + str(num) + ".tscn")
		get_tree().quit() # Raplce for a success notification
	else: return
	