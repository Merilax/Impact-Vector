extends RigidBody2D

@export var health_comp:HealthComponent
@export var score_comp:ScoreComponent
@export var hit_sound_comp:AudioStreamPlayer2D
@export var destroy_sound_comp:AudioStreamPlayer2D
@export var pickup_comp:PickupComponent
@export var editor_hitbox:EditorHitboxComponent

signal process_score(score:int)
signal brick_destroyed()

func _ready():
	if health_comp:
		health_comp.health = 2
		health_comp.health_depleted.connect(die.bind())

	if score_comp:
		score_comp.process_score.connect(add_score.bind())

func hit(ball):
	if ball.is_in_group('Ball'):
		if hit_sound_comp:
			hit_sound_comp.play()
		if health_comp:
			health_comp.damage(ball.damage)

func die():
	$'CollisionPolygon2D'.disabled = true
	$'Sprite2D'.hide()
	if score_comp:
		score_comp.emit_score()
	brick_destroyed.emit()

	if pickup_comp:
		var pickup:Area2D = pickup_comp.pickup.instantiate()
		add_sibling(pickup)
		pickup.global_position = self.global_position

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
