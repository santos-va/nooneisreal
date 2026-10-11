class_name LivingBodyMotion
extends RefCounted
## The living body (plan docs/Plans/2026-10-07-Living-Body.md, steps 1–2; T5 brief
## docs/GDD/2026-10-07-Tricks-Moves-And-Street-Encounters.md § 2.1 J1–J3, § 2.4 R1/R7/R8, § 2.2 P8):
##   R1 — a side hit plays Hit_Shoulder_L/R, every flinch clip fills the hitstun instead of being cut, the capsule rig's
##        flinch spring reaches the spine additively, and the force of the blow sets how far the body gives;
##   R7 — the get-up clip, from its first moving frame, fills getup_frames() instead of jumping into the stance;
##   R8 — a light blow on a heavy body («утримався») gives a small flinch and no squash on the hero, picture only;
##   J1 — a longer take-off (0.20 s) with a short stretch; a running jump takes NinjaJump_Start;
##   J2 — one tuck (NinjaJump_Idle) per jump from the ground, legs reaching for the support 6 frames before it, arms
##        searching for balance after 0.6 s of falling (LiftAir_Fall_Air, arms only);
##   J3 / P8 — three landings by impact speed: light < 14 m/s, normal 14–18 (deeper squash, a hand on the ground,
##        dust), heavy ≥ 18 (NinjaJump_Land, the trailing knee to the ground, a hand down, dust).
## Jump arc С2 (plan docs/Plans/2026-10-09-Rope-Pull-Jump-Arc-Substance-Momentum.md step 2; T5 С1–С6 in
## docs/GDD/2026-10-09-Rope-Pull-And-Jump-Arc-Numbers.md § 2, PLACEHOLDER): after a take-off the air is exactly
## takeoff → apex (the tuck) → fall, the tuck from the end of the take-off until the ground is 0.31 s away and never one
## shorter than 0.28 s; no `rise` after a take-off; blends of at least 0.12 s; the light landing plays Jump_Land ×6.
##
## Contract (docs/Fix/2026-10-07-Living-Body-Fix.md § Звірка, п. 1). SkeletalRig first draws the mannequin exactly as
## before. That pose is the authority: BoneRagdoll starts from it (BoneRagdoll.gd:52-57) and the fighter's position
## follows the ragdoll pelvis (Fighter.gd:1683-1686). draw() saves every mannequin bone's position, rotation and scale,
## lays this layer's pose over them for the hero retarget only, and restore() writes the saved values back exactly.
## The layer never writes the fighter, any RNG or the physics world; the reach ray is a read-only query.
## Every number below is a PLACEHOLDER presentation value unless a comment names its source; none is frame data.

