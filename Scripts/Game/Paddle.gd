extends Node2D
class_name Paddle

@export var hit_sound_comp:AudioStreamPlayer2D
@export var magnet_sound:AudioStreamPlayer2D

var magnetised:bool = false
var single_use_magnet:bool = true
var width:float = 0
var balls:Array = []
var magnet_power:int = 1 # Decouple 

@onready var hitbox = $'Hitbox'

func _ready():
	hitbox.body_entered.connect(_on_body_entered_hitbox.bind())
	hitbox.area_entered.connect(_on_area_entered_hitbox.bind())
	width = $'Sprite2D'.get_rect().size.x * $'Sprite2D'.scale.x

func _process(_delta):
	self.position.x = get_global_mouse_position().x
	self.position.x = clampf(self.position.x, $"../WorldBorder/WallL".position.x + width/2, $"../WorldBorder/WallR".position.x - width/2)

	if Input.is_action_pressed("mouse_primary"):
		release_magnet()
		single_use_magnet = false

func _on_body_entered_hitbox(_node:Node2D):
	pass
		
func _on_area_entered_hitbox(node:Area2D):
	if node.is_in_group('PickUp'):
		node.send_signal()

func calculate_bounce_vector(node) -> Vector2:
	var x_diff = node.global_position.x - self.global_position.x
	var calc_x = clampf(x_diff / (width/1.5), -0.75, 0.75) # No 90º bounces
	var calc_y = 1 - abs(calc_x)
	return Vector2(calc_x, -calc_y).normalized()

func receive_ball(ball:RigidBody2D):
	if magnetised or single_use_magnet and balls.size() < magnet_power:
		ball.freeze = true
		ball.linear_velocity = Vector2.ZERO
		ball.reparent(self)

		balls.append(ball)
		if magnet_sound:
			magnet_sound.play()
	else:
		ball.linear_velocity = calculate_bounce_vector(ball)

		if hit_sound_comp: hit_sound_comp.play()
		
		await get_tree().create_tween().tween_property($Sprite2D, "position", Vector2(0, 10), 0.1).finished
		get_tree().create_tween().tween_property($Sprite2D, "position", Vector2(0, 0), 0.1)

func release_magnet():
	for ball:RigidBody2D in balls:
		balls.erase(ball)

		ball.reparent($"../Balls")
		ball.linear_velocity = calculate_bounce_vector(ball)
		ball.freeze = false
