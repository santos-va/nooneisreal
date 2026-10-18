extends SceneTree
## Plan docs/Plans/2026-10-14-Quality-Debt-Posts-Awning-Guards.md step 2 (T2-A): the consistency guard «chosen — not cut».
## Subject: for every rope anchor A and every sampled position P from which the product's traversal selection picks A
## (the camera's HarpoonAim packet, GrappleHook._assist_ready at the press and at the launch), a real keyboard E press
## shoots at A, makes contact (HANG on A, never a rewind), and the hang is not ended on its first hanging tick by solid
## geometry on hand → anchor (the hang's GrappleHook.line_clear; the anchor's own lamp post excepted).
## The cut is attributed by this check's own ray on the product's rope rule (body layer and cover), the own post found
## from CityLayout.anchor_supports() (a `post` body centred on its `mount`), never from the product's meta.
## Positions, in the production CityWorld (residents still, events off):
##   route — the P11 route of rope_pull_check / auto_hook_check: W along the leg for 12 ticks, then E (part 1 only);
##   ring  — around every anchor, RINGS m × BEARINGS bearings, on every standing floor of that column (a 0.6 m patch
##           with 1.8 m of headroom) whose hand is within the hook's range of the anchor, 1.5 m under it, on a clear
##           line: pressed standing (facing the anchor, the camera on it) and on the run (W for 12 ticks along the
##           tangent, alternately left and right).
## Whatever anchor the product picks from a position is the one evaluated; every anchor of the part must be picked.
## «On the first tick» is the plan's literal («обрив на першому тику біля цього якоря → 0»; «без обриву на першому тику
## після контакту»). A cut later in the swing is the cover rule (04-Grapple-System § Трос V4), not this guard's.
## OPEN (KNOWN_CUTS): the class is wider than the grocer's awning — 11 presses (Choko 4, Skea 7; 10 first-tick cuts and
## one rewind past range) whose contact the selection does not foresee, found by this guard on 2026-10-14 and left to
## Santos with his M3 feedback (the plan's variant Т2, a selection that also checks the line from the hand at contact,
## is deferred; selection code is not changed). Each is printed as «ROPE_CHOICE OPEN …» and is not a failure, under a
## negative too; a cut or rewind not in the list fails (`cut`, `rewind`), and on the product a listed one that no longer
## happens fails too (`open`), so any change to the class has to be looked at. An OPEN cut is pinned to what cuts it (T4
## audit 2026-10-14 proposal 7, plan «Рішення T1 після аудиту T4»): the blocker's name is part of the key (an
## engine-made name «@Class@N» depends on build order, so such a body is named by its parent and class instead), and the
## first-tick hit must lie within BLOCKER_TOLERANCE of the pinned point — another blocker, or the same one elsewhere,
## at the same press is a new cut (`cut`), and the pinned one is gone (`open`).
## DENIED (KNOWN_DENIED): a press that marked or launched at an anchor but neither hung nor rewound within 60 ticks.
## Measured on 2026-10-14 (18 presses, Choko 11, Skea 7); each is printed «ROPE_CHOICE DENIED …», and on the product a
## denied press not in the list, or a listed one that no longer happens, fails (`denied`): counted per part, pinned.
##   --hero=choko|skea (default both) · --part=K/N (default 1/1): the rings of the anchors whose index % N == K − 1,
##     and the route in part 1, so the battery splits the 12000-frame budget.
##   --break=awning|late_wall|flight — negative controls, each must go red in `cut` (a negative stops pressing at its
##     first failure): the grocer's spread awning back (its collider as before step 2, layer 1 | 8); a thin plate put
##     across hand → anchor on the contact tick; the parkour projectile at a quarter of its speed, so the hand moves
##     four times as far between the choice and the contact.
##   --break=blocker_name — the pin's own negative, red in `cut`: every engine-named solid of the market renamed
##     (MarketSolid<N>), so the same body at the same point is another blocker by name.
## Transfers (ADR-028 п. 5, plan 2026-10-15-Rope-Climb-Perch-Release step 5; T5 docs/GDD/2026-10-15-Rope-Climb-Numbers.md
## § 8 «Вибрав — не обірвав» для переходів): --transfer runs the same rule on the city rope's E from a hang. For every
## anchor A of the part the hero hangs on A (the replay's recorded packet from the first standing start that hangs), the
## pull settles, the camera turns through BEARINGS; every other anchor B the camera's packet marks is pressed once (real
## E, from a fresh hang on A): the new rope on B is not ended on its first hanging tick by solid geometry on hand → B (the
## anchor's own post excepted, as above). T3's case (anchor 2 → 17, the old post AnchorPost2) is one of them. A first-tick
## cut on a transfer is pinned in KNOWN_TRANSFER_CUTS like KNOWN_CUTS (4: 22 → 19 and 14 → 22 for each hero); denied
## transfers and rewinds are printed and counted, and pinned at the 0 measured on 2026-10-15 (T4 audit 15а Y4): one on the
## product fails (`transfer_denied`, `transfer_rewind`) — look at it, then pin it with its reason or fix it.
##   Sentinel (transfer): ROPE_CHOICE_COMPLETE checks=N failures=M mutation=<m> part=K/N mode=transfer anchors=a/A
##   presses=p hangs=h cut_first=c open=o rewinds=r denied=d red=<families|none>.
## Sentinel: ROPE_CHOICE_COMPLETE checks=N failures=M mutation=<m> part=K/N anchors=a/A presses=p hangs=h cut_first=c
## open=o rewinds=r red=<families|none>; failures print "ROPE_CHOICE: ...".
const RINGS: Array[float] = [2.5, 5.0, 8.0, 11.0]
const BEARINGS: int = 8
const HAND_Y: float = 1.25          # GrappleHook.HAND
const ABOVE: float = 1.5            # T8 hard filter: the anchor 1.5 m over the hand (HarpoonAim, anchor_coverage)
const CLEARANCE: float = 1.8
const PATCH: float = 0.3
const COVER_LAYER := 8              # ArenaLayout.COVER_LAYER: the product's line_clear mask is COVER_LAYER | 1
const RUN_TICKS: int = 12           # rope_pull_check / auto_hook_check P11
const SETTLE_TICKS: int = 4         # a restart lands in 1–2 ticks; HarpoonAim.reset clears the target lock
const HANG := 3
const FLIGHT := 2
const REWIND := 4
## The grocer's awning as it stood before step 2 (CityInteriors: shop door (−26.6, 0, 12), box (0, 3.85, −0.52) of
## 6.5 × 0.18 × 1.15) — the `awning` negative.
const GROCER_AWNING := Vector3(-26.6, 3.85, 11.48)
const GROCER_AWNING_SIZE := Vector3(6.5, 0.18, 1.15)
## OPEN first-tick cuts (see the header): "<hero>|<press label>|<anchor hung on>|<blocker>" → the first-tick hit point
## (`at`, the rewind has none: its flight line is clear, the hand past range) and why. Measured on the tree of plan
## 2026-10-14 step 2 (the grocer's awning rolled), docs/Fix/2026-10-14-Lamp-Posts-Awning-Anchor-5-Fix.md § 2; the same
## points to 0.01 m in T4's run (scratchpad t4-debt/logs/P-choice-*.log) and in docs/Fix/2026-10-14-Guard-Pins-After-Audit-Fix.md.
const KNOWN_CUTS: Dictionary = {
	"choko|anchor 5 ring 5.0/5 y0.0 run|4|CityMarket/StaticBody3D": {"at": Vector3(7.29, 2.65, 18.81), "why": "anchor 4, the east z 18 stall's canopy; the line at contact was clear"},
	"choko|anchor 17 ring 11.0/4 y0.0 run|16|ShopLintel": {"at": Vector3(-25.86, 3.35, 12.15), "why": "anchor 16, the grocer's lintel: the run ends in the shop door"},
	"choko|anchor 22 ring 5.0/0 y0.0 run|22|ArchitectureSolid1537": {"at": Vector3(-9.89, 5.90, -25.81), "why": "anchor 22, the plaster house's facade; the line at contact was clear"},
	"choko|anchor 23 ring 11.0/4 y0.0 run|rewind|-": {"why": "anchor 23, the hand 14.32 m from it at contact (range 14): rewound"},
	"skea|anchor 3 ring 11.0/2 y2.7 run|3|PracticeLedge": {"at": Vector3(5.23, 2.48, 17.00), "why": "anchor 3, PracticeLedge under the line"},
	"skea|anchor 5 ring 5.0/5 y0.0 run|4|CityMarket/StaticBody3D": {"at": Vector3(7.38, 2.65, 18.72), "why": "anchor 4, the east z 18 stall's canopy"},
	"skea|anchor 14 ring 8.0/0 y0.0 run|14|RoofBridge": {"at": Vector3(-4.27, 3.50, -21.80), "why": "anchor 14, RoofBridge: the run ends under the bridge"},
	"skea|anchor 14 ring 11.0/0 y0.0 run|15|RoofBridge": {"at": Vector3(4.14, 3.50, -21.80), "why": "anchor 15, RoofBridge: the run ends under the bridge"},
	"skea|anchor 15 ring 8.0/4 y0.0 run|15|RoofBridge": {"at": Vector3(4.27, 3.50, -21.80), "why": "anchor 15, RoofBridge: the run ends under the bridge"},
	"skea|anchor 17 ring 11.0/4 y0.0 run|16|ShopLintel": {"at": Vector3(-25.67, 3.70, 12.15), "why": "anchor 16, the grocer's lintel: the run ends in the shop door"},
	"skea|anchor 22 ring 5.0/0 y0.0 run|22|ArchitectureSolid1624": {"at": Vector3(-9.80, 5.76, -26.01), "why": "anchor 22, the plaster house's facade"},
}
## How far the first-tick hit may lie from its pinned point: under the shift of one hanging tick (the contact and the
## first-tick hits of one press lie 0.04–0.13 m apart) and under the gap between the two heroes' hits at one press
## (0.13 m at anchor 5); the runs are deterministic (T2-A's and T4's points are identical to 0.01 m).
const BLOCKER_TOLERANCE: float = 0.1
## DENIED presses (see the header): "<hero>|<press label>" → what the product did, from this guard's own «DENIED» lines
## on 2026-10-14 (docs/Fix/2026-10-14-Guard-Pins-After-Audit-Fix.md § 3). Per part 1–5: Choko 5 · 1 · 2 · 1 · 2, Skea
## 4 · 0 · 0 · 1 · 2 — the same counts as T2-A's and T4's runs (their «denied=» per hero line).
const KNOWN_DENIED: Dictionary = {
	"choko|route (-29.0, 3.0, -5.5)": "part 1: marked StreetAnchor18, a windup the launch never followed (1×9 0×1)",
	"choko|anchor 5 ring 11.0/5 y0.0 run": "part 1: marked StreetAnchor5, a windup the launch never followed (1×9 0×1)",
	"choko|anchor 10 ring 5.0/5 y0.0 run": "part 1: marked StreetAnchor3, a windup the launch never followed (1×9 0×1)",
	"choko|anchor 20 ring 5.0/2 y4.0 run": "part 1: marked StreetAnchor13, a windup the launch never followed (1×9 0×1)",
	"choko|anchor 20 ring 8.0/3 y4.0 run": "part 1: marked StreetAnchor20, a windup the launch never followed (1×9 0×1)",
	"choko|anchor 16 ring 8.0/0 y0.0 run": "part 2: marked StreetAnchor17, the press started nothing (0×4)",
	"choko|anchor 17 ring 5.0/0 y0.0 run": "part 3: marked StreetAnchor17, the press started nothing (0×4)",
	"choko|anchor 17 ring 5.0/4 y0.0 run": "part 3: marked StreetAnchor16, the press started nothing (0×4)",
	"choko|anchor 13 ring 8.0/5 y4.0 run": "part 4: marked StreetAnchor13, a windup the launch never followed (1×9 0×1)",
	"choko|anchor 14 ring 2.5/7 y0.0 run": "part 5: marked StreetAnchor22, a windup the launch never followed (1×9 0×1)",
	"choko|anchor 24 ring 2.5/2 y4.0 run": "part 5: marked StreetAnchor12, a windup the launch never followed (1×9 0×1)",
	"skea|anchor 5 ring 11.0/5 y0.0 run": "part 1: marked StreetAnchor5, a windup the launch never followed (1×9 0×1)",
	"skea|anchor 10 ring 5.0/5 y0.0 run": "part 1: marked StreetAnchor3, a windup the launch never followed (1×9 0×1)",
	"skea|anchor 20 ring 5.0/2 y4.0 run": "part 1: marked StreetAnchor13, a windup the launch never followed (1×9 0×1)",
	"skea|anchor 20 ring 8.0/3 y4.0 run": "part 1: marked StreetAnchor20, a windup the launch never followed (1×9 0×1)",
	"skea|anchor 13 ring 8.0/5 y4.0 run": "part 4: marked StreetAnchor13, a windup the launch never followed (1×9 0×1)",
	"skea|anchor 14 ring 2.5/7 y0.0 run": "part 5: marked StreetAnchor22, a windup the launch never followed (1×9 0×1)",
	"skea|anchor 24 ring 2.5/2 y4.0 run": "part 5: marked StreetAnchor12, a windup the launch never followed (1×9 0×1)",
}
## OPEN first-tick cuts on a transfer: "<hero>|transfer <A>→<B>|<blocker>" → the first-tick hit (`at`) and why. Measured
## on 2026-10-15 (docs/Fix/2026-10-15-Rope-Climb-City-Fix.md § 3.6), the same points for both heroes: in both the line at
## contact was already blocked — the selection does not foresee the hand at contact (the class of KNOWN_CUTS, variant Т2
## deferred), not the post just left.
const KNOWN_TRANSFER_CUTS: Dictionary = {
	"choko|transfer 22→19|ArchitectureSolid1569": {"at": Vector3(-15.24, 7.70, -25.15), "why": "from the plaster house's bracket to the tower's: the tower's own cornice on the line at contact"},
	"skea|transfer 22→19|ArchitectureSolid1569": {"at": Vector3(-15.24, 7.70, -25.15), "why": "from the plaster house's bracket to the tower's: the tower's own cornice on the line at contact"},
	"choko|transfer 14→22|NorthWestRoof": {"at": Vector3(-10.00, 2.97, -24.13), "why": "from the alley lamp to the plaster house's bracket: the terrace's edge on the line at contact"},
	"skea|transfer 14→22|NorthWestRoof": {"at": Vector3(-10.00, 2.97, -24.13), "why": "from the alley lamp to the plaster house's bracket: the terrace's edge on the line at contact"},
}
const TRANSFER_AFTER: int = 34      # + the 6 ticks of marking: E 40 ticks after the hang, as T3's probe pressed it
## T3's case itself (scratchpad t3-rope-probe/s7b.log): E on anchor 2 from (0, 0, 9.5), the camera on it; 40 ticks later E
## at the marked anchor 17, still and with W held; the old lamp's post AnchorPost2 cut the new rope on its 1st–2nd tick.
## Here the new rope must hold through its whole pull (the fix's window) and the first tick after it.
const S7B_FROM: int = 2
const S7B_TO: int = 17
const S7B_START := Vector3(0, 0, 9.5)
var transfer_mode: bool = false
var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var only_hero: String = ""
var part: int = 1
var parts: int = 1
var red: Dictionary = {}
var router: Node
var supports: Array[Dictionary] = []
var anchors: Array[Vector3] = []
var picked: Dictionary = {}         # anchor index -> presses that hung on it (all heroes)
var totals := {"presses": 0, "hangs": 0, "cut_first": 0, "open": 0, "rewinds": 0, "denied": 0, "none": 0}
var seen_open: Dictionary = {}
var seen_denied: Dictionary = {}
var late_plate: StaticBody3D


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
		elif argument.begins_with("--hero="):
			only_hero = argument.trim_prefix("--hero=")
		elif argument == "--transfer":
			transfer_mode = true
		elif argument.begins_with("--part="):
			var split := argument.trim_prefix("--part=").split("/")
			part = int(split[0])
			parts = maxi(1, int(split[1]))
	_run.call_deferred()


