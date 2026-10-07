extends SceneTree
## Tight-station camera readability probe. Measurement only: production CityWorld,
## CityCamera, SpringArm3D, CityCameraProximity and the parkour motor run unmodified;
## the hero is driven only through InputRouter virtual input, like a player.
##
## Native (pixels + PNG), same flags as the CI Compatibility step:
##   xvfb-run -a -s '-screen 0 1280x720x24 -nolisten tcp' godot --path game \
##     --rendering-method gl_compatibility --audio-driver Dummy --fixed-fps 60 \
##     --script "$PWD/tools/camera/tight_station_probe.gd" -- --out=DIR
## Headless (geometry only, no pixels/PNG): godot --headless --path game --fixed-fps 60 --script ...
## Filters (comma lists): --hero=choko,skea --station=tight,open --transition=hang,drop,kick
## Options: --orbit=<rad> (one HarpoonAim.apply_look at the first hang tick), --png-every=N,
##          --jpg (frames as JPEG q90: cheap continuous strips with --png-every=1), --sample-every=N (pixel coverage cadence), --profile=low|medium|high (GraphicsSettings, default high).
## Output: DIR/receipt.json (per-tick trace + per-segment summary), DIR/summary.csv,
##         DIR/<case>/NNNN.png (production frame with HUD), DIR/<case>/mNNNN_*.png (pixel masks).
## The only presentation touch is a measurement visual layer on hero meshes (HERO_LAYER) so two
## extra SubViewports can render the same camera with and without the hero (a third, hero-only view
## gives the drawn silhouette; hero_px = changed pixels inside it, so the hero's shadow is excluded); the production camera
## cull mask contains that layer, lights keep their full cull masks, gameplay/physics are untouched.
## failures counts harness integrity only (missing hang/kick/drop/landing), not readability.
##
## Stations: practice = the shipped PracticeLedge grip face (read from CityDistrict); tight = the
## pre-2026-10-07 ledge rebuilt as a probe-only fixture 1.8 m from SouthBoundary; open = control.
## Regression (headless, tools/gates/playable_check.sh): --check [--break=damping|recovery50|floor|station]
##   Subject: for every route and tick of the declared set,
##   S1 tight kick: arm growth per tick <= 0.86 m and no arm jump > 3 m in either direction;
##   S2 practice station: hang and post-landing ticks keep >= 4/6 key points and visibility >= 0.85;
##   S3 tight kick: applied fill >= 0.25 and the ink outline stays at 1.
##   Thresholds are literals of the plan and the T6 criteria, never read from production code, so a
##   drifted constant in CityCamera/CityCameraProximity turns this red (T4 recurring class 14).
##   Sentinel: TIGHT_STATION_COMPLETE checks=N failures=M mode=<break or none>; failures print
##   "TIGHT_STATION: ..." errors.

const TIGHT_STATION := Vector3(4, 0, 31.4)
const TIGHT_LEDGE_CENTER := Vector3(4, 1.4, 29) # CityDistrict.gd PracticeLedge at f27fd67
const LEDGE_SIZE := Vector3(2.8, 2.8, 2.4)
const OPEN_STATION := Vector3(12, 0, -3.3)
const STATION_GAP: float = 1.2 # start this far from the grip face, as the original fixtures did
const MIN_KEYPOINTS: float = 4.0 / 6.0 # PLACEHOLDER (plan step 2)
const MIN_VISIBILITY: float = 0.85 # PLACEHOLDER (plan step 2)
const SETTLED_HANG_TICKS: int = 10
# docs/Plans/2026-10-07-Tight-Support-Camera.md step 1 after e47be94: "0 jumps > 3 m and growth per tick by
# 1 - e^(-k dt), k = 9.21 -> <= 0.86 m/tick". PLACEHOLDER values of the plan, deliberately not computed.
const PLAN_ARM_GROWTH_MAX: float = 0.86
const PLAN_ARM_JUMP_MAX: float = 3.0
# docs/Art/2026-10-07-Tight-Station-Readability-Criteria.md / plan step 3: the fill thins to a 25 % floor.
const PLAN_FILL_FLOOR_MIN: float = 0.25
const KEYPOINTS: Array[String] = ["Head", "LeftHand", "RightHand", "Hips", "LeftFoot", "RightFoot"]
const HERO_LAYER: int = 1 << 19
const IDLE_TICKS: int = 30
const HANG_ACTION_TICK: int = 20
const HANG_HOLD_TICKS: int = 100
const SETTLE_TICKS: int = 45
const MAX_TICKS: int = 320
const MEASURE_SIZE := Vector2i(480, 320)
const ALL_LAYERS: int = 0xFFFFFFFF