const HookMotion = preload("res://scripts/fighter/GrappleMotion.gd")
const SAMPLE_HZ: float = 30.0
## R1: which clip shows a hit on the victim's left / right side.
const SIDE_CLIPS: Dictionary = {"left": "Hit_Shoulder_L", "right": "Hit_Shoulder_R"}
## The zone clips the mannequin already plays (SkeletalRig.STATE_CLIPS hit_high / hit_mid / hit_low).
const ZONE_CLIPS: Dictionary = {"high": "Hit_Head", "mid": "Hit_Chest", "low": "Hit_Stomach"}
## Limb swings that travel across the body (a «бічний удар»): an attacker's right one lands on the victim's left.
const HOOK_VARIANTS: Array[String] = ["bodyhook", "roundhouse"]
const SIDE_DOT: float = 0.707 # PLACEHOLDER: an attacker ≥ 45° off the victim's facing hits a side.
## R1/R8 force = the squash term of Fighter.receive_hit (damage / 60 clamped to 0.5…1.6, Fighter.gd:1327) over the
## victim's CharacterData.weight.
const FULL_RATIO: float = 1.2 # PLACEHOLDER: at or above it the full authored flinch.
const LIGHT_RATIO: float = 0.6 # PLACEHOLDER: at or below it the smallest flinch.
const LIGHT_AMPLITUDE: float = 0.45 # PLACEHOLDER share of the authored flinch for the lightest blow.
const HOLD_RATIO: float = 0.8 # PLACEHOLDER: below it R8 «утримався» — the hero shows no squash.
## R1 additive spring: Active-Ragdoll.md stage 3 «lite», influence 0.3–0.6 over 6–12 frames (PLACEHOLDER there).
const SPRING_INFLUENCE: Vector2 = Vector2(0.3, 0.6)
const SPRING_FRAMES: Vector2 = Vector2(6.0, 12.0)
## R7: the clip from its first moving frame. Measured on UAL2: LayToIdle keeps the pelvis at 0.03–0.04 m until ~0.40 s
## and rises from 0.51 s; KipUp moves from its first frame.
const GETUP_FROM: Dictionary = {"LayToIdle": 0.40, "KipUp": 0.0}
## J1–J3, T5 brief § 2.1.
const TAKEOFF_SECONDS: float = 0.20
## Seconds of each take-off clip drawn after the body has left the ground. Jump_Start: the rising half (0.45…1.0),
## as AuthoredLocomotion samples it. NinjaJump_Start: the feet leave at ~0.08 s and the tuck holds after ~0.4 s.
const NINJA_TAKEOFF: Vector2 = Vector2(0.08, 0.80)
const JUMP_TAKEOFF_FROM: float = 0.45
const STRETCH: float = 0.6 # PLACEHOLDER take-off stretch, the mirror of Fighter.SQUASH_HIT.
const APEX_SPEED: float = 2.0 # only the long-fall arm clock (_fall_time) now; the tuck is timed (С1–С3)
## С2: the tuck ends when the support is this many seconds away: 0.18 (fall blend) + 0.10 (REACH_FRAMES) + 0.03.
const TUCK_EXIT_SECONDS: float = 0.31
## С3: a tuck that would last less than this (0.18 + 0.10) is never started — a low jump does not flick into one.
const TUCK_MIN_SECONDS: float = 0.28
const REACH_FRAMES: float = 6.0
const LONG_FALL_SECONDS: float = 0.6
const NORMAL_LANDING: float = 14.0
const HEAVY_LANDING: float = 18.0
const LAND_RATE: float = 2.5 # Jump_Land ×2.5 instead of ×7: the normal landing.
const LIGHT_LAND_RATE: float = 6.0 # С5: the light landing, Jump_Land ≈ 1.27 s → 0.21 s; standing again ≈ 8–9 ticks after.
const HEAVY_LAND_FRAMES: float = 20.0 # P8: NinjaJump_Land ×3.8.
const NORMAL_SQUASH: float = 1.4
const KNEEL_BACK: float = 0.32 # PLACEHOLDER metres the trailing foot goes back so its knee meets the ground.
const NORMAL_DROP: float = 0.20 # PLACEHOLDER metres the hips go below the clip's crouch on a normal landing.
const HEAVY_DROP: float = 0.26 # PLACEHOLDER, heavy landing.
const NORMAL_LEAN: float = 0.80 # PLACEHOLDER radians the chest leans forward over the knees, normal landing.
const HEAVY_LEAN: float = 0.80 # PLACEHOLDER, heavy landing.
const HAND_HEIGHT: float = 0.04 # PLACEHOLDER metres: the wrist bone just above the ground.
## Blends between this layer's own modes, and the fade back into the authority pose.
## С4: peak ≈ 12°/tick from the tuck to the straight pose (was 21–25° at 0.08–0.10 s). Take-off: T5's own fallback
## 0.18 — at 0.15 the running take-off turned the sword hand 18.9° (Choko) / 22.2° (Skea) in a tick, above 17.1 / 22.1
## before bf38d3e (G3, tools/animation/jump_arc_check.gd); at 0.18 it is 16.0 / 18.7.
## Landings — T1's choice, T2 variant B (plan 2026-10-09 «Рішення T1 після кроків 1–4»): light 0.15, normal 0.08,
## heavy 0.06. At T5's 0.12 the light landing kicked the legs ≥ 15° for a tick, the heavy one stayed shallower than the
## normal one (G4), and the hand missed the ground on normal / heavy landings (living_body_check J3 / P8, ≤ 0.10 m).
## B is the only tested set where both checks hold; the air modes keep T5's ≥ 0.12 s, and normal / heavy are still
## twice as long as on 97675c7 (0.04 / 0.03). PLACEHOLDER until T5 / playtest.
const MODE_BLEND: Dictionary = {"takeoff": 0.18, "apex": 0.18, "fall": 0.18, "rise": 0.12, "land_light": 0.15, "land_normal": 0.08, "land_heavy": 0.06}
const EXIT_SECONDS: float = 0.15
## Landing into the stance (plan docs/Plans/2026-10-09-Animation-Feel-Landing-Rope-Stop-Wall.md step 1; T6 review on
## 595490d: the hips rose 0.85 → 1.00 → 0.855 m, the pose held 7 ticks at 0.0°/tick, the heavy landing turned bones
## 62–67°/tick and slid the trailing foot 131 + 175 mm). Every tier now: the descent plays the clip to its deepest
## crouch at the tier's rate, never in fewer than LAND_DESCENT_MIN on a normal or heavy landing; the bottom keeps the
## clip to LAND_BOTTOM; then the body rises from that crouch straight into the stance clip at the authority's own clip
## time, never through the clip's straight end; the layer stays until the authority has left Jump_Land
## (AuthoredLocomotion.LAND_SECONDS + BLEND_SECONDS) and fades into it with no hold. Clip seconds are measured on UAL
## Jump_Land / NinjaJump_Land (see apply_hero_contacts); the durations are PLACEHOLDER until T5 / T6.
const LAND_DEEPEST: float = 0.21
const LAND_BOTTOM: float = 0.32
const LAND_STAND: float = 0.85
const LAND_DESCENT_MIN: float = 0.20 # PLACEHOLDER: 12 ticks into a normal / heavy crouch (it was 3.3–5; at 6 / 9 ticks 33–40 / 31–34°/tick)
const LAND_BLEND_MIN: float = 0.10   # PLACEHOLDER: the normal / heavy entry blend (variant B's 0.08 / 0.06 spiked)
const KNEEL_LIFT: float = 0.12       # PLACEHOLDER metres: the trailing foot steps back through the air, not along the ground

var enabled: bool = true
## The С4/С5/С3 values as variables only so a check can put the 2026-10-08 ones back as negative controls.
var mode_blend: Dictionary = MODE_BLEND
var light_land_rate: float = LIGHT_LAND_RATE
var tuck_min_seconds: float = TUCK_MIN_SECONDS
## Step 1 of plan 2026-10-09 as variables only so a check can put the product of 595490d back (anim_ground_check
## --break=land / kneel): false plays the clip to its straight end and holds, or slides the kneeling foot.
var land_settle: bool = true
var kneel_step: bool = true
var _contact_envelope: float = 0.0
## Read-only for checks and captures.
var mode: String = ""
var clip: String = ""
var clip_time: float = 0.0
var amplitude: float = 1.0
var hit_side: String = ""
var hit_force: float = 1.0
var held: bool = false
var landing_tier: String = ""
var impact_speed: float = 0.0
var reach_weight: float = 0.0
var arm_weight: float = 0.0
var hand_clearance: float = INF
var knee_clearance: float = INF
var hero_scale: Vector3 = Vector3.ONE
var draws: int = 0

var _cache: Dictionary = {}       # GLB name → Array of [Array[Quaternion], Vector3 pelvis]
var _lengths: Dictionary = {}
var _bone_count: int = 0
var _pelvis: int = -1
var _spine: Array[int] = []
var _arms: Array[int] = []
var _authority_position: Array[Vector3] = []
var _authority_rotation: Array[Quaternion] = []
var _authority_scale: Array[Vector3] = []
var _presented: Array[Quaternion] = []
var _presented_pelvis: Vector3 = Vector3.ZERO
var _from: Array[Quaternion] = []
var _from_pelvis: Vector3 = Vector3.ZERO
var _mode_time: float = 0.0
var _exit_time: float = 0.0
var _exit_seconds: float = 0.0
var _exit_hold: float = 0.0
var _hero_position: Array[Vector3] = []
var _hero_rotation: Array[Quaternion] = []
var _hero_scale_pose: Array[Vector3] = []
var _hero_cached: bool = false
var _laid: bool = false            # this layer's pose is on the mannequin (between draw() → true and restore())
var _hero_kept: bool = false
var _hero_base_scale: Vector3 = Vector3.ONE
var _hero: Node3D = null
var _idle_clip: String = ""
var _getup_clip: String = ""
# bookkeeping, every processed frame
var _prev_state: int = -1
var _ground_speed: float = 0.0
var _air_time: float = 0.0
var _fall_time: float = 0.0
var _takeoff: bool = false
var _takeoff_running: bool = false
var _last_air_vy: float = 0.0
var _landing_time: float = INF
var _landing_frames: int = 0
var _hit_serial: int = 0
var _flinch_serial: int = -1
var _flinch_total: int = 1
var _flinch_frames: int = 0
var _pending_side: String = ""
var _pending_force: float = 1.0
var _pending_held: bool = false
var _pending_amplitude: float = 1.0
var _takeoff_frames: int = 0
enum Tuck { PENDING, ON, DONE }
var _tuck: Tuck = Tuck.DONE
var _landing_id: int = 0
var _dust_id: int = -1


