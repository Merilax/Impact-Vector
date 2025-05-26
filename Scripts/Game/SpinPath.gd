extends Node2D
class_name SpinPath

var PathPointVisual = preload("uid://bkbhsiv24h3ro");

@export var speed:float = 100;
@export var looped:bool = false;
@export var apply_rotation:bool = true;
@export var steps:float = 1;
@export var rotate_by:float = 0;
@export var apply_rotation_equally:bool = true;

@export var stepper_array:Array[Node2D] = [];
@export var transform_target:Node2D;
@export var center_transformer:RemoteTransform2D;
@export var visuals_node:Node2D;
@export var visuals_center_node:Node2D;

var transformers:Array[RemoteTransform2D] = [];
var bricks:Array[Dictionary] = []; # Only utilized for loading saved data.

var tweens:Array[Tween] = [];

func _ready():
	stepper_array.clear();
	setup_visuals();

func setup():
	center_transformer.remote_path = center_transformer.get_path_to(transform_target);

	for i:int in range(steps):
		if i < stepper_array.size(): continue;
		var new_stepper := Node2D.new();
		new_stepper.name = str("Stepper", i); 
		self.add_child(new_stepper, true);
		stepper_array.append(new_stepper);

	reposition_steps();
	setup_tweens();

func play_tweens(play:bool):
	if play:
		for tween in tweens: tween.play();
	else:
		for tween in tweens: tween.pause();

func reset_tweens():
	for tween in tweens: tween.stop();

func setup_tweens():
	for tween in tweens: tween.kill();
	tweens.clear();
	if self.speed == 0: return;

	var min_speed := 0;
	var max_speed := 100;
	var min_time := 10;
	var max_time := 0.15;
	var time = (self.speed - min_speed) * (max_time - min_time) / (max_speed - min_speed) + min_time; # linear interpolation

	for i:int in range(stepper_array.size()):
		var stepper = stepper_array[i];
		var tween:Tween = stepper.create_tween().set_loops();
		var starting_angle = stepper.rotation_degrees; # 0 if not looped and not applied equally.

		if self.looped:
			var fract_angle = starting_angle / rotate_by;
			if rotate_by == 0: fract_angle = 0;
			if apply_rotation_equally:
				# Wrap-around, steppers move as one group and overshoot final angle.
				tween.tween_property(stepper, "rotation_degrees", rotate_by + starting_angle, time).from(starting_angle);
			else:
				# Wrap-around, steppers move individually and wrap around final angle.
				tween.tween_property(stepper, "rotation_degrees", rotate_by, time * (1 - fract_angle)).from(starting_angle);
				tween.tween_property(stepper, "rotation_degrees", starting_angle, time * fract_angle).from(0);

		if not self.looped:
			tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT);

			if apply_rotation_equally:
				# Back and forth, steppers start spread out, steppers overshoot final angle.
				tween.tween_property(stepper, "rotation_degrees", rotate_by + starting_angle, time).from(starting_angle);
			else:
				# Back and forth, steppers start from 0, steppers spread out up to final angle.
				if steps == 1:
					tween.tween_property(stepper, "rotation_degrees", rotate_by, time).from(starting_angle);
				else:
					tween.tween_property(stepper, "rotation_degrees", (rotate_by / clampf(steps-1, 1, INF)) * i, time).from(starting_angle);
			tween.tween_property(stepper, "rotation_degrees", starting_angle, time);

		tween.stop();
		tweens.append(tween);

func setup_visuals():
	for node in visuals_node.get_children():
		node.queue_free();

	var amount := steps as int;
	if looped and not apply_rotation_equally:
		amount += 1;
	amount = clampi(amount, 2, 9999);
	for i:int in range(amount):
		var line := Line2D.new();
		line.width = 3;
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND;
		line.end_cap_mode = Line2D.LINE_CAP_ROUND;
		if i == 0 or i == amount-1: line.default_color = Color(1, 0.1, 0.1, 1); 

		visuals_node.add_child(line);
		line.add_point(Vector2(0,0));
		line.add_point(Vector2(160,0));
		line.position = Vector2.ZERO;
		# if amount <= 1:
			# line.rotation_degrees = rotate_by;
		# else:
		line.rotation_degrees = (rotate_by / (amount-1)) * i;

