extends Node2D

@export var transition_wall_up:Sprite2D;
@export var transition_wall_down:Sprite2D;
@export var open_sound:AudioStreamPlayer;
@export var close_sound:AudioStreamPlayer;

func close_transition_walls() -> bool:
	close_sound.play();
	transition_wall_up.show();
	transition_wall_down.show();

	var tween := get_tree().create_tween();
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN);
	tween.tween_property(transition_wall_up, "global_position:y", transition_wall_up.global_position.y + (transition_wall_up.get_rect().size.y * transition_wall_up.scale.y), 0.5);
	tween.set_parallel();
	tween.tween_property(transition_wall_down, "global_position:y", transition_wall_down.global_position.y - (transition_wall_down.get_rect().size.y * transition_wall_down.scale.y), 0.5);
	await tween.finished;

	return true;

func open_transition_walls() -> bool:
	open_sound.play();

	var tween := get_tree().create_tween();
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT);
	tween.tween_property(transition_wall_up, "global_position:y", transition_wall_up.global_position.y - (transition_wall_up.get_rect().size.y * transition_wall_up.scale.y), 0.6);
	tween.set_parallel();
	tween.tween_property(transition_wall_down, "global_position:y", transition_wall_down.global_position.y + (transition_wall_down.get_rect().size.y * transition_wall_down.scale.y), 0.6);
	await tween.finished;

	transition_wall_up.hide();
	transition_wall_down.hide();
	return true;