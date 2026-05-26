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
				2:
					level_dict["spinpaths"] = [];

					for path in level_dict.paths:
						path.speed = clampf(path.speed, 0, 75)
						for vec in path.step_positions:
							vec.x -= 42;

					for brick in level_dict.bricks:
						if brick.path_group > -1:
							# brick.position = {"x": 0, "y": 0}
							brick.position = {
								"x":
									brick.global_position.x - level_dict.paths[brick.path_group].step_positions[brick.path_step].x - 42,
								"y":
									brick.global_position.y - level_dict.paths[brick.path_group].step_positions[brick.path_step].y
							}
						else:
							brick.position = {"x": brick.global_position.x - 0, "y": brick.global_position.y};
						brick.global_position = null;
						brick.rotation_degrees = brick.global_rotation_degrees;
						brick.global_rotation_degrees = null;
						brick.scale = brick.global_scale;
						brick.global_scale = null;
						brick.shader_colors = [brick.shader_color, "#ffffffff", "#ffffffff", "#ffffffff"];
						brick.shader_color_count = 1;
						brick.shader_modulation = "#ffffffff";
						brick.shader_color = null;
						brick.spin_group = -1;
						brick.spin_step = 0;

						match brick.texture_path:
							"res://Assets/Visuals/BrickTextures/Circle/BrickBaseCircle.png":
								brick.texture_path = "res://Assets/Visuals/BrickTextures/Circle/1/BrickBaseCircle.png";
							"res://Assets/Visuals/BrickTextures/Circle/BrickCircle.png":
								brick.texture_path = "res://Assets/Visuals/BrickTextures/Circle/1/BrickCircle.png";
							"res://Assets/Visuals/BrickTextures/Quadrangle/BrickBaseRect.png":
								brick.texture_path = "res://Assets/Visuals/BrickTextures/Quadrangle/1/BrickBaseRect.png";
							"res://Assets/Visuals/BrickTextures/Quadrangle/BrickBaseSqr.png":
								brick.texture_path = "res://Assets/Visuals/BrickTextures/Quadrangle/1/BrickBaseSqr.png";
							"res://Assets/Visuals/BrickTextures/Quadrangle/BrickFullRect.png":
								brick.texture_path = "res://Assets/Visuals/BrickTextures/Quadrangle/1/BrickFullRect.png";
							"res://Assets/Visuals/BrickTextures/Quadrangle/BrickFullSqr.png":
								brick.texture_path = "res://Assets/Visuals/BrickTextures/Quadrangle/1/BrickFullSqr.png";
							"res://Assets/Visuals/BrickTextures/Quadrangle/BrickGlass.png":
								brick.texture_path = "res://Assets/Visuals/BrickTextures/Quadrangle/1/BrickGlass.png";
							"res://Assets/Visuals/BrickTextures/Quadrangle/BrickMetal.png":
								brick.texture_path = "res://Assets/Visuals/BrickTextures/Quadrangle/1/BrickMetal.png";
							"res://Assets/Visuals/BrickTextures/Quadrangle/BrickSpiral.png":
								brick.texture_path = "res://Assets/Visuals/BrickTextures/Quadrangle/1/BrickSpiral.png";
				3:
					level_dict["action_groups"] = [];
					level_dict.action_groups += level_dict.paths;
					level_dict.action_groups += level_dict.spinpaths;
					
					for brick in level_dict.bricks:
						if (brick.path_group >= 0):
							brick.action_group = brick.path_group;
							brick.action_step = brick.path_step;
						if (brick.spin_group >= 0):
							brick.action_group = brick.spin_group + level_dict.paths.size();
							brick.action_step = brick.spin_step;

						brick.path_group = null;
						brick.path_step = null;
						brick.spin_group = null;
						brick.spin_step = null;
					
					level_dict.paths = null;
					level_dict.spinpaths = null;


		data.build_number += 1;
		LoggerFile.write(str("Upgraded to build ", data.build_number, ", checking for further steps."), "Utils");
		return upgrade_level_version(data, level_dict, current_build_number, directory.trim_suffix('/'));
	else:
		var err := ResourceSaver.save(data, directory.trim_suffix('/') + "/data.tres");
		if err != OK:
			LoggerFile.write("Level data save error: " + error_string(err), "Utils");
			return false;

		var json := JSON.stringify(level_dict, "", false, true);
		var writer := FileAccess.open(directory.trim_suffix('/')  + "/level.json", FileAccess.WRITE);
		if writer == null:
			LoggerFile.write("Level JSON save error." + error_string(FileAccess.get_open_error()), "Utils");
			return false;
		writer.store_string(json);
		writer.close();
		return true;