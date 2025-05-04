extends SceneTree

func _init():
    print("Checking for errors in the project...")
    
    # Check level data resources
    check_level_data()
    
    # Exit after checks
    quit()

func check_level_data():
    print("Checking level data resources...")
    
    var dir = DirAccess.open("res://resources/levels")
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        
        while file_name != "":
            if file_name.ends_with(".tres"):
                var path = "res://resources/levels/" + file_name
                print("Checking level: " + path)
                
                var level = load(path)
                if level:
                    print("Level loaded successfully: " + level.level_name)
                    
                    # Check for required properties
                    if level.waves.size() == 0 and level.total_waves > 0:
                        print("WARNING: Level " + level.level_name + " has total_waves > 0 but no waves defined")
                else:
                    print("ERROR: Failed to load level: " + path)
            
            file_name = dir.get_next()
    else:
        print("ERROR: Could not access levels directory")