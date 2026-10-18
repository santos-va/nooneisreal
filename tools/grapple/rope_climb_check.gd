extends SceneTree
## Plan docs/Plans/2026-10-15-Rope-Climb-Perch-Release.md step 5 (15а), ADR-028 п. 1–5 and 8; numbers T5
## docs/GDD/2026-10-15-Rope-Climb-Numbers.md (§ 8 rules), input T8 docs/GDD/2026-10-15-Rope-Climb-Input.md (§ «Як
## перевірити»), pose T6 docs/Art/2026-10-15-Rope-Climb-Animation.md § 3. The production CityWorld, real keys, SOLO.
## Subject: for every street anchor A of the district and both heroes, a rope on A climbed with the held jump reaches the
## 2.0 m limit at no more than 3.6 / 60 m a tick, pulls up onto A's arm in exactly 30 ticks, grips it — the grip point
## y_A + 0.30 ± 0.01, the feet y_A − 1.28 (Choko) / 1.32 (Skea) ± 0.01 (T6 pose, T1; T5 wrote 1.75, docs/Fix/2026-10-15-Rope-Climb-City-Fix.md
## § 0), still — and the rope is back in its owner's stock on that tick, one slot, never two (П-2); on every tick
## available + shot_or_recovery + deployed = capacity for the owner (П-1); the held jump on the grip lifts nothing (Л-в);
## on a bracket each hand (wrist, grip + 0.04) keeps 0.10 m off the axis of the bracket's strut or tie rod (T6 § 3).
## A pull-up whose swept path is blocked keeps the hero at the rope's top: pinned in KNOWN_BLOCKED with the anchor (an
## unpinned block, or a pinned one that no longer happens, fails: `blocked`).
##   --part=K/N (default 1/1): the anchors whose index % N == K − 1, both heroes (--hero= for one).
##   --part=rules: the rest of T8's list for each hero — P9 (a jump held through the attach never climbs; a jump held
##     from the climb never leaps), the grip's 3.0 s (+1 s «Сила») and its drop, Z / X drops, the leap 6.8 / 7.4 m/s with
##     the stick and away from the support without it, E on the grip at a shown anchor (10 ticks of windup with the
##     hands still on the arm, −1 hook, a new hang) and E with nothing shown (drops), the dodge's press taken by the rope
##     (P7) and a fresh dodge in the air after the release (P8), ROPE CLIMB · TOGGLE (P12), G on a rope next to a resident
##     opens no talk (P10), the reel (П-3: time = distance / 9 ± 1 tick, movement × 0.35, a dodge pauses it; П-4: refused
##     past 14 m, behind a wall, with somebody on the rope, for a foreign rope — nothing changes), every new HUD row one
##     line at 1600 × 900 (P13).
##   --part=duel: the duel keeps its rope (T8 § 7): a held dodge on the rope is a dodge (DASH), E with no target keeps the
##     hang and says why, Space stops 1.2 m short of the swing length.
##   --break=double|far|hung (rope_climb_mutants.gd via rope_climb_fighter.gd): the grip refunds two slots, the reel takes
##     a rope 20 m off or behind a wall, the reel takes a rope somebody hangs on; red in `inventory`, `reel_refuse`,
##     `reel_refuse`. --break=duel_flag: the duel's hook gets the city's climb (the canary of T8 § 7): red in `duel`.
##     --break=tie_rod: the far hand back at 0.66 m on the tie-rod brackets 22–24 (0.07 m off the rod): red in `perch`.
##     --break=reel_range: the reel takes a rope up to 16 m off, the line clear (T4 audit 15а RED-2 а): red in `reel_refuse`
##     (П-4 far stands 14.5 m off on a clear line; its control at 13.5 m is offered and reels).
##   P3 (gamepad): Y + X on the rope neither slides nor dashes; X alone slides (control) — `pad`. ROPE CLIMB is HOLD by
##     default as read before the fixture sets a mode — `comfort`.
## T8 acceptance docs/Audit/2026-10-15-T8-Rope-Climb-Input-Acceptance.md (ТЗ 1–6, --part=rules), real InputEventJoypadButton
## / InputEventJoypadMotion where it says pad:
##   the pad on the rope: A held climbs, X held slides with no DASH (P3's control); L3 and Y + LT with nothing shown for
##     ≥ 15 ticks let go, B lets go; on the grip B and D-pad Down drop, X dodges (DASH), A + the stick leaps 6.8 / 7.4 m/s
##     — `pad`; LShift on the grip dodges — `grip`. --break=pad_dash (rope_climb_fighter: the slide reads the held dash
##     too) → `pad` (P3).
##   P7's canary N2: --break=rope_buffer (rope_climb_fighter: the rope's tick no longer takes the dodge's press) → `dodge`.
##   The grip takes the dash's press (ТЗ 6, Skea only — Choko has no air dash without «Spring»): LAlt or Y + X on the grip,
##     B 2 ticks later, no DASH for 8 ticks; a fresh LAlt after the drop flashes (control) — `perch_dash`.
##     --break=perch_flash (rope_climb_fighter: the grip no longer takes it) → `perch_dash`.
##   P10b (ТЗ 1): a street event's passer-by in talk reach (CityEventDirector.in_talk_reach, a precondition) is not talked to
##     while the hook is busy — hanging on a rope, while a rope reels in — and beside the hanging hero the leaves' prompt
##     stays hidden and the real G opens no menu; on the ground with the hook free the same passer-by is (control) —
##     `talk`. --break=passerby (rope_climb_events.gd via CityWorld.events_script: can_talk_to without the hook's check)
##     → `talk`.
##   ROPE CLIMB by real keys (ТЗ 2–3): the pause's COMFORT by Enter, the focus on MASTER, the row's title
##     «ROPE CLIMB · CITY ONLY» (T8's literal), 7 × Down reach the row, Enter · Down · Enter pick TOGGLE (InputRouter and
##     settings.cfg [input] rope_climb), the pad's A · D-pad Up · A pick HOLD; settings.cfg's bytes are kept before the
##     first press and put back (or the file removed) — `comfort`. --break=rope_row (the row's item_selected
##     disconnected, as blood_content_check's drugs_row) → `comfort`.
##   P13 with the pad's glyphs too: the rope's, the grip's and the reel's rows shown after pad presses — `hud`.
## The drawn hero on the same climbs (T6 acceptance docs/Audit/2026-10-15-T6-Rope-Climb-Acceptance.md § 9 п. 2–3, T1): from
## the rope's last tick through the grip's first PERCH_WATCH ticks the body's lean (Hips → Head from vertical) changes at
## most PERCH_TILT_STEP a tick; from the pull-up's SETTLE_TICKS-th tick on it leans at most PERCH_TILT_MAX, and before that
## never more than the rope left it (T6: «за перші 6 тиків звести до вертикалі»; a rope swinging 33° at its top hands the
## body over at 33°) — `perch_tilt`; from the same tick no leg bone comes nearer than LEG_CLEARANCE to the lamp's post box
## (AnchorPost<n>) — `perch_legs`; on the grip the crown (head_end) keeps CROWN_CLEARANCE off the arm's box (AnchorArm<n>)
## — `perch_head`; no bone turns more than BONE_TURN_MAX a tick in skeleton space and the hero's facing turns at most
## FACING_STEP_MAX a tick — `perch_turn`. T6's own stations (anchors 3, 22, 16 from her probe's starts, both heroes) lean
## ≤ 15° on every tick: docs/Fix/2026-10-15-Rope-Perch-Entry-Fix.md § 1.
## The climb itself, drawn (T6 § 9 п. 1): on every climbing tick the drawn cycle (AuthoredHookMotion.reel_cycle) advances at
## most CADENCE_HZ / 60 — `cadence`; the feet clamp in phase, |left − right| height ≤ FEET_APART — `feet_phase`; on a climb
## of ≥ STROKE_TICKS settled ticks (after the first STROKE_SETTLE) the hands' height difference over their shoulders swings
## ≥ 2 × STROKE_AMPLITUDE peak to peak and changes sign — `hand_stroke` (the number of such climbs is printed).
## The rope coming back on the grip, drawn (T6 § 9 п. 6): over the pull-up the tail's free end never goes down and is within
## TAIL_LEFT of the hand on its last tick — `retrieve_tail`; on the grip's tick the stock is +1 (П-2) but the HUD still
## shows the old number; the hook flies RETURN_TICKS ± 1 to the waist, ends within RETURN_GAP of it, and the HUD shows +1
## on the tick it lands — `retrieve_hook`, `retrieve_hud`. --break=tail_stays (the tail drawn at full length on the pull-up)
## → `retrieve_tail`; --break=instant (the HUD +1 on the grip's tick) → `retrieve_hud`.
## The leap off the grip (T6 § 9 п. 5, T1; --part=rules): on anchors LEAP_ANCHORS, with no stick and the stick along the arm
## both ways and across it both ways, for LEAP_WATCH ticks no body bone's centre (hands and forearms aside) lies inside the
## arm's or the ceramic cap's box — `leap_clear`; --break=leap_along (15а's rule: no stick → along the arm) → `leap_clear`.
## The shot from the grip (T6 § 9 п. 7, --part=rules): the hand on the target's side is ≥ THROW_AWAY off its grip point at
## the windup's end, the other ≤ KEEP_ON off its own through the windup and the flight, the rope leaves the throwing hand
## (≤ THROW_ROPE) — `perch_throw`; --break=two_hands (both hands kept on the arm) → `perch_throw`.
## The reel (П-3, T6 § 9 п. 4): after its first REEL_HANDS_SETTLE ticks the drawn rope leaves within REEL_HANDS_GAP of the
## middle of the two hands — `reel_hands`; --break=reel_right (the line from the right hand, as 15а drew it) → `reel_hands`.
##   --break=cadence (climb_cadence_hz 0: 5.5 Hz again) → `cadence`; --break=stroke (climb_stroke off) → `hand_stroke`;
##   --break=antiphase (feet_in_phase off) → `feet_phase`.
##   --break=flag (HeroBodyMotion.perch_upright off: the rope's lean on the pull-up, 15а as T6 saw it) → `perch_tilt`;
##   --break=head (perch_head_back 0) → `perch_head`; --break=snap (rope_climb_fighter: no turn toward the arm, the grip
##   flips the facing) → `perch_turn`; --break=elbow (AuthoredHookMotion.arm_continuity off) → `perch_turn`.
## The drawn surface (T6's re-acceptance after T2-М, docs/Audit/2026-10-15-T6-Rope-Climb-Acceptance.md; the bone centres
## above miss the hair and the sleeves): rope_mesh_clearance.gd skins every vertex of the hero (T6's probe formula) and
## counts those strictly inside the support's boxes. On every climb: on each pull-up tick no head, torso or upper-arm
## vertex inside the ceramic cap or the arm (AnchorCeramic<n>, AnchorArm<n>) — `pull_ceramic`; on each of the grip's first
## PERCH_WATCH ticks no head vertex inside them — `perch_head_mesh`; on both, on a bracket, no vertex at all inside its strut
## or tie rod (AnchorStrut<n>) — `sleeve_strut`. On the leaps (--part=rules, beside `leap_clear`): no head, torso,
## upper-arm or leg vertex inside the arm or its cap for LEAP_WATCH ticks, except the leaps pinned in KNOWN_LEAP_SURFACE,
## which stay within their pin and must still happen — `leap_mesh`. The time it costs is printed («ROPE_CLIMB surface»).
##   --break=body_near (Skea back at T2-М's 0.14: PERCH_BODY_BACK_MORE taken off perch_body_back) → `perch_head_mesh` (and
##   `pull_ceramic`, `sleeve_strut`; on --part=rules `leap_mesh`); --break=pull_first (pull_up_duck 0: 15а's path, up to the
##   grip's height under the cap, then across) → `pull_ceramic`; --break=strut_far (the far hand back at 0.66 on the struts
##   from below) → `sleeve_strut`. --break=head and --break=flag turn `perch_head_mesh` red too, --break=leap_along `leap_mesh`.
## T4's re-audit of 15а (docs/Audit/2026-10-15-Rope-Climb-15a-Recheck.md, T2-С docs/Fix/2026-10-15-Rope-Recheck-Yellow-Fix.md):
##   Y-A: the rope takes the dash's press too (T8 § 3; Skea only, as `perch_dash`): LAlt or Y + X on the rope, B 2 ticks later,
##     no DASH for 8 ticks; a fresh LAlt after the let-go flashes (control) — `rope_dash`. --break=hang_flash
##     (rope_climb_fighter: the rope's tick no longer takes the dash, the grip still does) → `rope_dash`.
##   Y-B: P10b for every street event — the leaves', the alley's asker and the pedlar beside the hanging hero: the prompt stays
##     hidden, the real G opens no menu — `talk`. --break=alley_reach / vendor_reach (rope_climb_events.gd: that event's
##     prompt asks the reach alone, as T4's product mutants) → `talk`.
##   Y-C: the climb's lower bound — every climbing tick that does not end at the 2.0 m limit shortens at least
##     (CLIMB_SPEED − RATE_TOLERANCE) / 60 — `climb_rate`; --break=climb_slow (GrappleHook.climb_speed 3.0) → `climb_rate`.
##     The slide's lower bound lives in rope_pull_check (`sliderate`).
##   Y-E: a pinned leap (KNOWN_LEAP_SURFACE) also pins which boxes and groups enter (box:group, every tick of the leap); a pin
##     the run never visited fails `count`.
##   Y-F: П-4 far's preconditions (the spot found, 14.5 m on a clear line) are `count`, not `reel_refuse`.
## Sentinel: ROPE_CLIMB_COMPLETE checks=N failures=M mutation=<m> part=<p> anchors=a/A perched=p blocked=b red=<families|none>.
const RINGS: Array[float] = [2.5, 4.0, 6.0, 8.0]
const BEARINGS: int = 8
const HAND_Y: float = 1.25          # GrappleHook.HAND
const ABOVE: float = 1.5            # the traversal's 1.5 m over the hand
const CLEARANCE: float = 1.8
const CLIMB_SPEED: float = 3.6      # T5 Л1
## The climb's lower bound (T4 re-audit 15а Y-C): T5 § 8 Л-а gives the upper bound only (3.6 / 60 + 1e-6 a tick); the
## tolerance below it is T1's brief for T2-С, «3.6 ± 0.1», as T5 gave no other.
const RATE_TOLERANCE: float = 0.1
const MIN_ROPE: float = 2.0         # T5 Л2
const PULL_UP_TICKS: int = 30       # T5 Л3
const GRIP_RISE: float = 0.30       # T5 Л4
const FEET_BELOW: Dictionary = {"choko": 1.28, "skea": 1.32} # T6 § 3; per hero — T1 on T6 acceptance § 9 п. 8
const PERCH_SECONDS: float = 3.0    # T5 З1
const STRENGTH_BONUS: float = 1.0   # T5 З1 «Сила»
const LEAP_OUT: float = 6.8         # T5 З3
const LEAP_UP: float = 7.4
const WINDUP_TICKS: int = 10        # T5 § 3.2 (parkour_windup_frames)
const REWIND_SPEED: float = 9.0     # T5 П4
const RECOVERY_MOVE: float = 0.35   # T5 П4
const REEL_RANGE: float = 14.0      # T5 П3
const HINT_WIDTH: float = 1552.0    # T8 § 4: 1600 − 48 logical px, font 18
const WRIST_RISE: float = 0.04      # AuthoredHookMotion.PERCH_WRIST: the wrist over the grip point
const BRACE_CLEARANCE: float = 0.10 # T6 § 3: the struts from below keep 0.10 m to the far hand; the tie rods the same
const PERCH_TILT_MAX: float = 15.0  # T6 acceptance § 9 п. 2 / T1: Hips → Head from vertical, every pull-up and grip tick
const PERCH_TILT_STEP: float = 10.0 # the same: its change in one tick
const LEG_CLEARANCE: float = 0.05   # the same: a leg bone off the post's box
const CROWN_CLEARANCE: float = 0.03 # T6 § 9 п. 3: head_end off the arm's box on the grip
const BONE_TURN_MAX: float = 30.0   # anim_traversal_check TURN_LIMIT: skeleton-space turn of any hero bone in one tick
const FACING_STEP_MAX: float = 10.0 # the hero's facing in one tick (HeroBodyMotion.BODY_TURN_RATE is 7°)
const PERCH_WATCH: int = 40         # grip ticks the drawn pose is watched
const SETTLE_TICKS: int = 6         # T6 § 9 п. 2: the pull-up's first ticks bring the rope's lean to vertical
const REEL_HANDS_GAP: float = 0.03  # T6 § 9 п. 4: the reeled rope's drawn start off the middle of the two hands
const TAIL_LEFT: float = 0.30       # T6 § 9 п. 6: the tail below the hand on the pull-up's last tick
const THROW_AWAY: float = 0.20      # T6 § 9 п. 7: the throwing hand off its grip point at the windup's end
const LEAP_ANCHORS: Array[int] = [3, 22, 16] # T6 § 9: the lamp and the two brackets she judged
const LEAP_WATCH: int = 14          # ticks after the leap's press T6 counted
const LEAP_ACROSS: float = 0.5      # CityFighter.PERCH_LEAP_ACROSS: the rule's literal (PLACEHOLDER, T5 / T8)
const KEEP_ON: float = 0.10         # the same: the other hand off its grip point (Choko's IK falls 0.05–0.08 short)
const THROW_ROPE: float = 0.05      # the same: the rope's drawn start off the throwing hand in flight
const RETURN_TICKS: int = 15        # the same: the hook's arc to the waist ≈ 0.25 s
const RETURN_GAP: float = 0.20      # the hook's last drawn point off the waist (hero + 0.95 m)
const REEL_HANDS_SETTLE: int = 6    # reel ticks while Fish_Reel comes in (the line is drawn from the pose of the tick before)
const CADENCE_HZ: float = 2.0       # T6 § 9 п. 1: the climb's drawn cycle at most 2.0 Hz
const FEET_APART: float = 0.05      # the same: |left foot − right foot| height while the feet clamp
const STROKE_AMPLITUDE: float = 0.20 # the same: the hands' height difference swings at least ±0.20 m
const STROKE_SETTLE: int = 15       # climbing ticks the stroke takes to deepen (the elbow's pole turns, 0.3 s)
const STROKE_TICKS: int = 25        # settled climbing ticks judged: more than a half cycle at 2.0 Hz (15 ticks)
const HANG := 3
const MISS_REWIND := 4
const CLIMB_TOP := 7
const PERCH := 8
const STATE_IDLE := 1
const STATE_JUMP := 4
const STATE_DASH := 5
const STATE_GRAPPLE := 13
const SETTINGS := "user://settings.cfg" # InputRouter.SETTINGS_PATH
const COMFORT_DOWNS := 7            # T8 acceptance § 5 F2: Down × 7 from MASTER (the focus at open) reach ROPE CLIMB
const ROPE_CLIMB_TITLE := "ROPE CLIMB · CITY ONLY" # T8 acceptance § 3, С2 (ComfortPanel.ROPE_CLIMB_TITLE)
## Pull-ups blocked on their swept path (measured on 2026-10-15, docs/Fix/2026-10-15-Rope-Climb-City-Fix.md § 3):
## "<hero>|<anchor>" → why. None so far.
const KNOWN_BLOCKED: Dictionary = {}
## The leaps off the grip whose drawn surface still enters the arm or its cap (T6's re-acceptance 2026-10-15; docs/Fix/
## 2026-10-15-Rope-Perch-Mesh-Clearance-Fix.md § 6): "hero|anchor|stick" → [ticks of LEAP_WATCH, deepest m], measured on
## this code. Along the arm toward its free end (along+) the torso / legs pass the ceramic cap — the rule's 0.5 across
## (CityFighter.PERCH_LEAP_ACROSS, T5 / T8); Skea's upper arm rises into the arm on the first ticks (the grip's elbow under
## the arm's back edge, T6's pose). For T1: either is a decision, not a fix here. A pinned leap that gets worse (more ticks,
## deeper than LEAP_PIN_SLACK past its pin) or no longer happens fails `leap_mesh`; every other leap stays at 0.
## The third item (T4 re-audit 15а Y-E) is every «box:group» that entered on any tick of the leap, measured on this code
## (docs/Fix/2026-10-15-Rope-Recheck-Yellow-Fix.md § 4): a box or a group outside it — the head where the upper arm was, the
## cap where the arm was — fails `leap_mesh` whatever the ticks and the depth; a pin the run never judged fails `count`.
const KNOWN_LEAP_SURFACE: Dictionary = {
	"choko|16|along+": [1, 0.012, ["Ceramic:leg"]],
	"skea|3|along+": [4, 0.066, ["Arm:upperarm", "Ceramic:torso"]],
	"skea|3|along-": [3, 0.030, ["Arm:upperarm", "Ceramic:upperarm"]],
	"skea|22|none": [1, 0.001, ["Arm:upperarm"]],
	"skea|22|along+": [4, 0.063, ["Arm:upperarm", "Ceramic:torso"]],
	"skea|22|along-": [2, 0.036, ["Arm:upperarm"]],
	"skea|16|none": [1, 0.004, ["Arm:upperarm"]],
	"skea|16|along+": [2, 0.044, ["Arm:upperarm", "Ceramic:torso", "Ceramic:upperarm"]],
	"skea|16|along-": [3, 0.064, ["Arm:upperarm"]],
}
const LEAP_PIN_SLACK: float = 0.003
var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var only_hero: String = ""
var part_label: String = "1/1"
var part: int = 1
var parts: int = 1
var red: Dictionary = {}
var router: Node
var supports: Array[Dictionary] = []
var totals := {"anchors": 0, "sampled": 0, "perched": 0, "blocked": 0}
var seen_blocked: Dictionary = {}
var _pose_previous: Dictionary = {}
## The drawn surface (rope_mesh_clearance.gd), set up for each hero's district; the time it took, for the cost line.
var mesh_clearance: RefCounted = null
var mesh_usec: int = 0
var mesh_ticks: int = 0
var climb_default: String = ""
var stroke_climbs: int = 0


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
		elif argument.begins_with("--hero="):
			only_hero = argument.trim_prefix("--hero=")
		elif argument.begins_with("--part="):
			part_label = argument.trim_prefix("--part=")
			if part_label.contains("/"):
				part = int(part_label.get_slice("/", 0))
				parts = maxi(1, int(part_label.get_slice("/", 1)))
	_run.call_deferred()


