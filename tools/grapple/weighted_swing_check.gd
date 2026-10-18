extends SceneTree
## Behavioural regression: motor budget, pendulum energy and shared attachment ownership.
## The duel keeps Space ≤ 1.2 m (T5 docs/GDD/2026-10-15-Rope-Climb-Numbers.md § 8: lines unchanged). The responsive
## profile without the city climb (the duel after 15в) keeps the 1.2 m stroke too. The city rope (ADR-028, a CityFighter
## body, GrappleHook.climb_enabled) follows T5 § 8:
##   Л-а — Space held: L shortens by at most climb_speed / 60 + 1e-6 a tick and stops at 2.0 ± 1e-6;
##   Л-б — then exactly 30 ticks of the pull-up, after them the grip: the hands' grip point y_anchor + 0.30 ± 0.01, the
##         feet y_anchor − GrappleHook.perch_feet() ± 0.01 (Choko 1.28: the T6 pose, per hero by T1; T5 wrote 1.75 —
##         docs/Fix/2026-10-15-Rope-Climb-City-Fix.md § 0, docs/Fix/2026-10-15-Rope-Perch-Entry-Fix.md), |v| ≤ 0.001;
##   Л-в — 179 more ticks of Space on the grip keep the feet (± 0.001); without Space the rope never shortens (no floor
##         here, so no pull either);
##   Е-1 — no stick, no Space, no pull: E_world = ½|v|² + g·y_hand (world zero) never grows by more than 0.03 a tick;
##   Е-2 — the stick against the motion: the same bound; Е-3 — the stick with the motion: amplitude ≤ 75°, the hand at
##         least 0.25·L under the anchor, |v| ≤ min(11, 0.85·√(gL));
##   Е-4 — a climb step adds at most 0.03 to the tangential speed; Е-5 — the slide adds at most 0.03 to E_world;
##   Е-6 — a let-go changes |v| by at most 0.001.
##   --break=fast|lift|noreq|perpetual|twosided|boost — negatives (class 18: each prints its families on the
##     WEIGHTED_SWING_FAMILIES line and must go red in its own): the climb at 2 × climb_speed (Л-а), the grip 0.5 m higher
##     (Л-б), a climb with nothing held (Л-в, rope_climb_mutants.gd), the velocity × 1.01 a tick (Е-1), a pump along the
##     motion whatever the stick, k 24 (Е-2), + 1 m/s on a let-go (Е-6).
var checks: int = 0
var failures: int = 0
var f: Node3D
var other: Node3D
var anchor: Node3D
var Hook: GDScript
var Actor: GDScript
var registry: Node3D
var mutation: String = "none"
var red: Dictionary = {}
var city: Node3D            # the city rope's body: Fighter.tscn running CityFighter
var perch_anchor: Node3D
const HOOK_MUTATIONS: Array[String] = ["noreq", "perpetual", "twosided", "boost"]
const CLIMB_SPEED: float = 3.6      # T5 Л1
const MIN_ROPE: float = 2.0         # T5 Л2
const PULL_UP_TICKS: int = 30       # T5 Л3: 0.5 s at 60 ticks/s
const GRIP_RISE: float = 0.30       # T5 Л4
const FEET_BELOW: float = 1.28      # T6 § 3 pose, Choko's (the city body here): T1 on T6 acceptance § 9 п. 8 (see the header)
const SLIDE_SPEED: float = 2.0      # T5 С1

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	_run.call_deferred()

func check(ok: bool, label: String, family: String = "") -> void:
	checks += 1
	if not ok:
		failures += 1
		if not family.is_empty():
			red[family] = true
		push_error("WEIGHTED_SWING: " + ("[%s] " % family if not family.is_empty() else "") + label)

func hang(length: float, responsive: bool = false) -> void:
	registry.clear_match()
	f.position = Vector3(0, 3, 0)
	f.velocity = Vector3.ZERO
	f._wish = Vector3.ZERO
	f.control_locked = false
	f.state = Actor.State.GRAPPLE
	anchor.position = f.position + Hook.HAND + Vector3.UP * length
	var token: int = registry.issue(1)
	registry.deploy(token, 1, anchor.position, f.position + Hook.HAND, length)
	f.grapple.responsive_parkour = responsive
	f.grapple.fire(false, "grapple_parkour" if responsive else "grapple")

