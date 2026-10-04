class_name DuelCamera
extends Node3D
## Free-movement duel camera (Prototype 0.3, GameState.free_move; FightCamera stays for the plane).
## ADR-020: solo starts behind P1, then preserves its world side through fighter crossings. Continuous
## circling still turns smoothly; hero facing never forces the lens to chase their back. In VERSUS it stands side-on, so up
## close it reads like the 0.2 side camera. The screen-right direction is GameState.duel.right (simulation side, never
## flips 180° when the fighters swap); this node only follows it — presentation, not gameplay.
## The SpringArm3D keeps the camera out of walls. Framing numbers are FightCamera's.
## Plan: docs/Plans/2026-10-03-Prototype-0.3-Free-Movement.md, step 0.3-2.

## T5 Арес, docs/GDD/02-Combat-System.md § Камера дуелі на швидкому розвороті:
## `camera_yaw_clamp` — the yaw turns at most this per physics tick (180°/s; FM C10, ДИЗАЙН).
const YAW_CLAMP_DEG := 3.0
## While the clamp lags the fighters' line by more than this, the arm pulls back (no cuts) …
const PULLBACK_LAG_DEG := 15.0
## … by up to this fraction of its length (+30 %, ДИЗАЙН).
const PULLBACK_MAX := 0.3
## Smoke bound (T2): while circling, the view stays within this of side-on — catches a camera that
## stops following the line. Not a design number.
const MAX_SIDE_OFF_DEG := 25.0
## Launch 6, ADR-015 + docs/GDD/02-Combat-System.md § Камера за спиною і плавність (T5 Арес, all PLACEHOLDER):
## `camera_yaw_accel` — the yaw's turn rate changes by at most this per physics tick (both modes).
const YAW_ACCEL_DEG := 0.25
## ADR-018 «the fight with air», numbers K-1 (GDD 02 § Кадр із запасом — replace ADR-015's closer ones; PLACEHOLDER).
## Mode `behind` (solo vs CPU): initially on the line P2 → P1; ADR-020 retains that presentation side.
const BEHIND_DIST := 5.0          # m behind P1 while sep ≤ BEHIND_DIST_SEP …
const BEHIND_DIST_SEP := 4.0
const BEHIND_DIST_PER_M := 0.35   # … then +0.35 m per metre of sep …
const BEHIND_DIST_MAX := 9.0      # … up to 9 m
const BEHIND_HEIGHT_NEAR := 3.8   # m above the floor at sep ≤ 1 m …
const BEHIND_HEIGHT_FAR := 3.0    # … linearly down to this at sep ≥ 4 m
const BEHIND_SHOULDER := 1.0      # m to screen-right of P1
const BEHIND_FOCUS := 0.5         # the view aims at the pair's middle (ADR-018 п. 2, 4) …
const BEHIND_FOCUS_Y := 1.2       # … at this height
## Mode `side` (VERSUS): arm length = clamp(SIDE_DIST + SIDE_DIST_PER_M · sep, SIDE_DIST_MIN, SIDE_DIST_MAX).
const SIDE_DIST := 6.0
const SIDE_DIST_PER_M := 0.68   # Арес 2026-10-03 (T4 RED п. 3, variant а): 0.7 measured 14.84 % at sep 6, 0.68 ≥ 15 %
const SIDE_DIST_MIN := 8.0
const SIDE_DIST_MAX := 24.0
## The pull-back never stretches the arm past the larger of this and the unpulled framing distance (Арес 2026-10-03,
## 02 § Відтягування й межа Гермеса): 12.47 m keeps a 1.8 m fighter at 12.5 % of the frame height at fov 60.
const PULLBACK_CAP_M := 12.47
## Vertical field of view of both arena cameras (Arena.tscn), 91.5° horizontal in 16:9; the ceiling (ADR-018 п. 1).
const FOV_DEG := 60.0
## GDD 02, "Far-opponent readability" (T5, 2026-10-04): presentation-only PLACEHOLDER tuning.
## Preserve the ADR-018 near fight and the shared side camera; trade unused air for a larger far hero.
const FAR_FOV_MIN := 38.0
const FAR_BLEND_START := 6.0
const FAR_BLEND_END := 12.0
const FAR_TARGET_SHARE := 0.125
const FAR_NEAR_SAFE_SHARE := 0.28
const FAR_HORIZONTAL_MARGIN := 0.15
## Fighter.tscn capsule radius; framing uses the existing smoke's 1.8 m nominal body height.
const FRAMING_RADIUS := 0.35
const FRAMING_HEIGHT := 1.8
## ADR-020 / GDD 02: presentation axis survives a crossing; tiny separations have no stable bearing.
const AXIS_HOLD_ENTER := 0.5
const AXIS_HOLD_EXIT := 0.75
const LEAD_SECONDS := 0.15
const LEAD_MAX := 0.75
const LEAD_SMOOTH_SECONDS := 0.20

