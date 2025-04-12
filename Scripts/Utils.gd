extends Node

func decompose_vector2_array(array:PackedVector2Array) -> Array[Dictionary]:
	var new_array:Array[Dictionary] = [];
	for vector in array.duplicate():
		new_array.append({"x": vector.x, "y": vector.y});

	return new_array;

func compose_vector2_array(array:Array) -> PackedVector2Array:
	var new_array:PackedVector2Array = [];
	for vector in array.duplicate():
		new_array.append(Vector2(vector.x, vector.y));

	return new_array;