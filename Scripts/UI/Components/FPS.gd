extends Label
class_name FPSCounter

func _process(_delta):
    text = str("FPS\n", Engine.get_frames_per_second());