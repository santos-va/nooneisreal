extends SceneTree
## Plan docs/Plans/2026-10-09-Rope-Pull-Jump-Arc-Substance-Momentum.md step 1 (rope V4); numbers T5
## docs/GDD/2026-10-09-Rope-Pull-And-Jump-Arc-Numbers.md Т1–Т8; contract docs/GDD/04-Grapple-System.md.
## Subject: for every city parkour HANG in the production CityWorld — real keyboard E, W and Space, both heroes, from a
## standing start and along the P11 route — the rope pulls itself in to
##   L_target = min(L0, max(2.0, y_anchor − y_floor − 1.25 − 0.5)),  y_floor = the higher support under the anchor and
##   under the hero at contact,
## never lets out, shortens by at most max(8, 3.6) m/s per tick (never the sum), Space reels at most 1.2 m beyond
## L_target; the body never moves more than (11 + 8) / 60 m in a tick; and the body stays off the floor for at least
## half a pendulum period π·√(L_target / g) unless solid geometry cuts the rope (checked here by its own ray).
## «In the air» (plan 2026-10-14-Quality-Debt-Posts-Awning-Guards step 3, the T4 audit's variant c as a guard): a tick
## counts only off the floor and without a side collision — a slide collision whose normal is steeper than the body's
## floor_max_angle (a counter, a post, a wall the swing leans on is not air).
## Every threshold is T5's literal, computed here from the world's geometry, never read from the product.
## Own support (T1, plan «Рішення T1 після кроків 1–4»): for every such hang, the lamp post the anchor stands on never
## ends it, and any other solid on hand → anchor (cornice, awning, cover) still does — within a tick. The post is found
## here from CityLayout.anchor_supports() (a `post` body centred on its `mount`), never from the product's meta.
##   --hero=choko|skea (default both)
##   --break=nopull|snap|lengthen|sum — negative controls: no pull (HEAD's contract), the rope set to its target in one
##     tick (V3), the rope let out once per hang, the pull and Space summed in one tick; each must go red in its family.
##   --break=own|wrong|wide — the anchors' "support" meta removed (the post back in the hang's check), pointing at the
##     next lamp's post, or widened to every solid within 6 m of the anchor; red in `own`, `own`, `cover`.
## R3, a foreign post (T4 audit 2026-10-09 proposal 1, plan 2026-10-14 step 3): a real hang on bracket anchor 22
## (−12, 9.3, −24.6), 1.17 m from the post of lamp 14 (mount (−11, 4, −24)); once the pull has settled the hand is put
## (position only) where hand → anchor crosses lamp 14's post: the rope is released within FOREIGN_TICKS tick, by that
## post (this check's ray). Control: the hand at the mirror image across the anchor's x, a clear line: the rope holds.
##   --break=all_posts — R3: every anchor's "support" meta names every lamp post (the hang skips all of them); red in
##     `foreign`.
## Help (T1 after steps 1–4): the pause help and COMFORT & CONTROLS, as shown, say that the city hook pulls the hero up
## by itself and that Space reels at most 1.2 m (Т5) further, and neither keeps the old «Get closer beneath an anchor
## for lift» promise.
##   --break=help_nopull|help_reel|help_lift — the pull left out of the pause help, «2 m» for 1.2 m in COMFORT, the old
##     promise back in COMFORT; each red in `help` (the route is skipped for these).
## OPEN_AIR: anchor 5 (8.6, 6.7, 24.6) — its swing leans on the east z 25 stall (counter and goods, 0.225 m off the
## vertical the one-ray support falls past) for most of the hang. The plan's fix (variant a, the support from a 0.75 m
## cylinder) was measured and returned to T1 (docs/Fix/2026-10-14-Lamp-Posts-Awning-Anchor-5-Fix.md § 3): its `air`
## failure is printed «ROPE_PULL OPEN air …» and not counted; on the product it must still happen (family `open`), so a
## change there has to be looked at.
##   --break=counter|wall — the guard's own negatives, each red in `air`: a 1.1 m counter whose edge is 0.225 m off
##     anchor 0's vertical (anchor 5's stall, at another anchor), or a wall whose face is 0.2 m off it — both beyond the
##     vertical as the P11 route swings in, so the hanging body comes to rest leaning on them; `is_on_floor()` alone
##     counts both as air.
## Sentinel: ROPE_PULL_COMPLETE checks=N failures=M mutation=<m> red=<failed families|none>, after a line
## «ROPE_PULL open=<open items|none>»; failures print "ROPE_PULL: ...".
const PULL_SPEED: float = 8.0      # Т1
const CLEARANCE: float = 0.5       # Т2
const HAND_Y: float = 1.25         # Т3, GrappleHook.HAND
const MIN_ROPE: float = 2.0        # Т6
const REEL: float = 1.2            # Т5
const REEL_SPEED: float = 3.6      # parkour_reel_speed, 04-Grapple-System
const STEP_LIMIT: float = (11.0 + 8.0) / 60.0  # Т8
const GRAVITY: float = 24.0        # Fighter.GRAVITY (T5 § 1.2)
const TICK: float = 1.0 / 60.0
const SAFE_POINT := Vector3(0, 0, 9.5)
const SOUTH_ANCHORS: Array[Vector3] = [Vector3(8, 6.5, 8), Vector3(-8, 6.5, 8)]
const HANG := 3
const COVER_LAYER := 8             # ArenaLayout.COVER_LAYER: the product's line_clear mask is COVER_LAYER | 1
const WIDE_REACH: float = 6.0      # --break=wide: the support list grows to every solid this close to the anchor
const FOREIGN_ANCHOR: int = 22     # T4 audit 2026-10-09 § П. 1 «Чужий стовп рве», proposal 1
const FOREIGN_POST: int = 14
const FOREIGN_TICKS: int = 1       # proposal 1: «обрив за ≤ 1 тик»
const FOREIGN_HOLD: int = 3        # the control holds at least this long (the cut window and two more)
## Terrace starts tried in order until the camera's selection marks anchor 22 (T4 probes/foreign_post.gd).
## OPEN `air` items (see the header): anchor index → why.
const OPEN_AIR: Dictionary = {5: "the swing leans on the east z 25 stall; variant a returned to T1"}
## The air negatives sit at anchor 0, which the P11 route sample (−16.5, 0, 0) hooks (rope_pull.log).
const AIR_NEGATIVE_ANCHOR: int = 0
const AIR_NEGATIVE_FROM := Vector3(-16.5, 0, 0)
const FOREIGN_STARTS: Array[Vector3] = [Vector3(-13.0, 4.0, -22.0), Vector3(-14.0, 4.0, -23.0), Vector3(-12.0, 4.0, -21.5),
	Vector3(-15.0, 4.0, -24.0), Vector3(-13.5, 4.0, -21.0), Vector3(-12.5, 4.0, -22.5)]
