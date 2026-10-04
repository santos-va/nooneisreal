class_name GrappleHook
extends Node3D
## Charge-based swept harpoon: 30-frame windup, fixed flight, confirmed contact.
## Hold an attached anchor to hang; Space reels a bounded distance, movement pumps the pendulum.
## Finite match inventory. Only recovery refunds; deployed ropes persist across rounds.
## Design: docs/GDD/04-Grapple-System.md

signal changed(charges: int, cooldown_left: float, max_charges: int)

enum Target { NONE, ANCHOR, ENEMY }

enum Phase { IDLE, WINDUP, FLIGHT, HANG, MISS_REWIND, ENEMY_EXTRACT }
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
var _hang_start_length: float = 0.0
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
	# A round returns an unfinished recoverable shot, never a deployed rope.
	if token != 0:
		registry.refund(token, fighter.player_index)
	token = 0
	_finish_idle()
	inventory_changed(registry.available(fighter.player_index), max_charges)


func on_match_cleared() -> void:
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


func reusable_rope() -> int:
	if registry == null:
		return 0
	var existing := registry.nearby(fighter.global_position + HAND)
	if existing != 0:
		var record: Dictionary = registry.records[existing]
		var hand := fighter.global_position + HAND
		if hand.distance_to(record.anchor) <= minf(record.length, range_m) + 0.001 and line_clear(hand, record.anchor):
			return existing
	return 0


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
			aim_intent = aim.capture(fighter, prefer_enemy)
	if not prefer_enemy:
		var existing := reusable_rope()
		if existing != 0 and not aim_intent.is_empty():
			var marker: Node = registry.records[existing].marker
			if String(aim_intent.get("target_id", "")) != String(marker.get_path()):
				existing = 0 # A recorded/manual choice has priority over proximity assistance.
		if existing != 0:
			var record: Dictionary = registry.records[existing]
			_deployed_token = existing
			registry.attach_user(existing, self)
			anchor_point = record.anchor
			rope_length = minf(record.length, (anchor_point - (fighter.global_position + HAND)).length())
			_hang_start_length = rope_length
			attached = true
			phase = Phase.HANG
			return Target.ANCHOR
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


func _recorded_anchor_occupied() -> bool:
	if _prefer_enemy or aim_intent.is_empty():
		return false
	var id := String(aim_intent.get("target_id", ""))
	var selected := get_node_or_null(NodePath(id)) as Node3D if not id.is_empty() else null
	return selected != null and registry.occupied(selected.global_position)


func _launch() -> void:
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
		if rope_length > range_m:
			projectile_position = anchor_point
			_begin_rewind()
			return
		_frames = 0
		# Two projectiles may select the same free point before either arrives.
		# The registry owns this atomic check; a rejected shot remains recoverable.
		if not registry.deploy(token, fighter.player_index, anchor_point, fighter.global_position + HAND, rope_length):
			projectile_position = anchor_point
			_begin_rewind()
			return
		_hang_start_length = rope_length
		_deployed_token = token
		registry.attach_user(token, self)
		token = 0
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


## Inextensible pendulum: motor work comes only from bounded Space reeling.
## Constraint displacement moves the body but is removed from stored radial momentum.
func drive(delta: float, held: bool, reel_held: bool = false) -> void:
	if delta <= 0.0:
		return
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
	if reel_held:
		var shortest := minf(_hang_start_length, maxf(minimum_rope, _hang_start_length - reel_distance))
		rope_length = minf(rope_length, maxf(rope_length - reel_speed * delta, shortest))
	f.velocity.y -= Fighter.GRAVITY * delta
	# Pump below the anchor only; full gravity and drag oppose perpetual powered loops.
	if radial.y > 0.35:
		f.velocity += (wish - radial * wish.dot(radial)) * steer_accel * delta
	f.velocity *= exp(-swing_drag * delta)
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
	if not line_clear(f.global_position + HAND, anchor_point):
		_release(false)
		return
	_draw_rope(f.global_position + HAND, anchor_point)


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
	_frames = 0
	if _rope:
		_rope.visible = false
	if _rope_visual:
		_rope_visual.visible = false


func _begin_rewind() -> void:
	phase = Phase.MISS_REWIND
	attached = false
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


func _draw_rope(a: Vector3, b: Vector3) -> void:
	# Compute slack at the physical attachment BEFORE substituting the skinned hand.
	# An overhead animated hand is closer to the anchor, but that is not spare cable.
	var physical_slack := maxf(0.0, rope_length - a.distance_to(b)) if phase == Phase.HANG else 0.0
	# The skinned hand only anchors the rendered line, never the sweep or constraint.
	if is_instance_valid(fighter.skeletal):
		a = fighter.skeletal.hand_world("Right")
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
