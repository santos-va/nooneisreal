extends RefCounted
## City traversal transitions without snaps (plan docs/Plans/2026-10-09-Animation-Feel-Landing-Rope-Stop-Wall.md,
## branch B, steps 4–5). The T6 review measured 84–180°/tick on the rope catch and the catch → pull change, 108–137° on
## the ledge entry and the mantle start, 150° leaving Skea's wall run and 163–169° releasing the rope: every layer
## (authored hook, parkour contacts, the idle guard it leaves) switches its weight in one tick.
## When the traversal presentation changes — entering or leaving the rope, a rope phase, a parkour phase or its source
## clip — the final hero pose blends from the pose drawn on the tick before over BLEND_SECONDS, in skeleton space (so
## no bone's drawn rotation changes faster than its blend share), the hips position with it.
## Presentation only: it runs last on the hero skeleton (before the living body caches it), reads the fighter's state
## and rope phase, and never writes the fighter, the rope, the mannequin or any RNG. City fighters only — the duel and
## the enemy hook have no parkour motor, their signature is "" and this layer returns before touching their skeleton.
const BLEND_SECONDS: float = 0.16 # PLACEHOLDER art timing: a 180° flip spread over ~10 ticks.
## While blending no drawn bone turns more than this in one tick (PLACEHOLDER, under the plan's 30°/tick); the blend
## goes on until the pose is within CAUGHT_UP of its target.
const MAX_TURN: float = 28.0 * PI / 180.0
const CAUGHT_UP: float = 0.5 * PI / 180.0
## --break control of tools/animation/anim_traversal_check.gd: false draws the product of main 595490d.
var enabled: bool = true
## --break=yield control of tools/animation/anim_ground_check.gd: false blends the wall kick's first tick, as the merge of
## branches A and B first did (see handed()).
var yield_kick: bool = true
## --break=follow control of anim_ground_check: false hands the kick over without following the drawn pose (a blend
## after the kick then starts from the hang left before it).
var follow_kick: bool = true
var _order: Array[int] = []
var _parents: Array[int] = []
var _hips: int = -1
var _signature: String = ""
var _last: Array[Quaternion] = []
var _last_hips: Vector3 = Vector3.ZERO
var _elapsed: float = INF
var _serial: int = -1
var _output: Array[Quaternion] = []
var _output_hips: Vector3 = Vector3.ZERO
var _blending: bool = false
var _residual: float = 0.0


func reset() -> void:
	_signature = ""
	_last.clear()
	_output.clear()
	_elapsed = INF
	_serial = -1
	_blending = false
	_residual = 0.0


## What the traversal presentation draws now; "" outside the city. Only branch-B actions name their parkour phase —
## the vault, the side run and the wall kick (whose course branch A owns) read as "no action", so only the way into
## and out of the rope, the ledge, the wall run and the roll is blended.
static func signature(f: Fighter, parkour_phase: String, parkour_clip: String, hook_phase: String) -> String:
	if not f.has_method("parkour_snapshot"):
		return ""
	var rope: bool = f.state == Fighter.State.GRAPPLE
	var own: bool = parkour_phase in ["hang", "mantle", "wall_run", "landing_roll"]
	# The rope's own sub-phases (catch → pull → hang → reel) hand over inside AuthoredHookMotion; only the rope phase
	# and the recovery climb are transitions here.
	var recover: bool = rope and hook_phase == "recover"
	return "%s|%d|%s|%s|%s" % [rope, f.grapple.phase if rope else -1, recover, parkour_phase if own else "", parkour_clip if own else ""]


## Whole actions that are transitions in themselves, drawn under the cap for as long as they run: the city hook's
## windup and flight (10 frames from the stance to a full overhand throw) and the mantle (30 frames from the hang to the
## stand on top, through the ClimbLedge arm swing and the grip letting go).
static func throwing(f: Fighter, parkour_phase: String = "") -> bool:
	if not f.has_method("parkour_snapshot"):
		return false
	return parkour_phase == "mantle" or (f.state == Fighter.State.GRAPPLE and f.grapple.phase in [GrappleHook.Phase.WINDUP, GrappleHook.Phase.FLIGHT])


## The wall kick is branch A's transition (HeroBodyMotion): on its first tick the fighter's heading — and with it the rig
## node — flips to the kick's course (180° off the hang in anim_ground_check) while the hips carry the old heading as a
## yaw offset that the air turn spends at AIR_TURN_RATE, and finish_pose crossfades from the pose left. This layer blends
## in skeleton space: a blend begun on that tick (the hang → "no action" signature change) held the skeleton pose while
## the node turned, so the whole drawn body flipped 174.9° in one tick. While the kick runs this layer draws nothing and
## only follows the drawn pose, so a later transition blends from what was drawn.
static func handed(parkour_phase: String) -> bool:
	return parkour_phase == "wall_kick"