func _check(ok: bool, family: String, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		red[family] = true
		push_error("ROPE_CHOICE: [%s] %s" % [family, label])


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
	for spec: Dictionary in supports:
		anchors.append(spec.point)
	var state: Node = root.get_node("GameState")
	state.set_free_move(true)
	state.water = null
	var heroes: Array[String] = []
	for hero: String in ["choko", "skea"]:
		if only_hero.is_empty() or only_hero == hero:
			heroes.append(hero)
			await _district(hero)
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		var node := root.get_node_or_null(singleton)
		if node != null:
			node.queue_free()
	var deadline: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < deadline:
		await process_frame
		OS.delay_msec(1)
	var sampled: Array[int] = []
	var missing: Array[int] = []
	for index: int in anchors.size():
		if index % parts == part - 1:
			sampled.append(index)
			if int(picked.get(index, 0)) == 0:
				missing.append(index)
	var counts: PackedStringArray = []
	for index: int in anchors.size():
		counts.append("%d:%d" % [index, int(picked.get(index, 0))])
	print("ROPE_CHOICE picked %s" % " ".join(counts))
	print("ROPE_CHOICE totals %s" % str(totals))
	# Non-vacuous: every anchor of this part was picked from some sampled position and evaluated (on the product; a
	# negative stops at its first failure).
	if mutation == "none" and transfer_mode:
		_check(missing.is_empty(), "count", "transfers: anchors of part %d/%d never hung on as a source: %s" % [part, parts, missing])
		_check(int(totals.hangs) > 0, "count", "transfers: %d transfer hangs in part %d/%d" % [totals.hangs, part, parts])
		for key: String in KNOWN_TRANSFER_CUTS:
			if heroes.has(key.get_slice("|", 0)) and int(key.get_slice("|", 1).get_slice(" ", 1).get_slice("→", 0)) % parts == part - 1:
				_check(seen_open.has(key), "open", "the OPEN transfer cut «%s» (%s) no longer happens: look at it and unpin it" % [key, KNOWN_TRANSFER_CUTS[key]])
		_check(int(totals.rewinds) == 0, "transfer_rewind", "transfers: %d presses rewound in part %d/%d, pinned 0" % [totals.rewinds, part, parts])
		_check(int(totals.denied) == 0, "transfer_denied", "transfers: %d presses denied in part %d/%d, pinned 0" % [totals.denied, part, parts])
	if mutation == "none" and not transfer_mode:
		_check(missing.is_empty(), "count", "anchors of part %d/%d never picked from a sampled position: %s" % [part, parts, missing])
		_check(int(totals.hangs) >= sampled.size(), "count", "%d hangs for %d anchors" % [totals.hangs, sampled.size()])
	# Every OPEN cut of the heroes and the part that ran still happens (only on the product: a negative changes the world).
	if mutation == "none" and not transfer_mode:
		for key: String in KNOWN_CUTS:
			if _expected(key, heroes):
				_check(seen_open.has(key), "open", "the OPEN first-tick cut «%s» (%s) no longer happens: look at it and unpin it" % [key, KNOWN_CUTS[key].why])
		# DENIED, per part: every pinned denied press of this run still happens (a new one already failed at its press).
		var expected_denied := 0
		for key: String in KNOWN_DENIED:
			if _expected(key, heroes):
				expected_denied += 1
				_check(seen_denied.has(key), "denied", "the pinned denied press «%s» (%s) no longer happens: look at it and unpin it" % [key, KNOWN_DENIED[key]])
		_check(int(totals.denied) == expected_denied, "denied", "%d denied presses in part %d/%d, pinned %d" % [totals.denied, part, parts, expected_denied])
		print("ROPE_CHOICE denied %d (pinned for this part %d)" % [totals.denied, expected_denied])
	var families: Array = red.keys()
	families.sort()
	print("ROPE_CHOICE frames=%d (the playable harness quits after 12000)" % Engine.get_process_frames())
	if transfer_mode:
		print("ROPE_CHOICE_COMPLETE checks=%d failures=%d mutation=%s part=%d/%d mode=transfer anchors=%d/%d presses=%d hangs=%d cut_first=%d open=%d rewinds=%d denied=%d red=%s" % [
			checks, failures, mutation, part, parts, sampled.size() - missing.size(), sampled.size(), totals.presses, totals.hangs,
			totals.cut_first, totals.open, totals.rewinds, totals.denied, ",".join(families) if not families.is_empty() else "none"])
		quit(1 if failures else 0)
		return
	print("ROPE_CHOICE_COMPLETE checks=%d failures=%d mutation=%s part=%d/%d anchors=%d/%d presses=%d hangs=%d cut_first=%d open=%d rewinds=%d red=%s" % [
		checks, failures, mutation, part, parts, sampled.size() - missing.size(), sampled.size(), totals.presses, totals.hangs,
		totals.cut_first, totals.open, totals.rewinds, ",".join(families) if not families.is_empty() else "none"])
	quit(1 if failures else 0)


## A KNOWN_CUTS key belongs to this run: its hero ran, and its press is the route (part 1) or a ring of this part.
func _expected(key: String, heroes: Array[String]) -> bool:
	var fields := key.split("|")
	if not heroes.has(fields[0]):
		return false
	var label: String = fields[1]
	if label.begins_with("route"):
		return part == 1
	return int(label.get_slice(" ", 1)) % parts == part - 1


func _district(hero: String) -> void:
	var state: Node = root.get_node("GameState")
	state.p1_character = hero
	router.apply_profile("solo", false)
	var world: Node = load("res://scenes/world/CityWorld.tscn").instantiate()
	world.story_save_enabled = false
	world.journey_save_enabled = false
	world.lower_story_save_enabled = false
	if mutation == "transfer_skip":
		# The transfer's grace removed (tools/grapple/rope_climb_mutants.gd): the old post cuts the new rope again.
		Engine.set_meta("rope_climb_mutation", mutation)
		world.fighter_script = load((get_script() as Script).resource_path.get_base_dir().path_join("rope_climb_fighter.gd"))
	root.add_child(world)
	current_scene = world
	world.progress.save_enabled = false
	world.npc_director.save_enabled = false
	world.npc_director.process_mode = Node.PROCESS_MODE_DISABLED
	await _ticks(40)
	world.onboarding.skip()
	_break_scene(world)
	var space: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state
	var range_m: float = world.player.grapple.range_m
	var before := totals.duplicate()
	if transfer_mode:
		if S7B_FROM % parts == part - 1:
			for variant: String in ["still", "swing_W"]:
				await _s7b(world, hero, variant)
		for index: int in anchors.size():
			if index % parts == part - 1:
				await _transfers(world, hero, index)
		print("ROPE_CHOICE transfer %s presses=%d hangs=%d cut_first=%d open=%d rewinds=%d denied=%d" % [hero,
			totals.presses - before.presses, totals.hangs - before.hangs, totals.cut_first - before.cut_first,
			totals.open - before.open, totals.rewinds - before.rewinds, totals.denied - before.denied])
		world.queue_free()
		current_scene = null
		await _ticks(3)
		return
	# P11 route: run along each leg, tap E.
	if part == 1:
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
				await _press(world, hero, "route %s" % at, at, direction, direction)
	# Rings around the anchors of this part.
	for index: int in anchors.size():
		if index % parts != part - 1:
			continue
		var point: Vector3 = anchors[index]
		var turn := 0
		for radius: float in RINGS:
			for bearing: int in BEARINGS:
				var angle := TAU * float(bearing) / float(BEARINGS)
				var flat := Vector3(cos(angle), 0, sin(angle))
				var x := point.x + flat.x * radius
				var z := point.z + flat.z * radius
				for floor_y: float in _floors(space, x, z, point.y - ABOVE - HAND_Y):
					var at := Vector3(x, floor_y, z)
					var hand := at + Vector3(0, HAND_Y, 0)
					if hand.distance_to(point) > range_m or not _ray(space, hand, point, COVER_LAYER | 1).is_empty():
						continue
					var toward := Vector3(point.x - x, 0, point.z - z).normalized()
					var level := "y%.1f" % floor_y
					await _press(world, hero, "anchor %d ring %.1f/%d %s standing" % [index, radius, bearing, level], at, toward, toward, false)
					var tangent := Vector3(-toward.z, 0, toward.x) * (1.0 if turn % 2 == 0 else -1.0)
					turn += 1
					await _press(world, hero, "anchor %d ring %.1f/%d %s run" % [index, radius, bearing, level], at, tangent, tangent)
	print("ROPE_CHOICE %s presses=%d hangs=%d cut_first=%d open=%d rewinds=%d denied=%d none=%d" % [hero,
		totals.presses - before.presses, totals.hangs - before.hangs, totals.cut_first - before.cut_first,
		totals.open - before.open, totals.rewinds - before.rewinds, totals.denied - before.denied, totals.none - before.none])
	world.queue_free()
	current_scene = null
	await _ticks(3)


## One press from `at`: reset there facing `facing`, the camera along `view`; run with W for RUN_TICKS when `run`; tap E
## (W released once the hook holds, as P11). Evaluates the anchor the product launched at.
func _press(world: Node, hero: String, label: String, at: Vector3, facing: Vector3, view: Vector3, run: bool = true) -> void:
	if mutation != "none" and failures > 0:
		return # A negative has made its point; the slow `flight` would not fit the frame budget otherwise.
	var hero_node: CharacterBody3D = world.player
	var hook: Node = hero_node.grapple
	_key(KEY_W, false)
	hook.detach()
	world.ropes.clear_match()
	await _ticks(1)
	hero_node.restart_at(at)
	hero_node._set_forward(facing)
	var rig: Node3D = world.camera_rig
	rig.reset_view()
	rig.aim.yaw_offset = atan2(-view.x, -view.z)
	await _ticks(SETTLE_TICKS)
	if run:
		_key(KEY_W, true)
		await _ticks(RUN_TICKS)
	var marked := String(rig.aim.published.get("target_id", ""))
	totals.presses += 1
	_key(KEY_E, true)
	await _ticks(1)
	_key(KEY_E, false)
	var launched := ""
	var phases: Array[int] = []
	var hung := false
	for tick: int in 60:
		await _ticks(1)
		phases.append(int(hook.phase))
		if int(hook.phase) == FLIGHT and launched.is_empty():
			launched = String(hook.aim_intent.get("target_id", ""))
		if int(hook.phase) == HANG and hook.attached:
			hung = true
			break
		if tick > 2 and int(hook.phase) == 0:
			break
	_key(KEY_W, false)
	var tag := "[%s] %s: " % [hero, label]
	if REWIND in phases:
		totals.rewinds += 1
		# What stopped the projectile: the flight's own query (GrappleHook._flight: cover, body and layer 4, areas too)
		# from where it was launched toward the point it was launched at.
		var target := root.get_node_or_null(NodePath(launched)) as Node3D if not launched.is_empty() else null
		var blocker := "?"
		var rewind_by := "?"
		if target != null:
			var query := PhysicsRayQueryParameters3D.create(hook.get("_launch_origin"), target.global_position, COVER_LAYER | 1 | 4)
			query.collide_with_areas = true
			query.hit_from_inside = true
			query.exclude = [hero_node.get_rid(), hero_node.hurtbox.get_rid()]
			var hit := hero_node.get_world_3d().direct_space_state.intersect_ray(query)
			rewind_by = "-" if hit.is_empty() else _blocker_id(hit.collider as Node)
			blocker = "-" if hit.is_empty() else "%s@(%.2f,%.2f,%.2f)" % [(hit.collider as Node).name, hit.position.x, hit.position.y, hit.position.z]
			# A clear flight line rewinds only when the hand is past range at contact (GrappleHook._flight).
			blocker += ", hand→point %.2f m now (range %.1f)" % [(hero_node.global_position + Vector3(0, HAND_Y, 0)).distance_to(target.global_position), float(hook.range_m)]
		var key := "%s|%s|rewind|%s" % [hero, label, rewind_by]
		var entry := "%s from %s, marked %s, launched at %s: rewound before contact, the flight line stopped by %s" % [key, at, _name(marked), _name(launched), blocker]
		if KNOWN_CUTS.has(key):
			totals.open += 1
			seen_open[key] = true
			print("ROPE_CHOICE OPEN %s" % entry)
			return
		print("ROPE_CHOICE CUT %s" % entry)
		_check(false, "rewind", tag + "the shot at %s (marked %s) rewound before contact (%s)" % [_name(launched), _name(marked), blocker])
		return
	if not hung:
		var denied := not launched.is_empty() or not marked.is_empty()
		totals.denied += int(denied)
		totals.none += int(not denied)
		if denied:
			var key := "%s|%s" % [hero, label]
			seen_denied[key] = true
			var entry := "%s from %s, marked %s, launched at %s, phases %s" % [key, at, _name(marked), _name(launched) if not launched.is_empty() else "-", _phases(phases)]
			print("ROPE_CHOICE DENIED %s%s" % [entry, "" if KNOWN_DENIED.has(key) else " (not pinned)"])
			if mutation == "none":
				_check(KNOWN_DENIED.has(key), "denied", tag + "marked %s, launched at %s, but neither hung nor rewound in 60 ticks (phases %s), and this press is not in KNOWN_DENIED" % [_name(marked), _name(launched), _phases(phases)])
		return
	var anchor: Vector3 = hook.anchor_point
	var index := anchors.find(anchor)
	_check(index >= 0 and _name(launched) == "StreetAnchor%d" % index, "count", tag + "the hang %s is on the anchor launched at (%s)" % [anchor, _name(launched)])
	totals.hangs += 1
	picked[index] = int(picked.get(index, 0)) + 1
	var spec: Dictionary = supports[index] if index >= 0 else {}
	if mutation == "late_wall":
		_plate(world, hero_node.global_position + Vector3(0, HAND_Y, 0), anchor)
	var contact_line := _line(hero_node, hero_node.global_position + Vector3(0, HAND_Y, 0), anchor, spec)
	# The first hanging tick: one drive of the hang (its move, then its line check).
	await _ticks(1)
	var line := _line(hero_node, hero_node.global_position + Vector3(0, HAND_Y, 0), anchor, spec)
	var released: bool = int(hook.phase) != HANG or not hook.attached
	if late_plate != null:
		late_plate.free()
		late_plate = null
	if not released:
		return
	var cut := not String(line.other).is_empty()
	_check(cut, "release", tag + "the hang on %s ended on the first tick with a clear line" % _name(launched))
	if not cut:
		return
	totals.cut_first += 1
	var key := "%s|%s|%d|%s" % [hero, label, index, line.other_id]
	var entry := "%s from %s, marked %s: first tick cut by %s; contact line %s" % [key, at, _name(marked), line.other, contact_line.other if not String(contact_line.other).is_empty() else "clear"]
	var pin: Dictionary = KNOWN_CUTS.get(key, {})
	var off := INF if pin.is_empty() else Vector3(line.other_at).distance_to(Vector3(pin.get("at", Vector3.INF)))
	if not pin.is_empty() and off <= BLOCKER_TOLERANCE:
		totals.open += 1
		seen_open[key] = true
		print("ROPE_CHOICE OPEN %s (%.3f m from the pinned point)" % [entry, off])
		return
	print("ROPE_CHOICE CUT %s" % entry)
	var pinned := ""
	for other: String in KNOWN_CUTS:
		if other.begins_with("%s|%s|" % [hero, label]):
			pinned = "; the press is pinned as «%s» at %s (this hit %.3f m from it, at most %.2f)" % [other, KNOWN_CUTS[other].get("at", "-"), Vector3(line.other_at).distance_to(Vector3(KNOWN_CUTS[other].get("at", Vector3.INF))), BLOCKER_TOLERANCE]
	_check(false, "cut", tag + "chosen %s, cut on the first hanging tick by %s%s" % [_name(launched), line.other, pinned])


func _name(target_id: String) -> String:
	return target_id.get_file()


## A blocker as the OPEN key names it: its own name, or «<parent>/<class>» when the engine made the name («@Class@N»
## counts every node built before it, so it moves whenever the city gains or loses one).
func _blocker_id(node: Node) -> String:
	if node == null:
		return "?"
	var own := String(node.name)
	if not own.begins_with("@"):
		return own
	return "%s/%s" % [String(node.get_parent().name) if node.get_parent() != null else "?", node.get_class()]


## The phases of a press, run-length coded (GrappleHook.Phase: 0 idle, 1 windup, 2 flight, 3 hang, 4 miss rewind):
## «1×9 0×1» — a windup the launch never followed; «0×4» — the press started nothing.
func _phases(phases: Array[int]) -> String:
	var parts_out: PackedStringArray = []
	var index := 0
	while index < phases.size():
		var run := 1
		while index + run < phases.size() and phases[index + run] == phases[index]:
			run += 1
		parts_out.append("%d×%d" % [phases[index], run])
		index += run
	return " ".join(parts_out) if not parts_out.is_empty() else "-"


## Walkable floors of one column below `top`, top to bottom: an upward-facing hit with CLEARANCE free above it and the
## same height within 0.1 m at ±PATCH (anchor_coverage's standing patch).
func _floors(space: PhysicsDirectSpaceState3D, x: float, z: float, top: float) -> Array[float]:
	var result: Array[float] = []
	var from_y := top + CLEARANCE
	for guard: int in 12:
		var hit := _ray(space, Vector3(x, from_y, z), Vector3(x, -1.0, z), 1)
		if hit.is_empty():
			break
		var y: float = hit.position.y
		if y <= top and Vector3(hit.normal).y > 0.7 and _standing_patch(space, x, y, z):
			if result.is_empty() or absf(result[-1] - y) > 0.2:
				result.append(y)
		from_y = y - 0.02
	return result


func _standing_patch(space: PhysicsDirectSpaceState3D, x: float, y: float, z: float) -> bool:
	for offset: Vector2 in [Vector2.ZERO, Vector2(PATCH, 0), Vector2(-PATCH, 0), Vector2(0, PATCH), Vector2(0, -PATCH)]:
		var px := x + offset.x
		var pz := z + offset.y
		if _ray(space, Vector3(px, y + 0.1, pz), Vector3(px, y - 0.1, pz), 1).is_empty():
			return false
		if not _ray(space, Vector3(px, y + 0.05, pz), Vector3(px, y + CLEARANCE, pz), 1).is_empty():
			return false
	return true


func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, mask: int) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, mask)
	return space.intersect_ray(query)


