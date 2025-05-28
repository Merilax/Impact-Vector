extends Node2D
class_name PickupComponent

@export var pickup_type:String;
@export var pickup_sprite:String;

@export var shader_target:Brick;

var tween:Tween;

func _ready():
    # Desync glow from other bricks
    await get_tree().create_timer(randf_range(0, 2)).timeout;
    shader_target.texture_manager.tween_shader_modulation(Color(1, .9, .2), 0.3, true, true, 0.35, randf_range(1.5, 2.5));
