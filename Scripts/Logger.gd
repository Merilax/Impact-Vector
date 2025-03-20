extends Node

var logger:FileAccess
var logger_backup:FileAccess

# Logger.write(str(""), "");

func _ready():
    var ok:int;
    if not DirAccess.dir_exists_absolute("user://game-logs/"):
        ok = DirAccess.make_dir_absolute("user://game-logs/");
        if ok != OK:
            print("Couldn't initialize logger: " + error_string(ok));
            return;
    
    DirAccess.remove_absolute("user://game-logs/latest.txt");
    logger = FileAccess.open("user://game-logs/latest.txt", FileAccess.WRITE);
    logger_backup = FileAccess.open("user://game-logs/log" + Time.get_datetime_string_from_system().replace(':', '.') + ".txt", FileAccess.WRITE);
    if not logger:
        print("Couldn't initialize logger: " + error_string(FileAccess.get_open_error()));
        return;

func write(text:String, origin:String = "Undefined"):
    if text.is_empty(): return;
    var line:String = str(Time.get_time_string_from_system(), " [", origin, "] ", text);
    print(line);
    if logger:
        logger.store_line(line);
        logger_backup.store_line(line);
        flush();

func flush():
    if not logger: return;
    logger.flush();
    logger_backup.flush();
