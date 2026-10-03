class_name SwordStormFx
extends Node3D
## Choko ultimate «Шторм мечів»: eight spectral emerald blades rise behind him, then rain down
## in a line in front: 6 fast hits + a final heavy strike that ragdolls. Hits skip combo scaling.

const BLADES := 8
const RISE := 18
const EVERY := 6
const HITS := 6
const FINAL := 62
const REACH := 5.4
const HALF_WIDTH := 0.6   # free movement: the band is 5.4 × 1.2 m (width ДИЗАЙН, docs/GDD/03 § Як у 3D)

var owner_f: Fighter
var _f: int = 0
var _facing: int = 1
var _blades: Array = []
var _tick: MoveData
var _final: MoveData
var _mat: StandardMaterial3D


static func spawn(f: Fighter) -> SwordStormFx:
	var s := SwordStormFx.new()
	s.owner_f = f
	Fx.root(f).add_child(s)
	s.global_position = f.global_position
	return s


func _ready() -> void:
	_facing = owner_f.facing
	if GameState.free_move:
		# free movement: turn the whole effect onto the gaze; locally it is the plane's +x setup
		rotation.y = owner_f.yaw()
		_facing = 1
	_tick = SkillHit.make("sword_storm_tick", 26.0, 14, Vector2(0.6, 0.0),
		{"hitstop": 2, "ignore_scaling": true, "can_crit": false, "meter": 0.0, "sfx": "sword"})
	_final = SkillHit.make("sword_storm_final", 100.0, 30, Vector2(8.5, 7.0),
		{"hitstop": 10, "knockdown": true, "ragdoll": 1.3, "ignore_scaling": true, "can_crit": false, "meter": 0.0, "sfx": "hit_heavy"})
	_mat = Fx.mat(Color(owner_f.data.vfx_primary, 0.85), true)
	for i in BLADES:
		var bm := PrismMesh.new()
		bm.size = Vector3(0.16, 1.2, 0.05)
		var b := Fx.mesh(bm, _mat)
		add_child(b)
		b.position = Vector3(0, 1.2, 0)
		_blades.append(b)
	Sfx.play("sword", -2)


func _physics_process(_delta: float) -> void:
	if owner_f == null or not is_instance_valid(owner_f):
		queue_free()
		return
	if owner_f.frozen_frames > 0 or TimeStopFx.freezes(global_position, owner_f):
		return
	_f += 1
	for i in BLADES:
		var b: MeshInstance3D = _blades[i]
		var launch := RISE + i * 5
		if _f < launch:
			var ang := float(i) / float(BLADES) * PI + float(_f) * 0.08
			var t := minf(1.0, float(_f) / float(RISE))
			b.position = Vector3(-_facing * 0.6 + cos(ang) * 1.3, 1.2 + sin(ang) * 1.3 * t + 0.8 * t, -0.3)
			b.rotation.z = ang
		else:
			var k := minf(1.0, float(_f - launch) / 6.0)
			var target := Vector3(_facing * (1.0 + float(i) * 0.58), 0.5, 0.1)
			var start := Vector3(target.x - _facing * 1.5, 5.5, 0.1)
			b.position = start.lerp(target, k)
			b.rotation.z = PI if _facing > 0 else -PI
			b.visible = _f < launch + 16
	if _f >= RISE and (_f - RISE) % EVERY == 0 and (_f - RISE) / EVERY < HITS:
		_hit(_tick)
	if _f == FINAL:
		_hit(_final)
		SmearShards.burst(Fx.root(owner_f), to_global(Vector3(_facing * 0.5, 0, 0)), to_global(Vector3(_facing * REACH, 0, 0)),
			[owner_f.data.vfx_primary, owner_f.data.vfx_secondary, Color(0.05, 0.05, 0.08)], 18, 5)
	if _f > FINAL + 24:
		queue_free()


func _hit(m: MoveData) -> void:
	var v := owner_f.opponent
	if v == null or not v.hurtbox_enabled():
		return
	var dx := (v.global_position.x - global_position.x) * float(_facing)
	var side := 0.0
	if GameState.free_move:
		var local := to_local(v.global_position)   # +x = the gaze at the start of the ultimate
		dx = local.x
		side = absf(local.z)
	if dx >= -0.6 and dx <= REACH and side <= HALF_WIDTH and absf(v.global_position.y - global_position.y) < 3.0:
		v.receive_hit(owner_f, m)
