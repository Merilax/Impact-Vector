extends AudioStreamPlayer

var track_type:String = ""

func set_track_type(type:String):
    if type.to_lower() == track_type.to_lower(): return

    match type.to_lower():
        "mainmenu":
            var dir:DirAccess = DirAccess.open("res://Assets/Audio/Music/MainMenu/")
            if dir:
                track_type = "MainMenu"
                stop()
                play_set_type()
        "ingame":
            var dir:DirAccess = DirAccess.open("res://Assets/Audio/Music/InGame/")
            if dir:
                track_type = "InGame"
                stop()
                play_set_type()

func play_set_type():
    match track_type.to_lower():
        "mainmenu":
            var dir:DirAccess = DirAccess.open("res://Assets/Audio/Music/MainMenu/")
            var files:PackedStringArray = dir.get_files()
            if files.size() > 0:
                var track_file = ("res://Assets/Audio/Music/MainMenu/" + files[randi_range(0, files.size() - 1)].trim_suffix(".remap")).split(".import", false)[0]
                var track:AudioStream = ResourceLoader.load(track_file)
                self.stream = track
        "ingame":
            var dir:DirAccess = DirAccess.open("res://Assets/Audio/Music/InGame/")
            var files = dir.get_files()
            if files.size() > 0:
                var track_file = ("res://Assets/Audio/Music/InGame/" + files[randi_range(0, files.size() - 1)].trim_suffix(".remap")).split(".import", false)[0]
                var track:AudioStream = ResourceLoader.load(track_file)
                self.stream = track

    play()
    await finished
    play_set_type()