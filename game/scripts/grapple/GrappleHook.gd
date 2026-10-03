class_name GrappleHook
extends Node3D
## Charge-based grapple hook: tap = zip to an anchor, hold = swing (kinematic distance constraint,
## Spider-Man 2 (2004) style), tap with crouch = pull the enemy ("get over here").
## Charges regenerate sequentially (one per cooldown) and regen pauses while tethered.
## Design: docs/GDD/04-Grapple-System.md

signal changed(charges: int, cooldown_left: float, max_charges: int)

enum Target { NONE, ANCHOR, ENEMY }

const ZIP_FRAMES := 12
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
var reel_speed: float = 9.0
var zip_accel: float = 70.0
var release_boost: float = 1.15
var max_speed: float = 26.0
var steer_accel: float = 14.0
var cone_deg: float = 30.0      # free movement only (docs/GDD/04-Grapple-System.md § Конус вибору в 3D)

var attached: bool = false
var anchor_point: Vector3 = Vector3.ZERO
var rope_length: float = 0.0
var _frames: int = 0
var _rope: MeshInstance3D
var _rope_mesh: ImmediateMesh
var _flash_time: float = 0.0


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
	changed.emit(charges, cooldown_left, max_charges)


func reset() -> void:
	charges = max_charges
	cooldown_left = 0.0
	detach()
	changed.emit(charges, cooldown_left, max_charges)


func tick_regen(delta: float, tethered: bool) -> void:
	if _flash_time > 0.0:
		_flash_time -= delta
		if _flash_time <= 0.0:
			_rope.visible = attached
	if charges >= max_charges:
		cooldown_left = 0.0
		return
	if tethered:
		return
	cooldown_left -= delta
	if cooldown_left <= 0.0:
		charges = max_charges if regen_all else charges + 1
		cooldown_left = _recharge() if charges < max_charges else 0.0
		Sfx.play("ui_move", -12)
		changed.emit(charges, cooldown_left, max_charges)


func fire(prefer_enemy: bool) -> int:
	if charges <= 0:
		Sfx.play("grapple_denied", -4)
		changed.emit(charges, cooldown_left, max_charges)
		return Target.NONE
	var opp := fighter.opponent
	var enemy_ok := false
	if opp != null and opp.hurtbox_enabled():
		var to_opp := opp.global_position - fighter.global_position
		enemy_ok = to_opp.length() <= range_m and to_opp.length() > 1.2 and signf(to_opp.x) == float(fighter.facing)
		if GameState.free_move:
			enemy_ok = to_opp.length() <= range_m and to_opp.length() > 1.2 and _in_cone(to_opp, fighter.forward)
	var anchor := _best_anchor()
	var target := Target.NONE
	if prefer_enemy and enemy_ok:
		target = Target.ENEMY
	elif anchor != null:
		target = Target.ANCHOR
	elif enemy_ok:
		target = Target.ENEMY
	if target == Target.NONE:
		Sfx.play("grapple_denied", -4)
		return Target.NONE
	_spend()
	if target == Target.ANCHOR:
		anchor_point = anchor.global_position
		rope_length = maxf((anchor_point - (fighter.global_position + HAND)).length(), 2.0)
		attached = true
		_frames = 0
		_rope.visible = true
		Sfx.play("grapple_fire")
	return target


func _spend() -> void:
	charges -= 1
	fighter.add_fatigue(Fighter.FATIGUE_GRAPPLE_S)   # every shot, whichever of the three verbs (02 § Втома (б))
	if cooldown_left <= 0.0:
		cooldown_left = _recharge()
	changed.emit(charges, cooldown_left, max_charges)


## One charge's recharge now: the data's cooldown × the fighter's fatigue.
func _recharge() -> float:
	cooldown_total = cooldown * fighter.fatigue_mult(Fighter.FATIGUE_GRAPPLE)
	return cooldown_total


