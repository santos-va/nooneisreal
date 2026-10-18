class_name GrappleHook
extends Node3D
## Charge-based swept harpoon: profiled windup, fixed flight, confirmed contact.
## Hold an attached anchor to hang; Space reels a bounded distance, movement pumps the pendulum.
## The city parkour hook first pulls itself in to the swing length (rope V4); the duel keeps the contact length.
## Finite match inventory. Only recovery refunds; deployed ropes persist across rounds.
## Design: docs/GDD/04-Grapple-System.md

signal changed(charges: int, cooldown_left: float, max_charges: int)
## A traversal press that issued nothing (T8 Г): reason is a HarpoonAim.REASONS code; the HUD words it.
signal denied(reason: String)
## grapple_denied for a traversal press plays at most once per this many physics ticks (0.3 s, PLACEHOLDER).
const DENIED_GAP_TICKS := 18

enum Target { NONE, ANCHOR, ENEMY }

## CLIMB_TOP and PERCH exist only with climb_enabled (the city, ADR-028): the 0.5 s pull-up from the rope's top onto the
## anchor's arm, then the grip on the arm itself with the rope already back in the owner's stock.
enum Phase { IDLE, WINDUP, FLIGHT, HANG, MISS_REWIND, ENEMY_EXTRACT, ROPE_REACH, CLIMB_TOP, PERCH }
var _pending_rope: int = 0
var chain_throw: bool = false
const WINDUP_FRAMES := 30
@export var projectile_speed: float = 36.0 # PLACEHOLDER pending playtest.
@export var contact_distance: float = 0.70 # User-authorized current hand-to-span reach.
var phase: Phase = Phase.IDLE
var windup_progress: float = 0.0
var projectile_position := Vector3.ZERO
var _launch_origin := Vector3.ZERO
var _flight_direction := Vector3.ZERO
var _flight_distance: float = 0.0
var _selected_anchor: Node3D
var _prefer_enemy: bool = false
var _tip: MeshInstance3D
var registry: MatchRopes
var token: int = 0
var action: String = "grapple"
var aim_intent: Dictionary = {}
var recovery_remaining: float = 0.0
var recovery_progress: float = 0.0
var recovery_paused: bool = false
var extract_flash: float = 0.0
var extract_side: String = "right_leg"
@export var recovery_move_scale: float = 0.35 # PLACEHOLDER light manoeuvring.
var _recovery_total: float = 0.0
var _extract_frames: int = 0
var _miss_velocity := Vector3.ZERO
var _victim: Fighter
var _deployed_token: int = 0
var _rope_visual: Node3D
@export var rewind_speed: float = 9.0 # PLACEHOLDER; length-based return, no regeneration.
@export var extract_duration_frames: int = 45 # PLACEHOLDER ordinary hand extraction.
const HAND := Vector3(0.0, 1.25, 0.0)

var fighter: Fighter
var max_charges: int = 3
var charges: int = 3
var cooldown: float = 3.0
var cooldown_left: float = 0.0
## The full wait the current charge started from (fatigue stretches it, 02 § Втома); the HUD fills against it.
var cooldown_total: float = 3.0
var regen_all: bool = false
var range_m: float = 14.0
# PLACEHOLDER feel tuning, approved in 2026-10-04-Combat-Control; playtest on the target device.
@export var reel_speed: float = 2.0
@export var reel_distance: float = 1.2
@export var minimum_rope: float = 2.0
@export var max_speed: float = 11.0
@export var steer_accel: float = 5.0
@export var swing_drag: float = 0.65
@export var swing_speed_ratio: float = 0.85
# Explicitly enabled by city exploration. Duel and enemy shots keep their profile.
# PLACEHOLDER responsive traversal tuning; unchanged constraint and motor budget.
@export var responsive_parkour: bool = false
@export var parkour_windup_frames: int = 10
@export var parkour_projectile_speed: float = 48.0
@export var parkour_reel_speed: float = 3.6
@export var parkour_steer_accel: float = 9.0
@export var parkour_swing_drag: float = 0.30
# Rope V4 (plan 2026-10-09-Rope-Pull-Jump-Arc-Substance-Momentum step 1; T5 Т1–Т7 in
# docs/GDD/2026-10-09-Rope-Pull-And-Jump-Arc-Numbers.md, all PLACEHOLDER): after a city parkour attach the rope
# pulls itself in to the swing length, never lets out; Space then reels reel_distance beyond it.
@export var parkour_pull_speed: float = 8.0
@export var parkour_swing_clearance: float = 0.5
## The settled hang length Space reels from: the contact length, or for the city parkour hook the swing length the
## pull reaches (min(contact, max(minimum_rope, anchor − floor − HAND − clearance)), floor = the higher support under
## the anchor and under the hero at contact).
var _hang_start_length: float = 0.0
## This tick's shortening came from the pull, not from Space (read-only; presentation draws a hang, not a regrip).
var pulling: bool = false
## The colliders the hanging rope's own anchor stands on (its lamp post), from the anchor marker's
## "support" meta; the hang's hand → anchor check skips them (T1, plan 2026-10-09 «Рішення T1 після кроків 1–4»: a
## swing that carries the line behind the post it hangs from keeps the rope). Cornices, awnings and cover still cut.
## Anchors without the meta (the duel's) skip nothing.
var _own_support: Array[RID] = []
var cone_deg: float = 30.0      # free movement only (docs/GDD/04-Grapple-System.md § Конус вибору в 3D)
# The city rope (ADR-028 п. 1–5; plan 2026-10-15-Rope-Climb-Perch-Release step 5, 15а; numbers T5
# docs/GDD/2026-10-15-Rope-Climb-Numbers.md, all PLACEHOLDER until Santos plays it on M3). Set only by CityFighter, never
# by responsive_parkour (T8 § 7): with it off the duel keeps the 1.2 m reel, the dodge off the rope and the deny on E.
var climb_enabled: bool = false
## CityFighter writes it before every drive: +1 climb (jump held), −1 slide (dodge held), 0 neither or both.
var climb_input: int = 0
@export var climb_speed: float = 3.6        # T5 Л1 = parkour_reel_speed (what Santos felt on M3, without the 1.2 m stop)
@export var slide_speed: float = 2.0        # T5 С1 = reel_speed of the duel («плавно»)
@export var climb_top_seconds: float = 0.5  # T5 Л3 = CityParkourProfile.mantle_seconds: rope top → grip on the arm
@export var perch_hand_rise: float = 0.30   # T5 Л4: the grip on the arm, point + 0.30 (CityDistrict arm_y)
## T6 § 3 (docs/Art/2026-10-15-Rope-Climb-Animation.md): the shoulders at point + 0.02, 1.34 / 1.38 m above the feet,
## so the feet 1.32 m under the point; T5 Л5 said 1.75 from reach_height (the journal of this step, § 0, item 1).
@export var perch_feet_below: float = 1.32
## T1 on T6's acceptance 2026-10-15 § 9 п. 8: the pose stays T6's (1.32; T5's 1.75 withdrawn), per hero where that is
## simple — Choko's wrists stop 6–7 cm short of the arm at 1.32, so he hangs PERCH_FEET_RAISE higher (1.28); Skea 1.32.
## PLACEHOLDER (T6 pose).
const PERCH_FEET_RAISE: Dictionary = {"choko": 0.04}
@export var perch_grip_near: float = 0.26   # T6 § 3: the hands 0.26 and 0.66 m from the point toward the mount
@export var perch_grip_far: float = 0.66
## T6 § 3: on the brackets whose tie rod comes down onto the arm's middle from above (22–24) the far hand 0.66 m out is
## 0.07 m from the rod; 0.62 keeps the 0.10 m the struts from below have. PLACEHOLDER: T2's pick, T6 checks the frame.
@export var perch_tie_rod_far: float = 0.62
## T6's re-acceptance 2026-10-15 (the skinned surface, docs/Fix/2026-10-15-Rope-Perch-Mesh-Clearance-Fix.md § 4): on the
## brackets with a strut from below the far sleeve at 0.66 touched the strut's top (Skea, up to 11 vertices 0.018 m deep
## on 6, 7, 9, 16, 17); at 0.62 (T6's variant) 6 and 7 kept 5 vertices 0.007 m deep through the grip's first ticks, at
## 0.58 the steep strut of 19 (BRACE_DROP 0.75) still 1–2 vertices 0.004 m deep, at 0.56 none on any strut. PLACEHOLDER:
## T2's pick, T6 checks the frame.
@export var perch_strut_far: float = 0.56
@export var perch_body_back: float = 0.14   # T6 § 3: the shoulders 0.14 m behind the middle of the grip
## T6's re-acceptance 2026-10-15 (docs/Fix/2026-10-15-Rope-Perch-Mesh-Clearance-Fix.md § 2): Skea's drawn body stands
## on her capsule, Choko's 0.10 m behind his (the rig), so at 0.14 her hair went 0.06 m into the arm and his 0.02; she
## hangs this much further back. Per hero where that is simple, as PERCH_FEET_RAISE. PLACEHOLDER (T6 pose).
const PERCH_BODY_BACK_MORE: Dictionary = {"skea": 0.05}
## The same (§ 3): the pull-up's sideways leg runs this far under the grip's height, so the head passes under the ceramic
## cap and the arm's end and comes up beside the arm, not through them (15а went up to the grip's height first). The cap's
## underside is 0.175 m over the point, the hair's top 0.29–0.31 m on the grip; 0.20 cleared the cap but on bracket 19,
## where the rope's top hangs 0.6 m in under the arm, the head still came up against the steep strut's top. PLACEHOLDER (T2).
const PULL_UP_DUCK: float = 0.30
## The pull-up's share of time for the climb under the rope and for the sideways leg; the rest is the last rise beside the
## arm. 30 ticks in all (T5 Л3), as before. PLACEHOLDER (T2).
const PULL_UP_RISE_SHARE: float = 0.5
const PULL_UP_ACROSS_SHARE: float = 0.3
## --break control of tools/grapple/rope_climb_check.gd (`pull_first`): 0 draws 15а's path (up to the grip's height, then
## across).
var pull_up_duck: float = PULL_UP_DUCK
## The shot from the perch fires at an anchor not lower than the hand (T5 З2); on the rope and on the ground it stays
## 1.5 m above it (HarpoonAim).
const PERCH_MIN_RISE := 0.0
const TRAVERSAL_MIN_RISE := 1.5
## Presentation and HUD read these (never write): this tick the rope shortened by the climb / let out by the slide.
var climbing: bool = false
var sliding: bool = false
## The slide has let the rope out to its whole deployed length in the air (T5 С2: Shift does nothing more).
var rope_end: bool = false
## The last climb found the pull-up onto the arm blocked (T5 Л3): the hero stays at the rope top.
var climb_blocked: bool = false
## The slide put the feet on a floor on this drive: the hook let go, the rope stays deployed (T5 С3).
var slid_to_floor: bool = false
var perch_elapsed: float = 0.0
var perch_anchor: Vector3 = Vector3.ZERO
var perch_pose: Dictionary = {}
var _climb_from: Vector3 = Vector3.ZERO
## The pull-up's corners from the rope's top to the grip (_climb_path) and the progress at which each is reached.
var _climb_way: Array[Vector3] = []
var _climb_marks: Array[float] = []
var _climb_elapsed: float = 0.0
## A shot from the perch: the body keeps gripping the arm through the windup and the flight, until contact (T5 § 3.2).
var _perch_hold: bool = false
## Transfer (ADR-028 п. 5, T3 s7b): the support of the anchor the hero has just left (its lamp post). Only the city's
## new rope passes it, and only while that rope is still pulling the hero in toward the new anchor (rope V4); once the
## pull has settled the usual cover rule applies to it like to any other solid.
var _transfer_skip: Array[RID] = []
## The rewind in progress is the reel of a hanging rope (presentation: Fish_Reel, T6 § 5), not a miss.
var reeling_in: bool = false
## T6 § «Що з цього мусить зробити T2» п. 2: the rope's free end below the hands, down to its deployed length or the floor.
var _tail_visual: Node3D
## T6 acceptance 2026-10-15 § 9 п. 6: the rope coming back on the grip, drawn: the tail shortens to the hand over the pull-up;
## on the grip's tick the hook leaves the ceramic and flies a short arc of RETURN_SECONDS to the waist, the line behind it
## from the hands. The slot is back in the stock on the grip's tick (T5 П1, the game's number); the HUD shows it when the
## hook touches the hero (pending_return(), T1: the HUD and the picture lag, the stock does not). Presentation only.
const RETURN_SECONDS: float = 0.25
const RETURN_ARC: float = 0.35   # the arc's rise over the straight line, m (PLACEHOLDER)
const WAIST := Vector3(0.0, 0.95, 0.0)
## T6's re-acceptance 2026-10-15, N2: the hook lands on the front of the drawn waist, this far ahead of the hips bone (the
## drawn body, not the capsule: Choko's stands 0.10 m behind his), not on the body's axis inside the torso. PLACEHOLDER.
const RETURN_FRONT: float = 0.12
var _return_elapsed: float = -1.0
## T6's re-acceptance 2026-10-15, N3: after a shot from the grip latches, the drawn line's start moves from the throwing
## hand to the right one over LINE_HANDOVER_SECONDS (the city catch, AuthoredHookMotion.PARKOUR_CATCH_SECONDS), not in one
## tick (0.43–0.50 m). Presentation only; the duel never perches.
const LINE_HANDOVER_SECONDS: float = 0.12
var _line_hand: String = ""
var _line_handover: float = -1.0
## T6 acceptance 2026-10-15 § 9 п. 7: a shot from the grip is thrown by the hand on the target's side ("Right"/"Left"), the
## other keeps the arm; "" — no shot from the grip. Presentation reads it; the rope is drawn from that hand until contact.
var throw_hand: String = ""
var _climb_tail: float = 0.0
var _climb_tail_low: float = -INF
var _return_from: Vector3 = Vector3.ZERO

