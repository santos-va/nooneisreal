class_name Afterimage
extends Node3D
## A frozen, translucent copy of a fighter's pose (from RigAnimator.part_snapshot).
## Used for Skea's flash-step ghosts, Choko's rewind trail, veil shimmer and Grimoire shadows.
## Burns away in steps (12 fps feel, fx_glow / fx_ink dissolve) so it reads as a drawn frame, not a motion-blur smear.

var _mat: ShaderMaterial
var _life: float = 0.3
var _left: float = 0.3
var _alpha: float = 0.5
var _drift: Vector3 = Vector3.ZERO


static func spawn(parent: Node, snapshot: Array, color: Color, life: float = 0.3, alpha: float = 0.5,
		additive: bool = true, scale_mult: float = 1.0, offset: Vector3 = Vector3.ZERO, drift: Vector3 = Vector3.ZERO) -> Afterimage:
	var a := Afterimage.new()
	a.add_to_group("afterimage")
	parent.add_child(a)
	a._build(snapshot, color, life, alpha, additive, scale_mult, offset, drift)
	return a


func _build(snapshot: Array, color: Color, life: float, alpha: float, additive: bool, scale_mult: float, offset: Vector3, drift: Vector3) -> void:
	_life = maxf(life, 0.05)
	_left = _life
	_alpha = alpha
	_drift = drift
	# additive ghosts get a fresnel rim (a drawn outline of the pose); the ink double stays a flat silhouette
	_mat = FxShader.stroke(color, alpha, additive, 0.0, 1.0 if additive else 0.0)
	if snapshot.is_empty():
		return
	var center: Vector3 = (snapshot[0].transform as Transform3D).origin
	for s in snapshot:
		var cm := CapsuleMesh.new()
		cm.radius = s.radius * scale_mult * 1.08
		cm.height = maxf(s.length + s.radius * 2.0, s.radius * 2.0) * scale_mult
		cm.radial_segments = 10
		cm.rings = 2
		var mi := Fx.mesh(cm, _mat)
		add_child(mi)
		var t: Transform3D = s.transform
		var o := center + (t.origin - center) * scale_mult + offset
		mi.transform = Transform3D(t.basis, o)


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()
		return
	var k := Fx.stepped(_left / _life)
	FxShader.fade(_mat, k)
	_mat.set_shader_parameter("alpha", _alpha * (0.5 + 0.5 * k))
	position += _drift * delta