func setup(player: AnimationPlayer, skeleton: Skeleton3D, f: Fighter) -> void:
	_bone_count = skeleton.get_bone_count()
	_pelvis = skeleton.find_bone("pelvis")
	for name: String in ["spine_01", "spine_02", "spine_03"]:
		if skeleton.find_bone(name) >= 0:
			_spine.append(skeleton.find_bone(name))
	for bone: int in _bone_count:
		var name: String = skeleton.get_bone_name(bone)
		if name.begins_with("clavicle_") or name.begins_with("upperarm_") or name.begins_with("lowerarm_") or name.begins_with("hand_") or name.contains("thumb") or name.contains("index") or name.contains("middle") or name.contains("ring") or name.contains("pinky"):
			_arms.append(bone)
	_idle_clip = f.data.idle_clip.trim_suffix("_Loop")
	_getup_clip = f.data.getup_clip.trim_suffix("_Loop")
	var sources: Array[String] = ["Hit_Shoulder_L", "Hit_Shoulder_R", "Hit_Head", "Hit_Chest", "Hit_Stomach",
		"Jump_Start", "Jump_Land", "NinjaJump_Start", "NinjaJump_Idle", "NinjaJump_Land", "LiftAir_Fall_Air", _getup_clip]
	for source: String in sources:
		_sample_clip(player, skeleton, source, false)
	# The whole stance loop: a landing rises into it at the authority's own clip time (step 1 of plan 2026-10-09).
	_sample_clip(player, skeleton, _idle_clip, false)
	player.stop()
	skeleton.reset_bone_poses()


func _sample_clip(player: AnimationPlayer, skeleton: Skeleton3D, source: String, first_only: bool) -> void:
	if source.is_empty() or _cache.has(source):
		return
	var name: String = source if player.has_animation(source) else "ual2/" + source
	if not player.has_animation(name):
		push_error("Missing living-body source: " + source)
		return
	var length: float = player.get_animation(name).length
	_lengths[source] = length
	var frames: Array = []
	player.play(name)
	for frame: int in (1 if first_only else ceili(length * SAMPLE_HZ) + 1):
		skeleton.reset_bone_poses()
		player.seek(minf(float(frame) / SAMPLE_HZ, length), true)
		var rotations: Array[Quaternion] = []
		for bone: int in _bone_count:
			rotations.append(skeleton.get_bone_pose_rotation(bone))
		frames.append([rotations, skeleton.get_bone_pose_position(_pelvis)])
	_cache[source] = frames


func has_clip(source: String) -> bool:
	return _cache.has(source)


func clip_length(source: String) -> float:
	return float(_lengths.get(source, 0.0))


## Pose of a cached clip at `at` seconds: [Array[Quaternion], pelvis position].
func sample(source: String, at: float) -> Array:
	var frames: Array = _cache[source]
	var position: float = clampf(at * SAMPLE_HZ, 0.0, float(frames.size() - 1))
	var a: int = int(position)
	var b: int = mini(a + 1, frames.size() - 1)
	var t: float = position - float(a)
	var ra: Array[Quaternion] = frames[a][0]
	var rb: Array[Quaternion] = frames[b][0]
	var rotations: Array[Quaternion] = []
	for bone: int in _bone_count:
		rotations.append(ra[bone].slerp(rb[bone], t) if t > 0.0 else ra[bone])
	return [rotations, Vector3(frames[a][1]).lerp(frames[b][1], t)]


func reset() -> void:
	mode = ""
	_presented.clear()
	_exit_time = 0.0
	_exit_seconds = 0.0
	_prev_state = -1
	_landing_time = INF
	_flinch_serial = _hit_serial
	_hero_cached = false
	_laid = false
	_hero_kept = false


## Fighter.hit_landed of this fighter (victim side). Read-only: attacker and victim are only looked at.
func on_hit(attacker: Fighter, victim: Fighter, move: MoveData, blocked: bool) -> void:
	if blocked or move == null or attacker == null or victim == null:
		return
	_hit_serial += 1
	_pending_side = struck_side(attacker, victim, move)
	_pending_force = clampf(move.damage / 60.0, 0.5, 1.6)
	var ratio: float = _pending_force / maxf(victim.data.weight, 0.2)
	_pending_amplitude = lerpf(LIGHT_AMPLITUDE, 1.0, clampf((ratio - LIGHT_RATIO) / (FULL_RATIO - LIGHT_RATIO), 0.0, 1.0))
	_pending_held = ratio < HOLD_RATIO
	# Fighter has squashed the rig already (Fighter.gd:1327, before this signal) and hitstop now holds the drawing:
	# a held body shows no squash from the first frame, a full one shows Fighter's.
	if _hero != null and enabled and victim.hp > 0.0 and victim.on_ground() and not (move.launcher or move.knockdown):
		var current: Vector3 = _squash_scale(victim.squash)
		_hero.scale = Vector3(_hero_base_scale.x / current.x, _hero_base_scale.y / current.y, _hero_base_scale.z / current.z) if _pending_held else _hero_base_scale


