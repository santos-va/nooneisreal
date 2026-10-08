extends SceneTree
## Plan docs/Plans/2026-10-07-First-Enemy-Lethal-Fight.md steps 3–4 (ADR-024 п. 4, п. 7): blood in the lethal pocket,
## ContentSettings, the blood card and HIT FLASH Reduced, on the real Arena / CityWorld / ComfortPanel with real
## keyboard and gamepad events where the player acts.
##   S. A sparring never shows blood, even with a BloodFx watching it.
##   C. ContentSettings defaults, round trip, damaged and unknown files kept byte for byte (session: ink / reduced);
##      the ComfortPanel rows by keyboard and gamepad; HIT FLASH Reduced ≤ half of Full.
##   L. The pocket: the card before the first fight (Esc / B step back unseen; Enter on a mode opens it, persisted,
##      never twice); levels by damage (< 50 / 50–89 / ≥ 90, crit +1, cap 4); clean hit → splash and floor drops
##      (1/2/3/4); block, DoT → none; frozen → splash; off / ink / muted; quality ½ and ¼; 16 floor drops at High;
##      the lens rule; the decisive KO → +1 level and a puddle to ≈ 1.2 m in three steps; the pocket's close takes the
##      blood with it.
##      Every mode draws its randomness from BloodFx.rng: a hit in full / muted / ink / off leaves the shared
##      FxShader.rng() and the global RNG where they were (ADR-024 п. 4).
##   T. Blood never changes the fight: fresh fights with blood (Choko Full/High, Choko Ink/High, Skea Muted/Low) are
##      identical tick by tick to the same hero's fight with Off/High — hp, states, positions, frames, hitstop, the
##      round and both fighters' and the CPU brain's RNG states. Five traces cover Ink, Muted, Low and both heroes
##      without a full cross product (Ink never reads the quality profile; Full/Muted do). TRACE_TICKS is PLACEHOLDER.
## Thresholds are literals of GDD 02 § Кров, the T6 brief and the T8 spec. --break=<m> is a negative control;
## sentinel BLOOD_CONTENT_COMPLETE checks=N failures=M mutation=<m>; failures print "BLOOD_CONTENT: ...".
const MUTATIONS := ["sparring", "cfg", "flash", "notice", "back", "block", "mode", "ink", "rng", "late", "state", "rng_state"]
const FLASH_FULL_SECONDS := 0.09        # RigAnimator.gd:194 at c1cdd4e, the current white flash
const HIT_LIGHT_FULL := 4.0             # HitSpark.gd:38, the current hit light
const REDUCED_MAX := 0.5                # T8: Reduced ≤ half of Full
const FLOOR_LIMIT_HIGH := 16            # T6 § Профілі якості: High 16 floor drops a fight
const PUDDLE_FULL := 1.2                # T6: the pool grows to ≈ 1.2 m …
const PUDDLE_STEPS := 3                 # … in three steps
const SAFE_POINT := Vector3(0, 0, 9.5)
const TRACE_TICKS := 700               # PLACEHOLDER: ≈ 11.7 s of fight, 14 splashes with Choko Full (2026-10-07)
## [hero, blood mode, quality profile] — the reference of each hero is Off/High (index 0 and 3).
const TRACES := [["choko", "off", "high"], ["choko", "full", "high"], ["choko", "ink", "high"], ["skea", "off", "high"], ["skea", "muted", "low"]]
var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var state: Node
var router: Node
var content: Node
var F: GDScript
var MF: GDScript
var BloodScript: GDScript
var SplashScript: GDScript
var FxS: GDScript
var _paths: Array[String] = []


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("BLOOD_CONTENT: " + label)


func _ticks(count: int) -> void:
	for tick: int in count:
		await physics_frame
		await process_frame


func _settle() -> void:
	for frame: int in 4:
		await process_frame


func _key(code: Key) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await physics_frame
		await _settle()


func _pad(button: JoyButton) -> void:
	for down: bool in [true, false]:
		var event := InputEventJoypadButton.new()
		event.device = 0
		event.button_index = button
		event.pressed = down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await physics_frame
		await _settle()


func _until(condition: Callable, limit: int) -> void:
	for tick: int in limit:
		if condition.call():
			return
		await _ticks(1)


