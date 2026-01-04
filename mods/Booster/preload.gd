extends Object

static var flame_core_material: ParticleProcessMaterial = null
static var flame_core_mesh: QuadMesh = null

static var flame_outer_material:  ParticleProcessMaterial = null
static var flame_outer_mesh: QuadMesh = null

static var sparks_material: ParticleProcessMaterial = null
static var sparks_mesh: QuadMesh = null

static var smoke_material:  ParticleProcessMaterial = null
static var smoke_mesh:  QuadMesh = null

func mod_preload():
	print("[Booster] Preloading particle materials...")

	create_flame_core()
	create_flame_outer()
	create_sparks()
	create_smoke()

	print("[Booster] Preload complete!")

func create_flame_core():
	# Bright hot core - tiny, dense, white/yellow
	flame_core_material = ParticleProcessMaterial.new()

	flame_core_material.direction = Vector3(0, 0, -1)
	flame_core_material.spread = 5.0

	flame_core_material.initial_velocity_min = 10.0
	flame_core_material.initial_velocity_max = 14.0

	flame_core_material.gravity = Vector3(0, 0, 0)

	flame_core_material.scale_min = 0.03
	flame_core_material.scale_max = 0.06

	# Shrink quickly
	var scale_curve = CurveTexture.new()
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.3, 0.5))
	curve.add_point(Vector2(1.0, 0.0))
	scale_curve.curve = curve
	flame_core_material.scale_curve = scale_curve

	# White hot to yellow
	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.colors = PackedColorArray([
		Color(1, 1, 1, 1),
		Color(1, 1, 0.8, 1),
		Color(1, 0.9, 0.4, 0.8),
		Color(1, 0.6, 0.1, 0)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.2, 0.5, 1.0])
	gradient.gradient = grad
	flame_core_material.color_ramp = gradient

	# Mesh - tiny
	flame_core_mesh = QuadMesh.new()
	flame_core_mesh.size = Vector2(0.08, 0.08)

	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	flame_core_mesh.material = mat

func create_flame_outer():
	# Outer flame - small, orange/red, turbulent
	flame_outer_material = ParticleProcessMaterial.new()

	flame_outer_material.direction = Vector3(0, 0, -1)
	flame_outer_material.spread = 15.0

	flame_outer_material.initial_velocity_min = 6.0
	flame_outer_material.initial_velocity_max = 10.0

	flame_outer_material.gravity = Vector3(0, 1.5, 0)

	# Turbulence
	flame_outer_material.turbulence_enabled = true
	flame_outer_material.turbulence_noise_strength = 1.5
	flame_outer_material.turbulence_noise_speed = Vector3(1.0, 1.0, 1.0)
	flame_outer_material.turbulence_noise_scale = 4.0

	flame_outer_material.scale_min = 0.04
	flame_outer_material.scale_max = 0.1

	# Grow then shrink
	var scale_curve = CurveTexture.new()
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 0.6))
	curve.add_point(Vector2(0.1, 1.0))
	curve.add_point(Vector2(0.5, 0.5))
	curve.add_point(Vector2(1.0, 0.0))
	scale_curve.curve = curve
	flame_outer_material.scale_curve = scale_curve

	# Spin
	flame_outer_material.angle_min = 0.0
	flame_outer_material.angle_max = 360.0
	flame_outer_material.angular_velocity_min = -180.0
	flame_outer_material.angular_velocity_max = 180.0

	# Orange to red to dark
	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.colors = PackedColorArray([
		Color(1, 0.8, 0.3, 1),
		Color(1, 0.5, 0.1, 1),
		Color(0.9, 0.25, 0, 0.7),
		Color(0.4, 0.08, 0, 0.3),
		Color(0.15, 0.03, 0.01, 0)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.15, 0.4, 0.7, 1.0])
	gradient.gradient = grad
	flame_outer_material.color_ramp = gradient

	# Color variation
	var color_var = GradientTexture1D.new()
	var color_grad = Gradient.new()
	color_grad.colors = PackedColorArray([
		Color(1, 0.9, 0.7, 1),
		Color(1, 0.7, 0.4, 1),
		Color(1, 0.5, 0.2, 1)
	])
	color_grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	color_var.gradient = color_grad
	flame_outer_material.color_initial_ramp = color_var

	# Mesh - small
	flame_outer_mesh = QuadMesh.new()
	flame_outer_mesh.size = Vector2(0.12, 0.12)

	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	flame_outer_mesh.material = mat

func create_sparks():
	# Sparks - tiny bright dots
	sparks_material = ParticleProcessMaterial.new()

	sparks_material.direction = Vector3(0, 0, -1)
	sparks_material.spread = 40.0

	sparks_material.initial_velocity_min = 8.0
	sparks_material.initial_velocity_max = 18.0

	sparks_material.gravity = Vector3(0, -4.0, 0)

	sparks_material.scale_min = 0.01
	sparks_material.scale_max = 0.025

	# Fade out
	var scale_curve = CurveTexture.new()
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.6, 0.8))
	curve.add_point(Vector2(1.0, 0.0))
	scale_curve.curve = curve
	sparks_material.scale_curve = scale_curve

	# Bright yellow/orange
	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.colors = PackedColorArray([
		Color(1, 1, 0.9, 1),
		Color(1, 0.8, 0.3, 1),
		Color(1, 0.5, 0.1, 0.7),
		Color(0.8, 0.2, 0, 0)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.2, 0.6, 1.0])
	gradient.gradient = grad
	sparks_material.color_ramp = gradient

	# Mesh - tiny dot
	sparks_mesh = QuadMesh.new()
	sparks_mesh.size = Vector2(0.04, 0.04)

	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	sparks_mesh.material = mat

func create_smoke():
	# Smoke - small puffs, rises, dissipates
	smoke_material = ParticleProcessMaterial.new()

	smoke_material.direction = Vector3(0, 0, -1)
	smoke_material.spread = 25.0

	smoke_material.initial_velocity_min = 2.0
	smoke_material.initial_velocity_max = 4.0

	smoke_material.gravity = Vector3(0, 3.0, 0)

	# Turbulence for billowy look
	smoke_material.turbulence_enabled = true
	smoke_material.turbulence_noise_strength = 2.0
	smoke_material.turbulence_noise_speed = Vector3(0.4, 0.6, 0.4)
	smoke_material.turbulence_noise_scale = 2.5

	smoke_material.scale_min = 0.05
	smoke_material.scale_max = 0.12

	# Grow as it dissipates
	var scale_curve = CurveTexture.new()
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 0.5))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(0.7, 1.3))
	curve.add_point(Vector2(1.0, 0.8))
	scale_curve.curve = curve
	smoke_material.scale_curve = scale_curve

	# Slow spin
	smoke_material.angle_min = 0.0
	smoke_material.angle_max = 360.0
	smoke_material.angular_velocity_min = -40.0
	smoke_material.angular_velocity_max = 40.0

	# Dark gray, fade out
	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.colors = PackedColorArray([
		Color(0.3, 0.28, 0.26, 0.4),
		Color(0.25, 0.23, 0.22, 0.3),
		Color(0.2, 0.18, 0.17, 0.15),
		Color(0.15, 0.13, 0.12, 0)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.3, 0.6, 1.0])
	gradient.gradient = grad
	smoke_material.color_ramp = gradient

	# Mesh - small puff
	smoke_mesh = QuadMesh.new()
	smoke_mesh.size = Vector2(0.2, 0.2)

	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	smoke_mesh.material = mat