func _check(ok: bool, family: String, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		red[family] = true
		push_error("ROPE_CLIMB: [%s] %s" % [family, label])


func _ticks(count: int) -> void:
	for tick: int in count:
		await physics_frame
		await process_frame


func _key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	if code == KEY_SHIFT or code == KEY_ALT:
		event.location = KEY_LOCATION_LEFT
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()


## The leap's horizontal direction by the rule (see CityFighter.perch_leap_direction): no stick — square to the arm, away
## from it; a stick — its part across the arm, away from it, at least LEAP_ACROSS.
static func _leap_expected(stick: Vector3, facing: Vector3) -> Vector3:
	var away := Vector3(-facing.x, 0.0, -facing.z).normalized()
	if stick.length() < 0.4:
		return away
	var wanted := stick.normalized()
	var across := wanted.dot(away)
	return wanted if across >= LEAP_ACROSS else (wanted - away * across + away * LEAP_ACROSS).normalized()


func _leap_clear(world: Node, hero: String) -> void:
	var hero_node: CharacterBody3D = world.player
	var hook: Node = hero_node.grapple
	var skeleton: Skeleton3D = hero_node.skeletal.hero_skeleton
	var judged_pins: Dictionary = {}
	for index: int in LEAP_ANCHORS:
		for stick: String in ["none", "along+", "along-", "away", "toward"]:
			if not await _perch_on(world, index):
				_check(false, "count", "[%s] anchor %d: the leap's grip (%s)" % [hero, index, stick])
				continue
			_key(KEY_SPACE, false)
			var pose: Dictionary = hook.perch_pose
			var arm_dir: Vector3 = Vector3(pose.away)
			# The camera looks along the arm, toward its free end: W/S along the arm, A/D across it.
			world.camera_rig.aim.yaw_offset = atan2(-arm_dir.x, -arm_dir.z)
			await _ticks(4)
			var code: Key = {"none": KEY_NONE, "along+": KEY_W, "along-": KEY_S, "away": KEY_A, "toward": KEY_D}[stick]
			var away := Vector3(-Vector3(pose.facing).x, 0, -Vector3(pose.facing).z).normalized()
			if code != KEY_NONE:
				_key(code, true)
				await _ticks(2)
				var wish := Vector3(hero_node.wish().x, 0, hero_node.wish().z).normalized()
				# The precondition: the stick points where the case says (A/D map to either side; the side is read back).
				var meant: bool = (stick.begins_with("along") and absf(wish.dot(arm_dir)) >= 0.9) or (not stick.begins_with("along") and absf(wish.dot(away)) >= 0.9)
				_check(meant, "count", "[%s] anchor %d: the stick %s points along / across the arm (wish %s, arm %s)" % [hero, index, stick, wish, arm_dir])
			_key(KEY_SPACE, true)
			var inside := 0
			var worst := ""
			var surface_ticks := 0
			var surface_depth := 0.0
			var surface_worst := "-"
			# Every «box:group» that entered on any tick (Arm / Ceramic, the anchor's number dropped: the key holds it).
			var surface_boxes: Dictionary = {}
			var boxes: Array = [world.district.get_node_or_null("AnchorArm%d" % index), world.district.get_node_or_null("AnchorCeramic%d" % index)]
			for tick: int in LEAP_WATCH:
				await _ticks(1)
				if tick == 0:
					_key(KEY_SPACE, false)
				# T6's re-acceptance 2026-10-15: the skinned surface beside the bone centres — head, torso, upper arms and legs
				# (the hands and forearms leave the arm on the leap's first ticks, as below).
				var started: int = Time.get_ticks_usec()
				var surface: Dictionary = mesh_clearance.count(boxes, ["head", "torso", "upperarm", "leg"])
				mesh_usec += Time.get_ticks_usec() - started
				mesh_ticks += 1
				if mesh_clearance.inside(surface) > 0:
					surface_ticks += 1
					var deepest := 0.0
					for box: String in surface:
						deepest = maxf(deepest, float(surface[box].depth))
						for group: String in mesh_clearance.GROUPS:
							if int(surface[box].get(group, 0)) > 0:
								surface_boxes["%s:%s" % [box.trim_prefix("Anchor").rstrip("0123456789"), group]] = true
					if deepest >= surface_depth:
						surface_depth = deepest
						surface_worst = "tick %d: %s" % [tick, mesh_clearance.describe(surface)]
				var hits: Array[String] = []
				for target: String in ["AnchorArm%d" % index, "AnchorCeramic%d" % index]:
					var box := world.district.get_node_or_null(target) as Node3D
					if box == null:
						continue
					for bone: int in skeleton.get_bone_count():
						var name: String = skeleton.get_bone_name(bone)
						if name.contains("Hand") or name.contains("ForeArm"):
							continue
						if _box_gap(box, skeleton.global_transform * skeleton.get_bone_global_pose(bone).origin) <= 0.0:
							hits.append("%s@%s" % [name, target])
				if not hits.is_empty():
					inside += 1
					worst = str(hits.slice(0, 4))
			if code != KEY_NONE:
				_key(code, false)
			_check(inside == 0, "leap_clear", "[%s] anchor %d: T6 § 9 п. 5: the leap (%s) carries a body bone through the arm or its cap on %d of %d ticks (%s)" % [hero, index, stick, inside, LEAP_WATCH, worst])
			var pin_key := "%s|%d|%s" % [hero, index, stick]
			var entered: Array = surface_boxes.keys()
			entered.sort()
			if KNOWN_LEAP_SURFACE.has(pin_key):
				judged_pins[pin_key] = true
				var ceiling: Array = KNOWN_LEAP_SURFACE[pin_key]
				_check(surface_ticks > 0, "leap_mesh", "[%s] anchor %d: the pinned leap (%s) no longer enters the arm or its cap: look at it and unpin it" % [hero, index, stick])
				_check(surface_ticks <= int(ceiling[0]) and surface_depth <= float(ceiling[1]) + LEAP_PIN_SLACK, "leap_mesh", "[%s] anchor %d: the pinned leap (%s) enters the arm or its cap on %d of %d ticks, %.3f m deep (%s); pinned at %d ticks, %.3f m" % [hero, index, stick, surface_ticks, LEAP_WATCH, surface_depth, surface_worst, ceiling[0], ceiling[1]])
				# T4 re-audit 15а Y-E: the same ticks and depth by another box or group is another leap.
				var stray: Array[String] = []
				for pair: String in entered:
					if not (ceiling[2] as Array).has(pair):
						stray.append(pair)
				_check(stray.is_empty(), "leap_mesh", "[%s] anchor %d: the pinned leap (%s) enters by %s, pinned %s only (outside the pin: %s)" % [hero, index, stick, entered, ceiling[2], stray])
			else:
				_check(surface_ticks == 0, "leap_mesh", "[%s] anchor %d: T6 re-acceptance: the leap (%s) carries the drawn head / torso / upper arms / legs into the arm or its cap on %d of %d ticks, %.3f m deep (%s)" % [hero, index, stick, surface_ticks, LEAP_WATCH, surface_depth, surface_worst])
			print("ROPE_CLIMB_LEAP %s anchor=%d stick=%s inside=%d surface=%d depth=%.3f (%s) boxes=%s v=%s" % [hero, index, stick, inside, surface_ticks, surface_depth, surface_worst, ",".join(entered) if not entered.is_empty() else "-", hero_node.velocity])
			await _ticks(40)
	# T4 re-audit 15а Y-E: a pin the run never judged (LEAP_ANCHORS changed, a grip that failed) guards nothing.
	for pin_key: String in KNOWN_LEAP_SURFACE:
		if pin_key.begins_with(hero + "|"):
			_check(judged_pins.has(pin_key), "count", "[%s] the pinned leap «%s» was judged (LEAP_ANCHORS %s)" % [hero, pin_key, LEAP_ANCHORS])


func _pad(button: JoyButton, down: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _pad_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _tap_pad(button: JoyButton) -> void:
	_pad(button, true)
	await _ticks(1)
	_pad(button, false)


## Every pad button and axis the rules press, released: a pad scenario starts and ends at neutral.
func _pad_neutral() -> void:
	for button: JoyButton in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_LEFT_STICK, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_UP]:
		_pad(button, false)
	_pad_axis(JOY_AXIS_LEFT_X, 0.0)
	_pad_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)