var attached: bool = false
var anchor_point: Vector3 = Vector3.ZERO
var rope_length: float = 0.0
var _frames: int = 0
var _rope: MeshInstance3D
var _rope_mesh: ImmediateMesh


func setup(f: Fighter) -> void:
	fighter = f
	max_charges = f.data.grapple_charges
	charges = max_charges
	cooldown = f.data.grapple_cooldown
	cooldown_total = cooldown
	regen_all = f.data.grapple_regen_all_at_once
	range_m = f.data.grapple_range
	cone_deg = f.data.grapple_cone_deg
	_rope_mesh = ImmediateMesh.new()
	_rope = MeshInstance3D.new()
	_rope.mesh = _rope_mesh
	_rope.top_level = true
	_rope.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = f.data.accent_color.lightened(0.3)
	mat.emission_enabled = true
	mat.emission = f.data.accent_color
	mat.emission_energy_multiplier = 2.0
	_rope.material_override = mat
	_rope.visible = false
	add_child(_rope)
	_tip = MeshInstance3D.new()
	var tip_mesh := CylinderMesh.new()
	tip_mesh.top_radius = 0.0
	tip_mesh.bottom_radius = 0.09
	tip_mesh.height = 0.32
	_tip.mesh = tip_mesh
	_tip.material_override = GearSurface.make("metal",Color("81959a"),f.data.accent_color)
	tip_mesh.radial_segments = 6
	var collar := MeshInstance3D.new()
	var collar_shape := TorusMesh.new()
	collar_shape.inner_radius = 0.062
	collar_shape.outer_radius = 0.075
	collar_shape.rings = 12
	collar_shape.ring_segments = 4
	collar.mesh = collar_shape
	collar.material_override = GearSurface.make("leather",Color("2d3036"),f.data.accent_color)
	collar.position.y = -0.115
	_tip.add_child(collar)
	_tip.top_level = true
	_tip.visible = false
	add_child(_tip)
	var ancestor: Node = fighter.get_parent()
	while ancestor != null and registry == null:
		registry = ancestor.get_node_or_null("MatchRopes") as MatchRopes
		ancestor = ancestor.get_parent()
	if registry == null:
		registry = MatchRopes.new()
		registry.name = "MatchRopes"
		fighter.get_parent().add_child(registry)
	registry.register_hook(self, fighter.player_index, max_charges)
	if ResourceLoader.exists("res://scripts/grapple/RopeVisual.gd"):
		_rope_visual = load("res://scripts/grapple/RopeVisual.gd").new()
		add_child(_rope_visual)
	changed.emit(charges, cooldown_left, max_charges)


func inventory_changed(available: int, capacity: int) -> void:
	charges = available
	max_charges = capacity
	cooldown_left = 0.0
	changed.emit(charges, cooldown_left, max_charges)


func reset() -> void:
	_return_elapsed = -1.0
	# A round returns an unfinished recoverable shot, never a deployed rope.
	if token != 0:
		registry.refund(token, fighter.player_index)
	token = 0
	_finish_idle()
	inventory_changed(registry.available(fighter.player_index), max_charges)


func on_match_cleared() -> void:
	_return_elapsed = -1.0
	token = 0
	_finish_idle()


func recovering() -> bool:
	return phase in [Phase.MISS_REWIND, Phase.ENEMY_EXTRACT]


func hands_busy() -> bool:
	return recovering()


func tick_regen(delta: float, tethered: bool) -> void:
	# Retained call name for HUD/legacy integration: there is no timer regeneration.
	extract_flash = maxf(0.0, extract_flash - delta)
	if busy() and not tethered and not recovering():
		detach()
	if recovering():
		recovery_paused = fighter.frozen_frames > 0 or fighter.hitstop_frames > 0 or fighter.state in [Fighter.State.DASH, Fighter.State.HITSTUN, Fighter.State.BLOCKSTUN, Fighter.State.KO, Fighter.State.LAUNCHED, Fighter.State.KNOCKDOWN, Fighter.State.GETUP, Fighter.State.STUMBLE, Fighter.State.WALL_SPLAT, Fighter.State.INTRO]
		if not recovery_paused:
			_tick_recovery(delta)
		elif phase == Phase.MISS_REWIND:
			_draw_rope(fighter.global_position + HAND, projectile_position)
		elif is_instance_valid(_victim):
			_draw_rope(fighter.global_position + HAND, _victim.global_position + HAND)


