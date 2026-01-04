extends Node

const ModLevelClass = preload("res://classes/level.gd")
const ModPlayerClass = preload("res://classes/player.gd")
const ModSheepClass = preload("res://classes/sheep.gd")

signal level_loaded(level)
signal level_unloaded()
signal player_ready(player)
signal sheep_ready(sheep)
signal node_added(node)

var _current_level: String = ""
var _current_scene: Node = null
var _player = null
var _sheep:  Array = []
var _level = null
var _node_modifiers:  Array = []

func _ready():
	print("[ModAPI] Initialized")
	get_tree().node_added.connect(_on_node_added)
	get_tree().node_removed.connect(_on_node_removed)

func _on_node_added(node:  Node):
	emit_signal("node_added", node)

	if node.get_class() == "VehicleBody3D":
		for modifier in _node_modifiers:
			modifier.call(node)

func _on_node_removed(node: Node):
	if node == _current_scene:
		print("[ModAPI] Scene removed, clearing cache")
		_clear_cache()
		emit_signal("level_unloaded")
		_current_scene = null

func register_node_modifier(callback: Callable):
	if not callback.is_valid():
		push_warning("[ModAPI] Invalid node modifier")
		return
	_node_modifiers.append(callback)
	print("[ModAPI] Registered node modifier")

func _process(_delta):
	var scene = get_tree().current_scene

	if scene != _current_scene:
		var level = Global.currentlevel

		if _current_scene != null:
			_clear_cache()
			emit_signal("level_unloaded")

		_current_scene = scene
		_current_level = level

		if scene != null and level != "":
			await get_tree().process_frame
			_cache_level()

func _clear_cache():
	_player = null
	_sheep.clear()
	_level = null

func _cache_level():
	var scene = get_tree().current_scene
	if scene == null:
		return

	_level = ModLevelClass.new(scene, _current_level)
	emit_signal("level_loaded", _level)

	var vehicles = []
	for node in _get_all_nodes(scene):
		if node.get_class() == "VehicleBody3D":
			vehicles.append(node)

	if vehicles.size() == 0:
		return

	_resolve_player_and_sheep(vehicles)

	print("[ModAPI] Level:  ", _current_level, " | Player: ", _player != null, " | Sheep: ", _sheep.size())

# ============ GAME ACCESS ============

func get_level():
	return _level

func get_level_name() -> String:
	return _current_level

func get_player():
	return _player

func get_sheep() -> Array:
	return _sheep.duplicate()

func get_sheep_count() -> int:
	return Global.global_sheep

func get_player_name() -> String:
	return Global.playername

func get_unlocked_levels() -> int:
	return Global.unlockedlevels

func get_beaten_levels() -> int:
	return Global.beatenlevels

# ============ RESOURCE LOADING ============

func load_texture(path: String) -> ImageTexture:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("[ModAPI] Failed to load texture: " + path)
		return null

	var buffer = file.get_buffer(file.get_length())
	file.close()

	var image = Image.new()
	if path.ends_with(".png"):
		image.load_png_from_buffer(buffer)
	elif path.ends_with(".jpg") or path.ends_with(".jpeg"):
		image.load_jpg_from_buffer(buffer)
	else:
		return null

	return ImageTexture.create_from_image(image)

func load_json(path: String) -> Variant:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var json = JSON.new()
	json.parse(file.get_as_text())
	file.close()
	return json.data

func load_audio_mp3(path: String) -> AudioStreamMP3:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var stream = AudioStreamMP3.new()
	stream.data = file.get_buffer(file.get_length())
	file.close()
	return stream

func load_audio_ogg(path: String) -> AudioStreamOggVorbis:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var buffer = file.get_buffer(file.get_length())
	file.close()
	return AudioStreamOggVorbis.load_from_buffer(buffer)

func load_audio_wav(path: String) -> AudioStreamWAV:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("[ModAPI] Failed to load WAV:  " + path)
		return null

	var buffer = file.get_buffer(file.get_length())
	file.close()

	var idx = 12

	var format = 1
	var channels = 1
	var sample_rate = 44100
	var bits_per_sample = 16
	var data_start = 0
	var data_size = 0

	while idx < buffer.size():
		var chunk_id = buffer.slice(idx, idx + 4).get_string_from_ascii()
		var chunk_size = buffer.decode_u32(idx + 4)

		if chunk_id == "fmt ":
			format = buffer.decode_u16(idx + 8)
			channels = buffer.decode_u16(idx + 10)
			sample_rate = buffer.decode_u32(idx + 12)
			bits_per_sample = buffer.decode_u16(idx + 22)
		elif chunk_id == "data":
			data_start = idx + 8
			data_size = chunk_size
			break

		idx += 8 + chunk_size

	if data_start == 0:
		print("[ModAPI] Failed to parse WAV:  " + path)
		return null

	var stream = AudioStreamWAV.new()
	stream.data = buffer.slice(data_start, data_start + data_size)
	stream.mix_rate = sample_rate
	stream.stereo = (channels == 2)

	if bits_per_sample == 8:
		stream.format = AudioStreamWAV.FORMAT_8_BITS
	else:
		stream.format = AudioStreamWAV.FORMAT_16_BITS

	print("[ModAPI] WAV loaded:  " + path)
	return stream