func _tap(code: Key) -> void:
	_key(code, true)
	await _ticks(1)
	_key(code, false)


func _run() -> void:
	await process_frame
	router = root.get_node("InputRouter")
	# T8 § 5: HOLD by default — read before this fixture sets a mode itself (T4 audit 15а Y3).
	climb_default = String(router.rope_climb)
	supports = load("res://scripts/world/CityLayout.gd").anchor_supports()
	var state: Node = root.get_node("GameState")
	state.set_free_move(true)
	state.water = null
	if part_label == "duel":
		await _duel()
	else:
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
	if mutation == "none" and part_label.contains("/"):
		_check(int(totals.sampled) == int(totals.anchors) and int(totals.anchors) > 0, "count", "every anchor of the part found a standing start: %d of %d" % [totals.sampled, totals.anchors])
		for key: String in KNOWN_BLOCKED:
			var anchor := int(key.get_slice("|", 1))
			if anchor % parts == part - 1 and (only_hero.is_empty() or key.begins_with(only_hero + "|")):
				_check(seen_blocked.has(key), "blocked", "the pinned blocked pull-up «%s» (%s) no longer happens: look at it and unpin it" % [key, KNOWN_BLOCKED[key]])
	if part_label.contains("/"):
		print("ROPE_CLIMB stroke judged on %d climbs of %d ticks or more" % [stroke_climbs, STROKE_TICKS])
		if mutation == "none":
			_check(stroke_climbs > 0, "hand_stroke", "the hands' stroke was judged on at least one climb of the part (%d)" % stroke_climbs)
	var families: Array = red.keys()
	families.sort()
	print("ROPE_CLIMB frames=%d (the playable harness quits after 12000)" % Engine.get_process_frames())
	print("ROPE_CLIMB surface %d ticks, %.1f s, %.1f ms a tick (rope_mesh_clearance.gd)" % [mesh_ticks, mesh_usec / 1000000.0, mesh_usec / 1000.0 / maxf(mesh_ticks, 1)])
	print("ROPE_CLIMB_COMPLETE checks=%d failures=%d mutation=%s part=%s anchors=%d/%d perched=%d blocked=%d red=%s" % [
		checks, failures, mutation, part_label, totals.sampled, totals.anchors, totals.perched, totals.blocked,
		",".join(families) if not families.is_empty() else "none"])
	quit(1 if failures else 0)


func _district(hero: String) -> void:
	var state: Node = root.get_node("GameState")
	state.p1_character = hero
	router.apply_profile("solo", false)
	router.set_rope_climb("hold", false)
	var world: Node = load("res://scenes/world/CityWorld.tscn").instantiate()
	world.story_save_enabled = false
	world.journey_save_enabled = false
	world.lower_story_save_enabled = false
	if mutation in ["double", "far", "hung", "snap", "reel_range", "reel_right", "tail_stays", "instant", "leap_along", "rope_buffer", "perch_flash", "pad_dash", "hang_flash"]:
		Engine.set_meta("rope_climb_mutation", mutation)
		world.fighter_script = load((get_script() as Script).resource_path.get_base_dir().path_join("rope_climb_fighter.gd"))
	if mutation in ["passerby", "alley_reach", "vendor_reach"]:
		Engine.set_meta("rope_climb_mutation", mutation)
		world.events_script = load((get_script() as Script).resource_path.get_base_dir().path_join("rope_climb_events.gd"))
	root.add_child(world)
	current_scene = world
	world.progress.save_enabled = false
	world.npc_director.save_enabled = false
	world.npc_director.process_mode = Node.PROCESS_MODE_DISABLED
	await _ticks(40)
	world.onboarding.skip()
	mesh_clearance = load((get_script() as Script).resource_path.get_base_dir().path_join("rope_mesh_clearance.gd")).new()
	_check(int(mesh_clearance.setup(world.player)) > 0 and int(mesh_clearance.vertices) > 0, "count", "[%s] the hero's skinned surface is found (%d vertices)" % [hero, mesh_clearance.vertices])
	if mutation == "body_near":
		world.player.grapple.perch_body_back -= float(world.player.grapple.PERCH_BODY_BACK_MORE.get(hero, 0.0))
	if mutation == "pull_first":
		world.player.grapple.pull_up_duck = 0.0
	if mutation == "climb_slow":
		# T4 re-audit 15а Y-C: the climb at 3.0 m/s (T4's mutant `climb_30`), under the lower bound 3.5.
		world.player.grapple.climb_speed = 3.0
	if mutation == "strut_far":
		world.player.grapple.perch_strut_far = world.player.grapple.perch_grip_far
	if mutation == "tie_rod":
		world.player.grapple.perch_tie_rod_far = world.player.grapple.perch_grip_far
	if mutation == "flag":
		world.player.skeletal.body_motion.perch_upright = false
	if mutation == "head":
		world.player.skeletal.body_motion.perch_head_back = 0.0
	if mutation == "elbow":
		world.player.skeletal.authored_hook.arm_continuity = false
	if mutation == "cadence":
		world.player.skeletal.authored_hook.climb_cadence_hz = 0.0
	if mutation == "stroke":
		world.player.skeletal.authored_hook.climb_stroke = false
	if mutation == "antiphase":
		world.player.skeletal.authored_hook.feet_in_phase = false
	if mutation == "two_hands":
		world.player.skeletal.authored_hook.one_hand_throw = false
	if part_label == "rules":
		await _rules(world, hero)
	else:
		for index: int in supports.size():
			if index % parts == part - 1:
				await _climb_anchor(world, hero, index)
	world.queue_free()
	current_scene = null
	await _ticks(3)


# --- helpers ---------------------------------------------------------------------------------------------------------

func _reset(world: Node, at: Vector3, toward: Vector3) -> void:
	var hero_node: Node3D = world.player
	for code: Key in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SPACE, KEY_SHIFT, KEY_E, KEY_Z, KEY_X, KEY_G, KEY_F]:
		_key(code, false)
	hero_node.grapple.detach()
	world.ropes.clear_match()
	await _ticks(1)
	hero_node.restart_at(at)
	var view := Vector3(toward.x - at.x, 0, toward.z - at.z)
	if view.length() > 0.01:
		hero_node._set_forward(view.normalized())
	world.camera_rig.reset_view()
	world.camera_rig.aim.yaw_offset = atan2(-view.x, -view.z) if view.length() > 0.01 else 0.0
	await _ticks(4)


## A shot at `index` through the product's recorded-aim path (the replay's packet; no selection), the state as
## Fighter._try_grapple sets it. True when the hook holds A.
func _hang_on(world: Node, index: int) -> bool:
	var hero_node: Node = world.player
	var hook: Node = hero_node.grapple
	var marker: Node3D = world.district.get_node("StreetAnchor%d" % index)
	var target: int = hook.fire(false, "grapple_parkour", {"point": marker.global_position, "target_id": String(marker.get_path())})
	if target == 0:
		return false
	hero_node._set_state(STATE_GRAPPLE)
	for tick: int in 60:
		await _ticks(1)
		if hook.phase == HANG and hook.attached:
			return Vector3(hook.anchor_point).is_equal_approx(marker.global_position)
		if hook.phase == 0 or hook.phase == MISS_REWIND:
			return false
	return false


## Standing starts for anchor `index`, in ring order (RINGS × BEARINGS): on a floor with headroom, the hand seeing the
## anchor within the hook's range, 1.5 m under it. At most `limit`.
func _starts_for(world: Node, index: int, limit: int = 6) -> Array[Vector3]:
	var found: Array[Vector3] = []
	var space: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state
	var point: Vector3 = supports[index].point
	var range_m: float = world.player.grapple.range_m
	for radius: float in RINGS:
		for bearing: int in BEARINGS:
			var angle := TAU * float(bearing) / float(BEARINGS)
			var x := point.x + cos(angle) * radius
			var z := point.z + sin(angle) * radius
			var top := point.y - ABOVE - HAND_Y
			var from_y := top + CLEARANCE
			for guard: int in 8:
				var hit := _ray(space, Vector3(x, from_y, z), Vector3(x, -1.0, z), 1)
				if hit.is_empty():
					break
				var y: float = hit.position.y
				from_y = y - 0.02
				if y > top or Vector3(hit.normal).y < 0.7:
					continue
				if not _ray(space, Vector3(x, y + 0.05, z), Vector3(x, y + CLEARANCE, z), 1).is_empty():
					continue
				var hand := Vector3(x, y + HAND_Y, z)
				if hand.distance_to(point) <= range_m - 0.5 and _ray(space, hand, point, 8 | 1).is_empty():
					found.append(Vector3(x, y, z))
					if found.size() >= limit:
						return found
	return found


func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, mask: int) -> Dictionary:
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, mask))


## П-1: available + shot_or_recovery + deployed = capacity for player 1 (the hook's stock is available()).
func _inventory_ok(world: Node) -> bool:
	var ropes: Node = world.ropes
	var issued := 0
	var deployed := 0
	for record: Dictionary in ropes.records.values():
		if int(record.owner) == 1:
			if bool(record.deployed):
				deployed += 1
			else:
				issued += 1
	return world.player.grapple.charges + issued + deployed == int(world.player.data.grapple_charges)


func _settle_pull(hook: Node) -> void:
	for tick: int in 90:
		await _ticks(1)
		if not hook.get("pulling") and tick > 1:
			return


# --- the climb on every anchor ----------------------------------------------------------------------------------------