func _temp(name: String) -> String:
	var path := "user://blood_content_%s_%d.cfg" % [name, OS.get_process_id()]
	_paths.append(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return path


func _write(path: String, bytes: PackedByteArray) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()


func _run() -> void:
	await process_frame
	state = root.get_node("GameState")
	router = root.get_node("InputRouter")
	content = root.get_node("ContentSettings")
	F = load("res://scripts/fighter/Fighter.gd")
	MF = load("res://scripts/arena/MatchFlow.gd")
	BloodScript = load("res://scripts/fx/BloodFx.gd")
	SplashScript = load("res://scripts/fx/BloodSplash.gd")
	FxS = load("res://scripts/fx/FxShader.gd")
	var old_content: String = content.storage_path
	state.set_free_move(true)
	router.apply_profile("solo", false)
	state.training_mode = false
	state.p1_character = "choko"
	state.p2_character = "skea"
	root.size = Vector2i(1600, 900)
	root.gui_embed_subwindows = true
	if mutation in ["none", "sparring"]:
		await _sparring()
	if mutation in ["none", "cfg", "flash"]:
		await _content_settings()
	if mutation in ["none", "notice", "back", "block", "mode", "ink", "rng", "late"]:
		await _pocket()
	if mutation in ["none", "state", "rng_state"]:
		await _traces()
	content.load_settings(old_content)
	for path: String in _paths:
		for suffix: String in ["", ".tmp"]:
			if FileAccess.file_exists(path + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	for singleton: String in ["Sfx", "UltMusic"]:
		root.get_node(singleton).queue_free()
	var until: int = Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("BLOOD_CONTENT_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
	quit(0 if failures == 0 else 1)


func _blood_nodes(scene: Node) -> int:
	var n := 0
	for node: Node in scene.find_children("*", "", true, false):
		var label := String(node.name)
		if label.contains("BloodSplash") or label.contains("BloodStain") or label.contains("BloodPuddle"):
			n += 1
	return n


# --- S. sparring ------------------------------------------------------------------------------------------
func _sparring() -> void:
	state.skeletal_rig = false
	content.set_blood_mode("full")
	var arena: Node = load("res://scenes/arena/Arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	var flow: Node = arena.get_node("MatchFlow")
	var p1: Node = arena.get("p1")
	var p2: Node = arena.get("p2")
	if p2._brain != null:
		p2._brain.process_mode = Node.PROCESS_MODE_DISABLED
	# A BloodFx wired into the duel, as a future change might: the fight's own `lethal` must still keep it dry.
	var blood: Node = BloodScript.new()
	arena.add_child(blood)
	blood.setup(p1, p2, flow)
	if mutation == "sparring":
		flow.lethal = true
	await _until(func() -> bool: return flow.phase == MF.Phase.FIGHT, 200)
	for i: int in 5:
		p2.receive_hit(p1, p1.data.heavy if i % 2 == 0 else p1.data.light)
		await _ticks(12)
	_check(blood.splashes == 0 and blood.ink_bursts == 0 and blood.floor_items.is_empty() and _blood_nodes(arena) == 0, "a sparring shows no blood after 5 clean hits (splashes %d, floor %d)" % [blood.splashes, blood.floor_items.size()])
	arena.queue_free()
	await _ticks(3)
	state.skeletal_rig = true


# --- C. ContentSettings, ComfortPanel rows, HIT FLASH ---------------------------------------------------
func _content_settings() -> void:
	var fresh := _temp("fresh")
	_check(content.load_settings(fresh) == OK and content.blood_mode() == "full" and content.hit_flash() == "full" and not content.notice_seen() and content.storage_ok(), "no file → Full blood, Full flash, card unseen")
	content.set_blood_mode("muted")
	content.set_hit_flash("reduced")
	content.mark_notice_seen()
	_check(content.save_settings() == OK, "a readable file saves")
	content.load_settings(fresh)
	_check(content.blood_mode() == "muted" and content.hit_flash() == "reduced" and content.notice_seen(), "the choices survive a reload")
	_check(not content.set_blood_mode("gore") and not content.set_hit_flash("strobe"), "unknown modes are refused")
	for case: Array in [["damaged", "[broken\nnot a content config".to_utf8_buffer()], ["unknown", "[content]\nblood=\"gore\"\nhit_flash=\"full\"\nnotice_seen=true\n".to_utf8_buffer()]]:
		var path := _temp(case[0])
		_write(path, case[1])
		var before := FileAccess.get_file_as_bytes(path)
		var printing: bool = Engine.print_error_messages
		Engine.print_error_messages = false   # the engine's own parse error is the expected outcome here
		content.load_settings(path)
		Engine.print_error_messages = printing
		_check(content.blood_mode() == "ink" and content.hit_flash() == "reduced" and not content.notice_seen() and not content.storage_ok(), "%s file → this session Ink, Reduced, card unseen" % case[0])
		content.set_blood_mode("full")
		content.mark_notice_seen()
		_check(content.save_settings() != OK, "%s file refuses to be saved over" % case[0])
		if mutation == "cfg":
			_write(path, "[content]\nblood=\"full\"\n".to_utf8_buffer())
		_check(FileAccess.get_file_as_bytes(path) == before, "%s file keeps its bytes for recovery" % case[0])
	# ComfortPanel: BLOOD and HIT FLASH by keyboard and gamepad, between CAMERA SHAKE and RESTORE.
	var ui_path := _temp("ui")
	content.load_settings(ui_path)
	var comfort: Node = root.get_node("ComfortSettings")
	var old_comfort: String = comfort.storage_path
	comfort.load_settings(_temp("comfort"))
	var launcher := Button.new()
	launcher.text = "LAUNCHER"
	root.add_child(launcher)
	var panel: Control = load("res://scripts/ui/ComfortPanel.gd").new()
	root.add_child(panel)
	await _settle()
	panel.show_panel(launcher, "help")
	await _settle()
	var shake: Control = panel.sliders["shake"]
	shake.grab_focus()
	await _key(KEY_DOWN)
	_check(panel.blood_choice.has_focus(), "Down from CAMERA SHAKE reaches BLOOD")
	await _key(KEY_ENTER)
	var popup: PopupMenu = panel.blood_choice.get_popup()
	_check(popup.visible, "Enter opens the BLOOD choices")
	await _key(KEY_DOWN)
	await _key(KEY_ENTER)
	_check(content.blood_mode() == "muted" and panel.blood_choice.selected == 1, "keyboard picks Muted (got %s)" % content.blood_mode())
	var saved := ConfigFile.new()
	_check(saved.load(ui_path) == OK and saved.get_value("content", "blood", "") == "muted", "the BLOOD choice is saved to content.cfg")
	panel.blood_choice.grab_focus()
	await _key(KEY_DOWN)
	_check(panel.hit_flash_choice.has_focus(), "Down from BLOOD reaches HIT FLASH")
	await _pad(JOY_BUTTON_A)
	await _pad(JOY_BUTTON_DPAD_DOWN)
	await _pad(JOY_BUTTON_A)
	_check(content.hit_flash() == "reduced" and panel.hit_flash_choice.selected == 1, "gamepad picks Reduced (got %s)" % content.hit_flash())
	panel.hit_flash_choice.grab_focus()
	await _key(KEY_DOWN)
	_check(panel.restore_button.has_focus(), "Down from HIT FLASH reaches RESTORE (the old RESTORE → help step stays)")
	panel.close_panel()
	panel.queue_free()
	launcher.queue_free()
	comfort.load_settings(old_comfort)
	await _settle()
	# HIT FLASH: Full is today's flash; Reduced is at most half of it, the hit light too.
	state.skeletal_rig = false
	var fighter: Node = load("res://scenes/fighter/Fighter.tscn").instantiate()
	root.add_child(fighter)
	await _ticks(1)
	content.set_hit_flash("full")
	fighter.animator.flash()
	_check(is_equal_approx(fighter.animator.flash_time, FLASH_FULL_SECONDS) and is_equal_approx(fighter.animator.flash_strength, 1.0), "Full keeps today's white flash (%.3f s, ×%.2f)" % [fighter.animator.flash_time, fighter.animator.flash_strength])
	var spark: Node3D = load("res://scripts/fx/HitSpark.gd").new()
	root.add_child(spark)
	spark.setup(false, Color.WHITE, 40.0)
	_check(is_equal_approx(spark._light.light_energy, HIT_LIGHT_FULL), "Full keeps today's hit light (%.2f)" % spark._light.light_energy)
	spark.queue_free()
	content.set_hit_flash("reduced")
	if mutation == "flash":
		content.set_hit_flash("full")
	fighter.animator.flash()
	_check(fighter.animator.flash_time <= FLASH_FULL_SECONDS * REDUCED_MAX + 0.0001 and fighter.animator.flash_strength <= REDUCED_MAX + 0.0001, "Reduced halves the white flash (%.3f s, ×%.2f)" % [fighter.animator.flash_time, fighter.animator.flash_strength])
	var dim: Node3D = load("res://scripts/fx/HitSpark.gd").new()
	root.add_child(dim)
	dim.setup(false, Color.WHITE, 40.0)
	_check(dim._light.light_energy <= HIT_LIGHT_FULL * REDUCED_MAX + 0.0001, "Reduced halves the hit light (%.2f)" % dim._light.light_energy)
	dim.queue_free()
	fighter.queue_free()
	content.set_hit_flash("full")
	state.skeletal_rig = true
	await _ticks(2)


# --- L. the lethal pocket -------------------------------------------------------------------------------
func _city() -> Node:
	var world: Node = load("res://scenes/world/CityWorld.tscn").instantiate()
	world.story_save_enabled = false
	world.journey_save_enabled = false
	world.lower_story_save_enabled = false
	root.add_child(world)
	current_scene = world
	world.progress.save_enabled = false
	world.npc_director.save_enabled = false
	return world


func _newest_splash(world: Node) -> Node:
	var found: Node = null
	for node: Node in world.get_node("FX").get_children():
		if node.get_script() == SplashScript:
			found = node
	return found


func _pocket() -> void:
	var path := _temp("pocket")
	content.load_settings(path)
	var world: Node = _city()
	var lethal: Node = world.lethal
	var hero: Node = world.player
	await _ticks(30)
	hero.restart_at(SAFE_POINT)
	await _ticks(150)
	await _key(KEY_G)
	await _ticks(1)
	var card: Node = lethal.notice
	_check(card != null and card.visible and not lethal.active and router.ui_suppressed(), "the first lethal fight starts with the blood card, not ROUND 1")
	if card == null or not card.visible:
		world.queue_free()
		await _ticks(3)
		return
	_check(card.title.text == "THIS FIGHT SHOWS BLOOD" and card.buttons.size() == 4 and card.buttons["full"].has_focus(), "the card names blood, offers the 4 modes and focuses the current one (Full)")
	# Esc (keyboard) and B (gamepad) step back to the city: no fight, no city pause, the card stays unseen, no file.
	for back: String in ["esc", "pad_b"]:
		if back == "esc":
			await _key(KEY_ESCAPE)
		else:
			await _pad(JOY_BUTTON_B)
		await _ticks(1)
		if mutation == "back":
			content.mark_notice_seen()   # a step back that counts as "seen": the card would never come again
		_check(not card.visible and not lethal.active and not content.notice_seen() and not router.ui_suppressed() and not world.hud.paused_ui and not FileAccess.file_exists(path), "%s steps back to the city: no fight, no pause, the card stays unseen, nothing saved" % back)
		await _key(KEY_G)
		await _ticks(1)
		_check(card.visible and card.buttons["full"].has_focus() and not lethal.active, "after %s the next interact shows the card again, focus on Full" % back)
	await _key(KEY_DOWN)
	_check(card.buttons["muted"].has_focus(), "Down moves to Muted")
	await _key(KEY_UP)
	await _key(KEY_ENTER)
	await _ticks(1)
	_check(not card.visible and lethal.active and content.notice_seen() and content.blood_mode() == "full", "Enter on Full confirms and opens the fight")
	if mutation == "notice":
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var saved := ConfigFile.new()
	_check(saved.load(path) == OK and bool(saved.get_value("content", "notice_seen", false)), "the seen card is saved (notice_seen = true)")
	if not lethal.active:
		world.queue_free()
		await _ticks(3)
		return
	var enemy: Node = lethal.enemy
	var flow: Node = lethal.flow
	var blood: Node = lethal.blood
	enemy._brain.process_mode = Node.PROCESS_MODE_DISABLED
	router.v_clear(2)
	await _until(func() -> bool: return flow.phase == MF.Phase.FIGHT, 200)
	hero.global_position = Vector3(-1.0, 0.02, 0)
	enemy.global_position = Vector3(1.0, 0.02, 0)
	await _ticks(3)
	# Levels by damage (GDD 02 § Кров).
	var levels: Array = [[49.0, false, 1], [50.0, false, 2], [89.0, false, 2], [90.0, false, 3], [40.0, true, 2], [60.0, true, 3], [95.0, true, 4]]
	var level_ok := true
	for row: Array in levels:
		level_ok = level_ok and BloodScript.call("level_for", row[0], row[1]) == row[2]
	_check(level_ok, "levels: < 50 → 1, 50–89 → 2, ≥ 90 → 3, crit +1, cap 4")
	enemy.hp = 1.0e6
	var light: Resource = hero.data.light
	# Clean hit on a grounded enemy: a splash and one floor drop (level 1).
	var s0: int = blood.splashes
	var f0: int = blood.floor_spawned
	enemy.receive_hit(hero, light)
	_check(blood.splashes == s0 + 1 and blood.floor_spawned == f0 + 1 and _newest_splash(world) != null and _newest_splash(world).drop_count() > 0, "a clean hit splashes and leaves 1 floor drop (level 1)")
	var crit: Resource = light.duplicate()
	crit.force_crit = true
	f0 = blood.floor_spawned
	await _ticks(20)
	enemy.receive_hit(hero, crit)
	_check(blood.floor_spawned == f0 + 2, "a crit raises the level: 2 floor drops")
	# Block: no blood.
	await _ticks(25)
	enemy._set_state(F.State.BLOCK)
	enemy._set_forward(hero.global_position - enemy.global_position)
	s0 = blood.splashes
	f0 = blood.floor_spawned
	enemy.receive_hit(hero, light)
	var blocked: bool = enemy.state == F.State.BLOCKSTUN
	if mutation == "block":
		blood._on_hit(hero, enemy, light, false)
	_check(blocked and blood.splashes == s0 and blood.floor_spawned == f0, "a blocked hit draws no blood (blockstun %s)" % blocked)
	await _ticks(30)
	# DoT ticks: no blood.
	s0 = blood.splashes
	var hp0: float = enemy.hp
	enemy.dot_frames = 60
	enemy.dot_damage = 6.0
	await _ticks(62)
	_check(enemy.hp < hp0 and blood.splashes == s0, "DoT ticks hurt without blood")
	# Frozen (TIME STOP): a hit still bleeds.
	await _until(func() -> bool: return enemy.is_actionable(), 120)
	enemy.freeze(30)
	s0 = blood.splashes
	enemy.receive_hit(hero, light)
	_check(blood.splashes == s0 + 1, "a hit on a frozen fighter bleeds")
	await _ticks(40)
	# Modes.
	content.set_blood_mode("off")
	if mutation == "mode":
		content.set_blood_mode("full")
	s0 = blood.splashes
	f0 = blood.floor_spawned
	var i0: int = blood.ink_bursts
	enemy.receive_hit(hero, light)
	_check(blood.splashes == s0 and blood.floor_spawned == f0 and blood.ink_bursts == i0, "Off: no blood, no ink, only the existing sparks")
	await _ticks(20)
	content.set_blood_mode("ink")
	if mutation == "ink":
		content.set_blood_mode("full")
	s0 = blood.splashes
	f0 = blood.floor_spawned
	i0 = blood.ink_bursts
	enemy.receive_hit(hero, light)
	_check(blood.ink_bursts == i0 + 1 and blood.splashes == s0 and blood.floor_spawned == f0, "Ink: ink strokes instead of drops, nothing on the floor")
	await _ticks(20)
	content.set_blood_mode("muted")
	s0 = blood.splashes
	enemy.receive_hit(hero, light)
	var muted: Node = _newest_splash(world)
	var longest: float = 0.0
	var fill := Color()
	if muted != null:
		for item: Dictionary in muted._items:
			longest = maxf(longest, float(item.life))
		fill = (muted._items[0].mat as ShaderMaterial).get_shader_parameter("fill")
	_check(blood.splashes == s0 + 1 and fill.get_luminance() < Color("A3243B").get_luminance() and longest <= 0.55 * 0.5 + 0.0001, "Muted: darker (%s) and shorter (%.2f s ≤ half of 0.55 s)" % [fill.to_html(false), longest])
	await _ticks(20)
	# Own RNG in every mode: BloodFx's hit handler alone (no HitSpark, which draws the shared RNG by design) leaves
	# FxShader.rng() and the global RNG untouched, and still draws its blood (so the check is not vacuous).
	var own_rng: RandomNumberGenerator = blood.rng
	if mutation == "rng":
		blood.rng = FxS.call("rng")   # blood sharing the presentation RNG
	for m: String in ["full", "muted", "ink", "off"]:
		content.set_blood_mode(m)
		var shared: RandomNumberGenerator = FxS.call("rng")
		var before_state: int = shared.state
		var drawn: int = blood.splashes + blood.ink_bursts
		seed(4242)
		blood._on_hit(hero, enemy, light, false)
		var global_after: int = randi()
		seed(4242)
		var global_moved: bool = global_after != randi()
		var drew: bool = (blood.splashes + blood.ink_bursts) == drawn + (0 if m == "off" else 1)
		_check(shared.state == before_state and not global_moved and drew, "%s: a hit leaves FxShader.rng() and the global RNG where they were (shared moved %s, global moved %s, drew %s)" % [m, shared.state != before_state, global_moved, drew])
		await _ticks(10)
	blood.rng = own_rng
	content.set_blood_mode("full")
	await _ticks(20)
	# Quality: Medium ½ and Low ¼ of High's drops (T6 table).
	var graphics: Node = root.get_node("GraphicsSettings")
	var old_profile: String = graphics.get_profile()
	var counts := {}
	var heavy95: Resource = light.duplicate()   # level 3 (≥ 90) without a launcher, so the enemy stays grounded
	heavy95.damage = 95.0
	for profile: String in ["high", "medium", "low"]:
		graphics.set_profile(profile)
		await _ticks(25)
		enemy.receive_hit(hero, heavy95)
		var splash: Node = _newest_splash(world)
		counts[profile] = splash.drop_count() if splash != null else -1
		await _until(func() -> bool: return enemy.is_actionable(), 200)
	graphics.set_profile(old_profile)
	var high: int = int(counts.high)
	_check(high > 0 and int(counts.medium) == maxi(1, roundi(high * 0.5)) and int(counts.low) == maxi(1, roundi(high * 0.25)), "drops by quality: High %d, Medium ½, Low ¼ (%s)" % [high, counts])
	# Floor budget at High.
	for i: int in 20:
		await _until(func() -> bool: return enemy.state != F.State.LAUNCHED and enemy.state != F.State.KO, 120)
		enemy.receive_hit(hero, light)
		await _ticks(3)
	_check(blood.floor_items.size() == FLOOR_LIMIT_HIGH, "High keeps at most 16 floor drops (%d)" % blood.floor_items.size())
	# Lens rule (T6 § Proximity dither): nothing new right at the lens or beside a faded hero.
	var camera: Camera3D = root.get_viewport().get_camera_3d()
	var at_lens := camera.global_position - camera.global_basis.z * 0.5
	_check(not blood._may_spawn(enemy, at_lens) and blood._may_spawn(enemy, enemy.global_position + Vector3.UP), "no new blood 0.5 m from the lens; the enemy's chest is fine")
	var hero_material: ShaderMaterial = hero.animator.materials[0]
	var old_visibility: Variant = hero_material.get_shader_parameter("camera_visibility")
	hero_material.set_shader_parameter("camera_visibility", 0.3)
	_check(not blood._may_spawn(hero, hero.global_position + Vector3.UP), "no new blood beside a hero faded to 0.3")
	hero_material.set_shader_parameter("camera_visibility", old_visibility if old_visibility != null else 1.0)
	# Round 1 KO by a real hit: not decisive, no puddle.
	await _until(func() -> bool: return enemy.is_actionable(), 200)
	enemy.hp = 1.0
	enemy.receive_hit(hero, light)
	# GDD 02 / ADR-024 п. 4: the puddle belongs to the decisive KO — a blow that wins the match while the round is still
	# fought. Round 1 is now decided (ROUND_END, the hero one win from the match): a late lethal blow on the body pools
	# nothing (T4 audit 2026-10-07, proposal 7).
	var late_phase: int = flow.phase
	var late_wins: int = int(flow.wins.get(hero.player_index, 0))
	if mutation == "late":
		flow.phase = MF.Phase.FIGHT   # the guard sees a round still being fought
	blood._on_hit(hero, enemy, light, false)
	flow.phase = late_phase
	_check(late_phase == MF.Phase.ROUND_END and late_wins + 1 >= state.rounds_to_win and enemy.hp <= 0.0 and blood._puddle_frames < 0,
		"a late lethal blow after round 1 is decided pools nothing (phase %d, hero wins %d, puddle scheduled %s)" % [late_phase, late_wins, blood._puddle_frames >= 0])
	if mutation == "late":
		blood.reset_match()   # keep the negative to its own subject
	await _ticks(80)
	_check(blood.puddle_size() == 0.0, "a round-1 KO leaves no puddle")
	await _until(func() -> bool: return flow.round_no == 2 and flow.phase == MF.Phase.FIGHT, 400)
	await _ticks(5)
	enemy.global_position = Vector3(1.0, 0.02, 0)
	hero.global_position = Vector3(-1.0, 0.02, 0)
	await _ticks(2)
	enemy.hp = 1.0
	f0 = blood.floor_spawned
	enemy.receive_hit(hero, light)
	var decisive_floor: int = blood.floor_spawned - f0
	var sizes: Array[float] = []
	for tick: int in 120:
		await _ticks(1)
		var size: float = blood.puddle_size() if is_instance_valid(blood) else 0.0
		if size > 0.0 and (sizes.is_empty() or not is_equal_approx(sizes[-1], size)):
			sizes.append(size)
	_check(decisive_floor == 2, "the decisive blow bleeds one level more (2 floor drops for a light, got %d)" % decisive_floor)
	_check(sizes.size() == PUDDLE_STEPS and not sizes.is_empty() and absf(sizes[-1] - PUDDLE_FULL) < 0.05, "the decisive KO pools under the body in %d steps to ≈ 1.2 m (%s)" % [PUDDLE_STEPS, sizes])
	print("BLOOD_CONTENT_INFO pocket: drops by quality %s, floor %d of %d spawned, puddle steps %s, decisive floor drops %d" % [counts, blood.floor_items.size() if is_instance_valid(blood) else -1, blood.floor_spawned if is_instance_valid(blood) else -1, sizes, decisive_floor])
	await _until(func() -> bool: return not lethal.active, 300)
	await _ticks(45)
	_check(not lethal.active and lethal.blood == null and _blood_nodes(world) == 0, "the pocket closes and takes every drop, stain and pool with it (%d left)" % _blood_nodes(world))
	world.queue_free()
	await _ticks(3)


# --- T. blood never changes the fight ----------------------------------------------------------------------
func _trace(hero_id: String, mode: String, profile: String) -> Array:
	var label := "%s %s/%s" % [hero_id, mode, profile]
	content.set_blood_mode(mode)
	var graphics: Node = root.get_node("GraphicsSettings")
	var old_profile: String = graphics.get_profile()
	graphics.set_profile(profile)
	state.p1_character = hero_id
	var world: Node = _city()
	await _ticks(20)
	var hero: Node = world.player
	hero.restart_at(SAFE_POINT)
	await _ticks(10)
	var opened: bool = world.lethal.request_open()
	_check(opened and world.lethal.notice == null and hero.data.id == hero_id, "%s: a seen card never shows again; the fight opens at once (hero %s)" % [label, hero.data.id])
	if not opened:
		world.queue_free()
		graphics.set_profile(old_profile)
		await _ticks(3)
		return []
	var enemy: Node = world.lethal.enemy
	var flow: Node = world.lethal.flow
	var brain: Node = enemy._brain
	if mutation == "state" and hero_id == "choko" and mode == "full":
		for f: Node in [hero, enemy]:
			f.hit_landed.connect(func(_a: Node, victim: Node, _m: Resource, blocked: bool) -> void:
				if not blocked:
					victim.hp -= 1.0)
	if mutation == "rng_state" and mode == "ink":
		# Blood that draws one number from the hero's own fight RNG: hp, states and positions stay the same (that RNG
		# only picks weak marks), so only the RNG columns of the trace can see it.
		for f: Node in [hero, enemy]:
			f.hit_landed.connect(func(_a: Node, _v: Node, _m: Resource, blocked: bool) -> void:
				if not blocked:
					hero._rng.randi())
	var out: Array = []
	for tick: int in TRACE_TICKS:
		if tick % 23 == 5:
			router.v_press(1, "light")
		if tick % 61 == 7:
			router.v_press(1, "heavy")
		await _ticks(1)
		out.append([snappedf(hero.hp, 0.001), hero.state, snappedf(hero.global_position.x, 0.0001), snappedf(hero.global_position.z, 0.0001), hero.move_frame, hero.hitstop_frames,
			snappedf(enemy.hp, 0.001), enemy.state, snappedf(enemy.global_position.x, 0.0001), snappedf(enemy.global_position.z, 0.0001), enemy.move_frame, enemy.hitstop_frames, flow.phase, flow.round_no,
			hero._rng.state, enemy._rng.state, brain._rng.state if brain != null else -1])
	var blood: Node = world.lethal.blood
	out.append(["blood", blood.splashes, blood.ink_bursts])
	world.lethal.close("abort")
	world.queue_free()
	graphics.set_profile(old_profile)
	await _ticks(5)
	return out


func _traces() -> void:
	if not content.notice_seen():
		content.mark_notice_seen()   # a scoped negative run skips part L, where the card is confirmed for real
	var old_hero: String = state.p1_character
	var runs: Array = []
	for row: Array in TRACES:
		runs.append(await _trace(row[0], row[1], row[2]))
	state.p1_character = old_hero
	content.set_blood_mode("full")
	var refs: Dictionary = {}   # hero → its Off/High trace (TRACES lists each reference before that hero's variants)
	var summary: PackedStringArray = []
	for i: int in TRACES.size():
		var hero_id: String = TRACES[i][0]
		var mode: String = TRACES[i][1]
		var label := "%s %s/%s" % TRACES[i]
		var run: Array = runs[i]
		if run.is_empty():
			_check(false, "%s: the trace ran" % label)
			continue
		var counts: Array = run.pop_back()
		var splashes: int = int(counts[1])
		var inks: int = int(counts[2])
		var shows: bool
		match mode:
			"off":
				shows = splashes == 0 and inks == 0
			"ink":
				shows = inks > 0 and splashes == 0
			_:
				shows = splashes > 0 and inks == 0
		_check(shows, "%s: the traced fight shows its own blood (splashes %d, ink %d)" % [label, splashes, inks])
		if mode == "off" and TRACES[i][2] == "high":
			refs[hero_id] = run
			summary.append("%s reference, %d ticks" % [label, run.size()])
			continue
		if not refs.has(hero_id):
			_check(false, "%s: an Off/High reference of the same hero ran" % label)
			continue
		var ref: Array = refs[hero_id]
		var first := -1
		var column := -1
		for k: int in mini(run.size(), ref.size()):
			if run[k] != ref[k]:
				first = k
				for c: int in run[k].size():
					if run[k][c] != ref[k][c]:
						column = c
						break
				break
		summary.append("%s %d splashes %d ink, first difference %d (column %d)" % [label, splashes, inks, first, column])
		_check(first == -1 and run.size() == TRACE_TICKS and ref.size() == TRACE_TICKS, "%s: hp, states, positions, frames, hitstop, round and the fighters'/CPU RNG states equal %s off/high over %d ticks (first difference: %d, column %d)" % [label, hero_id, TRACE_TICKS, first, column])
	print("BLOOD_CONTENT_INFO trace: %d ticks each; %s" % [TRACE_TICKS, "; ".join(summary)])