## R1: the side of the victim a blow lands on — "left", "right", or "" for the front/back zone clips.
static func struck_side(attacker: Fighter, victim: Fighter, move: MoveData) -> String:
	var forward: Vector3 = victim.forward if GameState.free_move else Vector3(float(victim.facing), 0.0, 0.0)
	forward.y = 0.0
	var to: Vector3 = attacker.global_position - victim.global_position
	to.y = 0.0
	if to.length() > 0.05 and forward.length() > 0.5:
		var direction: Vector3 = to.normalized()
		var lateral: float = direction.dot(forward.normalized().cross(Vector3.UP))
		if absf(lateral) >= SIDE_DOT:
			return "right" if lateral > 0.0 else "left"
		if direction.dot(forward) < 0.0:
			return ""
	var source: Dictionary = AuthoredCombatMotion.resolve(move, attacker.data.id)
	if not source.is_empty() and String(source.variant) in HOOK_VARIANTS:
		return "left" if source.side == "right" else "right"
	return ""


static func landing_tier_for(speed: float) -> String:
	if speed >= HEAVY_LANDING:
		return "heavy"
	if speed >= NORMAL_LANDING:
		return "normal"
	return "light"


## Bookkeeping that runs on every processed frame, drawn or not.
func observe(f: Fighter, rig: SkeletalRig, delta: float) -> void:
	var state: int = f.state
	if state in [Fighter.State.IDLE, Fighter.State.WALK] and f.on_ground():
		_ground_speed = Vector2(f.velocity.x, f.velocity.z).length()
	if state == Fighter.State.JUMP:
		if _prev_state != Fighter.State.JUMP:
			_air_time = 0.0
			_fall_time = 0.0
			_takeoff_frames = 0
			_takeoff = _prev_state in [Fighter.State.IDLE, Fighter.State.WALK, Fighter.State.CROUCH, Fighter.State.BLOCK] and f.velocity.y > 0.0
			_takeoff_running = _ground_speed > AuthoredLocomotion.WALK_LIMIT * rig._gait_scale
			# Only a jump from the ground tucks; a rope release, a second jump or a step off an edge is rise / fall.
			_tuck = Tuck.PENDING if _takeoff else Tuck.DONE
		else:
			_air_time += maxf(delta, 0.0)
			_takeoff_frames += 1
		_fall_time = _fall_time + maxf(delta, 0.0) if f.velocity.y <= -APEX_SPEED else 0.0
		_last_air_vy = f.velocity.y
		if _tuck != Tuck.DONE and _takeoff_frames >= roundi(TAKEOFF_SECONDS * 60.0):
			var to_ground: float = time_to_ground(f)
			if _tuck == Tuck.PENDING:
				_tuck = Tuck.ON if to_ground - TUCK_EXIT_SECONDS >= tuck_min_seconds else Tuck.DONE
			elif to_ground <= TUCK_EXIT_SECONDS:
				_tuck = Tuck.DONE
	elif _prev_state == Fighter.State.JUMP and state in [Fighter.State.IDLE, Fighter.State.WALK] and f.on_ground():
		# Fighter cleared velocity.y on contact; the last airborne value plus this tick's gravity is the impact.
		impact_speed = maxf(0.0, -(_last_air_vy - Fighter.GRAVITY * f.data.fall_gravity_mult * maxf(delta, 0.0)))
		landing_tier = landing_tier_for(impact_speed)
		_landing_time = 0.0
		_landing_frames = 0
		_landing_id += 1
	elif state in [Fighter.State.IDLE, Fighter.State.WALK]:
		_landing_time += maxf(delta, 0.0)
		_landing_frames += 1
	else:
		_landing_time = INF
	if state == Fighter.State.HITSTUN:
		if _flinch_serial != _hit_serial or _prev_state != Fighter.State.HITSTUN:
			var fresh: bool = _flinch_serial != _hit_serial
			_flinch_serial = _hit_serial
			_flinch_total = maxi(f.stun_frames + 1, 1)
			_flinch_frames = 0
			hit_side = _pending_side if fresh else ""
			hit_force = _pending_force if fresh else 1.0
			amplitude = _pending_amplitude if fresh else 1.0
			held = _pending_held if fresh else false
		else:
			_flinch_frames += 1
	else:
		_flinch_serial = _hit_serial   # a hit that launched, knocked out or was absorbed is not a later flinch
	_prev_state = state


func _allowed(f: Fighter, rig: SkeletalRig) -> bool:
	return enabled and rig.ragdoll == null and not RigAnimator.levitating(f) and not HookMotion.recovery_active(f) \
		and f.state != Fighter.State.GRAPPLE and rig.parkour_motion.phase.is_empty() and not f.dodging


func _choose(f: Fighter, rig: SkeletalRig) -> String:
	if not _allowed(f, rig):
		return ""
	match f.state:
		Fighter.State.HITSTUN:
			return "flinch" if _cache.has(_flinch_clip(f)) else ""
		Fighter.State.GETUP:
			return "getup" if _cache.has(_getup_clip) else ""
		Fighter.State.JUMP:
			if _takeoff and _takeoff_frames < roundi(TAKEOFF_SECONDS * 60.0):
				return "takeoff"
			if _tuck == Tuck.ON:
				return "apex"
			if _takeoff:
				return "fall" # С1: no `rise` after a take-off — one arc
			return "fall" if f.velocity.y < 0.0 else "rise"
		Fighter.State.IDLE:
			if rig.locomotion.moving():
				return ""
			if land_settle and landing_tier in ["light", "normal", "heavy"]:
				return ("land_" + landing_tier) if _landing_time < float(_land_times().settled) else ""
			match landing_tier:
				"heavy":
					return "land_heavy" if _landing_time < HEAVY_LAND_FRAMES / 60.0 else ""
				"normal", "light":
					return ("land_" + landing_tier) if _landing_time * _land_rate() < clip_length("Jump_Land") else ""
	return ""


func _flinch_clip(f: Fighter) -> String:
	if SIDE_CLIPS.has(hit_side):
		return SIDE_CLIPS[hit_side]
	return ZONE_CLIPS.get(f.animator.flinch_zone, ZONE_CLIPS["mid"])


