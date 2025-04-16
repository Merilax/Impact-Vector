extends Node
class_name Logger;

# var logger:FileAccess;

# func _ready():
#     return;
#     @warning_ignore("unreachable_code")
#     var ok:int;
#     if not DirAccess.dir_exists_absolute("user://game-logs/"):
#         ok = DirAccess.make_dir_absolute("user://game-logs/");
#         if ok != OK:
#             print("Couldn't initialize logger: " + error_string(ok));
#             return;
    
#     DirAccess.remove_absolute("user://game-logs/latest.txt");
#     logger = FileAccess.open("user://game-logs/latest.txt", FileAccess.WRITE);
#     if not logger:
#         print("Couldn't initialize logger: " + error_string(FileAccess.get_open_error()));
#         return;

# Logger.write(str(""), "");
static func write(text:String, origin:String = "Undefined") -> void:
    if text.is_empty(): return;
    var line:String = str(Time.get_time_string_from_system(), " [", origin, "] ", text);
    print(line);
    # if logger:
    #     logger.store_line(line);
    #     flush();

# func flush() -> void:
#     if logger:
#         logger.flush();