## `whole_action` — a transition in itself (throwing()): drawn under the cap as long as it runs, not only its first tick.
## `kick` — handed(): branch A owns the pose this tick.
func apply(hero: Skeleton3D, serial: int, delta: float, wanted: String, whole_action: bool = false, kick: bool = false) -> void:
	if wanted.is_empty():
		return # not a city fighter: nothing is read or written
	if _order.is_empty():
		_build(hero)
	if serial == _serial:
		# A repeated retarget of the same physics tick redraws exactly the same blended pose.
		if _blending:
			_write(hero, _output, _output_hips)
		return
	_serial = serial
	if kick and yield_kick:
		if not follow_kick:
			return
		_signature = wanted
		_elapsed = INF
		_blending = false
		_residual = 0.0
		_last = _globals(hero)
		_last_hips = hero.get_bone_pose_position(_hips)
		return
	if enabled and wanted != _signature and not _last.is_empty():
		_elapsed = 0.0
	_signature = wanted
	var before: float = _elapsed
	_elapsed += maxf(delta, 0.0)
	var target: Array[Quaternion] = _globals(hero)
	var target_hips: Vector3 = hero.get_bone_pose_position(_hips)
	var done: float = smoothstep(0.0, BLEND_SECONDS, before)
	# The blend runs its schedule, then — for at most another schedule — until the drawn pose has caught up with a
	# target the cap held back. A source that keeps outrunning the cap snaps after that, and the regression sees it.
	_blending = enabled and not _last.is_empty() and (done < 1.0 or whole_action or (_residual > CAUGHT_UP and before < 2.0 * BLEND_SECONDS))
	if _blending:
		# Each tick closes the share of the remaining gap that the smoothstep schedule asks for, from the pose drawn on
		# the tick before: the short arc toward a moving target never flips the way slerp(start, target) does near 180°.
		var step: float = 1.0 if done >= 1.0 else (smoothstep(0.0, BLEND_SECONDS, _elapsed) - done) / (1.0 - done)
		var blended: Array[Quaternion] = []
		blended.resize(target.size())
		_residual = 0.0
		for bone: int in _order:
			var next: Quaternion = _last[bone].slerp(target[bone], step)
			var turn: float = _last[bone].angle_to(next)
			if turn > MAX_TURN:
				next = _last[bone].slerp(next, MAX_TURN / turn)
			blended[bone] = next
			_residual = maxf(_residual, next.angle_to(target[bone]))
		var locals: Array[Quaternion] = []
		locals.resize(target.size())
		for bone: int in _order:
			var parent: int = _parents[bone]
			locals[bone] = ((blended[parent].inverse() if parent >= 0 else Quaternion.IDENTITY) * blended[bone]).normalized()
		_output = locals
		_output_hips = _last_hips.lerp(target_hips, step)
		_write(hero, _output, _output_hips)
		_last = blended
		_last_hips = _output_hips
	else:
		_residual = 0.0
		_last = target
		_last_hips = target_hips


func _build(hero: Skeleton3D) -> void:
	_parents.clear()
	var depth: Array[int] = []
	for bone: int in hero.get_bone_count():
		_parents.append(hero.get_bone_parent(bone))
		var d: int = 0
		var p: int = hero.get_bone_parent(bone)
		while p >= 0:
			d += 1
			p = hero.get_bone_parent(p)
		depth.append(d)
	_order.clear()
	for bone: int in hero.get_bone_count():
		_order.append(bone)
	_order.sort_custom(func(a: int, b: int) -> bool: return depth[a] < depth[b] or (depth[a] == depth[b] and a < b))
	_hips = hero.find_bone("Hips")


func _globals(hero: Skeleton3D) -> Array[Quaternion]:
	var out: Array[Quaternion] = []
	for bone: int in hero.get_bone_count():
		out.append(hero.get_bone_global_pose(bone).basis.orthonormalized().get_rotation_quaternion())
	return out


func _write(hero: Skeleton3D, locals: Array[Quaternion], hips: Vector3) -> void:
	for bone: int in locals.size():
		hero.set_bone_pose_rotation(bone, locals[bone])
	hero.set_bone_pose_position(_hips, hips)
