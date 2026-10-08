extends SceneTree
## Plan docs/Plans/2026-10-07-Living-Body.md step 2 (T5 brief § 2.2) on the real CityFighter, CityParkourMotor and
## InputRouter against real static colliders:
##   P1 vault      — on the run, a 1.0 m × 0.35 m obstacle is crossed in vault_seconds without a hang, the capsule never
##                   overlaps it, the hero lands beyond at the take-off level with no speed bonus; a 1.5 m obstacle,
##                   a 1.2 m deep one, a 1 m drop behind it, a standing jump and a low ceiling over it are not vaults;
##   P4 side run   — a jump along a wall on the run gives a horizontal run along it at wall_along_speed with the height
##                   held, Skea wall_seconds (39 ticks) and Choko side_wall_short_seconds (21 ticks); releasing the jump
##                   ends it and a fresh jump away kicks off the wall; a run into the wall, at 45° to it, in the open or
##                   a standing jump beside it is not a side run;
##   P5 shimmy     — in a hang, right moves the body along the ledge at shimmy_speed with both grips on the support and
##                   the hang timer running; it stops where the outer grip would leave the ledge and at an obstacle, and
##                   a mantle still works after it;
##   P8 heavy land — a 12 m drop without crouch is drawn as land_heavy and leaves land_lag, state and position as the same
##                   drop without the living body; a crouched landing on the run rolls and is never drawn as land_heavy.
## --break=<m> is a negative control (profile knobs widened); sentinel PARKOUR_MOVES_COMPLETE checks=N failures=M mutation=<m>.
const DT: float = 1.0 / 60.0
const MUTATIONS := ["vault_height", "vault_floor", "side_angle", "shimmy_grip"]
var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var actor: Node3D
var input: Node
var solids: Node3D
var FighterScript: Script
var profile: Resource


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	run.call_deferred()


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PARKOUR_MOVES: " + label)


