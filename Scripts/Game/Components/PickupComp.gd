extends Node2D
class_name PickupComponent

@export var pickup_type:String
@export var pickup_sprite:String

@export var shader_target:Sprite2D

var glowing:bool = false
var tween:Tween

func _process(_delta):
    glow()
    
func glow():
    if glowing:
        return
    
    glowing = true
    var return_color:Color = shader_target.material.get_shader_parameter("to")

    await get_tree().create_timer(2.5).timeout
    tween = get_tree().create_tween()
    await tween.tween_method(func(value): shader_target.material.set_shader_parameter("to", value), return_color, Color(1, .9, .2), 0.3).finished
    
    await get_tree().create_timer(0.35).timeout
    tween = get_tree().create_tween()
    await tween.tween_method(func(value): shader_target.material.set_shader_parameter("to", value), Color(1, .9, .2), return_color, 0.3).finished

    glowing = false