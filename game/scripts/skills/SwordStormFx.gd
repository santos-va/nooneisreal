class_name SwordStormFx
extends Node3D
## Choko ultimate «Шторм мечів»: eight spectral emerald blades rise behind him, then rain down
## in a line in front: 6 fast hits + a final heavy strike that ragdolls. Hits skip combo scaling.
## Crystal look (Santos 2026-10-03, «кристальна ульта»): each blade is a faceted emerald crystal (crystal.gdshader);
## it sticks into the ground where it lands and bursts into shards; the final strike throws a wave of shards.
## Presentation only — the hit frames, reach and damage below are unchanged.

const BLADES := 8
const RISE := 18
const EVERY := 6
const HITS := 6
const FINAL := 62
const REACH := 5.4
const HALF_WIDTH := 0.6   # free movement: the band is 5.4 × 1.2 m (width ДИЗАЙН, docs/GDD/03 § Як у 3D)
const CRYSTAL := preload("res://shaders/crystal.gdshader")
const BLADE_SHARDS := 5     # shards when a landed blade bursts
const FINAL_SHARDS := 14    # shards along the line on the final strike
const SHARD_LIFE := 22      # frames

var owner_f: Fighter
var _f: int = 0
var _facing: int = 1
var _blades: Array = []
var _tick: MoveData
var _final: MoveData
var _mat: ShaderMaterial
var shards: Array = []      # [{node, vel, spin, left}] — read by the smoke
var shards_spawned: int = 0


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
	_mat = ShaderMaterial.new()
	_mat.shader = CRYSTAL
	var c: Color = owner_f.data.vfx_primary
	_mat.set_shader_parameter("core", c.lightened(0.45))
	_mat.set_shader_parameter("deep", c.darkened(0.7))
	var blade := crystal_blade(1.2, 0.16, 0.07)
	for i in BLADES:
		var b := Fx.mesh(blade, _mat)
		add_child(b)
		b.position = Vector3(0, 1.2, 0)
		_blades.append(b)
	Sfx.play("sword", -2)


## A crystal sword: hexagonal cross-section, a long faceted tip pointing +y and a short point at the base.
## Unindexed triangles, so each facet is flat. Length along y, width along x, thickness along z.
static func crystal_blade(length: float, width: float, thick: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring: Array[Vector3] = []
	var y0 := -length * 0.32   # widest ring sits low: a heavy blade, long tip
	for k in 6:
		var a := TAU * float(k) / 6.0
		ring.append(Vector3(cos(a) * width * 0.5, y0, sin(a) * thick * 0.5))
	var tip := Vector3(0, length * 0.5, 0)
	var base := Vector3(0, -length * 0.5, 0)
	for k in 6:
		var p := ring[k]
		var q := ring[(k + 1) % 6]
		for v in [p, tip, q, q, base, p]:
			st.add_vertex(v)
	st.generate_normals()
	return st.commit()


## Shards: small crystals flung from `at`, spread around `dir` (local space). Deterministic (index-based), visual only.
func _burst(at: Vector3, dir: Vector3, count: int, size: float, salt: int) -> void:
	var shard := crystal_blade(size, size * 0.45, size * 0.3)
	for k in count:
		var h := float((salt * 73 + k * 37) % 101) / 101.0
		var h2 := float((salt * 29 + k * 61) % 97) / 97.0
		var n := Fx.mesh(shard, _mat)
		add_child(n)
		n.position = at
		n.rotation = Vector3(h * TAU, h2 * TAU, 0.0)
		var spread := Vector3(cos(h * TAU), 0.0, sin(h * TAU)) * (1.5 + h2 * 2.0)
		shards.append({"node": n, "vel": dir * (2.0 + h2 * 3.0) + spread + Vector3(0, 3.0 + h * 3.0, 0),
			"spin": Vector3(6.0 + h * 8.0, 4.0 - h2 * 8.0, 0.0), "left": SHARD_LIFE})
	shards_spawned += count


func _tick_shards() -> void:
	var dt := 1.0 / 60.0
	for e in shards:
		var n: MeshInstance3D = e["node"]
		e["left"] = int(e["left"]) - 1
		e["vel"] = (e["vel"] as Vector3) + Vector3(0, -18.0 * dt, 0)
		n.position += (e["vel"] as Vector3) * dt
		if n.position.y < 0.02:
			n.position.y = 0.02
			e["vel"] = (e["vel"] as Vector3) * Vector3(0.5, -0.3, 0.5)
		n.rotation += (e["spin"] as Vector3) * dt
		n.scale = Vector3.ONE * Fx.stepped(float(e["left"]) / float(SHARD_LIFE), 4)
		if int(e["left"]) <= 0:
			n.queue_free()
	shards = shards.filter(func(e: Dictionary) -> bool: return int(e["left"]) > 0)


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
			# tip down, tilted along the fall; once landed the crystal stays stuck in the ground
			b.rotation.z = PI + _facing * 0.35 * (1.0 - k) if _facing > 0 else -PI + _facing * 0.35 * (1.0 - k)
			b.visible = _f < launch + 16
			if _f == launch + 16:
				_burst(target + Vector3(0, -0.3, 0), Vector3(_facing, 0, 0), BLADE_SHARDS, 0.28, i + 1)
	if _f >= RISE and (_f - RISE) % EVERY == 0 and (_f - RISE) / EVERY < HITS:
		_hit(_tick)
	if _f == FINAL:
		_hit(_final)
		SmearShards.burst(Fx.root(owner_f), to_global(Vector3(_facing * 0.5, 0, 0)), to_global(Vector3(_facing * REACH, 0, 0)),
			[owner_f.data.vfx_primary, owner_f.data.vfx_secondary, Color(0.05, 0.05, 0.08)], 18, 5)
		for k in FINAL_SHARDS:
			var x := 0.5 + (REACH - 0.5) * float(k) / float(FINAL_SHARDS - 1)
			_burst(Vector3(_facing * x, 0.1, 0.0), Vector3(_facing, 0.4, 0), 1, 0.45, 40 + k)
	_tick_shards()
	if _f > FINAL + SHARD_LIFE + 2 and shards.is_empty():
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