## What solid geometry lies on hand→anchor, by the product's own rope rule (body layer and cover): `own` names the
## anchor's own post if the line crosses it, `other` the first other solid ("" when none). rope_pull_check's rule.
func _line(hero_node: CharacterBody3D, from: Vector3, to: Vector3, spec: Dictionary) -> Dictionary:
	var result := {"own": "", "other": "", "other_id": "", "other_at": Vector3.INF}
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
		# The blocker's name now: a negative's plate is freed before the verdict reads it.
		result.other_id = _blocker_id(node)
		result.other_at = hit.position
		break
	return result


func _is_own_post(node: Node3D, spec: Dictionary) -> bool:
	if spec.is_empty() or String(spec.kind) != "post" or not node is StaticBody3D:
		return false
	var mount: Vector3 = spec.mount
	var at := node.global_position
	return Vector2(at.x - mount.x, at.z - mount.z).length() < 0.05 and at.y > mount.y and at.y < Vector3(spec.point).y + 0.3


# --- negative controls -------------------------------------------------------------------------------------------
func _break_scene(world: Node) -> void:
	match mutation:
		"awning":
			var body := StaticBody3D.new()
			body.name = "NegativeGrocerAwning"
			body.collision_layer = 1 | 8
			body.collision_mask = 0
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = GROCER_AWNING_SIZE
			shape.shape = box
			body.add_child(shape)
			world.add_child(body)
			body.global_position = GROCER_AWNING
		"flight":
			var hook: Node = world.player.grapple
			hook.set("parkour_projectile_speed", float(hook.get("parkour_projectile_speed")) * 0.25)
		"blocker_name":
			var market := world.find_child("CityMarket", true, false)
			var renamed := 0
			if market != null:
				for child: Node in market.get_children():
					if child is StaticBody3D and String(child.name).begins_with("@"):
						child.name = "MarketSolid%d" % renamed
						renamed += 1
			print("ROPE_CHOICE break=blocker_name renamed %d market solids" % renamed)
	print("ROPE_CHOICE break=%s" % mutation)