## Lays this frame's living pose over the authoritative mannequin. Returns true when it drew — the caller then
## retargets and calls restore(). False: the mannequin was not touched.
func draw(skeleton: Skeleton3D, hero: Node3D, f: Fighter, rig: SkeletalRig, delta: float) -> bool:
	_hero_cached = false
	_laid = false
	observe(f, rig, delta)
	var wanted: String = _choose(f, rig)
	if wanted.is_empty():
		if mode.is_empty() or _presented.is_empty() or not enabled or rig.ragdoll != null:
			_finish(hero)
			return false
		# Fade back into the authority, only into a neutral pose; an attack, a dash or a parkour hold takes over at once.
		if _exit_seconds <= 0.0:
			_exit_seconds = EXIT_SECONDS if f.state in [Fighter.State.IDLE, Fighter.State.WALK, Fighter.State.JUMP] and _allowed(f, rig) else 0.0
			# Standing, the authority itself still blends out of the clip it drew (AuthoredLocomotion.BLEND_SECONDS);
			# fading into that blend would dip the body back into the old pose. Hold, then fade into the settled stance.
			# A settled landing (step 1 of plan 2026-10-09) leaves only after the authority's blend has ended: no hold.
			var settled_landing: bool = land_settle and mode.begins_with("land_")
			_exit_hold = AuthoredLocomotion.BLEND_SECONDS if f.state == Fighter.State.IDLE and not rig.locomotion.moving() and not settled_landing else 0.0
			_exit_time = 0.0
			_from = _presented.duplicate()
			_from_pelvis = _presented_pelvis
		_exit_time += maxf(delta, 0.0)
		if _exit_time >= _exit_hold + _exit_seconds:
			_finish(hero)
			return false
	else:
		_exit_seconds = 0.0
	_save_authority(skeleton)
	var target: Array = _target(wanted, f, rig, skeleton) if not wanted.is_empty() else [_authority_rotation.duplicate(), _authority_position[_pelvis]]
	if wanted != mode and not wanted.is_empty():
		_from = _presented.duplicate() if not _presented.is_empty() else _authority_rotation.duplicate()
		_from_pelvis = _presented_pelvis if not _presented.is_empty() else _authority_position[_pelvis]
		_mode_time = 0.0
		mode = wanted
	else:
		_mode_time += maxf(delta, 0.0)
	var weight: float
	if wanted.is_empty():
		weight = smoothstep(0.0, _exit_seconds, _exit_time - _exit_hold)
	else:
		var blend: float = float(mode_blend.get(wanted, 0.0))
		if land_settle and wanted in ["land_normal", "land_heavy"]:
			blend = maxf(blend, LAND_BLEND_MIN)
		weight = 1.0 if blend <= 0.0 else smoothstep(0.0, blend, _mode_time)
	var rotations: Array[Quaternion] = target[0]
	var presented: Array[Quaternion] = []
	for bone: int in _bone_count:
		var pose: Quaternion = _from[bone].slerp(rotations[bone], weight) if weight < 1.0 else rotations[bone]
		presented.append(pose)
		skeleton.set_bone_pose_rotation(bone, pose)
	_presented = presented
	_presented_pelvis = _from_pelvis.lerp(target[1], weight) if weight < 1.0 else Vector3(target[1])
	skeleton.set_bone_pose_position(_pelvis, _presented_pelvis)
	if wanted.is_empty():
		mode = "" if weight >= 1.0 else mode
	_scale_hero(hero, f, wanted)
	_dust(f, wanted)
	draws += 1
	_laid = true
	_hero_kept = false
	return true


func _save_authority(skeleton: Skeleton3D) -> void:
	_authority_position.resize(_bone_count)
	_authority_rotation.resize(_bone_count)
	_authority_scale.resize(_bone_count)
	for bone: int in _bone_count:
		_authority_position[bone] = skeleton.get_bone_pose_position(bone)
		_authority_rotation[bone] = skeleton.get_bone_pose_rotation(bone)
		_authority_scale[bone] = skeleton.get_bone_pose_scale(bone)


## Writes the saved authority back, value for value. From here until the next draw() the deferred skeleton callback
## reapplies the hero pose keep_hero() took instead of retargeting the (restored) authority.
func restore(skeleton: Skeleton3D, _hero_skeleton: Skeleton3D) -> void:
	for bone: int in _authority_rotation.size():
		skeleton.set_bone_pose_position(bone, _authority_position[bone])
		skeleton.set_bone_pose_rotation(bone, _authority_rotation[bone])
		skeleton.set_bone_pose_scale(bone, _authority_scale[bone])
	_hero_cached = _laid and _hero_kept
	_laid = false


## SkeletalRig.retarget() output while this layer's pose is on the mannequin — taken right after the retarget and
## before the sword transfer and prop poses, so a reapply plus those same steps rebuilds the identical final pose.
func keep_hero(hero_skeleton: Skeleton3D) -> void:
	if not _laid or hero_skeleton == null:
		return
	var count: int = hero_skeleton.get_bone_count()
	_hero_position.resize(count)
	_hero_rotation.resize(count)
	_hero_scale_pose.resize(count)
	for bone: int in count:
		_hero_position[bone] = hero_skeleton.get_bone_pose_position(bone)
		_hero_rotation[bone] = hero_skeleton.get_bone_pose_rotation(bone)
		_hero_scale_pose[bone] = hero_skeleton.get_bone_pose_scale(bone)
	_hero_kept = true


## True between restore() and the next draw: the hero already shows this tick's living pose, so the deferred skeleton
## callback must not retarget it from the (restored) authority.
func holds_hero() -> bool:
	return _hero_cached


func reapply_hero(hero_skeleton: Skeleton3D) -> void:
	for bone: int in _hero_rotation.size():
		hero_skeleton.set_bone_pose_position(bone, _hero_position[bone])
		hero_skeleton.set_bone_pose_rotation(bone, _hero_rotation[bone])
		hero_skeleton.set_bone_pose_scale(bone, _hero_scale_pose[bone])


## True when the mannequin holds exactly the saved authority (the check's invariant after restore()).
func authority_intact(skeleton: Skeleton3D) -> bool:
	if _authority_rotation.size() != skeleton.get_bone_count():
		return false
	for bone: int in _authority_rotation.size():
		if skeleton.get_bone_pose_position(bone) != _authority_position[bone] or skeleton.get_bone_pose_rotation(bone) != _authority_rotation[bone] or skeleton.get_bone_pose_scale(bone) != _authority_scale[bone]:
			return false
	return true


func presented_rotations() -> Array[Quaternion]:
	return _presented