var folder: String = "/tmp/nir-tight-station-probe"
var heroes: Array[String] = ["choko", "skea"]
var stations: Array[String] = ["practice", "tight", "open"]
var check_mode: bool = false
var break_mode: String = "none"
var out_given: bool = false
var checks: int = 0
var check_failures: int = 0
var after_process: Node
var check_routes: Array[Array] = []
var transitions: Array[String] = ["hang", "drop", "kick"]
var orbit: float = 0.0
var profile: String = "high"
var png_every: int = 6
var jpg: bool = false
var arm_recovery_override: float = -1.0
var sample_every: int = 3
var native: bool = false
var trace: Array[Dictionary] = []
var routes: Array[Dictionary] = []
var summary_rows: Array[String] = []
var geometry: Dictionary = {}
var saved: int = 0
var failures: int = 0
var input: Node
var game: Node
var fighter_script: Script
var vp_with: SubViewport
var vp_without: SubViewport
var vp_hero: SubViewport
var cam_with: Camera3D
var cam_without: Camera3D
var cam_hero: Camera3D

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			folder = argument.trim_prefix("--out=")
			out_given = true
		elif argument == "--check":
			check_mode = true
		elif argument.begins_with("--break="):
			break_mode = argument.trim_prefix("--break=")
		elif argument.begins_with("--hero="):
			heroes.assign(Array(argument.trim_prefix("--hero=").split(",")))
		elif argument.begins_with("--station="):
			stations.assign(Array(argument.trim_prefix("--station=").split(",")))
		elif argument.begins_with("--transition="):
			transitions.assign(Array(argument.trim_prefix("--transition=").split(",")))
		elif argument.begins_with("--orbit="):
			orbit = float(argument.trim_prefix("--orbit="))
		elif argument.begins_with("--profile="):
			profile = argument.trim_prefix("--profile=")
		elif argument.begins_with("--arm-recovery-rate="):
			arm_recovery_override = float(argument.trim_prefix("--arm-recovery-rate="))
		elif argument == "--jpg":
			jpg = true
		elif argument.begins_with("--png-every="):
			png_every = maxi(1, int(argument.trim_prefix("--png-every=")))
		elif argument.begins_with("--sample-every="):
			sample_every = maxi(1, int(argument.trim_prefix("--sample-every=")))
	native = DisplayServer.get_name() != "headless"
	if check_mode:
		_declare_check_routes()
	if not check_mode or out_given:
		DirAccess.make_dir_recursive_absolute(folder)
	# Reads happen after every node's _process (CityCamera applies proximity there), also headless.
	var helper := GDScript.new()
	helper.source_code = "extends Node\nsignal processed\nfunc _process(_delta: float) -> void:\n\tprocessed.emit()\n"
	helper.reload()
	after_process = Node.new()
	after_process.set_script(helper)
	after_process.process_priority = 1000
	root.add_child(after_process)
	root.size = Vector2i(960, 640)
	await process_frame
	game = root.get_node("GameState")
	fighter_script = load("res://scripts/fighter/Fighter.gd")
	input = root.get_node("InputRouter")
	game.skeletal_rig = true
	# GraphicsSettings arrived with PR #183; an older checkout keeps its fixed project quality.
	var graphics: Node = root.get_node_or_null("GraphicsSettings")
	var old_profile: String = ""
	if graphics != null:
		old_profile = graphics.get_profile()
		graphics.set_profile(profile)
	else:
		profile = "project-default"
	if native:
		_build_measure_viewports()
	summary_rows.append("case,segment,ticks,arm_desired,arm_hit_min,arm_hit_med,arm_hit_max,arm_ratio_med,lift_med,cam_head_min,cam_head_med,cam_body_min,cam_body_med,visibility_min,visibility_med,visibility_max,applied_min,keypoints_visible_min,keypoints_visible_med,hero_px_frac_med,hero_px_frac_min,hero_only_px_frac_med,world_occluded_med,cam_in_solid_ticks,near_plane_overlap_ticks,near_plane_overlap_21_9_ticks,clearance_min,camera_y_max,arm_step_max,visibility_step_max,samples")
	var expected: int = heroes.size() * stations.size() * transitions.size()
	if check_mode:
		expected = check_routes.size()
		for spec: Array in check_routes:
			await route(spec[0], spec[1], spec[2])
	else:
		for hero: String in heroes:
			for station: String in stations:
				for transition: String in transitions:
					await route(hero, station, transition)
	if routes.size() != expected:
		failures += 1
		push_error("TIGHT_STATION_PROBE incomplete route set %d/%d" % [routes.size(), expected])
	var receipt: Dictionary = {
		"fixture": "production CityWorld; declared station starts; InputRouter virtual input only",
		"engine": Engine.get_version_info().string,
		"renderer": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"display": DisplayServer.get_name(), "native_pixels": native,
		"quality": profile, "scaling_3d_scale": root.scaling_3d_scale, "msaa_3d": root.msaa_3d, "viewport": [root.size.x, root.size.y], "measure_viewport": [MEASURE_SIZE.x, MEASURE_SIZE.y],
		"camera": "unaltered CityCamera/SpringArm3D/CityCameraProximity; orbit=%.4f rad applied once at first hang tick" % orbit,
		"keypoints": KEYPOINTS, "station_geometry": geometry,
		"images": saved, "failures": failures, "routes": routes, "trace": trace,
		"limits": "Station starts, not a continuous traversal; Linux llvmpipe Compatibility is not M3 Forward+; physics raycasts ignore visual-only meshes (pixel coverage covers them).",
	}
	if check_mode:
		_evaluate()
		receipt["checks"] = checks
		receipt["check_failures"] = check_failures
		receipt["break"] = break_mode
	if not check_mode or out_given:
		var file := FileAccess.open(folder.path_join("receipt.json"), FileAccess.WRITE)
		if file == null:
			failures += 1
		else:
			file.store_string(JSON.stringify(receipt, "\t") + "\n")
			file.close()
		var csv := FileAccess.open(folder.path_join("summary.csv"), FileAccess.WRITE)
		if csv == null:
			failures += 1
		else:
			csv.store_string("\n".join(summary_rows) + "\n")
			csv.close()
	if graphics != null:
		graphics.set_profile(old_profile)
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		if root.has_node(singleton):
			root.get_node(singleton).queue_free()
	for viewport: SubViewport in [vp_with, vp_without, vp_hero]:
		if viewport != null:
			viewport.queue_free()
	var deadline: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < deadline:
		await process_frame
		OS.delay_msec(1)
	if after_process != null:
		after_process.queue_free()
	if check_mode:
		if failures > 0:
			check_failures += failures
			push_error("TIGHT_STATION: harness incomplete (%d)" % failures)
		print("TIGHT_STATION_COMPLETE checks=%d failures=%d mode=%s" % [checks, check_failures, break_mode])
		quit(1 if check_failures else 0)
		return
	print("TIGHT_STATION_PROBE_COMPLETE routes=%d ticks=%d images=%d failures=%d" % [routes.size(), trace.size(), saved, failures])
	quit(1 if failures else 0)

