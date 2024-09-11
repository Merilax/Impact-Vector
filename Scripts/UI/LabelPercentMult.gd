extends Label

func _ready():
	text = '100%'

func set_mult(mult:float):
	text = str(100 * mult) + '%'