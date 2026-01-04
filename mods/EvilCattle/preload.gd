extends Object

# Static variables persist across the preload
static var release_text = "EvilCattle3D Release 1.1 [Modded]"
static var apply_to_all_levels = true

func mod_preload():
    print("[EvilCattle] Preload running!")
    print("[EvilCattle] Configured release text: " + release_text)
