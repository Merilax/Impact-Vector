extends Label

func _ready():
	text = '0'

func add_score(amount:int):
	var score:int = text.to_int()
	score += amount
	text = str(score)