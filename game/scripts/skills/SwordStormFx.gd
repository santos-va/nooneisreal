class_name SwordStormFx
extends Node3D
## Choko ultimate — the crystal ult (docs/GDD/03-Skills-Framework.md § Кристальна ульта Choko, T5 Арес 3c-1; plan
## docs/Plans/2026-10-03-Crystal-Ult-Arena-Fatigue.md, step 3c). The golden crystal sword bursts into «pyramids»:
## frame 6 — a point-blank blast (half-circle 1.2 m in front, 70 × crit, breaks Skea's ult armor); frames 18…48 — six
## ticks of crystal rain over 5 bands, each further band wider and weaker; frame 62 — the final over all bands
## (knockdown + ragdoll). A target is hit by the band it stands in on that tick. Hits skip combo scaling.
## All numbers PLACEHOLDER (ДИЗАЙН Ареса). Frames count from the move's first active frame (this node's _f).

const BLADES := 8           # crystals rising off the sword (look only)
const RISE := 18            # first rain tick
const EVERY := 6
const HITS := 6
const FINAL := 62
const BLAST_FRAME := 6
const BLAST_RADIUS := 1.2
const BLAST_DAMAGE := 70.0  # × Fighter.CRIT_MULT = 105
const BLAST_HITSTUN := 40
## Bands along the gaze: [from m, to m, full width m, damage per tick, final]. GDD 03 § (а).
const BANDS := [
	[0.8, 2.0, 1.2, 25.0, 75.0],
	[2.0, 3.2, 1.8, 22.0, 63.0],
	[3.2, 4.4, 2.4, 18.0, 57.0],
	[4.4, 5.6, 3.0, 15.0, 45.0],
	[5.6, 6.8, 3.6, 12.0, 33.0],
]
## Point-blank (closer than band 1's start, down to just behind Choko like the old line): still band 1 —
## GDD 03's smoke wants 330 at 0.5 m = blast 105 + band 1's 225.
const NEAR_BEHIND := -0.6
const REACH := 6.8
const CRYSTAL := preload("res://shaders/crystal.gdshader")
## Gold of ult sword №1 (weapons-choko-ult) — docs/Art/VFX-Direction.md § Кристальна ульта Choko (T6 Аполлон, 3c-2):
## taken from the card's pixels, the shadow shifted into Style-Guide's #B07AA6.
const GOLD_CORE := Color(0.812, 0.747, 0.447)    # #CFBE72
const GOLD_DEEP := Color(0.387, 0.218, 0.140)    # #633724
const GOLD_SHADE := Color("#8F5B4A")             # gold in shadow — final shards
const INK := Color("#2B2230")                    # line ink: shards and the crystals' outline
const TIP := Color("#EFEED4")                    # the cream tip: frame 5, «it is coming»
const GLOW := 1.6
const GLOW_FLASH := 3.0                          # frame 0
const OUTLINE_W := 0.022                         # same ink outline as the fighters (RigAnimator._mat)
const BLADE_SHARDS := 5     # shards when a landed crystal bursts
const SHARD_LIFE := 22      # frames

var owner_f: Fighter
var _f: int = 0
var _facing: int = 1
var _blades: Array = []
var _ticks: Array = []      # MoveData per band
var _finals: Array = []
var _blast: MoveData
var _mat: ShaderMaterial
var shards: Array = []      # [{node, vel, spin, left}] — read by the smoke
var shards_spawned: int = 0
var hit_log: Array = []     # [effect frame, move id] per landed hit — the smoke checks the frames against GDD 03 (б)


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
	for i in BANDS.size():
		_ticks.append(make_tick(i))
		_finals.append(make_final(i))
	_blast = make_blast()
	_mat = ShaderMaterial.new()
	_mat.shader = CRYSTAL
	_mat.set_shader_parameter("core", GOLD_CORE)
	_mat.set_shader_parameter("deep", GOLD_DEEP)
	# against terracotta the gold reads at contrast 2.15 only: the silhouette is the rim + the fighters' ink outline (T6)
	var ink := ShaderMaterial.new()
	ink.shader = RigAnimator.OUTLINE
	ink.set_shader_parameter("outline_color", INK)
	ink.set_shader_parameter("width", OUTLINE_W)
	_mat.next_pass = ink
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