func _climb_anchor(world: Node, hero: String, index: int) -> void:
	totals.anchors += 1
	var point: Vector3 = supports[index].point
	var tag := "[%s] anchor %d %s: " % [hero, index, point]
	var start := Vector3.INF
	for candidate: Vector3 in _starts_for(world, index):
		await _reset(world, candidate, point)
		if await _hang_on(world, index):
			start = candidate
			break
	if not start.is_finite():
		_check(false, "count", tag + "no standing start hangs on it")
		return
	totals.sampled += 1
	var hero_node: CharacterBody3D = world.player
	var hook: Node = hero_node.grapple
	await _settle_pull(hook)
	var token: int = hook._deployed_token
	var stock_before: int = hook.charges
	_key(KEY_SPACE, true)
	var drawn: Dictionary = {"tilt": 0.0, "tilt_at": "", "entry": 0.0, "excess": 0.0, "excess_at": "", "step": 0.0, "step_at": "", "legs": INF, "legs_at": "", "legs_settling": INF, "crown": INF, "crown_at": "", "turn": 0.0, "turn_at": "", "facing": 0.0, "facing_at": "", "pull_n": 0, "pull_at": "-", "pull_ticks": 0, "head_n": 0, "head_at": "-", "head_ticks": 0, "strut_n": 0, "strut_at": "-", "strut_ticks": 0}
	_pose_previous.clear()
	_pose_sample(world, index, drawn, -1)
	var skeleton: Skeleton3D = hero_node.skeletal.hero_skeleton
	var authored: Variant = hero_node.skeletal.authored_hook
	var cycle_before: float = float(authored.reel_cycle)
	var cycle_step := 0.0
	var feet_apart := 0.0
	var climbing_ticks := 0
	var stroke: Array[float] = []
	var previous: float = hook.rope_length
	var rate_ok := true
	# T4 re-audit 15а Y-C: the climbing ticks that do not end at the limit (the last one is cut to it) and the slowest of them.
	var full_ticks := 0
	var slowest := INF
	var slowest_at := -1
	var inventory_ok := true
	var reached := -1
	var began := -1
	var ticks := 0
	while ticks < 240:
		await _ticks(1)
		ticks += 1
		inventory_ok = inventory_ok and _inventory_ok(world)
		_pose_sample(world, index, drawn, 0 if hook.phase in [CLIMB_TOP, PERCH] else -1)
		if hook.phase == HANG and hook.get("climbing"):
			climbing_ticks += 1
			cycle_step = maxf(cycle_step, float(authored.reel_cycle) - cycle_before)
			if float(authored._clamp_mix) >= 0.999:
				feet_apart = maxf(feet_apart, absf(_bone_world(skeleton, "LeftFoot").y - _bone_world(skeleton, "RightFoot").y))
			if climbing_ticks > STROKE_SETTLE:
				stroke.append((_bone_world(skeleton, "LeftHand").y - _bone_world(skeleton, "LeftArm").y) - (_bone_world(skeleton, "RightHand").y - _bone_world(skeleton, "RightArm").y))
		cycle_before = float(authored.reel_cycle)
		if hook.phase != HANG:
			began = ticks
			break
		var shorten: float = previous - hook.rope_length
		rate_ok = rate_ok and shorten <= CLIMB_SPEED / 60.0 + 0.000001 and hook.rope_length >= MIN_ROPE - 0.000001
		if hook.get("climbing") and hook.rope_length > MIN_ROPE + 0.000001:
			full_ticks += 1
			if shorten < slowest:
				slowest = shorten
				slowest_at = ticks
		if reached < 0 and hook.rope_length <= MIN_ROPE + 0.000001:
			reached = ticks
		if hook.get("climb_blocked"):
			break
		previous = hook.rope_length
	_check(rate_ok, "climb_rate", tag + "Л-а: the climb shortened at most %.4f m a tick, never under %.1f" % [CLIMB_SPEED / 60.0, MIN_ROPE])
	_check(full_ticks > 0, "count", tag + "Y-C: the climb was judged on at least one tick short of the limit (%d)" % full_ticks)
	_check(full_ticks == 0 or slowest >= (CLIMB_SPEED - RATE_TOLERANCE) / 60.0 - 0.000001, "climb_rate", tag + "Y-C: every climbing tick short of the limit shortened at least %.5f m (%.1f m/s); the slowest %.5f on tick %d of %d" % [(CLIMB_SPEED - RATE_TOLERANCE) / 60.0, CLIMB_SPEED - RATE_TOLERANCE, slowest, slowest_at, full_ticks])
	print("ROPE_CLIMB_RATE %s anchor=%d full=%d slowest=%s" % [hero, index, full_ticks, "-" if full_ticks == 0 else "%.6f" % slowest])
	_check(cycle_step <= CADENCE_HZ / 60.0 + 0.000001, "cadence", tag + "T6 § 9 п. 1: the drawn climb cycle advanced %.4f a tick (%.2f Hz), at most %.1f Hz" % [cycle_step, cycle_step * 60.0, CADENCE_HZ])
	_check(feet_apart <= FEET_APART, "feet_phase", tag + "T6 § 9 п. 1: the clamping feet %.3f m apart in height, at most %.2f (in phase)" % [feet_apart, FEET_APART])
	if stroke.size() >= STROKE_TICKS:
		stroke_climbs += 1
		var signs := 0
		for k: int in range(1, stroke.size()):
			if stroke[k] * stroke[k - 1] < 0.0:
				signs += 1
		_check(stroke.max() - stroke.min() >= 2.0 * STROKE_AMPLITUDE and signs >= 1, "hand_stroke", tag + "T6 § 9 п. 1: the hands' height difference swings %.3f m peak to peak (at least %.2f), changing sign %d times (at least once a half cycle) over %d settled climbing ticks" % [stroke.max() - stroke.min(), 2.0 * STROKE_AMPLITUDE, signs, stroke.size()])
	var key := "%s|%d" % [hero, index]
	if hook.phase == HANG and hook.get("climb_blocked"):
		totals.blocked += 1
		seen_blocked[key] = true
		print("ROPE_CLIMB BLOCKED %s L=%.4f at %s" % [key, hook.rope_length, hero_node.global_position])
		_check(KNOWN_BLOCKED.has(key) or mutation != "none", "blocked", tag + "the pull-up onto the arm is blocked at the rope's top (not pinned)")
		_key(KEY_SPACE, false)
		return
	_check(began > 0 and hook.phase == CLIMB_TOP and absf(hook.rope_length - MIN_ROPE) <= 0.000001, "climb_rate", tag + "Л-а: the pull-up began at %.1f m (phase %d, L %.6f, tick %d)" % [MIN_ROPE, hook.phase, hook.rope_length, began])
	var pull_up := 0
	# The pull-up's corners (GrappleHook._climb_path): 4 — under the cap, 3 — 15а's path taken as the fallback.
	var way: int = (hook.get("_climb_way") as Array).size() if hook.get("_climb_way") != null else 0
	var tail_end := -INF
	var tail_drop := 0.0
	var tail_last := INF
	while hook.phase == CLIMB_TOP and pull_up < PULL_UP_TICKS + 10:
		await _ticks(1)
		pull_up += 1
		inventory_ok = inventory_ok and _inventory_ok(world)
		_pose_sample(world, index, drawn, pull_up)
		_mesh_sample(world, index, drawn, pull_up)
		var tail: Node = hook._tail_visual
		if hook.phase == CLIMB_TOP:
			if tail != null and tail.visible and not tail.points.is_empty():
				var low: float = Vector3(tail.points[tail.points.size() - 1]).y
				tail_drop = maxf(tail_drop, tail_end - low)
				tail_end = maxf(tail_end, low)
				tail_last = Vector3(tail.points[0]).distance_to(Vector3(tail.points[tail.points.size() - 1]))
			else:
				tail_last = 0.0
	var pose: Dictionary = hook.perch_pose
	_check(hook.phase == PERCH and pull_up == PULL_UP_TICKS, "perch", tag + "Л-б: %d ticks of pull-up, expected %d, then the grip (phase %d)" % [pull_up, PULL_UP_TICKS, hook.phase])
	if hook.phase != PERCH:
		_key(KEY_SPACE, false)
		return
	totals.perched += 1
	_check(absf(Vector3(pose.grip).y - (point.y + GRIP_RISE)) <= 0.01, "perch", tag + "Л-б: the grip at y_A + %.2f (%.4f)" % [GRIP_RISE, Vector3(pose.grip).y - point.y])
	_check(absf(hero_node.global_position.y - (point.y - float(FEET_BELOW[hero]))) <= 0.01, "perch", tag + "Л-б: the feet at y_A − %.2f (%.4f)" % [FEET_BELOW[hero], hero_node.global_position.y - point.y])
	_check(hero_node.velocity.length() <= 0.001, "perch", tag + "Л-б: the grip is still (|v| %.4f)" % hero_node.velocity.length())
	# T6 § 3: on a bracket each wrist keeps BRACE_CLEARANCE off the axis of the built strut / tie rod (AnchorStrut<n>).
	var brace := INF
	var strut := world.district.get_node_or_null("AnchorStrut%d" % index) as Node3D
	if strut != null:
		var size: Vector3 = ((strut.get_child(0) as MeshInstance3D).mesh as BoxMesh).size
		var half: Vector3 = strut.global_transform.basis.z.normalized() * size.z * 0.5
		for side: String in ["left", "right"]:
			var wrist: Vector3 = Vector3(pose[side]) + Vector3.UP * WRIST_RISE
			var gap := _segment_distance(wrist, strut.global_position - half, strut.global_position + half)
			brace = minf(brace, gap)
			_check(gap >= BRACE_CLEARANCE, "perch", tag + "T6 § 3: the %s wrist %.3f m off the brace's axis (at least %.2f)" % [side, gap, BRACE_CLEARANCE])
	# П-2: the climbed rope is gone and exactly one slot came back to its owner on the grip's tick.
	_check(not world.ropes.records.has(token) and hook.charges == stock_before + 1, "inventory", tag + "П-2: the rope %d came back, the stock %d → %d" % [token, stock_before, hook.charges])
	_check(tail_drop <= 0.005 and tail_last <= TAIL_LEFT, "retrieve_tail", tag + "T6 § 9 п. 6: the tail's free end went down %.3f m on the pull-up (never), %.3f m of it on the last tick (at most %.2f)" % [tail_drop, tail_last, TAIL_LEFT])
	var hud_at_grip: String = String(world.hud.resource_label.text)
	_check(hud_at_grip.contains("HOOKS %d /" % stock_before), "retrieve_hud", tag + "T6 § 9 п. 6: on the grip's tick the HUD still shows the old stock %d («%s»)" % [stock_before, hud_at_grip.get_slice("\n", 0)])
	var flight := 0
	var landed_at := Vector3.INF
	var hud_landed := ""
	var feet: float = hero_node.global_position.y
	var held := true
	while hook._tip.visible and flight < RETURN_TICKS + 10 and hook.phase == PERCH:
		landed_at = hook._tip.global_position
		await _ticks(1)
		flight += 1
		hud_landed = String(world.hud.resource_label.text)
		_pose_sample(world, index, drawn, PULL_UP_TICKS + flight)
		_mesh_sample(world, index, drawn, PULL_UP_TICKS + flight)
		held = held and absf(hero_node.global_position.y - feet) <= 0.001
	var waist: Vector3 = hero_node.global_position + Vector3(0, 0.95, 0)
	_check(absi(flight - RETURN_TICKS) <= 1 and landed_at.is_finite() and landed_at.distance_to(waist) <= RETURN_GAP, "retrieve_hook", tag + "T6 § 9 п. 6: the hook flew %d ticks back (%d ± 1), its last point %.3f m off the waist (at most %.2f)" % [flight, RETURN_TICKS, landed_at.distance_to(waist) if landed_at.is_finite() else INF, RETURN_GAP])
	_check(hud_landed.contains("HOOKS %d /" % (stock_before + 1)), "retrieve_hud", tag + "T6 § 9 п. 6: when the hook lands the HUD shows %d («%s»)" % [stock_before + 1, hud_landed.get_slice("\n", 0)])
	_check(inventory_ok and _inventory_ok(world), "inventory", tag + "П-1: available + shot + deployed = capacity on every tick")
	var held_ticks := flight
	for tick: int in 179 - flight:
		await _ticks(1)
		if hook.phase != PERCH:
			break
		if flight + tick < PERCH_WATCH:
			_pose_sample(world, index, drawn, PULL_UP_TICKS + 1 + flight + tick)
			_mesh_sample(world, index, drawn, PULL_UP_TICKS + 1 + flight + tick)
		held_ticks += 1
		held = held and absf(hero_node.global_position.y - feet) <= 0.001
	_check(held and held_ticks >= 170, "noreq", tag + "Л-в: the held jump on the grip lifted nothing for %d ticks (feet %.4f → %.4f)" % [held_ticks, feet, hero_node.global_position.y])
	_check(float(drawn.tilt) <= PERCH_TILT_MAX, "perch_tilt", tag + "T6 § 9 п. 2: the body leans %.1f° from vertical (%s), at most %.0f° from the pull-up's tick %d through the grip" % [drawn.tilt, drawn.tilt_at, PERCH_TILT_MAX, SETTLE_TICKS])
	_check(float(drawn.excess) <= 0.5, "perch_tilt", tag + "T6 § 9 п. 2: the pull-up's first ticks lean %.1f° past what the rope left (%.1f°) or %.0f° (%s)" % [drawn.excess, drawn.entry, PERCH_TILT_MAX, drawn.excess_at])
	_check(float(drawn.step) <= PERCH_TILT_STEP, "perch_tilt", tag + "T6 § 9 п. 2: the lean changes %.1f° in one tick (%s), at most %.0f°" % [drawn.step, drawn.step_at, PERCH_TILT_STEP])
	_check(float(drawn.legs) >= LEG_CLEARANCE, "perch_legs", tag + "T6 § 9 п. 2: a leg bone %.3f m off the post (%s), at least %.2f" % [drawn.legs, drawn.legs_at, LEG_CLEARANCE])
	_check(float(drawn.crown) >= CROWN_CLEARANCE, "perch_head", tag + "T6 § 9 п. 3: the crown %.3f m off the arm on the grip (%s), at least %.2f" % [drawn.crown, drawn.crown_at, CROWN_CLEARANCE])
	_check(float(drawn.turn) <= BONE_TURN_MAX, "perch_turn", tag + "a bone turns %.1f° in one tick (%s), at most %.0f°" % [drawn.turn, drawn.turn_at, BONE_TURN_MAX])
	_check(float(drawn.facing) <= FACING_STEP_MAX, "perch_turn", tag + "the facing turns %.1f° in one tick (%s), at most %.0f°" % [drawn.facing, drawn.facing_at, FACING_STEP_MAX])
	# T6's re-acceptance 2026-10-15: the skinned surface, not the bone centres (see _mesh_sample).
	_check(int(drawn.pull_ticks) >= PULL_UP_TICKS - 1 and int(drawn.pull_n) == 0, "pull_ceramic", tag + "T6 re-acceptance N1: on the pull-up %d head / torso / upper-arm vertices inside the ceramic cap or the arm (%s), none on %d ticks" % [drawn.pull_n, drawn.pull_at, drawn.pull_ticks])
	_check(int(drawn.head_ticks) >= PERCH_WATCH and int(drawn.head_n) == 0, "perch_head_mesh", tag + "T6 re-acceptance п. 1: on the grip %d head vertices inside the arm or the cap (%s), none on %d ticks" % [drawn.head_n, drawn.head_at, drawn.head_ticks])
	if world.district.get_node_or_null("AnchorStrut%d" % index) != null:
		_check(int(drawn.strut_ticks) >= PULL_UP_TICKS + PERCH_WATCH - 1 and int(drawn.strut_n) == 0, "sleeve_strut", tag + "T6 re-acceptance п. 3: %d vertices inside the strut / tie rod (%s), none on %d pull-up and grip ticks" % [drawn.strut_n, drawn.strut_at, drawn.strut_ticks])
	_key(KEY_SPACE, false)
	print("ROPE_CLIMB %s anchor=%d start=%s reached=%d pull_up=%d grip=%.4f feet=%.4f held=%d stock=%d→%d brace=%s" % [hero, index, start, reached, pull_up, Vector3(pose.grip).y - point.y, feet - point.y, held_ticks, stock_before, hook.charges, "-" if brace == INF else "%.3f" % brace])
	print("ROPE_CLIMB_STROKE %s anchor=%d climbing=%d cycle_hz=%.2f feet_apart=%.3f stroke=%s" % [hero, index, climbing_ticks, cycle_step * 60.0, feet_apart, "-" if stroke.size() < STROKE_TICKS else "%.3f" % (stroke.max() - stroke.min())])
	print("ROPE_CLIMB_MESH %s anchor=%d way=%d pull=%d/%d (%s) head=%d/%d (%s) strut=%d/%d (%s)" % [hero, index, way, drawn.pull_n, drawn.pull_ticks, drawn.pull_at, drawn.head_n, drawn.head_ticks, drawn.head_at, drawn.strut_n, drawn.strut_ticks, drawn.strut_at])
	print("ROPE_CLIMB_POSE %s anchor=%d entry=%.1f tilt=%.1f step=%.1f legs=%s legs_settling=%s crown=%.3f turn=%.1f (%s) facing=%.1f" % [hero, index, drawn.entry, drawn.tilt, drawn.step, "-" if drawn.legs == INF else "%.3f" % drawn.legs, "-" if drawn.legs_settling == INF else "%.3f" % drawn.legs_settling, drawn.crown, drawn.turn, drawn.turn_at, drawn.facing])


