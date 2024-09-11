extends Node2D
class_name PickupComponent

@export var pickup:PackedScene
@export var sprite:Sprite2D

var glowing:bool = false
var tween:Tween

func _process(_delta):
    glow()
    
func glow():
    if glowing:
        return
    glowing = true
    await get_tree().create_timer(2.5).timeout
    tween = get_tree().create_tween()
    await tween.tween_property(sprite, "self_modulate", Color8(255, 255, 100), 0.3).finished
    await get_tree().create_timer(0.25).timeout
    tween = get_tree().create_tween()
    await tween.tween_property(sprite, "self_modulate", Color8(255, 255, 255), 0.3).finished
    glowing = false