## A 4-sided pyramid «пірамідка» (T6: CylinderMesh, top_radius 0, radial_segments 4), `size` tall.
static func pyramid(size: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = 0.0
	m.bottom_radius = size * 0.45
	m.height = size
	m.radial_segments = 4
	m.rings = 1
	return m


## Shards: small crystals flung from `at`, spread around `dir` (local space). Deterministic (index-based), visual only.
func _burst(at: Vector3, dir: Vector3, count: int, size: float, salt: int) -> void:
	var shard := pyramid(size)
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
	# frames 0…6 (T6): a flash on frame 0, the cream tip on frame 5, back to gold when it bursts on 6 — in steps, no fades
	_mat.set_shader_parameter("glow", GLOW_FLASH if _f == 1 else GLOW)
	_mat.set_shader_parameter("core", TIP if _f == BLAST_FRAME - 1 else GOLD_CORE)
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
			var target := Vector3(_facing * (1.0 + float(i) * 0.8), 0.5, 0.1)   # spread over the 5 bands (0.8–6.8 m)
			var start := Vector3(target.x - _facing * 1.5, 5.5, 0.1)
			b.position = start.lerp(target, k)
			# tip down, tilted along the fall; once landed the crystal stays stuck in the ground
			b.rotation.z = PI + _facing * 0.35 * (1.0 - k) if _facing > 0 else -PI + _facing * 0.35 * (1.0 - k)
			b.visible = _f < launch + 16
			if _f == launch + 16:
				_burst(target + Vector3(0, -0.3, 0), Vector3(_facing, 0, 0), BLADE_SHARDS, 0.28, i + 1)
	if _f == BLAST_FRAME:
		_hit_blast()
		_burst(Vector3(_facing * 0.6, 1.0, 0.0), Vector3(_facing, 0.6, 0), 8, 0.3, 90)
	if _f >= RISE and (_f - RISE) % EVERY == 0 and (_f - RISE) / EVERY < HITS:
		_hit_band(_ticks)
	if _f == FINAL:
		_hit_band(_finals)
		SmearShards.burst(Fx.root(owner_f), to_global(Vector3(_facing * 0.5, 0, 0)), to_global(Vector3(_facing * REACH, 0, 0)),
			[GOLD_CORE, GOLD_SHADE, INK], 18, 5)
		for i in BANDS.size():
			var b: Array = BANDS[i]
			var mid := (float(b[0]) + float(b[1])) * 0.5
			for side in [-1.0, 0.0, 1.0]:
				_burst(Vector3(_facing * mid, 0.1, side * float(b[2]) * 0.4), Vector3(_facing, 0.4, 0), 1, 0.45, 40 + i * 3 + int(side) + 1)
	_tick_shards()
	if _f > FINAL + SHARD_LIFE + 2 and shards.is_empty():
		queue_free()


static func make_tick(i: int) -> MoveData:
	return SkillHit.make("sword_storm_band%d" % (i + 1), BANDS[i][3], 14, Vector2(0.6, 0.0),
		{"hitstop": 2, "ignore_scaling": true, "can_crit": false, "meter": 0.0, "sfx": "sword"})


static func make_final(i: int) -> MoveData:
	return SkillHit.make("sword_storm_final%d" % (i + 1), BANDS[i][4], 30, Vector2(8.5, 7.0),
		{"hitstop": 10, "knockdown": true, "ragdoll": 1.3, "ignore_scaling": true, "can_crit": false, "meter": 0.0, "sfx": "hit_heavy"})


static func make_blast() -> MoveData:
	return SkillHit.make("sword_storm_blast", BLAST_DAMAGE, BLAST_HITSTUN, Vector2.ZERO,
		{"hitstop": 8, "ignore_scaling": true, "force_crit": true, "breaks_armor": true, "meter": 0.0, "sfx": "hit_heavy"})


## Target in the effect's frame (+x = the gaze at the ult's start; the plane: x along facing, no side).
func _local(p: Vector3) -> Vector2:
	if GameState.free_move:
		var l := to_local(p)
		return Vector2(l.x, l.z)
	return Vector2((p.x - global_position.x) * float(_facing), 0.0)


## Band index (0…4) of a point in the effect's frame, -1 = none. Point-blank (NEAR_BEHIND…0.8 m) counts as band 1.
static func band_at(local: Vector2) -> int:
	var x := local.x
	if x < NEAR_BEHIND or x >= REACH:
		return -1
	for i in BANDS.size():
		var b: Array = BANDS[i]
		if (x < float(b[1]) or i == BANDS.size() - 1) and (i == 0 or x >= float(b[0])):
			return i if absf(local.y) <= float(b[2]) * 0.5 else -1
	return -1


## The rain never lands outside the arena (free movement: the circle; the plane: its half width).
static func in_arena(p: Vector3) -> bool:
	if GameState.free_move:
		return Vector2(p.x, p.z).length() <= Fighter.ARENA_RADIUS
	return absf(p.x) <= Fighter.ARENA_HALF_WIDTH


## Point-blank blast: half-circle of BLAST_RADIUS in front of Choko.
static func in_blast(local: Vector2) -> bool:
	return local.x >= 0.0 and local.length() <= BLAST_RADIUS


func _target() -> Fighter:
	var v := owner_f.opponent
	if v == null or not v.hurtbox_enabled() or absf(v.global_position.y - global_position.y) >= 3.0:
		return null
	return v


func _hit_band(moves: Array) -> void:
	var v := _target()
	if v == null or not in_arena(v.global_position):
		return
	var i := band_at(_local(v.global_position))
	if i >= 0:
		v.receive_hit(owner_f, moves[i])
		hit_log.append([_f, (moves[i] as MoveData).id])


func _hit_blast() -> void:
	var v := _target()
	if v != null and in_blast(_local(v.global_position)):
		v.receive_hit(owner_f, _blast)
		hit_log.append([_f, _blast.id])
