extends Node

var API:  Node
var player_node: Node = null
var gun_node: Sprite3D = null
var audio_node: AudioStreamPlayer3D = null
var mod_path: String = ""

var fire_rate: float = 0.225
var can_shoot: bool = true
var projectile_speed: float = 80.0

var gun_tex: ImageTexture = null
var gun_sound: AudioStream = null

func _ready():
    print("[SheepGun] Mod loaded!")
    mod_path = get_script().resource_path.get_base_dir()

    await get_tree().process_frame

    API = get_node_or_null("/root/ModAPI")
    if API:
        API.player_ready.connect(_on_player_ready)
        API.level_unloaded.connect(_on_level_unloaded)

        gun_tex = API.load_texture(mod_path + "/assets/Ak47.png")
        if !gun_tex:
            print("Failed to load Ak47 Texture")

        # Just load the sound, don't create node yet
        gun_sound = API.load_audio_mp3(mod_path + "/assets/gunshot.mp3")

    else:
        print("[SheepGun] ERROR: ModAPI not found!")

func _on_level_unloaded():
    player_node = null
    gun_node = null
    audio_node = null
    can_shoot = true

func _on_player_ready(player):
    player_node = player.get_node()

    audio_node = AudioStreamPlayer3D.new()
    audio_node.stream = gun_sound
    audio_node.volume_db = -15
    player_node.add_child(audio_node)

    var mesh = player.get_mesh()
    if mesh:
        gun_node = Sprite3D.new()
        gun_node.name = "Ak47"
        gun_node.texture = gun_tex
        gun_node.pixel_size = 0.005
        gun_node.billboard = BaseMaterial3D.BILLBOARD_DISABLED
        gun_node.scale = Vector3(1, 1, 1)
        gun_node.position = Vector3(1.05, 1, 0)
        gun_node.rotation_degrees = Vector3(0, 90, 0)
        mesh.add_child(gun_node)

    print("[SheepGun] Gun equipped")

func _unhandled_input(event):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            shoot()

    if event is InputEventKey:
        if event.keycode == KEY_F and event.pressed:
            shoot()

func shoot():
    if not can_shoot:
        return
    if gun_node == null:
        return
    if not is_instance_valid(gun_node):
        return

    if audio_node and is_instance_valid(audio_node):
        audio_node.stop()
        audio_node.play(0.0)

    can_shoot = false

    # Spawn position
    var start_pos: Vector3 = gun_node.to_global(Vector3(2, -0.25, 0))

    # Direction gun is facing
    var forward = gun_node.global_transform.basis.x
    forward.y = 0
    forward = forward.normalized()

    # Create physics bowling ball
    var ball = RigidBody3D.new()
    ball.name = "BowlingBall"
    ball.mass = 80.0
    ball.scale = Vector3(0.5, 0.5, 0.5)
    ball.gravity_scale = 1.0
    ball.continuous_cd = true

    # Ball mesh
    var mesh = MeshInstance3D.new()
    var sphere = SphereMesh.new()
    sphere.radius = 0.3
    sphere.height = 0.6
    mesh.mesh = sphere

    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(0.1, 0.1, 0.1)
    mat.metallic = 0.8
    mat.roughness = 0.2
    mesh.material_override = mat
    ball.add_child(mesh)

    # Collision shape
    var collision = CollisionShape3D.new()
    var shape = SphereShape3D.new()
    shape.radius = 0.6
    collision.shape = shape
    ball.add_child(collision)

    get_tree().current_scene.add_child(ball)
    ball.position = start_pos

    ball.linear_velocity = forward * projectile_speed

    # Delete after 10 seconds
    destroy_after(ball, 10.0)

    # Cooldown
    await get_tree().create_timer(fire_rate).timeout
    can_shoot = true

func destroy_after(node:  Node, time: float):
    await get_tree().create_timer(time).timeout
    if is_instance_valid(node):
        node.queue_free()