## One tick of the drawn hero (see the header): the extremes go into `drawn` from the pull-up's first tick (`since` 0)
## through the grip; the rope's ticks (`since` −1) only seed the previous values.
func _pose_sample(world: Node, index: int, drawn: Dictionary, since: int) -> void:
	var judged: bool = since >= 0
	var hero_node: Node3D = world.player
	var skeleton: Skeleton3D = hero_node.skeletal.hero_skeleton
	var hook: Node = hero_node.grapple
	var at := "phase %d, pull-up tick %d" % [hook.phase, since]
	var tilt: float = rad_to_deg((_bone_world(skeleton, "Head") - _bone_world(skeleton, "Hips")).angle_to(Vector3.UP))
	var facing := Vector3(hero_node.forward.x, 0.0, hero_node.forward.z).normalized()
	var turn := 0.0
	var turn_bone := ""
	var rotations: Dictionary = {}
	for bone: int in skeleton.get_bone_count():
		var rotation: Quaternion = skeleton.get_bone_global_pose(bone).basis.get_rotation_quaternion()
		rotations[bone] = rotation
		if _pose_previous.has(bone):
			var degrees: float = rad_to_deg(2.0 * acos(clampf(absf(rotation.dot(_pose_previous[bone])), 0.0, 1.0)))
			if degrees > turn:
				turn = degrees
				turn_bone = skeleton.get_bone_name(bone)
	var settling: bool = since < SETTLE_TICKS
	if not judged:
		drawn.entry = tilt
	if judged and _pose_previous.has("tilt"):
		if settling:
			var excess: float = tilt - maxf(PERCH_TILT_MAX, float(drawn.entry))
			if excess > float(drawn.excess):
				drawn.excess = excess
				drawn.excess_at = at
		elif tilt > float(drawn.tilt):
			drawn.tilt = tilt
			drawn.tilt_at = at
		var step: float = absf(tilt - float(_pose_previous.tilt))
		if step > float(drawn.step):
			drawn.step = step
			drawn.step_at = at
		if turn > float(drawn.turn):
			drawn.turn = turn
			drawn.turn_at = "%s %s" % [turn_bone, at]
		var facing_step: float = rad_to_deg(facing.angle_to(Vector3(_pose_previous.facing)))
		if facing_step > float(drawn.facing):
			drawn.facing = facing_step
			drawn.facing_at = at
		var post := world.district.get_node_or_null("AnchorPost%d" % index) as Node3D
		if post != null:
			for bone: int in skeleton.get_bone_count():
				var name: String = skeleton.get_bone_name(bone)
				if name.contains("Leg") or name.contains("Foot") or name.contains("Toe"):
					var gap := _box_gap(post, skeleton.global_transform * skeleton.get_bone_global_pose(bone).origin)
					if settling:
						drawn.legs_settling = minf(float(drawn.legs_settling), gap)
					elif gap < float(drawn.legs):
						drawn.legs = gap
						drawn.legs_at = "%s %s" % [name, at]
		var arm := world.district.get_node_or_null("AnchorArm%d" % index) as Node3D
		if hook.phase == PERCH and arm != null and skeleton.find_bone("head_end") >= 0:
			var crown := _box_gap(arm, _bone_world(skeleton, "head_end"))
			if crown < float(drawn.crown):
				drawn.crown = crown
				drawn.crown_at = at
	_pose_previous = rotations
	_pose_previous["tilt"] = tilt
	_pose_previous["facing"] = facing


## One tick of the drawn surface (T6's re-acceptance 2026-10-15, docs/Fix/2026-10-15-Rope-Perch-Mesh-Clearance-Fix.md § 5):
## on a pull-up tick the head, torso and upper-arm vertices inside the ceramic cap or the arm (`pull_ceramic`); on a grip
## tick the head vertices inside the arm or the cap (`perch_head_mesh`); on both every vertex inside the strut or tie rod
## (`sleeve_strut`). The worst tick is kept in `drawn`.
func _mesh_sample(world: Node, index: int, drawn: Dictionary, since: int) -> void:
	var hook: Node = world.player.grapple
	var arm := world.district.get_node_or_null("AnchorArm%d" % index) as Node3D
	var cap := world.district.get_node_or_null("AnchorCeramic%d" % index) as Node3D
	var strut := world.district.get_node_or_null("AnchorStrut%d" % index) as Node3D
	var started: int = Time.get_ticks_usec()
	var at := "phase %d, pull-up tick %d" % [hook.phase, since]
	if hook.phase == CLIMB_TOP or hook.phase == PERCH:
		var found: Dictionary = mesh_clearance.count([arm, cap], ["head", "torso", "upperarm"] if hook.phase == CLIMB_TOP else ["head"])
		var n: int = mesh_clearance.inside(found)
		var key := "pull" if hook.phase == CLIMB_TOP else "head"
		drawn[key + "_ticks"] = int(drawn[key + "_ticks"]) + 1
		if n > int(drawn[key + "_n"]):
			drawn[key + "_n"] = n
			drawn[key + "_at"] = "%s: %s" % [at, mesh_clearance.describe(found)]
		if strut != null:
			var touched: Dictionary = mesh_clearance.count([strut], mesh_clearance.GROUPS)
			var m: int = mesh_clearance.inside(touched)
			drawn.strut_ticks = int(drawn.strut_ticks) + 1
			if m > int(drawn.strut_n):
				drawn.strut_n = m
				drawn.strut_at = "%s: %s" % [at, mesh_clearance.describe(touched)]
	mesh_usec += Time.get_ticks_usec() - started
	mesh_ticks += 1


static func _bone_world(skeleton: Skeleton3D, name: String) -> Vector3:
	return skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(name)).origin


## Distance from `point` to the box CityDistrict built as `holder` (its first child's BoxMesh); 0 inside.
static func _box_gap(holder: Node3D, point: Vector3) -> float:
	var size: Vector3 = ((holder.get_child(0) as MeshInstance3D).mesh as BoxMesh).size
	var local: Vector3 = holder.global_transform.affine_inverse() * point
	return Vector3(maxf(0.0, absf(local.x) - size.x * 0.5), maxf(0.0, absf(local.y) - size.y * 0.5), maxf(0.0, absf(local.z) - size.z * 0.5)).length()


