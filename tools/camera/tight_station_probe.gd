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
## Filters (comma lists): --hero=choko,skea --station=practice,tight,open,wallrun --transition=hang,drop,kick,wallrun
##   (the wallrun station pairs only with the wallrun transition: city_parkour_check.gd:230 inputs at (14,0,31.25)).
## Options: --orbit=<rad> (one HarpoonAim.apply_look at the first hang tick), --png-every=N,
##          --jpg (frames as JPEG q90: cheap continuous strips with --png-every=1), --sample-every=N (pixel coverage cadence), --profile=low|medium|high (GraphicsSettings, default high),
##          --ink-sentinel (hero ink hulls painted pure green: exact ink count, frames not for art review),
##          --keep-all (keep the measurement images of every sampled tick, e.g. for render-identity diffs).
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
## Regression (headless, tools/gates/playable_check.sh):
##   --check [--break=damping|recovery50|floor|station|mask|restore|resident|lane]
##   Subject: for every route and tick of the declared set,
##   S1 tight kick: arm growth per tick <= 0.86 m and no arm jump > 3 m in either direction;
##   S2 practice station: hang and post-landing ticks keep >= 4/6 key points and visibility >= 0.85;
##   S3 tight kick: applied fill >= 0.25 and the ink outline stays at 1;
##   S4 tight kick: hero ink chain is body -> depth mask -> near hull exactly while fill < 1, and the
##      exact original opaque hull at fill 1 (render at full visibility as before iteration 2);
##   S5 tight kick, native pixels only (check mode turns --ink-sentinel on): ink <= 10 % of the frame
##      on every sampled tick and the ring is counted at full fill; headless has no pixels and skips S5,
##      saying so in its own line before the sentinel: "TIGHT_STATION S5=NOT MEASURED (headless)" (T4 audit
##      2026-10-07: a skip must be visible in the output, not only here); a native run prints the routes measured;
##   S6 fixture after choko practice hang: a resident 0.6 m from the lens is drawn at <= 25 % fill,
##      its node stays visible, shared NPC materials are untouched, exact slots return away from it;
##   S7 practice kick: no resident closer to the lens than the hero and taller in frame for > 30 ticks.
##   Thresholds are literals of the plan and the T6 criteria, never read from production code, so a
##   drifted constant in CityCamera/CityCameraProximity turns this red (T4 recurring class 14).
##   Sentinel: TIGHT_STATION_COMPLETE checks=N failures=M mode=<break or none>; failures print
##   "TIGHT_STATION: ..." errors.