## `late_wall`: a 0.6 × 0.6 m plate, 5 cm thick, across hand → anchor halfway, on the contact tick.
func _plate(world: Node, hand: Vector3, anchor: Vector3) -> void:
	late_plate = StaticBody3D.new()
	late_plate.collision_layer = 1 | 8
	late_plate.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.6, 0.6, 0.05)
	shape.shape = box
	late_plate.add_child(shape)
	world.add_child(late_plate)
	var mid := hand.lerp(anchor, 0.5)
	var direction := (anchor - hand).normalized()
	late_plate.global_transform = Transform3D(Basis.looking_at(direction, Vector3.UP if absf(direction.y) < 0.99 else Vector3.FORWARD), mid)



# --- transfers (--transfer) -----------------------------------------------------------------------------------------

## Standing starts for anchor `index` in ring order (rope_climb_check's rule): a floor with headroom whose hand sees the
## anchor within range, 1.5 m under it.
func _transfer_starts(world: Node, index: int) -> Array[Vector3]:
	var found: Array[Vector3] = []
	var space: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state
	var point: Vector3 = anchors[index]
	var range_m: float = world.player.grapple.range_m
	for radius: float in [2.5, 4.0, 6.0, 8.0]:
		for bearing: int in BEARINGS:
			var angle := TAU * float(bearing) / float(BEARINGS)
			var x := point.x + cos(angle) * radius
			var z := point.z + sin(angle) * radius
			for floor_y: float in _floors(space, x, z, point.y - ABOVE - HAND_Y):
				var hand := Vector3(x, floor_y + HAND_Y, z)
				if hand.distance_to(point) <= range_m - 0.5 and _ray(space, hand, point, COVER_LAYER | 1).is_empty():
					found.append(Vector3(x, floor_y, z))
					if found.size() >= 6:
						return found
	return found