static func _segment_distance(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.000001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


# --- the rest of T8's list (--part=rules) ----------------------------------------------------------------------------

## A rope on `index` climbed to the grip with the held jump; the jump stays held. True on the grip.
func _perch_on(world: Node, index: int) -> bool:
	var point: Vector3 = supports[index].point
	for candidate: Vector3 in _starts_for(world, index):
		await _reset(world, candidate, point)
		if await _hang_on(world, index):
			break
	var hook: Node = world.player.grapple
	if hook.phase != HANG:
		return false
	await _settle_pull(hook)
	_key(KEY_SPACE, true)
	for tick: int in 240:
		await _ticks(1)
		if hook.phase == PERCH or (hook.phase == HANG and hook.get("climb_blocked")):
			break
	return hook.phase == PERCH


func _rules(world: Node, hero: String) -> void:
	var hero_node: CharacterBody3D = world.player
	var hook: Node = hero_node.grapple
	var tag := "[%s] " % hero
	# P9a: a jump held through the attach never climbs; a new press does.
	await _reset(world, _starts_for(world, 3)[0], supports[3].point)
	_key(KEY_SPACE, true)
	var hung := await _hang_on(world, 3)
	await _settle_pull(hook)
	var settled: float = hook.rope_length
	var stayed := true
	for tick: int in 40:
		await _ticks(1)
		stayed = stayed and hook.phase == HANG and hook.rope_length >= settled - 0.000001
	_check(hung and stayed, "arm", tag + "P9: the jump held through the attach did not climb (L %.4f → %.4f)" % [settled, hook.rope_length])
	_key(KEY_SPACE, false)
	await _ticks(2)
	_key(KEY_SPACE, true)
	await _ticks(10)
	_check(hook.rope_length < settled - 0.3, "arm", tag + "P9: a new press climbs (L %.4f → %.4f)" % [settled, hook.rope_length])
	_key(KEY_SPACE, false)
	# The grip lasts 3.0 s, then drops still; with «Сила» 4.0 s. P9b: the held jump never leaps.
	for strength: bool in [false, true]:
		hero_node.hunger.strength_left = 100000 if strength else 0
		var perched := await _perch_on(world, 3)
		_check(perched, "grip", tag + "the climb gripped anchor 3")
		var held := 0
		var own_marked := 0
		for tick: int in 20:
			await _ticks(1)
			if hook.phase == PERCH:
				held += 1
			if String(world.camera_rig.aim.published.get("target_id", "")).ends_with("/StreetAnchor3"):
				own_marked += 1
		_check(held == 20, "arm", tag + "P9: the jump held from the climb never leaps (%d of 20 ticks on the grip)" % held)
		_check(own_marked == 0, "perch_e", tag + "the gripped anchor is never marked as the next one (%d ticks)" % own_marked)
		_key(KEY_SPACE, false)
		var lasted := 21
		while hook.phase == PERCH and lasted < 400:
			await _ticks(1)
			lasted += 1
		var expected := roundi((PERCH_SECONDS + (STRENGTH_BONUS if strength else 0.0)) * 60.0) + 1
		_check(absi(lasted - expected) <= 1 and hero_node.state == STATE_JUMP, "grip", tag + "the grip%s held %d ticks, expected %d ± 1, then dropped (state %d)" % [" with «Сила»" if strength else "", lasted, expected, hero_node.state])
		_check(absf(hero_node.velocity.x) + absf(hero_node.velocity.z) <= 0.001, "grip", tag + "the drop is still (v %s)" % hero_node.velocity)
	hero_node.hunger.strength_left = 0
	# Z and X drop the grip, the velocity 0.
	for code: Key in [KEY_Z, KEY_X]:
		if await _perch_on(world, 3):
			_key(KEY_SPACE, false)
			await _ticks(2)
			_key(code, true)
			await _ticks(1)
			_check(hook.phase == 0 and hero_node.state == STATE_JUMP and hero_node.velocity.length() <= 0.4 + 0.001, "grip", tag + "%s drops the grip (phase %d, state %d, v %s)" % [OS.get_keycode_string(code), hook.phase, hero_node.state, hero_node.velocity])
			_key(code, false)
	# The leap: 6.8 / 7.4 — without the stick square to the arm, away from it; with it, the stick's direction projected off
	# the arm (T1 on T6 acceptance § 9 п. 5: LEAP_ACROSS away from the arm at least).
	for with_stick: bool in [true, false]:
		if await _perch_on(world, 3):
			_key(KEY_SPACE, false)
			await _ticks(2)
			var facing: Vector3 = hook.perch_pose.facing
			if with_stick:
				_key(KEY_A, true)
				await _ticks(2)
			var wish: Vector3 = hero_node.wish()
			_key(KEY_SPACE, true)
			await _ticks(1)
			_key(KEY_SPACE, false)
			var v: Vector3 = hero_node.velocity
			var flat := Vector3(v.x, 0, v.z)
			var along: Vector3 = _leap_expected(Vector3(wish.x, 0, wish.z) if with_stick else Vector3.ZERO, facing)
			_check(hook.phase == 0 and absf(flat.length() - LEAP_OUT) <= 0.6 and absf(v.y - (LEAP_UP - 24.0 / 60.0)) <= 0.45 and flat.normalized().dot(along) >= 0.95, "leap", tag + "the leap %s: v %s, expected %.1f along %s and %.1f up" % ["with the stick" if with_stick else "square to the arm, away from it", v, LEAP_OUT, along, LEAP_UP])
			_key(KEY_A, false)
			await _ticks(30)
	await _leap_clear(world, hero)
	# E on the grip with nothing in reach (no hooks left, no rope in 0.70 m) and nothing shown for 15 ticks: drops.
	if await _perch_on(world, 3):
		_key(KEY_SPACE, false)
		while hook.charges > 0:
			world.ropes.issue(1)
		await _ticks(20)
		var aim: Node = world.camera_rig.aim
		_check(String(aim.published.get("target_id", "")).is_empty() and aim.ticks_since_target() >= 15, "perch_e", tag + "nothing shown for 15 ticks on the grip (%s, %d)" % [aim.published.get("target_id", ""), aim.ticks_since_target()])
		await _tap(KEY_E)
		_check(hook.phase == 0 and hero_node.state == STATE_JUMP, "perch_e", tag + "E with no target on the grip drops (phase %d, state %d)" % [hook.phase, hero_node.state])
		world.ropes.clear_match()
		await _ticks(30)
	# E on the grip at a shown anchor (anchor 2 → 17, T3 s7b's pair): 10 ticks of windup with the hands on the arm,
	# −1 hook, a hang on the new anchor.
	if await _perch_on(world, 2):
		_key(KEY_SPACE, false)
		var to: Vector3 = supports[17].point
		world.camera_rig.aim.yaw_offset = atan2(-(to.x - hero_node.global_position.x), -(to.z - hero_node.global_position.z))
		var shown := ""
		for tick: int in 40:
			await _ticks(1)
			shown = String(world.camera_rig.aim.published.get("target_id", ""))
			if not shown.is_empty():
				break
		_check(not shown.is_empty(), "perch_shot", tag + "an anchor not lower than the hand is shown from the grip on anchor 2 (%s)" % shown)
		var stock: int = hook.charges
		var at: Vector3 = hero_node.global_position
		var pose: Dictionary = hook.perch_pose.duplicate()
		await _tap(KEY_E)
		var still := true
		var windup := 0
		var skeleton: Skeleton3D = hero_node.skeletal.hero_skeleton
		var thrower: String = String(hook.get("throw_hand"))
		var keeper: String = "Left" if thrower == "Right" else "Right"
		var keeper_off := 0.0
		var thrower_off := 0.0
		var rope_off := 0.0
		var flight_ticks := 0
		while hook.phase == 1 and windup < 30:
			still = still and hero_node.global_position.distance_to(at) <= 0.001
			await _ticks(1)
			windup += 1
			if not thrower.is_empty():
				keeper_off = maxf(keeper_off, _bone_world(skeleton, keeper + "Hand").distance_to(Vector3(pose[keeper.to_lower()]) + Vector3.UP * WRIST_RISE))
				thrower_off = _bone_world(skeleton, thrower + "Hand").distance_to(Vector3(pose[thrower.to_lower()]) + Vector3.UP * WRIST_RISE)
		_check(windup >= WINDUP_TICKS - 1 and windup <= WINDUP_TICKS + 1 and still, "perch_shot", tag + "the shot from the grip winds up %d ticks with the hands on the arm (still %s)" % [windup, still])
		var hang_new := false
		for tick: int in 60:
			await _ticks(1)
			if hook.phase == 2 and not thrower.is_empty():
				flight_ticks += 1
				keeper_off = maxf(keeper_off, _bone_world(skeleton, keeper + "Hand").distance_to(Vector3(pose[keeper.to_lower()]) + Vector3.UP * WRIST_RISE))
				var visual: Node = hook._rope_visual
				if visual != null and visual.visible and not visual.points.is_empty():
					rope_off = maxf(rope_off, Vector3(visual.points[0]).distance_to(_bone_world(skeleton, thrower + "Hand")))
			if hook.phase == HANG and hook.attached:
				hang_new = true
				break
		# T6 § 9 п. 7: one hand lets go and throws, the rope from it; the other keeps the arm (the body still, above).
		_check(not thrower.is_empty() and thrower_off >= THROW_AWAY and keeper_off <= KEEP_ON and flight_ticks > 0 and rope_off <= THROW_ROPE, "perch_throw", tag + "T6 § 9 п. 7: the %s hand throws (%.3f m off its grip at the windup's end, at least %.2f), the %s keeps the arm (%.3f, at most %.2f), the rope leaves the throwing hand (%.3f over %d flight ticks, at most %.2f)" % [thrower, thrower_off, THROW_AWAY, keeper, keeper_off, KEEP_ON, rope_off, flight_ticks, THROW_ROPE])
		_check(hang_new and hook.charges == stock - 1 and shown.ends_with("StreetAnchor%d" % supports.find(_spec_at(hook.anchor_point))), "perch_shot", tag + "the shot hangs on the shown anchor, −1 hook (%d → %d, anchor %s)" % [stock, hook.charges, hook.anchor_point])
	# P7 / P8: the dodge's press on the rope is taken by the rope; a fresh one in the air after the release dodges.
	await _reset(world, _starts_for(world, 3)[0], supports[3].point)
	if await _hang_on(world, 3):
		await _settle_pull(hook)
		# Climb 0.6 m first, so the release leaves the hero in the air long enough for both checks.
		_key(KEY_SPACE, true)
		await _ticks(10)
		_key(KEY_SPACE, false)
		await _tap(KEY_SHIFT)
		await _ticks(2)
		await _tap(KEY_Z)
		var dashed := false
		for tick: int in 6:
			await _ticks(1)
			dashed = dashed or hero_node.state == STATE_DASH
		var airborne: bool = not hero_node.on_ground()
		_check(not dashed and airborne, "dodge", tag + "P7: a dodge pressed on the rope never fires after the release (dashed %s, still in the air %s)" % [dashed, airborne])
		var states: Array[int] = []
		await _tap(KEY_SHIFT)
		for tick: int in 3:
			states.append(hero_node.state)
			await _ticks(1)
		_check(states.has(STATE_DASH), "dodge", tag + "P8: a fresh dodge in the air after the release dodges (states %s, in the air before %s)" % [states, airborne])
		await _ticks(40)
	# P3 (T8 § «Як перевірити», gamepad; T4 audit 15а Y8): Y + X on the rope is the dash chord, never the slide. Control: X
	# alone held slides.
	_pad_neutral()
	await _reset(world, _starts_for(world, 3)[0], supports[3].point)
	if await _hang_on(world, 3):
		await _settle_pull(hook)
		# T8 ТЗ 4: A held climbs (the pad's jump).
		var low: float = hook.rope_length
		_pad(JOY_BUTTON_A, true)
		await _ticks(10)
		_pad(JOY_BUTTON_A, false)
		_check(hook.phase == HANG and hook.rope_length < low - 0.3, "pad", tag + "A / Cross held on the rope climbs (L %.4f → %.4f in 10 ticks)" % [low, hook.rope_length])
		await _ticks(2)
		var before: float = hook.rope_length
		var dashed_x := false
		_pad(JOY_BUTTON_X, true)
		for tick: int in 20:
			await _ticks(1)
			dashed_x = dashed_x or hero_node.state == STATE_DASH
		_pad(JOY_BUTTON_X, false)
		var slid: float = hook.rope_length - before
		_check(not dashed_x, "pad", tag + "X / Square held on the rope slides with no DASH")
		await _ticks(4)
		before = hook.rope_length
		var dashed := false
		_pad(JOY_BUTTON_Y, true)
		await _ticks(1)
		_pad(JOY_BUTTON_X, true)
		for tick: int in 20:
			await _ticks(1)
			dashed = dashed or hero_node.state == STATE_DASH
		_pad(JOY_BUTTON_X, false)
		_pad(JOY_BUTTON_Y, false)
		_check(slid > 0.5, "pad", tag + "P3 control: X / Square held on the rope slides (%.3f m in 20 ticks)" % slid)
		_check(hook.phase == HANG and absf(hook.rope_length - before) <= 0.000001 and not dashed, "pad", tag + "P3: Y + X on the rope neither slides nor dashes (L %.4f → %.4f, phase %d, dashed %s)" % [before, hook.rope_length, hook.phase, dashed])
		await _ticks(4)
	# The rest of the pad on the rope and on the grip (T8 ТЗ 4), the grip's dash press (ТЗ 6).
	await _pad_rows(world, hero)
	await _perch_dash(world, hero)
	await _hang_dash(world, hero)
	# P12: ROPE CLIMB · TOGGLE.
	router.set_rope_climb("toggle", false)
	await _reset(world, _starts_for(world, 3)[0], supports[3].point)
	if await _hang_on(world, 3):
		await _settle_pull(hook)
		var l0: float = hook.rope_length
		await _tap(KEY_SPACE)
		await _ticks(10)
		var l1: float = hook.rope_length
		await _tap(KEY_SPACE)
		await _ticks(2)
		var l2: float = hook.rope_length
		await _ticks(10)
		var l3: float = hook.rope_length
		await _tap(KEY_SHIFT)
		await _ticks(10)
		var l4: float = hook.rope_length
		await _tap(KEY_SPACE)
		await _ticks(5)
		world.hud.set_paused(true)
		await _ticks(2)
		world.hud.set_paused(false)
		await _ticks(3)
		var l5: float = hook.rope_length
		await _ticks(10)
		var l6: float = hook.rope_length
		_check(l1 < l0 - 0.4 and absf(l3 - l2) <= 0.000001 and l4 > l3 + 0.2 and absf(l6 - l5) <= 0.000001, "toggle", tag + "P12: tap climbs, tap stops, dodge slides, the pause stops (L %.3f %.3f %.3f %.3f %.3f %.3f %.3f)" % [l0, l1, l2, l3, l4, l5, l6])
	router.set_rope_climb("hold", false)
	# P10b: a street event's passer-by (T8 ТЗ 1), before P10 brings the residents near anchor 3.
	await _passerby(world, hero)
	# P10: G on a rope next to a resident opens no talk; on the ground next to the same resident it does.
	var director: Node = world.npc_director
	director.process_mode = Node.PROCESS_MODE_INHERIT
	director.active_radius = 100.0
	director._refresh_actors()
	director.process_mode = Node.PROCESS_MODE_DISABLED
	var resident: int = director.actors.keys()[0] if not director.actors.is_empty() else -1
	await _reset(world, _starts_for(world, 3)[0], supports[3].point)
	if resident >= 0 and await _hang_on(world, 3):
		var actor: Node3D = director.actors[resident]
		actor.set_physics_process(false)
		actor.global_position = hero_node.global_position + Vector3(0, 0, director.player_radius() + actor.interaction_radius() + 0.3)
		_check(not director.can_talk(resident) and director.find_nearest() < 0, "talk", tag + "P10: no talk while on the rope")
		hook.detach()
		hero_node._set_state(STATE_IDLE)
		hero_node.global_position = actor.global_position - Vector3(0, actor.global_position.y, director.player_radius() + actor.interaction_radius() + 0.3)
		await _ticks(1)
		hero_node.global_position = Vector3(hero_node.global_position.x, actor.global_position.y, hero_node.global_position.z)
		_check(director.can_talk(resident), "talk", tag + "P10 control: on the ground next to the same resident the talk is offered")
		# P11: the resident wins the key over the rope left hanging by him (T8 § 2.4: the reel is last).
		var rope_near: bool = not hook.reel_candidate().is_empty()
		await _ticks(2)
		_check(rope_near and not ("Reel in" in String(world.hud._story_prompt)), "talk", tag + "P11: next to a resident and a rope the key offers the talk, not the reel (rope in reach %s, prompt «%s»)" % [rope_near, world.hud._story_prompt])
	# ROPE CLIMB in COMFORT & CONTROLS (T8 § 5): HOLD by default, the row switches the city's mode.
	await _comfort_row(world, hero)
	# П-3 / П-4: the reel.
	await _reel(world, hero)
	# P13: every new row is one line at 1600 × 900 (the hint label's own font, 18 px, 1552 px).
	await _hud_rows(world, hero)


func _comfort_row(world: Node, hero: String) -> void:
	var hud: Node = world.hud
	router.set_rope_climb("hold", false)
	# settings.cfg as it was before the first press, put back at the end (a run outside the battery writes the real file).
	var had_file: bool = FileAccess.file_exists(SETTINGS)
	var kept: PackedByteArray = FileAccess.get_file_as_bytes(SETTINGS) if had_file else PackedByteArray()
	_pad_neutral()
	hud.set_paused(true)
	await _ticks(2)
	hud.comfort_button.grab_focus()
	await _ticks(1)
	await _tap(KEY_ENTER)
	await _ticks(3)
	var panel: Control = hud.comfort
	var row: OptionButton = panel.find_child("RopeClimb", true, false) as OptionButton
	if mutation == "rope_row" and row != null:
		for connection: Dictionary in row.item_selected.get_connections():
			row.item_selected.disconnect(connection.callable)
	var focus: Control = panel.get_viewport().gui_get_focus_owner()
	_check(panel.visible and focus == panel.sliders["master"], "comfort", "[%s] Enter on the pause's COMFORT opens the panel with the focus on MASTER (%s)" % [hero, focus.name if focus != null else "none"])
	_check(climb_default == "hold", "comfort", "[%s] ROPE CLIMB is HOLD by default, read before the fixture sets a mode (%s)" % [hero, climb_default])
	_check(row != null and row.selected == 0 and row.get_item_text(0).begins_with("Hold"), "comfort", "[%s] the ROPE CLIMB row shows HOLD by default" % hero)
	var title: Label = row.get_parent().get_child(row.get_index() - 1) as Label if row != null and row.get_index() > 0 else null
	_check(title != null and title.text == ROPE_CLIMB_TITLE, "comfort", "[%s] T8 С2: the row's title is «%s» («%s»)" % [hero, ROPE_CLIMB_TITLE, title.text if title != null else "-"])
	for step: int in COMFORT_DOWNS:
		await _tap(KEY_DOWN)
		await _ticks(1)
	focus = panel.get_viewport().gui_get_focus_owner()
	_check(row != null and focus == row, "comfort", "[%s] %d × Down from MASTER reach ROPE CLIMB (%s)" % [hero, COMFORT_DOWNS, focus.name if focus != null else "none"])
	await _tap(KEY_ENTER)
	await _ticks(2)
	var listed: bool = row != null and row.get_popup().visible
	await _tap(KEY_DOWN)
	await _ticks(1)
	await _tap(KEY_ENTER)
	await _ticks(2)
	var saved := ConfigFile.new()
	var loaded := saved.load(SETTINGS)
	_check(listed and router.rope_climb == "toggle" and row.selected == 1 and loaded == OK and String(saved.get_value("input", "rope_climb", "")) == "toggle", "comfort", "[%s] Enter · Down · Enter pick TOGGLE: the list opened %s, InputRouter %s, the row %d, settings.cfg %s rope_climb=%s" % [hero, listed, router.rope_climb, row.selected if row != null else -1, error_string(loaded), saved.get_value("input", "rope_climb", "-")])
	await _tap_pad(JOY_BUTTON_A)
	await _ticks(2)
	await _tap_pad(JOY_BUTTON_DPAD_UP)
	await _ticks(1)
	await _tap_pad(JOY_BUTTON_A)
	await _ticks(2)
	saved = ConfigFile.new()
	loaded = saved.load(SETTINGS)
	_check(router.rope_climb == "hold" and row.selected == 0 and loaded == OK and String(saved.get_value("input", "rope_climb", "")) == "hold", "comfort", "[%s] the pad's A · D-pad Up · A pick HOLD: InputRouter %s, the row %d, settings.cfg %s rope_climb=%s" % [hero, router.rope_climb, row.selected if row != null else -1, error_string(loaded), saved.get_value("input", "rope_climb", "-")])
	_pad_neutral()
	panel.close_panel()
	hud.set_paused(false)
	await _ticks(2)
	router.set_rope_climb("hold", false)
	if had_file:
		var file := FileAccess.open(SETTINGS, FileAccess.WRITE)
		if file != null:
			file.store_buffer(kept)
			file.close()
	elif FileAccess.file_exists(SETTINGS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS))
	var back: bool = FileAccess.get_file_as_bytes(SETTINGS) == kept if had_file else not FileAccess.file_exists(SETTINGS)
	_check(back, "count", "[%s] settings.cfg is back as it was before the presses (existed %s, %d bytes)" % [hero, had_file, kept.size()])


## A rope on `index` climbed to the grip with the pad's A held; A stays held. True on the grip.
func _perch_pad(world: Node, index: int) -> bool:
	_pad_neutral()
	var point: Vector3 = supports[index].point
	for candidate: Vector3 in _starts_for(world, index):
		await _reset(world, candidate, point)
		if await _hang_on(world, index):
			break
	var hook: Node = world.player.grapple
	if hook.phase != HANG:
		return false
	await _settle_pull(hook)
	_pad(JOY_BUTTON_A, true)
	for tick: int in 240:
		await _ticks(1)
		if hook.phase == PERCH or (hook.phase == HANG and hook.get("climb_blocked")):
			break
	return hook.phase == PERCH


## T8 ТЗ 4: the let-go by the pad on the rope, and the pad and LShift on the grip.
func _pad_rows(world: Node, hero: String) -> void:
	var hero_node: CharacterBody3D = world.player
	var hook: Node = hero_node.grapple
	var tag := "[%s] " % hero
	# On the rope: L3 and Y + LT with nothing shown for ≥ 15 ticks let go (no hooks left, no rope in 0.70 m); B lets go.
	for how: String in ["L3", "Y + LT", "B"]:
		_pad_neutral()
		await _reset(world, _starts_for(world, 3)[0], supports[3].point)
		if not await _hang_on(world, 3):
			_check(false, "count", tag + "pad %s: a hang on anchor 3" % how)
			continue
		await _settle_pull(hook)
		if how != "B":
			while hook.charges > 0:
				world.ropes.issue(1)
			await _ticks(20)
			var aim: Node = world.camera_rig.aim
			_check(String(aim.published.get("target_id", "")).is_empty() and aim.ticks_since_target() >= 15, "count", tag + "pad %s: nothing shown on the rope for 15 ticks (%s, %d)" % [how, aim.published.get("target_id", ""), aim.ticks_since_target()])
		match how:
			"L3":
				await _tap_pad(JOY_BUTTON_LEFT_STICK)
			"Y + LT":
				_pad(JOY_BUTTON_Y, true)
				await _ticks(1)
				_pad_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
				await _ticks(1)
				_pad_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
				_pad(JOY_BUTTON_Y, false)
			"B":
				await _tap_pad(JOY_BUTTON_B)
		await _ticks(1)
		_check(hook.phase == 0 and hero_node.state == STATE_JUMP, "pad", tag + "pad %s on the rope lets go (phase %d, state %d)" % [how, hook.phase, hero_node.state])
		_pad_neutral()
		world.ropes.clear_match()
		await _ticks(30)
	# On the grip: B and D-pad Down drop, X and LShift dodge off it, A + the stick leaps.
	for how: String in ["B", "D-pad Down", "X", "LShift", "A + stick"]:
		if not await _perch_pad(world, 3):
			_check(false, "count", tag + "pad grip %s: the climb gripped anchor 3" % how)
			continue
		_pad(JOY_BUTTON_A, false)
		await _ticks(2)
		match how:
			"B":
				await _tap_pad(JOY_BUTTON_B)
			"D-pad Down":
				await _tap_pad(JOY_BUTTON_DPAD_DOWN)
			"X":
				await _tap_pad(JOY_BUTTON_X)
			"LShift":
				await _tap(KEY_SHIFT)
			"A + stick":
				_pad_axis(JOY_AXIS_LEFT_X, -1.0)
				await _ticks(2)
				await _tap_pad(JOY_BUTTON_A)
		var v: Vector3 = hero_node.velocity
		var phase: int = hook.phase
		var states: Array[int] = []
		for tick: int in 3:
			states.append(hero_node.state)
			await _ticks(1)
		_pad_neutral()
		match how:
			"B", "D-pad Down":
				_check(phase == 0 and states[0] == STATE_JUMP, "pad", tag + "pad %s on the grip drops (phase %d, states %s)" % [how, phase, states])
			"X", "LShift":
				_check(phase == 0 and states.has(STATE_DASH), "pad" if how == "X" else "grip", tag + "%s on the grip dodges off it (phase %d, states %s)" % [how, phase, states])
			"A + stick":
				var flat := Vector2(v.x, v.z).length()
				_check(phase == 0 and absf(flat - LEAP_OUT) <= 0.6 and absf(v.y - (LEAP_UP - 24.0 / 60.0)) <= 0.45, "pad", tag + "pad A + stick on the grip leaps (phase %d, |v_flat| %.2f of %.1f, v_y %.2f of %.1f)" % [phase, flat, LEAP_OUT, v.y, LEAP_UP])
		await _ticks(40)


