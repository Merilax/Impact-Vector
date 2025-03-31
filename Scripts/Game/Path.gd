extends Path2D
class_name BrickPath

var speed:float = 250;
var looped:bool = false;

@export var follower:PathFollow2D;
@export var transformer:RemoteTransform2D;
@export var line:Line2D;
@export var points_node:Node2D;
@export var transform_target:Node2D;

func _ready():
    if transform_target and transformer:
        self.transformer.remote_path = self.transformer.get_path_to(transform_target);
