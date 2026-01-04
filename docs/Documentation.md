
# CrazyCattle3D Modding Documentation

## Table of Contents

1. [Getting Started](#getting-started)
2. [Mod Structure](#mod-structure)
3. [Mod Lifecycle](#mod-lifecycle)
4. [ModAPI Reference](#modapi-reference)
5. [Class Reference](#class-reference)
6. [Examples](#examples)

---

## Getting Started

### Requirements

- CrazyCattle3D with mod loader installed
- Basic GDScript knowledge
- Mods go in `/Mods/YourModName/` relative to the CC3DModLoader executable

> **Assumed knowledge**: Familiarity with Godot nodes, scenes, signals, and the scene tree is expected. If you’re new, review Godot 4 fundamentals first.

> **Important**: The game’s scene layout is **messy and frozen**. Node paths are fragile and reflect the original game. The wrappers (`ModPlayer` and `ModSheep`) mirror this layout. Do not assume paths are generalizable or stable outside this game.

### Minimal Mod Structure


```
Mods/
└── MyMod/
    ├── mod.json
    └── main.gd
```

```json
{
	"name": "MyMod",
	"description": "My first mod",
	"author": "YourName",
	"version": "1.0.0"
}
```

```gdscript
extends Node

var API: Node
var mod_path:  String = ""

func _ready():
	print("[MyMod] Loaded!")
	mod_path = get_script().resource_path.get_base_dir()
	
	await get_tree().process_frame
	
	API = get_node_or_null("/root/ModAPI")
	if API:
		API.player_ready.connect(_on_player_ready)
		API.level_unloaded.connect(_on_level_unloaded)

func _on_player_ready(player):
	print("[MyMod] Player spawned!")

func _on_level_unloaded():
	print("[MyMod] Level ended!")
```


---

### 2️⃣ Mod Structure

```markdown
## Mod Structure

### Files

| File | Required | Purpose |
|------|----------|---------|
| `main.gd` | Yes | Main per-level script |
| `preload.gd` | No | Run once at game startup |
| `mod.json` | Yes | Metadata required by the loader |

**Note:** File names are **hardcoded**. Asset organization is flexible, but paths must match what your code references.

### mod.json Example

```json
{
  "name": "Booster",
  "description": "Adds a rocket booster. Hold SHIFT to boost!",
  "author": "MildRacc",
  "version": "1.0.0"
}
```


---

### 3️⃣ Mod Lifecycle

```markdown
## Mod Lifecycle

> Mods load before levels exist, but interact after the level and player spawn. Most issues come from doing things at the wrong time.

### Load Order

1. `preload.gd` runs at game start (`mod_preload()` called)  
2. `main.gd` added to scene tree (`_ready()` called)  
3. `/root/ModAPI` becomes available after first processed frame  
4. `level_loaded` → wrappers created, `player_ready` and `sheep_ready` signals emitted  
5. `level_unloaded` → cleanup signal emitted  
6. Steps 4–5 repeat for each level

### Preload Script

- Extends `Object`  
- Defines `mod_preload()`  
- Use `static var` for persistent data  
- Runs once at game startup; resources persist across levels  

Use preload for:
- Materials, textures, meshes used by particles, curves, gradients, shared resources

### Main Script

- Extends `Node`  
- File name is hardcoded (`main.gd`)  
- Nodes here are **level-scoped**; do not store persistent resources  
- Clear references on `level_unloaded` to avoid crashes

---

## ModAPI Reference

### Getting the API

```gdscript
var API: Node
var mod_path: String = ""

func _ready():
	mod_path = get_script().resource_path.get_base_dir()
	
	await get_tree().process_frame
	API = get_node_or_null("/root/ModAPI")
```

> **Why you must wait one frame**: The ModAPI node is injected after mods are added but before the first processed frame. Waiting one frame guarantees `/root/ModAPI` exists.

If you do not wait:
-   `get_node_or_null()` may return `null`
-   Signal connections may silently fail

### Signals

| Signal | Parameter | Parameter Type | When |
|--------|-----------|----------------|------|
| `level_loaded` | `level` | `ModLevel` | Level scene loaded |
| `level_unloaded` | - | - | Level scene removed |
| `player_ready` | `player` | `ModPlayer` | Player vehicle ready |
| `sheep_ready` | `sheep` | `Array[ModSheep]` | All sheep ready |
| `node_added` | `node` | `Node` (raw) | Low-level, any node added; use carefully |

### Player Detection
- Prefer vehicles with `"is_player"` metadata or `"player"` group.
- Legacy heuristic uses Camera3D.
- Fallback selects first vehicle.

### Game Access

- `get_level()`, `get_player()`, `get_sheep()` → wrappers
- `get_level_name()`, `get_player_name()`, `get_unlocked_levels()`, `get_beaten_levels()` → primitives
- Wrappers may be invalid after level_unloaded; always check `is_valid()`

```gdscript
# Get wrapper objects
var level = API.get_level()           # ModLevel or null
var player = API.get_player()         # ModPlayer or null
var sheep = API.get_sheep()           # Array of (ModSheep or null)

# Get game state
var level_name = API.get_level_name() # String:  "ireland", "egypt", etc.
var sheep_count = API.get_sheep_count() # int: total sheep in level
var player_name = API.get_player_name() # String: player's name
var unlocked = API.get_unlocked_levels() # int: unlocked level count
var beaten = API.get_beaten_levels()     # int: beaten level count
```

### Resource Loading

```gdscript
var mod_path = get_script().resource_path.get_base_dir()

# Textures (PNG, JPG)
var tex = API.load_texture(mod_path + "/assets/image.png")

# Audio
var mp3 = API.load_audio_mp3(mod_path + "/assets/sound.mp3")
var ogg = API.load_audio_ogg(mod_path + "/assets/sound.ogg")
var wav = API.load_audio_wav(mod_path + "/assets/sound.wav")

# 3D Models
var gltf = API.load_model_gltf(mod_path + "/assets/model.glb")
var obj = API.load_model_obj(mod_path + "/assets/model.obj")

# JSON
var data = API.load_json(mod_path + "/assets/config.json")
```

### Node Modifiers

> **Warning**: Node modifiers bypass wrapper safety and operate on raw engine nodes.

-   Called for every `VehicleBody3D`
-   You must prevent double-modification
-   Cleanup is your responsibility

Prefer wrappers unless you intentionally want to modify all vehicles identically.

**Important:** The callback receives the raw `VehicleBody3D` node, NOT a `ModPlayer` or `ModSheep` wrapper. Use direct node paths like `node.get_node_or_null("sheep")`.

```gdscript
var modified_nodes:  Array = []

func _ready():
	mod_path = get_script().resource_path.get_base_dir()
	
	await get_tree().process_frame
	API = get_node_or_null("/root/ModAPI")
	if API:
		API.register_node_modifier(_modify_vehicle)
		API.level_unloaded.connect(_on_level_unloaded)

func _on_level_unloaded():
	modified_nodes.clear()

func _modify_vehicle(node: Node):
	# Avoid modifying the same node twice
	if node in modified_nodes: 
		return
	modified_nodes.append(node)
	
	# Access mesh directly (not through wrapper)
	var mesh = node.get_node_or_null("sheep")
	if mesh: 
		# Modify the mesh
		pass
```

---

## Class Reference

### Wrappers vs Raw Nodes

> **Rule of thumb**: If the API provides a wrapper method, prefer it. Raw node access is advanced usage.

The ModAPI provides two ways to access vehicles:

| Approach | What You Get | Use For |
|----------|--------------|---------|
| `player_ready` signal | `ModPlayer` wrapper | Player-specific logic with convenience methods |
| `sheep_ready` signal | `Array[ModSheep]` wrappers | Sheep-specific logic with convenience methods |
| `API.get_player()` | `ModPlayer` wrapper | Access player anytime after level load |
| `API.get_sheep()` | `Array[ModSheep]` wrappers | Access sheep anytime after level load |
| `register_node_modifier` | Raw `VehicleBody3D` | Modify ALL vehicles identically |
| `node_added` signal | Raw `Node` | React to any node being added |

**Wrappers provide:**
- Named methods instead of string paths (e.g., `player.get_mesh()` vs `node.get_node_or_null("sheep")`)
- Validity checking via `is_valid()`
- Actions like `bleat()`, `explode()`, `hide()`, `show()`
- Property access like `get_position()`, `set_speed()`

### ModPlayer

Wrapper for the player's VehicleBody3D. Obtained via `player_ready` signal or `API.get_player()`. 

#### Node Access

```gdscript
player.get_node()                  # VehicleBody3D - the raw node
player.get_mesh()                  # Node3D - the sheep mesh
player.get_collider()              # CollisionShape3D

# Cameras
player.get_playercam()             # Camera3D - main camera
player.get_freecam()               # Camera3D - free camera
player.get_playercam_listener()    # AudioListener3D
player.get_freecam_listener()      # AudioListener3D

# Audio
player.get_bleat_audio()           # AudioStreamPlayer3D
player.get_explosion_audio()       # AudioStreamPlayer3D
player.get_crowd_audio()           # AudioStreamPlayer
player.get_explosion_sprite()      # Sprite3D

# Wheels
player.get_front_left_wheel()      # VehicleWheel3D
player.get_front_right_wheel()     # VehicleWheel3D
player.get_back_left_wheel()       # VehicleWheel3D
player.get_back_right_wheel()      # VehicleWheel3D
player.get_all_wheels()            # Array of VehicleWheel3D

# Other
player.get_peripheral_owner_node() # Node
player.get_detector_dead()         # ShapeCast3D

# UI Labels
player.get_label_remaining_cattle() # RichTextLabel
player.get_label_eliminated_cattle() # RichTextLabel
player.get_label_dead()             # RichTextLabel
player.get_label_win()              # RichTextLabel
player.get_label_release_header()   # RichTextLabel
```

#### Properties

```gdscript
# Position/Rotation
var pos = player.get_position()     # Vector3
player.set_position(Vector3(0, 10, 0))

var rot = player.get_rotation()     # Vector3
player.set_rotation(Vector3(0, 0, 0))

# State
var dead = player.is_dead()         # bool
var won = player.is_win_state()     # bool
var speed = player.get_speed()      # float
player.set_speed(50.0)

# Validity
var valid = player.is_valid()       # bool - check before using
```

#### Actions

```gdscript
player.bleat()     # Play bleat sound with random pitch
player.explode()   # Play explosion effect
player.hide()      # Hide the mesh
player.show()      # Show the mesh
```

### ModSheep

Wrapper for NPC sheep VehicleBody3D. Obtained via `sheep_ready` signal or `API.get_sheep()`.

#### Node Access

```gdscript
sheep.get_node()                   # VehicleBody3D - the raw node
sheep.get_mesh()                   # Node3D - the sheep mesh
sheep.get_collision()              # CollisionShape3D
sheep.get_label()                  # Label3D - number label
sheep.get_label_shadow()           # Label3D - shadow label

# Audio
sheep.get_bleat_audio()            # AudioStreamPlayer3D
sheep.get_explosion_audio()        # AudioStreamPlayer3D
sheep.get_explosion_sprite()       # AnimatedSprite3D

# Wheels
sheep.get_front_left_wheel()       # VehicleWheel3D
sheep.get_front_right_wheel()      # VehicleWheel3D
sheep.get_back_left_wheel()        # VehicleWheel3D
sheep.get_back_right_wheel()       # VehicleWheel3D
sheep.get_all_wheels()             # Array of VehicleWheel3D

# Detectors (AI)
sheep.get_detector_right()         # ShapeCast3D
sheep.get_detector_left()          # ShapeCast3D
sheep.get_detector_ahead()         # ShapeCast3D
sheep.get_detector_dead()          # ShapeCast3D
```

#### Properties

```gdscript
# Position/Rotation
var pos = sheep.get_position()      # Vector3
sheep.set_position(Vector3(0, 10, 0))

var rot = sheep.get_rotation()      # Vector3
sheep.set_rotation(Vector3(0, 0, 0))

# Label
var num = sheep.get_number()        # int - sheep number
sheep.set_number(42)

var text = sheep.get_label_text()   # String
sheep.set_label_text("BOB")

# Validity
var valid = sheep.is_valid()        # bool - check before using
```

#### Actions

```gdscript
sheep.bleat()      # Play bleat sound with random pitch
sheep.explode()    # Play explosion effect
sheep.hide()       # Hide the mesh
sheep.show()       # Show the mesh
```

### ModLevel

Wrapper for the current level scene. Obtained via `level_loaded` signal or `API.get_level()`.

```gdscript
level.node    # Node - the scene root
level.name    # String - level name (e.g., "ireland", "uk")
```

---

## Examples

### Apply Force to Player

```gdscript
var API:  Node
var player_node: Node = null

func _ready():
	await get_tree().process_frame
	API = get_node_or_null("/root/ModAPI")
	if API: 
		API.player_ready.connect(_on_player_ready)
		API.level_unloaded.connect(_on_level_unloaded)

func _on_player_ready(player):
	player_node = player.get_node()

func _on_level_unloaded():
	player_node = null

func boost():
	if player_node and is_instance_valid(player_node):
		var forward = player_node.global_transform.basis.z
		player_node.apply_central_impulse(forward * 50.0)
```

### Add a 3D Model to Player

```gdscript
var API: Node
var mod_path: String = ""

func _ready():
	mod_path = get_script().resource_path.get_base_dir()
	
	await get_tree().process_frame
	API = get_node_or_null("/root/ModAPI")
	if API:
		API.player_ready.connect(_on_player_ready)

func _on_player_ready(player):
	var mesh = player.get_mesh()
	if mesh:
		var hat = API.load_model_gltf(mod_path + "/assets/hat.glb")
		hat.position = Vector3(0, 1, 0)
		hat.scale = Vector3(0.5, 0.5, 0.5)
		mesh.add_child(hat)
```

### Play Looping Audio

```gdscript
var API: Node
var mod_path: String = ""
var audio: AudioStreamPlayer3D = null
var loop_point: float = 1.5

func _ready():
	mod_path = get_script().resource_path.get_base_dir()
	
	await get_tree().process_frame
	API = get_node_or_null("/root/ModAPI")
	if API: 
		API.player_ready.connect(_on_player_ready)
		API.level_unloaded.connect(_on_level_unloaded)

func _on_player_ready(player):
	audio = AudioStreamPlayer3D.new()
	audio.stream = API.load_audio_wav(mod_path + "/assets/engine.wav")
	audio.volume_db = -15
	audio.finished.connect(_on_audio_finished)
	player.get_node().add_child(audio)

func _on_audio_finished():
	audio.play(loop_point)  # Restart from 1.5 seconds

func _on_level_unloaded():
	audio = null  # Freed with player
```

### Create Particle System

**preload.gd:**
```gdscript
extends Object

static var particle_material: ParticleProcessMaterial = null
static var particle_mesh: QuadMesh = null

func mod_preload():
	# Create expensive materials once
	particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, 1, 0)
	particle_material.spread = 30.0
	particle_material.initial_velocity_min = 5.0
	particle_material.initial_velocity_max = 10.0
	
	particle_mesh = QuadMesh.new()
	particle_mesh.size = Vector2(0.1, 0.1)
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	particle_mesh.material = mat
```

**main.gd:**
```gdscript
extends Node

const Preload = preload("res://mods/MyMod/preload.gd")

var API: Node
var particles: GPUParticles3D = null

func _ready():
	await get_tree().process_frame
	API = get_node_or_null("/root/ModAPI")
	if API:
		API.player_ready.connect(_on_player_ready)
		API.level_unloaded.connect(_on_level_unloaded)

func _on_player_ready(player):
	# Create cheap container, reference preloaded materials
	particles = GPUParticles3D.new()
	particles.amount = 50
	particles.lifetime = 1.0
	particles.local_coords = false
	particles.process_material = Preload.particle_material
	particles.draw_pass_1 = Preload.particle_mesh
	player.get_node().add_child(particles)

func _on_level_unloaded():
	particles = null
```

### Modify All Vehicles (Player + Sheep)

Use `register_node_modifier` to modify every `VehicleBody3D`. The callback receives raw nodes, not wrappers.

```gdscript
var API: Node
var mod_path: String = ""
var modified_nodes: Array = []
var hat_texture: ImageTexture = null

func _ready():
	mod_path = get_script().resource_path.get_base_dir()
	
	await get_tree().process_frame
	API = get_node_or_null("/root/ModAPI")
	if API: 
		hat_texture = API.load_texture(mod_path + "/assets/hat.png")
		API.register_node_modifier(_add_hat_to_vehicle)
		API.level_unloaded.connect(_on_level_unloaded)

func _on_level_unloaded():
	modified_nodes.clear()

func _add_hat_to_vehicle(node: Node):
	if node in modified_nodes: 
		return
	modified_nodes.append(node)
	
	var mesh = node.get_node_or_null("sheep")
	if mesh and hat_texture:
		var hat = Sprite3D.new()
		hat.texture = hat_texture
		hat.position = Vector3(0, 1.9, 0)
		mesh.add_child(hat)
```

### Modify Only Sheep (Not Player)

Use `sheep_ready` signal to get only NPC sheep with wrapper convenience methods: 

```gdscript
var API: Node

func _ready():
	await get_tree().process_frame
	API = get_node_or_null("/root/ModAPI")
	if API:
		API.sheep_ready.connect(_on_sheep_ready)

func _on_sheep_ready(sheep_array):
	for sheep in sheep_array:
		if sheep.is_valid():
			sheep.set_label_text("BAA")
			
			var bleat = sheep.get_bleat_audio()
			if bleat:
				bleat.pitch_scale = 2.0
```

### Handle Input

```gdscript
func _unhandled_input(event):
	if event is InputEventKey: 
		if event.keycode == KEY_F and event.pressed:
			do_something()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			shoot()
```

### Physics Every Frame

```gdscript
var player_node: Node = null

func _on_player_ready(player):
	player_node = player.get_node()

func _on_level_unloaded():
	player_node = null

func _physics_process(delta):
	if player_node == null:
		return
	if not is_instance_valid(player_node):
		return
	
	# Apply continuous force
	if Input.is_key_pressed(KEY_SHIFT):
		var forward = player_node.global_transform.basis.z
		player_node.apply_central_force(forward * 1000.0)
```

### Using Wrappers vs Raw Nodes

```gdscript
# WITH WRAPPER (via player_ready signal)
func _on_player_ready(player):
	var mesh = player.get_mesh()           # Convenience method
	var cam = player.get_playercam()       # Convenience method
	var wheels = player.get_all_wheels()   # Returns array
	player.bleat()                          # Action method
	
	# Still need raw node for physics
	var raw = player.get_node()
	raw.apply_central_impulse(Vector3(0, 100, 0))

# WITHOUT WRAPPER (via register_node_modifier)
func _modify_vehicle(node:  Node):
	var mesh = node.get_node_or_null("sheep")           # Manual path
	var cam = node.get_node_or_null("Camera3D")         # Manual path
	var bleat = node.get_node_or_null("Bleat")          # Manual path
	if bleat:
		bleat.play()
	
	node.apply_central_impulse(Vector3(0, 100, 0))
```

---

## Tips

### Always Check Validity

```gdscript
if player_node and is_instance_valid(player_node):
	# Safe to use
```

Or with wrappers: 

```gdscript
if player.is_valid():
	# Safe to use
```

### Nullify References on Level Unload

> **Why this matters**: Level unload destroys nodes. Holding references past unload causes crashes or silent failures.

```gdscript
func _on_level_unloaded():
	player_node = null
	audio_node = null
	particles = null
	modified_nodes.clear()
```

### Get Mod Path

```gdscript
var mod_path = get_script().resource_path.get_base_dir()
# Returns:  "res://mods/YourModName"
```

### Use Tabs, Not Spaces

GDScript in Godot 4 requires consistent indentation. Use tabs.

### Preload vs Main

| Put in Preload | Put in Main |
|----------------|-------------|
| Materials | Node creation |
| Textures (for materials) | Signal connections |
| Gradients/Curves | Adding children |
| Meshes (for particles) | Per-level logic |
| Anything expensive | Anything per-level |

### When to Use Wrappers vs Raw Nodes

| Use Wrappers | Use Raw Nodes |
|--------------|---------------|
| Player-only or sheep-only logic | Modify all vehicles the same way |
| Need convenience methods | Need maximum control |
| Working with specific vehicle types | Reacting to any node spawn |
| `player_ready` / `sheep_ready` signals | `register_node_modifier` / `node_added` |
