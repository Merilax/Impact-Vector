extends RigidBody2D

@export var texture_path:String # Keep empty to use default editor sprite
@export var shader_color:Color = Color(1, 1, 1)

@export var health_comp:HealthComponent
@export var score_comp:ScoreComponent
@export var hit_sound_comp:AudioStreamPlayer2D
@export var destroy_sound_comp:AudioStreamPlayer2D
@export var pickup_comp:PickupComponent
@export var editor_hitbox:EditorHitboxComponent

signal process_score(score:int)
signal spawn_pickup(global_position:Vector2, type:String, texture:String)
signal brick_destroyed()

func _ready():
	if texture_path:
		$Sprite2D.texture = load(texture_path)
	if shader_color:
		$Sprite2D.material.set_shader_parameter("to", shader_color)

	if health_comp:
		health_comp.health = 2 # TODO editor
		health_comp.health_depleted.connect(die.bind())

	if score_comp:
		score_comp.process_score.connect(add_score.bind())

func hit(node):
	if node.is_in_group('Ball'):
		if hit_sound_comp:
			hit_sound_comp.play()
		if health_comp:
			health_comp.damage(node.damage)
		
	if node.is_in_group('Bullet'):
		health_comp.damage(node.damage)

func die():
	$'CollisionPolygon2D'.disabled = true
	$'Sprite2D'.hide()
	if score_comp:
		score_comp.emit_score()
	brick_destroyed.emit()

	if pickup_comp:
		spawn_pickup.emit(self.global_position, pickup_comp.pickup_type, pickup_comp.pickup_sprite)

	if destroy_sound_comp and hit_sound_comp:
		hit_sound_comp.stop()
		destroy_sound_comp.play()
		await destroy_sound_comp.finished
	elif destroy_sound_comp:
		destroy_sound_comp.play()
		await destroy_sound_comp.finished
	elif hit_sound_comp:
		await hit_sound_comp.finished

	self.queue_free()

func add_score(score:int):
	process_score.emit(score)

func set_shader_color(color:Color):
	$Sprite2D.material.set_shader_parameter("to", color)