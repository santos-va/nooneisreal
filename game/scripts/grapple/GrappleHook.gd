class_name GrappleHook
extends Node3D
## Charge-based swept harpoon: 30-frame windup, fixed flight, confirmed contact.
## Hold an attached anchor to hang; steer tangentially and press toward it to reel.
## Charges regenerate sequentially (one per cooldown) and regen pauses while tethered.
## Design: docs/GDD/04-Grapple-System.md

signal changed(charges: int, cooldown_left: float, max_charges: int)

enum Target { NONE, ANCHOR, ENEMY }

enum Phase { IDLE, WINDUP, FLIGHT, HANG }
const WINDUP_FRAMES := 30
@export var projectile_speed: float = 36.0 # PLACEHOLDER pending playtest.
var phase: Phase = Phase.IDLE
var windup_progress: float = 0.0
var projectile_position := Vector3.ZERO
var _launch_origin := Vector3.ZERO
var _flight_direction := Vector3.ZERO
var _flight_distance: float = 0.0
var _selected_anchor: Node3D
var _prefer_enemy: bool = false
var _tip: MeshInstance3D
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
	_tip.material_override = mat
	_tip.top_level = true
	_tip.visible = false
	add_child(_tip)
	changed.emit(charges, cooldown_left, max_charges)


func reset() -> void:
	charges = max_charges
	cooldown_left = 0.0
	detach()
	changed.emit(charges, cooldown_left, max_charges)


func tick_regen(delta: float, tethered: bool) -> void:
	if busy() and not tethered:
		detach() # Interrupted windup/flight cannot launch later.
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


func busy() -> bool:
	return phase != Phase.IDLE


func fire(prefer_enemy: bool) -> int:
	if charges <= 0 or busy():
		Sfx.play("grapple_denied", -4)
		return Target.NONE
	_prefer_enemy = prefer_enemy
	phase = Phase.WINDUP
	_frames = 0
	windup_progress = 0.0
	# A shot without a target is still a shot; spend only at release.
	return Target.ENEMY if prefer_enemy else Target.ANCHOR


func _launch() -> void:
	_spend()
	_launch_origin = fighter.global_position + HAND
	projectile_position = _launch_origin
	_selected_anchor = null if _prefer_enemy else _best_anchor()
	var aim := aim_axis() if GameState.free_move else Vector3(float(fighter.facing), 0, 0)
	if is_instance_valid(_selected_anchor):
		aim = _selected_anchor.global_position - _launch_origin
	_flight_direction = aim.normalized()
	_flight_distance = 0.0
	phase = Phase.FLIGHT
	_tip.visible = true
	_tip.global_position = projectile_position
	_tip.global_basis = Basis(Quaternion(Vector3.UP, _flight_direction))
	_rope.visible = true
	Sfx.play("grapple_fire")


func _flight(delta: float, held: bool) -> void:
	var step := minf(projectile_speed * delta, range_m - _flight_distance)
	var end := projectile_position + _flight_direction * step
	var q := PhysicsRayQueryParameters3D.create(projectile_position, end, ArenaLayout.COVER_LAYER | 4)
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
		_frames = 0
		attached = held
		phase = Phase.HANG if held else Phase.IDLE
		_tip.visible = false
		if not held:
			detach()
		return
	if not hit.is_empty():
		var area := hit.collider as Area3D
		if area != null:
			var victim := area.get_parent() as Fighter
			if victim != null and victim != fighter and victim.hurtbox_enabled():
				_confirm_pull(victim)
		detach()
		return
	projectile_position = end
	_flight_distance += step
	_tip.global_position = end
	_draw_rope(fighter.global_position + HAND, end)
	if _flight_distance >= range_m:
		detach()


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


## Kinematic pendulum: gravity, explicit toward-anchor reel, tangent steering, then a distance
## constraint that removes only the outward radial velocity (tangential momentum is preserved).
func drive(delta: float, held: bool) -> void:
	if phase == Phase.WINDUP:
		_frames += 1
		windup_progress = float(_frames) / float(WINDUP_FRAMES)
		fighter.velocity.x = move_toward(fighter.velocity.x, 0.0, 30.0 * delta)
		fighter.velocity.z = move_toward(fighter.velocity.z, 0.0, 30.0 * delta)
		fighter.velocity.y -= Fighter.GRAVITY * delta
		fighter.move_and_slide()
		if _frames >= WINDUP_FRAMES:
			_launch()
		return
	if phase == Phase.FLIGHT:
		fighter.velocity.y -= Fighter.GRAVITY * delta
		fighter.move_and_slide()
		_flight(delta, held)
		return
	if not attached:
		return
	_frames += 1
	if not held:
		_release(false)
		return
	var f := fighter
	var hand := f.global_position + HAND
	var to_anchor := anchor_point - hand
	var radial := to_anchor.normalized()
	f.velocity.y -= Fighter.GRAVITY * delta * 0.9
	var wish := f.wish() if GameState.free_move else Vector3(InputRouter.axis(f.player_index), 0, 0)
	if f.control_locked:
		wish = Vector3.ZERO
	var forward_input := maxf(0.0, wish.dot(Vector3(radial.x, 0, radial.z).normalized()))
	rope_length = maxf(rope_length - reel_speed * delta * forward_input, 1.0)
	# Only tangent acceleration; neutral hold preserves rope length.
	f.velocity += (wish - radial * wish.dot(radial)) * steer_accel * delta
	var next := hand + f.velocity * delta
	var off := next - anchor_point
	if off.length() > rope_length:
		var n := off.normalized()
		next = anchor_point + n * rope_length
		f.velocity -= maxf(0.0, f.velocity.dot(n)) * n
	f.velocity = (next - hand) / delta
	if not GameState.free_move:
		f.velocity.z = 0.0
	f.velocity = f.velocity.limit_length(max_speed)
	f.move_and_slide()
	if not line_clear(f.global_position + HAND, anchor_point):
		_release(false)
		return
	_draw_rope(f.global_position + HAND, anchor_point)


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
	phase = Phase.IDLE
	windup_progress = 0.0
	_selected_anchor = null
	if _tip:
		_tip.visible = false
	attached = false
	_frames = 0
	if _rope:
		_rope.visible = false


func _confirm_pull(opp: Fighter) -> void:
	var f := fighter
	if GameState.free_move:
		opp.get_pulled_to(f.global_position + f.forward * 1.25, 22)
	else:
		opp.get_pulled(f.global_position.x + float(f.facing) * 1.25, 22)
	Sfx.play("grapple_hit")


func _draw_rope(a: Vector3, b: Vector3) -> void:
	# The skinned hand only anchors the rendered line, never the sweep or constraint.
	if is_instance_valid(fighter.skeletal):
		a = fighter.skeletal.hand_world("Right")
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