func _build_measure_viewports() -> void:
	var magenta := Environment.new()
	magenta.background_mode = Environment.BG_COLOR
	magenta.background_color = Color(1, 0, 1)
	magenta.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	magenta.ambient_light_color = Color.WHITE
	magenta.ambient_light_energy = 0.4
	var built: Array = _measure_viewport("MeasureWithHero", 0xFFFFF, null)
	vp_with = built[0]
	cam_with = built[1]
	built = _measure_viewport("MeasureWithoutHero", 0xFFFFF & ~HERO_LAYER, null)
	vp_without = built[0]
	cam_without = built[1]
	built = _measure_viewport("MeasureHeroOnly", HERO_LAYER, magenta)
	vp_hero = built[0]
	cam_hero = built[1]

func _measure_viewport(id: String, mask: int, environment: Environment) -> Array:
	var viewport := SubViewport.new()
	viewport.name = id
	viewport.size = MEASURE_SIZE
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	var camera := Camera3D.new()
	camera.cull_mask = mask
	if environment != null:
		camera.environment = environment
	viewport.add_child(camera)
	camera.make_current()
	return [viewport, camera]

func route(hero: String, station_id: String, transition: String) -> void:
	var id: String = "%s_%s_%s" % [hero, station_id, transition]
	if not is_zero_approx(orbit):
		id += "_orbit%+.2f" % orbit
	if profile != "high" and profile != "project-default":
		id += "_" + profile
	var output: String = folder.path_join(id)
	if not check_mode or out_given:
		DirAccess.make_dir_recursive_absolute(output)
	game.p1_character = hero
	# Project classes stay dynamic: a --script SceneTree compiles before autoloads exist.
	var world = load("res://scenes/world/CityWorld.tscn").instantiate()
	world.story_save_enabled = false
	world.journey_save_enabled = false
	world.lower_story_save_enabled = false
	root.add_child(world)
	current_scene = world
	if world.player == null or world.progress == null or world.npc_director == null:
		failures += 1
		push_error("TIGHT_STATION_PROBE incomplete city initialization " + id)
		world.queue_free()
		await process_frame
		return
	world.progress.save_enabled = false
	world.npc_director.save_enabled = false
	var actor = world.player
	var rig = world.camera_rig
	var production_rate: float = rig.arm_recovery_rate
	var production_floor: float = rig.proximity.fill_floor
	if arm_recovery_override >= 0.0:
		rig.arm_recovery_rate = arm_recovery_override
	if break_mode == "damping":
		rig.arm_recovery_rate = 1.0e6 # Negative control: the pre-fix instant recovery.
	elif break_mode == "recovery50":
		rig.arm_recovery_rate = 50.0 # Negative control: a drifted but still damped constant (T ~ 0.09 s).
	elif break_mode == "floor":
		rig.proximity.fill_floor = 0.0 # Negative control: the pre-fix dither to nothing, line included.
		rig.proximity.keep_outline = false
	var station: Vector3 = _station_point(world, station_id)
	input.v_clear(1)
	actor.restart_at(station)
	rig.reset_view()
	# One settled physics tick for every route keeps all timelines identical.
	await physics_frame
	if not geometry.has(station_id):
		geometry[station_id] = _station_geometry(actor, station)
	var exclude: Array[RID] = _hero_rids(actor)
	var hang_ticks: int = 0
	var acted: bool = false
	var action_tick: int = -1
	var landed_tick: int = -1
	var kick_seen: bool = false
	var drop_seen: bool = false
	var last_segment: String = ""
	var images_before: int = saved
	var rows: Array[Dictionary] = []
	var kept: Dictionary = {}
	var end_tick: int = MAX_TICKS
	for tick: int in MAX_TICKS:
		await physics_frame
		var previous: Dictionary = actor.parkour_snapshot()
		var previous_phase: String = str(previous.get("phase", ""))
		if previous_phase == "hang":
			hang_ticks += 1
		if hang_ticks == 1 and previous_phase == "hang" and not is_zero_approx(orbit):
			rig.aim.apply_look(Vector2(-orbit, 0.0))
		if landed_tick >= 0:
			input.v_clear(1)
		elif hang_ticks == 0 and not acted:
			input.v_set(1, "up", tick >= IDLE_TICKS)
			input.v_set(1, "jump", tick >= IDLE_TICKS + 3)
		else:
			input.v_set(1, "up", false)
			var act: bool = transition != "hang" and (acted or hang_ticks >= HANG_ACTION_TICK)
			# "Away from the wall" in camera-relative keys for the current yaw (world +Z at yaw 0 = down).
			var away: Array[String] = []
			if act:
				away = _away_keys(rig.rotation.y)
			for key: String in ["up", "down", "left", "right"]:
				input.v_set(1, key, key in away)
			input.v_set(1, "jump", act and transition == "kick")
			input.v_set(1, "grapple_detach", act and transition == "drop" and not acted)
			if act and not acted:
				acted = true
				action_tick = tick
		await process_frame
		var sample: bool = native and (tick % sample_every == 0)
		if sample:
			_sync_measure(rig.camera, actor)
		await after_process.processed
		if native:
			await RenderingServer.frame_post_draw
		var snapshot: Dictionary = actor.parkour_snapshot()
		var phase: String = str(snapshot.get("phase", ""))
		if phase == "wall_kick":
			kick_seen = true
		if transition == "drop" and acted and tick <= action_tick + 2 and phase.is_empty() and previous_phase == "hang":
			drop_seen = true
		if acted and landed_tick < 0 and tick > action_tick + 3 and actor.is_on_floor() and phase.is_empty():
			landed_tick = tick
			end_tick = tick + SETTLE_TICKS
		var segment: String = _segment(tick, phase, hang_ticks, acted, landed_tick, transition)
		var row: Dictionary = _measure(world, actor, rig, exclude)
		var before: Dictionary = rows[-1] if not rows.is_empty() else row
		row["arm_step"] = snappedf(absf(float(row.arm_hit) - float(before.arm_hit)), 0.0001)
		row["visibility_step"] = snappedf(absf(float(row.visibility) - float(before.visibility)), 0.0001)
		row.merge({"case": id, "tick": tick, "segment": segment, "phase": phase,
			"progress": float(snapshot.get("progress", 0.0)), "hang_ticks": hang_ticks,
			"state": fighter_script.State.keys()[actor.state], "position": vec(actor.global_position),
			"velocity": vec(actor.velocity), "on_floor": actor.is_on_floor()})
		var first_in_segment: bool = segment != last_segment
		if sample:
			# Keep the raw measurement images once per segment so the mask method stays auditable.
			row.merge(_pixels(output, tick, not kept.has(segment)))
			kept[segment] = true
		if native and (tick % png_every == 0 or first_in_segment or tick == action_tick):
			var path: String = output.path_join(("%04d.jpg" if jpg else "%04d.png") % tick)
			var frame: Image = root.get_texture().get_image()
			if (frame.save_jpg(path, 0.9) if jpg else frame.save_png(path)) == OK:
				saved += 1
				row["image"] = path
			else:
				failures += 1
		last_segment = segment
		rows.append(row)
		trace.append(row)
		if transition == "hang" and hang_ticks >= HANG_HOLD_TICKS:
			end_tick = tick
		if tick >= end_tick:
			break
	input.v_clear(1)
	var ok: bool = hang_ticks > 0
	if transition == "kick":
		ok = ok and kick_seen and landed_tick >= 0
	elif transition == "drop":
		ok = ok and drop_seen and not kick_seen and landed_tick >= 0
	else:
		ok = ok and hang_ticks >= HANG_HOLD_TICKS
	if not ok:
		failures += 1
		push_error("TIGHT_STATION_PROBE route incomplete " + id)
	var segments: Dictionary = _summarize(id, rows)
	routes.append({"case": id, "hero": hero, "station": station_id, "station_point": vec(station),
		"transition": transition, "ok": ok, "hang_ticks": hang_ticks, "action_tick": action_tick,
		"production_rate": production_rate, "follow": rig.follow_distance, "production_floor": production_floor,
		"landed_tick": landed_tick, "kick_seen": kick_seen, "drop_seen": drop_seen,
		"ticks": rows.size(), "images": saved - images_before, "segments": segments})
	print("TIGHT_STATION_PROBE_ROUTE case=%s ok=%s ticks=%d hang=%d action=%d landed=%d" % [id, ok, rows.size(), hang_ticks, action_tick, landed_tick])
	world.queue_free()
	await process_frame
	await physics_frame