## T8 ТЗ 6 (Skea; Choko has no air dash without «Spring»): a dash pressed on the grip, where it means nothing, never fires
## after the drop; a fresh one after the drop does (control).
func _perch_dash(world: Node, hero: String) -> void:
	if hero != "skea":
		return
	var hero_node: CharacterBody3D = world.player
	var hook: Node = hero_node.grapple
	for how: String in ["LAlt", "Y + X"]:
		if not await _perch_pad(world, 3):
			_check(false, "count", "[%s] grip dash %s: the climb gripped anchor 3" % [hero, how])
			continue
		_pad(JOY_BUTTON_A, false)
		await _ticks(2)
		if how == "LAlt":
			await _tap(KEY_ALT)
		else:
			_pad(JOY_BUTTON_Y, true)
			await _ticks(1)
			await _tap_pad(JOY_BUTTON_X)
			_pad(JOY_BUTTON_Y, false)
		var kept_grip: bool = hook.phase == PERCH and hero_node.state != STATE_DASH
		await _ticks(1)
		await _tap_pad(JOY_BUTTON_B)
		var dropped: bool = hook.phase == 0
		var dashed := false
		for tick: int in 8:
			await _ticks(1)
			dashed = dashed or hero_node.state == STATE_DASH
		_check(kept_grip and dropped and not dashed, "perch_dash", "[%s] %s on the grip, B 2 ticks later: no DASH for 8 ticks after the drop (grip kept %s, dropped %s, dashed %s)" % [hero, how, kept_grip, dropped, dashed])
		var airborne: bool = not hero_node.on_ground()
		var states: Array[int] = []
		await _tap(KEY_ALT)
		for tick: int in 3:
			states.append(hero_node.state)
			await _ticks(1)
		_check(airborne and states.has(STATE_DASH), "perch_dash", "[%s] control: a fresh LAlt after the drop flashes (in the air %s, states %s)" % [hero, airborne, states])
		_pad_neutral()
		await _ticks(40)


## T4 re-audit 15а Y-A (T8 § 3, T2-П's subject «`dash` на тросі й звисі»; Skea only, as above): a dash pressed while
## hanging on the rope, where the rope takes it, never fires after the let-go; a fresh one after the let-go does (control).
## The same presses as _perch_dash, the hang instead of the grip (T4's probe t4_hang_dash_probe.gd).
func _hang_dash(world: Node, hero: String) -> void:
	if hero != "skea":
		return
	var hero_node: CharacterBody3D = world.player
	var hook: Node = hero_node.grapple
	for how: String in ["LAlt", "Y + X"]:
		_pad_neutral()
		await _reset(world, _starts_for(world, 3)[0], supports[3].point)
		if not await _hang_on(world, 3):
			_check(false, "count", "[%s] rope dash %s: a hang on anchor 3" % [hero, how])
			continue
		await _settle_pull(hook)
		if how == "LAlt":
			await _tap(KEY_ALT)
		else:
			_pad(JOY_BUTTON_Y, true)
			await _ticks(1)
			await _tap_pad(JOY_BUTTON_X)
			_pad(JOY_BUTTON_Y, false)
		var kept_hang: bool = hook.phase == HANG and hook.attached and hero_node.state != STATE_DASH
		await _ticks(1)
		await _tap_pad(JOY_BUTTON_B)
		var let_go: bool = hook.phase == 0
		var dashed := false
		for tick: int in 8:
			await _ticks(1)
			dashed = dashed or hero_node.state == STATE_DASH
		_check(kept_hang and let_go and not dashed, "rope_dash", "[%s] %s on the rope, B 2 ticks later: no DASH for 8 ticks after the let-go (hang kept %s, let go %s, dashed %s)" % [hero, how, kept_hang, let_go, dashed])
		var airborne: bool = not hero_node.on_ground()
		var states: Array[int] = []
		await _tap(KEY_ALT)
		for tick: int in 3:
			states.append(hero_node.state)
			await _ticks(1)
		_check(airborne and states.has(STATE_DASH), "rope_dash", "[%s] control: a fresh LAlt after the let-go flashes (in the air %s, states %s)" % [hero, airborne, states])
		_pad_neutral()
		await _ticks(40)


## A point 1.2 m from the hero on his level with a clear line to him (the first of four bearings).
func _beside(world: Node) -> Vector3:
	var at: Vector3 = world.player.global_position
	for direction: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
		if world.events.clear_line(at, at + direction * 1.2):
			return at + direction * 1.2
	return at + Vector3.RIGHT * 1.2


func _clean_event(world: Node) -> void:
	var events: Node = world.events
	if events.active != null:
		events.abort_active("fixture")
	if events.dialogue.opened:
		events.dialogue.close()
	await _ticks(2)


## P10b (T8 ТЗ 1): see the header.
func _passerby(world: Node, hero: String) -> void:
	var hero_node: CharacterBody3D = world.player
	var hook: Node = hero_node.grapple
	var events: Node = world.events
	var tag := "[%s] P10b: " % hero
	await _reset(world, _starts_for(world, 3)[0], supports[3].point)
	if not await _hang_on(world, 3):
		_check(false, "count", tag + "a hang on anchor 3")
		return
	await _settle_pull(hook)
	var person: Node3D = events.spawn_passerby(7, _beside(world))
	await _ticks(1)
	person.global_position = _beside(world)
	_check(events.in_talk_reach(person), "count", tag + "the passer-by stands in talk reach of the hanging hero (precondition)")
	_check(hook.phase == HANG and not events.can_talk_to(person), "talk", tag + "no talk to a passer-by while hanging on the rope (phase %d)" % hook.phase)
	person.queue_free()
	# Each street event's passer-by beside the hanging hero (the fixture starts it; the director starts one only on the
	# ground with the hook free, CityEventDirector.common_block_reason): the prompt stays hidden, the real G opens no menu.
	# The leaves' offer, then (T4 re-audit 15а Y-B) the alley's asker and the pedlar's offer — each asks its own prompt.
	for id: String in ["leaves", "alley", "vendor"]:
		await _passerby_event(world, hero, id)
	# The reel: no talk while the rope comes back; on the ground with the hook free, the same passer-by beside the hero is.
	var token := await _leave_rope(world)
	_check(token != 0, "count", tag + "a rope stays hanging after the slide")
	if token == 0:
		return
	await _tap(KEY_G)
	await _ticks(2)
	var other: Node3D = events.spawn_passerby(8, _beside(world))
	await _ticks(1)
	other.global_position = _beside(world)
	var reeling: bool = hook.phase == MISS_REWIND and hero_node.on_ground()
	_check(reeling and events.in_talk_reach(other), "count", tag + "the hero reels on the ground, the passer-by in talk reach (phase %d; precondition)" % hook.phase)
	_check(not events.can_talk_to(other), "talk", tag + "no talk to a passer-by while a rope reels in (phase %d)" % hook.phase)
	for tick: int in 140:
		await _ticks(1)
		if hook.phase == 0:
			break
	other.global_position = _beside(world)
	await _ticks(1)
	_check(hook.phase == 0 and events.in_talk_reach(other) and events.can_talk_to(other), "talk", tag + "control: on the ground with the hook free the same passer-by is talked to (phase %d)" % hook.phase)
	other.queue_free()
	world.ropes.clear_match()
	await _ticks(2)


## P10b for one street event `id` beside the hero hanging on anchor 3: the event started by the fixture, its passer-by held
## beside the hero until he offers (the leaves, the pedlar) or asks (the alley); his prompt stays hidden, the real G opens no
## menu (`talk`); the start, the phase, the reach and the hang are preconditions (`count`).
func _passerby_event(world: Node, hero: String, id: String) -> void:
	var hook: Node = world.player.grapple
	var events: Node = world.events
	var tag := "[%s] P10b: " % hero
	var starts: String = {"leaves": "the leaves start", "alley": "the alley's call starts", "vendor": "the pedlar's offer starts"}[id]
	var who: String = {"leaves": "the leaves' passer-by offers", "alley": "the alley's asker asks", "vendor": "the pedlar offers"}[id]
	var whose: String = {"leaves": "the leaves'", "alley": "the alley's", "vendor": "the pedlar's"}[id]
	var talking: String = "ask" if id == "alley" else "offer"
	_check(hook.phase == HANG and world.npc_director.find_nearest() < 0 and events.active == null and events.start(id), "count", tag + "%s beside the hanging hero, no resident in reach (precondition)" % starts)
	var event: Node = events.active
	if event != null:
		var person: Node3D = event.get("asker") if id == "alley" else event.get("person")
		for tick: int in 60:
			if is_instance_valid(person):
				person.global_position = _beside(world)
				person.stop()
			await _ticks(1)
			if not is_instance_valid(event) or event.phase == talking:
				break
		var offering: bool = is_instance_valid(event) and event.phase == talking and is_instance_valid(person)
		if offering:
			person.global_position = _beside(world)
		await _ticks(2)
		var reach: bool = offering and events.in_talk_reach(person)
		var shown: bool = events.dialogue.prompt.visible
		await _tap(KEY_G)
		await _ticks(2)
		_check(offering and reach and hook.phase == HANG, "count", tag + "%s in talk reach of the hanging hero (%s %s, reach %s, phase %d; precondition)" % [who, talking, offering, reach, hook.phase])
		_check(not shown and not events.dialogue.opened, "talk", tag + "hanging on the rope, %s prompt stays hidden (%s) and G opens no menu (%s)" % [whose, shown, events.dialogue.opened])
	await _clean_event(world)


func _spec_at(point: Vector3) -> Dictionary:
	for spec: Dictionary in supports:
		if Vector3(spec.point).distance_to(point) <= 0.01:
			return spec
	return {}


## A rope left hanging under anchor 3 (the slide to the floor), the hero standing where the slide put him.
func _leave_rope(world: Node) -> int:
	var hook: Node = world.player.grapple
	await _reset(world, _starts_for(world, 3)[0], supports[3].point)
	if not await _hang_on(world, 3):
		return 0
	var token: int = hook._deployed_token
	await _settle_pull(hook)
	_key(KEY_SHIFT, true)
	for tick: int in 200:
		await _ticks(1)
		if hook.phase != HANG:
			break
	_key(KEY_SHIFT, false)
	await _ticks(4)
	return token if world.ropes.records.has(token) and bool(world.ropes.records[token].deployed) else 0