func busy() -> bool:
	return phase != Phase.IDLE


func _responsive_traversal() -> bool:
	return responsive_parkour and action == "grapple_parkour" and not _prefer_enemy


## Remaining physical stroke, shared by the motor and its contextual HUD.
func reel_remaining() -> float:
	if not attached or phase != Phase.HANG:
		return 0.0
	var shortest := minf(_hang_start_length, maxf(minimum_rope, _hang_start_length - reel_distance))
	return maxf(0.0, rope_length - shortest)


## Current hand contact only. Future velocity cannot extend the authorized reach.
func rope_grab_candidate(preferred_token: int = 0) -> Dictionary:
	if registry == null:
		return {}
	var hand := fighter.global_position + HAND
	var best: Dictionary = {}
	var best_distance := INF
	for key: int in registry.records:
		var record: Dictionary = registry.records[key]
		if not record.deployed or key == _deployed_token or (preferred_token != 0 and key != preferred_token):
			continue
		if hand.distance_to(record.anchor) > minf(record.length, range_m) + 0.001 or not line_clear(hand, record.anchor):
			continue
		var grip := registry.closest_grip(key, hand)
		var nearest: Vector3 = grip.point
		var distance: float = grip.distance
		if not line_clear(hand, nearest):
			continue
		if distance <= contact_distance + 0.000001 and (distance < best_distance or (is_equal_approx(distance, best_distance) and key < int(best.get("token", key)))):
			best_distance = distance
			best = {"token": key, "point": nearest, "distance": distance, "reachable": true}
	return best


func reusable_rope() -> int:
	return int(rope_grab_candidate().get("token", 0))


## Read-only animation snapshot; distant approach cues are never a hand target.
func presentation_grip() -> Dictionary:
	if attached and phase == Phase.HANG:
		return {"point": fighter.global_position + HAND, "reachable": true, "token": _deployed_token}
	if phase == Phase.ROPE_REACH:
		return rope_grab_candidate(_pending_rope)
	return {}


func _attach_existing(existing: int) -> void:
	if _deployed_token != 0:
		registry.detach_user(_deployed_token, self)
	var record: Dictionary = registry.records[existing]
	_deployed_token = existing
	registry.attach_user(existing, self)
	anchor_point = record.anchor
	rope_length = minf(record.length, (anchor_point - (fighter.global_position + HAND)).length())
	_hang_start_length = _swing_length(rope_length)
	_own_support = _support_of(anchor_point)
	pulling = false
	attached = true
	phase = Phase.HANG
	_frames = 0
	if _tip != null:
		_tip.visible = false


## A deliberate second parkour press changes support without braking momentum.
## Failed aim/stock validation keeps the current rope; the old device stays deployed.
func retarget(recorded_aim: Dictionary = {}) -> bool:
	if not attached or phase != Phase.HANG or fighter.control_locked:
		return false
	var existing := reusable_rope()
	if existing != 0:
		_attach_existing(existing)
		return true
	var packet := recorded_aim.duplicate(true)
	if packet.is_empty():
		var camera := get_viewport().get_camera_3d()
		if camera != null and camera.has_meta("harpoon_aim"):
			packet = camera.get_meta("harpoon_aim").press_packet(fighter, false)
	var id := String(packet.get("target_id", ""))
	var selected := get_node_or_null(NodePath(id)) as Node3D if not id.is_empty() else null
	if packet.get("assist", false) and not (selected != null and selected.is_in_group("deployed_rope")) and not _assist_ready(packet, false):
		# T8 Г: the transfer has no windup, so the same press re-selects once from this hand, else it is denied.
		var fresh := _fresh_traversal()
		if not _assist_ready(fresh, false):
			_deny(_reason_of(fresh))
			return false
		packet = fresh
		id = String(packet.get("target_id", ""))
		selected = get_node_or_null(NodePath(id)) as Node3D
	if selected != null and selected.is_in_group("deployed_rope"):
		var old_intent := aim_intent
		aim_intent = packet
		if _prepare_rope_catch():
			registry.detach_user(_deployed_token, self)
			_deployed_token = 0
			attached = false
			return true
		aim_intent = old_intent
		return false
	if selected == null or not selected.is_in_group("grapple_anchor") or charges <= 0 or registry.occupied(selected.global_position):
		return false
	var hand := fighter.global_position + HAND
	if hand.distance_to(selected.global_position) > range_m or not line_clear(hand, selected.global_position):
		return false
	# The target is validated before releasing support. Launch spends exactly once.
	# The city's new rope passes the post just left while it pulls the hero away from it (ADR-028 п. 5, T3 s7b).
	_transfer_skip.clear()
	if climb_enabled:
		_transfer_skip.append_array(_own_support)
	registry.detach_user(_deployed_token, self)
	_deployed_token = 0
	attached = false
	action = "grapple_parkour"
	_prefer_enemy = false
	aim_intent = packet
	# Validation and launch must agree even if an old snapshot carries a stale point.
	aim_intent.point = selected.global_position
	chain_throw = true
	_launch()
	return phase == Phase.FLIGHT


func fire(prefer_enemy: bool, shot_action: String = "grapple", recorded_aim: Dictionary = {}) -> int:
	if busy():
		return Target.NONE
	action = shot_action
	_prefer_enemy = prefer_enemy
	aim_intent = recorded_aim.duplicate(true)
	if aim_intent.is_empty():
		var camera := get_viewport().get_camera_3d()
		if camera != null and camera.has_meta("harpoon_aim"):
			var aim: Node = camera.get_meta("harpoon_aim")
			aim_intent = aim.press_packet(fighter, prefer_enemy)
	if not prefer_enemy:
		var existing := reusable_rope()
		if existing != 0:
			_attach_existing(existing)
			return Target.ANCHOR
	if not prefer_enemy and _prepare_rope_catch():
		return Target.ANCHOR
	# A distant/stale rope cue never falls through to issuing a new device.
	if not prefer_enemy and _rope_intent():
		return Target.NONE
	if _assist_intent() and not _assist_ready(aim_intent, true):
		# T8 Г: no target, no shot — no windup, no slot, no fatigue and no throw animation; a sound and a reason.
		var fresh := _fresh_traversal() if charges > 0 else {}
		if not _assist_ready(fresh, true):
			_deny("no_harpoons" if charges <= 0 else _reason_of(aim_intent if fresh.is_empty() else fresh))
			return Target.NONE
		aim_intent = fresh
	if _recorded_anchor_occupied():
		Sfx.play("grapple_denied", -4)
		return Target.NONE
	if charges <= 0:
		Sfx.play("grapple_denied", -4)
		return Target.NONE
	phase = Phase.WINDUP
	_frames = 0
	windup_progress = 0.0
	return Target.ENEMY if prefer_enemy else Target.ANCHOR


func _rope_intent() -> bool:
	if aim_intent.get("candidate_kind", "") == "rope" or int(aim_intent.get("rope_token", 0)) != 0:
		return true
	var id := String(aim_intent.get("target_id", ""))
	var marker := get_node_or_null(NodePath(id)) as Node3D if not id.is_empty() else null
	return marker != null and marker.is_in_group("deployed_rope")

func _prepare_rope_catch() -> bool:
	var id := String(aim_intent.get("target_id", ""))
	var marker := get_node_or_null(NodePath(id)) as Node3D if not id.is_empty() else null
	if marker == null or not marker.is_in_group("deployed_rope"):
		return false
	var key := int(marker.get_meta("rope_token", 0))
	var record: Dictionary = registry.records.get(key, {})
	if record.is_empty() or not record.deployed:
		return false
	var contact := rope_grab_candidate(key)
	if contact.is_empty():
		return false
	_pending_rope = key
	_rope.visible = false
	if _rope_visual != null:
		_rope_visual.visible = false
	anchor_point = contact.point
	phase = Phase.ROPE_REACH
	return true


func _drive_rope_reach(_delta: float, held: bool) -> void:
	if not held or not registry.records.has(_pending_rope):
		_finish_idle()
		return
	var record: Dictionary = registry.records[_pending_rope]
	var hand := fighter.global_position + HAND
	var grab := rope_grab_candidate(_pending_rope)
	if int(grab.get("token", 0)) == _pending_rope:
		_attach_existing(_pending_rope)
		_pending_rope = 0
		_draw_rope(hand, record.anchor)
		return
	# Moving support or a new blocker invalidates preparation before confirmation.
	_finish_idle()


