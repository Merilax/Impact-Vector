extends Node2D
class_name Game

var current_build_number:int = 2;

var campaign_path:String
var campaign_num:String
var level_num:String

var save_state:SaveGameData;

# Higher weight = More spawns.
var pickup_list:Array = [ 
	{
		"type": "slow",
		"name": "Speed down",
		"texture": "uid://caxekbaxpxgvy",
		"weight": 10
	},
	{
		"type": "speed",
		"name": "Speed up",
		"texture": "uid://b2ufqhunhh27l",
		"weight": 10
	},
	{
		"type": "narrow",
		"name": "Smaller paddle",
		"texture": "uid://1sfr7xkm72ia",
		"weight": 10
	},
	{
		"type": "wide",
		"name": "Bigger paddle",
		"texture": "uid://be6sue13o1ueb",
		"weight": 10
	},
	{
		"type": "small",
		"name": "Smaller balls",
		"texture": "uid://bx32kafyc2ca6",
		"weight": 8
	},
	{
		"type": "big",
		"name": "Larger balls",
		"texture": "uid://cvg4excj60cr3",
		"weight": 8
	},
	{
		"type": "turrets",
		"name": "Turrets",
		"texture": "uid://bsp8gm0swv3kh",
		"weight": 6
	},
	{
		"type": "magnet",
		"name": "Magnet",
		"texture": "uid://dil2gntnddaec",
		"weight": 6
	},
	{
		"type": "triple",
		"name": "Triple balls",
		"texture": "uid://ci00dwenehe35",
		"weight": 6
	},
	{
		"type": "death",
		"name": "Death",
		"texture": "uid://bvc6p2do3llr4",
		"weight": 2
	},
]
var total_pickup_weight:int = 0;

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

var ball_speed_mult:float = 1;
var visual_speed_mult:int = 3;
var ball_size_level:int = 0;

var can_spawn_balls:bool = true;
var ball_stuck_timer:SceneTreeTimer;

@export var notification_text_window:Label;
@export var notification_score_window:Label;
@export var notification_window_timer:Timer;
@export var score_counter:Label;
@export var speed_counter:Label;
@export var life_counter:HBoxContainer;
var BallLifeRect = preload("uid://b5s0bxfmkxjel");

@export var world_border:WorldBorder;
@export var ball_container:Node2D;
var level_content:Node2D;
var level_content_bricks:Node2D;
var level_content_paths:Node2D;
@export var background:Parallax2D;
@export var escape_layer:EscapeLayer;

@export var speed_meter:TextureProgressBar;
@export var magnet_meter:TextureProgressBar;

@export var arm_horizontal:Node2D;
@export var arm_vertical:Node2D;
@export var arm_placer:Node2D;
@export var arm_placer_sound:AudioStreamPlayer;

var transitioning_levels:bool = false;
var skip_animations:bool = false;
var tabbed_out:bool = false;

signal game_over_signal(game_won:bool);
signal change_ball_speed(mult:float, update_counter:bool);
signal change_ball_size(level:int);

func _ready():
	transitioning_levels = true;
	background.retrigger();

	get_window().focus_exited.connect(func(): tabbed_out = true);
	get_window().focus_entered.connect(func(): tabbed_out = false);
	tabbed_out = not get_window().has_focus();

	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN;
	$"DeathZone".body_entered.connect(_on_ball_lost);

	escape_layer.menu_closed.connect(func(): if paddle: DisplayServer.warp_mouse(paddle.global_position)); # Hacky

	if notification_window_timer:
		notification_window_timer.timeout.connect(func(): notification_text_window.text = ""; notification_score_window.text = "");

	for life in lives:
		life_counter.add_child(BallLifeRect.instantiate());

	change_ball_speed.connect(speed_counter.set_mult);

	for i in range(0, pickup_list.size()):
		total_pickup_weight += pickup_list[i].weight;

	if save_state:
		load_gamedata();
	else:
		await load_level(campaign_path + campaign_num + "/" + level_num + "/");

	get_tree().node_added.connect(_on_child_entered_tree);

	transitioning_levels = false;
	await spawn_paddle();
	spawn_ball(true, true);

	Logger.write(str("Ready."), "Level");

func _process(_delta):
	if transitioning_levels and (Input.is_action_pressed("mouse_primary") or Input.is_action_pressed("mouse_secondary")):
		skip_animations = true;

	if paddle and not tabbed_out:
		var mouse_pos = DisplayServer.mouse_get_position();
		if (mouse_pos.x < world_border.wall_left.global_position.x + (paddle.width / 2)):
			DisplayServer.warp_mouse(Vector2i(roundi(world_border.wall_left.global_position.x + (paddle.width / 2)) , mouse_pos.y));
		if (mouse_pos.x > world_border.wall_right.global_position.x - (paddle.width / 2)):
			DisplayServer.warp_mouse(Vector2i(roundi(world_border.wall_right.global_position.x - (paddle.width / 2)) , mouse_pos.y));

