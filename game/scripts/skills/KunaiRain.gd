class_name KunaiRain
extends Node3D
## Skea S1 «Стальний ливень»: a bundle of kunai tossed up rains on a circle around the target point.
## 8 quick ticks, small hitstun each, every tick applies Armor Break (reveals all weak points).

const RADIUS := 2.2
const TICKS := 8
const FIRST := 14
const EVERY := 7
const FALL_SPEED := 30.0

var owner_f: Fighter
var _f: int = 0
var _ticks: int = 0
var _kunai: Array = []
var _tick_move: MoveData
var _ring_mat: StandardMaterial3D
var _steel: StandardMaterial3D
var _glow: StandardMaterial3D
var _rng := RandomNumberGenerator.new()


static func spawn(f: Fighter, center_x: float) -> KunaiRain:
	var k := KunaiRain.new()
	k.owner_f = f
	Fx.root(f).add_child(k)
	k.global_position = Vector3(center_x, 0.0, 0.0)
	return k


func _ready() -> void:
	_rng.seed = 4242
	_tick_move = SkillHit.make("kunai_tick", 11.0, 11, Vector2(0.4, 0.0),
		{"blockstun": 6, "hitstop": 1, "chip": 3.0, "effect": "armor_break", "can_crit": false, "meter": 2.0, "sfx": "kunai"})
	_ring_mat = Fx.mat(Color(owner_f.data.vfx_primary, 0.55), true)
	var tm := TorusMesh.new()
	tm.inner_radius = RADIUS - 0.08
	tm.outer_radius = RADIUS
	tm.rings = 40
	tm.ring_segments = 4
	var ring := Fx.mesh(tm, _ring_mat)
	ring.position = Vector3(0, 0.03, 0)
	add_child(ring)
	_steel = StandardMaterial3D.new()
	_steel.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_steel.albedo_color = Color(0.16, 0.15, 0.2)
	_glow = Fx.mat(Color(owner_f.data.vfx_primary, 0.8), true)
	Sfx.play("whoosh", -4)


func _physics_process(delta: float) -> void:
	if SkillHit.paused(owner_f):
		if owner_f == null or not is_instance_valid(owner_f):
			queue_free()
		return
	if TimeStopFx.freezes(global_position, owner_f):
		return
	_f += 1
	if _f >= 6 and _f < FIRST + TICKS * EVERY - 4:
		for i in 2:
			_spawn_kunai()
	for k in _kunai:
		var n: Node3D = k.node
		if k.stuck:
			k.left -= delta
			n.visible = k.left > 0.0
			continue
		n.position.y -= FALL_SPEED * delta
		if n.position.y <= 0.15:
			n.position.y = 0.15
			k.stuck = true
	if _f >= FIRST and (_f - FIRST) % EVERY == 0 and _ticks < TICKS:
		_ticks += 1
		_hit()
	_ring_mat.albedo_color.a = 0.55 * (0.6 + 0.4 * sin(float(_f) * 0.5))
	if _ticks >= TICKS and _f > FIRST + TICKS * EVERY + 24:
		queue_free()


func _spawn_kunai() -> void:
	var root := Node3D.new()
	var blade := Fx.mesh(PrismMesh.new(), _steel)
	(blade.mesh as PrismMesh).size = Vector3(0.09, 0.32, 0.03)
	blade.rotation.z = PI
	root.add_child(blade)
	var tail := Fx.mesh(BoxMesh.new(), _glow)
	(tail.mesh as BoxMesh).size = Vector3(0.02, 0.5, 0.02)
	tail.position = Vector3(0, 0.38, 0)
	root.add_child(tail)
	add_child(root)
	root.position = Vector3(_rng.randf_range(-RADIUS, RADIUS), _rng.randf_range(6.5, 8.5), _rng.randf_range(-0.5, 0.6))
	root.rotation.z = _rng.randf_range(-0.15, 0.15)
	_kunai.append({"node": root, "stuck": false, "left": 0.35})


func _hit() -> void:
	var v := owner_f.opponent
	if v == null or not v.hurtbox_enabled():
		return
	if absf(v.global_position.x - global_position.x) <= RADIUS and v.global_position.y < 4.0:
		v.receive_hit(owner_f, _tick_move)