func _recorded_anchor_occupied() -> bool:
	if _prefer_enemy or aim_intent.is_empty():
		return false
	var id := String(aim_intent.get("target_id", ""))
	var selected := get_node_or_null(NodePath(id)) as Node3D if not id.is_empty() else null
	return selected != null and registry.occupied(selected.global_position)


## The current shot carries a traversal packet (human P1, solo camera, never the enemy hook): T8 Г applies.
func _assist_intent() -> bool:
	return not _prefer_enemy and aim_intent.get("assist", false)


## A traversal packet may launch now: a free anchor with stock, on a clear line from the hand, in range of the hand now
## and of the hand at contact (contact_hand). `with_windup` for a fresh press; a launch or a transfer has none left.
func _assist_ready(packet: Dictionary, with_windup: bool) -> bool:
	if packet.is_empty() or charges <= 0:
		return false
	var id := String(packet.get("target_id", ""))
	var selected := get_node_or_null(NodePath(id)) as Node3D if not id.is_empty() else null
	if selected == null or not selected.is_in_group("grapple_anchor") or registry.occupied(selected.global_position):
		return false
	var hand := fighter.global_position + HAND
	var point := selected.global_position
	return hand.distance_to(point) <= range_m and point.distance_to(contact_hand(point, with_windup)) <= range_m and line_clear(hand, point)


## T8 Г: where the hand meets `point` if a traversal shot is taken now. A fresh press first travels through the windup
## (the city keeps its run; the duel brakes to a stop at 30 m/s², see drive), then the body coasts during the flight.
## A point beyond range from that hand would rewind at contact (_flight), so selection and launch refuse it. The hand
## path is a straight line, so checking now and at contact also covers the launch hand.
func contact_hand(point: Vector3, with_windup: bool) -> Vector3:
	var hand := fighter.global_position + HAND
	var flat := Vector3(fighter.velocity.x, 0.0, fighter.velocity.z)
	if with_windup and not responsive_parkour:
		if flat.length() < 0.001:
			return hand
		return hand + flat.normalized() * minf(flat.length() * float(WINDUP_FRAMES) / 60.0, flat.length_squared() / 60.0)
	if with_windup:
		hand += flat * float(parkour_windup_frames) / 60.0
	var speed := parkour_projectile_speed if responsive_parkour else projectile_speed
	return hand + flat * (hand.distance_to(point) / maxf(1.0, speed))


## A new traversal selection from the fighter's actual hand by the same rules, anchors only (a device is about to be
## launched); never remembered (the camera owns that).
func _fresh_traversal() -> Dictionary:
	var camera := get_viewport().get_camera_3d()
	if camera == null or not camera.has_meta("harpoon_aim"):
		return {}
	var packet: Dictionary = camera.get_meta("harpoon_aim").capture(fighter, false, false, true)
	return packet if packet.get("assist", false) else {}


func _reason_of(packet: Dictionary) -> String:
	if charges <= 0:
		return "no_harpoons"
	var reason := String(packet.get("reason", ""))
	return reason if not reason.is_empty() else "none"


func _deny(reason: String) -> void:
	if Engine.get_physics_frames() - int(Sfx.last_frame.get("grapple_denied", -1000000)) >= DENIED_GAP_TICKS:
		Sfx.play("grapple_denied", -4)
	denied.emit(reason)


func _launch() -> void:
	if _assist_intent() and not chain_throw and not _assist_ready(aim_intent, false):
		# T8 Г: the windup moved the hand (or the point was taken). Re-select from the actual hand before spending;
		# nothing to launch at returns to IDLE with no slot or fatigue spent. A shot into empty air never happens.
		var fresh := _fresh_traversal()
		if not _assist_ready(fresh, false):
			_deny(_reason_of(fresh))
			_finish_idle()
			return
		aim_intent = fresh
	if _recorded_anchor_occupied():
		Sfx.play("grapple_denied", -4)
		_finish_idle()
		return
	_spend()
	if token == 0:
		_finish_idle()
		return
	_launch_origin = fighter.global_position + HAND
	projectile_position = _launch_origin
	_selected_anchor = null if _prefer_enemy else _best_anchor()
	var aim := aim_axis() if GameState.free_move else Vector3(float(fighter.facing), 0, 0)
	if is_instance_valid(_selected_anchor):
		aim = _selected_anchor.global_position - _launch_origin
	if not aim_intent.is_empty():
		aim = Vector3(aim_intent.point) - _launch_origin
		_selected_anchor = get_node_or_null(NodePath(String(aim_intent.get("target_id", "")))) as Node3D if not _prefer_enemy and String(aim_intent.get("target_id", "")) != "" else null
	anchor_point = _launch_origin + aim
	_flight_direction = aim.normalized()
	_flight_distance = 0.0
	phase = Phase.FLIGHT
	_tip.visible = true
	_tip.global_position = projectile_position
	_tip.global_basis = Basis(Quaternion(Vector3.UP, _flight_direction))
	_rope.visible = true
	Sfx.play("grapple_fire")


func _flight(delta: float, held: bool) -> void:
	var speed := parkour_projectile_speed if _responsive_traversal() else projectile_speed
	var step := minf(speed * delta, range_m - _flight_distance)
	var end := projectile_position + _flight_direction * step
	var q := PhysicsRayQueryParameters3D.create(projectile_position, end, ArenaLayout.COVER_LAYER | 1 | 4)
	q.collide_with_areas = true
	q.hit_from_inside = true
	q.exclude = [fighter.get_rid(), fighter.hurtbox.get_rid()]
	var hit := fighter.get_world_3d().direct_space_state.intersect_ray(q)
	var anchor_hit := false
	var anchor_t := INF
	if is_instance_valid(_selected_anchor):
		# The point anchor is hit only when this fixed ray reaches its selected point.
		var to_anchor := _selected_anchor.global_position - projectile_position
		anchor_t = to_anchor.dot(_flight_direction)
		anchor_hit = anchor_t >= 0.0 and anchor_t <= step and (to_anchor - _flight_direction * anchor_t).length() < 0.05
	var hit_distance: float = projectile_position.distance_to(hit.position) if not hit.is_empty() else INF
	if anchor_hit and anchor_t < hit_distance:
		anchor_point = _selected_anchor.global_position
		rope_length = (anchor_point - (fighter.global_position + HAND)).length()
		if rope_length > range_m:
			projectile_position = anchor_point
			_begin_rewind()
			return
		_frames = 0
		if _perch_hold and not throw_hand.is_empty():
			_line_hand = throw_hand
			_line_handover = 0.0
		_perch_hold = false
		# Two projectiles may select the same free point before either arrives.
		# The registry owns this atomic check; a rejected shot remains recoverable.
		if not registry.deploy(token, fighter.player_index, anchor_point, fighter.global_position + HAND, rope_length):
			projectile_position = anchor_point
			_begin_rewind()
			return
		_hang_start_length = _swing_length(rope_length)
		_own_support = _support_of(anchor_point)
		pulling = false
		_deployed_token = token
		registry.attach_user(token, self)
		token = 0
		if _assist_intent():
			Sfx.play("grapple_anchor", -6) # T8: silent until the sound is added with its registry row.
		attached = held
		phase = Phase.HANG if held else Phase.IDLE
		_tip.visible = false
		if not held:
			_finish_idle()
		return
	if not hit.is_empty():
		var area := hit.collider as Area3D
		if area != null:
			var victim := area.get_parent() as Fighter
			if _prefer_enemy and victim != null and victim != fighter and victim.hurtbox_enabled():
				_confirm_pull(victim)
				_victim = victim
				phase = Phase.ENEMY_EXTRACT
				_extract_frames = 0
				recovery_progress = 0.0
				_tip.visible = false
				return
		projectile_position = hit.position
		_begin_rewind()
		return
	projectile_position = end
	_flight_distance += step
	_tip.global_position = end
	_draw_rope(fighter.global_position + HAND, end)
	if _flight_distance >= range_m:
		_begin_rewind()


func _spend() -> void:
	token = registry.issue(fighter.player_index)
	if token != 0:
		fighter.add_fatigue(Fighter.FATIGUE_GRAPPLE_S)


## One charge's recharge now: the data's cooldown × the fighter's fatigue.
func _recharge() -> float:
	cooldown_total = cooldown * fighter.fatigue_mult(Fighter.FATIGUE_GRAPPLE)
	return cooldown_total


## Free movement: the cone axis — the camera-relative stick when it is deflected, else where the
## fighter looks. Direction is captured once at launch, never homing.
func aim_axis() -> Vector3:
	var w := fighter.wish()
	return Vector3(w.x, 0.0, w.z).normalized() if Vector3(w.x, 0.0, w.z).length() > 0.1 else fighter.forward


## Yaw-only cone test: is `to` within cone_deg of `axis` on the ground plane? A target straight
## above has no yaw and counts as inside.
func _in_cone(to: Vector3, axis: Vector3) -> bool:
	var flat := Vector3(to.x, 0.0, to.z)
	if flat.length() < 0.05:
		return true
	return flat.normalized().dot(axis) >= cos(deg_to_rad(cone_deg))