var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var only_hero: String = ""
var red: Dictionary = {}
var router: Node
var supports: Array[Dictionary] = []
var open_seen: Dictionary = {}


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
		elif argument.begins_with("--hero="):
			only_hero = argument.trim_prefix("--hero=")
	_run.call_deferred()


func _check(ok: bool, family: String, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		red[family] = true
		push_error("ROPE_PULL: [%s] %s" % [family, label])


func _ticks(count: int) -> void:
	for tick: int in count:
		await physics_frame
		await process_frame


func _key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _run() -> void:
	await process_frame
	router = root.get_node("InputRouter")
	supports = load("res://scripts/world/CityLayout.gd").anchor_supports()
	var state: Node = root.get_node("GameState")
	state.set_free_move(true)
	state.water = null
	for hero: String in ["choko", "skea"]:
		if only_hero.is_empty() or only_hero == hero:
			await _district(hero)
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		var node := root.get_node_or_null(singleton)
		if node != null:
			node.queue_free()
	var deadline: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < deadline:
		await process_frame
		OS.delay_msec(1)
	if mutation == "none":
		for index: int in OPEN_AIR:
			_check(open_seen.has(index), "open", "the OPEN air item on anchor %d (%s) no longer fails: look at it and unpin it" % [index, OPEN_AIR[index]])
	var families: Array = red.keys()
	families.sort()
	var opened: PackedStringArray = []
	for index: int in OPEN_AIR:
		if open_seen.has(index):
			opened.append("air:%d" % index)
	print("ROPE_PULL frames=%d (the playable harness quits after 12000)" % Engine.get_process_frames())
	# The battery matches the sentinel as a whole line, so the OPEN items get a line of their own.
	print("ROPE_PULL open=%s" % (",".join(opened) if not opened.is_empty() else "none"))
	print("ROPE_PULL_COMPLETE checks=%d failures=%d mutation=%s red=%s" % [checks, failures, mutation, ",".join(families) if not families.is_empty() else "none"])
	quit(1 if failures else 0)


func _district(hero: String) -> void:
	var state: Node = root.get_node("GameState")
	state.p1_character = hero
	router.apply_profile("solo", false)
	var world: Node = load("res://scenes/world/CityWorld.tscn").instantiate()
	world.story_save_enabled = false
	world.journey_save_enabled = false
	world.lower_story_save_enabled = false
	root.add_child(world)
	current_scene = world
	world.progress.save_enabled = false
	world.npc_director.save_enabled = false
	world.npc_director.process_mode = Node.PROCESS_MODE_DISABLED
	await _ticks(40)
	world.onboarding.skip()
	await _help(world, hero)
	if mutation.begins_with("help_"):
		world.queue_free()
		current_scene = null
		await _ticks(3)
		return
	var hook: Node = world.player.grapple
	if mutation == "nopull":
		hook.set("parkour_pull_speed", 0.0)
	elif mutation == "snap":
		hook.set("parkour_pull_speed", 1.0e6)
	elif mutation in ["own", "wrong", "wide", "all_posts"]:
		_break_support(world)
	elif mutation in ["counter", "wall"]:
		_air_obstacle(world)
	# A standing start under both south lamps (still, and Space held from the hang), then the first lamp with W held.
	var standing: Array[Dictionary] = []
	for index: int in SOUTH_ANCHORS.size():
		standing.append(await _standing(world, hero, SOUTH_ANCHORS[index], false, false))
	standing.append(await _standing(world, hero, SOUTH_ANCHORS[1], true, false))
	standing.append(await _standing(world, hero, SOUTH_ANCHORS[0], false, true))
	for result: Dictionary in standing:
		_check(not result.is_empty(), "count", "[%s] a standing press under a south lamp hung" % hero)
	# P11 route: run in with W, tap E, let go of W once the hook holds.
	var hangs := 0
	var evaluated := 0
	var cuts := 0
	var held_through_own := 0
	var own_cuts := 0
	for result: Dictionary in standing:
		if not result.is_empty():
			held_through_own += int(result.own_ticks)
			own_cuts += int(result.own_cut)
	var route: Array[Vector3] = load("res://scripts/world/CityLayout.gd").route_points()
	for leg: int in route.size() - 1:
		var from: Vector3 = route[leg]
		var to: Vector3 = route[leg + 1]
		var length := Vector2(to.x - from.x, to.z - from.z).length()
		if length < 1.0:
			continue
		var direction := Vector3(to.x - from.x, 0, to.z - from.z).normalized()
		var samples := maxi(1, floori(length / 8.0))
		for sample: int in samples:
			var at := from.lerp(to, (float(sample) + 0.5) / float(samples))
			await _reset(world, at, direction)
			_key(KEY_W, true)
			await _ticks(12)
			var result: Dictionary = await _press_and_observe(world, hero, "route %s" % at, false, true)
			_key(KEY_W, false)
			if result.is_empty():
				continue
			hangs += 1
			held_through_own += int(result.own_ticks)
			own_cuts += int(result.own_cut)
			if result.cut:
				cuts += 1
			else:
				evaluated += 1
	print("ROPE_PULL route %s hangs=%d evaluated=%d cut=%d" % [hero, hangs, evaluated, cuts])
	print("ROPE_PULL own %s cut_by_own_support=%d ticks_held_through_own_support=%d" % [hero, own_cuts, held_through_own])
	_check(own_cuts == 0, "own", "[%s] %d hangs ended on their anchor's own post" % [hero, own_cuts])
	# Not vacuous: some swing must carry the line behind its own post and keep the rope (the route's south lamps do).
	_check(held_through_own > 0, "own", "[%s] no hang held its rope with the line through its own post (%d ticks)" % [hero, held_through_own])
	_check(hangs >= 10 and evaluated * 2 >= hangs, "count", "[%s] route: %d hangs, %d evaluated to the end, %d cut by geometry (at least 10 hangs, at least half evaluated)" % [hero, hangs, evaluated, cuts])
	await _foreign_post(world, hero)
	world.queue_free()
	current_scene = null
	await _ticks(3)


## The help as the player reads it: the pause column's help label and the COMFORT & CONTROLS text opened from it.
func _help(world: Node, hero: String) -> void:
	var hud: Node = world.hud
	hud.set_paused(true)
	await _ticks(2)
	var pause: Label = null
	for node: Node in hud.pause_panel.find_children("*", "Label", true, false):
		if (node as Label).text.begins_with("Move:"):
			pause = node as Label
	_check(pause != null, "help", "[%s] the pause shows its help" % hero)
	if pause == null:
		hud.set_paused(false)
		return
	if mutation == "help_nopull":
		pause.text = pause.text.replace(" · it pulls you up to swing height", "")
	hud.comfort_button.pressed.emit()
	await _ticks(2)
	var full: Label = hud.comfort.controls_label
	if mutation == "help_reel":
		full.text = full.text.replace("%.1f m" % REEL, "2 m")
	elif mutation == "help_lift":
		full.text += "\nGet closer beneath an anchor for lift; distant ropes pull toward it."
	var reel := "%.1f m" % REEL
	_check("pulls you up" in pause.text and reel in pause.text, "help", "[%s] the pause help says the hook pulls you up and Space reels %s: %s" % [hero, reel, pause.text.get_slice("\n", 1) + " / " + pause.text.get_slice("\n", 2)])
	_check("In the city the parkour hook pulls you up" in full.text and ("up to " + reel) in full.text, "help", "[%s] COMFORT says the city hook pulls you up and Space reels up to %s" % [hero, reel])
	for old: String in ["Get closer beneath an anchor", "distant ropes pull toward it"]:
		_check(old not in pause.text and old not in full.text, "help", "[%s] no help keeps the old «%s»" % [hero, old])
	hud.comfort.close_panel()
	hud.set_paused(false)
	await _ticks(2)


func _reset(world: Node, at: Vector3, view: Vector3) -> void:
	var hero_node: Node3D = world.player
	_key(KEY_W, false)
	_key(KEY_SPACE, false)
	hero_node.grapple.detach()
	world.ropes.clear_match()
	await _ticks(1)
	hero_node.restart_at(at)
	hero_node._set_forward(Vector3(view.x, 0, view.z))
	var rig: Node3D = world.camera_rig
	rig.reset_view()
	rig.aim.yaw_offset = atan2(-view.x, -view.z)
	await _ticks(14)


func _standing(world: Node, hero: String, anchor: Vector3, space: bool, pump: bool) -> Dictionary:
	await _reset(world, SAFE_POINT, anchor - SAFE_POINT)
	var label := "standing %s%s%s" % [anchor, " + Space" if space else "", " + W" if pump else ""]
	var result: Dictionary = await _press_and_observe(world, hero, label, space, false, pump)
	if not result.is_empty():
		_check(Vector3(result.anchor).is_equal_approx(anchor), "count", "[%s] %s hooked the marked lamp (%s)" % [hero, label, result.anchor])
	return result


## Tap E; once the hook holds, observe the hang tick by tick. Returns {} when no hang, else the measured record.
func _press_and_observe(world: Node, hero: String, label: String, space: bool, release_w: bool, pump: bool = false) -> Dictionary:
	var hero_node: CharacterBody3D = world.player
	var hook: Node = hero_node.grapple
	_key(KEY_E, true)
	await _ticks(1)
	_key(KEY_E, false)
	var hung := false
	for tick: int in 50:
		await _ticks(1)
		if hook.phase == HANG and hook.attached:
			hung = true
			break
		if tick > 2 and hook.phase == 0:
			break
	if release_w:
		_key(KEY_W, false)
	if not hung:
		print("ROPE_PULL %s %s no_hang phase=%d" % [hero, label, hook.phase])
		return {}
	var tag := "[%s] %s: " % [hero, label]
	# The first tick in HANG: the contact tick returned from _flight, no hang drive has run yet.
	var anchor: Vector3 = hook.anchor_point
	var contact: float = hook.rope_length
	var hand: Vector3 = hero_node.global_position + Vector3(0, HAND_Y, 0)
	_check(contact <= hand.distance_to(anchor) + 0.001, "lengthen", tag + "the contact length %.3f is not longer than hand→anchor %.3f" % [contact, hand.distance_to(anchor)])
	var support := maxf(_support(hero_node, anchor + Vector3.DOWN * 0.05), _support(hero_node, hero_node.global_position + Vector3.UP * 0.05))
	var target := contact if is_inf(support) else minf(contact, maxf(MIN_ROPE, anchor.y - support - HAND_Y - CLEARANCE))
	var final := minf(target, maxf(MIN_ROPE, target - REEL)) if space else target
	var pull_ticks := ceili((contact - target) / (PULL_SPEED * TICK) - 0.0001)
	var reel_ticks := ceili((target - final) / (REEL_SPEED * TICK) - 0.0001)
	var half := ceili(60.0 * PI * sqrt(target / GRAVITY))
	var window := pull_ticks + reel_ticks + half + 30
	if space:
		_key(KEY_SPACE, true)
	if pump:
		_key(KEY_W, true)
	var previous_length := contact
	var previous_position: Vector3 = hero_node.global_position
	var reached_at := -1
	var final_at := -1
	var air := 0
	var max_step := 0.0
	var max_shorten := 0.0
	var cut := false
	var cut_by := ""
	var let_out := false
	var shortest := contact
	var ticks := 0
	var own_ticks := 0
	var own_cut := false
	var covered := 0
	var side_ticks := 0
	var leaned: Dictionary = {}
	var spec := _spec(anchor)
	for tick: int in window:
		await _ticks(1)
		ticks = tick + 1
		var line := _line(hero_node, hero_node.global_position + Vector3(0, HAND_Y, 0), anchor, spec)
		if hook.phase != HANG or not hook.attached:
			# The product released the rope: legitimate only when solid geometry other than the anchor's own post cuts
			# hand→anchor now.
			cut = not String(line.other).is_empty()
			cut_by = line.other
			own_cut = not cut and not String(line.own).is_empty()
			_check(not own_cut, "own", tag + "the hang ended on tick %d on its anchor's own post %s" % [ticks, line.own])
			_check(cut or own_cut, "cut", tag + "the hang ended on tick %d with a clear line to the anchor" % ticks)
			break
		if not String(line.own).is_empty():
			own_ticks += 1
		# Any other solid on the line cuts the rope: the product checks after its own move this tick, so a second
		# hanging tick with a blocked line is a rope held through cover.
		covered = covered + 1 if not String(line.other).is_empty() else 0
		_check(covered < 2, "cover", tag + "tick %d the rope still hangs through %s" % [ticks, line.other])
		var now: float = hook.rope_length
		if mutation == "lengthen" and reached_at >= 0 and not let_out:
			hook.rope_length += 0.3 # Injected: a rope let out once per hang.
			now = hook.rope_length
			let_out = true
		if mutation == "sum" and space and hook.get("pulling"):
			hook.rope_length -= minf(REEL_SPEED * TICK, maxf(0.0, hook.rope_length - final)) # Injected: Space added on top of the pull.
			now = hook.rope_length
		var shorten := previous_length - now
		max_shorten = maxf(max_shorten, shorten)
		_check(shorten >= -0.000001, "lengthen", tag + "tick %d the rope let out %.4f m (%.4f → %.4f)" % [ticks, -shorten, previous_length, now])
		var limit := PULL_SPEED * TICK if previous_length > target + 0.0001 else REEL_SPEED * TICK
		_check(shorten <= limit + 0.00001, "rate", tag + "tick %d the rope shortened %.4f m, over max(pull, Space) %.4f" % [ticks, shorten, limit])
		_check(now >= final - 0.0001, "target", tag + "tick %d the rope %.4f is shorter than its end %.4f" % [ticks, now, final])
		var step: float = hero_node.global_position.distance_to(previous_position)
		max_step = maxf(max_step, step)
		_check(step <= STEP_LIMIT + 0.0001, "step", tag + "tick %d the body moved %.4f m, over %.4f" % [ticks, step, STEP_LIMIT])
		var side := _side_contact(hero_node)
		if not side.is_empty():
			side_ticks += 1
			leaned[side] = int(leaned.get(side, 0)) + 1
		if not hero_node.is_on_floor() and side.is_empty():
			air += 1
		if reached_at < 0 and now <= target + 0.0001:
			reached_at = ticks
		if final_at < 0 and now <= final + 0.0001:
			final_at = ticks
		shortest = minf(shortest, now)
		previous_length = now
		previous_position = hero_node.global_position
		if reached_at >= 0 and final_at >= 0 and air >= half and ticks >= pull_ticks + reel_ticks + 2:
			break
	_key(KEY_SPACE, false)
	_key(KEY_W, false)
	if not cut:
		_check(reached_at >= 0 and reached_at <= pull_ticks + 1, "target", tag + "the rope reached the swing length %.3f (from %.3f) on tick %d, expected by %d" % [target, contact, reached_at, pull_ticks + 1])
		_check(final_at >= 0 and absf(shortest - final) < 0.002, "target", tag + "the rope settled at %.3f, expected %.3f" % [shortest, final])
		var index := supports.find(spec)
		if air < half and OPEN_AIR.has(index):
			open_seen[index] = true
			print("ROPE_PULL OPEN air %s in the air %d ticks, half a period %d; side collisions on %d ticks %s (%s)" % [tag, air, half, side_ticks, str(leaned), OPEN_AIR[index]])
		else:
			_check(air >= half, "air", tag + "in the air (off the floor, no side collision) %d ticks on the rope, at least half a period %d; side collisions on %d ticks %s" % [air, half, side_ticks, str(leaned)])
	print("ROPE_PULL %s %s anchor=%s contact=%.3f target=%.3f final=%.3f reached=%d/%d air=%d/%d side=%d %s max_step=%.3f max_shorten=%.4f ticks=%d own_ticks=%d cut=%s %s" % [hero, label, anchor, contact, target, final, reached_at, pull_ticks, air, half, side_ticks, str(leaned) if not leaned.is_empty() else "{}", max_step, max_shorten, ticks, own_ticks, cut, cut_by])
	return {"anchor": anchor, "cut": cut or own_cut, "air": air, "half": half, "target": target, "contact": contact, "own_ticks": own_ticks, "own_cut": own_cut}


## The first collider of this tick's slides whose normal is steeper than the body's floor (the engine's own
## floor_max_angle), as a name ("" when none): the body leans on it from the side.
func _side_contact(hero_node: CharacterBody3D) -> String:
	for index: int in hero_node.get_slide_collision_count():
		var collision := hero_node.get_slide_collision(index)
		if collision.get_normal().angle_to(Vector3.UP) > hero_node.floor_max_angle + 0.001:
			var node := collision.get_collider() as Node
			return String(node.name) if node != null else "?"
	return ""


## R3 (see the header): a real hang on FOREIGN_ANCHOR, then the hand put on the line through FOREIGN_POST's post, and on
## its mirror image as the control.
func _foreign_post(world: Node, hero: String) -> void:
	var anchor_spec: Dictionary = supports[FOREIGN_ANCHOR]
	var post_spec: Dictionary = supports[FOREIGN_POST]
	var anchor: Vector3 = anchor_spec.point
	var mount: Vector3 = post_spec.mount
	# The audit's numbers, checked against the layout: a bracket anchor 1.17 m (±1 cm) off a lamp post's axis.
	var axis_gap := Vector2(anchor.x - mount.x, anchor.z - mount.z).length()
	_check(String(anchor_spec.kind) == "bracket" and String(post_spec.kind) == "post" and absf(axis_gap - 1.17) <= 0.01, "foreign", "[%s] anchor %d is a bracket 1.17 m off lamp %d's post axis (%s, %s, %.3f m)" % [hero, FOREIGN_ANCHOR, FOREIGN_POST, anchor_spec.kind, post_spec.kind, axis_gap])
	var post_point := Vector3(mount.x, Vector3(post_spec.point).y, mount.z)
	var through := anchor + (post_point - anchor) * 1.5
	var clear := Vector3(anchor.x - (through.x - anchor.x), through.y, through.z)
	for trial: String in ["through", "clear"]:
		var hand_at := through if trial == "through" else clear
		var hung: Dictionary = await _hang_on(world, anchor)
		if hung.is_empty():
			_check(false, "foreign", "[%s] R3 %s: no start on the terrace hooks anchor %d" % [hero, trial, FOREIGN_ANCHOR])
			return
		var hero_node: CharacterBody3D = world.player
		var hook: Node = hero_node.grapple
		hero_node.global_position = hand_at - Vector3(0, HAND_Y, 0)
		hero_node.velocity = Vector3.ZERO
		var line := _line(hero_node, hand_at, anchor, anchor_spec)
		var released_at := -1
		var cut_line := {}
		for tick: int in FOREIGN_HOLD:
			await _ticks(1)
			if hook.phase != HANG or not hook.attached:
				released_at = tick + 1
				cut_line = _line(hero_node, hero_node.global_position + Vector3(0, HAND_Y, 0), anchor, anchor_spec)
				break
		var tag := "[%s] R3 %s (start %s, rope %.3f, hand %s, line %s): " % [hero, trial, hung.start, hung.rope, hand_at, line.other if not String(line.other).is_empty() else "clear"]
		if trial == "through":
			var by_post: bool = String(line.other).begins_with("AnchorPost%d@" % FOREIGN_POST)
			_check(by_post, "foreign", tag + "the hand's line crosses lamp %d's post" % FOREIGN_POST)
			_check(released_at >= 1 and released_at <= FOREIGN_TICKS, "foreign", tag + "a foreign post on the line released the rope on tick %d, within %d" % [released_at, FOREIGN_TICKS])
			_check(released_at < 0 or String(cut_line.get("other", "")).begins_with("AnchorPost%d@" % FOREIGN_POST), "foreign", tag + "released by lamp %d's post (%s)" % [FOREIGN_POST, cut_line.get("other", "")])
		else:
			_check(String(line.other).is_empty(), "foreign", tag + "the control's line is clear")
			_check(released_at < 0, "foreign", tag + "a clear line keeps the rope for %d ticks (released on tick %d)" % [FOREIGN_HOLD, released_at])
		print("ROPE_PULL foreign %s %s start=%s rope=%.3f hand=%s line=%s released_at=%d by=%s" % [hero, trial, hung.start, hung.rope, hand_at, line.other if not String(line.other).is_empty() else "clear", released_at, cut_line.get("other", "-")])


## `counter` / `wall` (the air negatives): one solid box at anchor 0 on layer 1 | 8, beyond the vertical as seen from
## AIR_NEGATIVE_FROM. The counter is the stall's (1.1 m high, 0.85 m deep, 3.2 m wide), its near edge 0.225 m from the
## vertical (anchor 5's counter: 0.225 m); the wall is 0.1 m thick, 4 m high and 8 m long, its face 0.2 m from it.
func _air_obstacle(world: Node) -> void:
	var anchor: Vector3 = supports[AIR_NEGATIVE_ANCHOR].point
	var toward := Vector3(AIR_NEGATIVE_FROM.x - anchor.x, 0, AIR_NEGATIVE_FROM.z - anchor.z).normalized()
	var side := Vector3(-toward.z, 0, toward.x)
	var body := StaticBody3D.new()
	body.collision_layer = 1 | 8
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var centre := Vector3(anchor.x, 0, anchor.z)
	if mutation == "counter":
		box.size = Vector3(3.2, 1.1, 0.85)
		centre -= toward * (0.225 + 0.425)
		centre.y = 0.55
	else:
		box.size = Vector3(8.0, 4.0, 0.1)
		centre -= toward * (0.2 + 0.05)
		centre.y = 2.0
	shape.shape = box
	body.add_child(shape)
	world.add_child(body)
	# Local x across the swing (the counter's width, the wall's length), local z along it (the depth).
	body.global_transform = Transform3D(Basis(side, Vector3.UP, side.cross(Vector3.UP)), centre)
	print("ROPE_PULL break=%s at anchor %d %s, centre %s" % [mutation, AIR_NEGATIVE_ANCHOR, anchor, centre])


## A real E press from the first FOREIGN_STARTS position whose camera selection marks `anchor`; the pull left to settle.
## Returns {start, rope} or {} when no start hangs on it.
func _hang_on(world: Node, anchor: Vector3) -> Dictionary:
	var hero_node: CharacterBody3D = world.player
	var hook: Node = hero_node.grapple
	var wanted := "StreetAnchor%d" % FOREIGN_ANCHOR
	for start: Vector3 in FOREIGN_STARTS:
		await _reset(world, start, anchor - start)
		if not String(world.camera_rig.aim.published.get("target_id", "")).ends_with(wanted):
			continue
		_key(KEY_E, true)
		await _ticks(1)
		_key(KEY_E, false)
		var hung := false
		for tick: int in 50:
			await _ticks(1)
			if hook.phase == HANG and hook.attached:
				hung = true
				break
		if not hung or not Vector3(hook.anchor_point).is_equal_approx(anchor):
			continue
		for tick: int in 60:
			await _ticks(1)
			if hook.phase != HANG or not hook.attached or not hook.get("pulling"):
				break
		if hook.phase == HANG and hook.attached:
			return {"start": start, "rope": float(hook.rope_length)}
	return {}


## Height of the first solid surface straight below `from` on the body layer, -INF if none within 64 m.
func _support(hero_node: CharacterBody3D, from: Vector3) -> float:
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 64.0, 1)
	query.exclude = [hero_node.get_rid()]
	var hit := hero_node.get_world_3d().direct_space_state.intersect_ray(query)
	return -INF if hit.is_empty() else float(hit.position.y)