const TIGHT_STATION := Vector3(4, 0, 31.4)
const TIGHT_LEDGE_CENTER := Vector3(4, 1.4, 29) # CityDistrict.gd PracticeLedge at f27fd67
const LEDGE_SIZE := Vector3(2.8, 2.8, 2.4)
const OPEN_STATION := Vector3(12, 0, -3.3)
const WALLRUN_STATION := Vector3(14, 0, 31.25) # tools/parkour/city_parkour_check.gd:230, 0.75 m from SouthBoundary
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
# docs/Plans/2026-10-07-Camera-Readability-Iteration-2.md step 2 / T6 review: ink <= 10 % of the frame on
# the old geometry (PLACEHOLDER of the plan). Step 3 / T6 Y1: no resident closer to the lens than the hero
# and taller in frame for more than 0.5 s (PLACEHOLDER). S6 fixture: a resident 0.6 m from the lens is
# drawn at <= 25 % fill (PLACEHOLDER of this iteration). Literals, never read from production code.
const PLAN_INK_FRAME_MAX: float = 0.10
const PLAN_RESIDENT_FOREGROUND_TICKS_MAX: int = 30
const RESIDENT_FIXTURE_LENS: float = 0.6
const RESIDENT_FIXTURE_FILL_MAX: float = 0.25
const OLD_RESIDENT_7_HOME := Vector3(2, 0, 22) # CityNpcActor.home_for(7) before iteration 2 (lane negative)
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
var s5_routes: int = 0 # tight-kick routes whose S5 ink was really sampled (0 headless)
var after_process: Node
var check_routes: Array[Array] = []
var transitions: Array[String] = ["hang", "drop", "kick"]
var orbit: float = 0.0
var profile: String = "high"
var png_every: int = 6
var jpg: bool = false
var ink_sentinel: bool = false
var keep_all: bool = false
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
var route_hull: Material
var restore_swapped: bool = false

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
		elif argument == "--ink-sentinel":
			ink_sentinel = true
		elif argument == "--keep-all":
			keep_all = true
		elif argument == "--jpg":
			jpg = true
		elif argument.begins_with("--png-every="):
			png_every = maxi(1, int(argument.trim_prefix("--png-every=")))
		elif argument.begins_with("--sample-every="):
			sample_every = maxi(1, int(argument.trim_prefix("--sample-every=")))
	native = DisplayServer.get_name() != "headless"
	if check_mode and native:
		ink_sentinel = true # S5 counts ink exactly; check-mode frames are not for art review.
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
	var expected: int = 0
	for station: String in stations:
		for transition: String in transitions:
			if _pairs(station, transition):
				expected += heroes.size()
	if check_mode:
		expected = check_routes.size()
		for spec: Array in check_routes:
			await route(spec[0], spec[1], spec[2])
	else:
		for hero: String in heroes:
			for station: String in stations:
				for transition: String in transitions:
					if _pairs(station, transition):
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
		"keypoints": KEYPOINTS, "station_geometry": geometry, "ink_sentinel": ink_sentinel,
		"images": saved, "failures": failures, "routes": routes, "trace": trace,
		"limits": "Station starts, not a continuous traversal; Linux llvmpipe Compatibility is not M3 Forward+; physics raycasts ignore visual-only meshes (pixel coverage covers them).",
	}
	if check_mode:
		_evaluate()
		receipt["s5"] = _s5_status()
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
		print("TIGHT_STATION " + _s5_status())
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
	# Captured before the camera's first update: the exact opaque hull S4 expects back at fill 1.
	route_hull = (actor.skeletal.hero_mesh.material_override as ShaderMaterial).next_pass
	restore_swapped = false
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
	elif break_mode == "mask":
		rig.proximity.depth_mask = false # Negative control: the opaque hull in the dither holes (dark figure).
	elif break_mode == "resident":
		rig.proximity.resident_fade = false # Negative control: residents keep full fill at the lens.
	elif break_mode == "lane":
		# Negative control: resident 7 back on its pre-iteration lane, set up exactly as CityNpcActor.setup did.
		var resident: Node3D = world.npc_director.actors.get(7)
		if resident == null:
			failures += 1
			push_error("TIGHT_STATION_PROBE lane control has no resident 7")
		else:
			resident.home = OLD_RESIDENT_7_HOME
			resident.position = OLD_RESIDENT_7_HOME
			resident.route.assign([OLD_RESIDENT_7_HOME + Vector3(-0.5, 0, -4), OLD_RESIDENT_7_HOME + Vector3(0.5, 0, -4),
				OLD_RESIDENT_7_HOME + Vector3(0.5, 0, 4), OLD_RESIDENT_7_HOME + Vector3(-0.5, 0, 4)])
			resident.waypoint = 7 % 4
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
		elif transition == "wallrun":
			# city_parkour_check.gd:230 inputs (up into the pilaster, then jump), held like a player for as long
			# as the run lasts: CityParkourMotor.gd:115 ends a wall run when jump is released.
			var running: bool = not acted or previous_phase == "wall_run"
			input.v_set(1, "up", tick >= IDLE_TICKS and running)
			input.v_set(1, "jump", tick >= IDLE_TICKS + 3 and running)
			if previous_phase == "wall_run" and not acted:
				acted = true
				action_tick = tick
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
		if break_mode == "restore" and not restore_swapped and row.ink_chain == "mask":
			# Negative control: once masked, the policy would hand back a copy instead of the exact hull.
			for entry: Dictionary in rig.proximity._hulls:
				entry.hull = (entry.hull as Material).duplicate()
			restore_swapped = true
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
			# A check run without --out keeps no files (native check: pixels are measured, not saved).
			row.merge(_pixels(output, tick, (keep_all or not kept.has(segment)) and (not check_mode or out_given)))
			kept[segment] = true
		if native and (not check_mode or out_given) and (tick % png_every == 0 or first_in_segment or tick == action_tick):
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
	if transition == "wallrun":
		ok = action_tick >= 0 and landed_tick >= 0
	elif transition == "kick":
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
	if check_mode and hero == "choko" and station_id == "practice" and transition == "hang" and break_mode in ["none", "resident"]:
		await _resident_fixture(world, rig)
	world.queue_free()
	await process_frame
	await physics_frame

