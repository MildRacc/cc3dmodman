# CrazyCattle3D - Modder's Guide

## Getting Started

### Requirements

- CrazyCattle3D with mod loader extracted to a folder
- Basic GDScript knowledge (Godot 4)
- Text editor or Godot IDE

### Prerequisites

This guide assumes you're familiar with:
- Godot nodes, scenes, and the scene tree
- Signals and event-driven programming
- Basic 3D concepts (transforms, meshes, materials)

If you're new to Godot, review [Godot 4 fundamentals](https://docs.godotengine.org/) first.

### Important Notes

> **Scene Layout**: The game's scene layout is messy and frozen. Node paths are fragile and reflect the original game. The wrappers (`ModPlayer` and `ModSheep`) mirror this layout. Do not assume paths are generalizable or stable outside this game.

---

## Creating Your First Mod

### Minimal Mod Structure

```
mods/
└── MyMod/
    ├── mod.json
    └── main.gd
```

### mod.json

Every mod requires a `mod.json` metadata file:

```json
{
	"name": "MyMod",
	"description": "My first mod",
	"author": "YourName",
	"version": "1.0.0"
}
```

All fields are required.

### main.gd

The main script runs once per level:

```gdscript
extends Node

var API: Node
var mod_path: String = ""

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

## Mod Lifecycle

Understanding when things happen is critical to avoid crashes and bugs.

### Load Order

1. **Game starts** → `preload.gd` runs (`mod_preload()` called)
2. **Level loads** → `main.gd` added to scene tree (`_ready()` called)
3. **First frame** → `/root/ModAPI` becomes available
4. **Level ready** → `level_loaded` signal → wrappers created
5. **Player ready** → `player_ready` signal emitted
6. **Sheep ready** → `sheep_ready` signal emitted
7. **Level ends** → `level_unloaded` signal
8. Steps 4–7 repeat for each level

### Why Wait One Frame?

```gdscript
await get_tree().process_frame
API = get_node_or_null("/root/ModAPI")
```

The ModAPI node is injected after mods load but before the first processed frame. Without waiting:
- `get_node_or_null()` may return `null`
- Signal connections may silently fail
- Your mod won't work

**Always wait one frame before accessing `/root/ModAPI`.**

### File Structure

| File | Required | Purpose |
|------|----------|---------|
| `main.gd` | Yes | Per-level logic, runs every level |
| `preload.gd` | No | One-time setup at game start |
| `mod.json` | Yes | Metadata for mod loader |

File names are **hardcoded**. Asset organization is flexible.

---

## Preload vs Main Scripts

### When to Use Preload

Use `preload.gd` for expensive resources that should be created once and reused:

**preload.gd:**
```gdscript
extends Object

static var particle_material: ParticleProcessMaterial = null
static var hat_texture: ImageTexture = null

func mod_preload():
	# Created once at game start
	particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, 1, 0)
	particle_material.spread = 30.0
```

Use preload for:
- Materials and shaders
- Textures (when used in materials/particles)
- Gradients and curves
- Meshes for particle systems
- Any expensive resource that doesn't change between levels

### When to Use Main

Use `main.gd` for everything that happens per-level:

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

func _on_player_ready(player):
	# Reference preloaded material
	particles = GPUParticles3D.new()
	particles.process_material = Preload.particle_material
	player.get_node().add_child(particles)
```

Use main for:
- Signal connections
- Node creation and modification
- Level-specific logic
- Anything that needs cleanup

---

## Working with the Player

### Getting the Player

Two ways to access the player:

**1. Via Signal (Recommended)**
```gdscript
func _on_player_ready(player):
	# player is a ModPlayer wrapper
	var mesh = player.get_mesh()
	player.bleat()
```

**2. Via API Call**
```gdscript
func some_function():
	var player = API.get_player()
	if player and player.is_valid():
		# Use player
		pass
```

### Player Wrapper vs Raw Node

The `ModPlayer` wrapper provides convenience methods:

```gdscript
# WITH WRAPPER
var mesh = player.get_mesh()
var camera = player.get_playercam()
player.bleat()

# WITHOUT WRAPPER (raw node)
var raw = player.get_node()
var mesh = raw.get_node_or_null("sheep")
var camera = raw.get_node_or_null("Camera3D")
```

For physics, you still need the raw node:

```gdscript
var raw_node = player.get_node()
raw_node.apply_central_impulse(Vector3(0, 100, 0))
```

---

## Working with Sheep

Sheep are NPC vehicles that use similar mechanics to the player.

### Getting Sheep

```gdscript
func _on_sheep_ready(sheep_array):
	for sheep in sheep_array:
		if sheep.is_valid():
			sheep.set_label_text("MOO")
			sheep.bleat()
```

