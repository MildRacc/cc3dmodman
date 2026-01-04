extends Node

const Preload = preload("res://mods/Booster/preload.gd")

var API:  Node
var player_node: Node = null
var mod_path:  String = ""
var apply_boost: bool = false

var boost_sound: AudioStreamPlayer3D = null
var loop_start_time: float = 1.5
var is_fading_out: bool = false

var flame_core:  GPUParticles3D = null
var flame_outer:  GPUParticles3D = null
var sparks: GPUParticles3D = null
var smoke: GPUParticles3D = null

func _ready():
	print("[Booster] Mod loaded!")
	mod_path = get_script().resource_path.get_base_dir()

	await get_tree().process_frame

	API = get_node_or_null("/root/ModAPI")
	if API:
		API.player_ready.connect(_on_player_ready)
		API.level_unloaded.connect(_on_level_unloaded)
	else:
		print("[Booster] ERROR: ModAPI not found!")

func _physics_process(delta:  float) -> void:
	if ! player_node:
		return

	if apply_boost:
		boost()

	# Handle fade out
	if is_fading_out and boost_sound and is_instance_valid(boost_sound):
		boost_sound.volume_db -= delta * 30.0
		if boost_sound.volume_db <= -40.0:
			boost_sound.stop()
			is_fading_out = false

func _on_level_unloaded():
	player_node = null
	boost_sound = null
	flame_core = null
	flame_outer = null
	sparks = null
	smoke = null
	is_fading_out = false

func _on_player_ready(player):
	player_node = player.get_node()

	# Setup boost sound
	boost_sound = AudioStreamPlayer3D.new()
	boost_sound.stream = API.load_audio_wav(mod_path + "/assets/rocket.wav")
	boost_sound.volume_db = -15
	boost_sound.finished.connect(_on_boost_sound_finished)
	player_node.add_child(boost_sound)

	# Flame core - white hot center, dense
	flame_core = GPUParticles3D.new()
	flame_core.name = "FlameCore"
	flame_core.emitting = false
	flame_core.amount = 120
	flame_core.lifetime = 0.2
	flame_core.explosiveness = 0.0
	flame_core.position = Vector3(0, 0.8, -1.15)
	flame_core.local_coords = false
	flame_core.process_material = Preload.flame_core_material
	flame_core.draw_pass_1 = Preload.flame_core_mesh
	player_node.add_child(flame_core)

	# Flame outer - orange/red flames
	flame_outer = GPUParticles3D.new()
	flame_outer.name = "FlameOuter"
	flame_outer.emitting = false
	flame_outer.amount = 150
	flame_outer.lifetime = 0.4
	flame_outer.explosiveness = 0.0
	flame_outer.randomness = 0.3
	flame_outer.position = Vector3(0, 0.8, -1.25)
	flame_outer.local_coords = false
	flame_outer.process_material = Preload.flame_outer_material
	flame_outer.draw_pass_1 = Preload.flame_outer_mesh
	player_node.add_child(flame_outer)

	# Sparks - flying embers
	sparks = GPUParticles3D.new()
	sparks.name = "Sparks"
	sparks.emitting = false
	sparks.amount = 80
	sparks.lifetime = 0.4
	sparks.explosiveness = 0.2
	sparks.randomness = 0.7
	sparks.position = Vector3(0, 0.8, -1.2)
	sparks.local_coords = false
	sparks.process_material = Preload.sparks_material
	sparks.draw_pass_1 = Preload.sparks_mesh
	player_node.add_child(sparks)

	# Smoke - trailing dark smoke
	smoke = GPUParticles3D.new()
	smoke.name = "Smoke"
	smoke.emitting = false
	smoke.amount = 60
	smoke.lifetime = 1.0
	smoke.explosiveness = 0.0
	smoke.randomness = 0.5
	smoke.position = Vector3(0, 0.8, -1.5)
	smoke.local_coords = false
	smoke.process_material = Preload.smoke_material
	smoke.draw_pass_1 = Preload.smoke_mesh
	player_node.add_child(smoke)

	var mesh = player.get_mesh()
	if mesh:
		var rocket_mesh:  Node3D = API.load_model_gltf(mod_path + "/assets/rocket.glb")
		if rocket_mesh:
			rocket_mesh.name = "rocket"
			rocket_mesh.scale = Vector3(0.35, 0.25, 0.35)
			rocket_mesh.rotation_degrees = Vector3(270, 0, 0)
			rocket_mesh.position = Vector3(0, 0.8, -1)
			player_node.add_child(rocket_mesh)
		else:
			print("[Booster] Couldnt load Booster model")

func _on_boost_sound_finished():
	if apply_boost and boost_sound and is_instance_valid(boost_sound):
		boost_sound.play(loop_start_time)

func _unhandled_input(event):
	if event is InputEventKey:
		if event.keycode == KEY_SHIFT and event.pressed:
			start_boosting()
		elif event.keycode == KEY_SHIFT and ! event.pressed:
			stop_boosting()

func start_boosting():
	apply_boost = true
	is_fading_out = false

	if boost_sound and is_instance_valid(boost_sound):
		boost_sound.volume_db = -15
		boost_sound.play()

	if flame_core and is_instance_valid(flame_core):
		flame_core.emitting = true
	if flame_outer and is_instance_valid(flame_outer):
		flame_outer.emitting = true
	if sparks and is_instance_valid(sparks):
		sparks.emitting = true
	if smoke and is_instance_valid(smoke):
		smoke.emitting = true

func stop_boosting():
	apply_boost = false
	is_fading_out = true

	if flame_core and is_instance_valid(flame_core):
		flame_core.emitting = false
	if flame_outer and is_instance_valid(flame_outer):
		flame_outer.emitting = false
	if sparks and is_instance_valid(sparks):
		sparks.emitting = false
	if smoke and is_instance_valid(smoke):
		smoke.emitting = false

func boost():
	var forward = player_node.global_transform.basis.z
	player_node.apply_central_impulse(forward * 10.0)
