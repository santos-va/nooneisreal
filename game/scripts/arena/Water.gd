class_name Water
extends Node3D
## River stage surface: owns the WaveField clock, the toon water mesh and the "holding" rings
## (кільця тримання) under each fighter's feet. Docs: docs/World/Stage-River.md.
## Ticks before the fighters (physics priority) so they read this frame's surface.

const WATER_SHADER := preload("res://shaders/water_toon.gdshader")
const SIZE := Vector2(64.0, 25.0)      # x along the fight axis, z from the camera side to the backdrop
const CENTER_Z := -5.5                 # spans z ≈ +7 … −18 (backdrop plane)
## Free movement (0.3-5): a square around the arena centre that reaches the turning backdrop card
## (Backdrop keeps ~18 m from the centre), fading into the painted river by distance from the centre.
const FREE_SIZE := 38.0
const FREE_FAR_R := 18.0

var field: WaveField
var _mat: ShaderMaterial
var _rings: Dictionary = {}            # Fighter -> MeshInstance3D
var _fighters: Array[Fighter] = []


func setup(wf: WaveField, fighters: Array[Fighter]) -> void:
	field = wf
	_fighters = fighters
	process_physics_priority = -50       # after InputRouter (-100), before fighters (0)
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(FREE_SIZE, FREE_SIZE) if wf.use_z else SIZE
	mesh.subdivide_width = 160
	mesh.subdivide_depth = 6
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = Vector3.ZERO if wf.use_z else Vector3(0.0, 0.0, CENTER_Z)
	if wf.use_z:
		mesh.subdivide_depth = 160
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 2.0
	_mat = ShaderMaterial.new()
	_mat.shader = WATER_SHADER
	_mat.set_shader_parameter("amp", field.amplitudes)
	_mat.set_shader_parameter("wavelength", field.wavelengths)
	_mat.set_shader_parameter("speed", field.speeds)
	_mat.set_shader_parameter("phase", field.phases)
	_mat.set_shader_parameter("use_z", field.use_z)
	_mat.set_shader_parameter("dir_deg", field.directions_deg)
	_mat.set_shader_parameter("far_r", FREE_FAR_R if field.use_z else 0.0)
	mi.material_override = _mat
	add_child(mi)
	for f in fighters:
		_rings[f] = _make_ring(f.data.accent_color)
	_sync_shader()


func on_round_started(round_no: int) -> void:
	field.reset(round_no)
	_sync_shader()


func _physics_process(_delta: float) -> void:
	if field == null:
		return
	field.tick()
	_sync_shader()


func _process(_delta: float) -> void:
	if field == null:
		return
	var pulse := 1.0 + 0.07 * sin(field.time_s() * 5.0)
	var dim := 1.0 - 0.65 * field.swell_env()
	for f in _fighters:
		var ring: MeshInstance3D = _rings[f]
		var h := field.height(f.global_position.x, f.global_position.z)
		var grounded := f.global_position.y <= h + 0.12
		ring.visible = grounded and f.state != Fighter.State.KO and f.animator.visible
		ring.global_position = Vector3(f.global_position.x, h + 0.03, f.global_position.z)
		var g := field.gradient(f.global_position.x, f.global_position.z)
		ring.rotation.z = atan(g.x)
		ring.rotation.x = -atan(g.y)
		ring.scale = Vector3(pulse, 0.25, pulse)
		(ring.material_override as StandardMaterial3D).albedo_color.a = 0.85 * dim


func _sync_shader() -> void:
	_mat.set_shader_parameter("wave_time", field.time_s())
	_mat.set_shader_parameter("swell_amp", field.swell_amplitude * field.swell_env())


func _make_ring(color: Color) -> MeshInstance3D:
	var t := TorusMesh.new()
	t.inner_radius = 0.42
	t.outer_radius = 0.5
	t.rings = 32
	t.ring_segments = 6
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(color.r, color.g, color.b, 0.85)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 1.6
	var mi := MeshInstance3D.new()
	mi.mesh = t
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.scale = Vector3(1.0, 0.25, 1.0)
	add_child(mi)
	return mi