## Free movement: the cone axis — the camera-relative stick when it is deflected, else where the
## fighter looks (lock-on, i.e. at the opponent).
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
## Sprint A3: true when no cover (ArenaLayout.COVER_LAYER) lies on the segment `from` → `to`. Cover only — the floor and
## the fighters never cut a rope.
func line_clear(from: Vector3, to: Vector3) -> bool:
	if not is_inside_tree():
		return true
	var q := PhysicsRayQueryParameters3D.create(from, to, ArenaLayout.COVER_LAYER)
	return fighter.get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func best_anchor() -> Node3D:
	return _best_anchor()


func _best_anchor() -> Node3D:
	var best: Node3D = null
	var best_score := INF
	var origin := fighter.global_position + HAND
	var axis := aim_axis() if GameState.free_move else Vector3.ZERO
	for n in get_tree().get_nodes_in_group("grapple_anchor"):
		var a := n as Node3D
		if a == null:
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


## Kinematic pendulum: gravity, optional reel/zip toward the anchor, steer, then a distance
## constraint that removes only the outward radial velocity (tangential momentum is preserved).
func drive(delta: float, held: bool) -> void:
	if not attached:
		return
	_frames += 1
	var f := fighter
	var hand := f.global_position + HAND
	var to_anchor := anchor_point - hand
	var zipping := _frames <= ZIP_FRAMES
	f.velocity.y -= Fighter.GRAVITY * delta * 0.9
	if zipping or held:
		rope_length = maxf(rope_length - reel_speed * delta, 1.0)
		f.velocity += to_anchor.normalized() * zip_accel * delta
	if GameState.free_move:
		var w := f.wish()
		f.velocity += Vector3(w.x, 0.0, w.z) * steer_accel * delta   # camera-relative stick
	else:
		var steer := InputRouter.axis(f.player_index) if not f.control_locked else 0.0
		f.velocity.x += steer * steer_accel * delta
	var next := hand + f.velocity * delta
	var off := next - anchor_point
	if off.length() > rope_length:
		var n := off.normalized()
		next = anchor_point + n * rope_length
		f.velocity -= maxf(0.0, f.velocity.dot(n)) * n
	f.velocity = (next - hand) / delta
	if not GameState.free_move:
		f.velocity.z = 0.0
	if f.velocity.length() > max_speed:
		f.velocity = f.velocity.normalized() * max_speed
	f.move_and_slide()
	if not line_clear(f.global_position + HAND, anchor_point):
		_release(false)   # A3: cover cuts the rope (04 § Правило укриття)
		return
	_draw_rope(f.global_position + HAND, anchor_point)
	var reached := (anchor_point - (f.global_position + HAND)).length() < 1.4
	var landed := f.on_ground() and f.velocity.y <= 0.0 and _frames > 8
	if reached or landed or (not held and not zipping):
		_release(reached)


func _release(reached: bool) -> void:
	var f := fighter
	f.velocity *= release_boost
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
	attached = false
	_frames = 0
	if _rope:
		_rope.visible = false


## Enemy pull: instant for the prototype (no projectile). The opponent is yanked next to us and stunned.
func pull_enemy(opp: Fighter) -> void:
	var f := fighter
	var to_opp := opp.global_position - f.global_position
	if GameState.free_move:
		# along the gaze, in the same cone (docs/GDD/04-Grapple-System.md)
		if to_opp.length() > range_m or not _in_cone(to_opp, f.forward) or not opp.hurtbox_enabled():
			Sfx.play("whoosh", -6)
			return
		opp.get_pulled_to(f.global_position + f.forward * 1.25, 22)
	else:
		if to_opp.length() > range_m or signf(to_opp.x) != float(f.facing) or not opp.hurtbox_enabled():
			Sfx.play("whoosh", -6)
			return
		var target_x := f.global_position.x + float(f.facing) * 1.25
		opp.get_pulled(target_x, 22)
	_draw_rope(f.global_position + HAND, opp.global_position + Vector3(0, 1.1, 0))
	_rope.visible = true
	_flash_time = 0.12
	Sfx.play("grapple_hit")


func _draw_rope(a: Vector3, b: Vector3) -> void:
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