func _declare_check_routes() -> void:
	# Each negative control runs only the routes its broken property is measured on.
	match break_mode:
		"damping", "recovery50", "floor":
			check_routes.assign([["choko", "tight", "kick"]])
		"station":
			check_routes.assign([["choko", "tight", "kick"]])
		_:
			for hero: String in ["choko", "skea"]:
				for transition: String in ["hang", "drop", "kick"]:
					check_routes.append([hero, "practice", transition])
				check_routes.append([hero, "tight", "kick"])

func _station_point(world: Node3D, station_id: String) -> Vector3:
	match station_id:
		"tight":
			# Rebuild the old ledge with the district's own builder: same collision layer and material.
			world.district._box("ProbeTightLedge", TIGHT_LEDGE_CENTER, LEDGE_SIZE, "stone", 9)
			return TIGHT_STATION
		"practice":
			var ledge: Node3D = world.district.get_node_or_null("PracticeLedge") as Node3D
			var shape: BoxShape3D = null
			if ledge != null:
				for child: Node in ledge.get_children():
					if child is CollisionShape3D and (child as CollisionShape3D).shape is BoxShape3D:
						shape = (child as CollisionShape3D).shape as BoxShape3D
			if shape == null:
				failures += 1
				push_error("TIGHT_STATION_PROBE missing PracticeLedge collision")
				return OPEN_STATION
			var face: float = ledge.global_position.z + shape.size.z * 0.5
			return Vector3(ledge.global_position.x, 0, face + STATION_GAP)
	return OPEN_STATION

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		check_failures += 1
		push_error("TIGHT_STATION: " + label)