## The anchor fire() would pick right now (null = none); public for the smoke test.
## World geometry blocks selection, transfer, catches and loaded ropes alike.
## Fighter bodies/hurtboxes are excluded; solid city roofs and floors are not.
## `skip` — extra colliders the ray ignores (the hang passes its anchor's own support, _own_support).
func line_clear(from: Vector3, to: Vector3, skip: Array[RID] = []) -> bool:
	if not is_inside_tree():
		return true
	var q := PhysicsRayQueryParameters3D.create(from, to, ArenaLayout.COVER_LAYER | 1)
	q.hit_from_inside = true
	var exclude: Array[RID] = [fighter.get_rid(), fighter.hurtbox.get_rid()]
	exclude.append_array(skip)
	q.exclude = exclude
	return fighter.get_world_3d().direct_space_state.intersect_ray(q).is_empty()


## The colliders the anchor at `point` declares as its own support ("support" meta of its grapple_anchor marker;
## CityDistrict sets it to the lamp post it builds; its brackets have no collider). Empty for anchors without it.
func _support_of(point: Vector3) -> Array[RID]:
	var rids: Array[RID] = []
	if not is_inside_tree():
		return rids
	for n in get_tree().get_nodes_in_group("grapple_anchor"):
		var marker := n as Node3D
		if marker == null or marker.global_position.distance_to(point) > 0.01:
			continue
		for body in marker.get_meta("support", []):
			var solid := body as CollisionObject3D
			if is_instance_valid(solid):
				rids.append(solid.get_rid())
	return rids


func best_anchor() -> Node3D:
	return _best_anchor()


func _best_anchor() -> Node3D:
	var best: Node3D = null
	var best_score := INF
	var origin := fighter.global_position + HAND
	var axis := aim_axis() if GameState.free_move else Vector3.ZERO
	for n in get_tree().get_nodes_in_group("grapple_anchor"):
		var a := n as Node3D
		if a == null or (registry != null and registry.occupied(a.global_position)):
			continue
		var to := a.global_position - origin
		var d := to.length()
		if d > range_m or d < 1.5:
			continue
		if to.y < 1.5:
			continue
		if not line_clear(origin, a.global_position):
			continue   # A3: an anchor behind cover is not picked (04 § Правило укриття)
		var fwd := to.x * float(fighter.facing)
		if GameState.free_move:
			if not _in_cone(to, axis):
				continue
			fwd = Vector3(to.x, 0.0, to.z).dot(axis)
		if fwd < -1.5:
			continue
		var score := d - fwd * 0.6
		if score < best_score:
			best_score = score
			best = a
	return best


## Inextensible pendulum: motor work comes only from bounded Space reeling and, for the city parkour hook, the pull to
## the swing length.
## Constraint displacement moves the body but is removed from stored radial momentum.
func drive(delta: float, held: bool, reel_held: bool = false) -> void:
	if delta <= 0.0:
		return
	slid_to_floor = false
	if phase == Phase.ROPE_REACH:
		_drive_rope_reach(delta, held or reel_held)
		return
	if phase == Phase.PERCH:
		_drive_perch(delta)
		return
	if phase == Phase.CLIMB_TOP:
		_drive_climb_top(delta)
		return
	if _perch_hold:
		# A shot from the perch: the hands stay on the arm until contact, while the grip lasts (T5 § 3.2).
		perch_elapsed += delta
		if perch_elapsed > perch_limit():
			_perch_hold = false
	if phase == Phase.WINDUP:
		if not _prefer_enemy:
			var existing := reusable_rope()
			if existing != 0:
				_perch_hold = false
				_attach_existing(existing)
				_draw_rope(fighter.global_position + HAND, anchor_point)
				return
		_frames += 1
		var windup_frames := maxi(1, parkour_windup_frames) if _responsive_traversal() else WINDUP_FRAMES
		windup_progress = float(_frames) / float(windup_frames)
		if _perch_hold:
			fighter.velocity = Vector3.ZERO
		else:
			if not _responsive_traversal():
				fighter.velocity.x = move_toward(fighter.velocity.x, 0.0, 30.0 * delta)
				fighter.velocity.z = move_toward(fighter.velocity.z, 0.0, 30.0 * delta)
			fighter.velocity.y -= Fighter.GRAVITY * delta
			fighter.move_and_slide()
		if _frames >= windup_frames:
			_launch()
		return
	if phase == Phase.FLIGHT:
		if _perch_hold:
			fighter.velocity = Vector3.ZERO
		else:
			fighter.velocity.y -= Fighter.GRAVITY * delta
			fighter.move_and_slide()
		_flight(delta, held or reel_held)
		return
	if not attached:
		return
	_frames += 1
	if not held and not reel_held:
		_release(false)
		return
	var f := fighter
	var hand := f.global_position + HAND
	var radial := (anchor_point - hand).normalized()
	var wish := f.wish() if GameState.free_move else Vector3(InputRouter.axis(f.player_index), 0, 0)
	if f.control_locked:
		wish = Vector3.ZERO
		reel_held = false
	# Т7: one tick shortens by the larger of the pull and Space, never their sum. The pull stops at the swing length,
	# Space at reel_distance beyond it (reel_remaining); neither ever lets the rope out.
	var pull_step := 0.0
	if _responsive_traversal() and rope_length > _hang_start_length:
		pull_step = minf(maxf(0.0, parkour_pull_speed * delta), rope_length - _hang_start_length)
	var reel_step := 0.0
	var slide_step := 0.0
	if climb_enabled and _responsive_traversal():
		# ADR-028 п. 1–2 (T5 Л1, С1, С2): the held jump climbs to the 2.0 m pendulum limit, the held dodge lets the rope
		# out to its deployed length, never during the pull and never with the climb (CityFighter gives 0 for both).
		if f.control_locked:
			climb_input = 0
		if climb_input > 0:
			reel_step = minf(maxf(0.0, climb_speed * delta), maxf(0.0, rope_length - minimum_rope))
		elif climb_input < 0 and pull_step <= 0.0:
			slide_step = minf(maxf(0.0, slide_speed * delta), maxf(0.0, slide_limit() - rope_length))
		rope_end = climb_input < 0 and pull_step <= 0.0 and slide_step <= 0.0
	elif reel_held:
		var motor_speed := parkour_reel_speed if _responsive_traversal() else reel_speed
		reel_step = minf(maxf(0.0, motor_speed * delta), reel_remaining())
	pulling = pull_step > 0.0 and pull_step >= reel_step
	climbing = reel_step > 0.0 and reel_step > pull_step
	sliding = slide_step > 0.0
	if pull_step > 0.0 or reel_step > 0.0:
		rope_length -= maxf(pull_step, reel_step)
	elif slide_step > 0.0:
		rope_length += slide_step
		# The slide is the hero's own choice of length: the pull never takes it back (T5 § 2, «ніколи під час тяги»).
		_hang_start_length = maxf(_hang_start_length, rope_length)
	f.velocity.y -= Fighter.GRAVITY * delta
	# Pump below the anchor only; full gravity and drag oppose perpetual powered loops.
	if radial.y > 0.35:
		var pump := parkour_steer_accel if _responsive_traversal() else steer_accel
		f.velocity += (wish - radial * wish.dot(radial)) * pump * delta
	var drag := parkour_swing_drag if _responsive_traversal() else swing_drag
	f.velocity *= exp(-drag * delta)
	var speed_limit := minf(max_speed, sqrt(Fighter.GRAVITY * maxf(rope_length, 0.01)) * swing_speed_ratio)
	f.velocity = f.velocity.limit_length(speed_limit)
	if not GameState.free_move:
		f.velocity.z = 0.0
	var next := hand + f.velocity * delta
	var off := next - anchor_point
	var taut := off.length() >= rope_length
	if taut:
		next = anchor_point + off.normalized() * rope_length
	f.velocity = (next - hand) / delta
	f.move_and_slide()
	if taut:
		# A reel correction is not an inward launch on the next frame. Retain tangent
		# momentum after collision response instead of overwriting the constraint result.
		var normal := (f.global_position + HAND - anchor_point).normalized()
		f.velocity = f.velocity.slide(normal).limit_length(speed_limit)
	# T5 С3: the slide puts the feet on a floor — the hook lets go on this tick, the rope stays deployed as it is.
	if sliding and f.is_on_floor():
		slid_to_floor = true
		_release(false)
		return
	# The anchor's own post / bracket never cuts its rope; every other solid on hand → anchor does (04 § Трос V4).
	var skip: Array[RID] = _own_support
	if not _transfer_skip.is_empty():
		if rope_length > _hang_start_length + 0.000001:
			skip = []
			skip.append_array(_own_support)
			skip.append_array(_transfer_skip)
		else:
			_transfer_skip.clear()
	if not line_clear(f.global_position + HAND, anchor_point, skip):
		_release(false)
		return
	_draw_rope(f.global_position + HAND, anchor_point)
	_draw_tail(delta)
	# T5 Л3: the held climb at the 2.0 m limit becomes the 0.5 s pull-up onto the anchor's arm, if its path is clear.
	if climb_enabled and climb_input > 0 and not pulling and rope_length <= minimum_rope + 0.000001:
		_begin_climb_top()