func load_model_gltf(path: String) -> Node3D:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("[ModAPI] Failed to open model: " + path)
		return null

	var buffer = file.get_buffer(file.get_length())
	file.close()

	var gltf = GLTFDocument.new()
	var state = GLTFState.new()

	var err = gltf.append_from_buffer(buffer, "", state)
	if err != OK:
		print("[ModAPI] Failed to parse GLTF: " + str(err))
		return null

	var scene = gltf.generate_scene(state)
	if scene == null:
		print("[ModAPI] Failed to generate scene from GLTF")
		return null

	print("[ModAPI] Model loaded:  " + path)
	return scene

func load_model_obj(path: String) -> MeshInstance3D:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("[ModAPI] Failed to open model: " + path)
		return null

	var obj_text = file.get_as_text()
	file.close()

	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()

	var vertex_list = []
	var normal_list = []
	var uv_list = []

	var lines = obj_text.split("\n")
	for line in lines:
		line = line.strip_edges()
		if line.begins_with("v "):
			var parts = line.split(" ", false)
			vertex_list.append(Vector3(float(parts[1]), float(parts[2]), float(parts[3])))
		elif line.begins_with("vn "):
			var parts = line.split(" ", false)
			normal_list.append(Vector3(float(parts[1]), float(parts[2]), float(parts[3])))
		elif line.begins_with("vt "):
			var parts = line.split(" ", false)
			uv_list.append(Vector2(float(parts[1]), float(parts[2])))
		elif line.begins_with("f "):
			var parts = line.split(" ", false)
			for i in range(1, parts.size()):
				var indices = parts[i].split("/")
				var vi = int(indices[0]) - 1
				vertices.append(vertex_list[vi])
				if indices.size() > 1 and indices[1] != "":
					var ti = int(indices[1]) - 1
					uvs.append(uv_list[ti])
				if indices.size() > 2 and indices[2] != "":
					var ni = int(indices[2]) - 1
					normals.append(normal_list[ni])

	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	if normals.size() > 0:
		arrays[Mesh.ARRAY_NORMAL] = normals
	if uvs.size() > 0:
		arrays[Mesh.ARRAY_TEX_UV] = uvs

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh

	print("[ModAPI] OBJ loaded: " + path + " (" + str(vertices.size()) + " vertices)")
	return mesh_instance

# ============ INTERNAL ============

func _get_all_nodes(node: Node) -> Array:
	var nodes = [node]
	for child in node.get_children():
		nodes.append_array(_get_all_nodes(child))
	return nodes


func _is_player_vehicle(vehicle: Node) -> bool:
	if vehicle.has_meta("is_player") and vehicle.get_meta("is_player") == true:
		return true

	if vehicle.is_in_group("player"):
		return true

	return false

func _resolve_player_and_sheep(vehicles: Array):
	_sheep.clear()
	_player = null
	var player_vehicle: Node = null

	# 1. Explicit marking
	for v in vehicles:
		if _is_player_vehicle(v):
			player_vehicle = v
			break

	# 2. Legacy heuristic (Camera3D)
	if player_vehicle == null:
		for v in vehicles:
			if v.get_node_or_null("Camera3D") != null:
				player_vehicle = v
				print("[ModAPI] WARNING: Player detected via Camera3D heuristic")
				break

	# 3. Fallback
	if player_vehicle == null and vehicles.size() > 0:
		player_vehicle = vehicles[0]
		print("[ModAPI] WARNING: Player not detected; using first vehicle as fallback")

	# Finalize
	if player_vehicle != null:
		_player = ModPlayerClass.new(player_vehicle)
		emit_signal("player_ready", _player)

	for v in vehicles:
		if v != player_vehicle:
			_sheep.append(ModSheepClass.new(v))

	if _sheep.size() > 0:
		emit_signal("sheep_ready", _sheep)