func _finish(hero: Node3D) -> void:
	mode = ""
	clip = ""
	_presented.clear()
	_exit_seconds = 0.0
	_exit_time = 0.0
	reach_weight = 0.0
	arm_weight = 0.0
	hand_clearance = INF
	knee_clearance = INF
	_contact_envelope = 0.0
	hero_scale = Vector3.ONE
	if hero != null:
		hero.scale = _hero_base_scale


func set_hero(hero: Node3D) -> void:
	_hero = hero
	_hero_base_scale = hero.scale


func _target(wanted: String, f: Fighter, rig: SkeletalRig, skeleton: Skeleton3D) -> Array:
	reach_weight = 0.0
	arm_weight = 0.0
	match wanted:
		"flinch":
			return _flinch_target(f, skeleton)
		"getup":
			clip = _getup_clip
			var from: float = float(GETUP_FROM.get(_getup_clip, 0.0))
			var progress: float = clampf(float(f.frame_in_state) / float(maxi(f.getup_frames() - 1, 1)), 0.0, 1.0)
			clip_time = lerpf(from, clip_length(clip), progress)
			return sample(clip, clip_time)
		"takeoff":
			clip = "NinjaJump_Start" if _takeoff_running else "Jump_Start"
			var progress: float = clampf(float(_takeoff_frames + 1) / (TAKEOFF_SECONDS * 60.0), 0.0, 1.0)
			var window: Vector2 = NINJA_TAKEOFF if _takeoff_running else Vector2(JUMP_TAKEOFF_FROM * clip_length("Jump_Start"), clip_length("Jump_Start"))
			clip_time = lerpf(window.x, window.y, progress)
			return sample(clip, clip_time)
		"apex":
			clip = "NinjaJump_Idle"
			clip_time = fposmod(_air_time, clip_length(clip))
			return sample(clip, clip_time)
		"rise":
			clip = ""
			return [_authority_rotation.duplicate(), _authority_position[_pelvis]]
		"fall":
			return _fall_target(f)
		"land_light", "land_normal", "land_heavy":
			if land_settle:
				return _land_target()
			if wanted == "land_heavy":
				clip = "NinjaJump_Land"
				clip_time = clip_length(clip) * clampf(_landing_time / (HEAVY_LAND_FRAMES / 60.0), 0.0, 1.0)
				return sample(clip, clip_time)
			clip = "Jump_Land"
			clip_time = minf(_landing_time * _land_rate(), clip_length(clip))
			return sample(clip, clip_time)
	return [_authority_rotation.duplicate(), _authority_position[_pelvis]]


## Clip seconds per second of each tier: light Jump_Land ×6 (С5), normal ×2.5, heavy NinjaJump_Land in 20 frames (P8).
func _land_clip_rate() -> float:
	if landing_tier == "heavy":
		return clip_length("NinjaJump_Land") / (HEAVY_LAND_FRAMES / 60.0)
	return _land_rate()


## Seconds after the contact: the deepest crouch, the end of the bottom, standing in the stance, the authority settled.
func _land_times() -> Dictionary:
	var rate: float = maxf(_land_clip_rate(), 0.0001)
	var descent: float = LAND_DEEPEST / rate
	if landing_tier != "light":
		descent = maxf(descent, LAND_DESCENT_MIN)
	var bottom: float = descent + (LAND_BOTTOM - LAND_DEEPEST) / rate
	var stand: float = bottom + (LAND_STAND - LAND_BOTTOM) / rate
	return {"rate": rate, "descent": descent, "bottom": bottom, "stand": stand,
		"settled": maxf(stand, AuthoredLocomotion.LAND_SECONDS + AuthoredLocomotion.BLEND_SECONDS)}


## The descent into the clip's deepest crouch, its bottom, then a rise from that crouch into the stance clip at the
## authority's clip time (SkeletalRig loops the stance from the state change, which is the contact tick).
func _land_target() -> Array:
	clip = "NinjaJump_Land" if landing_tier == "heavy" else "Jump_Land"
	var times: Dictionary = _land_times()
	var t: float = _landing_time
	if t < float(times.descent):
		clip_time = LAND_DEEPEST * t / maxf(float(times.descent), 0.0001)
	else:
		clip_time = minf(LAND_DEEPEST + (t - float(times.descent)) * float(times.rate), LAND_BOTTOM)
	var crouch: Array = sample(clip, clip_time)
	var rise: float = smoothstep(float(times.bottom), float(times.stand), t)
	_contact_envelope = smoothstep(0.0, float(times.descent), t) * (1.0 - rise)
	if rise <= 0.0 or not _cache.has(_idle_clip):
		return crouch
	var stance: Array = sample(_idle_clip, fposmod(t, clip_length(_idle_clip)))
	var from: Array[Quaternion] = crouch[0]
	var to: Array[Quaternion] = stance[0]
	var rotations: Array[Quaternion] = []
	for bone: int in _bone_count:
		rotations.append(from[bone].slerp(to[bone], rise) if rise < 1.0 else to[bone])
	return [rotations, Vector3(crouch[1]).lerp(stance[1], rise)]


func _flinch_target(f: Fighter, skeleton: Skeleton3D) -> Array:
	clip = _flinch_clip(f)
	var progress: float = clampf(1.0 - float(f.stun_frames) / float(maxi(_flinch_total, 1)), 0.0, 1.0)
	clip_time = progress * clip_length(clip)
	var pose: Array = sample(clip, clip_time)
	var rotations: Array[Quaternion] = pose[0]
	var pelvis: Vector3 = pose[1]
	if amplitude < 1.0 and _cache.has(_idle_clip):
		var rest: Array = sample(_idle_clip, 0.0)
		var rest_rotations: Array[Quaternion] = rest[0]
		for bone: int in _bone_count:
			rotations[bone] = rest_rotations[bone].slerp(rotations[bone], amplitude)
		pelvis = Vector3(rest[1]).lerp(pelvis, amplitude)
	_spring(skeleton, rotations, f)
	return [rotations, pelvis]