@onready var arm: SpringArm3D = $SpringArm3D
@onready var cam: Camera3D = $SpringArm3D/Camera3D

var p1: Fighter
var p2: Fighter
@export_range(0.0, 1.0) var impact_scale: float = 1.0
var _impact := CameraImpact.new()
var _yaw: float = 0.0
var _yaw_prev: float = 0.0   # yaw at the previous physics tick — the render frame interpolates between the two
var _omega: float = 0.0      # yaw turn this tick (rad/tick), |Δ| ≤ YAW_ACCEL_DEG per tick
var _pull: float = 0.0   # current arm pull-back fraction, 0 … PULLBACK_MAX
var force_pull: float = -1.0   # smoke only: ≥ 0 pins the pull-back fraction
## Match mode: true = solo continuity camera (initially behind P1), false = shared side-on (VERSUS).
var behind: bool = false
var _presentation_line := Vector3.RIGHT
var _axis_held := false
var _lookahead := Vector3.ZERO
var aim_controller: HarpoonAim


func setup(a: Fighter, b: Fighter) -> void:
	p1 = a
	p2 = b
	arm.collision_mask = 1    # static world only; fighters are layer 2
	behind = GameState.duel.behind
	if aim_controller == null:
		aim_controller = HarpoonAim.new()
		add_child(aim_controller)
	aim_controller.setup(cam, behind)
	_presentation_line = GameState.duel.line
	_axis_held = false
	_lookahead = Vector3.ZERO
	_impact.reset()
	_yaw = _target_yaw()
	_yaw_prev = _yaw
	_omega = 0.0
	rotation = Vector3(0.0, _yaw, 0.0)
	_apply(1.0)
	cam.make_current()


## Yaw of this rig whose +Z (the arm's direction, back toward the camera) points at the camera spot:
## side — 90° off screen-right; behind — from the focus to the spot behind P1's shoulder.
func _target_yaw() -> float:
	if behind:
		var v := behind_spot() - behind_focus()
		return atan2(v.x, v.z)
	var back := GameState.duel.right.cross(Vector3.UP)
	return atan2(back.x, back.z)


## Ground separation between the fighters (m).
func _sep() -> float:
	var d := p2.global_position - p1.global_position
	return Vector2(d.x, d.z).length()


## Solo mode: the base focus (50 % P1 → P2, 1.2 m up), before bounded velocity lookahead.
func behind_focus() -> Vector3:
	var f := p1.global_position.lerp(p2.global_position, BEHIND_FOCUS)
	return Vector3(f.x, BEHIND_FOCUS_Y, f.z)


## Behind mode: where the camera wants to stand — behind P1 on the line, over the right shoulder, GDD 02 numbers.
func behind_spot() -> Vector3:
	var sep := _sep()
	var dist := minf(BEHIND_DIST + maxf(sep - BEHIND_DIST_SEP, 0.0) * BEHIND_DIST_PER_M, BEHIND_DIST_MAX)
	var h := lerpf(BEHIND_HEIGHT_NEAR, BEHIND_HEIGHT_FAR, clampf((sep - 1.0) / 3.0, 0.0, 1.0))
	# Midpoint/radius is identical to the original behind-P1 framing before a crossing. After it,
	# retain the chosen world side: translating from the new P1 would reverse the camera at long range.
	var line := _presentation_line
	var midpoint := (p1.global_position + p2.global_position) * 0.5
	var p := midpoint - line * (dist + sep * 0.5) + line.cross(Vector3.UP) * BEHIND_SHOULDER
	return Vector3(p.x, h, p.z)


## The yaw runs on the physics tick, so the smoke measures exactly what the rules say: |turn| ≤ YAW_CLAMP_DEG
## per tick and |change of turn| ≤ YAW_ACCEL_DEG per tick. The turn eases off so it can stop on the target
## (speed ≤ √(2·accel·remaining)) instead of overshooting.
func _physics_process(delta: float) -> void:
	if p1 == null or p2 == null:
		return
	aim_controller.step(delta)
	_update_presentation(delta)
	_yaw_prev = _yaw
	var diff := angle_difference(_yaw, _target_yaw() + aim_controller.yaw_offset)
	var accel := deg_to_rad(YAW_ACCEL_DEG)
	var want := signf(diff) * minf(minf(deg_to_rad(YAW_CLAMP_DEG), sqrt(2.0 * accel * absf(diff))), absf(diff))
	_omega += clampf(want - _omega, -accel, accel)
	_yaw += _omega
	rotation = Vector3(0.0, _yaw, 0.0)
	var lag := rad_to_deg(absf(angle_difference(_yaw, _target_yaw() + aim_controller.yaw_offset)))
	_pull = lerpf(_pull, PULLBACK_MAX if lag > PULLBACK_LAG_DEG else 0.0, 1.0 - pow(0.0015, delta))
	if force_pull >= 0.0:
		_pull = force_pull