func _evaluate() -> void:
	for route_record: Dictionary in routes:
		var id: String = route_record.case
		var rows: Array[Dictionary] = []
		for row: Dictionary in trace:
			if row.case == id:
				rows.append(row)
		_check(bool(route_record.ok) and not rows.is_empty(), id + " route reached its declared phases")
		if rows.is_empty():
			continue
		var station: String = route_record.station
		var transition: String = route_record.transition
		if station == "tight" and transition == "kick" and break_mode in ["none", "damping", "recovery50"]:
			# S1: plan literals, on the old geometry where the sweep clears the wall top.
			var worst: float = 0.0
			var jump: float = 0.0
			for index: int in range(1, rows.size()):
				var step: float = float(rows[index].arm_hit) - float(rows[index - 1].arm_hit)
				worst = maxf(worst, step)
				jump = maxf(jump, absf(step))
			_check(worst <= PLAN_ARM_GROWTH_MAX, "%s arm outward growth %.3f m/tick <= %.2f" % [id, worst, PLAN_ARM_GROWTH_MAX])
			_check(jump <= PLAN_ARM_JUMP_MAX, "%s arm jump %.3f m/tick <= %.1f" % [id, jump, PLAN_ARM_JUMP_MAX])
		if station == "tight" and transition == "kick" and break_mode in ["none", "floor"]:
			# S3: the fill never thins below the criteria floor and the ink line stays on every tick.
			var floor_value: float = PLAN_FILL_FLOOR_MIN
			var low_fill: float = INF
			var low_outline: float = INF
			for row: Dictionary in rows:
				low_fill = minf(low_fill, float(row.applied) if row.applied != null else 1.0)
				low_outline = minf(low_outline, float(row.applied_outline) if row.applied_outline != null else 1.0)
			_check(low_fill >= floor_value - 0.0001, "%s applied fill min %.3f >= floor %.3f" % [id, low_fill, floor_value])
			_check(low_outline >= 0.9999, "%s ink outline min %.3f stays 1" % [id, low_outline])
		var s2_station: String = "tight" if break_mode == "station" else "practice"
		if station == s2_station and break_mode in ["none", "station"]:
			# S2: readable hero in the settled hang and on every tick after landing.
			var judged: int = 0
			var worst_points: float = 1.0
			var worst_visibility: float = 1.0
			for row: Dictionary in rows:
				var settled_hang: bool = row.segment == "hang" and int(row.hang_ticks) >= SETTLED_HANG_TICKS
				if settled_hang or row.segment == "landed":
					judged += 1
					worst_points = minf(worst_points, float(row.keypoints_visible))
					worst_visibility = minf(worst_visibility, float(row.visibility))
			_check(judged > 0 and worst_points >= MIN_KEYPOINTS - 0.0001 and worst_visibility >= MIN_VISIBILITY,
				"%s settled hang/landing key points min %.2f >= %.2f, visibility min %.2f >= %.2f over %d ticks" % [id, worst_points, MIN_KEYPOINTS, worst_visibility, MIN_VISIBILITY, judged])

func _away_keys(yaw: float) -> Array[String]:
	# DuelFrame.human_to_world: world = right * x + view * y, view = (-sin, 0, -cos), right = (cos, 0, -sin).
	# Both stations face +Z outward, so the best 8-way key set for +Z is (-sin yaw, -cos yaw) quantized.
	var keys: Array[String] = []
	if absf(sin(yaw)) > 0.38:
		keys.append("left" if sin(yaw) > 0.0 else "right")
	if absf(cos(yaw)) > 0.38:
		keys.append("down" if cos(yaw) > 0.0 else "up")
	return keys

func _segment(tick: int, phase: String, hang_ticks: int, acted: bool, landed_tick: int, transition: String) -> String:
	if landed_tick >= 0 and tick >= landed_tick:
		return "landed"
	if acted:
		if phase == "wall_kick":
			return "kick"
		if phase == "hang":
			return "hang"
		return transition + "_air"
	if phase == "hang":
		return "hang"
	if tick < IDLE_TICKS:
		return "idle"
	return "approach" if hang_ticks == 0 else phase