func spawn_paddle() -> bool:
	paddle = PaddleScene.instantiate();
	paddle.world_border = world_border;
	paddle.target_ball_container = ball_container;
	add_child(paddle);
	paddle.global_position = Vector2(750, 1120);
	await create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).tween_property(paddle, "global_position:y", 1040, 1).finished;
	DisplayServer.warp_mouse(Vector2i(750, 1040));

	if paddle.has_signal("spawn_bullet"):
		paddle.spawn_bullet.connect(spawn_bullet);

	paddle.follow_mouse = true;
	return true;

func spawn_ball(on_paddle:bool, centered:bool = false, pos:Vector2 = Vector2.ZERO, dir:Vector2 = Vector2.ZERO, add_to_count:bool = true):
	if not can_spawn_balls: return;
	if ball_count >= 100: return;
	else:
		var ball:Ball = BallScene.instantiate();
		ball_container.call_deferred("add_child", ball);

		ball.dir = dir;
		if on_paddle:
			if centered:
				paddle.add_magnet(true);
			ball.set_deferred("global_position", pos);
			paddle.call_deferred("receive_ball", ball, centered);
			#ball.set_deferred("position", Vector2(paddle.global_position.x, paddle.global_position.y - (paddle.get_node("Sprite2D").get_rect().size.y * paddle.get_node("Sprite2D").scale.y)))
		else:
			ball.set_deferred("global_position", pos);
			ball.set_deferred("freeze", false);

		#ball.reset_stuck_timer.connect(_on_ball_reset_stuck_timer)

		ball.speed_mult = ball_speed_mult
		if add_to_count:
			ball_count += 1

func _on_ball_lost(node:Node2D):
	if node.is_in_group("Pickup"):
		await get_tree().create_timer(3).timeout;
		if node:
			node.queue_free();
	
	if node.is_in_group('Ball'):
		node.lost = true;
		node.collision_mask = 0; # Let the ball visibly get lost, eventually dying off-screen

		if transitioning_levels: return;

		ball_count -= 1;

		if ball_count <= 0:
			lives -= 1;
			kill_paddle();

			if lives >= 3:
				var livesVar = life_counter.get_node("LivesVar");
				if lives == 3:
					livesVar.queue_free();
					life_counter.add_child(BallLifeRect.instantiate());
					life_counter.add_child(BallLifeRect.instantiate());
				else:
					livesVar.text = ' x ' + str(lives);
			else:
				life_counter.get_child(0).queue_free();
			
			await get_tree().create_timer(1).timeout;
			node.die();

			if lives <= 0:
				await get_tree().create_timer(2).timeout;
				get_tree().call_group("PickUp", "queue_free");
				game_over(false);
			else:
				await get_tree().create_timer(1).timeout;
				get_tree().call_group("PickUp", "queue_free");
				if not paddle:
					await spawn_paddle();

				spawn_ball(true, true);
				reset_speed_mult();
				ball_size_level = 0;
				change_ball_size.emit(ball_size_level);
				if paddle: paddle.reposition_magnetised_balls();

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

func notify(display_text:String, display_score:String):
	#notification_window_timer.stop();
	notification_text_window.text = display_text;
	notification_score_window.text = display_score;
	notification_window_timer.start();

func game_over(game_won:bool):
	escape_layer.forbid_unescape = true; # Don't let the Escape key do anything anymore, it's over. 
	Logger.write(str("Game over."), "Level");
	can_spawn_balls = false
	if game_won == true:
		DirAccess.remove_absolute("user://SaveGameData.tres");
		Logger.write(str("Deleted game in progress data."), "Level");
	game_over_signal.emit(game_won);

func win():
	Logger.write(str("Transitioning levels."), "Level");
	transitioning_levels = true;
	can_spawn_balls = false;

	var stored_speed_mult = ball_speed_mult;

	create_tween().tween_method(func(speed): change_ball_speed.emit(speed, false), stored_speed_mult, 0, 2.5);

	await get_tree().create_timer(3.5).timeout;

	level_content.queue_free();
	get_tree().call_group("Ball", "queue_free");
	get_tree().call_group("PickUp", "queue_free");
	get_tree().call_group("Brick", "queue_free");

	ball_count = 0;
	ball_speed_mult = 1; # TODO Add difficulty.
	reset_speed_mult();
	ball_size_level = 0;
	change_ball_size.emit(ball_size_level);
	if paddle: paddle.reposition_magnetised_balls();

	unsaved_score = score;
	unsaved_lives = lives;
	unsaved_total_lives = total_lives;
	
	var next_level_num:String = "0";
	
	if campaign_path.contains("res://"):
		next_level_num = str(BaseCampaignManager.find_next_level(campaign_path + campaign_num + '/', level_num.to_int()));
	else: next_level_num = str(CampaignManager.find_next_level(campaign_path + campaign_num , level_num.to_int()));
	
	if next_level_num == "0":
		game_over(true);
		return;
		
	if not FileAccess.file_exists(campaign_path + campaign_num + "/" + next_level_num + "/level.tscn") or not await load_level(campaign_path + campaign_num + "/" + next_level_num + "/"):
		game_over(true);
		return;
	
	Logger.write(str("Next level found: ", next_level_num), "Level");

	level_num = next_level_num;
	save_gamedata();

	transitioning_levels = false;
	skip_animations = false;
	if is_instance_valid(paddle):
		paddle.reset_powers();
	else:
		await spawn_paddle();
	can_spawn_balls = true;
	spawn_ball(true, true);