## Т3/Т4: the length whose lowest point keeps the hand parkour_swing_clearance above a standing hand on the higher of
## the supports under the anchor and under the hero now. Only the city parkour hook pulls; the duel, the enemy hook and
## a missing support keep `contact`. The outer min never lets the rope out.
func _swing_length(contact: float) -> float:
	if not _responsive_traversal() or not is_inside_tree():
		return contact
	var support := maxf(_support_below(anchor_point + Vector3.DOWN * 0.05), _support_below(fighter.global_position + Vector3.UP * 0.05))
	if is_inf(support):
		return contact
	return minf(contact, maxf(minimum_rope, anchor_point.y - support - HAND.y - parkour_swing_clearance))


## Height of the first solid world surface straight below `from` (-INF when there is none within 64 m). A read-only
## query on the body layer; the fighter's own body and hurtbox are excluded.
func _support_below(from: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 64.0, 1)
	q.exclude = [fighter.get_rid(), fighter.hurtbox.get_rid()]
	var hit := fighter.get_world_3d().direct_space_state.intersect_ray(q)
	return -INF if hit.is_empty() else float(hit.position.y)


## ADR-028 (the city only, climb_enabled): the rope's top, the anchor's arm and the rope coming back. ------------------

## How long the perch grips: CityFighter's hand budget (the ledge's hang_seconds + «Сила», T5 З1); 0 without one.
func perch_limit() -> float:
	return float(fighter.call("perch_limit")) if fighter.has_method("perch_limit") else 0.0


## How far the slide may let the rope out: the length it was deployed with (T5 С2, MatchRopes record.length).
func slide_limit() -> float:
	var record: Dictionary = registry.records.get(_deployed_token, {}) if registry != null else {}
	return float(record.get("length", rope_length))


## The height filter of the traversal selection: an anchor not lower than the hand from the perch (T5 З2), else 1.5 m
## above it.
func target_min_rise() -> float:
	return PERCH_MIN_RISE if phase == Phase.PERCH or _perch_hold else TRAVERSAL_MIN_RISE


## Presentation reads it (never writes): the hands are on an anchor's arm, not on a rope — the pull-up onto it, the grip,
## or a shot from the grip until contact (T6 acceptance 2026-10-15 § 9 п. 2).
func perch_presentation() -> bool:
	return climb_enabled and (phase in [Phase.CLIMB_TOP, Phase.PERCH] or _perch_hold)


## The anchor whose arm the hero grips now (or grips through a shot from it): never a target of its own grip.
func is_own_perch(point: Vector3) -> bool:
	return (phase == Phase.PERCH or _perch_hold) and point.distance_to(perch_anchor) <= 0.01


## Let go of the rope or the arm where the hero is: the velocity stays as it is (T5 Е1, З4).
func let_go() -> void:
	_release(false)


## The grip on the anchor at `point` (T6 § 3, T5 Л4): the hands on its arm 0.26 and 0.66 m from the point toward the
## support, perch_hand_rise above the point; the body across the arm on the side it comes from, its shoulders
## perch_body_back behind the middle of the grip, the feet perch_feet_below under the point. {} for an anchor without
## an arm (the "perch" meta CityDistrict gives its street anchors).
func perch_pose_for(point: Vector3, from: Vector3) -> Dictionary:
	var marker := _marker_at(point)
	if marker == null or not marker.has_meta("perch"):
		return {}
	var spec: Dictionary = marker.get_meta("perch")
	var mount: Vector3 = spec.get("mount", point)
	var toward := Vector3(mount.x - point.x, 0.0, mount.z - point.z)
	if toward.length() < 0.001:
		return {}
	toward = toward.normalized()
	var across := toward.cross(Vector3.UP).normalized()
	var side := 1.0 if Vector3(from.x - point.x, 0.0, from.z - point.z).dot(across) >= 0.0 else -1.0
	var grip_y := point.y + perch_hand_rise
	var near := Vector3(point.x, grip_y, point.z) + toward * perch_grip_near
	var far_out: float = perch_grip_far
	if bool(spec.get("tie_rod", false)):
		far_out = perch_tie_rod_far
	elif String(spec.get("kind", "")) == "bracket":
		far_out = perch_strut_far
	var far := Vector3(point.x, grip_y, point.z) + toward * far_out
	var middle := (near + far) * 0.5
	var body := middle + across * side * perch_back()
	var facing := -across * side
	# The hero's right hand is the one on his right while he faces the arm.
	var right_side := facing.cross(Vector3.UP).normalized()
	var right := near if (near - middle).dot(right_side) > 0.0 else far
	var left := far if right == near else near
	return {"origin": Vector3(body.x, point.y - perch_feet(), body.z), "grip": middle, "left": left, "right": right,
		"facing": facing, "away": -toward, "point": point, "mount": mount}


## How far under the anchor's point the feet hang on its arm: perch_feet_below less this hero's PERCH_FEET_RAISE.
func perch_feet() -> float:
	return perch_feet_below - float(PERCH_FEET_RAISE.get(_hero_id(), 0.0))


## How far behind the middle of the grip the body hangs: perch_body_back and this hero's PERCH_BODY_BACK_MORE.
func perch_back() -> float:
	return perch_body_back + float(PERCH_BODY_BACK_MORE.get(_hero_id(), 0.0))


func _hero_id() -> String:
	return String(fighter.data.id) if fighter != null and fighter.data != null else ""


func _marker_at(point: Vector3) -> Node3D:
	if not is_inside_tree():
		return null
	for n in get_tree().get_nodes_in_group("grapple_anchor"):
		var marker := n as Node3D
		if marker != null and marker.global_position.distance_to(point) <= 0.01:
			return marker
	return null


## The body's capsule swept from `from` to `to` and resting at `to` touches nothing (CityParkourMotor._clear's rule).
func _body_path_clear(from: Vector3, to: Vector3) -> bool:
	var pose: Transform3D = fighter.global_transform
	pose.origin = from
	if fighter.test_move(pose, to - from, null, 0.035):
		return false
	var shape := fighter.get_node_or_null("BodyShape") as CollisionShape3D
	if shape == null:
		return true
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape.shape
	pose.origin = to
	query.transform = pose * shape.transform
	query.collision_mask = fighter.collision_mask
	query.exclude = [fighter.get_rid()]
	query.margin = 0.005
	return fighter.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


## The pull-up's two legs, as the ledge's mantle (hang → apex → landing): straight up under the rope to the grip's height,
## then across onto the arm — a balcony or a cornice under the arm is passed above it, not through it.
func _climb_apex(from: Vector3, to: Vector3) -> Vector3:
	return Vector3(from.x, to.y, from.z)


## The pull-up's corners (T6's re-acceptance 2026-10-15, N1): up under the rope to pull_up_duck under the grip's height,
## across to the grip's place at that height, the last rise beside the arm — the head no longer comes up into the ceramic
## cap and through the arm's end. With pull_up_duck 0 (or when that path is blocked and 15а's is clear) 15а's two legs
## (_climb_apex). Returns [corners, progress marks]; [] when neither path is clear.
func _climb_path(from: Vector3, to: Vector3) -> Array:
	if pull_up_duck > 0.0:
		var low: float = maxf(from.y, to.y - pull_up_duck)
		var way: Array[Vector3] = [from, Vector3(from.x, low, from.z), Vector3(to.x, low, to.z), to]
		var marks: Array[float] = [0.0, PULL_UP_RISE_SHARE, PULL_UP_RISE_SHARE + PULL_UP_ACROSS_SHARE, 1.0]
		if _way_clear(way):
			return [way, marks]
	var apex := _climb_apex(from, to)
	var old: Array[Vector3] = [from, apex, to]
	var old_marks: Array[float] = [0.0, 0.5, 1.0]
	return [old, old_marks] if _way_clear(old) else []


func _way_clear(way: Array[Vector3]) -> bool:
	for k: int in range(1, way.size()):
		if not _body_path_clear(way[k - 1], way[k]):
			return false
	return true


## The point of the pull-up's path at `progress` (0…1): linear along each leg between its marks.
func _climb_point(progress: float) -> Vector3:
	for k: int in range(1, _climb_way.size()):
		if progress <= _climb_marks[k] or k == _climb_way.size() - 1:
			var span: float = maxf(_climb_marks[k] - _climb_marks[k - 1], 0.000001)
			return _climb_way[k - 1].lerp(_climb_way[k], clampf((progress - _climb_marks[k - 1]) / span, 0.0, 1.0))
	return _climb_from


