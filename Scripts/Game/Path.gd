extends Path2D
class_name BrickPath

var PathPointVisual = preload("uid://bkbhsiv24h3ro");

@export var speed:float = 250;
@export var looped:bool = false;
@export var apply_rotation:bool = false;

@export var follower:PathFollow2D;
@export var transformer:RemoteTransform2D;
@export var line:Line2D;
@export var points_node:Node2D;
@export var transform_target:Node2D;

func _ready():
	if transform_target and transformer:
		self.transformer.remote_path = self.transformer.get_path_to(transform_target);
		transformer.update_rotation = apply_rotation;
	
	if self.curve.point_count > 0:
		for i:int in range(0, self.curve.point_count):
			if line: line.add_point(self.curve.get_point_position(i));
			if points_node:
				var node:Node2D = PathPointVisual.instantiate();
				node.set_meta("point_idx", i);
				points_node.add_child(node);
				node.global_position = self.curve.get_point_position(i);
