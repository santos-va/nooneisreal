extends SceneTree
## Plan docs/Plans/2026-10-07-Living-Body.md step 1 (R1, R7, R8, J1–J3) and the P8 landing of step 2, on the real
## Arena, Fighter, CityFighter and SkeletalRig (game/scripts/fighter/LivingBodyMotion.gd):
##   T. The living body never changes the fight. A duel with it is identical tick by tick to the same duel without it:
##      hp, state, frames in state, stun, hitstop, move frame, position, velocity, facing, hurtbox, invulnerability,
##      land lag, combo, meter, squash, round and phase, and the fighters', capsule rigs' and CPU's RNG states — Choko vs
##      Skea and Skea vs Choko. On every drawn tick the mannequin holds exactly the authority the layer saved. The
##      scenario must start ≥ 1 ragdoll right after the layer drew, or the pose-leak negative would prove nothing.
##   R. R1/R8: a side hit plays Hit_Shoulder_L/R by side, a hook from the front by the swinging hand, a front hit keeps
##      the zone clip; every flinch clip reaches its end with the hitstun (the mannequin's stops part way); the force of
##      the blow orders the flinch; a light blow on the heavy Lamplighter holds (no squash on the hero), a heavy blow on
##      Skea does not; the flinch spring reaches the spine.
##   G. R7: the get-up clip runs from its first moving frame to its end in getup_frames(); the hero's hips are up when
##      GETUP ends, where the authority shows the body still low and jumping into the stance (measured both ways).
##   J. J1–J3 and P8 on CityFighter over real colliders: a 12-tick take-off with a stretch, NinjaJump_Start when running;
##      the apex; legs reaching in the last 6 frames; arms after 0.6 s of falling; landings light / normal / heavy by
##      impact speed, with a hand on the ground (normal, heavy), the trailing knee (heavy), the deeper squash (normal) and
##      dust (normal, heavy).
##   D. The deferred skeleton callback keeps the living pose on the hero and the mannequin stays the authority.
## Thresholds: brief/plan literals where named (T5 brief § 2.1, § 2.4); the contact distances are PLACEHOLDER (T6).
## --dump=<dir> writes the duel traces (TSV + SHA-256 of the raw rows) for a before/after comparison across trees. It
## also runs on a tree without the living body (the base); then only the plain duel is traced.
## --break=<m> is a negative control; sentinel LIVING_BODY_COMPLETE checks=N failures=M mutation=<m>.
const MUTATIONS := ["pose", "state", "rng", "hurtbox", "side", "fill", "getup", "tier", "deferred", "transfer"]
const TRACE_TICKS := 900                # PLACEHOLDER: 15 s of duel per run
const PAIRS := [["choko", "skea"], ["skea", "choko"]]
const HAND_TOUCH := 0.10                # PLACEHOLDER metres: «a hand on the ground»
const KNEE_TOUCH := 0.15                # PLACEHOLDER metres: «the knee to the ground»
const FILL_END := 0.85                  # the flinch clip has reached its end with the hitstun
var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var dump_dir: String = ""
var state: Node
var router: Node
var F: GDScript
var MF: GDScript
var City: GDScript
var LB: GDScript
var solids: Node3D
var _leaked_ragdolls: int = 0


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
		if argument.begins_with("--dump="):
			dump_dir = argument.trim_prefix("--dump=")
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("LIVING_BODY: " + label)


func _ticks(count: int) -> void:
	for tick: int in count:
		await physics_frame
		await process_frame


func _until(condition: Callable, limit: int) -> void:
	for tick: int in limit:
		if condition.call():
			return
		await _ticks(1)


