extends Label

func _ready():
	text = '100%'

func set_mult(mult:float, update_label:bool):
	if update_label:
		text = str(100 * mult) + '%'