func _measure(world: Node3D, actor, rig, exclude: Array[RID]) -> Dictionary:
	var camera: Camera3D = rig.camera
	var cam: Vector3 = camera.global_position
	var space: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state
	var skeleton: Skeleton3D = actor.skeletal.hero_skeleton
	var points: Dictionary = {}
	var visible: int = 0
	var min_depth: float = INF
	var view: Transform3D = camera.global_transform.affine_inverse()
	for bone: String in KEYPOINTS:
		var index: int = skeleton.find_bone(bone)
		if index < 0:
			points[bone] = {"missing": true}
			continue
		var point: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(index).origin
		var in_frustum: bool = camera.is_position_in_frustum(point)
		var query := PhysicsRayQueryParameters3D.create(cam, point, ALL_LAYERS, exclude)
		var hit: Dictionary = space.intersect_ray(query)
		var occluder: String = "" if hit.is_empty() else String((hit.collider as Node).name)
		var seen: bool = in_frustum and hit.is_empty()
		if seen:
			visible += 1
		var depth: float = -(view * point).z
		min_depth = minf(min_depth, depth)
		points[bone] = {"distance": snappedf(cam.distance_to(point), 0.0001), "depth": snappedf(depth, 0.0001),
			"in_frustum": in_frustum, "occluder": occluder, "visible": seen}
	var head_index: int = skeleton.find_bone("Head")
	var head: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(head_index).origin
	# Same lens-to-body segment CityCameraProximity measures (player origin + 0.55..1.9 m).
	var near_body: Vector3 = Geometry3D.get_closest_point_to_segment(cam,
		actor.global_position + Vector3.UP * 0.55, actor.global_position + Vector3.UP * 1.9)
	var applied: Variant = null
	var applied_outline: Variant = null
	var body_material: ShaderMaterial = actor.skeletal.hero_mesh.material_override as ShaderMaterial
	if body_material != null:
		applied = body_material.get_shader_parameter("camera_visibility")
		if body_material.next_pass is ShaderMaterial:
			applied_outline = (body_material.next_pass as ShaderMaterial).get_shader_parameter("camera_outline_visibility")
	var solid: Array[String] = _overlap_names(space, _point_shape(), Transform3D(Basis.IDENTITY, cam), exclude)
	var near_hits: Array[String] = _overlap_names(space, _near_plane_shape(camera, float(root.size.x) / float(root.size.y)), _near_plane_transform(camera), exclude)
	var near_wide: Array[String] = _overlap_names(space, _near_plane_shape(camera, 21.0 / 9.0), _near_plane_transform(camera), exclude)
	return {
		"arm_desired": snappedf(rig.follow_distance, 0.0001),
		"arm_reach": snappedf(rig.arm.spring_length, 0.0001),
		"arm_hit": snappedf(rig.arm.get_hit_length(), 0.0001),
		"arm_ratio": snappedf(rig.arm.get_hit_length() / maxf(rig.arm.spring_length, 0.0001), 0.0001),
		"arm_lift": snappedf(rig.arm.position.y, 0.0001), "arm_shoulder": snappedf(rig.arm.position.x, 0.0001),
		"arm_pitch": snappedf(rig.arm.rotation.x, 0.0001), "close_weight": snappedf(rig._close_weight, 0.0001),
		"yaw": snappedf(rig.rotation.y, 0.0001), "camera_position": vec(cam),
		"cam_head": snappedf(cam.distance_to(head), 0.0001), "cam_body": snappedf(cam.distance_to(near_body), 0.0001),
		"visibility": snappedf(rig.proximity.visibility, 0.0001),
		"applied": null if applied == null else snappedf(float(applied), 0.0001),
		"applied_outline": null if applied_outline == null else snappedf(float(applied_outline), 0.0001),
		"fill": snappedf(float(rig.proximity.get("fill_visibility") if rig.proximity.get("fill_visibility") != null else rig.proximity.visibility), 0.0001),
		"keypoints": points, "keypoints_visible": snappedf(float(visible) / float(KEYPOINTS.size()), 0.0001),
		"keypoint_min_depth": snappedf(min_depth, 0.0001),
		"cam_in_solid": solid, "near_plane_overlap": near_hits, "near_plane_overlap_21_9": near_wide,
		"clearance": snappedf(_clearance(space, cam, exclude), 0.001),
	}

func _point_shape() -> Shape3D:
	var shape := SphereShape3D.new()
	shape.radius = 0.005
	return shape

func _near_plane_shape(camera: Camera3D, aspect: float) -> Shape3D:
	# KEEP_HEIGHT: fov is vertical, so a wider screen widens the near plane.
	var half_height: float = camera.near * tan(deg_to_rad(camera.fov * 0.5))
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0 * half_height * aspect, 2.0 * half_height, 0.002)
	return shape

func _near_plane_transform(camera: Camera3D) -> Transform3D:
	var pose: Transform3D = camera.global_transform.orthonormalized()
	pose.origin -= pose.basis.z * camera.near
	return pose

func _overlap_names(space: PhysicsDirectSpaceState3D, shape: Shape3D, pose: Transform3D, exclude: Array[RID]) -> Array[String]:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = pose
	query.collision_mask = ALL_LAYERS
	query.exclude = exclude
	var names: Array[String] = []
	for hit: Dictionary in space.intersect_shape(query, 8):
		var node: Node = hit.collider as Node
		names.append(String(node.name) if node != null else "?")
	return names