func _on_child_entered_tree(node:Node):
	if node.is_in_group('Ball'):
		change_ball_speed.emit(ball_speed_mult, false);
		change_ball_size.emit(ball_size_level);
		if paddle: paddle.reposition_magnetised_balls();
		if not self.is_connected('change_ball_speed', node.set_speed):
			change_ball_speed.connect(node.set_speed);
		if not self.is_connected('change_ball_size', node.set_size):
			change_ball_size.connect(node.set_size);

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
			brick_count += 1;
			if randi() % 101 <= 20: # Pickup spawn %
				var pickup_comp:PickupComponent = PickupComp.instantiate();
				brick.add_child(pickup_comp);
				brick.pickup_comp = pickup_comp;
				brick.pickup_comp.shader_target = brick;

				var random_weight = randi() % total_pickup_weight + 1;
				var weight_sum:int = 0;
				for i in range(0, pickup_list.size()):
					weight_sum += pickup_list[i].weight;
					if random_weight <= weight_sum:
						brick.pickup_comp.pickup_type = pickup_list[i].type;
						brick.pickup_comp.pickup_sprite = pickup_list[i].texture;
						break;

func init_path(path:BrickPath):
	var tween:Tween = path.follower.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT).set_loops();
	tween.tween_property(path.follower, "progress_ratio", 1, path.speed / 100).from(0);
	if not path.looped: # Back & forth
		tween.tween_property(path.follower, "progress_ratio", 0, path.speed / 100).from(1);

func kill_paddle():
	if is_instance_valid(paddle):
		paddle.die();
		magnet_meter.value = 0;

var arm_tweener:Tween;
func position_arm(pos:Vector2, play_sound:bool = true) -> bool:
	if skip_animations:
		if arm_tweener: arm_tweener.kill();
		arm_horizontal.global_position.y = -100;
		arm_vertical.global_position.x = -100;
		arm_placer.global_position = Vector2(-100, -100);
		return true;
	
	var duration = (arm_placer.global_position - pos).length() / 2000 / GlobalVars.arm_speed_multiplier;
	arm_tweener = arm_placer.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT);
	arm_tweener.tween_property(arm_horizontal, "global_position:y", pos.y, duration)
	arm_tweener.set_parallel();
	arm_tweener.tween_property(arm_vertical, "global_position:x", pos.x, duration);
	arm_tweener.set_parallel();
	arm_tweener.tween_property(arm_placer, "global_position", pos, duration);
	await arm_tweener.finished;
	arm_placer.get_node("GPUParticles2D").restart();
	if play_sound and arm_placer_sound: arm_placer_sound.play();
	await get_tree().create_timer(.04).timeout;
	return true;

func process_pickup(type:String):
	if transitioning_levels: return;
	if not is_instance_valid(paddle): return;
	# TODO SFX each
	match type.to_lower():
		'speed':
			notify("SPEED UP", "250 POINTS");
			add_score(200);
			add_speed_mult(true);
		'slow':
			notify("SPEED DOWN", "100 POINTS");
			add_score(100);
			add_speed_mult(false);
		"magnet":
			notify("MAGNET STRENGTH UP", "200 POINTS");
			add_score(200);
			add_magnet();
		"turrets":
			notify("RELOAD GUNS", "200 POINTS");
			add_score(200);
			paddle.activate_turrets();
			if magnet_meter: magnet_meter.value = 0;
		"death":
			notify("QUESTIONABLE\nLIFE CHOICES", "2000 POINTS");
			add_score(2000);
			kill_paddle();
		"triple":
			notify("TRIPLE BALLS", "200 POINTS");
			add_score(100);
			for ball:Ball in get_tree().get_nodes_in_group('Ball').duplicate():
				if ball.lost: continue;
				if ball.on_paddle:
					spawn_ball(false, false, ball.global_position, Vector2.UP.rotated(PI/8));
					spawn_ball(false, false, ball.global_position, Vector2.UP.rotated(-PI/8));
				else:	
					spawn_ball(false, false, ball.global_position, ball.dir.rotated(PI/8));
					spawn_ball(false, false, ball.global_position, ball.dir.rotated(-PI/8));
		"wide":
			notify("BIGGER PADDLE", "100 POINTS");
			add_score(100);
			paddle.adjust_size(true);
		"narrow":
			notify("SMALLER PADDLE", "250 POINTS");
			add_score(200);
			paddle.adjust_size(false);
		"big":
			notify("BIGGER BALLS", "100 POINTS");
			add_score(100);
			add_size_level(true);
		"small":
			notify("SMALLER BALLS", "250 POINTS");
			add_score(250);
			add_size_level(false);

