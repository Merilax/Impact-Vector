extends Node2D
class_name ScoreComponent

@export var score:int = 0

signal process_score(score:int)

func emit_score():
	process_score.emit(score)