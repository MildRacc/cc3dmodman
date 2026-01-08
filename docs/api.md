# CrazyCattle3D - API Reference

## Table of Contents

1. [ModAPI](#modapi)
2. [ModPlayer](#modplayer)
3. [ModSheep](#modsheep)
4. [ModLevel](#modlevel)

---

## ModAPI

The ModAPI singleton provides access to game state, signals, and resource loading.

### Accessing ModAPI

```gdscript
var API: Node

func _ready():
	await get_tree().process_frame
	API = get_node_or_null("/root/ModAPI")
```

**Important**: Always wait one frame before accessing `/root/ModAPI`. It is injected after mods load but before the first processed frame.

---

### Signals

#### level_loaded

```gdscript
signal level_loaded(level: ModLevel)
```

Emitted when a level scene is loaded.

**Parameters:**
- `level` (ModLevel): Wrapper for the level scene

**Example:**
```gdscript
API.level_loaded.connect(_on_level_loaded)

func _on_level_loaded(level):
	print("Level loaded: ", level.name)
```

---

#### level_unloaded

```gdscript
signal level_unloaded()
```

Emitted when the current level is about to be removed from the scene tree.

**Example:**
```gdscript
API.level_unloaded.connect(_on_level_unloaded)

func _on_level_unloaded():
	# Clean up references
	player_node = null
	particles = null
```

---

#### player_ready

```gdscript
signal player_ready(player: ModPlayer)
```

Emitted when the player vehicle is ready.

**Parameters:**
- `player` (ModPlayer): Wrapper for the player's VehicleBody3D

**Example:**
```gdscript
API.player_ready.connect(_on_player_ready)

func _on_player_ready(player):
	var mesh = player.get_mesh()
	player.bleat()
```

---

#### sheep_ready

```gdscript
signal sheep_ready(sheep: Array[ModSheep])
```

Emitted when all NPC sheep are ready.

**Parameters:**
- `sheep` (Array[ModSheep]): Array of wrappers for sheep VehicleBody3D nodes

**Example:**
```gdscript
API.sheep_ready.connect(_on_sheep_ready)

func _on_sheep_ready(sheep_array):
	for sheep in sheep_array:
		if sheep.is_valid():
			sheep.set_label_text("BAA")
```

---

#### node_added

```gdscript
signal node_added(node: Node)
```

Low-level signal emitted when any node is added to the scene tree.

**Parameters:**
- `node` (Node): The raw node that was added

**Warning**: This fires for EVERY node. Use with caution.

**Example:**
```gdscript
API.node_added.connect(_on_node_added)

func _on_node_added(node):
	if node is VehicleBody3D:
		# Do something with vehicle
		pass
```

---

### Game State Methods

#### get_level

```gdscript
func get_level() -> ModLevel
```

Returns the current level wrapper, or `null` if no level is loaded.

**Returns:** ModLevel or null

**Example:**
```gdscript
var level = API.get_level()
if level:
	print("Current level: ", level.name)
```

---

#### get_player

```gdscript
func get_player() -> ModPlayer
```

Returns the player wrapper, or `null` if not available.

**Returns:** ModPlayer or null

**Example:**
```gdscript
var player = API.get_player()
if player and player.is_valid():
	player.bleat()
```

---

#### get_sheep

```gdscript
func get_sheep() -> Array
```

Returns an array of sheep wrappers.

**Returns:** Array of ModSheep (may contain null entries)

**Example:**
```gdscript
var sheep = API.get_sheep()
for s in sheep:
	if s and s.is_valid():
		s.hide()
```

---

#### get_level_name

```gdscript
func get_level_name() -> String
```

Returns the current level's internal name (e.g., "ireland", "egypt").

**Returns:** String

**Example:**
```gdscript
var name = API.get_level_name()
if name == "ireland":
	# Do ireland-specific thing
	pass
```

---

#### get_sheep_count

```gdscript
func get_sheep_count() -> int
```

Returns the total number of sheep in the current level.

**Returns:** int

**Example:**
```gdscript
var count = API.get_sheep_count()
print("There are ", count, " sheep")
```

---

#### get_player_name

```gdscript
func get_player_name() -> String
```

Returns the player's name.

**Returns:** String

---

#### get_unlocked_levels

```gdscript
func get_unlocked_levels() -> int
```

Returns the number of unlocked levels.

**Returns:** int

---

#### get_beaten_levels

```gdscript
func get_beaten_levels() -> int
```

Returns the number of beaten levels.

**Returns:** int

---

### Resource Loading

All resource loading methods take absolute paths. Use your mod's path as a base:

```gdscript
var mod_path = get_script().resource_path.get_base_dir()
```

#### load_texture

```gdscript
func load_texture(path: String) -> ImageTexture
```

Loads a PNG or JPG texture.

**Parameters:**
- `path` (String): Absolute path to image file

**Returns:** ImageTexture or null

**Example:**
```gdscript
var tex = API.load_texture(mod_path + "/assets/icon.png")
```

---

#### load_audio_mp3

```gdscript
func load_audio_mp3(path: String) -> AudioStreamMP3
```

Loads an MP3 audio file.

**Parameters:**
- `path` (String): Absolute path to MP3 file

**Returns:** AudioStreamMP3 or null

**Example:**
```gdscript
var music = API.load_audio_mp3(mod_path + "/assets/music.mp3")
```

---

#### load_audio_ogg

```gdscript
func load_audio_ogg(path: String) -> AudioStreamOggVorbis
```

Loads an OGG Vorbis audio file.

**Parameters:**
- `path` (String): Absolute path to OGG file

**Returns:** AudioStreamOggVorbis or null

**Example:**
```gdscript
var sfx = API.load_audio_ogg(mod_path + "/assets/sound.ogg")
```

---

#### load_audio_wav

```gdscript
func load_audio_wav(path: String) -> AudioStreamWAV
```

Loads a WAV audio file.

**Parameters:**
- `path` (String): Absolute path to WAV file

**Returns:** AudioStreamWAV or null

**Example:**
```gdscript
var wav = API.load_audio_wav(mod_path + "/assets/bleat.wav")
```

---

#### load_model_gltf

```gdscript
func load_model_gltf(path: String) -> Node3D
```

Loads a GLTF/GLB 3D model.

**Parameters:**
- `path` (String): Absolute path to GLB/GLTF file

**Returns:** Node3D (scene root) or null

**Example:**
```gdscript
var model = API.load_model_gltf(mod_path + "/assets/hat.glb")
if model:
	model.position = Vector3(0, 1, 0)
	mesh.add_child(model)
```

---

#### load_model_obj

```gdscript
func load_model_obj(path: String) -> MeshInstance3D
```

Loads an OBJ 3D model.

**Parameters:**
- `path` (String): Absolute path to OBJ file

**Returns:** MeshInstance3D or null

**Example:**
```gdscript
var model = API.load_model_obj(mod_path + "/assets/prop.obj")
```

---

#### load_json

```gdscript
func load_json(path: String) -> Dictionary
```

Loads and parses a JSON file.

**Parameters:**
- `path` (String): Absolute path to JSON file

**Returns:** Dictionary (parsed JSON) or empty Dictionary on error

**Example:**
```gdscript
var config = API.load_json(mod_path + "/assets/config.json")
if config.has("speed"):
	var speed = config["speed"]
```

---

### Node Modifiers

#### register_node_modifier

```gdscript
func register_node_modifier(callback: Callable)
```

Registers a callback to be called for every `VehicleBody3D` node added to the scene.

**Parameters:**
- `callback` (Callable): Function that takes a `Node` parameter

**Callback Signature:**
```gdscript
func callback(node: Node) -> void
```

**Important Notes:**
- Callback receives raw `VehicleBody3D` nodes, NOT wrappers
- Called for both player and sheep vehicles
- You must prevent double-modification yourself
- Cleanup is your responsibility

**Example:**
```gdscript
var modified_nodes: Array = []

func _ready():
	await get_tree().process_frame
	API = get_node_or_null("/root/ModAPI")
	if API:
		API.register_node_modifier(_modify_vehicle)
		API.level_unloaded.connect(_on_level_unloaded)

func _on_level_unloaded():
	modified_nodes.clear()

func _modify_vehicle(node: Node):
	if node in modified_nodes:
		return
	modified_nodes.append(node)
	
	var mesh = node.get_node_or_null("sheep")
	if mesh:
		# Modify mesh
		pass
```

---

## ModPlayer

Wrapper for the player's VehicleBody3D node. Provides convenience methods and safe access to player components.

### Getting ModPlayer

```gdscript
# Via signal (recommended)
API.player_ready.connect(_on_player_ready)

func _on_player_ready(player: ModPlayer):
	# Use player here

# Via API call
var player = API.get_player()
if player and player.is_valid():
	# Use player here
```

---

### Node Access Methods

#### get_node

```gdscript
func get_node() -> VehicleBody3D
```

Returns the raw VehicleBody3D node.

**Returns:** VehicleBody3D

**Example:**
```gdscript
var raw = player.get_node()
raw.apply_central_impulse(Vector3(0, 100, 0))
```

---

#### get_mesh

```gdscript
func get_mesh() -> Node3D
```

Returns the sheep mesh node.

**Returns:** Node3D

**Example:**
```gdscript
var mesh = player.get_mesh()
mesh.visible = false
```

---

#### get_collider

```gdscript
func get_collider() -> CollisionShape3D
```

Returns the collision shape.

**Returns:** CollisionShape3D

---

#### get_playercam

```gdscript
func get_playercam() -> Camera3D
```

Returns the main player camera.

**Returns:** Camera3D

---

#### get_freecam

```gdscript
func get_freecam() -> Camera3D
```

Returns the free camera.

**Returns:** Camera3D

---

#### get_playercam_listener

```gdscript
func get_playercam_listener() -> AudioListener3D
```

Returns the player camera's audio listener.

**Returns:** AudioListener3D

---

#### get_freecam_listener

```gdscript
func get_freecam_listener() -> AudioListener3D
```

Returns the free camera's audio listener.

**Returns:** AudioListener3D

---

#### get_bleat_audio

```gdscript
func get_bleat_audio() -> AudioStreamPlayer3D
```

Returns the bleat sound player.

**Returns:** AudioStreamPlayer3D

---

#### get_explosion_audio

```gdscript
func get_explosion_audio() -> AudioStreamPlayer3D
```

Returns the explosion sound player.

**Returns:** AudioStreamPlayer3D

---

#### get_crowd_audio

```gdscript
func get_crowd_audio() -> AudioStreamPlayer
```

Returns the crowd sound player.

**Returns:** AudioStreamPlayer

---

#### get_explosion_sprite

```gdscript
func get_explosion_sprite() -> Sprite3D
```

Returns the explosion sprite.

**Returns:** Sprite3D

---

#### get_front_left_wheel

```gdscript
func get_front_left_wheel() -> VehicleWheel3D
```

Returns the front left wheel.

**Returns:** VehicleWheel3D

---

#### get_front_right_wheel

```gdscript
func get_front_right_wheel() -> VehicleWheel3D
```

Returns the front right wheel.

**Returns:** VehicleWheel3D

---

#### get_back_left_wheel

```gdscript
func get_back_left_wheel() -> VehicleWheel3D
```

Returns the back left wheel.

**Returns:** VehicleWheel3D

---

#### get_back_right_wheel

```gdscript
func get_back_right_wheel() -> VehicleWheel3D
```

Returns the back right wheel.

**Returns:** VehicleWheel3D

---

#### get_all_wheels

```gdscript
func get_all_wheels() -> Array[VehicleWheel3D]
```

Returns all four wheels in an array.

**Returns:** Array of VehicleWheel3D

**Example:**
```gdscript
var wheels = player.get_all_wheels()
for wheel in wheels:
	wheel.wheel_friction_slip = 2.0
```

---

#### get_peripheral_owner_node

```gdscript
func get_peripheral_owner_node() -> Node
```

Returns the peripheral owner node.

**Returns:** Node

---

#### get_detector_dead

```gdscript
func get_detector_dead() -> ShapeCast3D
```

Returns the dead detection shape cast.

**Returns:** ShapeCast3D

---

#### get_label_remaining_cattle

```gdscript
func get_label_remaining_cattle() -> RichTextLabel
```

Returns the remaining cattle UI label.

**Returns:** RichTextLabel

---

#### get_label_eliminated_cattle

```gdscript
func get_label_eliminated_cattle() -> RichTextLabel
```

Returns the eliminated cattle UI label.

**Returns:** RichTextLabel

---

#### get_label_dead

```gdscript
func get_label_dead() -> RichTextLabel
```

Returns the "dead" UI label.

**Returns:** RichTextLabel

---

#### get_label_win

```gdscript
func get_label_win() -> RichTextLabel
```

Returns the "win" UI label.

**Returns:** RichTextLabel

---

#### get_label_release_header

```gdscript
func get_label_release_header() -> RichTextLabel
```

Returns the release header UI label.

**Returns:** RichTextLabel

---

### Property Methods

#### get_position

```gdscript
func get_position() -> Vector3
```

Returns the player's global position.

**Returns:** Vector3

---

#### set_position

```gdscript
func set_position(pos: Vector3)
```

Sets the player's global position.

**Parameters:**
- `pos` (Vector3): New position

---

#### get_rotation

```gdscript
func get_rotation() -> Vector3
```

Returns the player's rotation in radians.

**Returns:** Vector3

---

#### set_rotation

```gdscript
func set_rotation(rot: Vector3)
```

Sets the player's rotation.

**Parameters:**
- `rot` (Vector3): New rotation in radians

---

#### is_dead

```gdscript
func is_dead() -> bool
```

Returns whether the player is in the dead state.

**Returns:** bool

---

#### is_win_state

```gdscript
func is_win_state() -> bool
```

Returns whether the player is in the win state.

**Returns:** bool

---

#### get_speed

```gdscript
func get_speed() -> float
```

Returns the player's current speed.

**Returns:** float

---

#### set_speed

```gdscript
func set_speed(speed: float)
```

Sets the player's speed.

**Parameters:**
- `speed` (float): New speed value

---

#### is_valid

```gdscript
func is_valid() -> bool
```

Returns whether the wrapper is still valid (node exists and is not freed).

**Returns:** bool

**Example:**
```gdscript
if player.is_valid():
	player.bleat()
```

---

### Action Methods

#### bleat

```gdscript
func bleat()
```

Plays the bleat sound with random pitch variation.

**Example:**
```gdscript
player.bleat()
```

---

#### explode

```gdscript
func explode()
```

Plays the explosion effect.

---

#### hide

```gdscript
func hide()
```

Hides the player mesh.

---

#### show

```gdscript
func show()
```

Shows the player mesh.

---

## ModSheep

Wrapper for NPC sheep VehicleBody3D nodes. Provides convenience methods similar to ModPlayer.

### Getting ModSheep

```gdscript
# Via signal (recommended)
API.sheep_ready.connect(_on_sheep_ready)

func _on_sheep_ready(sheep_array: Array[ModSheep]):
	for sheep in sheep_array:
		if sheep.is_valid():
			# Use sheep here
			pass

# Via API call
var sheep = API.get_sheep()
```

---

### Node Access Methods

#### get_node

```gdscript
func get_node() -> VehicleBody3D
```

Returns the raw VehicleBody3D node.

**Returns:** VehicleBody3D

---

#### get_mesh

```gdscript
func get_mesh() -> Node3D
```

Returns the sheep mesh node.

**Returns:** Node3D

---

#### get_collision

```gdscript
func get_collision() -> CollisionShape3D
```

Returns the collision shape.

**Returns:** CollisionShape3D

---

#### get_label

```gdscript
func get_label() -> Label3D
```

Returns the number label (main).

**Returns:** Label3D

---

#### get_label_shadow

```gdscript
func get_label_shadow() -> Label3D
```

Returns the shadow label.

**Returns:** Label3D

---

#### get_bleat_audio

```gdscript
func get_bleat_audio() -> AudioStreamPlayer3D
```

Returns the bleat sound player.

**Returns:** AudioStreamPlayer3D

---

#### get_explosion_audio

```gdscript
func get_explosion_audio() -> AudioStreamPlayer3D
```

Returns the explosion sound player.

**Returns:** AudioStreamPlayer3D

---

#### get_explosion_sprite

```gdscript
func get_explosion_sprite() -> AnimatedSprite3D
```

Returns the explosion sprite.

**Returns:** AnimatedSprite3D

---

#### get_front_left_wheel

```gdscript
func get_front_left_wheel() -> VehicleWheel3D
```

Returns the front left wheel.

**Returns:** VehicleWheel3D

---

#### get_front_right_wheel

```gdscript
func get_front_right_wheel() -> VehicleWheel3D
```

Returns the front right wheel.

**Returns:** VehicleWheel3D

---

#### get_back_left_wheel

```gdscript
func get_back_left_wheel() -> VehicleWheel3D
```

Returns the back left wheel.

**Returns:** VehicleWheel3D

---

#### get_back_right_wheel

```gdscript
func get_back_right_wheel() -> VehicleWheel3D
```

Returns the back right wheel.

**Returns:** VehicleWheel3D

---

#### get_all_wheels

```gdscript
func get_all_wheels() -> Array[VehicleWheel3D]
```

Returns all four wheels in an array.

**Returns:** Array of VehicleWheel3D

---

#### get_detector_right

```gdscript
func get_detector_right() -> ShapeCast3D
```

Returns the right-side AI detector.

**Returns:** ShapeCast3D

---

#### get_detector_left

```gdscript
func get_detector_left() -> ShapeCast3D
```

Returns the left-side AI detector.

**Returns:** ShapeCast3D

---

#### get_detector_ahead

```gdscript
func get_detector_ahead() -> ShapeCast3D
```

Returns the forward AI detector.

**Returns:** ShapeCast3D

---

#### get_detector_dead

```gdscript
func get_detector_dead() -> ShapeCast3D
```

Returns the dead detection shape cast.

**Returns:** ShapeCast3D

---

### Property Methods

#### get_position

```gdscript
func get_position() -> Vector3
```

Returns the sheep's global position.

**Returns:** Vector3

---

#### set_position

```gdscript
func set_position(pos: Vector3)
```

Sets the sheep's global position.

**Parameters:**
- `pos` (Vector3): New position

---

#### get_rotation

```gdscript
func get_rotation() -> Vector3
```

Returns the sheep's rotation in radians.

**Returns:** Vector3

---

#### set_rotation

```gdscript
func set_rotation(rot: Vector3)
```

Sets the sheep's rotation.

**Parameters:**
- `rot` (Vector3): New rotation in radians

---

#### get_number

```gdscript
func get_number() -> int
```

Returns the sheep's number (from label).

**Returns:** int

---

#### set_number

```gdscript
func set_number(num: int)
```

Sets the sheep's number (updates label).

**Parameters:**
- `num` (int): New number

---

#### get_label_text

```gdscript
func get_label_text() -> String
```

Returns the label text.

**Returns:** String

---

#### set_label_text

```gdscript
func set_label_text(text: String)
```

Sets the label text.

**Parameters:**
- `text` (String): New label text

**Example:**
```gdscript
sheep.set_label_text("BAA")
```

---

#### is_valid

```gdscript
func is_valid() -> bool
```

Returns whether the wrapper is still valid.

**Returns:** bool

---

### Action Methods

#### bleat

```gdscript
func bleat()
```

Plays the bleat sound with random pitch variation.

---

#### explode

```gdscript
func explode()
```

Plays the explosion effect.

---

#### hide

```gdscript
func hide()
```

Hides the sheep mesh.

---

#### show

```gdscript
func show()
```

Shows the sheep mesh.

---

## ModLevel

Simple wrapper for the current level scene.

### Properties

#### node

```gdscript
var node: Node
```

The level scene's root node.

---

#### name

```gdscript
var name: String
```

The level's internal name (e.g., "ireland", "egypt", "france").

**Example:**
```gdscript
var level = API.get_level()
if level and level.name == "ireland":
	# Ireland-specific logic
	pass
```