func add_speed_mult(add:bool = true):
	var previous:float = ball_speed_mult;
	var amount:float = .1;
	var visual_amount:int = 1; 
	if not add:
		amount = -amount;
		visual_amount = -visual_amount;

	ball_speed_mult = clampf(ball_speed_mult + amount, 0.7, 1.5);
	visual_speed_mult = clampi(visual_speed_mult + visual_amount, 0, 8); # TODO Split into two meters, 1,5 green, 0,-3 red, neutral difficulty at 1
	change_ball_speed.emit(ball_speed_mult, true);
	if ball_speed_mult == 1.5 && ball_speed_mult > previous:
		add_score(800);
		notify("SENSATIONAL!\nMAX SPEED", "1000 POINTS"); # 200 speedup + 800 bonus

	if speed_meter: speed_meter.value = visual_speed_mult;

func add_size_level(add:bool = true):
	var amount:int = 1;

	if not add:
		amount = -amount;
	
	ball_size_level = clampi(ball_size_level + amount, -2, 2);
	change_ball_size.emit(ball_size_level);
	if paddle: paddle.reposition_magnetised_balls();

func reset_speed_mult(): # TODO Add difficulty
	ball_speed_mult = 1;
	visual_speed_mult = 3;
	if speed_meter: speed_meter.value = visual_speed_mult;
	change_ball_speed.emit(ball_speed_mult, true) # Reset speed

func add_magnet():
	if is_instance_valid(paddle):
		var power:int = paddle.add_magnet();
		if magnet_meter: magnet_meter.value = power;

func load_level(dir:String) -> bool:
	Logger.write(str("Loading level at ", dir), "Level");
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
		Logger.write(str("Upgrading level from version ", level_data.build_number), "Level");
		upgrade_version(level_data);

	level_content_bricks = level_content.find_child("Bricks");
	level_content_paths = level_content.find_child("Paths");
	get_tree().call_group("PathLineVisual", "hide");
	get_tree().call_group("PathPointVisual", "hide");

	background.retrigger(); # Might tie to level data in the future
	await position_arm(Vector2(-100, -100), false); # Reset once to sync every arm piece

	Logger.write(str("Initializing Bricks."), "Level");
	for brick:Brick in get_tree().get_nodes_in_group("Brick"):
		init_brick(brick, true);
	
	for brick:Brick in get_tree().get_nodes_in_group("Brick"):
		await position_arm(brick.global_position);
		brick.show();
	
	Logger.write(str("Initializing Paths."), "Level");
	for path:BrickPath in get_tree().get_nodes_in_group("Path"):
		init_path(path);
	
	await position_arm(Vector2(-100, -100), false);
	await get_tree().create_timer(.5).timeout;

	Logger.write(str("Level finished loading."), "Level");
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

			for node:Brick in get_tree().get_nodes_in_group("Brick"):
				node.reparent(new_level_content_bricks);

			# Add Paths container
			var new_level_content_paths := Node2D.new();
			new_level_content_paths.name = "Paths";
			level_content.add_child(new_level_content_paths, true);
			new_level_content_paths.owner = level_content;
			
	data.build_number += 1;
	Logger.write(str("Upgraded to build ", data.build_number, ", checking for further steps."), "LevelEditor");
	upgrade_version(data);

func save_gamedata():
	Logger.write(str("Saving game in progress to storage."), "Level");
	var data:SaveGameData = SaveGameData.new();
	data.level_path = campaign_path + "/" + campaign_num + "/" + level_num;
	data.score = unsaved_score;
	data.lives = unsaved_lives;
	data.total_lives = unsaved_total_lives;
	
	var err = ResourceSaver.save(data, "user://SaveGameData.tres");
	if err != OK:
		Logger.write("Level data save error: " + error_string(err), "Level");
		ResourceSaver.save(data, "user://SaveGameData.tres");

	return true;

func load_gamedata():
	Logger.write(str("Loading game in progress from storage."), "Level");
	await load_level(save_state.level_path);
	score = save_state.score;
	lives = save_state.lives;
	total_lives = save_state.total_lives;
	unsaved_score = score;
	unsaved_lives = lives;
	unsaved_total_lives = total_lives;