func _run() -> void:
	await process_frame
	state = root.get_node("GameState")
	router = root.get_node("InputRouter")
	F = load("res://scripts/fighter/Fighter.gd")
	MF = load("res://scripts/arena/MatchFlow.gd")
	City = load("res://scripts/world/CityFighter.gd")
	state.set_free_move(true)
	state.skeletal_rig = true
	state.training_mode = false
	state.water = null
	router.apply_profile("solo", false)
	root.size = Vector2i(1280, 720)
	var living_tree: bool = false
	for property: Dictionary in (load("res://scripts/fighter/SkeletalRig.gd") as Script).get_script_property_list():
		living_tree = living_tree or property.name == "living_body"
	if not dump_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(dump_dir)
	if mutation in ["none", "pose", "state", "rng", "hurtbox"] or not dump_dir.is_empty():
		await _traces(living_tree)
	if living_tree and dump_dir.is_empty():
		# Arena.gd:44 sets GameState.water for a stage with water and nothing clears it after the traces; the living
		# body then leaves the landing to FxDirector's river splash and draws no dust.
		state.water = null
		LB = load("res://scripts/fighter/LivingBodyMotion.gd")
		solids = Node3D.new()
		root.add_child(solids)
		_box(Vector3(0, -0.5, 0), Vector3(80, 1, 80))
		await physics_frame
		if mutation in ["none", "side", "fill"]:
			await _reactions()
		if mutation in ["none", "getup"]:
			await _getup()
		if mutation in ["none", "tier"]:
			await _jumps()
		if mutation in ["none", "deferred", "transfer"]:
			await _deferred()
		solids.queue_free()
	for singleton: String in ["Sfx", "UltMusic"]:
		root.get_node(singleton).queue_free()
	var until: int = Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("LIVING_BODY_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
	quit(0 if failures == 0 else 1)


func _box(at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var geometry := BoxShape3D.new()
	geometry.size = size
	shape.shape = geometry
	body.add_child(shape)
	solids.add_child(body)
	body.position = at
	return body


# --- T. the living body never changes the fight -----------------------------------------------------------------
func _row(p1: Node, p2: Node, flow: Node) -> Array:
	var row: Array = []
	for f: Node in [p1, p2]:
		row.append_array([f.hp, f.state, f.frame_in_state, f.stun_frames, f.hitstop_frames, f.move_frame, f.global_position,
			f.velocity, f.forward, f.facing, f.hurt_shape.disabled, f.invulnerable_frames, f.land_lag, f.combo_count, f.meter,
			f.squash, f._rng.state, f.animator._rng.state])
	var brain: Node = p2._brain
	row.append_array([flow.phase, flow.round_no, brain._rng.state if brain != null else -1])
	return row


func _trace(a: String, b: String, living: bool, living_tree: bool) -> Dictionary:
	state.p1_character = a
	state.p2_character = b
	var arena: Node = load("res://scenes/arena/Arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	var p1: Node = arena.get("p1")
	var p2: Node = arena.get("p2")
	var flow: Node = arena.get_node("MatchFlow")
	if living_tree:
		for f: Node in [p1, p2]:
			f.skeletal.living_body.enabled = living
	var leak: bool = living and mutation in ["state", "rng", "hurtbox"]
	if leak:
		for f: Node in [p1, p2]:
			f.hit_landed.connect(_leak_hit)
	await _until(func() -> bool: return flow.phase == MF.Phase.FIGHT, 300)
	var rows: Array = []
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	var tsv: PackedStringArray = []
	var drawn: Dictionary = {"flinch": 0, "getup": 0, "takeoff": 0, "apex": 0, "fall": 0, "rise": 0, "land_light": 0, "land_normal": 0, "land_heavy": 0}
	var p1_drawn: Dictionary = drawn.duplicate()   # the player's hero alone: each hero is p1 in one pair
	var ragdolls_after_draw: int = 0
	var intact: bool = true
	var previous_mode: Dictionary = {}
	var previous_ragdolls: Dictionary = {}
	for f: Node in [p1, p2]:
		previous_mode[f] = ""
		previous_ragdolls[f] = int(f.stats.ragdolls)
	for tick: int in TRACE_TICKS:
		# Cycles of 194 ticks: trade blows and strafe, then jump (pressed until it is taken) and let it land.
		var cycle: int = tick % 194
		router.v_set(1, "left", cycle < 100 and (tick / 120) % 3 == 1)
		router.v_set(1, "right", cycle < 100 and (tick / 120) % 3 == 2)
		if cycle < 100 and tick % 23 == 5:
			router.v_press(1, "light")
		if cycle < 100 and tick % 61 == 7:
			router.v_press(1, "heavy")
		if cycle >= 100 and cycle < 112 and p1.state != F.State.JUMP:
			router.v_press(1, "jump")
		# On the cycles without the air blow the CPU is frozen (TIME STOP, Fighter.freeze) for the jump, or it
		# anti-airs every jump and the landing is never drawn (probe 2026-10-08: Choko LAUNCHED at tick 159).
		if cycle == 100 and (tick / 194) % 2 == 0:
			p2.freeze(70)
		# The same stimuli in every run: a blow in the air every second cycle (a ragdoll from the jump pose) and a
		# second blow in a flinch.
		if cycle == 118 and (tick / 194) % 2 == 1 and p1.state == F.State.JUMP:
			p1.receive_hit(p2, p2.data.light)
		if tick % 53 == 20 and p2.state == F.State.HITSTUN:
			p2.receive_hit(p1, p1.data.heavy)
		if tick % 71 == 35 and p2.state == F.State.JUMP:
			p2.receive_hit(p1, p1.data.light)
		await _ticks(1)
		if leak and mutation == "state":
			for f: Node in [p1, p2]:
				if f.has_meta("living_leak_stun") and f.state == F.State.HITSTUN:
					f.remove_meta("living_leak_stun")
					f.stun_frames += 1
		for f: Node in [p1, p2]:
			if living_tree and living:
				var body = f.skeletal.living_body
				if not body.mode.is_empty() and drawn.has(body.mode):
					drawn[body.mode] += 1
					if f == p1:
						p1_drawn[body.mode] += 1
				if not body.mode.is_empty() and f.skeletal.ragdoll == null and not body.authority_intact(f.skeletal.skeleton):
					intact = false
				if int(f.stats.ragdolls) > int(previous_ragdolls[f]) and not String(previous_mode[f]).is_empty():
					ragdolls_after_draw += 1
				previous_mode[f] = body.mode
				if mutation == "pose" and not body.mode.is_empty() and f.skeletal.ragdoll == null:
					# The leak this negative stands for: the presented pose stays on the mannequin after the retarget.
					var presented: Array = body.presented_rotations()
					for bone: int in presented.size():
						f.skeletal.skeleton.set_bone_pose_rotation(bone, presented[bone])
			previous_ragdolls[f] = int(f.stats.ragdolls)
		var row: Array = _row(p1, p2, flow)
		rows.append(row)
		hashing.update(var_to_bytes(row))
		if not dump_dir.is_empty():
			var cells: PackedStringArray = []
			for value: Variant in row:
				cells.append(var_to_str(value))
			tsv.append("\t".join(cells))
	router.v_clear(1)
	var digest: String = hashing.finish().hex_encode()
	arena.queue_free()
	await _ticks(4)
	return {"rows": rows, "digest": digest, "tsv": tsv, "drawn": drawn, "p1_drawn": p1_drawn, "ragdolls_after_draw": ragdolls_after_draw, "intact": intact}


## The leaks the T negatives stand for, on the victim of a clean blow.
func _leak_hit(_attacker: Node, victim: Node, _move: Resource, blocked: bool) -> void:
	if blocked:
		return
	if mutation == "rng":
		victim.animator._rng.randf()   # the capsule flinch RNG seeds the capsule ragdoll pose
	elif mutation == "hurtbox":
		victim.invulnerable_frames += 3
	elif mutation == "state":
		victim.set_meta("living_leak_stun", true)


func _traces(living_tree: bool) -> void:
	var summary: PackedStringArray = []
	for pair: Array in PAIRS:
		var label := "%s vs %s" % pair
		if not living_tree:
			var base: Dictionary = await _trace(pair[0], pair[1], false, false)
			_write_dump("%s_%s_base" % pair, base)
			summary.append("%s base %s" % [label, base.digest])
			continue
		var off: Dictionary = await _trace(pair[0], pair[1], false, true)
		var on: Dictionary = await _trace(pair[0], pair[1], true, true)
		_write_dump("%s_%s_off" % pair, off)
		_write_dump("%s_%s_on" % pair, on)
		var first := -1
		var column := -1
		for k: int in mini(on.rows.size(), off.rows.size()):
			if on.rows[k] != off.rows[k]:
				first = k
				for c: int in on.rows[k].size():
					if on.rows[k][c] != off.rows[k][c]:
						column = c
						break
				break
		summary.append("%s: on %s off %s, first difference %d (column %d), drawn %s, p1 %s, ragdolls right after a drawn tick %d" % [label, on.digest.left(16), off.digest.left(16), first, column, str(on.drawn), str(on.p1_drawn), on.ragdolls_after_draw])
		_check(first == -1 and on.digest == off.digest and on.rows.size() == TRACE_TICKS, "%s: every traced field and RNG equals the duel without the living body over %d ticks (first difference %d, column %d)" % [label, TRACE_TICKS, first, column])
		if mutation == "none":
			_check(on.intact, "%s: on every drawn tick the mannequin holds exactly the saved authority" % label)
			_check(on.drawn.flinch > 0 and on.drawn.getup > 0, "%s: the duel draws flinch and get-up (%s)" % [label, str(on.drawn)])
			var landings: int = int(on.p1_drawn.land_light) + int(on.p1_drawn.land_normal) + int(on.p1_drawn.land_heavy)
			_check(on.p1_drawn.takeoff > 0 and (on.p1_drawn.apex + on.p1_drawn.fall) > 0 and landings > 0, "%s: %s's own take-off, apex/fall and landing are drawn inside the traced duel (%s)" % [label, pair[0], str(on.p1_drawn)])
			_check(on.ragdolls_after_draw > 0, "%s: ≥ 1 ragdoll starts right after a drawn tick, so a pose leak would show (%d)" % [label, on.ragdolls_after_draw])
	print("LIVING_BODY_INFO trace: %d ticks each; %s" % [TRACE_TICKS, "; ".join(summary)])


func _write_dump(name: String, run: Dictionary) -> void:
	if dump_dir.is_empty():
		return
	var file := FileAccess.open(dump_dir.path_join(name + ".tsv"), FileAccess.WRITE)
	file.store_string("\n".join(run.tsv) + "\n")
	file.close()
	var digest := FileAccess.open(dump_dir.path_join(name + ".sha256"), FileAccess.WRITE)
	digest.store_string(String(run.digest) + "\n")
	digest.close()


# --- shared fixtures ---------------------------------------------------------------------------------------------
func _fighter(id: String, at: Vector3, city: bool = false) -> Node:
	var f: Node = load("res://scenes/fighter/Fighter.tscn").instantiate()
	if city:
		f.set_script(City)
	f.data = load("res://data/characters/%s.tres" % id)
	root.add_child(f)
	f.global_position = at
	f.forward = Vector3.RIGHT
	return f


# --- R. R1 / R8 ---------------------------------------------------------------------------------------------------
## Hits `victim` with `move` from an attacker standing at `offset`, steps until the hitstun ends and returns what the
## layer and the mannequin drew.
func _flinch(victim: Node, attacker: Node, move: Resource, offset: Vector3) -> Dictionary:
	victim.global_position = Vector3(0, 0, 0)
	victim.forward = Vector3.RIGHT
	victim.velocity = Vector3.ZERO
	victim.invulnerable_frames = 0
	victim.hitstop_frames = 0
	victim._set_state(F.State.IDLE)
	attacker.global_position = offset
	await _ticks(2)
	victim.global_position = Vector3.ZERO
	victim.forward = Vector3.RIGHT   # the idle controller turns toward the opponent; the blow lands on this facing
	var body = victim.skeletal.living_body
	if mutation == "side":
		victim.hit_landed.connect(func(_a: Node, _v: Node, _m: Resource, _b: bool) -> void:
			body._pending_side = {"left": "right", "right": "left"}.get(body._pending_side, body._pending_side), CONNECT_ONE_SHOT)
	victim.receive_hit(attacker, move)
	var out: Dictionary = {"clip": "", "last_time": 0.0, "length": 0.0, "authority_ratio": 0.0, "amplitude": 0.0, "held": false, "hero_scale_y": 0.0, "rig_scale_y": 0.0, "spring": 0.0, "frames": 0, "mode": ""}
	for tick: int in 120:
		await _ticks(1)
		if victim.state != F.State.HITSTUN:
			if tick > 2:
				break
			continue
		if mutation == "fill":
			# The defect this negative stands for: the clip is not paced by the hitstun at all and stays on its first
			# frames. (progress = 1 − stun / total reaches 1 for any positive total, so a wrong total is no defect.)
			body._flinch_total = 0
		out.frames += 1
		out.mode = body.mode
		# What the eye sees, hitstop included: Fighter's squash of the whole SkeletalRig times this layer's hero scale.
		var seen: float = victim.skeletal.scale.y * victim.skeletal.hero.scale.y
		out.hero_scale_y = seen if out.hero_scale_y == 0.0 else (minf(out.hero_scale_y, seen) if not body.held else maxf(absf(out.hero_scale_y - 1.0), absf(seen - 1.0)) + 1.0)
		out.rig_scale_y = maxf(out.rig_scale_y, 1.0 - victim.skeletal.scale.y)
		if body.mode == "flinch":
			out.clip = body.clip
			out.last_time = body.clip_time
			out.length = body.clip_length(body.clip)
			out.amplitude = body.amplitude
			out.held = body.held
			var sk: Node = victim.skeletal
			var anim: Animation = sk.player.get_animation(sk.clip)
			out.authority_ratio = sk.clip_pos / maxf(anim.length, 0.0001)
			if out.frames <= 8 and not body.presented_rotations().is_empty():
				var sample: Array = body.sample(body.clip, body.clip_time)
				var spine: int = sk.skeleton.find_bone("spine_02")
				var reference: Quaternion = (sample[0] as Array)[spine]
				if body.amplitude < 1.0:
					reference = (body.sample(body._idle_clip, 0.0)[0] as Array)[spine].slerp(reference, body.amplitude)
				out.spring = maxf(out.spring, rad_to_deg(reference.angle_to(body.presented_rotations()[spine])))
	await _ticks(20)
	return out


func _reactions() -> void:
	var summary: PackedStringArray = []
	for pair: Array in [["choko", "skea"], ["skea", "choko"]]:
		var victim: Node = _fighter(pair[0], Vector3.ZERO)
		var attacker: Node = _fighter(pair[1], Vector3(1.2, 0, 0))
		victim.opponent = attacker
		attacker.opponent = victim
		attacker.set_physics_process(false)
		await _ticks(3)
		var id: String = pair[0]
		# The victim faces +X: its left is −Z, its right +Z (forward × up).
		var left: Dictionary = await _flinch(victim, attacker, attacker.data.light, Vector3(0, 0, -1.2))
		_check(left.clip == "Hit_Shoulder_L", "%s: a blow from the left side plays Hit_Shoulder_L (got '%s')" % [id, left.clip])
		var right: Dictionary = await _flinch(victim, attacker, attacker.data.light, Vector3(0, 0, 1.2))
		_check(right.clip == "Hit_Shoulder_R", "%s: a blow from the right side plays Hit_Shoulder_R (got '%s')" % [id, right.clip])
		var front: Dictionary = await _flinch(victim, attacker, attacker.data.light, Vector3(1.2, 0, 0))
		var zone: String = LB.ZONE_CLIPS.get(victim.animator.flinch_zone, "")
		_check(front.clip == zone and zone != "", "%s: a front blow keeps the zone clip '%s' (got '%s')" % [id, zone, front.clip])
		var hook: Resource = load("res://scripts/fighter/LimbMoves.gd").resolve(attacker.data, "right_hand", 1, "right_hand", false, false)
		var hooked: Dictionary = await _flinch(victim, attacker, hook, Vector3(1.2, 0, 0))
		_check(hooked.clip == "Hit_Shoulder_L", "%s: the attacker's right hook from the front lands on the left (got '%s')" % [id, hooked.clip])
		for run: Dictionary in [left, right, front]:
			_check(run.length > 0.0 and run.last_time >= run.length * FILL_END, "%s %s: the flinch clip reaches its end with the hitstun (%.2f of %.2f s; the mannequin's stops at %.0f %%)" % [id, run.clip, run.last_time, run.length, run.authority_ratio * 100.0])
		_check(front.spring > 0.2, "%s: the flinch spring reaches the spine (%.2f° over the clip)" % [id, front.spring])
		var light: Dictionary = await _flinch(victim, attacker, attacker.data.light, Vector3(1.2, 0, 0))
		var heavy: Dictionary = await _flinch(victim, attacker, attacker.data.heavy, Vector3(1.2, 0, 0))
		_check(heavy.amplitude > light.amplitude or heavy.amplitude >= 1.0, "%s: the heavier blow moves the body further (light %.2f, heavy %.2f)" % [id, light.amplitude, heavy.amplitude])
		summary.append("%s: L %s %.0f%% / R %s %.0f%% / front %s %.0f%% (authority %.0f%%) / hook %s / spring %.1f° / amp light %.2f heavy %.2f" % [id, left.clip, left.last_time / maxf(left.length, 0.001) * 100.0, right.clip, right.last_time / maxf(right.length, 0.001) * 100.0, front.clip, front.last_time / maxf(front.length, 0.001) * 100.0, front.authority_ratio * 100.0, hooked.clip, front.spring, light.amplitude, heavy.amplitude])
		victim.queue_free()
		attacker.queue_free()
		await _ticks(3)
	if mutation != "none":
		print("LIVING_BODY_INFO reactions: " + "; ".join(summary))
		return
	# R8: a light blow on the heavy Lamplighter (weight 1.1) holds; a heavy blow on Skea (0.9) does not.
	var lamplighter: Node = _fighter("lamplighter", Vector3.ZERO)
	var choko: Node = _fighter("choko", Vector3(1.2, 0, 0))
	lamplighter.opponent = choko
	choko.opponent = lamplighter
	choko.set_physics_process(false)
	await _ticks(3)
	var held: Dictionary = await _flinch(lamplighter, choko, choko.data.light, Vector3(1.2, 0, 0))
	_check(held.held and held.amplitude < 1.0, "R8: Choko's light blow on the Lamplighter holds (held %s, amplitude %.2f)" % [held.held, held.amplitude])
	_check(held.rig_scale_y > 0.01 and absf(held.hero_scale_y - 1.0) < 0.005, "R8: Fighter still squashes the rig (%.3f) but the held hero shows no squash on any hitstun frame (worst hero y %.3f)" % [held.rig_scale_y, held.hero_scale_y])
	lamplighter.queue_free()
	choko.queue_free()
	var skea: Node = _fighter("skea", Vector3.ZERO)
	var striker: Node = _fighter("choko", Vector3(1.2, 0, 0))
	skea.opponent = striker
	striker.opponent = skea
	striker.set_physics_process(false)
	await _ticks(3)
	var full: Dictionary = await _flinch(skea, striker, striker.data.heavy, Vector3(1.2, 0, 0))
	_check(not full.held and full.amplitude >= 0.999 and full.hero_scale_y < 0.995, "R8: Choko's heavy blow on Skea is a full flinch with its squash (held %s, amplitude %.2f, hero y %.3f)" % [full.held, full.amplitude, full.hero_scale_y])
	summary.append("R8 Lamplighter light: held %s amp %.2f rig squash %.3f hero y %.3f; Skea heavy: held %s amp %.2f hero y %.3f" % [held.held, held.amplitude, held.rig_scale_y, held.hero_scale_y, full.held, full.amplitude, full.hero_scale_y])
	skea.queue_free()
	striker.queue_free()
	await _ticks(3)
	print("LIVING_BODY_INFO reactions: " + "; ".join(summary))


# --- G. R7 --------------------------------------------------------------------------------------------------------
func _hips(f: Node) -> float:
	var hero: Skeleton3D = f.skeletal.hero_skeleton
	return (hero.global_transform * hero.get_bone_global_pose(hero.find_bone("Hips")).origin).y - f.global_position.y


func _getup_run(f: Node, living: bool) -> Dictionary:
	f.skeletal.living_body.enabled = living
	f.global_position = Vector3.ZERO
	f.velocity = Vector3.ZERO
	await _ticks(30)
	var standing: float = _hips(f)
	f._set_state(F.State.GETUP)
	f.invulnerable_frames = 26
	var first_time: float = -1.0
	var last_time: float = -1.0
	var end_hips: float = 0.0
	var jump: float = 0.0
	var idle_ticks: int = 0
	var length: float = 0.0
	var previous: float = -1.0
	for tick: int in 60:
		await _ticks(1)
		if mutation == "getup":
			f.skeletal.living_body.enabled = false
		var now: float = _hips(f)
		if f.state == F.State.GETUP:
			end_hips = now
			if f.skeletal.living_body.mode == "getup":
				if first_time < 0.0:
					first_time = f.skeletal.living_body.clip_time
				last_time = f.skeletal.living_body.clip_time
				length = f.skeletal.living_body.clip_length(f.skeletal.living_body.clip)
		elif f.state == F.State.IDLE and end_hips > 0.0:
			# The jump into the stance: the largest one-tick hip move once GETUP has ended (control is back).
			jump = maxf(jump, absf(now - previous))
			idle_ticks += 1
			if idle_ticks >= 12:
				break
		previous = now
	f.skeletal.living_body.enabled = true
	return {"standing": standing, "first": first_time, "last": last_time, "length": length, "end": end_hips, "jump": jump}


func _getup() -> void:
	var summary: PackedStringArray = []
	for id: String in ["choko", "skea"]:
		var f: Node = _fighter(id, Vector3.ZERO)
		await _ticks(3)
		var before: Dictionary = await _getup_run(f, false)
		var after: Dictionary = await _getup_run(f, true)
		var from: float = float(LB.GETUP_FROM.get(f.data.getup_clip, 0.0))
		_check(absf(after.first - from) < 0.15 and after.last >= after.length - 0.001, "%s: %s runs from its first moving frame (%.2f s, want %.2f) to its end (%.2f of %.2f s) in getup_frames()" % [id, f.data.getup_clip, after.first, from, after.last, after.length])
		_check(after.end >= after.standing * 0.85, "%s: the hips are up when GETUP ends (%.2f m of standing %.2f)" % [id, after.end, after.standing])
		_check(after.jump < before.jump * 0.35, "%s: no jump into the stance — after GETUP the hips move at most %.3f m a tick with the living body, %.3f m without" % [id, after.jump, before.jump])
		summary.append("%s %s: authority ends GETUP with hips at %.2f m, then up to %.3f m a tick into the stance; living ends at %.2f m, then up to %.3f m a tick (standing %.2f)" % [id, f.data.getup_clip, before.end, before.jump, after.end, after.jump, after.standing])
		f.queue_free()
		await _ticks(3)
	print("LIVING_BODY_INFO getup: " + "; ".join(summary))


# --- J. J1–J3 / P8 ------------------------------------------------------------------------------------------------
func _drop(f: Node, height: float) -> Dictionary:
	router.v_clear(1)
	f.restart_at(Vector3(0, height, 0))
	f.global_position = Vector3(0, height, 0)
	f._set_state(F.State.JUMP)
	f.velocity = Vector3.ZERO
	var body = f.skeletal.living_body
	var out: Dictionary = {"tier": "", "speed": 0.0, "modes": {}, "reach": 0.0, "arms": 0.0, "hand": INF, "knee": INF, "squash_y": 1.0, "dust": 0}
	var fx_before: int = _flipbooks()
	var fx_most: int = fx_before
	var landed: bool = false
	for tick: int in 200:
		await _ticks(1)
		fx_most = maxi(fx_most, _flipbooks())
		if mutation == "tier" and body.mode.begins_with("land_") and body.landing_tier != "light":
			body.landing_tier = "light"
		if not body.mode.is_empty():
			out.modes[body.mode] = int(out.modes.get(body.mode, 0)) + 1
		out.reach = maxf(out.reach, body.reach_weight)
		out.arms = maxf(out.arms, body.arm_weight)
		if body.mode.begins_with("land_"):
			landed = true
			out.tier = body.landing_tier
			out.speed = body.impact_speed
			out.hand = minf(out.hand, body.hand_clearance)
			out.knee = minf(out.knee, body.knee_clearance)
			out.squash_y = minf(out.squash_y, body.hero_scale.y)
		elif landed and body.mode.is_empty():
			break
	out.dust = fx_most - fx_before
	await _ticks(10)
	return out


## Flipbook.spawned counts every sheet a Flipbook has played (a static, so a check can read it after the node is gone).
func _flipbooks() -> int:
	return int((load("res://scripts/fx/Flipbook.gd").spawned as Dictionary).get("dust_land", 0))


func _jumps() -> void:
	var summary: PackedStringArray = []
	for id: String in ["choko", "skea"]:
		var f: Node = _fighter(id, Vector3.ZERO, true)
		await _ticks(3)
		router.set_view_basis(1, Vector3.FORWARD)
		if mutation != "tier":
			# J1–J2: a standing jump, then a running one, on the real controller.
			router.v_clear(1)
			f.restart_at(Vector3.ZERO)
			await _ticks(20)
			var modes: Dictionary = {}
			var stretch: float = 1.0
			var takeoff_clip: String = ""
			router.v_press(1, "jump")
			for tick: int in 90:
				await _ticks(1)
				var body = f.skeletal.living_body
				if not body.mode.is_empty():
					modes[body.mode] = int(modes.get(body.mode, 0)) + 1
				if body.mode == "takeoff":
					stretch = maxf(stretch, body.hero_scale.y)
					takeoff_clip = body.clip
			_check(int(modes.get("takeoff", 0)) == 12 and takeoff_clip == "Jump_Start" and stretch > 1.02, "%s: a standing take-off draws Jump_Start for 12 ticks (0.20 s) with a stretch (got %d ticks, '%s', y ×%.3f)" % [id, int(modes.get("takeoff", 0)), takeoff_clip, stretch])
			_check(int(modes.get("apex", 0)) > 0 and int(modes.get("fall", 0)) > 0 and int(modes.get("land_light", 0)) > 0, "%s: apex, fall and a light landing follow (%s)" % [id, str(modes)])
			router.v_clear(1)
			f.restart_at(Vector3(-20, 0, 0))
			router.set_view_basis(1, Vector3.FORWARD)
			router.v_set(1, "right", true)
			await _ticks(50)
			router.v_press(1, "jump")
			var running_clip: String = ""
			for tick: int in 20:
				await _ticks(1)
				if f.skeletal.living_body.mode == "takeoff":
					running_clip = f.skeletal.living_body.clip
			router.v_clear(1)
			_check(running_clip == "NinjaJump_Start", "%s: a running take-off draws NinjaJump_Start (got '%s')" % [id, running_clip])
			await _ticks(60)
			summary.append("%s jump %s run '%s' stretch ×%.3f" % [id, str(modes), running_clip, stretch])
		# J2–J3 / P8: drops onto the real floor collider.
		var light: Dictionary = await _drop(f, 1.0)
		var normal: Dictionary = await _drop(f, 3.5)
		var heavy: Dictionary = await _drop(f, 20.0)
		_check(light.tier == "light" and normal.tier == "normal" and heavy.tier == "heavy", "%s: landings by impact speed light %.1f / normal %.1f / heavy %.1f m/s → %s / %s / %s" % [id, light.speed, normal.speed, heavy.speed, light.tier, normal.tier, heavy.tier])
		_check(normal.hand <= HAND_TOUCH and heavy.hand <= HAND_TOUCH, "%s: a hand reaches the ground on normal and heavy landings (%.3f / %.3f m)" % [id, normal.hand, heavy.hand])
		_check(heavy.knee <= KNEE_TOUCH, "%s: the trailing knee reaches the ground on a heavy landing (%.3f m)" % [id, heavy.knee])
		_check(normal.squash_y < 0.99 and light.squash_y >= 0.999, "%s: the normal landing squashes deeper than Fighter's (hero y ×%.3f), the light one does not (×%.3f)" % [id, normal.squash_y, light.squash_y])
		_check(normal.dust >= 1 and heavy.dust >= 1 and light.dust == 0, "%s: dust on normal and heavy landings only (%d / %d / %d)" % [id, light.dust, normal.dust, heavy.dust])
		_check(heavy.reach > 0.5 and heavy.arms > 0.5, "%s: in a long drop the legs reach for the ground (%.2f) and the arms search for balance (%.2f)" % [id, heavy.reach, heavy.arms])
		summary.append("%s drops: light %.1f m/s hand %.3f; normal %.1f m/s hand %.3f squash ×%.3f dust %d; heavy %.1f m/s hand %.3f knee %.3f dust %d reach %.2f arms %.2f" % [id, light.speed, light.hand, normal.speed, normal.hand, normal.squash_y, normal.dust, heavy.speed, heavy.hand, heavy.knee, heavy.dust, heavy.reach, heavy.arms])
		f.queue_free()
		await _ticks(3)
	router.v_clear(1)
	print("LIVING_BODY_INFO jumps: " + "; ".join(summary))


# --- D. the deferred skeleton callback -----------------------------------------------------------------------------
## Both heroes: Choko's sword transfer runs after every retarget, so a reapplied hero pose must be the retarget's own
## output, or the transfer lands twice (trick_motion_check «repeated full callback gives identical pose», 2026-10-08).
func _deferred() -> void:
	for pair: Array in [["skea", "choko"], ["choko", "skea"]]:
		var victim: Node = _fighter(pair[0], Vector3.ZERO)
		var attacker: Node = _fighter(pair[1], Vector3(0, 0, -1.2))
		victim.opponent = attacker
		attacker.opponent = victim
		attacker.set_physics_process(false)
		if victim.skeletal.sword != null:
			victim.sword_drawn = true
		await _ticks(5)
		victim.receive_hit(attacker, attacker.data.light)
		await _until(func() -> bool: return victim.state == F.State.HITSTUN and victim.hitstop_frames == 0 and victim.skeletal.living_body.mode == "flinch", 30)
		await physics_frame
		var sk: Node = victim.skeletal
		var hero: Skeleton3D = sk.hero_skeleton
		var before: Array = []
		for bone: int in hero.get_bone_count():
			before.append(hero.get_bone_pose(bone))
		if mutation == "deferred":
			sk.living_body._hero_cached = false   # the callback forgets this tick's living pose
		elif mutation == "transfer":
			# The 2026-10-08 defect: the kept pose is taken after the sword transfer, so a reapply transfers twice.
			sk.living_body._laid = true
			sk.living_body.keep_hero(hero)
			sk.living_body._laid = false
		var same: bool = true
		for repeat: int in 2:
			sk._on_mannequin_updated()
			for bone: int in hero.get_bone_count():
				same = same and (before[bone] as Transform3D).is_equal_approx(hero.get_bone_pose(bone))
		_check(sk.living_body.mode == "flinch" and same, "%s: repeated deferred skeleton callbacks keep this tick's living pose on the hero, sword transfer included" % pair[0])
		_check(sk.living_body.authority_intact(sk.skeleton) and sk.clip == sk.clip_name(sk.STATE_CLIPS["hit_" + victim.animator.flinch_zone]) and sk.living_body.clip == "Hit_Shoulder_L", "%s: the mannequin keeps the authority clip '%s' while the hero shows '%s'" % [pair[0], sk.clip, sk.living_body.clip])
		# In the air the drawn sword keeps its ready grip (SwordMotion.apply_transfer runs for JUMP, not HITSTUN).
		await _until(func() -> bool: return victim.state == F.State.IDLE, 60)
		victim.global_position = Vector3(0, 3.0, 0)
		victim.velocity = Vector3.ZERO
		victim._set_state(F.State.JUMP)
		await _until(func() -> bool: return victim.skeletal.living_body.mode in ["apex", "fall"] and victim.skeletal.living_body.presented_rotations().size() > 0, 20)
		await physics_frame
		var air: Array = []
		for bone: int in hero.get_bone_count():
			air.append(hero.get_bone_pose(bone))
		if mutation == "deferred":
			sk.living_body._hero_cached = false
		elif mutation == "transfer":
			sk.living_body._laid = true
			sk.living_body.keep_hero(hero)
			sk.living_body._laid = false
		var steady: bool = true
		for repeat: int in 2:
			sk._on_mannequin_updated()
			for bone: int in hero.get_bone_count():
				steady = steady and (air[bone] as Transform3D).is_equal_approx(hero.get_bone_pose(bone))
		_check(sk.living_body.mode in ["apex", "fall"] and steady, "%s: in the air (%s, sword drawn %s) repeated deferred callbacks rebuild the same hero pose" % [pair[0], sk.living_body.mode, victim.sword_drawn])
		victim.queue_free()
		attacker.queue_free()
		await _ticks(3)
