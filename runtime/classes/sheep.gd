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

# ============ VISUALS / AUDIO ============

func get_mesh() -> Node:
	return _get("sheep")

func get_label() -> Label3D:
	return _get("sheep/Label3D")

func get_label_shadow() -> Label3D:
	return _get("sheep/Label3D/Label3D2")

func get_collision() -> CollisionShape3D:
	return _get("CollisionShape3D")

func get_explosion_sprite() -> AnimatedSprite3D:
	return _get("explosion")

func get_explosion_audio() -> AudioStreamPlayer3D:
	return _get("Explode")

func get_bleat_audio() -> AudioStreamPlayer3D:
	return _get("Bleat")

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

# ============ DETECTORS ============

func get_detector_right() -> ShapeCast3D:
	return _get("detect_right")

func get_detector_left() -> ShapeCast3D:
	return _get("detect_left")

func get_detector_ahead() -> ShapeCast3D:
	return _get("detect_ahead")

func get_detector_dead() -> ShapeCast3D:
	return _get("detect_dead")

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

func get_number() -> int:
	var label = get_label()
	return int(label.text) if label else -1

func set_number(num: int):
	var label = get_label()
	var shadow = get_label_shadow()
	if label:
		label.text = str(num)
	if shadow:
		shadow.text = str(num)

func get_label_text() -> String:
	var label = get_label()
	return label.text if label else ""

func set_label_text(text: String):
	var label = get_label()
	var shadow = get_label_shadow()
	if label:
		label.text = text
	if shadow:
		shadow.text = text

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