func adjust_steps() -> Array[Brick]:
	var created_bricks:Array[Brick] = [];
	var temp_arr:Array[Node2D] = [];
	for i:int in range(0, stepper_array.size()):
		if i < steps:
			temp_arr.append(stepper_array[i]);
			continue;
		elif is_instance_valid(stepper_array[i]): stepper_array[i].queue_free();
			
	stepper_array.clear();
	stepper_array = temp_arr;

	var previous_stepper_count = stepper_array.size();
	for i:int in range(steps):
		if i < stepper_array.size(): continue;
		var new_stepper := Node2D.new();
		new_stepper.name = str("Stepper", i); 
		self.add_child(new_stepper, true);
		stepper_array.append(new_stepper);
					
	for brick:Brick in transform_target.get_child(0).get_children():
		created_bricks.append_array(add_and_position_brick(brick, false, previous_stepper_count));
				
	reposition_steps();
	setup_tweens();

	return created_bricks;

func reposition_steps():
	for i:int in range(stepper_array.size()):
		if looped and not apply_rotation_equally:
			stepper_array[i].rotation_degrees = (rotate_by / steps) * i;
		else:
			stepper_array[i].rotation_degrees = (rotate_by / clampf(steps - 1, 1, INF)) * i;

	setup_tweens();

func reposition_steps_for_play():
	# Modify stepper angles to match starting angle, not preview angle, if necessary.
	for stepper in stepper_array:
		if not looped and not apply_rotation_equally: stepper.rotation_degrees = 0;

	setup_tweens();

func setup_transforms():
	for brick in self.bricks:
		var tform := RemoteTransform2D.new();
		tform.update_scale = false;
		tform.update_rotation = apply_rotation;

		stepper_array[brick.step].add_child(tform);
		tform.global_rotation = brick.brick.global_rotation;
		tform.global_position = brick.brick.global_position;
		tform.remote_path = tform.get_path_to(brick.brick);

		transformers.append(tform);

func update_transforms():
	var temp_arr:Array[RemoteTransform2D] = [];
	for tform in transformers:
		if not is_instance_valid(tform): continue;
		elif not is_instance_valid(tform.get_node_or_null(tform.remote_path)): tform.queue_free();
		else: temp_arr.append(tform);
	await get_tree().process_frame;
	transformers = temp_arr;
	
	for tform in transformers:
		var node:Brick = tform.get_node(tform.remote_path);
		tform.update_rotation = apply_rotation;
		if apply_rotation == false: node.global_rotation = 0;

func add_and_position_brick(brick:Brick, create_first_transform:bool = true, ignore_before_stepper:int = -1) -> Array[Brick]:
	var temp_arr:Array[Brick] = [brick];
	for i:int in range(stepper_array.size()):
		if i < ignore_before_stepper: continue;
		var stepper = stepper_array[i];
		var new_brick := brick;
		
		if i > 0: # Original brick must keep position.
			new_brick = UtilsNode.duplicate_bug_bypass(brick, true);
			transform_target.get_child(i).add_child(new_brick, true);

			new_brick.position = brick.position.rotated(stepper.rotation);
			new_brick.rotation = brick.rotation;
			if apply_rotation:
				new_brick.rotation = brick.rotation + stepper.rotation;
			new_brick.is_path_clone = true;
			new_brick.spin_group = brick.spin_group;
			temp_arr.append(new_brick);

		if i > 0 or create_first_transform:
			var new_transform := RemoteTransform2D.new();
			new_transform.update_scale = false;
			new_transform.update_rotation = apply_rotation;
			stepper.add_child(new_transform);
			new_transform.global_position = new_brick.global_position;
			new_transform.global_rotation = new_brick.global_rotation;

			new_transform.remote_path = new_transform.get_path_to(new_brick);
			transformers.append(new_transform);
	return temp_arr;