func _reel(world: Node, hero: String) -> void:
	var hero_node: CharacterBody3D = world.player
	var hook: Node = hero_node.grapple
	var tag := "[%s] " % hero
	# П-3: time = distance / 9 ± 1 tick, the slot back at the hand.
	var token := await _leave_rope(world)
	_check(token != 0, "reel", tag + "a rope stays hanging after the slide")
	if token == 0:
		return
	var anchor: Vector3 = world.ropes.records[token].anchor
	var hand := hero_node.global_position + Vector3(0, HAND_Y, 0)
	var stock: int = hook.charges
	var expected := ceili(maxf(0.5, hand.distance_to(anchor)) / REWIND_SPEED * 60.0)
	await _tap(KEY_G)
	var ticks := 0
	var max_speed := 0.0
	var off_hands := 0.0
	var off_judged := 0
	var skeleton: Skeleton3D = hero_node.skeletal.hero_skeleton
	_key(KEY_W, true)
	while hook.phase == MISS_REWIND and ticks < 200:
		await _ticks(1)
		ticks += 1
		if hook.phase == MISS_REWIND:
			max_speed = maxf(max_speed, Vector2(hero_node.velocity.x, hero_node.velocity.z).length())
			# T6 § 9 п. 4: the reeled rope leaves between the two hands (Fish_Reel), once the pose has come in.
			var visual: Node = hook._rope_visual
			if ticks > REEL_HANDS_SETTLE and visual != null and visual.visible and not visual.points.is_empty():
				var middle: Vector3 = (_bone_world(skeleton, "LeftHand") + _bone_world(skeleton, "RightHand")) * 0.5
				off_hands = maxf(off_hands, Vector3(visual.points[0]).distance_to(middle))
				off_judged += 1
	_key(KEY_W, false)
	_check(off_judged > 0 and off_hands <= REEL_HANDS_GAP, "reel_hands", tag + "T6 § 9 п. 4: the reeled rope leaves %.3f m from between the hands at most (%d ticks after the first %d), at most %.2f" % [off_hands, off_judged, REEL_HANDS_SETTLE, REEL_HANDS_GAP])
	_check(absi(ticks - expected) <= 1 and hook.charges == stock + 1 and not world.ropes.records.has(token), "reel", tag + "П-3: the reel took %d ticks (%.2f m / 9 → %d), the stock %d → %d" % [ticks, hand.distance_to(anchor), expected, stock, hook.charges])
	var walk: float = float(hero_node.data.walk_speed) * hero_node.speed_mult() / 1.0
	_check(max_speed <= float(hero_node.data.walk_speed) * RECOVERY_MOVE + 0.05, "reel", tag + "П-3: movement × %.2f while reeling (max %.3f m/s, walk %.3f)" % [RECOVERY_MOVE, max_speed, walk])
	# A dodge pauses it.
	token = await _leave_rope(world)
	if token != 0:
		await _tap(KEY_G)
		await _ticks(3)
		await _tap(KEY_SHIFT)
		var paused := false
		var left_before: float = hook.recovery_remaining
		for tick: int in 6:
			await _ticks(1)
			if hero_node.state == STATE_DASH:
				paused = paused or absf(hook.recovery_remaining - left_before) <= 0.000001
			left_before = hook.recovery_remaining
		_check(paused, "reel", tag + "П-3: a dodge pauses the reel")
		for tick: int in 120:
			await _ticks(1)
			if hook.phase == 0:
				break
	# П-4 control (T4 audit 15а RED-2 а): from REEL_RANGE − 0.5 m, the line clear, the reel is offered and takes the rope.
	token = await _leave_rope(world)
	if token != 0:
		anchor = world.ropes.records[token].anchor
		var near := _reel_spot(world, anchor, REEL_RANGE - 0.5)
		_check(near.is_finite(), "reel", tag + "П-4 control: a standing spot %.1f m from the anchor with a clear line" % (REEL_RANGE - 0.5))
		if near.is_finite():
			hero_node.global_position = near
			hero_node.velocity = Vector3.ZERO
			await _ticks(2)
			stock = hook.charges
			var hand_now: Vector3 = hero_node.global_position + Vector3(0, HAND_Y, 0)
			var offered_near: bool = not hook.reel_candidate().is_empty()
			await _tap(KEY_G)
			for tick: int in 140:
				await _ticks(1)
				if hook.phase == 0:
					break
			_check(offered_near and hook.charges == stock + 1 and not world.ropes.records.has(token), "reel", tag + "П-4 control: %.2f m from the anchor, the line clear %s — the reel is offered (%s) and takes the rope (stock %d → %d)" % [hand_now.distance_to(anchor), hook.line_clear(hand_now, anchor), offered_near, stock, hook.charges])
		world.ropes.clear_match()
	# П-4: refusals change nothing — past 14 m (REEL_RANGE + 0.5 on a clear line), behind a wall, somebody on the rope, a
	# foreign rope.
	for refusal: String in ["far", "wall", "hung", "foreign"]:
		token = await _leave_rope(world)
		if token == 0:
			_check(false, "reel_refuse", tag + "П-4 %s: no rope left to refuse" % refusal)
			continue
		anchor = world.ropes.records[token].anchor
		var other: Node3D = null
		var wall: StaticBody3D = null
		match refusal:
			"far":
				# The distance alone refuses it: a standing spot REEL_RANGE + 0.5 m from the anchor whose line is clear (a
				# precondition, class 11 — the old spot was refused by a wall at 16.8 m, T4 audit 15а). A precondition is
				# `count`, never the subject's family (T4 re-audit 15а Y-F: `reel_range` must not go red by a broken spot).
				var spot := _reel_spot(world, anchor, REEL_RANGE + 0.5)
				_check(spot.is_finite(), "count", tag + "П-4 far: a standing spot %.1f m from the anchor with a clear line" % (REEL_RANGE + 0.5))
				if spot.is_finite():
					hero_node.global_position = spot
				hero_node.velocity = Vector3.ZERO
			"wall":
				wall = StaticBody3D.new()
				wall.collision_layer = 1
				var shape := CollisionShape3D.new()
				var box := BoxShape3D.new()
				box.size = Vector3(1.2, 1.2, 0.1)
				shape.shape = box
				wall.add_child(shape)
				world.add_child(wall)
				var from := hero_node.global_position + Vector3(0, HAND_Y, 0)
				wall.global_transform = Transform3D(Basis.looking_at((anchor - from).normalized(), Vector3.UP if absf((anchor - from).normalized().y) < 0.99 else Vector3.FORWARD), from.lerp(anchor, 0.5))
			"hung":
				other = (load("res://scenes/fighter/Fighter.tscn") as PackedScene).instantiate()
				other.data = load("res://data/characters/skea.tres")
				other.player_index = 2
				world.add_child(other)
				other.set_physics_process(false)
				other.global_position = Vector3(anchor.x, anchor.y - 5.0, anchor.z)
				other.grapple._attach_existing(token)
			"foreign":
				world.ropes.records[token].owner = 2
		await _ticks(2)
		var before: Dictionary = world.ropes.records.duplicate(true)
		stock = hook.charges
		var offered: bool = not hook.reel_candidate().is_empty()
		if refusal == "far":
			var hand_far: Vector3 = hero_node.global_position + Vector3(0, HAND_Y, 0)
			_check(hook.line_clear(hand_far, anchor) and absf(hand_far.distance_to(anchor) - (REEL_RANGE + 0.5)) <= 0.05, "count", tag + "П-4 far: the precondition holds — %.2f m, the line clear %s" % [hand_far.distance_to(anchor), hook.line_clear(hand_far, anchor)])
		await _tap(KEY_G)
		await _ticks(3)
		_check(not offered and hook.phase == 0 and hook.charges == stock and world.ropes.records.has(token) and bool(world.ropes.records[token].deployed), "reel_refuse", tag + "П-4 %s: the reel is refused and nothing changes (offered %s, phase %d, stock %d → %d)" % [refusal, offered, hook.phase, stock, hook.charges])
		if wall != null:
			wall.free()
		if other != null:
			other.grapple.detach()
			other.free()
		world.ropes.clear_match()


## A standing spot whose hand is `distance` from `anchor` with a clear line (GrappleHook.line_clear): a floor with headroom,
## searched around the anchor in 32 bearings. INF when there is none.
func _reel_spot(world: Node, anchor: Vector3, distance: float) -> Vector3:
	var space: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state
	var hook: Node = world.player.grapple
	for bearing: int in 32:
		var angle := TAU * float(bearing) / 32.0
		var flat := Vector3(cos(angle), 0, sin(angle))
		# The floor under the spot is found first at a guess of the radius, then the radius is solved for that floor.
		var radius := distance
		for pass_index: int in 3:
			var probe := anchor + flat * radius
			var hit := _ray(space, Vector3(probe.x, anchor.y + 0.5, probe.z), Vector3(probe.x, -1.0, probe.z), 1)
			if hit.is_empty() or Vector3(hit.normal).y < 0.7:
				radius = -1.0
				break
			var rise: float = anchor.y - (float(hit.position.y) + HAND_Y)
			if absf(rise) >= distance:
				radius = -1.0
				break
			radius = sqrt(distance * distance - rise * rise)
		if radius <= 0.0:
			continue
		var spot := anchor + flat * radius
		var floor_hit := _ray(space, Vector3(spot.x, anchor.y + 0.5, spot.z), Vector3(spot.x, -1.0, spot.z), 1)
		if floor_hit.is_empty() or Vector3(floor_hit.normal).y < 0.7:
			continue
		var feet := Vector3(spot.x, float(floor_hit.position.y), spot.z)
		var hand := feet + Vector3(0, HAND_Y, 0)
		if absf(hand.distance_to(anchor) - distance) > 0.02 or not _ray(space, feet + Vector3(0, 0.05, 0), feet + Vector3(0, CLEARANCE, 0), 1).is_empty():
			continue
		if hook.line_clear(hand, anchor):
			return feet + Vector3.UP * 0.02
	return Vector3.INF


## P13: the rows the city rope adds, as shown, each one line in the hint label (font 18, 1552 px; T8 § 4).
func _hud_rows(world: Node, hero: String) -> void:
	var hud: Node = world.hud
	var label: Label = hud.hint_label
	var font: Font = label.get_theme_font("font")
	var size := label.get_theme_font_size("font_size")
	var seen: Dictionary = {}
	var hook: Node = world.player.grapple
	await _reset(world, _starts_for(world, 3)[0], supports[3].point)
	if await _hang_on(world, 3):
		for tick: int in 60:
			await _ticks(1)
			if label.visible:
				seen[label.text] = true
		_key(KEY_SPACE, true)
		for tick: int in 140:
			await _ticks(1)
			if label.visible:
				seen[label.text] = true
			if hook.phase == PERCH:
				break
		for tick: int in 10:
			await _ticks(1)
			seen[label.text] = true
		_key(KEY_SPACE, false)
		for tick: int in 30:
			await _ticks(1)
			seen[label.text] = true
	var token := await _leave_rope(world)
	if token != 0:
		for tick: int in 3:
			await _ticks(1)
			seen[label.text] = true
	var wanted := {"ROPE · ": false, "ANCHOR · ": false, "Reel in your rope": false}
	for text: String in seen:
		for key: String in wanted:
			if key in text:
				wanted[key] = true
		var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x if font != null else 0.0
		if text.begins_with("ROPE") or text.begins_with("ANCHOR") or "Reel in" in text or text.begins_with("CLIMBING"):
			_check(width <= HINT_WIDTH, "hud", "[%s] P13: «%s» is one line (%.0f px of %.0f)" % [hero, text, width, HINT_WIDTH])
			print("ROPE_CLIMB row %s width=%.0f «%s»" % [hero, width, text])
	for key: String in wanted:
		_check(bool(wanted[key]), "hud", "[%s] P13: a row with «%s» was shown" % [hero, key])
	world.ropes.clear_match()
	# The same rows with the pad's glyphs (T8 acceptance ТЗ 4): the HUD names the pad's buttons after a pad press.
	var pad_seen: Dictionary = {}
	_pad_neutral()
	await _reset(world, _starts_for(world, 3)[0], supports[3].point)
	if await _hang_on(world, 3):
		await _settle_pull(hook)
		_pad(JOY_BUTTON_A, true)
		for tick: int in 140:
			await _ticks(1)
			if label.visible:
				pad_seen[label.text] = true
			if hook.phase == PERCH:
				break
		for tick: int in 10:
			await _ticks(1)
			pad_seen[label.text] = true
		_pad(JOY_BUTTON_A, false)
		for tick: int in 30:
			await _ticks(1)
			pad_seen[label.text] = true
	_pad_neutral()
	await _reset(world, _starts_for(world, 3)[0], supports[3].point)
	if await _hang_on(world, 3):
		await _settle_pull(hook)
		_pad(JOY_BUTTON_X, true)
		for tick: int in 200:
			await _ticks(1)
			if label.visible:
				pad_seen[label.text] = true
			if hook.phase != HANG:
				break
		_pad(JOY_BUTTON_X, false)
		for tick: int in 6:
			await _ticks(1)
			pad_seen[label.text] = true
	_pad_neutral()
	var glyphs := {"ROPE · ": "A / Cross", "ANCHOR · ": "A / Cross", "Reel in your rope": "Y / Triangle + D-pad Down"}
	var found := {"ROPE · ": false, "ANCHOR · ": false, "Reel in your rope": false}
	for text: String in pad_seen:
		for key: String in glyphs:
			if key in text and String(glyphs[key]) in text:
				found[key] = true
		var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x if font != null else 0.0
		if text.begins_with("ROPE") or text.begins_with("ANCHOR") or "Reel in" in text or text.begins_with("CLIMBING"):
			_check(width <= HINT_WIDTH, "hud", "[%s] P13 (pad): «%s» is one line (%.0f px of %.0f)" % [hero, text, width, HINT_WIDTH])
			print("ROPE_CLIMB row %s pad width=%.0f «%s»" % [hero, width, text])
	for key: String in found:
		_check(bool(found[key]), "hud", "[%s] P13 (pad): a row with «%s» named «%s»" % [hero, key, glyphs[key]])
	world.ropes.clear_match()


# --- the duel (--part=duel): its rope stays as it is (T8 § 7) ---------------------------------------------------------

func _duel() -> void:
	var state: Node = root.get_node("GameState")
	state.p1_character = "choko"
	state.p2_is_cpu = true
	state.training_mode = false
	router.apply_profile("solo", false)
	var arena: Node = load("res://scenes/arena/Arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	var p1: CharacterBody3D = arena.get("p1")
	var p2: CharacterBody3D = arena.get("p2")
	await _ticks(100)
	p2.set_physics_process(false)
	p2.global_position = Vector3(18, 0, 0)
	var hook: Node = p1.grapple
	if mutation == "duel_flag":
		# The canary (T8 § 7): the city's climb leaked into the duel with the city's fast profile (as 15в brings it).
		hook.climb_enabled = true
		hook.responsive_parkour = true
	_check(not hook.climb_enabled or mutation == "duel_flag", "duel", "the duel's hook has no city climb")
	var anchors: Array[Vector3] = []
	for node: Node in get_nodes_in_group_safe("grapple_anchor"):
		anchors.append((node as Node3D).global_position)
	var best: Vector3 = anchors[0]
	for point: Vector3 in anchors:
		if point.length() < best.length():
			best = point
	for scenario: String in ["space", "shift", "e"]:
		hook.detach()
		arena.get_node("MatchRopes").clear_match()
		await _ticks(2)
		var stand := Vector3(best.x, 0, best.z) + Vector3(best.x, 0, best.z).normalized() * -3.0
		p1.global_position = stand
		p1.velocity = Vector3.ZERO
		p1._set_forward((Vector3(best.x, 0, best.z) - stand).normalized())
		await _ticks(20)
		await _tap(KEY_E)
		var hung := false
		for tick: int in 60:
			await _ticks(1)
			if hook.attached and hook.phase == HANG:
				hung = true
				break
		_check(hung, "duel", "the duel's E hangs on %s (%s)" % [best, scenario])
		if not hung:
			continue
		await _ticks(40)
		match scenario:
			"space":
				var start: float = hook._hang_start_length
				_key(KEY_SPACE, true)
				await _ticks(80)
				_key(KEY_SPACE, false)
				var expected := minf(start, maxf(MIN_ROPE, start - 1.2))
				_check(hook.attached and absf(hook.rope_length - expected) <= 0.001, "duel", "Space in the duel stops 1.2 m short of the swing length (%.4f, expected %.4f)" % [hook.rope_length, expected])
			"shift":
				_key(KEY_SHIFT, true)
				await _ticks(1)
				_key(KEY_SHIFT, false)
				_check(p1.state == STATE_DASH, "duel", "a dodge on the duel's rope is a dodge (state %d)" % p1.state)
			"e":
				while hook.charges > 0:
					arena.get_node("MatchRopes").issue(1)
				var denied := []
				hook.denied.connect(func(reason: String) -> void: denied.append(reason))
				await _ticks(20)
				await _tap(KEY_E)
				_check(hook.attached and hook.phase == HANG, "duel", "E with no target keeps the duel's hang (attached %s, phase %d, denied %s)" % [hook.attached, hook.phase, denied])
	arena.queue_free()
	current_scene = null
	await _ticks(3)


func get_nodes_in_group_safe(group: String) -> Array[Node]:
	return root.get_tree().get_nodes_in_group(group)