func energy() -> float:
	var bottom: float = f.grapple.anchor_point.y - f.grapple.rope_length
	return 0.5 * f.velocity.length_squared() + Actor.GRAVITY * (f.position.y + Hook.HAND.y - bottom)

## T5 Е-1: the energy from the world's zero (the slide lowers the body; a pendulum-bottom reference would move with it).
func world_energy(body: Node3D) -> float:
	return 0.5 * body.velocity.length_squared() + Actor.GRAVITY * (body.position.y + Hook.HAND.y)

## A city hang: the CityFighter body on a fresh rope of `length` under the perch anchor (its arm runs 1 m toward +x).
func hang_city(length: float) -> void:
	registry.clear_match()
	city.position = Vector3(20, 3, 0)
	city.velocity = Vector3.ZERO
	city._wish = Vector3.ZERO
	city.control_locked = false
	city.state = Actor.State.GRAPPLE
	city.grapple.climb_input = 0
	perch_anchor.position = city.position + Hook.HAND + Vector3.UP * length
	var token: int = registry.issue(1)
	registry.deploy(token, 1, perch_anchor.position, city.position + Hook.HAND, length)
	city.grapple.fire(false, "grapple_parkour")

func _run() -> void:
	await process_frame
	Actor = load("res://scripts/fighter/Fighter.gd")
	Hook = load("res://scripts/grapple/GrappleHook.gd")
	var state: Node = root.get_node("GameState")
	state.free_move = true
	state.skeletal_rig = false
	state.water = null
	var scene := load("res://scenes/fighter/Fighter.tscn") as PackedScene
	f = scene.instantiate()
	f.data = load("res://data/characters/choko.tres")
	root.add_child(f)
	f.set_physics_process(false)
	other = scene.instantiate()
	other.data = load("res://data/characters/skea.tres")
	other.player_index = 2
	root.add_child(other)
	other.set_physics_process(false)
	other.position = Vector3(50, 0, 0)
	registry = f.grapple.registry
	registry.set_physics_process(false)
	anchor = Node3D.new()
	root.add_child(anchor)
	anchor.add_to_group("grapple_anchor")
	# The city rope's body (CityFighter on the hero scene, as CityWorld builds it) and an anchor with an arm.
	city = scene.instantiate()
	city.set_script(load("res://scripts/world/CityFighter.gd"))
	if mutation in HOOK_MUTATIONS:
		city.get_node("GrappleHook").set_script(load((get_script() as Script).resource_path.get_base_dir().path_join("rope_climb_mutants.gd")))
	city.data = load("res://data/characters/choko.tres")
	root.add_child(city)
	city.set_physics_process(false)
	if mutation in HOOK_MUTATIONS:
		city.grapple.set("mutation", mutation)
	elif mutation == "fast":
		city.grapple.climb_speed *= 2.0
	elif mutation == "lift":
		city.grapple.perch_feet_below -= 0.5
	perch_anchor = Node3D.new()
	perch_anchor.name = "PerchAnchor"
	root.add_child(perch_anchor)
	perch_anchor.add_to_group("grapple_anchor")
	await physics_frame
	hang(6.0)
	var start_y: float = f.position.y
	var input: Node = root.get_node("InputRouter")
	input.v_set(1, "jump", true)
	for frame: int in 120:
		f._tick_grapple(f._read_intent())
	input.v_clear(1)
	check(f.grapple.attached, "Space alone keeps the attached rope")
	check(f.position.y > start_y + 1.0 and f.position.y < start_y + 1.25, "Space lifts from rest without movement, bounded to 1.2 m")
	var held_length: float = f.grapple.rope_length
	for frame: int in 180:
		f.grapple.drive(1.0 / 60.0, false, true)
	check(is_equal_approx(held_length, f.grapple.rope_length), "continued Space cannot reel indefinitely")
	check(absf(f.velocity.y) < 0.02, "reel correction does not become inward spring momentum")
	f.grapple.drive(1.0 / 60.0, false, false)
	check(not f.grapple.attached, "both released detaches")
	# The responsive profile without the city climb (the duel after 15в) keeps the finite 1.2 m stroke and release energy.
	hang(6.0, true)
	check(is_equal_approx(f.grapple.reel_remaining(), 1.2), "city HUD exposes actual bounded stroke")
	start_y = f.position.y
	for frame: int in 20:
		f.grapple.drive(1.0 / 60.0, true, true)
	check(f.position.y > start_y + 1.19 and f.position.y < start_y + 1.21, "city reel completes 1.2 m stroke in 20 ticks")
	check(f.grapple.reel_remaining() < 0.0001, "city HUD reports spent stroke")
	for frame: int in 180:
		f.grapple.drive(1.0 / 60.0, true, true)
	check(is_equal_approx(f.grapple.rope_length, 4.8) and absf(f.velocity.y) < 0.02, "city held reel cannot become a perpetual lift")
	f.grapple.drive(1.0 / 60.0, false)
	check(is_zero_approx(f.grapple.reel_remaining()) and absf(f.velocity.y) < 0.02, "city release has no phantom stroke or vertical kick")
	for responsive: bool in [false, true]:
		verify_pendulum(responsive)
	verify_city_climb()
	verify_city_energy()
	# Render attachment offsets must not turn physical tension into spare cable.
	hang(6.0)
	var hand_rig = load("res://scripts/fighter/SkeletalRig.gd").new()
	f.add_child(hand_rig)
	var hand_skeleton := Skeleton3D.new()
	hand_skeleton.add_bone("RightHand")
	hand_rig.add_child(hand_skeleton)
	hand_rig.hero_skeleton = hand_skeleton
	f.skeletal = hand_rig
	for offset: Vector3 in [Vector3(0, 2.1, 0), Vector3(0.6, 0.9, 0.3), Vector3(-0.5, 1.8, -0.4)]:
		hand_rig.position = offset
		f.grapple._draw_rope(f.position + Hook.HAND, anchor.position)
		var cable = f.grapple._rope_visual
		check(cable.points[0].is_equal_approx(hand_rig.global_position), "render line follows actual hand")
		var straight: bool = true
		for i: int in cable.points.size():
			straight = straight and cable.points[i].distance_to(hand_rig.global_position.lerp(anchor.position, float(i) / (cable.points.size() - 1))) < 0.0001
		check(straight, "animated hand offset cannot invent slack under load")
	# Moving toward the anchor really does create slack; it must still fall.
	f.position.y += 1.0
	for frame: int in 60:
		f.grapple._draw_rope(f.position + Hook.HAND, anchor.position)
	var loose = f.grapple._rope_visual
	var sag: float = 0.0
	for i: int in loose.points.size():
		sag = maxf(sag, loose.points[i].distance_to(hand_rig.global_position.lerp(anchor.position, float(i) / (loose.points.size() - 1))))
	check(sag > 0.01, "physical slack remains deformable")
	f.skeletal = null
	hand_rig.free()
	# Occupancy is shared across players, checked at contact, and leaves a recoverable token.
	hang(6.0)
	var second: int = registry.issue(2)
	check(not registry.deploy(second, 2, anchor.position, other.position, 6.0), "second owner cannot deploy at occupied point")
	check(not registry.deploy(second, 2, anchor.position + Vector3(0.02, 0, 0), other.position, 6.0), "coincident marker does not bypass occupancy")
	check(not registry.records[second].deployed and registry.refund(second, 2) and not registry.refund(second, 2), "rejected deploy refunds exactly once")
	f.grapple.reset()
	check(registry.occupied(anchor.position) and f.grapple.best_anchor() == null, "round reset preserves occupied anchor; automatic new aim excludes it")
	var available: int = f.grapple.charges
	var intent := {"point": anchor.position, "target_id": String(anchor.get_path())}
	f.position = Vector3(5, 3, 0)
	check(f.grapple.fire(false, "grapple_parkour", intent) == Hook.Target.NONE and f.grapple.charges == available, "stale recorded occupied aim is refused before spending")
	# A shot launched earlier than the competing deployment must rewind after arrival.
	other.position = Vector3(0, 3, 0)
	var racing: int = registry.issue(2)
	other.grapple.token = racing
	other.grapple._selected_anchor = anchor
	other.grapple._flight_direction = Vector3.UP
	other.grapple.projectile_position = anchor.position + Vector3.DOWN * 0.2
	other.grapple.phase = Hook.Phase.FLIGHT
	other.grapple._flight_distance = 0.0
	other.grapple._flight(1.0 / 60.0, true)
	check(other.grapple.phase == Hook.Phase.MISS_REWIND and registry.records.has(racing) and not registry.records[racing].deployed, "in-flight race enters visible recoverable rewind")
	other.grapple.reset()
	other.position = registry.records.values()[0].tail - Hook.HAND
	var stock: int = other.grapple.charges
	other.grapple.fire(false)
	check(other.grapple.attached and other.grapple.charges == stock and registry.records.size() == 1, "foreign reuse retains stock and one shared rope")
	registry.clear_match()
	check(registry.records.is_empty() and not other.grapple.attached and not registry.occupied(anchor.position), "new match clears users, stock and occupancy")
	anchor.free()
	perch_anchor.free()
	f.free()
	other.free()
	city.free()
	registry.free()
	await process_frame
	# Release the audio servers' streaming decoders before the tree exits.
	for singleton: String in ["Sfx", "UltMusic"]:
		root.get_node(singleton).queue_free()
	var until := Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	var families: Array = red.keys()
	families.sort()
	# The positive sentinel stays one line; a negative's families get a line of their own (class 18).
	print("WEIGHTED_SWING_FAMILIES failures=%d mutation=%s red=%s" % [failures, mutation, ",".join(families) if not families.is_empty() else "none"])
	print("WEIGHTED_SWING_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)


func verify_pendulum(responsive: bool) -> void:
	for length: float in [2.2, 8.0]:
		hang(length, responsive)
		f.velocity = Vector3(3.0, 0, 0)
		var previous_energy: float = energy()
		var passive_ok: bool = true
		for frame: int in 240:
			f.grapple.drive(1.0 / 60.0, true)
			var measured: float = energy()
			passive_ok = passive_ok and measured <= previous_energy + 0.03
			previous_energy = measured
		check(passive_ok, "unpowered short/long pendulum dissipates energy %.1f" % length)
		hang(length, responsive)
		var below_anchor: bool = true
		var bounded: bool = true
		var constrained: bool = true
		for frame: int in 600:
			f._wish = Vector3.RIGHT if f.velocity.x >= 0 else Vector3.LEFT
			f.grapple.drive(1.0 / 60.0, true, true)
			below_anchor = below_anchor and f.position.y + Hook.HAND.y < anchor.position.y
			bounded = bounded and f.velocity.length() <= 11.001
			constrained = constrained and (f.position + Hook.HAND).distance_to(anchor.position) <= f.grapple.rope_length + 0.03
		check(below_anchor and bounded and constrained, "sustained pumping plus Space cannot orbit/run away %.1f" % length)
		var speed: float = f.velocity.length()
		f.grapple.drive(1.0 / 60.0, false)
		check(f.velocity.length() <= speed + 0.001, "release cannot manufacture speed %.1f" % length)


## T5 § 8 Л-а…Л-в on the city body, through GrappleHook.drive with climb_input as CityFighter writes it.
func verify_city_climb() -> void:
	hang_city(6.0)
	perch_anchor.set_meta("perch", {"mount": perch_anchor.position + Vector3(1.0, -6.5, 0.0), "kind": "post"})
	var hook: Node = city.grapple
	check(hook.attached and hook.climb_enabled and hook.phase == Hook.Phase.HANG, "the city body hangs with the climb enabled", "count")
	# Л-в, second half: without Space nothing shortens the rope (no floor under this anchor: no pull either).
	var still: float = hook.rope_length
	for tick: int in 120:
		hook.climb_input = 0
		hook.drive(1.0 / 60.0, true)
	check(absf(hook.rope_length - still) <= 0.000001, "without Space the rope keeps its length (%.6f → %.6f)" % [still, hook.rope_length], "noreq")
	hang_city(6.0)
	var previous: float = hook.rope_length
	var rate_ok := true
	var floor_ok := true
	var reached := -1
	var ticks := 0
	while hook.phase == Hook.Phase.HANG and ticks < 240:
		hook.climb_input = 1
		hook.drive(1.0 / 60.0, true)
		ticks += 1
		var shorten: float = previous - hook.rope_length
		rate_ok = rate_ok and shorten <= CLIMB_SPEED / 60.0 + 0.000001 and shorten >= -0.000001
		floor_ok = floor_ok and hook.rope_length >= MIN_ROPE - 0.000001
		if reached < 0 and hook.rope_length <= MIN_ROPE + 0.000001:
			reached = ticks
		previous = hook.rope_length
	check(rate_ok, "Л-а: the climb shortens by at most %.4f m a tick" % (CLIMB_SPEED / 60.0), "climb_rate")
	check(floor_ok and reached > 0, "Л-а: the climb stops at %.1f m (reached on tick %d, L %.6f)" % [MIN_ROPE, reached, hook.rope_length], "climb_rate")
	var pull_up := 0
	while hook.phase == Hook.Phase.CLIMB_TOP and pull_up < 120:
		hook.climb_input = 1
		hook.drive(1.0 / 60.0, true)
		pull_up += 1
	var point: Vector3 = perch_anchor.position
	var pose: Dictionary = hook.perch_pose
	check(hook.phase == Hook.Phase.PERCH and pull_up == PULL_UP_TICKS, "Л-б: exactly %d ticks of pull-up, then the grip (got %d, phase %d)" % [PULL_UP_TICKS, pull_up, hook.phase], "perch")
	check(not pose.is_empty() and absf(Vector3(pose.get("grip", Vector3.INF)).y - (point.y + GRIP_RISE)) <= 0.01, "Л-б: the grip on the arm at y_anchor + %.2f (%s)" % [GRIP_RISE, pose.get("grip", "-")], "perch")
	check(absf(city.position.y - (point.y - FEET_BELOW)) <= 0.01, "Л-б: the feet at y_anchor − %.2f (%.4f)" % [FEET_BELOW, city.position.y - point.y], "perch")
	check(city.velocity.length() <= 0.001, "Л-б: the grip holds still (|v| %.4f)" % city.velocity.length(), "perch")
	var feet: float = city.position.y
	var held := true
	for tick: int in 179:
		hook.climb_input = 1
		hook.drive(1.0 / 60.0, true)
		if hook.phase != Hook.Phase.PERCH:
			break
		held = held and absf(city.position.y - feet) <= 0.001
	check(held, "Л-в: Space on the grip lifts nothing (feet %.4f → %.4f)" % [feet, city.position.y], "noreq")
	perch_anchor.remove_meta("perch")
	hook.detach()


## T5 § 8 Е-1…Е-6 on the city body.
func verify_city_energy() -> void:
	var hook: Node = city.grapple
	for length: float in [2.2, 8.0]:
		# Е-1: no stick, no Space, no pull.
		hang_city(length)
		city.velocity = Vector3(3.0, 0, 0)
		var before: float = world_energy(city)
		var passive := true
		for tick: int in 240:
			hook.climb_input = 0
			city._wish = Vector3.ZERO
			hook.drive(1.0 / 60.0, true)
			var now: float = world_energy(city)
			passive = passive and now <= before + 0.03
			before = now
		check(passive, "Е-1: the unpowered city pendulum %.1f never gains over 0.03 a tick" % length, "e1")
		# Е-2: the stick against the motion.
		hang_city(length)
		city.velocity = Vector3(3.0, 0, 0)
		before = world_energy(city)
		var against := true
		for tick: int in 240:
			hook.climb_input = 0
			city._wish = -Vector3(city.velocity.x, 0.0, city.velocity.z).normalized()
			hook.drive(1.0 / 60.0, true)
			var now: float = world_energy(city)
			against = against and now <= before + 0.03
			before = now
		check(against, "Е-2: the stick against the motion never pumps %.1f" % length, "e2")
		# Е-3: the stick with the motion for 10 s.
		hang_city(length)
		city.velocity = Vector3(1.0, 0, 0)
		var bounded := true
		for tick: int in 600:
			hook.climb_input = 0
			city._wish = Vector3(city.velocity.x, 0.0, city.velocity.z).normalized()
			hook.drive(1.0 / 60.0, true)
			var hand: Vector3 = city.position + Hook.HAND
			var down: float = perch_anchor.position.y - hand.y
			var limit: float = minf(11.0, 0.85 * sqrt(Actor.GRAVITY * hook.rope_length))
			var angle: float = rad_to_deg(acos(clampf(down / maxf(hand.distance_to(perch_anchor.position), 0.001), -1.0, 1.0)))
			bounded = bounded and angle <= 75.0 and down >= 0.25 * hook.rope_length and city.velocity.length() <= limit + 0.001
		check(bounded, "Е-3: pumping with the motion stays under 75°, a quarter of L below the anchor and the speed cap %.1f" % length, "e2")
	# Е-4: a climb step adds no tangential speed. Gravity alone changes it by up to g·dt a tick, so each tick runs twice
	# from the same state — once without the climb, once with it — and the climb's tick may be at most 0.03 faster.
	hang_city(6.0)
	city.velocity = Vector3(3.0, 0, 0)
	var climb_ok := true
	var worst := -INF
	for tick: int in 60:
		var saved := {"position": city.position, "velocity": city.velocity, "length": hook.rope_length, "start": hook._hang_start_length, "frames": hook._frames}
		hook.climb_input = 0
		city._wish = Vector3.ZERO
		hook.drive(1.0 / 60.0, true)
		var passive: float = city.velocity.slide((perch_anchor.position - (city.position + Hook.HAND)).normalized()).length()
		city.position = saved.position
		city.velocity = saved.velocity
		hook.rope_length = saved.length
		hook._hang_start_length = saved.start
		hook._frames = saved.frames
		hook.climb_input = 1
		hook.drive(1.0 / 60.0, true)
		if hook.phase != Hook.Phase.HANG:
			break
		var climbed: float = city.velocity.slide((perch_anchor.position - (city.position + Hook.HAND)).normalized()).length()
		worst = maxf(worst, climbed - passive)
		climb_ok = climb_ok and climbed <= passive + 0.03
	check(climb_ok, "Е-4: Space never pumps the swing (the climb's tick at most %.4f faster than the same tick without it)" % worst, "e4")
	# Е-5: the slide adds no energy (the rope deployed 10 m long, the slide from 4 m).
	hang_city(4.0)
	registry.records[city.grapple._deployed_token].length = 10.0
	city.velocity = Vector3(2.0, 0, 0)
	var slide_before: float = world_energy(city)
	var slide_ok := true
	for tick: int in 120:
		hook.climb_input = -1
		city._wish = Vector3.ZERO
		hook.drive(1.0 / 60.0, true)
		var now: float = world_energy(city)
		slide_ok = slide_ok and now <= slide_before + 0.03
		slide_before = now
	check(slide_ok, "Е-5: the slide never adds energy", "e5")
	# Е-6: let go keeps the velocity.
	hang_city(6.0)
	city.velocity = Vector3(4.0, 0, 1.0)
	for tick: int in 30:
		hook.climb_input = 0
		hook.drive(1.0 / 60.0, true)
	var v_before: Vector3 = city.velocity
	hook.let_go()
	check(not hook.attached and absf(city.velocity.length() - v_before.length()) <= 0.001, "Е-6: let go keeps the speed (%.4f → %.4f)" % [v_before.length(), city.velocity.length()], "e6")