## What solid geometry lies on hand→anchor, by the product's own rope rule (body layer and cover): `own` names the
## anchor's own post if the line crosses it, `other` the first other solid ("" when none).
func _line(hero_node: CharacterBody3D, from: Vector3, to: Vector3, spec: Dictionary) -> Dictionary:
	var result := {"own": "", "other": ""}
	var exclude: Array[RID] = [hero_node.get_rid()]
	for attempt: int in 4:
		var query := PhysicsRayQueryParameters3D.create(from, to, COVER_LAYER | 1)
		query.hit_from_inside = true
		query.exclude = exclude
		var hit := hero_node.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			break
		var node := hit.collider as Node3D
		var where := "%s@(%.2f,%.2f,%.2f)" % [node.name if node != null else "?", hit.position.x, hit.position.y, hit.position.z]
		if node != null and _is_own_post(node, spec):
			result.own = where
			exclude.append(hit.rid)
			continue
		result.other = where
		break
	return result


## The CityLayout.anchor_supports() entry of the anchor at `point` ({} if none).
func _spec(point: Vector3) -> Dictionary:
	for spec: Dictionary in supports:
		if Vector3(spec.point).distance_to(point) < 0.01:
			return spec
	return {}


## A `post` anchor stands on one body centred on its mount, rising from the mount to over the anchor.
func _is_own_post(node: Node3D, spec: Dictionary) -> bool:
	if spec.is_empty() or String(spec.kind) != "post" or not node is StaticBody3D:
		return false
	var mount: Vector3 = spec.mount
	var at := node.global_position
	return Vector2(at.x - mount.x, at.z - mount.z).length() < 0.05 and at.y > mount.y and at.y < Vector3(spec.point).y + 0.3


