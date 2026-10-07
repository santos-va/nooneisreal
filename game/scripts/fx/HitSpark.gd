class_name HitSpark
extends Node3D
## Anime hit spark: an additive billboard star (fx_spark: 4 rays, 8 on a crit) + a light flash + ink impact
## lines that shoot out and thin away (step 1.5: hits read heavier). Blocked hits are small and blue-white, no lines.
## Random angles come from FxShader.rng(), never the global RNG.

var _life: float = 0.0
var _dur: float = 0.18
var _quad: MeshInstance3D
var _light: OmniLight3D
var _base_scale: float = 1.0
var _lines: Array[MeshInstance3D] = []
var _line_len: float = 1.0

const INK := Color(0.169, 0.133, 0.188)   # #2B2230, Style-Guide line colour


## sheet = true: the painted spark_hit sheet draws the star (FxDirector.hit_spark), so the procedural quad stays hidden;
## the light flash and the ink impact lines stay.
func setup(blocked: bool, color: Color, damage: float, crit: bool = false, sheet: bool = false) -> void:
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
	_quad.material_override = FxShader.spark(c, 8 if crit else 4)
	_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_quad.visible = not sheet
	add_child(_quad)
	_light = OmniLight3D.new()
	_light.light_color = c
	# HIT FLASH Reduced (ContentSettings, T8): the hit light at ≤ half strength.
	_light.light_energy = (1.5 if blocked else 4.0) * ContentSettings.hit_flash_scale()
	_light.omni_range = 4.0
	add_child(_light)
	rotation.z = FxShader.rng().randf_range(0.0, TAU)
	if not blocked:
		var n := 5 if damage < 70.0 else 8
		if crit:
			n += 3
		_line_len = clampf(0.6 + damage / 120.0, 0.7, 1.9) * (1.3 if crit else 1.0)
		for i in n:
			_lines.append(_make_line(c if i % 2 == 0 else INK, TAU * float(i) / float(n) + FxShader.rng().randf_range(-0.25, 0.25)))


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
	_quad.scale = Vector3(s, s, 1.0)
	var m := _quad.material_override as ShaderMaterial
	if m:
		m.set_shader_parameter("alpha", Fx.stepped(1.0 - t))
	_light.light_energy *= 0.8
	# impact lines: shoot out fast (ease-out), start a gap away from the centre, thin to nothing
	var e := 1.0 - pow(1.0 - t, 3.0)
	for ln in _lines:
		ln.position = Vector3(cos(ln.rotation.z), sin(ln.rotation.z), 0.0) * (0.25 + 0.5 * e) * _line_len * 0.5
		ln.scale = Vector3(_line_len * (0.3 + 0.9 * e), 1.0 - t, 1.0)
	if t >= 1.0:
		queue_free()
