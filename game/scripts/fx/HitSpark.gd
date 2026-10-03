class_name HitSpark
extends Node3D
## Anime hit spark: an additive billboard burst + a light flash + ink impact lines that shoot out
## and thin away (step 1.5: hits read heavier). Blocked hits are small and blue-white, no lines.

var _life: float = 0.0
var _dur: float = 0.18
var _quad: MeshInstance3D
var _light: OmniLight3D
var _base_scale: float = 1.0
var _lines: Array[MeshInstance3D] = []
var _line_len: float = 1.0


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
	if not blocked:
		var n := 5 if damage < 70.0 else 8
		if crit:
			n += 3
		_line_len = clampf(0.6 + damage / 120.0, 0.7, 1.9) * (1.3 if crit else 1.0)
		for i in n:
			_lines.append(_make_line(c if i % 2 == 0 else Color(0.06, 0.04, 0.08), TAU * float(i) / float(n) + randf_range(-0.25, 0.25)))


func _make_line(color: Color, angle: float) -> MeshInstance3D:
	var pivot := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.0, 0.07)
	qm.center_offset = Vector3(0.5, 0.0, 0.0)   # grows outward from the impact point
	pivot.mesh = qm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = color
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	pivot.material_override = m
	pivot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pivot.rotation.z = angle
	add_child(pivot)
	return pivot


func _process(delta: float) -> void:
	_life += delta
	var t := clampf(_life / _dur, 0.0, 1.0)
	var s := _base_scale * (0.35 + 1.1 * sqrt(t))
	_quad.scale = Vector3(s, s * 0.55, 1.0)
	var m := _quad.material_override as StandardMaterial3D
	if m:
		m.albedo_color.a = 1.0 - t
	_light.light_energy *= 0.8
	# impact lines: shoot out fast (ease-out), start a gap away from the centre, thin to nothing
	var e := 1.0 - pow(1.0 - t, 3.0)
	for ln in _lines:
		ln.position = Vector3(cos(ln.rotation.z), sin(ln.rotation.z), 0.0) * (0.25 + 0.5 * e) * _line_len * 0.5
		ln.scale = Vector3(_line_len * (0.3 + 0.9 * e), 1.0 - t, 1.0)
	if t >= 1.0:
		queue_free()
