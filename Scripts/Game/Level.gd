extends Node2D
class_name Game

var current_build_number:int = 2;

@export var campaign_path:String
@export var campaign_num:String
@export var level_num:String

var save_state:SaveGameData;

var pickup_list:Array = [
	{
		"type": "slow",
		"name": "Speed Down",
		"texture": "res://Assets/Visuals/Pickups/PickupSlow.png"
	},
	{
		"type": "speed",
		"name": "Speed Up",
		"texture": "res://Assets/Visuals/Pickups/PickupSpeed.png"
	},
	{
		"type": "turrets",
		"name": "Turrets",
		"texture": "res://Assets/Visuals/Pickups/PickupGun.png"
	},
	{
		"type": "magnet",
		"name": "Magnet",
		"texture": "res://Assets/Visuals/Pickups/PickupMagnet.png"
	},
	{
		"type": "death",
		"name": "Death",
		"texture": "res://Assets/Visuals/Pickups/PickupDeath.png"
	},
	{
		"type": "triple",
		"name": "Triple balls",
		"texture": "res://Assets/Visuals/Pickups/PickupTriple.png"
	}
]

var BallScene = preload("uid://dxbg7h6mg1dtd");
var PaddleScene = preload("uid://bjjlgc7puyxfe");

var PickupComp = preload("uid://c5ebe7unjhv0x");
var PickupScene = preload("uid://dydm2dhj7p1nd");
var BulletScene = preload("uid://dlvm63pvf1dym");

var paddle:Paddle;

var score:int = 0;
var unsaved_score:int = score;

var lives:int = 3;
var total_lives:int = 3;
var unsaved_lives:int = lives;
var unsaved_total_lives:int = total_lives;

var brick_count:int = 0;
var ball_count:int = 0;

var speed_mult:float = 1;
var visual_speed_mult:int = 3;

var can_spawn_balls:bool = true;
var ball_stuck_timer:SceneTreeTimer;

@export var notification_window:Label;
@export var notification_window_timer:Timer;
@export var score_counter:Label;
@export var speed_counter:Label;
@export var life_counter:HBoxContainer;
var BallLifeRect = preload("uid://b5s0bxfmkxjel");

@export var world_border:WorldBorder;
var level_content:Node2D;
var level_content_bricks:Node2D;
var level_content_paths:Node2D;
var level_content_path_visuals:Node2D;
@export var background:Parallax2D;

@export var speed_meter:TextureProgressBar;
@export var magnet_meter:TextureProgressBar;

@export var arm_horizontal:Node2D;
@export var arm_vertical:Node2D;
@export var arm_placer:Node2D;
@export var arm_placer_sound:AudioStreamPlayer;

var transitioning_levels:bool = false;

signal game_over_signal(game_won:bool);
signal change_speed(mult:float, update_counter:bool);

func _ready():
	background.retrigger();

	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	$"DeathZone".body_entered.connect(_on_ball_lost)

	if notification_window_timer:
		notification_window_timer.timeout.connect(func(): notification_window.text = "");

	for life in lives:
		life_counter.add_child(BallLifeRect.instantiate())

	change_speed.connect(speed_counter.set_mult)

	if save_state:
		load_gamedata();
	else:
		await load_level(campaign_path + campaign_num + "/" + level_num + "/");

	get_tree().node_added.connect(_on_child_entered_tree)

	spawn_paddle()
	spawn_ball(true)

func spawn_paddle():
	paddle = PaddleScene.instantiate()
	paddle.world_border = world_border
	add_child(paddle)
	paddle.position = Vector2(1000, 1040)

	if paddle.has_signal("spawn_bullet"):
		paddle.spawn_bullet.connect(spawn_bullet)