Or via API:
```gdscript
var all_sheep = API.get_sheep()
```

### Modifying Only Sheep (Not Player)

Use `sheep_ready` to target only NPC sheep:

```gdscript
func _on_sheep_ready(sheep_array):
	for sheep in sheep_array:
		if sheep.is_valid():
			var mesh = sheep.get_mesh()
			# Customize this sheep
```

---

## Modifying All Vehicles

To modify both player and sheep identically, use node modifiers:

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
	# Prevent double-modification
	if node in modified_nodes:
		return
	modified_nodes.append(node)
	
	# node is raw VehicleBody3D, NOT a wrapper
	var mesh = node.get_node_or_null("sheep")
	if mesh:
		# Modify the mesh
		pass
```

**Important**: Node modifiers receive raw `VehicleBody3D` nodes, not wrappers. Use direct paths like `node.get_node_or_null("sheep")`.

### Wrappers vs Node Modifiers

| Use Wrappers | Use Node Modifiers |
|--------------|-------------------|
| Player-only logic | Modify all vehicles identically |
| Sheep-only logic | Need to catch vehicles as they spawn |
| Need convenience methods | Maximum control over timing |
| `player_ready` / `sheep_ready` | `register_node_modifier` |

---

## Loading Assets

### Get Your Mod's Path

```gdscript
var mod_path = get_script().resource_path.get_base_dir()
# Returns: "res://mods/YourModName"
```

### Load Resources

```gdscript
# Textures
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

---

## Common Patterns

### Adding a 3D Model to the Player

```gdscript
func _on_player_ready(player):
	var mesh = player.get_mesh()
	if mesh:
		var hat = API.load_model_gltf(mod_path + "/assets/hat.glb")
		hat.position = Vector3(0, 1, 0)
		hat.scale = Vector3(0.5, 0.5, 0.5)
		mesh.add_child(hat)
```

### Applying Force

```gdscript
var player_node: Node = null

func _on_player_ready(player):
	player_node = player.get_node()

func _on_level_unloaded():
	player_node = null

func boost():
	if player_node and is_instance_valid(player_node):
		var forward = player_node.global_transform.basis.z
		player_node.apply_central_impulse(forward * 50.0)
```

### Handling Input

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

### Looping Audio

```gdscript
var audio: AudioStreamPlayer3D = null
var loop_point: float = 1.5

func _on_player_ready(player):
	audio = AudioStreamPlayer3D.new()
	audio.stream = API.load_audio_wav(mod_path + "/assets/engine.wav")
	audio.volume_db = -15
	audio.finished.connect(_on_audio_finished)
	player.get_node().add_child(audio)

func _on_audio_finished():
	audio.play(loop_point)

func _on_level_unloaded():
	audio = null
```

---

## Best Practices

### Always Check Validity

```gdscript
if player.is_valid():
	# Safe to use wrapper
	pass

if player_node and is_instance_valid(player_node):
	# Safe to use raw node
	pass
```

### Clean Up on Level Unload

Level unload destroys nodes. Holding stale references causes crashes:

```gdscript
func _on_level_unloaded():
	player_node = null
	audio_node = null
	particles = null
	modified_nodes.clear()
```

### Use Tabs for Indentation

GDScript in Godot 4 requires consistent indentation. Use tabs, not spaces.

### Avoid Heavy Work in _ready()

```gdscript
# BAD - blocks the game
func _ready():
	for i in 10000:
		do_expensive_thing()

# GOOD - spreads work over frames
func _ready():
	await get_tree().process_frame
	for i in 10000:
		do_expensive_thing()
		if i % 100 == 0:
			await get_tree().process_frame
```

---

## Troubleshooting

### Mod Doesn't Load

- Check file names: `main.gd` and `mod.json` are **hardcoded**
- Verify `mod.json` has all required fields
- Check console for error messages

### Signals Don't Fire

- Did you wait one frame before getting ModAPI?
- Did you connect to the signal correctly?
- Is the signal connection happening in `_ready()`?

### Crashes on Level Change

- Are you nullifying references in `level_unloaded`?
- Are you checking `is_valid()` before using wrappers?
- Are you checking `is_instance_valid()` before using raw nodes?

### Node Not Found

- The game's node structure is frozen - paths must match exactly
- Use `get_node_or_null()` and check for `null`
- With wrappers, use the provided getter methods

### Resources Not Loading

- Check your `mod_path` is correct
- Verify file paths are relative to your mod folder
- Use forward slashes in paths, even on Windows

---

## Examples Repository

For complete, working examples, check the examples folder, or visit other mods created by the community.

## Getting Help

- Read the full API reference [api.md](api.md)
- Check existing mods for examples
- Ask in community forums
- Report bugs with detailed reproduction steps