extends Node2D
class_name PickupComponent

@export var pickup_type:String
@export var pickup_sprite:String

@export var shader_target:Brick

var glowing:bool = false
var tween:Tween

func _process(_delta):
    glow()
    
func glow():
    if glowing:
        return
    
    glowing = true
    var return_color:Color = shader_target.get_shader_color()

    await get_tree().create_timer(2.5).timeout
    await shader_target.tween_shader_color(Color(1, .9, .2), 0.3)
    
    await get_tree().create_timer(0.35).timeout
    await shader_target.tween_shader_color(return_color, 0.3)

    glowing = false