func _clearance(space: PhysicsDirectSpaceState3D, origin: Vector3, exclude: Array[RID]) -> float:
	# Largest free sphere around the lens, 0..1 m, against every collision layer.
	var low: float = 0.0
	var high: float = 1.0
	var shape := SphereShape3D.new()
	var query := PhysicsShapeQueryParameters3D.new()
	query.collision_mask = ALL_LAYERS
	query.exclude = exclude
	query.transform = Transform3D(Basis.IDENTITY, origin)
	for step: int in 12:
		var middle: float = (low + high) * 0.5
		shape.radius = maxf(middle, 0.001)
		query.shape = shape
		if space.intersect_shape(query, 1).is_empty():
			low = middle
		else:
			high = middle
	return low

func _hero_rids(actor: Node3D) -> Array[RID]:
	var rids: Array[RID] = [actor.get_rid()]
	for node: Node in actor.find_children("*", "CollisionObject3D", true, false):
		rids.append((node as CollisionObject3D).get_rid())
	return rids

func _hero_geometry(actor: Node3D) -> Array[GeometryInstance3D]:
	var meshes: Array[GeometryInstance3D] = []
	for node: Node in actor.find_children("*", "GeometryInstance3D", true, false):
		meshes.append(node as GeometryInstance3D)
	for child: Node in actor.get_parent().get_children():
		var script: Script = child.get_script() as Script
		if script != null and script.get_global_name() == &"CityCosmetics" and child.get("fighter") == actor:
			for node: Node in child.find_children("*", "GeometryInstance3D", true, false):
				meshes.append(node as GeometryInstance3D)
	return meshes

func _sync_measure(source: Camera3D, actor: Node3D) -> void:
	for mesh: GeometryInstance3D in _hero_geometry(actor):
		if mesh.layers != HERO_LAYER:
			mesh.layers = HERO_LAYER
	for camera: Camera3D in [cam_with, cam_without, cam_hero]:
		camera.global_transform = source.global_transform
		camera.fov = source.fov
		camera.near = source.near
		camera.far = source.far
		camera.keep_aspect = source.keep_aspect
	for viewport: SubViewport in [vp_with, vp_without, vp_hero]:
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func _pixels(output: String, tick: int, keep: bool) -> Dictionary:
	var with_hero: Image = vp_with.get_texture().get_image()
	var without_hero: Image = vp_without.get_texture().get_image()
	var hero_only: Image = vp_hero.get_texture().get_image()
	for image: Image in [with_hero, without_hero, hero_only]:
		if image.get_format() != Image.FORMAT_RGBA8:
			image.convert(Image.FORMAT_RGBA8)
	var a: PackedByteArray = with_hero.get_data()
	var b: PackedByteArray = without_hero.get_data()
	var h: PackedByteArray = hero_only.get_data()
	var total: int = MEASURE_SIZE.x * MEASURE_SIZE.y
	var visible: int = 0
	var changed: int = 0
	var silhouette: int = 0
	var ink: int = 0
	var mask: Image = Image.create(MEASURE_SIZE.x, MEASURE_SIZE.y, false, Image.FORMAT_L8) if keep else null
	for pixel: int in total:
		var i: int = pixel * 4
		var diff: int = absi(a[i] - b[i]) + absi(a[i + 1] - b[i + 1]) + absi(a[i + 2] - b[i + 2])
		# The hero-free camera also drops the hero's shadow (cull mask culls shadow casters), so a
		# changed pixel counts as hero only inside the drawn hero-only silhouette.
		var drawn: bool = not (h[i] > 240 and h[i + 1] < 15 and h[i + 2] > 240)
		if drawn:
			silhouette += 1
		if diff > 6:
			changed += 1
			if drawn:
				visible += 1
				# Unshaded ink hull colour (outline_color 0.06, 0.05, 0.09 -> sRGB 15, 13, 23).
				if absi(h[i] - 15) <= 6 and absi(h[i + 1] - 13) <= 6 and absi(h[i + 2] - 23) <= 6:
					ink += 1
				if keep:
					mask.set_pixel(pixel % MEASURE_SIZE.x, pixel / MEASURE_SIZE.x, Color.WHITE)
			elif keep:
				mask.set_pixel(pixel % MEASURE_SIZE.x, pixel / MEASURE_SIZE.x, Color(0.35, 0.35, 0.35))
	if keep:
		mask.save_png(output.path_join("m%04d_visible_mask.png" % tick))
		with_hero.save_png(output.path_join("m%04d_with.png" % tick))
		without_hero.save_png(output.path_join("m%04d_without.png" % tick))
		hero_only.save_png(output.path_join("m%04d_hero_only.png" % tick))
	return {"hero_px": visible, "hero_px_frac": snappedf(float(visible) / float(total), 0.00001),
		"changed_px_frac": snappedf(float(changed) / float(total), 0.00001),
		"ink_px": ink, "ink_px_frac": snappedf(float(ink) / float(total), 0.00001),
		"hero_only_px": silhouette, "hero_only_px_frac": snappedf(float(silhouette) / float(total), 0.00001),
		"world_occluded": null if silhouette == 0 else snappedf(1.0 - minf(1.0, float(visible) / float(silhouette)), 0.0001)}