## R1: the capsule rig's flinch spring (RigAnimator.flinch_x — x pushed back, z the seeded twist) reaches the spine and
## head additively, at influence 0.3–0.6 by force, fading over 6–12 frames. The per-zone gains are the capsule rig's own
## (RigAnimator._apply_pose): high snaps the head back, mid folds the body over, low buckles; a side blow leans the body
## away from it. Mannequin skeleton space: +Z forward, +X the body's left, +Y up (SkeletalRig.MODEL_YAW).
func _spring(skeleton: Skeleton3D, rotations: Array[Quaternion], f: Fighter) -> void:
	var influence: float = lerpf(SPRING_INFLUENCE.x, SPRING_INFLUENCE.y, clampf((hit_force - 0.5) / 1.1, 0.0, 1.0))
	influence *= 1.0 - smoothstep(SPRING_FRAMES.x, SPRING_FRAMES.y, float(_flinch_frames))
	if influence <= 0.0 or _spine.is_empty():
		return
	var x: float = f.animator.flinch_x.x
	var fold: Vector3 = Vector3.RIGHT          # +X: a positive angle bends forward
	var torso: float
	var head: float = -x * 0.45
	match f.animator.flinch_zone:
		"high":
			torso = -x * 0.25
			head = -x * 1.1
		"low":
			torso = absf(x) * 0.35
		_:
			torso = absf(x) * 0.55
	if SIDE_CLIPS.has(hit_side):
		# A blow on the left leans the body to its right (−X), and the other way round.
		fold = Vector3.FORWARD if hit_side == "left" else Vector3.BACK
		torso = absf(x) * 0.55
		head = absf(x) * 0.45
	var twist: float = f.animator.flinch_x.z * 0.2 * influence
	var per_bone: float = torso * influence / float(_spine.size())
	for bone: int in _spine:
		_turn(skeleton, rotations, bone, Quaternion(Vector3.UP, twist / float(_spine.size())) * Quaternion(fold, per_bone))
	var neck: int = skeleton.find_bone("neck_01")
	if neck >= 0:
		_turn(skeleton, rotations, neck, Quaternion(fold, head * influence))


## Turns one bone by a skeleton-space rotation, keeping its children's local poses.
func _turn(skeleton: Skeleton3D, rotations: Array[Quaternion], bone: int, turn: Quaternion) -> void:
	var globals: Array[Quaternion] = _globals(skeleton, rotations)
	var parent: int = skeleton.get_bone_parent(bone)
	var parent_rotation: Quaternion = globals[parent] if parent >= 0 else Quaternion.IDENTITY
	rotations[bone] = (parent_rotation.inverse() * (turn * globals[bone])).normalized()


func _fall_target(f: Fighter) -> Array:
	clip = ""
	var rotations: Array[Quaternion] = _authority_rotation.duplicate()
	var pelvis: Vector3 = _authority_position[_pelvis]
	# J2: legs reach for the support it will meet within REACH_FRAMES (read-only floor query).
	reach_weight = clampf(1.0 - time_to_ground(f) / (REACH_FRAMES / 60.0), 0.0, 1.0)
	if reach_weight > 0.0 and _cache.has("Jump_Land"):
		clip = "Jump_Land"
		clip_time = 0.0
		var reach: Array = sample("Jump_Land", 0.0)
		var reach_rotations: Array[Quaternion] = reach[0]
		for bone: int in _bone_count:
			rotations[bone] = rotations[bone].slerp(reach_rotations[bone], reach_weight)
		pelvis = pelvis.lerp(reach[1], reach_weight)
	# Arms only: a long fall searches for balance; the legs keep the jump / reach above.
	arm_weight = smoothstep(LONG_FALL_SECONDS, LONG_FALL_SECONDS + 0.2, _fall_time) * (1.0 - reach_weight)
	if arm_weight > 0.0 and _cache.has("LiftAir_Fall_Air"):
		var arms: Array = sample("LiftAir_Fall_Air", fposmod(_fall_time - LONG_FALL_SECONDS, clip_length("LiftAir_Fall_Air")))
		var arm_rotations: Array[Quaternion] = arms[0]
		for bone: int in _arms:
			rotations[bone] = rotations[bone].slerp(arm_rotations[bone], arm_weight)
		if clip.is_empty():
			clip = "LiftAir_Fall_Air"
			clip_time = fposmod(_fall_time - LONG_FALL_SECONDS, clip_length("LiftAir_Fall_Air"))
	return [rotations, pelvis]


## Seconds until the body meets the support below at its current vertical speed: up at Fighter.GRAVITY, down at
## GRAVITY × fall_gravity_mult (Fighter._tick_air). A falling body gives the J2 reach formula exactly. Read-only.
static func time_to_ground(f: Fighter) -> float:
	var height: float = maxf(f.global_position.y - f.floor_y(), 0.0)
	var down: float = Fighter.GRAVITY * f.data.fall_gravity_mult
	var rising: float = 0.0
	var speed: float = -f.velocity.y
	if speed < 0.0:
		rising = -speed / Fighter.GRAVITY
		height += speed * speed / (2.0 * Fighter.GRAVITY)
		speed = 0.0
	return rising + (-speed + sqrt(speed * speed + 2.0 * down * height)) / down


func _land_rate() -> float:
	return light_land_rate if landing_tier == "light" else LAND_RATE


## Skeleton-space rotations of every bone for a set of local rotations (parents precede children in UAL).
func _globals(skeleton: Skeleton3D, rotations: Array[Quaternion]) -> Array[Quaternion]:
	var out: Array[Quaternion] = []
	out.resize(_bone_count)
	for bone: int in _bone_count:
		var parent: int = skeleton.get_bone_parent(bone)
		out[bone] = (out[parent] * rotations[bone]) if parent >= 0 else rotations[bone]
	return out