func box(point: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var geometry := BoxShape3D.new()
	geometry.size = size
	shape.shape = geometry
	body.add_child(shape)
	solids.add_child(body)
	body.position = point
	return body


func step(count: int = 1) -> void:
	for index: int in count:
		await physics_frame
		actor._physics_process(DT)


func spawn(hero: String, rig: bool = false) -> void:
	root.get_node("GameState").skeletal_rig = rig
	actor = load("res://scenes/fighter/Fighter.tscn").instantiate()
	actor.set_script(load("res://scripts/world/CityFighter.gd"))
	actor.data = load("res://data/characters/" + hero + ".tres")
	root.add_child(actor)
	actor.set_physics_process(rig)
	check(actor.parkour.profile == profile, "the city fighter uses the shipped parkour profile this check reads")


func despawn() -> void:
	input.v_clear(1)
	actor.queue_free()
	await process_frame


func at(point: Vector3) -> void:
	input.v_clear(1)
	input.set_view_basis(1, Vector3.FORWARD)
	actor.restart_at(point)
	await step(6)


## True when the body capsule overlaps `body` at its current place.
func overlaps(body: StaticBody3D) -> bool:
	var shape: CollisionShape3D = actor.get_node("BodyShape") as CollisionShape3D
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape.shape
	query.transform = actor.global_transform * shape.transform
	query.collision_mask = actor.collision_mask
	query.exclude = [actor.get_rid()]
	for hit: Dictionary in actor.get_world_3d().direct_space_state.intersect_shape(query, 8):
		if hit.collider == body:
			return true
	return false


# --- P1 ----------------------------------------------------------------------------------------------------------
## Runs toward -Z from `start`, presses jump once the body is `jump_at` metres short of z = `face_z` (or stands and
## jumps when `run` is false) and watches the vault. Returns what happened.
func vault_run(start: Vector3, face_z: float, obstacle: StaticBody3D, run: bool = true) -> Dictionary:
	await at(start)
	var out: Dictionary = {"vault_ticks": 0, "hang": false, "overlap": false, "speed_in": 0.0, "speed_out": 0.0, "end": Vector3.ZERO, "landed_y": INF, "max_y": -INF}
	input.v_set(1, "up", run)
	var jumped: bool = false
	var was_vault: bool = false
	for tick: int in 150:
		if not jumped and (actor.position.z <= face_z + 1.15 or not run) and actor.is_on_floor():
			jumped = true
			out.speed_in = Vector2(actor.velocity.x, actor.velocity.z).length()
			input.v_press(1, "jump")
		await step()
		var phase: String = actor.parkour.phase
		if phase == "vault":
			out.vault_ticks += 1
			out.overlap = out.overlap or overlaps(obstacle)
		elif was_vault:
			out.speed_out = Vector2(actor.velocity.x, actor.velocity.z).length()
		out.hang = out.hang or phase in ["hang", "mantle"]
		out.max_y = maxf(out.max_y, actor.position.y)
		was_vault = phase == "vault"
		if jumped and tick > 10 and actor.is_on_floor() and actor.state != FighterScript.State.JUMP and phase.is_empty():
			out.landed_y = actor.position.y
			break
	input.v_set(1, "up", false)
	out.end = actor.position
	return out


func vaults() -> void:
	# Lane x = 0: the vault. x = 10: 1.5 m high. x = 20: 1.2 m deep. x = 30: 1 m drop behind. x = 40: low ceiling.
	var wall: StaticBody3D = box(Vector3(0, 0.5, 0), Vector3(2.4, 1.0, 0.35))
	var high: StaticBody3D = box(Vector3(10, 0.75, 0), Vector3(2.4, 1.5, 0.35))
	var deep: StaticBody3D = box(Vector3(20, 0.5, -0.425), Vector3(2.4, 1.0, 1.2))
	box(Vector3(30, 0.5, 4.0), Vector3(3.0, 1.0, 8.0))
	var edge: StaticBody3D = box(Vector3(30, 1.5, 0.175), Vector3(2.4, 1.0, 0.35))
	var low: StaticBody3D = box(Vector3(40, 0.5, 0), Vector3(2.4, 1.0, 0.35))
	box(Vector3(40, 2.45, 0), Vector3(2.4, 0.3, 3.0))
	await physics_frame
	if mutation == "vault_height":
		profile.vault_max_height = 3.0
	if mutation == "vault_floor":
		profile.vault_floor_tolerance = 5.0
	for hero: String in ["choko", "skea"]:
		spawn(hero)
		var good: Dictionary = await vault_run(Vector3(0, 0, 7), 0.175, wall)
		var want: int = roundi(profile.vault_seconds * 60.0)
		check(absi(int(good.vault_ticks) - want) <= 1, "%s: a run at the 1.0 m wall vaults for %d ticks (want %d)" % [hero, good.vault_ticks, want])
		check(not good.hang and not good.overlap, "%s: the vault never hangs and the capsule never overlaps the obstacle (hang %s, overlap %s)" % [hero, good.hang, good.overlap])
		check(good.end.z < -0.175 - 0.35 and absf(float(good.landed_y)) < 0.05, "%s: the hero lands beyond the obstacle at the take-off level (z %.2f, y %.3f)" % [hero, good.end.z, good.landed_y])
		check(good.speed_out <= good.speed_in + 0.001 and good.speed_out > 0.5 * good.speed_in, "%s: the vault carries the run speed and adds none (in %.2f, out %.2f m/s)" % [hero, good.speed_in, good.speed_out])
		var too_high: Dictionary = await vault_run(Vector3(10, 0, 7), 0.175, high)
		check(too_high.vault_ticks == 0, "%s: a 1.5 m obstacle is not a vault (%d ticks)" % [hero, too_high.vault_ticks])
		var too_deep: Dictionary = await vault_run(Vector3(20, 0, 7), 0.175, deep)
		check(too_deep.vault_ticks == 0, "%s: a 1.2 m deep obstacle is not a vault (%d ticks)" % [hero, too_deep.vault_ticks])
		var drop: Dictionary = await vault_run(Vector3(30, 1.0, 6.5), 0.35, edge)
		check(drop.vault_ticks == 0, "%s: an obstacle with a 1 m drop behind it is not a vault (%d ticks)" % [hero, drop.vault_ticks])
		var standing: Dictionary = await vault_run(Vector3(0, 0, 1.2), 0.175, wall, false)
		check(standing.vault_ticks == 0, "%s: a standing jump at the wall is not a vault (%d ticks)" % [hero, standing.vault_ticks])
		var ceiling: Dictionary = await vault_run(Vector3(40, 0, 7), 0.175, low)
		check(ceiling.vault_ticks == 0, "%s: a low ceiling over the obstacle blocks the vault path (%d ticks)" % [hero, ceiling.vault_ticks])
		print("PARKOUR_MOVES_INFO vault %s: %d ticks, speed %.2f → %.2f, end z %.2f y %.3f, max y %.2f" % [hero, good.vault_ticks, good.speed_in, good.speed_out, good.end.z, good.landed_y, good.max_y])
		await despawn()


# --- P4 ----------------------------------------------------------------------------------------------------------
## Runs from `start` with the inputs `keys` held, presses and holds jump at tick 12, releases it at `release` (-1:
## never) and watches the side run.
func side_run(start: Vector3, keys: Array, release: int = -1, ticks: int = 80) -> Dictionary:
	await at(start)
	var out: Dictionary = {"ticks": 0, "first": -1, "y0": 0.0, "dy": 0.0, "along": Vector3.ZERO, "start_pos": Vector3.ZERO, "end_pos": Vector3.ZERO, "wall_run": 0, "after": "", "forward": Vector3.ZERO}
	for key: String in keys:
		input.v_set(1, key, true)
	for tick: int in ticks:
		if tick == 12:
			input.v_press(1, "jump")
		input.v_set(1, "jump", tick >= 12 and (release < 0 or tick < release))
		await step()
		var phase: String = actor.parkour.phase
		if phase == "wall_side":
			if out.first < 0:
				out.first = tick
				out.y0 = actor.position.y
				out.start_pos = actor.position
				out.forward = actor.forward
			out.ticks += 1
			out.dy = maxf(out.dy, absf(actor.position.y - out.y0))
			out.end_pos = actor.position
		elif out.first >= 0 and String(out.after).is_empty():
			out.after = "%s/%s" % [phase, FighterScript.State.keys()[actor.state]]
		if phase == "wall_run":
			out.wall_run += 1
	for key: String in keys:
		input.v_set(1, key, false)
	input.v_set(1, "jump", false)
	return out


func side_runs() -> void:
	# A long wall whose east face (normal +X) is at x = -19.8; the run goes along -Z, 0.6 m from it.
	box(Vector3(-20, 3, -10), Vector3(0.4, 6, 40))
	await physics_frame
	if mutation == "side_angle":
		profile.side_wall_max_angle = 89.0
	for hero: String in ["choko", "skea"]:
		spawn(hero)
		var run: Dictionary = await side_run(Vector3(-19.2, 0, 12), ["up"])
		var want: int = roundi((profile.wall_seconds if hero == "skea" else profile.side_wall_short_seconds) * 60.0)
		var travel: Vector3 = Vector3(run.end_pos) - Vector3(run.start_pos)
		var speed: float = travel.length() / maxf(float(int(run.ticks) - 1) * DT, DT)
		check(absi(int(run.ticks) - want) <= 1, "%s: a jump along the wall on the run is a side run of %d ticks (want %d)" % [hero, run.ticks, want])
		# Pressed lightly against the wall (−normal × 0.5 m/s), the body closes the gap to it and never passes it.
		check(float(run.dy) < 0.05 and travel.x <= 0.001 and Vector3(run.end_pos).x >= -19.8 + 0.35 - 0.02 and travel.z < -0.5, "%s: the side run is horizontal along the wall and never through it (dy %.3f, travel %s, end x %.3f)" % [hero, run.dy, travel, Vector3(run.end_pos).x])
		check(absf(speed - profile.wall_along_speed) < 0.3 and Vector3(run.forward).dot(Vector3.FORWARD) > 0.95, "%s: it runs at wall_along_speed %.1f (%.2f m/s) facing along the wall" % [hero, profile.wall_along_speed, speed])
		check(String(run.after) == "/JUMP", "%s: after the run the hero falls (%s)" % [hero, run.after])
		# Released early: the run ends on the release tick and a fresh jump away from the wall kicks off it.
		await at(Vector3(-19.2, 0, 12))
		input.v_set(1, "up", true)
		var kicked: bool = false
		var side_ticks: int = 0
		var released_at: int = -1
		for tick: int in 70:
			if tick == 12:
				input.v_press(1, "jump")
			if actor.parkour.phase == "wall_side":
				side_ticks += 1
			if side_ticks == 5 and released_at < 0:
				released_at = tick
			input.v_set(1, "jump", tick >= 12 and released_at < 0)
			if released_at >= 0 and tick == released_at + 2:
				input.v_set(1, "up", false)
				input.v_set(1, "right", true)
				input.v_press(1, "jump")
				input.v_set(1, "jump", true)
			await step()
			if released_at >= 0 and tick == released_at:
				check(actor.parkour.phase != "wall_side", "%s: releasing the jump ends the side run" % hero)
			kicked = kicked or actor.parkour.phase == "wall_kick"
		input.v_clear(1)
		check(kicked, "%s: a fresh jump away from the wall after the side run is the existing wall kick" % hero)
		var into: Dictionary = await side_run(Vector3(-17.0, 0, -10), ["left"])
		check(into.ticks == 0, "%s: a run straight into the wall is not a side run (%d ticks; vertical wall run %d)" % [hero, into.ticks, into.wall_run])
		# Started so that both heroes pass within reach of the wall around the top of the jump.
		var diagonal: Dictionary = await side_run(Vector3(-16.4, 0, 0), ["up", "left"])
		check(diagonal.ticks == 0, "%s: a run at 45° to the wall is not a side run (%d ticks)" % [hero, diagonal.ticks])
		var open: Dictionary = await side_run(Vector3(0, 0, 12), ["up"])
		check(open.ticks == 0, "%s: a jump held in the open is not a side run (%d ticks)" % [hero, open.ticks])
		var standing: Dictionary = await side_run(Vector3(-19.2, 0, 0), [])
		check(standing.ticks == 0, "%s: a standing jump beside the wall is not a side run (%d ticks)" % [hero, standing.ticks])
		print("PARKOUR_MOVES_INFO side %s: %d ticks from tick %d, %.2f m/s, dy %.3f, then %s; into %d (wall run %d), 45° %d" % [hero, run.ticks, run.first, speed, run.dy, run.after, into.ticks, into.wall_run, diagonal.ticks])
		await despawn()


# --- P5 ----------------------------------------------------------------------------------------------------------
func hang_on(point: Vector3) -> bool:
	input.v_clear(1)
	input.set_view_basis(1, Vector3.FORWARD)
	actor.restart_at(point)
	actor.position = point
	actor._set_state(FighterScript.State.JUMP)
	actor.velocity = Vector3.UP
	input.v_set(1, "up", true)
	input.v_set(1, "jump", true)
	await step()
	input.v_set(1, "up", false)
	return actor.parkour.phase == "hang"


## Both grips of the current hang rest on `ledge`'s top at the real grip width (not the profile's, which a negative widens).
func grips_on(ledge: StaticBody3D) -> bool:
	var normal: Vector3 = actor.parkour.normal
	var tangent: Vector3 = normal.cross(Vector3.UP).normalized()
	var centre: Vector3 = (actor.parkour.hands[0] + actor.parkour.hands[1]) * 0.5
	for offset: float in [-0.24, 0.24]:
		var inside: Vector3 = centre + tangent * offset - normal * 0.12
		var query := PhysicsRayQueryParameters3D.create(inside + Vector3.UP * 0.08, inside - Vector3.UP * 0.08, actor.collision_mask)
		var hit: Dictionary = actor.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or hit.collider != ledge:
			return false
	return true


func shimmies() -> void:
	# A 4 m ledge 2 m high, south face (normal +Z) at z = -18, x from 18 to 22; a post beside it at the other lane.
	var ledge: StaticBody3D = box(Vector3(20, 1, -20), Vector3(4, 2, 4))
	var second: StaticBody3D = box(Vector3(40, 1, -20), Vector3(4, 2, 4))
	box(Vector3(41.0, 0.8, -17.55), Vector3(0.3, 1.6, 0.5))
	await physics_frame
	if mutation == "shimmy_grip":
		profile.grip_half_width = 0.0
	for hero: String in ["choko", "skea"]:
		spawn(hero)
		check(await hang_on(Vector3(20, 0.5, -17.3)), "%s: shimmy fixture hangs on the ledge" % hero)
		var x0: float = actor.position.x
		var hold0: float = float(actor.parkour_snapshot().get("hold_remaining", 0.0))
		input.v_set(1, "right", true)
		var grips: bool = true
		for tick: int in 60:
			await step()
			grips = grips and actor.parkour.phase == "hang" and grips_on(ledge)
		var moved: float = actor.position.x - x0
		var hold1: float = float(actor.parkour_snapshot().get("hold_remaining", 0.0))
		check(absf(moved - profile.shimmy_speed) < 0.08, "%s: right moves the hang %.2f m along the ledge in 1 s (shimmy_speed %.1f)" % [hero, moved, profile.shimmy_speed])
		check(grips, "%s: both grips stay on the ledge top while moving" % hero)
		check(absf((hold0 - hold1) - 1.0) < 0.05, "%s: the hang timer keeps running (%.2f → %.2f s)" % [hero, hold0, hold1])
		var limit: float = 22.0 - 0.24 - 0.12
		var furthest: float = actor.position.x
		for tick: int in 60:
			await step()
			if actor.parkour.phase == "hang":
				furthest = maxf(furthest, actor.position.x)
				grips = grips and grips_on(ledge)
		check(furthest <= 22.0 - 0.24 + 0.02 and furthest > limit - 0.2 and grips, "%s: the shimmy stops where the outer grip would leave the ledge (x %.2f, limit %.2f, grips %s)" % [hero, furthest, 22.0 - 0.24, grips])
		input.v_set(1, "right", false)
		input.v_set(1, "jump", false)
		await step()
		input.v_set(1, "up", true)
		input.v_press(1, "jump")
		input.v_set(1, "jump", true)
		await step()
		var mantled: bool = actor.parkour.phase == "mantle"
		for tick: int in 34:
			await step()
		input.v_clear(1)
		check(mantled and actor.position.y >= 2.0 and actor.position.z < -18.0, "%s: a mantle still climbs after the shimmy (mantle %s, at %s)" % [hero, mantled, actor.position])
		check(await hang_on(Vector3(40, 0.5, -17.3)), "%s: post fixture hangs on the second ledge" % hero)
		input.v_set(1, "right", true)
		var post_x: float = actor.position.x
		for tick: int in 60:
			await step()
			if actor.parkour.phase == "hang":
				post_x = maxf(post_x, actor.position.x)
		input.v_clear(1)
		check(post_x < 41.0 - 0.15 - 0.35 + 0.02, "%s: a post beside the hanging body stops the shimmy (x %.2f)" % [hero, post_x])
		await despawn()
	ledge.queue_free()
	second.queue_free()


# --- P8 ----------------------------------------------------------------------------------------------------------
## A drop from `height` at (x, z) with `velocity` and crouch held or not; the hero runs its own physics with the skeletal
## rig. Returns the living-body modes seen and the authority trace after touchdown.
func drop(point: Vector3, velocity: Vector3, crouch: bool, living: bool) -> Dictionary:
	actor.skeletal.living_body.enabled = living
	input.v_clear(1)
	input.set_view_basis(1, Vector3.FORWARD)
	actor.restart_at(point)
	actor.global_position = point
	actor._set_state(FighterScript.State.JUMP)
	actor.velocity = velocity
	if crouch:
		input.v_set(1, "crouch", true)
		input.v_set(1, "up", true)
	var out: Dictionary = {"modes": {}, "trace": [], "land_lag": -1, "roll": false}
	var landed: int = -1
	for tick: int in 140:
		await physics_frame
		await process_frame
		var mode: String = actor.skeletal.living_body.mode
		if not mode.is_empty():
			out.modes[mode] = int(out.modes.get(mode, 0)) + 1
		out.roll = out.roll or actor.parkour.phase == "landing_roll"
		if landed < 0 and actor.state != FighterScript.State.JUMP:
			landed = tick
			out.land_lag = actor.land_lag
		if landed >= 0:
			out.trace.append([actor.state, actor.land_lag, actor.global_position, actor.velocity, actor.squash])
			if tick - landed >= 40:
				break
	input.v_clear(1)
	actor.skeletal.living_body.enabled = true
	return out


func heavy_landings() -> void:
	for hero: String in ["choko", "skea"]:
		spawn(hero, true)
		await process_frame
		var drawn: Dictionary = await drop(Vector3(0, 12, 20), Vector3.ZERO, false, true)
		var plain: Dictionary = await drop(Vector3(0, 12, 20), Vector3.ZERO, false, false)
		check(int(drawn.modes.get("land_heavy", 0)) > 0, "%s: a 12 m drop without crouch is drawn as the heavy landing (%s)" % [hero, str(drawn.modes)])
		check(drawn.land_lag == plain.land_lag and drawn.trace == plain.trace and not drawn.trace.is_empty(), "%s: the heavy landing is picture only — land_lag %d (without the layer %d, data %d), state, position, velocity and squash equal the same drop without the living body over %d ticks" % [hero, drawn.land_lag, plain.land_lag, actor.data.land_frames, drawn.trace.size()])
		var rolled: Dictionary = await drop(Vector3(0, 12, 30), Vector3(0, 0, -6.0), true, true)
		check(rolled.roll and int(rolled.modes.get("land_heavy", 0)) == 0, "%s: a crouched landing on the run rolls and is never drawn as the heavy landing (roll %s, %s)" % [hero, rolled.roll, str(rolled.modes)])
		print("PARKOUR_MOVES_INFO heavy %s: drawn %s, land_lag %d; rolled %s %s" % [hero, str(drawn.modes), drawn.land_lag, rolled.roll, str(rolled.modes)])
		await despawn()


func run() -> void:
	await process_frame
	FighterScript = load("res://scripts/fighter/Fighter.gd")
	profile = load("res://data/world/city_parkour.tres")   # the cached instance CityFighter preloads
	var game: Node = root.get_node("GameState")
	game.set_free_move(true)
	game.water = null
	input = root.get_node("InputRouter")
	solids = Node3D.new()
	root.add_child(solids)
	box(Vector3(0, -0.5, 0), Vector3(120, 1, 120))
	await physics_frame
	if mutation in ["none", "vault_height", "vault_floor"]:
		await vaults()
	if mutation in ["none", "side_angle"]:
		await side_runs()
	if mutation in ["none", "shimmy_grip"]:
		await shimmies()
	if mutation == "none":
		await heavy_landings()
	input.v_clear(1)
	solids.queue_free()
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		root.get_node(singleton).queue_free()
	var drain_until_ms: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < drain_until_ms:
		await process_frame
		OS.delay_msec(1)
	print("PARKOUR_MOVES_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
	quit(1 if failures else 0)
