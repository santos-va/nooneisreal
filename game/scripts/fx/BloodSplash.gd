class_name BloodSplash
extends Node3D
## One splash of the lethal fight (docs/Art/2026-10-07-Blood-Visual-Language.md variant A): flat comma drops and lobed
## splats with an ink rim fly along the blow, arc down in steps, shrink and are gone — nothing stays on the body.
## Presentation only, seeded from its owner's private RNG. Durations are PLACEHOLDER (T6: 0.25–0.55 s).
const SHADER := preload("res://shaders/fx_blood.gdshader")
const LIFE := Vector2(0.25, 0.55)
const GRAVITY := 9.0

var _items: Array = []   # {node, mat, vel, life, left, size}


## colours: [fill, shade, rim]. life_mult < 1 shortens the splash (Muted).
static func burst(parent: Node, at: Vector3, direction: Vector3, count: int, size: float, colours: Array, rim: bool, rng: RandomNumberGenerator, life_mult: float = 1.0) -> BloodSplash:
	var s := BloodSplash.new()
	s.name = "BloodSplash"
	parent.add_child(s)
	s.global_position = at
	s._emit(direction, count, size, colours, rim, rng, life_mult)
	return s


static func material(colours: Array, shape: int, rim: bool, seed_value: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("fill", colours[0])
	m.set_shader_parameter("shade", colours[1])
	m.set_shader_parameter("rim_color", colours[2])
	m.set_shader_parameter("shape", shape)
	m.set_shader_parameter("rim", 0.06 if rim else 0.0)
	m.set_shader_parameter("seed", seed_value)
	return m


func _emit(direction: Vector3, count: int, size: float, colours: Array, rim: bool, rng: RandomNumberGenerator, life_mult: float) -> void:
	var dir := Vector3(direction.x, 0.0, direction.z)
	dir = dir.normalized() if dir.length() > 0.01 else Vector3.RIGHT
	var side := dir.cross(Vector3.UP)
	for i: int in count:
		var splat := i % 3 == 0
		var m := material(colours, 1 if splat else 0, rim, rng.randf() * 100.0)
		m.set_shader_parameter("lobes", float(rng.randi_range(3, 5)))
		var q := QuadMesh.new()
		var s := size * rng.randf_range(0.10, 0.22) * (1.3 if splat else 1.0)
		q.size = Vector2(s * (1.0 if splat else 1.8), s)
		var mi := Fx.mesh(q, m)
		mi.name = "Drop%d" % i
		m.set_shader_parameter("fade", 1.0)
		add_child(mi)
		mi.position = side * rng.randf_range(-0.15, 0.15) + Vector3.UP * rng.randf_range(-0.15, 0.2)
		var life := rng.randf_range(LIFE.x, LIFE.y) * life_mult
		var vel := dir * rng.randf_range(1.6, 4.2) + side * rng.randf_range(-1.2, 1.2) + Vector3.UP * rng.randf_range(0.4, 2.2)
		_items.append({"node": mi, "mat": m, "vel": vel, "life": life, "left": life})


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	var alive := 0
	for it: Dictionary in _items:
		if float(it.left) <= 0.0:
			continue
		it.left = float(it.left) - delta
		var n: MeshInstance3D = it.node
		if float(it.left) <= 0.0:
			n.visible = false
			continue
		alive += 1
		it.vel = (it.vel as Vector3) + Vector3.DOWN * GRAVITY * delta
		n.position += (it.vel as Vector3) * delta
		if camera != null:
			# Face the lens (a flat cut-out, like the painted sheets).
			var away := n.global_position - camera.global_position
			if Vector2(away.x, away.z).length() > 0.05:
				n.look_at(n.global_position + away, Vector3.UP)
		var k := Fx.stepped(float(it.left) / float(it.life))
		n.scale = Vector3.ONE * (0.45 + 0.55 * k)
		(it.mat as ShaderMaterial).set_shader_parameter("fade", k)
	if alive == 0:
		queue_free()


## Live drops (fixtures read it).
func drop_count() -> int:
	var n := 0
	for it: Dictionary in _items:
		if float(it.left) > 0.0:
			n += 1
	return n