## Squash and stretch the hero node on top of Fighter._apply_squash (which scales the whole SkeletalRig).
func _scale_hero(hero: Node3D, f: Fighter, wanted: String) -> void:
	hero_scale = Vector3.ONE
	var current: Vector3 = _squash_scale(f.squash)
	match wanted:
		"takeoff":
			var stretch: float = maxf(0.0, STRETCH - Fighter.SQUASH_DECAY * float(_takeoff_frames))
			hero_scale = Vector3(1.0 - 0.08 * stretch, 1.0 + 0.14 * stretch, 1.0 - 0.08 * stretch)
		"land_normal":
			var frames: float = float(_landing_frames)
			if land_settle:
				# The deeper squash runs on the clip's clock, so the body is as squashed at the (later) bottom as before.
				var times: Dictionary = _land_times()
				var deepest: float = LAND_DEEPEST / float(times.rate)
				var t: float = _landing_time
				frames = 60.0 * (deepest * t / float(times.descent) if t < float(times.descent) else deepest + t - float(times.descent))
			var deeper: Vector3 = _squash_scale(maxf(0.0, NORMAL_SQUASH - Fighter.SQUASH_DECAY * frames))
			hero_scale = Vector3(deeper.x / current.x, deeper.y / current.y, deeper.z / current.z)
		"flinch":
			if held:
				hero_scale = Vector3(1.0 / current.x, 1.0 / current.y, 1.0 / current.z)
	if hero != null:
		hero.scale = Vector3(_hero_base_scale.x * hero_scale.x, _hero_base_scale.y * hero_scale.y, _hero_base_scale.z * hero_scale.z)


## Fighter._apply_squash's own formula (Fighter.gd:668-670).
static func _squash_scale(value: float) -> Vector3:
	var s: float = clampf(value, 0.0, 1.6)
	return Vector3(1.0 + 0.08 * s, 1.0 - 0.14 * s, 1.0 + 0.08 * s)


func _dust(f: Fighter, wanted: String) -> void:
	if wanted not in ["land_normal", "land_heavy"] or _dust_id == _landing_id:
		return
	_dust_id = _landing_id
	if GameState.water != null:
		return   # FxDirector owns the river splash
	var at: Vector3 = f.global_position
	Flipbook.play(f, "dust_land", Vector3(at.x, f.floor_y() + 0.6, at.z), 2.2 if wanted == "land_normal" else 2.8)


## J3 contacts on the hero after the retarget: the hips drop into a three-point landing, the body leans over the lead
## foot and one hand goes to the ground (normal, heavy); on a heavy landing the trailing foot goes back so its knee meets
## the ground. Both feet keep the support they had. The weight peaks at the bottom of the landing clip. The imported
## heroes have short arms (0.37–0.38 m), so the hand only reaches the ground from a low, leaning body.
func apply_hero_contacts(hero: Skeleton3D, f: Fighter) -> void:
	hand_clearance = INF
	knee_clearance = INF
	if mode not in ["land_normal", "land_heavy"] or _presented.is_empty() or hero == null:
		return
	# Jump_Land and NinjaJump_Land reach the deepest crouch at ~0.21 s (pelvis 0.43 m) and stand again by ~0.85 s.
	var envelope: float = smoothstep(0.0, 0.14, clip_time) * (1.0 - smoothstep(0.32, 0.72, clip_time))
	if land_settle:
		# In with the descent, out with the rise into the stance (_land_target), in seconds rather than clip time.
		envelope = _contact_envelope
	if envelope <= 0.0:
		return
	var heavy: bool = mode == "land_heavy"
	var forward: Vector3 = f.forward if GameState.free_move else Vector3(float(f.facing), 0.0, 0.0)
	forward.y = 0.0
	forward = forward.normalized()
	var right: Vector3 = forward.cross(Vector3.UP)
	var floor: float = f.floor_y()
	var to_local: Transform3D = hero.global_transform.affine_inverse()
	var feet: Dictionary = {}
	for side: String in ["Left", "Right"]:
		feet[side] = hero.global_transform * hero.get_bone_global_pose(hero.find_bone(side + "Foot")).origin
	var hips: int = hero.find_bone("Hips")
	var drop: float = (HEAVY_DROP if heavy else NORMAL_DROP) * envelope
	hero.set_bone_pose_position(hips, hero.get_bone_pose_position(hips) + hero.global_basis.inverse() * (Vector3.DOWN * drop))
	# The lead leg keeps its foot; the trailing one keeps it too, or kneels back on a heavy landing. That foot steps
	# back and returns through the air (KNEEL_LIFT at mid-step), so it never slides along the ground.
	var trail_target: Vector3 = Vector3(feet["Right"]) - forward * (KNEEL_BACK * envelope if heavy else 0.0)
	if heavy and kneel_step:
		trail_target += Vector3.UP * (KNEEL_LIFT * sin(PI * clampf(envelope, 0.0, 1.0)))
	for side: String in ["Left", "Right"]:
		var target: Vector3 = trail_target if side == "Right" else Vector3(feet[side])
		AuthoredCombatMotion._solve_chain(hero, hero.find_bone(side + "UpLeg"), hero.find_bone(side + "Leg"), hero.find_bone(side + "Foot"), to_local * target)
	var lean: float = (HEAVY_LEAN if heavy else NORMAL_LEAN) * envelope
	# A positive turn about `right` (forward × up) tips the chest backwards; the landing leans forward, so it turns
	# by −lean (measured: with +lean the neck ended 0.08–0.12 m behind the hips at the bottom of the landing).
	var axis: Vector3 = (hero.global_basis.inverse() * right).normalized()
	for spine: String in ["Spine02", "Spine01"]:
		var bone: int = hero.find_bone(spine)
		if bone >= 0:
			AuthoredCombatMotion._set_global_rotation(hero, bone, Quaternion(axis, -lean * 0.5) * AuthoredCombatMotion._global_rotation(hero, bone))
	var arm: int = hero.find_bone("LeftArm")
	var fore: int = hero.find_bone("LeftForeArm")
	var hand: int = hero.find_bone("LeftHand")
	if mini(arm, mini(fore, hand)) >= 0:
		# Choko keeps his sword hand free; both heroes plant the left hand, beside and ahead of the lead foot.
		var shoulder: Vector3 = hero.global_transform * hero.get_bone_global_pose(arm).origin
		var target: Vector3 = Vector3(shoulder.x, floor + HAND_HEIGHT, shoulder.z) + forward * 0.05
		var actual: Vector3 = hero.global_transform * hero.get_bone_global_pose(hand).origin
		AuthoredCombatMotion._solve_chain(hero, arm, fore, hand, to_local * actual.lerp(target, envelope))
		hand_clearance = (hero.global_transform * hero.get_bone_global_pose(hand).origin).y - floor
	if heavy:
		knee_clearance = (hero.global_transform * hero.get_bone_global_pose(hero.find_bone("RightLeg")).origin).y - floor