## A settled hang on `index` through the replay's recorded packet; false when none of the starts hangs.
func _hang_source(world: Node, index: int) -> bool:
	var hero_node: CharacterBody3D = world.player
	var hook: Node = hero_node.grapple
	var marker: Node3D = world.district.get_node("StreetAnchor%d" % index)
	for start: Vector3 in _transfer_starts(world, index):
		_key(KEY_W, false)
		_key(KEY_E, false)
		hook.detach()
		world.ropes.clear_match()
		await _ticks(1)
		hero_node.restart_at(start)
		var view := Vector3(marker.global_position.x - start.x, 0, marker.global_position.z - start.z)
		hero_node._set_forward(view.normalized())
		world.camera_rig.reset_view()
		await _ticks(SETTLE_TICKS)
		if hook.fire(false, "grapple_parkour", {"point": marker.global_position, "target_id": String(marker.get_path())}) == 0:
			continue
		hero_node._set_state(13)
		for tick: int in 60:
			await _ticks(1)
			if int(hook.phase) == HANG and hook.attached or int(hook.phase) == 0 or int(hook.phase) == REWIND:
				break
		if int(hook.phase) == HANG and Vector3(hook.anchor_point).is_equal_approx(marker.global_position):
			# T3's timing (s7b): the transfer 40 ticks after the hang, the body still carried by the pull.
			await _ticks(TRANSFER_AFTER)
			return int(hook.phase) == HANG
	return false