func _declare_check_routes() -> void:
	# Each negative control runs only the routes its broken property is measured on.
	match break_mode:
		"damping", "recovery50", "floor":
			check_routes.assign([["choko", "tight", "kick"]])
		"station", "mask", "restore":
			check_routes.assign([["choko", "tight", "kick"]])
		"resident":
			check_routes.assign([["choko", "practice", "hang"]])
		"lane":
			check_routes.assign([["choko", "practice", "kick"], ["skea", "practice", "kick"]])
		_:
			for hero: String in ["choko", "skea"]:
				for transition: String in ["hang", "drop", "kick"]:
					check_routes.append([hero, "practice", transition])
				check_routes.append([hero, "tight", "kick"])

## The wall-run station has its own transition; hang/drop/kick belong to ledge stations.
static func _pairs(station: String, transition: String) -> bool:
	return (station == "wallrun") == (transition == "wallrun")

func _station_point(world: Node3D, station_id: String) -> Vector3:
	match station_id:
		"wallrun":
			return WALLRUN_STATION
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

## S5 needs pixels: headless never measures it, and a native run without ink samples did not measure it either.
func _s5_status() -> String:
	if not native:
		return "S5=NOT MEASURED (headless)"
	if s5_routes == 0:
		return "S5=NOT MEASURED (no ink samples)"
	return "S5=MEASURED (%d routes)" % s5_routes

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
		if station == "tight" and transition == "kick" and break_mode in ["none", "mask", "restore"]:
			# S4: the depth mask is on exactly while the fill is thinned; at full fill the exact original
			# opaque hull is back, so the hero renders as before the iteration.
			var masked: int = 0
			var whole: int = 0
			var wrong: Array[String] = []
			for row: Dictionary in rows:
				var thinned: bool = row.applied != null and float(row.applied) < 0.999
				var expected: String = "mask" if thinned else "hull"
				if thinned:
					masked += 1
				else:
					whole += 1
				if row.ink_chain != expected and wrong.size() < 4:
					wrong.append("t%d fill %s chain %s" % [int(row.tick), str(row.applied), str(row.ink_chain)])
			_check(wrong.is_empty() and masked > 0 and whole > 0,
				"%s depth mask iff fill < 1 (masked %d, full %d ticks)%s" % [id, masked, whole, "" if wrong.is_empty() else ": " + ", ".join(wrong)])
			# S5 (native pixels only; headless has none): exact sentinel ink <= 10 % of the frame on every
			# sampled tick, and the ink is really counted (a ring exists at full fill).
			var sampled: Array[Dictionary] = []
			for row: Dictionary in rows:
				if row.has("ink_px_frac"):
					sampled.append(row)
			if not sampled.is_empty():
				s5_routes += 1
				var top: Dictionary = sampled[0]
				var ring: int = 0
				for row: Dictionary in sampled:
					if float(row.ink_px_frac) > float(top.ink_px_frac):
						top = row
					if row.applied != null and float(row.applied) >= 0.999 and int(row.ink_px) > 0:
						ring += 1
				_check(float(top.ink_px_frac) <= PLAN_INK_FRAME_MAX, "%s ink max %.3f of frame (t%d, fill %s) <= %.2f" % [id, float(top.ink_px_frac), int(top.tick), str(top.applied), PLAN_INK_FRAME_MAX])
				_check(ring > 0, "%s ink sentinel counts the ring at full fill (%d ticks)" % [id, ring])
		if station == "practice" and transition == "kick" and break_mode in ["none", "lane"]:
			# S7 (T6 Y1): no resident closer to the lens than the hero and taller in frame (drawn at >= 50 %
			# fill) for more than 0.5 s once the kick starts.
			var run: int = 0
			var longest: int = 0
			for row: Dictionary in rows:
				if not (row.segment in ["kick", "kick_air", "landed"]):
					continue
				run = run + 1 if int(row.residents.foreground_visible) > 0 else 0
				longest = maxi(longest, run)
			_check(longest <= PLAN_RESIDENT_FOREGROUND_TICKS_MAX, "%s resident in the foreground %d consecutive ticks <= %d" % [id, longest, PLAN_RESIDENT_FOREGROUND_TICKS_MAX])
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

