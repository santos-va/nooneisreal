class_name SmokeCloud
extends Node3D
## Lingering smoke (Skea's Shadow Veil). `covers()` lets the CPU brain treat it as blinding.
## Look (fx_smoke): cel puffs with a lilac shadow side and an ink rim that burn away in steps.
## radius / life / covers() are read by the CPU brain — the look must never change them.

var radius: float = 2.0
var _puffs: Array = []
var _life: float = 3.0
var _left: float = 3.0
var _rng := RandomNumberGenerator.new()


static func spawn(parent: Node, pos: Vector3, color: Color, life: float = 3.0, r: float = 2.0) -> SmokeCloud:
	var s := SmokeCloud.new()
	s.add_to_group("smoke")
	parent.add_child(s)
	s.global_position = pos
	s._build(color, life, r)
	return s


func _build(color: Color, life: float, r: float) -> void:
	_rng.seed = FxShader.rng().randi()
	_life = life
	_left = life
	radius = r
	for i in 12:
		var m := FxShader.smoke(color)
		var sm := SphereMesh.new()
		sm.radius = _rng.randf_range(0.35, 0.7)
		sm.height = sm.radius * 2.0
		sm.radial_segments = 16   # fx_smoke pushes the surface out with noise — needs the vertices
		sm.rings = 8
		var mi := Fx.mesh(sm, m)
		add_child(mi)
		mi.position = Vector3(_rng.randf_range(-r, r) * 0.7, _rng.randf_range(-0.8, 0.9), _rng.randf_range(-0.4, 0.6))
		_puffs.append({"node": mi, "mat": m, "grow": _rng.randf_range(1.6, 2.6), "rise": _rng.randf_range(0.05, 0.3)})


func covers(p: Vector3) -> bool:
	return _left > 0.2 and Vector2(p.x - global_position.x, p.y + 1.0 - global_position.y).length() < radius


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()
		return
	var t := 1.0 - _left / _life
	for p in _puffs:
		var n: MeshInstance3D = p.node
		n.scale = Vector3.ONE * lerpf(0.5, p.grow, minf(1.0, t * 4.0))
		n.position.y += p.rise * delta
		FxShader.fade(p.mat, Fx.stepped(_left / _life, 6))