func spawn_ball(on_paddle:bool, pos:Vector2 = Vector2.ZERO, dir:Vector2 = Vector2.ZERO, add_to_count:bool = true):
	if not can_spawn_balls:
		return
	else:
		var ball:Ball = BallScene.instantiate()
		$Balls.call_deferred("add_child", ball)

		ball.dir = dir
		if on_paddle:
			paddle.add_magnet(true)
			paddle.call_deferred("receive_first_ball", ball)
			#ball.set_deferred("position", Vector2(paddle.global_position.x, paddle.global_position.y - (paddle.get_node("Sprite2D").get_rect().size.y * paddle.get_node("Sprite2D").scale.y)))
		else:
			ball.set_deferred("global_position", pos)
			ball.set_deferred("freeze", false)

		#ball.reset_stuck_timer.connect(_on_ball_reset_stuck_timer)

		ball.speed_mult = speed_mult
		if add_to_count:
			ball_count += 1

func _on_ball_lost(node:Node2D):
	if node.is_in_group("Pickup"):
		await get_tree().create_timer(3).timeout
		if node:
			node.queue_free()
	
	if node.is_in_group('Ball'):
		node.lost = true
		node.collision_mask = 0 # Let the ball visibly get lost, eventually dying off-screen

		if transitioning_levels: return

		ball_count -= 1

		if ball_count <= 0:
			lives -= 1
			kill_paddle();

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
			node.die()

			if lives <= 0:
				await get_tree().create_timer(2).timeout
				get_tree().call_group("PickUp", "queue_free")
				game_over(false)
			else:
				await get_tree().create_timer(1).timeout
				get_tree().call_group("PickUp", "queue_free")
				if not paddle:
					spawn_paddle()

				spawn_ball(true)
				reset_speed_mult();

func spawn_bullet(pos:Vector2, dir:float):
	var bullet:Bullet = BulletScene.instantiate()
	level_content.add_child(bullet)
	bullet.global_position = pos
	bullet.rotation = dir
	bullet.freeze = false

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

	var previous:int = score
	score += amount

	@warning_ignore("integer_division")
	if floori(previous / 10000) < floori(score / 10000):
		add_life(); # Extra life every 10000 score.

func _on_brick_destroyed():
	brick_count -= 1
	if brick_count <= 0:
		win()

func _on_ball_reset_stuck_timer(free_timer:bool): # Multiply balls if nothing meaningful was hit in 30 seconds. Unsure if I want to continue with this.
	return
	@warning_ignore("unreachable_code")
	ball_stuck_timer.free()
	if free_timer: return

	ball_stuck_timer = get_tree().create_timer(30, false)

	if ball_count == 1:
		await ball_stuck_timer.timeout

func _on_spawn_pickup(global_pos:Vector2, type:String, texture:String):
	var pickup:Pickup = PickupScene.instantiate()
	pickup.type = type
	pickup.get_node("Sprite2D").texture = load(texture)
	level_content.add_child(pickup)
	pickup.global_position = global_pos

func notify(text:String):
	#notification_window_timer.stop();
	notification_window.text = text;
	notification_window_timer.start();

func game_over(game_won:bool):
	can_spawn_balls = false
	if game_won == true:
		DirAccess.remove_absolute("user://SaveGameData.tres");
	game_over_signal.emit(game_won);

func win():
	transitioning_levels = true;
	can_spawn_balls = false;

	var stored_speed_mult = speed_mult;

	create_tween().tween_method(func(speed): change_speed.emit(speed, false), stored_speed_mult, 0, 2.5);

	await get_tree().create_timer(3.5).timeout;

	level_content.queue_free();
	for ball:Ball in $Balls.get_children():
		ball.queue_free();

	ball_count = 0;
	speed_mult = 1; # TODO Add difficulty.

	unsaved_score = score;
	unsaved_lives = lives;
	unsaved_total_lives = total_lives;
	
	var next_level_num:String = "0";
	
	if campaign_path.contains("res://"):
		next_level_num = str(BaseCampaignManager.find_next_level(campaign_path + campaign_num + '/', level_num.to_int()));
	else: next_level_num = str(CampaignManager.find_next_level(campaign_path + campaign_num , level_num.to_int()));
	print(next_level_num);
	if next_level_num == "0":
		game_over(true);
		return;
	print(campaign_path + campaign_num + "/" + next_level_num + "/");
	if not FileAccess.file_exists(campaign_path + campaign_num + "/" + next_level_num + "/level.tscn") or not await load_level(campaign_path + campaign_num + "/" + next_level_num + "/"):
		game_over(true);
		return;
	
	level_num = next_level_num;
	save_gamedata();

	transitioning_levels = false;
	if is_instance_valid(paddle):
		paddle.reset_powers();
	else:
		spawn_paddle();
	can_spawn_balls = true;
	spawn_ball(true);

