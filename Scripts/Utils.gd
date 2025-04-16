extends Node
class_name Utils;

static func decompose_vector2_array(array:PackedVector2Array) -> Array[Dictionary]:
	var new_array:Array[Dictionary] = [];
	for vector in array.duplicate():
		new_array.append({"x": vector.x, "y": vector.y});

	return new_array;

static func compose_vector2_array(array:Array) -> PackedVector2Array:
	var new_array:PackedVector2Array = [];
	for vector in array.duplicate():
		new_array.append(Vector2(vector.x, vector.y));

	return new_array;

static func upgrade_level_version(data:LevelData, level_dict:Dictionary, current_build_number:int, directory:String) -> bool:
	if data.build_number < current_build_number:
		match data.build_number:
				1:
					level_dict["last_saved"] = str(Time.get_unix_time_from_system());
					
		data.build_number += 1;
		Logger.write(str("Upgraded to build ", data.build_number, ", checking for further steps."), "Utils");
		return upgrade_level_version(data, level_dict, current_build_number, directory.trim_suffix('/'));
	else:
		var err := ResourceSaver.save(data, directory.trim_suffix('/') + "/data.tres");
		if err != OK:
			Logger.write("Level data save error: " + error_string(err), "Utils");
			return false;

		var json := JSON.stringify(level_dict, "", false, true);
		var writer := FileAccess.open(directory.trim_suffix('/')  + "/level.json", FileAccess.WRITE);
		if writer == null:
			Logger.write("Level JSON save error." + error_string(FileAccess.get_open_error()), "Utils");
			return false;
		writer.store_string(json);
		writer.close();
		return true;