extends Node2D
class_name Game

@export var campaign_name:String
@export var level_num:String

var BallScene = preload("res://Scenes/Game/Ball.tscn")
var PaddleScene = preload("res://Scenes/Game/Paddle.tscn")

var PickupComp = preload("res://Scenes/Game/Components/PickupComp.tscn")
var PickupSpeed = preload("res://Scenes/Game/PickupSpeed.tscn")
var PickupSlow = preload("res://Scenes/Game/PickupSlow.tscn")

var score:int = 0

var lives:int = 3
var total_lives:int = 3

var brick_count:int = 0
var ball_count:int = 0

var speed_mult:float = 1

var can_spawn_balls:bool = true

@onready var score_counter:Label = $'UILayer'.find_child('ScoreVar')
@onready var speed_counter:Label = $'UILayer'.find_child('SpeedVar')
@onready var life_counter:HBoxContainer = $'UILayer'.find_child('LivesContainer')
var BallLifeRect = preload("res://Scenes/UI/BallLifeRect.tscn")

@export var world_border:WorldBorder
var level_content:Node2D

signal game_over_signal(game_won:bool)
signal change_speed(mult:float)

func _ready():
	$"DeathZone".body_entered.connect(_on_ball_lost.bind())

	for life in lives:
		life_counter.add_child(BallLifeRect.instantiate())

	change_speed.connect(speed_counter.set_mult.bind())

	load_level("user://Levels/" + campaign_name + "/" + level_num + "/level.tscn")

	get_tree().node_added.connect(_on_child_entered_tree.bind())

	spawn_paddle()
	spawn_ball()

func spawn_paddle():
	var paddle:Paddle = PaddleScene.instantiate()
	add_child(paddle)
	paddle.position = Vector2(1000, 1040)

func spawn_ball(add_to_count:bool = true):
	if not can_spawn_balls:
		return
	else:
		var ball:Ball = BallScene.instantiate()
		$Balls.call_deferred("add_child", ball)
		var paddle = get_node("Paddle")
		ball.position.x = paddle.global_position.x
		ball.position.y = paddle.global_position.y - (paddle.get_node("Sprite2D").get_rect().size.y * paddle.get_node("Sprite2D").scale.y)
		paddle.single_use_magnet = true
		paddle.call_deferred("receive_ball", ball)

		change_speed.emit(speed_mult)
		if add_to_count:
			ball_count += 1
 
func _on_ball_lost(ball):
	if ball.is_in_group('Ball'):
		ball.collision_mask = 0 # Let the ball visibly get lost, eventually dying off-screen
		ball_count -= 1

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
			
			await get_tree().create_timer(1).timeout
			ball.die()

			if lives <= 0:
				game_over(false)
			else:
				spawn_ball()
				speed_mult = 1
				change_speed.emit(speed_mult) # Reset speed

func add_life():
	var livesVar:Label
	if lives == 3:
		for item:Node in life_counter.get_children()	:
			item.queue_free()
		life_counter.add_child(BallLifeRect.instantiate())
		var newLabel = Label.new()
		newLabel.name = 'LivesVar'
		newLabel.text = ' x 3'
		life_counter.add_child(newLabel, true)
		livesVar = newLabel

	lives += 1
	total_lives += 1

	if lives > 3:
		if not livesVar:
			livesVar = life_counter.get_node("LivesVar")
		livesVar.text = ' x ' + str(lives)
	else:
		life_counter.add_child(BallLifeRect.instantiate())

func add_score(amount:int):
	score_counter.add_score(amount)

	var _previous:int = score
	score += amount

	#if previous % 1000 < score % 1000:
	#	add_life()

func _on_brick_destroyed():
	brick_count -= 1
	if brick_count <= 0:
		win()

func game_over(game_won:bool):
	can_spawn_balls = false
	game_over_signal.emit(game_won)

func win():
	for ball:Ball in $Balls.get_children():
		ball.queue_free()
	can_spawn_balls = false
	
	level_content.queue_free()

	var campaign_data:Dictionary = CampaignManager.load_campaign_data("user://Levels/" + campaign_name + "/campaign.json")
	var current_idx:int = campaign_data.levels.find(level_num)
	
	if current_idx == -1 or current_idx >= campaign_data.levels.size() - 1:
		game_over(true)
		return

	var next_level_num:String = campaign_data.levels[current_idx + 1]

	if FileAccess.file_exists("user://Levels/" + campaign_name + "/" + next_level_num + "/level.tscn"):
		level_num = next_level_num
		load_level("user://Levels/" + campaign_name + "/" + next_level_num + "/level.tscn")

		can_spawn_balls = true
		spawn_ball(false)
	else:
		game_over(true)

func _on_child_entered_tree(node:Node):
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
			if randi() % 4 == 0:
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
		var level_content_scene = load(filepath)
		var new_level_content:Node2D = level_content_scene.instantiate()
		new_level_content.name = "LevelContent"
		add_child(new_level_content, true)
		level_content = new_level_content
		
		for brick:Node2D in new_level_content.get_children():
			init_brick(brick)
	else:
		push_error('Level filepath does not exist: ' + filepath)