## Yaw turn this physics tick (degrees) — the smoke's |Δω| check.
func turn_deg() -> float:
	return rad_to_deg(_omega)


## Arm length with the pull-back on `base`: +_pull, but never past max(PULLBACK_CAP_M, base).
func pulled(base: float) -> float:
	return minf(base * (1.0 + _pull), maxf(PULLBACK_CAP_M, base))


## Arm pull-back right now (0 … PULLBACK_MAX), for the smoke test.
func pullback() -> float:
	return _pull


func _process(delta: float) -> void:
	if p1 == null or p2 == null:
		return
	# render frames between physics ticks: interpolate the yaw (ADR-015 п. 3), never step it at 60 Hz
	rotation = Vector3(0.0, lerp_angle(_yaw_prev, _yaw, Engine.get_physics_interpolation_fraction()), 0.0)
	_apply(1.0 - pow(0.0015, delta))
	_apply_readability(1.0 - pow(0.0015, delta))
	var offset: Vector2 = _impact.step(delta, impact_scale * ComfortSettings.get_value("shake"))
	cam.h_offset = offset.x
	cam.v_offset = offset.y


## k = smoothing toward the target this frame (1 = snap).
func _apply(k: float) -> void:
	if behind:
		_apply_behind(k)
		return
	var a := p1.global_position
	var b := p2.global_position
	var sep := Vector3(a.x - b.x, 0.0, a.z - b.z).length()
	var hi := maxf(a.y, b.y)
	var dist := clampf(SIDE_DIST + sep * SIDE_DIST_PER_M, SIDE_DIST_MIN, SIDE_DIST_MAX)
	var focus := Vector3((a.x + b.x) * 0.5, 1.25 + hi * 0.4, (a.z + b.z) * 0.5)
	var lift := 0.35 + hi * 0.05 + dist * 0.14
	global_position = global_position.lerp(focus, k) if k < 1.0 else focus
	arm.rotation = Vector3(-atan2(lift, dist), 0.0, 0.0)
	arm.spring_length = pulled(sqrt(dist * dist + lift * lift))


## Behind mode: rig at the focus, arm pitched and stretched so the camera lands on behind_spot() (the yaw is
## the rate-limited one, so on a fast turn the camera swings round instead of cutting).
func _apply_behind(k: float) -> void:
	var focus := behind_focus()
	var v := behind_spot() - focus
	var flat := Vector2(v.x, v.z).length()
	focus += _safe_lookahead()
	global_position = global_position.lerp(focus, k) if k < 1.0 else focus
	arm.rotation = Vector3(-atan2(v.y, flat) + aim_controller.pitch_offset, 0.0, 0.0)
	arm.spring_length = pulled(v.length())


## Zoom only the lens, never the rig/input basis or a fighter's physical scale. The farther body
## has a soft target; preserving the near body and edge margins wins when perspective prevents it.
## At most 16 projected corners per render frame; no mesh skinning or per-vertex runtime work.
func _apply_readability(k: float) -> void:
	var wanted := FOV_DEG
	if behind and _sep() > FAR_BLEND_START:
		var aspect := cam.get_viewport().get_visible_rect().size.aspect()
		var tangent := tan(deg_to_rad(FOV_DEG * 0.5))
		var inverse := cam.global_transform.affine_inverse()
		var safe_zoom := tangent / tan(deg_to_rad(FAR_FOV_MIN * 0.5))
		var shares: Array[float] = []
		for fighter: Fighter in [p1, p2]:
			var foot: Vector3 = inverse * fighter.global_position
			var head: Vector3 = inverse * (fighter.global_position + Vector3.UP * FRAMING_HEIGHT)
			if foot.z >= -cam.near or head.z >= -cam.near:
				safe_zoom = 1.0
				break
			shares.append(absf(head.y / -head.z - foot.y / -foot.z) / (2.0 * tangent))
			for x: float in [-FRAMING_RADIUS, FRAMING_RADIUS]:
				for z: float in [-FRAMING_RADIUS, FRAMING_RADIUS]:
					for y: float in [0.0, FRAMING_HEIGHT]:
						var point: Vector3 = inverse * (fighter.global_position + Vector3(x, y, z))
						if point.z >= -cam.near:
							safe_zoom = 1.0
							continue
						var nx := absf(point.x / (-point.z * tangent * aspect))
						var ny := absf(point.y / (-point.z * tangent))
						safe_zoom = minf(safe_zoom, (1.0 - 2.0 * FAR_HORIZONTAL_MARGIN) / maxf(nx, 0.0001))
						safe_zoom = minf(safe_zoom, 1.0 / maxf(ny, 0.0001))
		if shares.size() == 2:
			safe_zoom = minf(safe_zoom, FAR_NEAR_SAFE_SHARE / maxf(maxf(shares[0], shares[1]), 0.0001))
			var desired_zoom := FAR_TARGET_SHARE / maxf(minf(shares[0], shares[1]), 0.0001)
			var zoom := maxf(1.0, minf(desired_zoom, safe_zoom))
			var fitted := rad_to_deg(2.0 * atan(tangent / zoom))
			wanted = lerpf(FOV_DEG, fitted, smoothstep(FAR_BLEND_START, FAR_BLEND_END, _sep()))
	# Returning to near range may not keep a stale narrow lens: ADR-018 near framing has priority.
	# Widen immediately if the current lens would violate the newly computed safety limit; narrowing eases.
	cam.fov = maxf(wanted, lerpf(cam.fov, wanted, k))


