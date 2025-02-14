extends Parallax2D

@export var in_editor:bool = false;

func _ready():
	retrigger()

func retrigger():
	var bgs:PackedStringArray = DirAccess.get_files_at("res://Assets/Visuals/Backgrounds")
	$Sprite2D.texture = ResourceLoader.load("res://Assets/Visuals/Backgrounds/" + bgs[randi() % bgs.size()].trim_suffix(".remap").trim_suffix(".import"))
	repeat_size = $Sprite2D.get_rect().size