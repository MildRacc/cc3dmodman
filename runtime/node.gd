extends Node

func _ready():
    randomize()
    if not get_tree().root.has_meta("mods_initialized"):
        get_tree().root.set_meta("mods_initialized", true)
        init_mod_api()
        preload_mods()
        initialise_game()
        loadData()
        load_mods()
    else:
        initialise_game()
        loadData()

func init_mod_api():
    print("[Mod Loader] Initializing ModAPI...")
    var api_path = "res://mod_api.gd"
    if not ResourceLoader.exists(api_path):
        print("[Mod Loader] ERROR: mod_api.gd not found!")
        return

    var api_script = load(api_path)
    if api_script == null:
        print("[Mod Loader] ERROR: Failed to load mod_api.gd!")
        return

    var api = api_script.new()
    if api == null:
        print("[Mod Loader] ERROR:  Failed to create ModAPI instance!")
        return

    api.name = "ModAPI"
    get_tree().root.call_deferred("add_child", api)
    print("[Mod Loader] ModAPI initialized")

func preload_mods():
    print("[Mod Loader] Preloading mods...")
    var mods_dir = "res://mods/"
    var dir = DirAccess.open(mods_dir)
    if dir == null:
        print("[Mod Loader] No mods directory found")
        return

    dir.list_dir_begin()
    var folder = dir.get_next()
    while folder != "":
        if dir.current_is_dir() and folder != "." and folder != "..":
            var preload_path = mods_dir + folder + "/preload.gd"
            if ResourceLoader.exists(preload_path):
                print("[Mod Loader] Running preload: " + folder)
                var script = load(preload_path)
                var instance = script.new()
                if instance.has_method("mod_preload"):
                    instance.mod_preload()
        folder = dir.get_next()
    dir.list_dir_end()

func load_mods():
    print("[Mod Loader] Loading mods...")
    var mods_dir = "res://mods/"
    var dir = DirAccess.open(mods_dir)
    if dir == null:
        return

    dir.list_dir_begin()
    var folder = dir.get_next()
    while folder != "":
        if dir.current_is_dir() and folder != "." and folder != "..":
            var main_path = mods_dir + folder + "/main.gd"
            if ResourceLoader.exists(main_path):
                print("[Mod Loader] Loading: " + folder)
                var mod = load(main_path).new()
                mod.name = folder
                get_tree().root.call_deferred("add_child", mod)
        folder = dir.get_next()
    dir.list_dir_end()

func initialise_game():
    if ResourceLoader.exists("user://savefile.tres"):
        print("Savefile Exists; Skipping Initialisation")
    else:
        var data = SaveData.new()
        data.savename = "Nardo Polo"
        data.saveunlockedlevels = 1
        data.mastervol = 0
        data.musicvol = 0
        data.beatenlevels = 0
        ResourceSaver.save(data, "user://savefile.tres")
        print("Savefile not found; Initialising")

func loadData():
    var data = ResourceLoader.load("user://savefile.tres") as SaveData
    Global.unlockedlevels = data.saveunlockedlevels
    Global.playername = data.savename
    Global.beatenlevels = data.beatenlevels
    AudioServer.set_bus_volume_db(0, data.mastervol)
    AudioServer.set_bus_volume_db(1, data.musicvol)
    if data.fullscreen:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    print("Loaded with name " + Global.playername + " and " + str(Global.unlockedlevels) + " unlocked levels")

func uiHover():
    $Uihover.play()

func uiPress():
    $Uipress.play()

func uiRelease():
    $Uirelease.play()

func _on_ng_pressed() -> void:
    get_tree().change_scene_to_file("res://worldmap.tscn")

func _on_opt_pressed() -> void:
    get_tree().change_scene_to_file("res://options.tscn")

func _on_quit_pressed() -> void:
    $quit.disabled = true
    $opt.disabled = true
    $ng.disabled = true
    $Baa.pitch_scale = randf_range(0.7, 1.3)
    $Baa.play()

func _on_ng_mouse_entered() -> void:
    uiHover()
func _on_opt_mouse_entered() -> void:
    uiHover()
func _on_quit_mouse_entered() -> void:
    uiHover()

func _on_ng_button_up() -> void:
    uiRelease()
func _on_ng_button_down() -> void:
    uiPress()

func _on_opt_button_up() -> void:
    uiRelease()
func _on_opt_button_down() -> void:
    uiPress()
func _on_quit_button_down() -> void:
    uiPress()
func _on_quit_button_up() -> void:
    uiRelease()

func _on_baa_finished() -> void:
    get_tree().quit()