## Accept the nearest equivalent pair axis against the PREVIOUS accepted axis, not the lagging
## rendered yaw. A continuous orbit therefore accumulates; an instant side swap does not demand 180°.
## This state never feeds back into DuelFrame, Fighter.forward or camera-relative input.
func _update_presentation(delta: float) -> void:
	if aim_controller != null and aim_controller.is_manual():
		return # Manual orbit owns the bearing; auto must not counter-steer.
	if not behind:
		_lookahead = Vector3.ZERO
		return
	var separation := _sep()
	if separation < AXIS_HOLD_ENTER:
		_axis_held = true
	elif separation >= AXIS_HOLD_EXIT:
		_axis_held = false
	if not _axis_held:
		var line := p2.global_position - p1.global_position
		line.y = 0.0
		line = line.normalized()
		if line.dot(_presentation_line) < 0.0:
			line = -line
		_presentation_line = line
	var velocity := (p1.velocity + p2.velocity) * 0.5
	velocity.y = 0.0
	var wanted := (velocity * LEAD_SECONDS).limit_length(LEAD_MAX)
	_lookahead = _lookahead.lerp(wanted, 1.0 - exp(-delta / LEAD_SMOOTH_SECONDS))


## Lead may spend only unused framing space. Bound it with a small fixed search, retaining the
## baseline if the nominal bodies cannot fit. The view still eases via the existing focus smoothing.
func _safe_lookahead() -> Vector3:
	if _lookahead.length_squared() < 0.000001:
		return Vector3.ZERO
	var aspect := cam.get_viewport().get_visible_rect().size.aspect()
	var tangent := tan(deg_to_rad(FOV_DEG * 0.5))
	var focus := behind_focus()
	var v := behind_spot() - focus
	var rig := Transform3D(Basis(Vector3.UP, rotation.y), focus)
	var pitched := Basis(Vector3.RIGHT, -atan2(v.y, Vector2(v.x, v.z).length()))
	var base := rig * Transform3D(pitched, Vector3.ZERO) * Transform3D(Basis.IDENTITY, Vector3(0, 0, pulled(v.length())))
	var lead := _lookahead
	for attempt in 7:
		var transform := base
		transform.origin += lead
		var inverse := transform.affine_inverse()
		var fits := true
		for fighter: Fighter in [p1, p2]:
			var foot: Vector3 = inverse * fighter.global_position
			var head: Vector3 = inverse * (fighter.global_position + Vector3.UP * FRAMING_HEIGHT)
			if foot.z >= -cam.near or head.z >= -cam.near:
				fits = false
			else:
				var share := absf(head.y / -head.z - foot.y / -foot.z) / (2.0 * tangent)
				var minimum := 0.125 if _sep() > 4.0 else 0.15
				if share > 0.30 or (_sep() <= 6.0 and share < minimum):
					fits = false
			for x: float in [-FRAMING_RADIUS, FRAMING_RADIUS]:
				for z: float in [-FRAMING_RADIUS, FRAMING_RADIUS]:
					for y: float in [0.0, FRAMING_HEIGHT]:
						var point: Vector3 = inverse * (fighter.global_position + Vector3(x, y, z))
						if point.z >= -cam.near or absf(point.x) > -point.z * tangent * aspect * (1.0 - 2.0 * FAR_HORIZONTAL_MARGIN) or absf(point.y) > -point.z * tangent:
							fits = false
		if fits:
			return lead
		lead *= 0.5
	return Vector3.ZERO


## Horizontal view direction of the camera (for the smoke turn-rate check).
func view_yaw() -> float:
	var z := cam.global_basis.z
	return atan2(z.x, z.z)


func shake(amount: float) -> void:
	_impact.trigger(amount)