func _transfers(world: Node, hero: String, index: int) -> void:
	var hero_node: CharacterBody3D = world.player
	var hook: Node = hero_node.grapple
	var rig: Node3D = world.camera_rig
	if not await _hang_source(world, index):
		print("ROPE_CHOICE transfer %s source %d: no start hangs" % [hero, index])
		return
	picked[index] = int(picked.get(index, 0)) + 1
	# The targets the camera marks from this hang, one bearing each.
	var marked: Dictionary = {}
	for bearing: int in BEARINGS:
		rig.aim.yaw_offset = TAU * float(bearing) / float(BEARINGS)
		await _ticks(3)
		var id := String(rig.aim.published.get("target_id", ""))
		var other := anchors.find(Vector3(rig.aim.published.get("point", Vector3.INF)))
		if not id.is_empty() and other >= 0 and other != index and not marked.has(other):
			marked[other] = rig.aim.yaw_offset
	for other: int in marked:
		if mutation != "none" and failures > 0:
			return
		if not await _hang_source(world, index):
			continue
		rig.aim.yaw_offset = float(marked[other])
		await _ticks(3)
		var label := "transfer %d→%d" % [index, other]
		var tag := "[%s] %s: " % [hero, label]
		if anchors.find(Vector3(rig.aim.published.get("point", Vector3.INF))) != other:
			print("ROPE_CHOICE NONE %s|%s: the mark moved (%s)" % [hero, label, rig.aim.published.get("target_id", "")])
			continue
		totals.presses += 1
		_key(KEY_E, true)
		await _ticks(1)
		_key(KEY_E, false)
		var phases: Array[int] = []
		var hung := false
		for tick: int in 60:
			await _ticks(1)
			phases.append(int(hook.phase))
			if int(hook.phase) == HANG and hook.attached and anchors.find(Vector3(hook.anchor_point)) == other:
				hung = true
				break
			if int(hook.phase) in [0, REWIND] and tick > 0:
				break
		if REWIND in phases:
			totals.rewinds += 1
			print("ROPE_CHOICE REWIND %s|%s phases %s" % [hero, label, _phases(phases)])
			continue
		if not hung:
			totals.denied += 1
			print("ROPE_CHOICE DENIED %s|%s phases %s (a transfer press that did not hang)" % [hero, label, _phases(phases)])
			continue
		totals.hangs += 1
		var anchor: Vector3 = hook.anchor_point
		var spec: Dictionary = supports[other]
		if mutation == "late_wall":
			_plate(world, hero_node.global_position + Vector3(0, HAND_Y, 0), anchor)
		var contact_line := _line(hero_node, hero_node.global_position + Vector3(0, HAND_Y, 0), anchor, spec)
		await _ticks(1)
		var line := _line(hero_node, hero_node.global_position + Vector3(0, HAND_Y, 0), anchor, spec)
		var released: bool = int(hook.phase) != HANG or not hook.attached
		if late_plate != null:
			late_plate.free()
			late_plate = null
		if not released:
			_check(true, "cut", tag + "held")
			print("ROPE_CHOICE HELD %s|%s contact line %s" % [hero, label, contact_line.other if not String(contact_line.other).is_empty() else "clear"])
			continue
		totals.cut_first += 1
		var key := "%s|%s|%s" % [hero, label, line.other_id]
		var pin: Dictionary = KNOWN_TRANSFER_CUTS.get(key, {})
		var off := INF if pin.is_empty() else Vector3(line.other_at).distance_to(Vector3(pin.get("at", Vector3.INF)))
		if not pin.is_empty() and off <= BLOCKER_TOLERANCE:
			totals.open += 1
			seen_open[key] = true
			print("ROPE_CHOICE OPEN %s cut by %s (%.3f m from the pinned point; %s)" % [key, line.other, off, pin.why])
			continue
		print("ROPE_CHOICE CUT %s cut by %s, contact line %s" % [key, line.other, contact_line.other])
		_check(false, "cut", tag + "the transfer to anchor %d was cut on its first hanging tick by %s" % [other, line.other if not String(line.other).is_empty() else "a clear line"])