func _on_child_entered_tree(node:Node):
	if node.is_in_group('Ball'):
		change_speed.emit(speed_mult, false)
		if not self.is_connected('change_speed', node.set_speed):
			change_speed.connect(node.set_speed)

	if node.is_in_group('PickUp'):
		node.trigger_pickup.connect(process_pickup)

func init_brick(brick, set_hidden:bool = false):
	if brick.is_in_group('Brick'):
		brick.setup(false);
		if set_hidden: brick.hide();
		
		if brick.has_signal('process_score'):
			brick.process_score.connect(add_score)
		if brick.has_signal('brick_destroyed'):
			brick.brick_destroyed.connect(_on_brick_destroyed)
		if brick.has_signal('spawn_pickup'):
			brick.spawn_pickup.connect(_on_spawn_pickup)

		if brick.is_in_group('Destructible'):
			brick_count += 1
			if randi() % 101 <= 20: # Pickup spawn %
				var pickup_comp:PickupComponent = PickupComp.instantiate()
				brick.add_child(pickup_comp)
				brick.pickup_comp = pickup_comp
				brick.pickup_comp.shader_target = brick#.get_node("Sprite2D")

				var random_pickup = pickup_list[randi() % pickup_list.size()]

				brick.pickup_comp.pickup_type = random_pickup.type
				brick.pickup_comp.pickup_sprite = random_pickup.texture

func init_path(path, time, returning:bool = true):
	var line:PathFollow2D = path.get_child(0);

	var tween:Tween = get_tree().create_tween();
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT);
	tween.tween_property(line, "progress_ratio", 1, time).from(0).set_loops();
	if returning:
		tween.tween_property(line, "progress_ratio", 0, time).from(1);

func kill_paddle():
	if is_instance_valid(paddle):
		paddle.die();
		magnet_meter.value = 0;