func _begin_climb_top() -> void:
	var pose := perch_pose_for(anchor_point, fighter.global_position)
	var from := fighter.global_position
	var path: Array = [] if pose.is_empty() else _climb_path(from, pose.origin)
	if path.is_empty():
		climb_blocked = true
		return
	climb_blocked = false
	_climb_way = path[0]
	_climb_marks = path[1]
	perch_pose = pose
	perch_anchor = anchor_point
	_climb_tail = maxf(0.0, slide_limit() - rope_length)
	_climb_tail_low = -INF
	_climb_from = fighter.global_position
	_climb_elapsed = 0.0
	_frames = 0
	phase = Phase.CLIMB_TOP


## T5 Л3: a finished 0.5 s move from the rope top to the grip, swept every tick like the ledge's mantle; blocked on the way
## — back to the rope top. On its last tick the rope comes back to its owner (T5 П1).
func _drive_climb_top(delta: float) -> void:
	_frames += 1
	var total := maxi(1, roundi(climb_top_seconds / maxf(delta, 0.0001)))
	var progress := minf(float(_frames) / float(total), 1.0)
	_climb_elapsed = progress * climb_top_seconds
	var before := fighter.global_position
	var target: Vector3 = _climb_point(progress)
	if not _body_path_clear(before, target):
		climb_blocked = true
		phase = Phase.HANG
		fighter.velocity = Vector3.ZERO
		return
	fighter.move_and_collide(target - before)
	if fighter.global_position.distance_to(target) > 0.01:
		climb_blocked = true
		phase = Phase.HANG
		fighter.velocity = Vector3.ZERO
		return
	fighter.velocity = (fighter.global_position - before) / maxf(delta, 0.0001)
	rope_length = minf(rope_length, (anchor_point - (fighter.global_position + HAND)).length())
	_draw_rope(fighter.global_position + HAND, anchor_point)
	_draw_tail(delta, _climb_tail * (1.0 - progress)) # the free end comes up to the hand over the pull-up (T6 § 9 п. 6)
	if progress >= 1.0:
		_grip_anchor()


func _grip_anchor() -> void:
	var rope := _deployed_token
	# The hook's flight back starts before the stock changes, so the HUD's refresh on retrieve already sees it pending.
	_return_from = anchor_point
	_return_elapsed = 0.0 if climb_enabled else -1.0
	registry.detach_user(rope, self)
	registry.retrieve(rope)
	_deployed_token = 0
	attached = false
	pulling = false
	climbing = false
	_own_support.clear()
	_transfer_skip.clear()
	phase = Phase.PERCH
	perch_elapsed = 0.0
	fighter.velocity = Vector3.ZERO
	if _rope:
		_rope.visible = false
	if _rope_visual:
		_rope_visual.visible = false
	if _tail_visual:
		_tail_visual.visible = false
	_draw_return(0.0)


## The hand that throws the shot from the grip ("" — none now; T6 § 9 п. 7). Presentation reads it.
func perch_throw_side() -> String:
	return throw_hand if _perch_hold and phase in [Phase.WINDUP, Phase.FLIGHT] else ""


## The slots the HUD does not show yet: 1 while the hook of the rope taken back on the grip is still flying to the waist.
func pending_return() -> int:
	return 1 if _return_elapsed >= 0.0 else 0


## The hook's flight back to the waist (see RETURN_SECONDS), one step of `delta`. A new shot, a reel or a miss (the hook's
## own visuals) ends it at once; so does its end, and then the HUD learns the slot (changed).
func _draw_return(delta: float) -> void:
	if _return_elapsed < 0.0:
		return
	_return_elapsed += maxf(delta, 0.0)
	var t: float = clampf(_return_elapsed / RETURN_SECONDS, 0.0, 1.0)
	var busy_now: bool = phase not in [Phase.PERCH, Phase.IDLE]
	if t >= 1.0 or busy_now or not is_inside_tree():
		_return_elapsed = -1.0
		if not busy_now:
			if _tip:
				_tip.visible = false
			if _rope_visual:
				_rope_visual.visible = false
		changed.emit(charges, cooldown_left, max_charges)
		return
	var waist: Vector3 = _return_point()
	var eased: float = t * t * (3.0 - 2.0 * t)
	var tip: Vector3 = _return_from.lerp(waist, eased) + Vector3.UP * RETURN_ARC * 4.0 * eased * (1.0 - eased)
	if _tip:
		_tip.visible = true
		_tip.global_position = tip
		var heading: Vector3 = (waist - tip)
		if heading.length() > 0.01:
			_tip.global_basis = Basis(Quaternion(Vector3.UP, heading.normalized()))
	if _rope_visual != null and is_instance_valid(fighter.skeletal):
		var hands: Vector3 = (fighter.skeletal.hand_world("Right") + fighter.skeletal.hand_world("Left")) * 0.5
		_rope_visual.update_rope(hands, tip, hands.distance_to(tip), delta, GameState.water, true)


## Where the returning hook lands (N2): RETURN_FRONT ahead of the drawn hips along the flat facing; without a rig, the waist.
func _return_point() -> Vector3:
	if not is_instance_valid(fighter.skeletal):
		return fighter.global_position + WAIST
	var hips: Vector3 = fighter.skeletal.bone_world("Hips", fighter.global_position + WAIST)
	var ahead := Vector3(fighter.forward.x, 0.0, fighter.forward.z)
	return hips + (ahead.normalized() * RETURN_FRONT if ahead.length() > 0.001 else Vector3.ZERO)


## Presentation only: the city rope's tail hangs straight down from the lower hand (the skinned hand; the physical HAND
## without a rig) for what is left of its deployed length, never through the floor.
## `length` ≥ 0 draws that much of it (the pull-up's shortening tail) instead of what the rope has left below the hand.
func _draw_tail(delta: float, length: float = -1.0) -> void:
	if not climb_enabled or not is_inside_tree() or not ResourceLoader.exists("res://scripts/grapple/RopeVisual.gd"):
		return
	if _tail_visual == null:
		_tail_visual = load("res://scripts/grapple/RopeVisual.gd").new()
		add_child(_tail_visual)
	var start: Vector3 = fighter.global_position + HAND
	if is_instance_valid(fighter.skeletal):
		var right: Vector3 = fighter.skeletal.hand_world("Right")
		var left: Vector3 = fighter.skeletal.hand_world("Left")
		start = right if right.y < left.y else left
	var tail := length if length >= 0.0 else slide_limit() - rope_length
	var floor_y := _support_below(start)
	var room := start.y - floor_y - 0.02 if not is_inf(floor_y) else tail
	var drop := minf(tail, room)
	if length >= 0.0:
		# The pull-up's tail: its free end only comes up (the lower hand changing sides must not lower it).
		drop = minf(drop, start.y - _climb_tail_low) if not is_inf(_climb_tail_low) else drop
		_climb_tail_low = maxf(_climb_tail_low, start.y - drop)
	if drop < 0.05:
		_tail_visual.visible = false
		return
	_tail_visual.update_rope(start, start + Vector3.DOWN * drop, drop, delta, GameState.water, false)


func _drive_perch(delta: float) -> void:
	perch_elapsed += delta
	fighter.velocity = Vector3.ZERO
	if perch_elapsed > perch_limit():
		_finish_idle() # The arms give out: a drop like off a ledge (T5 З1).


## E on the perch (T5 § 3.2): a new shot from the grip, 10 ticks of windup with the hands still on the arm; nothing to fire
## at — still gripping (CityFighter lets go only when no target was shown, T8 § 2.2).
func perch_shot() -> int:
	if phase != Phase.PERCH:
		return Target.NONE
	var held_for := perch_elapsed
	phase = Phase.IDLE
	var target := fire(false, "grapple_parkour")
	if target == Target.NONE or phase == Phase.IDLE:
		phase = Phase.PERCH
		perch_elapsed = held_for
		return Target.NONE
	_perch_hold = phase in [Phase.WINDUP, Phase.ROPE_REACH]
	perch_elapsed = held_for
	throw_hand = ""
	if _perch_hold and not perch_pose.is_empty():
		var facing: Vector3 = perch_pose.facing
		var aim_point: Vector3 = aim_intent.get("point", fighter.global_position + facing)
		throw_hand = "Right" if (aim_point - fighter.global_position).dot(facing.cross(Vector3.UP)) >= 0.0 else "Left"
	return target


## The leap off the perch (T5 З3): the grip ends, the body flies with `launch`.
func leap_from_perch(launch: Vector3) -> void:
	if phase != Phase.PERCH:
		return
	_finish_idle()
	fighter.velocity = launch
	Sfx.play("whoosh", -9)


## ADR-028 п. 4 (T5 П3, П4; T8 § 2.4): this hero's own rope hanging free — nobody on it — with its anchor within range_m of
## the hand on a clear line; the nearest to the hand. {} when none or while the hook is busy.
func reel_candidate() -> Dictionary:
	if registry == null or busy() or not is_inside_tree():
		return {}
	var hand := fighter.global_position + HAND
	var best: Dictionary = {}
	for key: int in registry.records:
		var record: Dictionary = registry.records[key]
		if not record.deployed or int(record.owner) != fighter.player_index or registry.in_use(key):
			continue
		var anchor: Vector3 = record.anchor
		if hand.distance_to(anchor) > range_m + 0.000001 or not line_clear(hand, anchor):
			continue
		var grip := registry.closest_grip(key, hand)
		if grip.is_empty():
			continue
		if best.is_empty() or float(grip.distance) < float(best.distance) or (is_equal_approx(float(grip.distance), float(best.distance)) and key < int(best.token)):
			best = {"token": key, "distance": float(grip.distance), "anchor": anchor}
	return best