func _s7b(world: Node, hero: String, variant: String) -> void:
	var hero_node: CharacterBody3D = world.player
	var hook: Node = hero_node.grapple
	var rig: Node3D = world.camera_rig
	var from: Vector3 = anchors[S7B_FROM]
	var tag := "[%s] s7b %s: " % [hero, variant]
	_key(KEY_W, false)
	hook.detach()
	world.ropes.clear_match()
	await _ticks(1)
	hero_node.restart_at(S7B_START)
	var view := Vector3(from.x - S7B_START.x, 0, from.z - S7B_START.z)
	hero_node._set_forward(view.normalized())
	rig.reset_view()
	rig.aim.yaw_offset = atan2(-view.x, -view.z)
	await _ticks(14)
	_key(KEY_E, true)
	await _ticks(1)
	_key(KEY_E, false)
	var hung := false
	for tick: int in 60:
		await _ticks(1)
		if int(hook.phase) == HANG and hook.attached:
			hung = true
			break
	_check(hung and Vector3(hook.anchor_point).is_equal_approx(from), "count", tag + "E from %s hangs on anchor %d (%s)" % [S7B_START, S7B_FROM, hook.anchor_point])
	if not hung:
		return
	if variant == "swing_W":
		_key(KEY_W, true)
	await _ticks(40)
	var marked := anchors.find(Vector3(rig.aim.published.get("point", Vector3.INF)))
	_check(marked == S7B_TO, "count", tag + "the camera marks anchor %d as in T3's probe (marked %d)" % [S7B_TO, marked])
	totals.presses += 1
	_key(KEY_E, true)
	await _ticks(1)
	_key(KEY_E, false)
	var on_new := false
	for tick: int in 40:
		await _ticks(1)
		if int(hook.phase) == HANG and hook.attached and anchors.find(Vector3(hook.anchor_point)) == S7B_TO:
			on_new = true
			break
	_check(on_new, "count", tag + "the transfer hangs on anchor %d" % S7B_TO)
	if not on_new:
		_key(KEY_W, false)
		return
	totals.hangs += 1
	var ticks := 0
	var held := true
	var by := ""
	while ticks < 90:
		await _ticks(1)
		ticks += 1
		if int(hook.phase) != HANG or not hook.attached:
			held = false
			by = _line(hero_node, hero_node.global_position + Vector3(0, HAND_Y, 0), anchors[S7B_TO], supports[S7B_TO]).other
			break
		if not hook.get("pulling") and ticks > 1:
			break
	_key(KEY_W, false)
	if not held:
		totals.cut_first += 1
	print("ROPE_CHOICE S7B %s %s held=%s ticks=%d by=%s" % [hero, variant, held, ticks, by if not by.is_empty() else "-"])
	_check(held, "cut", tag + "the transfer to anchor %d held through its pull (cut on tick %d by %s)" % [S7B_TO, ticks, by])