func position_arm(pos:Vector2, play_sound:bool = true) -> bool:
	var duration = (arm_placer.global_position - pos).length() / 2000;
	create_tween().tween_property(arm_horizontal, "global_position:y", pos.y, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	create_tween().tween_property(arm_vertical, "global_position:x", pos.x, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await create_tween().tween_property(arm_placer, "global_position", pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).finished;
	arm_placer.get_node("GPUParticles2D").restart();
	if play_sound and arm_placer_sound: arm_placer_sound.play();
	await get_tree().create_timer(.04).timeout;
	return true;

func process_pickup(type:String):
	if transitioning_levels: return
	# TODO SFX each
	match type.to_lower():
		'speed':
			notify("SPEED UP\n\n200 POINTS");
			add_score(200);
			add_speed_mult(true);
		'slow':
			notify("SPEED DOWN\n\n100 POINTS");
			add_score(100);
			add_speed_mult(false);
		"magnet":
			notify("MAGNET STRENGTH UP\n\n200 POINTS");
			add_score(200);
			add_magnet();
		"turrets":
			notify("RELOAD GUNS\n\n200 POINTS");
			add_score(200);
			if is_instance_valid(paddle): paddle.activate_turrets();
			if magnet_meter: magnet_meter.value = 0;
		"death":
			notify("QUESTIONABLE\nLIFE CHOICES\n\n2000 POINTS");
			add_score(2000);
			kill_paddle();
		"triple":
			notify("TRIPLE BALLS\n\n100 POINTS");
			add_score(100);
			for ball:Ball in get_tree().get_nodes_in_group('Ball').duplicate():
				if ball.lost: continue
				if ball.get_parent() == paddle:
					spawn_ball(false, ball.global_position - Vector2(0, 1), Vector2.UP.rotated(PI/8))
					spawn_ball(false, ball.global_position - Vector2(0, 1), Vector2.UP.rotated(-PI/8))
				else:	
					spawn_ball(false, ball.global_position, ball.dir.rotated(PI/8))
					spawn_ball(false, ball.global_position, ball.dir.rotated(-PI/8))

func add_speed_mult(add:bool = true):
	var previous:float = speed_mult;
	var amount:float = .1;
	var visual_amount:int = 1; 
	if not add:
		amount = -amount;
		visual_amount = -visual_amount;

	speed_mult = clampf(speed_mult + amount, 0.7, 1.5);
	visual_speed_mult = clampi(visual_speed_mult + visual_amount, 0, 8); # TODO Split into two meters, 1,5 green, 0,-3 red, neutral difficulty at 1
	change_speed.emit(speed_mult, true);
	if speed_mult == 1.5 && speed_mult > previous:
		add_score(800);
		notify("SENSATIONAL!\nMAX SPEED\n\n1000 POINTS");

	if speed_meter: speed_meter.value = visual_speed_mult;

func reset_speed_mult(): # TODO Add difficulty
	speed_mult = 1;
	visual_speed_mult = 3;
	if speed_meter: speed_meter.value = visual_speed_mult;
	change_speed.emit(speed_mult, true) # Reset speed

func add_magnet():
	if is_instance_valid(paddle):
		var power:int = paddle.add_magnet();
		if magnet_meter: magnet_meter.value = power;

func load_level(dir:String) -> bool:
	if not DirAccess.dir_exists_absolute(dir): return false

	var level_data:LevelData = load(dir + "data.tres");
	if not level_data: return false;
	

	var level_content_scene = load(dir + "level.tscn");
	if not level_content_scene: return false;

	var new_level_content:Node2D = level_content_scene.instantiate();
	new_level_content.name = "LevelContent";
	$LevelContentOffset.add_child(new_level_content, true);
	new_level_content.position = Vector2.ZERO;
	level_content = new_level_content;
	
	if level_data.build_number != current_build_number:
		upgrade_version(level_data);

	level_content_bricks = level_content.find_child("Bricks");
	level_content_paths = level_content.find_child("BrickPaths").find_child("Paths");
	level_content_path_visuals = level_content.find_child("BrickPaths").find_child("Visuals");
	level_content_path_visuals.hide();

	background.retrigger(); # Might tie to level data in the future
	await position_arm(Vector2(-50, -50), false);

	for brick:Node2D in get_tree().get_nodes_in_group("Brick"):
		init_brick(brick, true);
		#call_deferred("position_arm", brick.global_position);
		await position_arm(brick.global_position);
		brick.show();
	
	for path:Path2D in level_content_paths.get_children():
		init_path(path, 2, true); # Parametrize time, parametrize looping
	
	await position_arm(Vector2(-50, -50), false);
	await get_tree().create_timer(.5).timeout;

	return true;

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

			for node:Node2D in level_content.get_children():
				if node.is_in_group("Brick"):
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
	upgrade_version(data);

func save_gamedata():
	var data:SaveGameData = SaveGameData.new();
	data.level_path = campaign_path + "/" + campaign_num + "/" + level_num;
	data.score = unsaved_score;
	data.lives = unsaved_lives;
	data.total_lives = unsaved_total_lives;
	
	var err = ResourceSaver.save(data, "user://SaveGameData.tres");
	if err != OK:
		print("Level data save error: " + error_string(err));
		ResourceSaver.save(data, "user://SaveGameData.tres");

	return true;

func load_gamedata():
	await load_level(save_state.level_path);
	score = save_state.score;
	lives = save_state.lives;
	total_lives = save_state.total_lives;
	unsaved_score = score;
	unsaved_lives = lives;
	unsaved_total_lives = total_lives;
