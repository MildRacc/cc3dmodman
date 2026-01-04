extends RefCounted

# To anyone reading this:
# This wrapper mirrors the game's actual scene layout.
# The scene the game's actual scene layout is seriously this bad.
# Node paths are NOT stable in general, but are assumed frozen for this game, due to zero updates.


var node: Node  # VehicleBody3D

func _init(vehicle_node: Node):
	node = vehicle_node

# ============ INTERNAL ============

func _get(path: String) -> Node:
	if not is_valid():
		return null
	return node.get_node_or_null(path)

# ============ CORE ============

func is_valid() -> bool:
	return node != null and is_instance_valid(node)

func get_node() -> Node:
	return node  # UNSAFE: raw access

# ============ CAMERAS / AUDIO ============

func get_playercam() -> Camera3D:
	return _get("Camera3D")

func get_playercam_listener() -> AudioListener3D:
	return _get("Camera3D/AudioListener3D")

func get_freecam() -> Camera3D:
	return _get("Node/Camera3D3")

func get_freecam_listener() -> AudioListener3D:
	return _get("Node/Camera3D3/freecamlisten")

func get_crowd_audio() -> AudioStreamPlayer:
	return _get("Node/Camera3D3/freecamlisten/Crowd")

func get_explosion_audio() -> AudioStreamPlayer3D:
	return _get("Node/Camera3D3/freecamlisten/Explode")

func get_explosion_sprite() -> Sprite3D:
	return _get("Node/Camera3D3/freecamlisten/explosion")

func get_bleat_audio() -> AudioStreamPlayer3D:
	return _get("Bleat")

# ============ VISUALS / COLLISION ============

func get_mesh() -> Node:
	return _get("sheep")

func get_collider() -> CollisionShape3D:
	return _get("CollisionShape3D")

# ============ WHEELS ============

func get_front_left_wheel() -> VehicleWheel3D:
	return _get("front_left_wheel")

func get_front_right_wheel() -> VehicleWheel3D:
	return _get("front_right_wheel")

func get_back_left_wheel() -> VehicleWheel3D:
	return _get("back_left_wheel")

func get_back_right_wheel() -> VehicleWheel3D:
	return _get("back_right_wheel")

func get_all_wheels() -> Array:
	return [
		get_front_left_wheel(),
		get_front_right_wheel(),
		get_back_left_wheel(),
		get_back_right_wheel()
	]

# ============ DETECTORS / UI ============

func get_detector_dead() -> ShapeCast3D:
	return _get("detect_dead")

func get_label_remaining_cattle() -> RichTextLabel:
	return _get("detect_dead/RichTextLabel3")

func get_label_eliminated_cattle() -> RichTextLabel:
	return _get("detect_dead/RichTextLabel4")

func get_label_dead() -> RichTextLabel:
	return _get("detect_dead/RichTextLabel2")

func get_label_win() -> RichTextLabel:
	return _get("detect_dead/RichTextLabel5")

func get_label_release_header() -> RichTextLabel:
	return _get("detect_dead/RichTextLabel")

# ============ PROPERTIES ============

func get_position() -> Vector3:
	return node.global_position if is_valid() else Vector3.ZERO

func set_position(pos: Vector3):
	if not is_valid():
		return
	node.global_position = pos

func get_rotation() -> Vector3:
	return node.rotation if is_valid() else Vector3.ZERO

func set_rotation(rot: Vector3):
	if not is_valid():
		return
	node.rotation = rot

func is_dead() -> bool:
	return bool(node.get("isdead")) if is_valid() else false

func is_win_state() -> bool:
	return bool(node.get("iswinstate")) if is_valid() else false

func get_speed() -> float:
	return float(node.get("doamovespeed")) if is_valid() else 0.0

func set_speed(speed: float):
	if not is_valid():
		return
	node.set("doamovespeed", speed)

# ============ ACTIONS ============

func bleat():
	var audio = get_bleat_audio()
	if audio:
		audio.pitch_scale = randf_range(0.7, 1.3)
		audio.play()

func explode():
	var audio = get_explosion_audio()
	var sprite = get_explosion_sprite()
	if audio:
		audio.play()
	if sprite:
		sprite.play()

func hide():
	var mesh = get_mesh()
	if mesh:
		mesh.hide()

func show():
	var mesh = get_mesh()
	if mesh:
		mesh.show()
