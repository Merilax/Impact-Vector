extends Node2D

@export var current_level_path:String

var Ball = preload("res://Scenes/Game/Ball.tscn")
var Paddle = preload("res://Scenes/Game/Paddle.tscn")

var PickupComp = preload("res://Scenes/Game/Components/PickupComp.tscn")
var PickupSpeed = preload("res://Scenes/Game/PickupSpeed.tscn")
var PickupSlow = preload("res://Scenes/Game/PickupSlow.tscn")

var brick_count:int = 0
var ball_count:int = 0
var lives:int = 3
var speed_mult:float = 1

var can_spawn_balls:bool = true

@onready var score_counter:Label = $'UILayer'.find_child('ScoreVar')
@onready var speed_counter:Label = $'UILayer'.find_child('SpeedVar')
@onready var life_counter:HBoxContainer = $'UILayer'.find_child('LivesContainer')
var BallLifeRect = preload("res://Scenes/UI/BallLifeRect.tscn")

signal change_speed(mult:float)

func _ready():
	$"DeathZone".body_entered.connect(_on_ball_lost.bind())

	for life in lives:
		life_counter.add_child(BallLifeRect.instantiate())

	change_speed.connect(speed_counter.set_mult.bind())

	load_level(current_level_path)

	get_tree().node_added.connect(_on_child_entered_tree.bind())

	spawn_paddle()
	spawn_ball()

func spawn_paddle():
	var paddle:Node2D = Paddle.instantiate()
	add_child(paddle)
	paddle.position = Vector2(650, 880)

func spawn_ball():
	if not can_spawn_balls:
		return
	else:
		var ball = Ball.instantiate()
		$Balls.call_deferred("add_child", ball)
		var paddle = get_node("Paddle")
		ball.position.x = paddle.global_position.x
		ball.position.y = paddle.global_position.y - (paddle.get_node("Sprite2D").get_rect().size.y * paddle.get_node("Sprite2D").scale.y)
		paddle.single_use_magnet = true
		paddle.call_deferred("receive_ball", ball)

		change_speed.emit(speed_mult)

		ball_count += 1
 
func _on_ball_lost(ball):
	if ball.is_in_group('Ball'):
		ball_count -= 1
		ball.die()

		if ball_count <= 0:
			lives -= 1

			if lives >= 3:
				var livesVar = life_counter.get_node("LivesVar")
				if lives == 3:
					livesVar.queue_free()
					life_counter.add_child(BallLifeRect.instantiate())
					life_counter.add_child(BallLifeRect.instantiate())
				else:
					livesVar.text = ' x ' + str(lives)
			else:
				life_counter.get_child(0).queue_free()
			
			if lives <= 0:
				game_over()
			else:
				await get_tree().create_timer(1).timeout
				spawn_ball()
				speed_mult = 1
				change_speed.emit(speed_mult) # Reset speed

func add_life():
	var livesVar:Label
	if lives == 3:
		for item:Node in life_counter.get_children():
			item.queue_free()
		life_counter.add_child(BallLifeRect.instantiate())
		var newLabel = Label.new()
		newLabel.name = 'LivesVar'
		newLabel.text = ' x 3'
		#newLabel.label_settings = load("res://GDResources/LabelMedium.tres")
		life_counter.add_child(newLabel, true)
		livesVar = newLabel

	lives += 1

	if lives > 3:
		if not livesVar:
			livesVar = life_counter.get_node("LivesVar")
		livesVar.text = ' x ' + str(lives)
	else:
		life_counter.add_child(BallLifeRect.instantiate())

func add_score(amount:int):
	score_counter.add_score(amount)

func _on_brick_destroyed():
	brick_count -= 1
	if brick_count <= 0:
		win()

func game_over():
	can_spawn_balls = false
	get_tree().quit()
	pass # TODO: Game over

func win():
	for ball:Node in $Balls.get_children():
		ball.queue_free()
	can_spawn_balls = false
	
	$"LevelContent".queue_free()

	var regex:RegEx = RegEx.new()
	regex.compile(r'\d+\.tscn')
	var match:RegExMatch = regex.search(current_level_path)

	var dir:String = current_level_path.split(match.get_string(), false)[0]
	var file:String = current_level_path.split(dir, false)[0]
	var level_num:int = file.split('.tscn')[0].to_int() + 1
	
	var temp_path = "".join([dir, str(level_num), ".tscn"])

	if FileAccess.file_exists(temp_path):
		current_level_path = temp_path
		load_level(current_level_path)
		can_spawn_balls = true
	else:
		print("No levels left.")
		return

func _on_child_entered_tree(node:Node):
	if node.is_in_group('Brick'):
		init_brick(node)

	if node.is_in_group('Ball'):
		change_speed.emit(speed_mult)
		if not self.is_connected('change_speed', node.set_speed):
			change_speed.connect(node.set_speed.bind())

	if node.is_in_group('PickUp'):
		node.trigger_pickup.connect(process_pickup.bind())

func init_brick(node):
	if node.is_in_group('Brick'):
		if node.has_signal('process_score'):
			node.process_score.connect(add_score.bind())
		if node.has_signal('brick_destroyed'):
			node.brick_destroyed.connect(_on_brick_destroyed.bind())
		if node.is_in_group('Destructible'):
			brick_count += 1
			if randi() % 5 == 0:
				var pickup_comp:PickupComponent = PickupComp.instantiate()
				node.add_child(pickup_comp)
				node.pickup_comp = pickup_comp
				node.pickup_comp.sprite = node.get_node("Sprite2D")
				if randi() % 2 == 1:
					pickup_comp.pickup = PickupSpeed
				else:
					pickup_comp.pickup = PickupSlow

func process_pickup(type:String):
	match type.to_lower():
		'speed':
			speed_mult = clampf(speed_mult + 0.1, 0.7, 1.5)
			change_speed.emit(speed_mult)
		'slow':
			speed_mult = clampf(speed_mult - 0.1, 0.7, 1.5)
			change_speed.emit(speed_mult)

func load_level(filepath:String):
	if FileAccess.file_exists(filepath):
		var level_content_scene = load(current_level_path)
		var level_content:Node2D = level_content_scene.instantiate()
		level_content.name = "LevelContent"
		add_child(level_content, true)
		
		for brick:Node2D in level_content.get_children():
			init_brick(brick)
	else:
		push_error('Level filepath does not exist: ' + filepath)