## The reel (T5 П4): the rope leaves its anchor and comes back to the hand at rewind_speed like a miss — movement × 0.35,
## paused by a hit or a dodge, refunded at the hand. Refused (nothing changes) unless `key` is a candidate now.
func begin_reel(key: int) -> bool:
	if key == 0 or busy() or not registry.records.has(key):
		return false
	var record: Dictionary = registry.records[key]
	if not record.deployed or int(record.owner) != fighter.player_index or registry.in_use(key):
		return false
	var hand := fighter.global_position + HAND
	var anchor: Vector3 = record.anchor
	if hand.distance_to(anchor) > range_m + 0.000001 or not line_clear(hand, anchor):
		return false
	if not registry.begin_reel(key, fighter.player_index):
		return false
	token = key
	action = "grapple_parkour"
	_prefer_enemy = false
	projectile_position = anchor
	_flight_direction = (anchor - hand).normalized()
	_begin_rewind()
	_miss_velocity = Vector3.ZERO
	reeling_in = true
	return true


func _release(reached: bool) -> void:
	var f := fighter
	if reached:
		f.velocity.y = maxf(f.velocity.y, 3.5)
		if GameState.free_move:
			var h := Vector3(f.velocity.x, 0.0, f.velocity.z).limit_length(8.0)
			f.velocity.x = h.x
			f.velocity.z = h.z
		else:
			f.velocity.x = clampf(f.velocity.x, -8.0, 8.0)
	Sfx.play("grapple_release", -8)
	detach()


func detach() -> void:
	if recovering():
		return # Damage/dodge pauses recovery; it cannot erase the issued token.
	if token != 0:
		_begin_rewind()
		return
	_finish_idle()


func _finish_idle() -> void:
	if _deployed_token != 0 and is_instance_valid(registry):
		registry.detach_user(_deployed_token, self)
	phase = Phase.IDLE
	_pending_rope = 0
	chain_throw = false
	_perch_hold = false
	_line_handover = -1.0
	climbing = false
	sliding = false
	rope_end = false
	climb_blocked = false
	perch_pose = {}
	reeling_in = false
	_transfer_skip.clear()
	windup_progress = 0.0
	_selected_anchor = null
	_victim = null
	_deployed_token = 0
	recovery_remaining = 0.0
	recovery_progress = 0.0
	recovery_paused = false
	if _tip:
		_tip.visible = false
	attached = false
	pulling = false
	_frames = 0
	if _rope:
		_rope.visible = false
	if _rope_visual:
		_rope_visual.visible = false
	if _tail_visual:
		_tail_visual.visible = false


func _begin_rewind() -> void:
	phase = Phase.MISS_REWIND
	attached = false
	_perch_hold = false
	recovery_remaining = maxf(0.5, (projectile_position - (fighter.global_position + HAND)).length())
	_recovery_total = recovery_remaining
	recovery_progress = 0.0
	_miss_velocity = _flight_direction * 2.0
	_tip.visible = true


func visual_endpoint() -> Vector3:
	if phase == Phase.ENEMY_EXTRACT and is_instance_valid(_victim):
		return _victim.global_position + HAND
	return anchor_point if phase == Phase.HANG else projectile_position


func _tick_recovery(delta: float) -> void:
	var hand := fighter.global_position + HAND
	if phase == Phase.MISS_REWIND:
		_miss_velocity.y -= Fighter.GRAVITY * delta
		if GameState.water != null and projectile_position.y < GameState.water.height(projectile_position.x, projectile_position.z):
			_miss_velocity *= exp(-4.0 * delta)
		projectile_position += _miss_velocity * delta
		projectile_position.y = maxf(projectile_position.y, -2.0 if GameState.water != null else 0.05)
		recovery_remaining = maxf(0.0, recovery_remaining - rewind_speed * delta)
		var to_tip := projectile_position - hand
		projectile_position = hand + to_tip.limit_length(recovery_remaining)
		recovery_progress = 1.0 - recovery_remaining / maxf(_recovery_total, 0.001)
		_tip.global_position = projectile_position
		_draw_rope(hand, projectile_position)
		if recovery_remaining <= 0.01:
			_return_token()
	elif phase == Phase.ENEMY_EXTRACT:
		# Once a leg commits, its first active frame owns extraction. The ordinary
		# timer cannot steal that event during a late kick's startup.
		var committed_kick := fighter.state == Fighter.State.ATTACK and fighter.current_move != null and (fighter._limb_action.ends_with("leg") or fighter.current_move == fighter.data.heavy)
		if not committed_kick:
			_extract_frames += 1
		recovery_progress = float(_extract_frames) / maxf(1.0, float(extract_duration_frames))
		if is_instance_valid(_victim):
			_draw_rope(hand, _victim.global_position + HAND)
		if _extract_frames >= extract_duration_frames:
			_return_token()


func extract_on_kick(side: String = "right_leg") -> void:
	if phase == Phase.ENEMY_EXTRACT:
		extract_side = side
		extract_flash = 0.2
		_return_token()


func _return_token() -> void:
	if token != 0:
		registry.refund(token, fighter.player_index)
	token = 0
	_finish_idle()


func _confirm_pull(opp: Fighter) -> void:
	var f := fighter
	if GameState.free_move:
		opp.get_pulled_to(f.global_position + f.forward * 1.25, 22)
	else:
		opp.get_pulled(f.global_position.x + float(f.facing) * 1.25, 22)
	Sfx.play("grapple_hit")


## The reel's rope leaves between the hands where they are at the end of this tick: the fighter's tick drew it (tick_regen)
## before the body moved (T6 acceptance 2026-10-15 § 9 п. 4). Runs after the fighter's own tick (a child). Presentation
## only; the city reel only.
func _physics_process(delta: float) -> void:
	_draw_return(delta)
	if not reeling_in or phase != Phase.MISS_REWIND or _rope_visual == null or not _rope_visual.visible:
		return
	if fighter == null or not is_instance_valid(fighter.skeletal):
		return
	_rope_visual.move_start((fighter.skeletal.hand_world("Right") + fighter.skeletal.hand_world("Left")) * 0.5)


func _draw_rope(a: Vector3, b: Vector3) -> void:
	# Compute slack at the physical attachment BEFORE substituting the skinned hand.
	# An overhead animated hand is closer to the anchor, but that is not spare cable.
	var physical_slack := maxf(0.0, rope_length - a.distance_to(b)) if phase == Phase.HANG else 0.0
	# The skinned hand only anchors the rendered line, never the sweep or constraint.
	if is_instance_valid(fighter.skeletal):
		a = fighter.skeletal.hand_world(throw_hand if _perch_hold and not throw_hand.is_empty() else "Right")
		if _line_handover >= 0.0:
			if phase in [Phase.ROPE_REACH, Phase.HANG] and _line_handover < LINE_HANDOVER_SECONDS:
				a = fighter.skeletal.hand_world(_line_hand).lerp(a, smoothstep(0.0, LINE_HANDOVER_SECONDS, _line_handover))
				_line_handover += get_physics_process_delta_time()
			else:
				_line_handover = -1.0
		# T6 acceptance 2026-10-15 § 9 п. 4: the reel of a left rope (Fish_Reel, both hands together at the waist) takes the
		# rope between the two hands, not into the right one. Presentation only: HAND stays the logic's point.
		if reeling_in and phase == Phase.MISS_REWIND:
			a = (a + fighter.skeletal.hand_world("Left")) * 0.5
	if _rope_visual != null:
		_rope.visible = false
		_rope_visual.visible = true
		var length := recovery_remaining if phase == Phase.MISS_REWIND else a.distance_to(b) + physical_slack
		var slack := phase == Phase.MISS_REWIND or (phase == Phase.HANG and physical_slack > 0.02)
		_rope_visual.update_rope(a, b, length, get_physics_process_delta_time(), GameState.water, slack)
		return
	_rope.visible = true
	_rope.global_transform = Transform3D.IDENTITY
	_rope_mesh.clear_surfaces()
	_rope_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_rope_mesh.surface_add_vertex(a)
	_rope_mesh.surface_add_vertex(b)
	# slight sag/second line for visibility
	var mid := (a + b) * 0.5 + Vector3(0, -0.15, 0.02)
	_rope_mesh.surface_add_vertex(a)
	_rope_mesh.surface_add_vertex(mid)
	_rope_mesh.surface_add_vertex(mid)
	_rope_mesh.surface_add_vertex(b)
	_rope_mesh.surface_end()