## S6: a resident walked into the lens is dithered by camera-local materials and comes back exactly.
func _resident_fixture(world: Node3D, rig) -> void:
	var camera: Camera3D = rig.camera
	var resident: Node3D = null
	for index: Variant in world.npc_director.actors:
		var candidate: Node3D = world.npc_director.actors[index]
		if is_instance_valid(candidate) and not candidate.conversing and String(candidate.work_kind).is_empty():
			resident = candidate
			break
	_check(resident != null, "S6 fixture found a walking resident")
	if resident == null:
		return
	var before: Array = _slot_pointers(resident)
	var shared: Dictionary = {}
	for item: Array in before:
		if item[2] is ShaderMaterial:
			shared[item[2]] = (item[2] as ShaderMaterial).get_shader_parameter("camera_visibility")
	var home_position: Vector3 = resident.global_position
	resident.pause_left = 60.0 # Holds the resident in place (the director rewrites `walking` every refresh).
	var forward: Vector3 = -camera.global_transform.basis.z
	resident.global_position = camera.global_position + Vector3(forward.x, 0.0, forward.z).normalized() * RESIDENT_FIXTURE_LENS - Vector3.UP * 1.0
	for frame: int in 24:
		await physics_frame
		await process_frame
	await after_process.processed
	var lens: float = _segment_on_screen(camera, resident.global_position).lens
	var applied: float = _resident_applied(resident)
	print("TIGHT_STATION_TRACE S6 resident=%s lens=%.3f fill=%.3f" % [resident.name, lens, applied])
	_check(lens <= RESIDENT_FIXTURE_LENS + 0.05 and applied <= RESIDENT_FIXTURE_FILL_MAX,
		"S6 resident %.2f m from the lens drawn at fill %.3f <= %.2f" % [lens, applied, RESIDENT_FIXTURE_FILL_MAX])
	_check(resident.visible and resident.visual.visible, "S6 resident node stays visible (material policy, not hide)")
	var mutated: Array[String] = []
	for material: ShaderMaterial in shared:
		if material.get_shader_parameter("camera_visibility") != shared[material]:
			mutated.append("%s %s->%s" % [material, str(shared[material]), str(material.get_shader_parameter("camera_visibility"))])
	_check(mutated.is_empty(), "S6 shared NPC materials are never mutated%s" % ("" if mutated.is_empty() else ": " + ", ".join(mutated.slice(0, 3))))
	resident.global_position = home_position
	resident.pause_left = 0.0
	for frame: int in 24:
		await physics_frame
		await process_frame
	await after_process.processed
	var after: Array = _slot_pointers(resident)
	var exact: bool = after.size() == before.size()
	if exact:
		for index: int in before.size():
			exact = exact and after[index][0] == before[index][0] and after[index][1] == before[index][1] and after[index][2] == before[index][2]
	_check(exact, "S6 resident slots restored to the exact original pointers away from the lens")

