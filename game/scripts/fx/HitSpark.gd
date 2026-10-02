class_name HitSpark
extends Node3D
## Anime hit spark: an additive billboard burst + a light flash. Blocked hits are small and blue-white.

var _life: float = 0.0
var _dur: float = 0.18
var _quad: MeshInstance3D
var _light: OmniLight3D
var _base_scale: float = 1.0


func setup(blocked: bool, color: Color, damage: float, crit: bool = false) -> void:
	_dur = 0.14 if blocked else clampf(0.14 + damage / 900.0, 0.16, 0.34)
	_base_scale = 0.6 if blocked else clampf(0.9 + damage / 160.0, 0.9, 2.4)
	var c := Color(0.75, 0.9, 1.0) if blocked else color.lightened(0.35)
	if crit:
		c = Color(0.85, 0.45, 1.0)
		_base_scale *= 1.6
		_dur *= 1.3
	_quad = MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.0, 1.0)
	_quad.mesh = qm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = c
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_quad.material_override = m
	_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_quad)
	_light = OmniLight3D.new()
	_light.light_color = c
	_light.light_energy = 1.5 if blocked else 4.0
	_light.omni_range = 4.0
	add_child(_light)
	rotation.z = randf_range(0.0, TAU)


func _process(delta: float) -> void:
	_life += delta
	var t := clampf(_life / _dur, 0.0, 1.0)
	var s := _base_scale * (0.35 + 1.1 * sqrt(t))
	_quad.scale = Vector3(s, s * 0.55, 1.0)
	var m := _quad.material_override as StandardMaterial3D
	if m:
		m.albedo_color.a = 1.0 - t
	_light.light_energy *= 0.8
	if t >= 1.0:
		queue_free()
