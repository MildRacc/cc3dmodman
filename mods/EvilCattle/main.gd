extends Node

var API: Node

func _ready():
    print("[EvilCattle] Mod loaded!")
    await get_tree().process_frame

    API = get_node_or_null("/root/ModAPI")
    if API:
        API.player_ready.connect(_on_player_ready)
    else:
        print("[EvilCattle] ERROR: ModAPI not found!")

func _on_player_ready(player):

    var header_label = player.get_label_release_header()
    if header_label:
        header_label.text = "EvilCattle3D Release 1.1 [Modded]"
        print("[EvilCattle] Release header changed!")
    else:
        print("[EvilCattle] Could not find release header label!")
