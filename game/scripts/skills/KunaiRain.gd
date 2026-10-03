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
	return spawn_at(f, Vector3(center_x, 0.0, 0.0))


## Free movement: the circle lands on a ground point (x, z).
static func spawn_at(f: Fighter, center: Vector3) -> KunaiRain:
	var k := KunaiRain.new()
	k.owner_f = f
	Fx.root(f).add_child(k)
	k.global_position = Vector3(center.x, 0.0, center.z)
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
			Flipbook.play(self, "kunai_impact", n.global_position + Vector3(0, 0.03, 0), 0.9, {"mode": Flipbook.Mode.FLOOR, "additive": true})
	if _f >= FIRST and (_f - FIRST) % EVERY == 0 and _ticks < TICKS:
		_ticks += 1
		_hit()
	_ring_mat.albedo_color.a = 0.55 * (0.6 + 0.4 * sin(float(_f) * 0.5))
	if _ticks >= TICKS and _f > FIRST + TICKS * EVERY + 24:
		queue_free()


## A kunai: a still of T6·B's kunai_fall sheet (cell KUNAI_CELL — blade down, streak above) as a billboard; the
## procedural prism + streak only when the sheet is missing. The node moves; the drawing does not decide the hit.
const KUNAI_CELL := 5
func _spawn_kunai() -> void:
	var root := Node3D.new()
	add_child(root)
	if Flipbook.texture_for("kunai_fall") != null:
		Flipbook.play(self, "kunai_fall", Vector3(0, 0.25, 0), 1.0, {"parent": root, "first": KUNAI_CELL, "hold": true})
	else:
		var blade := Fx.mesh(PrismMesh.new(), _steel)
		(blade.mesh as PrismMesh).size = Vector3(0.09, 0.32, 0.03)
		blade.rotation.z = PI
		root.add_child(blade)
		var tail := Fx.mesh(BoxMesh.new(), _glow)
		(tail.mesh as BoxMesh).size = Vector3(0.02, 0.5, 0.02)
		tail.position = Vector3(0, 0.38, 0)
		root.add_child(tail)
	root.position = Vector3(_rng.randf_range(-RADIUS, RADIUS), _rng.randf_range(6.5, 8.5), _rng.randf_range(-0.5, 0.6))
	if GameState.free_move:
		root.position.z = _rng.randf_range(-RADIUS, RADIUS)   # the circle has depth now
	root.rotation.z = _rng.randf_range(-0.15, 0.15)
	_kunai.append({"node": root, "stuck": false, "left": 0.35})


func _hit() -> void:
	var v := owner_f.opponent
	if v == null or not v.hurtbox_enabled():
		return
	var d := v.global_position - global_position
	var reach := Vector2(d.x, d.z).length() if GameState.free_move else absf(d.x)   # 3D: a circle (docs/GDD/03 § Як у 3D)
	if reach <= RADIUS and v.global_position.y < 4.0:
		v.receive_hit(owner_f, _tick_move)