func _station_geometry(actor: Node3D, station: Vector3) -> Dictionary:
	var space: PhysicsDirectSpaceState3D = actor.get_world_3d().direct_space_state
	var result: Dictionary = {"station": vec(station)}
	var exclude: Array[RID] = _hero_rids(actor)
	for label: String in ["ahead_-z", "behind_+z", "left_-x", "right_+x", "up"]:
		var direction: Vector3 = {"ahead_-z": Vector3.FORWARD, "behind_+z": Vector3.BACK, "left_-x": Vector3.LEFT,
			"right_+x": Vector3.RIGHT, "up": Vector3.UP}[label]
		var origin: Vector3 = station + Vector3.UP * 1.2
		var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 30.0, ALL_LAYERS, exclude)
		var hit: Dictionary = space.intersect_ray(query)
		result[label] = {} if hit.is_empty() else {"distance": snappedf(origin.distance_to(hit.position), 0.001),
			"collider": String((hit.collider as Node).name), "normal": vec(hit.normal)}
	return result

func _summarize(id: String, rows: Array[Dictionary]) -> Dictionary:
	var order: Array[String] = []
	var groups: Dictionary = {}
	for row: Dictionary in rows:
		var segment: String = row.segment
		if not groups.has(segment):
			groups[segment] = []
			order.append(segment)
		groups[segment].append(row)
	var result: Dictionary = {}
	for segment: String in order:
		var group: Array = groups[segment]
		var stats: Dictionary = {"ticks": group.size()}
		for key: String in ["arm_hit", "arm_ratio", "arm_lift", "cam_head", "cam_body", "visibility", "applied", "keypoints_visible", "hero_px_frac", "hero_only_px_frac", "world_occluded", "clearance"]:
			var values: Array[float] = []
			for row: Dictionary in group:
				if row.has(key) and row[key] != null:
					values.append(float(row[key]))
			stats[key] = _stats(values)
		var in_solid: int = 0
		var near_overlap: int = 0
		var near_wide: int = 0
		var camera_y_max: float = -INF
		var arm_step_max: float = 0.0
		var visibility_step_max: float = 0.0
		for row: Dictionary in group:
			if not (row.cam_in_solid as Array).is_empty():
				in_solid += 1
			if not (row.near_plane_overlap as Array).is_empty():
				near_overlap += 1
			if not (row.near_plane_overlap_21_9 as Array).is_empty():
				near_wide += 1
			camera_y_max = maxf(camera_y_max, float(row.camera_position[1]))
			arm_step_max = maxf(arm_step_max, float(row.arm_step))
			visibility_step_max = maxf(visibility_step_max, float(row.visibility_step))
		stats["cam_in_solid_ticks"] = in_solid
		stats["near_plane_overlap_ticks"] = near_overlap
		stats["near_plane_overlap_21_9_ticks"] = near_wide
		stats["camera_y_max"] = snappedf(camera_y_max, 0.0001)
		stats["arm_step_max"] = snappedf(arm_step_max, 0.0001)
		stats["visibility_step_max"] = snappedf(visibility_step_max, 0.0001)
		result[segment] = stats
		var first: Dictionary = group[0]
		summary_rows.append(",".join([id, segment, str(group.size()), _f(first.arm_desired),
			_s(stats, "arm_hit", "min"), _s(stats, "arm_hit", "median"), _s(stats, "arm_hit", "max"), _s(stats, "arm_ratio", "median"),
			_s(stats, "arm_lift", "median"), _s(stats, "cam_head", "min"), _s(stats, "cam_head", "median"),
			_s(stats, "cam_body", "min"), _s(stats, "cam_body", "median"),
			_s(stats, "visibility", "min"), _s(stats, "visibility", "median"), _s(stats, "visibility", "max"), _s(stats, "applied", "min"),
			_s(stats, "keypoints_visible", "min"), _s(stats, "keypoints_visible", "median"),
			_s(stats, "hero_px_frac", "median"), _s(stats, "hero_px_frac", "min"), _s(stats, "hero_only_px_frac", "median"),
			_s(stats, "world_occluded", "median"), str(in_solid), str(near_overlap), str(near_wide), _s(stats, "clearance", "min"),
			_f(camera_y_max), _f(arm_step_max), _f(visibility_step_max), str((stats.hero_px_frac as Dictionary).get("n", 0))]))
	return result

func _stats(values: Array[float]) -> Dictionary:
	if values.is_empty():
		return {"n": 0}
	var sorted: Array[float] = values.duplicate()
	sorted.sort()
	var middle: int = sorted.size() / 2
	var median: float = sorted[middle] if sorted.size() % 2 == 1 else (sorted[middle - 1] + sorted[middle]) * 0.5
	return {"n": sorted.size(), "min": snappedf(sorted[0], 0.0001), "median": snappedf(median, 0.0001), "max": snappedf(sorted[-1], 0.0001)}

func _s(stats: Dictionary, key: String, field: String) -> String:
	var entry: Dictionary = stats.get(key, {})
	return _f(entry[field]) if entry.has(field) else ""

func _f(value: Variant) -> String:
	return "" if value == null else "%.4f" % float(value)

func vec(value: Vector3) -> Array:
	return [snappedf(value.x, 0.0001), snappedf(value.y, 0.0001), snappedf(value.z, 0.0001)]
