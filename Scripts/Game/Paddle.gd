extends Node2D
class_name Paddle

@export var hit_sound_comp:AudioStreamPlayer2D
@export var magnet_sound:AudioStreamPlayer2D
@export var turrets_comp:TurretsComponent

var magnetised:bool = false
var single_use_magnet:bool = false
var width:float = 0
var balls:Array = []
var magnet_power:int = 0 # Decouple 

var active_turrets:bool = false

@onready var hitbox = $'Hitbox'

signal spawn_bullet(pos:Vector2, dir:float)

func _ready():
	hitbox.body_entered.connect(_on_body_entered_hitbox)
	hitbox.area_entered.connect(_on_area_entered_hitbox)
	width = $'Sprite2D'.get_rect().size.x * $'Sprite2D'.scale.x

	if turrets_comp:
		turrets_comp.spawn_bullet.connect(_on_turrets_fire)
		turrets_comp.expire.connect(_on_turrets_expire)

func _process(_delta):
	self.position.x = get_global_mouse_position().x
	self.position.x = clampf(self.position.x, $"../WorldBorder/WallL".position.x + width/2, $"../WorldBorder/WallR".position.x - width/2)

	if Input.is_action_pressed("mouse_primary"):
		if magnetised or single_use_magnet:
			release_magnet()

		if turrets_comp:
			turrets_comp.fire()

func _on_turrets_fire(pos:Vector2, dir:float):
	spawn_bullet.emit(pos, dir)

func _on_turrets_expire():
	active_turrets = false

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

func receive_ball(ball:Ball):
	if (magnetised or single_use_magnet) and balls.size() < magnet_power:
		ball.freeze = true
		ball.dir = Vector2.ZERO
		ball.reparent(self)

		balls.append(ball)
		if magnet_sound:
			magnet_sound.play()
	else:
		ball.dir = calculate_bounce_vector(ball)

		if hit_sound_comp: hit_sound_comp.play()
		
		await get_tree().create_tween().tween_property($Sprite2D, "position", Vector2(0, 10), 0.1).set_ease(Tween.EASE_OUT).finished
		get_tree().create_tween().tween_property($Sprite2D, "position", Vector2(0, 0), 0.1).set_ease(Tween.EASE_IN)

func release_magnet():
	single_use_magnet = false
	for ball:Ball in balls:
		ball.call_deferred("reparent", $"../Balls") # Decouple
		ball.dir = calculate_bounce_vector(ball)
		ball.freeze = false
	balls.clear()

func add_magnet(single_use:bool = false):
	if magnetised:
		magnet_power += 1
	else:
		reset_powers()
		if single_use: single_use_magnet = true
		else: magnetised = true
		magnet_power = 1

func activate_turrets():
	if magnetised or single_use_magnet:
		release_magnet()
	reset_powers()
	turrets_comp.activate()

func reset_powers():
	active_turrets = false
	turrets_comp.deactivate()

	if magnetised or single_use_magnet:
		release_magnet()
	magnetised = false
	single_use_magnet = false

func die():
	if magnetised or single_use_magnet:
		release_magnet()
	queue_free()
