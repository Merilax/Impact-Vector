extends Path2D
class_name BrickPath

var PathPointVisual = preload("uid://bkbhsiv24h3ro");

@export var speed:float = 100;
@export var looped:bool = false;
@export var apply_rotation:bool = false;
@export var steps:float = 1;

@export var line:Line2D;
@export var points_node:Node2D;
@export var follower_array:Array[PathFollow2D];
@export var transform_target:Node2D;

var tweens:Array[Tween] = [];

func _ready():
	follower_array.clear();	
	setup_visuals();
		
func play_tweens(play:bool):
	if play:
		for tween in tweens: tween.play();
	else:
		for tween in tweens: tween.pause();

func reset_tweens():
	for tween in tweens: tween.stop();

func setup_steps():
	var temp_arr:Array[PathFollow2D] = [];
	for i:int in range(0, follower_array.size()):
		if i < steps:
			temp_arr.append(follower_array[i]);
			continue;
		elif is_instance_valid(follower_array[i]): follower_array[i].queue_free();
			
	# await get_tree().process_frame;
	follower_array.clear();
	follower_array = temp_arr;
	
	for i:int in range(0, steps):
		if i < follower_array.size(): continue;
		var step_offset:Node2D = transform_target.get_child(i);

		var new_follower := PathFollow2D.new();
		self.add_child(new_follower);
		if self.curve.point_count >= 2:
			new_follower.progress_ratio = 0;
		follower_array.append(new_follower);

		var new_transform := RemoteTransform2D.new();
		new_transform.update_scale = false;
		new_transform.update_rotation = apply_rotation;
		new_follower.add_child(new_transform);
		new_transform.position = Vector2.ZERO;

		if self.curve.point_count >= 2:
			step_offset.global_position = new_transform.global_position;

		new_transform.remote_path = new_transform.get_path_to(step_offset);
		
	reposition_steps();
	setup_tweens();

func setup_visuals():
	if self.curve.point_count > 0:
		for i:int in range(0, self.curve.point_count):
			if line: line.add_point(self.curve.get_point_position(i));
			if points_node:
				var node:Node2D = PathPointVisual.instantiate();
				node.set_meta("point_idx", i);
				points_node.add_child(node);
				node.global_position = self.curve.get_point_position(i);

func setup_tweens():
	if self.speed == 0: return;

	var min_speed := 0;
	var max_speed := 100;
	var min_time := 10;
	var max_time := 0.15;
	var time = (self.speed - min_speed) * (max_time - min_time) / (max_speed - min_speed) + min_time; # linear interpolation

	for follower in follower_array:
		var tween:Tween = follower.create_tween().set_loops();
		if self.looped:
			tween.tween_property(follower, "progress_ratio", 1, time * (1 - follower.progress_ratio)).from(follower.progress_ratio);
			tween.tween_property(follower, "progress_ratio", follower.progress_ratio, time * follower.progress_ratio).from(0);
		
		if not self.looped:
			tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT);
			tween.tween_property(follower, "progress_ratio", 1, time).from(follower.progress_ratio);
			tween.tween_property(follower, "progress_ratio", follower.progress_ratio, time).from(1);
		tween.stop();
		tweens.append(tween);

func reposition_steps():
	if self.curve.point_count < 2: return;

	var section:float = (1 / clampf(steps - 1, 1, 99999));
	if self.looped:
		section = (1 / steps);

	for i:int in range(follower_array.size()):
		follower_array[i].progress_ratio = clampf(section * i, 0, 1);