## Negative controls on the anchors' "support" meta (the product's input): `own` removes it, `wrong` hands every lamp
## the next lamp's post, `wide` adds every solid within WIDE_REACH of the anchor, `all_posts` (R3) hands every anchor
## every lamp post.
func _break_support(world: Node) -> void:
	var markers: Array[Node3D] = []
	for node: Node in get_nodes_in_group("grapple_anchor"):
		if world.is_ancestor_of(node):
			markers.append(node as Node3D)
	var posts: Array[Node3D] = []
	for marker: Node3D in markers:
		if not (marker.get_meta("support", []) as Array).is_empty():
			posts.append(marker)
	var solids: Array[Node] = world.find_children("*", "StaticBody3D", true, false)
	var originals: Array = []
	for marker: Node3D in posts:
		originals.append(marker.get_meta("support"))
	var every_post: Array[Node] = []
	for support: Array in originals:
		every_post.append_array(support)
	for marker: Node3D in markers:
		match mutation:
			"own":
				marker.remove_meta("support")
			"all_posts":
				# R3 (T4 audit 2026-10-09): every anchor skips every lamp post, its own and the foreign ones.
				marker.set_meta("support", every_post.duplicate())
			"wrong":
				var at := posts.find(marker)
				if at >= 0:
					marker.set_meta("support", originals[(at + 1) % posts.size()])
			"wide":
				var wide: Array[Node] = []
				wide.append_array(marker.get_meta("support", []))
				for node: Node in solids:
					var body := node as StaticBody3D
					for child: Node in body.get_children():
						var shape := child as CollisionShape3D
						if shape != null and shape.shape != null:
							var box: AABB = shape.global_transform * shape.shape.get_debug_mesh().get_aabb()
							var nearest := Vector3(clampf(marker.global_position.x, box.position.x, box.end.x), clampf(marker.global_position.y, box.position.y, box.end.y), clampf(marker.global_position.z, box.position.z, box.end.z))
							if nearest.distance_to(marker.global_position) < WIDE_REACH and not wide.has(body):
								wide.append(body)
				marker.set_meta("support", wide)
	print("ROPE_PULL break=%s anchors=%d posts=%d" % [mutation, markers.size(), posts.size()])
