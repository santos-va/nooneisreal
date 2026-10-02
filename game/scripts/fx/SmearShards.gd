class_name SmearShards
extends Node3D
## "Torn pieces of drawn motion": ink shards and paper-thin streaks left along a fast move,
## in the character's palette. They drift back against the motion, spin and shrink in steps.

var _items: Array = []   # {node, mat, vel, spin, life, left, alpha}
var _rng := RandomNumberGenerator.new()


static func burst(parent: Node, from: Vector3, to: Vector3, colors: Array, count: int = 14, streaks: int = 4) -> SmearShards:
	var s := SmearShards.new()
	parent.add_child(s)
	s._emit(from, to, colors, count, streaks)
	return s


func _emit(from: Vector3, to: Vector3, colors: Array, count: int, streaks: int) -> void:
	_rng.randomize()
	var dir := to - from
	var back := -dir.normalized() if dir.length() > 0.01 else Vector3.ZERO
	for i in count:
		var c: Color = colors[_rng.randi() % colors.size()]
		var ink := _rng.randf() < 0.45
		var m := Fx.mat(Color(c.r, c.g, c.b, 0.9), not ink)
		var q := QuadMesh.new()
		q.size = Vector2(_rng.randf_range(0.12, 0.42), _rng.randf_range(0.04, 0.16))
		var mi := Fx.mesh(q, m)
		add_child(mi)
		mi.position = from.lerp(to, _rng.randf()) + Vector3(0.0, _rng.randf_range(0.3, 1.9), _rng.randf_range(-0.15, 0.35))
		mi.rotation.z = _rng.randf_range(0.0, TAU)
		var life := _rng.randf_range(0.22, 0.55)
		_items.append({"node": mi, "mat": m, "vel": back * _rng.randf_range(1.0, 4.5) + Vector3(0.0, _rng.randf_range(-0.6, 1.4), 0.0),
			"spin": _rng.randf_range(-12.0, 12.0), "life": life, "left": life, "alpha": 0.9})
	for i in streaks:
		var c2: Color = colors[i % colors.size()]
		var m2 := Fx.mat(Color(c2.r, c2.g, c2.b, 0.75), true)
		var q2 := QuadMesh.new()
		q2.size = Vector2(maxf(dir.length() * _rng.randf_range(0.5, 0.95), 0.4), _rng.randf_range(0.02, 0.06))
		var mi2 := Fx.mesh(q2, m2)
		add_child(mi2)
		mi2.position = (from + to) * 0.5 + Vector3(0.0, _rng.randf_range(0.4, 1.8), 0.25)
		var life2 := _rng.randf_range(0.12, 0.22)
		_items.append({"node": mi2, "mat": m2, "vel": back * 2.0, "spin": 0.0, "life": life2, "left": life2, "alpha": 0.75})


func _process(delta: float) -> void:
	var alive := 0
	for it in _items:
		if it.left <= 0.0:
			continue
		it.left -= delta
		var n: MeshInstance3D = it.node
		if it.left <= 0.0:
			n.visible = false
			continue
		alive += 1
		n.position += (it.vel as Vector3) * delta
		n.rotation.z += it.spin * delta
		var k := Fx.stepped(it.left / it.life)
		n.scale = Vector3.ONE * (0.4 + 0.6 * k)
		(it.mat as StandardMaterial3D).albedo_color.a = it.alpha * k
	if alive == 0:
		queue_free()