func _slot_pointers(resident: Node3D) -> Array:
	var result: Array = []
	for node: Node in resident.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh == null:
			continue
		result.append([mesh, -1, mesh.material_override])
		for surface: int in mesh.mesh.get_surface_count():
			result.append([mesh, surface, mesh.get_surface_override_material(surface)])
	return result

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
	if phase == "wall_run":
		return "wall_run"
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
	var ink_chain: String = "none"
	var body_material: ShaderMaterial = actor.skeletal.hero_mesh.material_override as ShaderMaterial
	if body_material != null:
		applied = body_material.get_shader_parameter("camera_visibility")
		ink_chain = _ink_chain(body_material)
		# The drawn ink is the hull itself, or the near hull behind the depth mask while faded.
		var drawn_ink: Material = body_material.next_pass
		if drawn_ink != null and drawn_ink.has_meta("camera_proximity_mask"):
			drawn_ink = drawn_ink.next_pass
		if drawn_ink is ShaderMaterial:
			applied_outline = (drawn_ink as ShaderMaterial).get_shader_parameter("camera_outline_visibility")
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
		"ink_chain": ink_chain,
		"fill": snappedf(float(rig.proximity.get("fill_visibility") if rig.proximity.get("fill_visibility") != null else rig.proximity.visibility), 0.0001),
		"keypoints": points, "keypoints_visible": snappedf(float(visible) / float(KEYPOINTS.size()), 0.0001),
		"keypoint_min_depth": snappedf(min_depth, 0.0001),
		"cam_in_solid": solid, "near_plane_overlap": near_hits, "near_plane_overlap_21_9": near_wide,
		"clearance": snappedf(_clearance(space, cam, exclude), 0.001),
		"residents": _residents(world, actor, camera),
	}

## Hero ink chain at this tick, against the hull captured before the camera's first update:
## "hull" = the exact original opaque hull, "mask" = depth mask (ALPHA 0, depth_draw_always, lower
## priority) -> near hull (hero_outline_near, depth_draw_never), anything else is reported verbatim.
func _ink_chain(body: ShaderMaterial) -> String:
	var link: Material = body.next_pass
	if link == null:
		return "none"
	if link == route_hull:
		return "hull"
	if link.has_meta("camera_proximity_mask") and link is ShaderMaterial and link.next_pass is ShaderMaterial:
		var mask := link as ShaderMaterial
		var near := link.next_pass as ShaderMaterial
		var mask_path: String = mask.shader.resource_path if mask.shader != null else ""
		var near_path: String = near.shader.resource_path if near.shader != null else ""
		if mask_path == "res://shaders/camera_proximity_mask.gdshader" and near_path == "res://shaders/hero_outline_near.gdshader" and mask.render_priority < near.render_priority:
			return "mask"
		return "mask?%s>%s" % [mask_path.get_file(), near_path.get_file()]
	return "other:" + (link.resource_path if link.resource_path != "" else link.get_class())

## Residents in frame against the hero (T6 Y1: none closer to the lens than the hero and taller in
## frame for more than 0.5 s). Same 1.7 m vertical segment for everyone, so "taller" is comparable.
func _residents(world: Node3D, actor: Node3D, camera: Camera3D) -> Dictionary:
	var hero: Dictionary = _segment_on_screen(camera, actor.global_position)
	var result: Dictionary = {"count": 0, "foreground": 0, "foreground_indices": [], "foreground_visible": 0, "nearest_lens": null, "nearest_index": -1, "nearest_applied": null}
	if world.npc_director == null:
		return result
	var best: float = INF
	for index: Variant in world.npc_director.actors:
		var resident: Node3D = world.npc_director.actors[index]
		if not is_instance_valid(resident):
			continue
		result.count += 1
		var on_screen: Dictionary = _segment_on_screen(camera, resident.global_position)
		var applied: float = _resident_applied(resident)
		if on_screen.lens < best:
			best = on_screen.lens
			result.nearest_lens = snappedf(on_screen.lens, 0.001)
			result.nearest_index = int(index)
			result.nearest_applied = snappedf(applied, 0.001)
		if on_screen.in_frame and hero.in_frame and on_screen.depth < hero.depth and on_screen.height > hero.height:
			result.foreground += 1
			result.foreground_indices.append(int(index))
			if applied >= 0.5:
				result.foreground_visible += 1
	return result

func _segment_on_screen(camera: Camera3D, base: Vector3) -> Dictionary:
	var bottom: Vector3 = base + Vector3.UP * 0.05
	var top: Vector3 = base + Vector3.UP * 1.75
	var view: Transform3D = camera.global_transform.affine_inverse()
	var depth: float = -(view * ((bottom + top) * 0.5)).z
	var lens: float = camera.global_position.distance_to(Geometry3D.get_closest_point_to_segment(camera.global_position, bottom, top))
	var in_frame: bool = camera.is_position_in_frustum(bottom) or camera.is_position_in_frustum(top) or camera.is_position_in_frustum((bottom + top) * 0.5)
	var height: float = 0.0
	if depth > camera.near and not camera.is_position_behind(top) and not camera.is_position_behind(bottom):
		height = absf(camera.unproject_position(top).y - camera.unproject_position(bottom).y)
	return {"depth": depth, "lens": lens, "in_frame": in_frame, "height": height}

## Lowest camera_visibility on the resident's drawn materials (1 when the policy leaves it alone).
func _resident_applied(resident: Node3D) -> float:
	var low: float = 1.0
	for node: Node in resident.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh == null:
			continue
		for surface: int in mesh.mesh.get_surface_count():
			var material: ShaderMaterial = mesh.get_active_material(surface) as ShaderMaterial
			if material != null and material.get_shader_parameter("camera_visibility") != null:
				low = minf(low, float(material.get_shader_parameter("camera_visibility")))
	return low

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
		if ink_sentinel:
			_paint_ink(mesh)
	for camera: Camera3D in [cam_with, cam_without, cam_hero]:
		camera.global_transform = source.global_transform
		camera.fov = source.fov
		camera.near = source.near
		camera.far = source.far
		camera.keep_aspect = source.keep_aspect
	for viewport: SubViewport in [vp_with, vp_without, vp_hero]:
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

## --ink-sentinel (measurement runs only, frames not for art review): every hero ink hull is painted
## pure green, so ink pixels are counted exactly instead of by a dark colour that dark clothing shares.
func _paint_ink(mesh: GeometryInstance3D) -> void:
	var instance := mesh as MeshInstance3D
	if instance == null or instance.mesh == null:
		return
	var materials: Array[Material] = [instance.material_override]
	for surface: int in instance.mesh.get_surface_count():
		materials.append(instance.get_surface_override_material(surface))
		materials.append(instance.get_active_material(surface))
	for material: Material in materials:
		var link: Material = material
		var guard: int = 0
		while link != null and guard < 6:
			guard += 1
			if link is ShaderMaterial and _has_uniform(link as ShaderMaterial, "outline_color"):
				(link as ShaderMaterial).set_shader_parameter("outline_color", Color(0, 1, 0))
			link = link.next_pass

## Shader.code is the top file only (includes are not expanded), so ask the compiled uniform list.
static func _has_uniform(material: ShaderMaterial, uniform_name: String) -> bool:
	if material.shader == null:
		return false
	for uniform: Dictionary in material.shader.get_shader_uniform_list():
		if uniform.name == uniform_name:
			return true
	return false

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
				if ink_sentinel:
					if h[i] < 20 and h[i + 1] > 235 and h[i + 2] < 20:
						ink += 1
				# Unshaded ink hull colour (outline_color 0.06, 0.05, 0.09 -> sRGB 15, 13, 23); dark
				# clothing can share it, so --ink-sentinel is the exact count.
				elif absi(h[i] - 15) <= 6 and absi(h[i + 1] - 13) <= 6 and absi(h[i + 2] - 23) <= 6:
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
