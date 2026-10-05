extends SceneTree
## Native package-only verification. Never creates autoloads or mounts checkout resources.
## Run from an empty directory containing only project.godot:
## godot --path . --main-pack /absolute/game.pck --rendering-method gl_compatibility
##   --script /absolute/tools/distribution/living_district_pck_check.gd --
##   --verifier-dir=/absolute/empty --revision=<40 hex> --version=0.5.0
##   --content-sha=<district.json SHA256> [--capture=/absolute/result.png]
## Use a fresh OS user-data profile. Caller must reject ERROR/SCRIPT ERROR/SHADER ERROR
## in the raw log, require exit 0 and PCK_LIVING_COMPLETE failures=0.
var checks: int = 0
var failures: int = 0
var arguments: Dictionary = {}

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		var pair := argument.trim_prefix("--").split("=", true, 1)
		if pair.size() == 2:
			arguments[pair[0]] = pair[1]
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PCK_LIVING: " + label)

func meshes(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		result.append(node)
	for child: Node in node.get_children():
		result.append_array(meshes(child))
	return result

func run() -> void:
	var revision: String = arguments.get("revision", "")
	var version: String = arguments.get("version", "")
	var content_sha: String = arguments.get("content-sha", "")
	var verifier: String = arguments.get("verifier-dir", "")
	var hex := RegEx.new()
	hex.compile("^[0-9a-f]{40}$")
	check(hex.search(revision) != null and not version.is_empty() and content_sha.length() == 64, "Explicit revision, version and content SHA required")
	check(verifier.is_absolute_path() and DirAccess.dir_exists_absolute(verifier), "Explicit existing empty verifier directory required")
	if not verifier.is_empty() and DirAccess.dir_exists_absolute(verifier):
		var directory := DirAccess.open(verifier)
		directory.list_dir_begin()
		var entry: String = directory.get_next()
		while not entry.is_empty():
			check(entry == "project.godot" and not directory.current_is_dir(), "Verifier must contain only project.godot: " + entry)
			entry = directory.get_next()
		directory.list_dir_end()
		check(DirAccess.open(".").get_current_dir().simplify_path() == verifier.simplify_path(), "Process cwd is the empty verifier, not checkout")
	check(DisplayServer.get_name() != "headless", "Native pixels required")
	check(RenderingServer.get_current_rendering_method() == "gl_compatibility", "Compatibility shader compilation required")
	check(str(ProjectSettings.get_setting("application/config/version", "")) == version, "Version read from packed project")
	var marker := ConfigFile.new()
	check(marker.load("res://build_info.cfg") == OK, "Build marker is packed")
	check(str(marker.get_value("build", "revision", "")) == revision, "Packed revision matches exact source commit")
	check(FileAccess.file_exists("res://data/city/district.json"), "District JSON is packed")
	check(FileAccess.get_sha256("res://data/city/district.json") == content_sha, "Packed district JSON matches source hash")
	var document: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/city/district.json"))
	check(document is Dictionary and document.get("quests", []).size() == 6, "All six quests parse from packed JSON")
	var audio_manifest := ConfigFile.new()
	check(audio_manifest.load("res://data/audio/soundtracks.cfg") == OK and audio_manifest.has_section("tracks"), "Packed audio manifest parses")
	for key: String in audio_manifest.get_section_keys("tracks") if audio_manifest.has_section("tracks") else PackedStringArray():
		var path: String = str(audio_manifest.get_value("tracks", key, ""))
		if not path.is_empty():
			check(ResourceLoader.exists(path) and load(path) is AudioStream, "Configured audio stream loads: " + key)
	for singleton: String in ["GameState", "InputRouter", "Sfx", "Music"]:
		check(root.has_node(singleton), "Autoload supplied implicitly by packed project: " + singleton)
	for path: String in ["res://scripts/fighter/AuthoredHookMotion.gd", "res://scripts/fighter/FighterMotionSignals.gd", "res://scripts/fighter/HeroBodyMotion.gd", "res://scripts/fighter/HeroGroundContact.gd", "res://scripts/npc/NpcConversationContext.gd", "res://scripts/npc/NpcLocalConversation.gd", "res://scripts/npc/NpcChatter.gd", "res://scripts/world/CityCameraProximity.gd", "res://scripts/world/CityConversationFrame.gd", "res://shaders/camera_proximity.gdshaderinc"]:
		check(ResourceLoader.exists(path), "Packed resource exists: " + path)
		if ResourceLoader.exists(path):
			check(load(path) != null, "Packed resource loads: " + path)
	for path: String in ["res://scripts/core/GearSurface.gd", "res://scripts/fighter/HeroGearPresentation.gd", "res://scripts/fighter/HeroGarmentMask.gd", "res://scripts/npc/NpcClothMotion.gd", "res://shaders/gear_surface.gdshader", "res://shaders/hero_garment.gdshader", "res://shaders/grimoire_sigil.gdshader", "res://assets/characters/equipment/cloth_weave.svg"]:
		check(ResourceLoader.exists(path), "Packed equipment resource exists: " + path)
		if ResourceLoader.exists(path):
			check(load(path) != null, "Packed equipment resource loads: " + path)
	check(not FileAccess.file_exists("user://npc_conversation.cfg"), "Fresh profile required to verify default OFF without changing user settings")
	if failures > 0:
		finish(version, revision)
		return
	# Guarded by the clean-profile/default assertion: this must never start HTTP.
	var local: Node = load("res://scripts/npc/NpcLocalConversation.gd").new()
	root.add_child(local)
	check(not local.enabled and not local.busy, "Local model is OFF by default in package")
	if not local.enabled:
		var before: int = local.last_request_ms
		local.generate({"resident": "package_probe", "hero": "skea"}, "Авторська репліка")
		check(not local.busy and local.last_request_ms == before and local.pending_key.is_empty(), "Disabled generation never issues a request")
		check(local.request.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED and not local.completion_callback.is_valid(), "Disabled HTTP client stays disconnected")
	local.queue_free()
	var context: RefCounted = load("res://scripts/npc/NpcConversationContext.gd").new()
	var line: String = context.reply({"hero": "skea", "resident": "probe", "topic": "greeting", "meetings": 1, "trust": 0, "quests": {}}, 0)
	check(not line.is_empty() and line.contains("Skea"), "Packed authored context generates an immediate fallback")
	var stage := Node3D.new()
	root.add_child(stage)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(0, 3.0, 11)
	camera.look_at(Vector3(0,1,0))
	camera.make_current()
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35,-25,0)
	stage.add_child(light)
	var appearance: Script = load("res://scripts/npc/NpcAppearance.gd")
	for seed_value: int in 3:
		var visual: Node3D = appearance.build({"appearance_seed": seed_value})
		stage.add_child(visual)
		visual.position = Vector3(float(seed_value - 1) * 1.8, 0, 0)
		var expected: String = ["fox", "moth", "stone"][seed_value]
		check(visual.get_meta("appearance").phenotype == expected, "Packed phenotype builds: " + expected)
		var parts := meshes(visual)
		var triangles: int = 0
		for part: MeshInstance3D in parts:
			triangles += part.mesh.get_faces().size() / 3
		check(parts.size() > 0 and parts.size() <= 48 and triangles <= 8000, "Built phenotype meets mesh budget")
		var duplicate: Node3D = appearance.build({"appearance_seed": seed_value})
		var repeated := meshes(duplicate)
		check(parts.size() == repeated.size() and parts[0].mesh == repeated[0].mesh and parts[0].material_override == repeated[0].material_override, "Packed phenotype reuses mesh/material cache")
		duplicate.free()
	for seed_value: int in [40, 41, 42]:
		var worker: Node3D = appearance.build({"appearance_seed": seed_value})
		stage.add_child(worker)
		check_npc_cloth(worker)
		worker.free()
	var chatter: Script = load("res://scripts/npc/NpcChatter.gd")
	var timbres: Dictionary = {}
	for seed_value: int in 3:
		var stream: AudioStreamWAV = chatter.stream_for(seed_value, "talk")
		check(stream != null and stream.data.size() > 1000 and stream.get_length() > 0.2, "Packed chatter synthesizes nonempty PCM")
		check(stream == chatter.stream_for(seed_value, "talk"), "Packed chatter stream is cached")
		timbres[stream.data.hex_encode().sha256_text()] = true
	check(timbres.size() == 3, "Three distinct packed chatter timbres")
	# Both real heroes initialize the packed motion helpers on actual solid support.
	var state: Node = root.get_node("GameState")
	state.skeletal_rig = true
	state.free_move = true
	state.water = null
	check(FileAccess.file_exists("res://data/animation/foot_contacts.json"), "Packed source-contact profiles exist")
	var profiles: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/animation/foot_contacts.json"))
	check(profiles is Dictionary and not profiles.get("clips", {}).is_empty(), "Packed source-contact profiles parse")
	var ground := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(20,0.2,8)
	collision.shape = shape
	ground.add_child(collision)
	stage.add_child(ground)
	ground.position.y = -0.1
	for hero: String in ["choko", "skea"]:
		var fighter: Node3D = load("res://scenes/fighter/Fighter.tscn").instantiate()
		fighter.set_script(load("res://scripts/world/CityFighter.gd"))
		fighter.data = load("res://data/characters/" + hero + ".tres")
		stage.add_child(fighter)
		fighter.set_physics_process(false)
		fighter.restart_at(Vector3(-4.0 if hero == "choko" else 4.0,0,0))
		check(fighter.skeletal != null, "Packed authored hero rig builds: " + hero)
		if fighter.skeletal == null:
			continue
		fighter.skeletal.set_physics_process(false)
		var hook: RefCounted = fighter.skeletal.authored_hook
		for clip: String in ["Interact", "Climb_Enter", "Climb_Idle", "Climb_Up", "OverhandThrow"]:
			check(hook._cache.has(clip) and not hook._cache[clip].is_empty(), "Imported hook source sampled from package: " + hero + " " + clip)
		for frame: int in 12:
			await physics_frame
			fighter._ground_physics(1.0/60.0,0.0)
			fighter.animator.tick(1.0/60.0,fighter,false)
			fighter.skeletal._physics_process(1.0/60.0)
			fighter.skeletal.retarget()
		check(fighter.on_ground() and fighter.skeletal.motion_signals.grounded, "Packed motion snapshot sees real support: " + hero)
		check(fighter.skeletal.motion_signals.distance < 0.001, "Stationary packed hero does not accumulate strides: " + hero)
		check(fighter.skeletal.body_motion.serial >= 12 and is_finite(fighter.skeletal.body_motion.gaze_pitch), "Packed anatomical body/gaze pass runs: " + hero)
		check(not fighter.skeletal.ground_contact.samples.is_empty() and fighter.skeletal.ground_contact.query_count > 0, "Packed skinned soles query support: " + hero)
		check_hero_equipment(fighter, hero)
		check_camera_isolation(fighter, camera, stage)
	for index: int in 4:
		var path: String = ["toon", "outline", "sword_dissolve", "camera_cloth"][index]
		var shader: Shader = load("res://shaders/" + path + ".gdshader")
		check(shader != null, "Packed camera-dependent shader loads: " + path)
		var instance := MeshInstance3D.new()
		instance.mesh = BoxMesh.new()
		var material := ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("camera_visibility", 0.5)
		instance.material_override = material
		instance.position = Vector3(float(index) * 1.6 - 2.4, 0.5, 2.5)
		stage.add_child(instance)
	for frame: int in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	var pixels := root.get_texture().get_image()
	check(not pixels.is_empty(), "Native package frame is rendered")
	if arguments.has("capture"):
		check(pixels.save_png(arguments.capture) == OK, "Native package screenshot saved")
	stage.queue_free()
	await process_frame
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		var node := root.get_node_or_null(singleton)
		if node != null:
			node.queue_free()
	await create_timer(0.2).timeout
	finish(version, revision)

func finish(version: String, revision: String) -> void:
	print("PCK_LIVING_COMPLETE checks=%d failures=%d version=%s revision=%s renderer=%s" % [checks, failures, version, revision, RenderingServer.get_current_rendering_method()])
	quit(1 if failures > 0 else 0)

## Additional equipment assertions supplement every pre-existing package assertion.
func check_npc_cloth(visual: Node3D) -> void:
	check(visual.clothing != null and not visual.clothing.parts.is_empty(), "Packed NPC owns pinned cloth")
	if visual.clothing == null or visual.clothing.parts.is_empty():
		return
	var before: Transform3D = visual.transform
	var identity: Dictionary = visual.get_meta("appearance").duplicate(true)
	visual.reset_clothing()
	var peak: float = 0.0
	var bounded: bool = true
	for tick: int in 24:
		visual.position.x += 0.008 if tick < 12 else 0.0
		visual.rotation.y += 0.02 if tick < 12 else 0.0
		visual.step_clothing(1.0/60.0)
		for part: Dictionary in visual.clothing.parts:
			peak = maxf(peak, float(part.angle))
			var limit: float = 0.10 if part.kind == "leather" else 0.24
			var pose: Transform3D = part.node.transform
			var rest: Transform3D = part.rest
			bounded = bounded and is_finite(part.angle) and part.angle >= 0.0 and part.angle <= limit + 0.000001 and pose.origin.distance_to(rest.origin) <= 0.001 and pose.basis.get_scale().is_equal_approx(rest.basis.get_scale())
	check(peak > 0.001 and bounded, "Packed NPC cloth advances without stretch or detached pins")
	visual.transform = before
	visual.reset_clothing()
	var reset_ok: bool = true
	for part: Dictionary in visual.clothing.parts:
		reset_ok = reset_ok and part.node.transform == part.rest and part.angle == 0.0 and part.speed == 0.0
	check(reset_ok and visual.get_meta("appearance") == identity, "Packed cloth reset restores rest and preserves identity")

func check_hero_equipment(fighter: Node3D, hero: String) -> void:
	var rig: Node3D = fighter.skeletal
	var gear: Node3D = rig.gear
	check(gear != null and not gear.materials.is_empty() and gear.serial >= 12, "Packed actual hero equipment runs: " + hero)
	if gear == null:
		return
	var mask: RefCounted = gear.garment
	check(mask.original_mesh != null and mask.selected_vertices > 0 and mask.protected_vertices > 0 and mask.selected_vertices + mask.protected_vertices == mask.total_vertices, "Packed clothing mask includes cloth and protects anatomy: " + hero)
	var current: Mesh = rig.hero_mesh.mesh
	var source: Mesh = mask.original_mesh
	if source == null:
		return
	check(current != source and rig.hero_mesh.material_override.shader.resource_path == "res://shaders/hero_garment.gdshader", "Packed masked hero shader is active: " + hero)
	var unchanged: bool = current.get_surface_count() == source.get_surface_count()
	var lods_ok: bool = unchanged
	var lod_count: int = 0
	var selected: int = 0
	var protected_count: int = 0
	for surface: int in mini(current.get_surface_count(), source.get_surface_count()):
		var original: Array = source.surface_get_arrays(surface)
		var actual: Array = current.surface_get_arrays(surface)
		for slot: int in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_BONES, Mesh.ARRAY_WEIGHTS, Mesh.ARRAY_INDEX]:
			unchanged = unchanged and original[slot] == actual[slot]
		# Imported compressed normal/tangent decode-reencode has bounded rounding.
		for slot: int in [Mesh.ARRAY_NORMAL, Mesh.ARRAY_TANGENT]:
			unchanged = unchanged and original[slot].size() == actual[slot].size()
			for item: int in mini(original[slot].size(), actual[slot].size()):
				if slot == Mesh.ARRAY_NORMAL:
					var difference: Vector3 = (original[slot][item] - actual[slot][item]).abs()
					unchanged = unchanged and maxf(difference.x, maxf(difference.y, difference.z)) <= 0.0002
				else:
					unchanged = unchanged and absf(original[slot][item] - actual[slot][item]) <= 0.0002
		for color: Color in actual[Mesh.ARRAY_COLOR]:
			selected += 1 if color.g == 1.0 else 0
			protected_count += 1 if color.g == 0.0 else 0
		var old_lods: Array = RenderingServer.mesh_get_surface(source.get_rid(), surface).get("lods", [])
		var new_lods: Array = RenderingServer.mesh_get_surface(current.get_rid(), surface).get("lods", [])
		lod_count += old_lods.size()
		lods_ok = lods_ok and old_lods == new_lods
	check(unchanged and selected == mask.selected_vertices and protected_count == mask.protected_vertices, "Packed mask preserves actual geometry, UV and skin weights: " + hero)
	check(lods_ok and lod_count == 3, "Packed hero retains all three imported LODs: " + hero)
	var tails_ok: bool = gear._tails.size() == 2
	for tail: Dictionary in gear._tails:
		tails_ok = tails_ok and not tail.skin.is_empty() and tail.anchor.global_basis.determinant() > 0.0 and tail.segments.size() == 3 and tail.anchor.global_position.distance_to(gear.pin_transform(tail).origin) <= 0.001
	check(tails_ok, "Packed cloth tails have three segments and actual skin pins: " + hero)
	if hero != "choko":
		check(rig.sword == null, "Packed Skea has no Choko sword")
		var sigils: Array[Node] = gear.find_children("GrimoireEightSigil", "MeshInstance3D", true, false)
		check(sigils.size() == 1, "Packed Skea has one continuous grimoire infinity emblem")
		if sigils.size() == 1:
			var sigil: MeshInstance3D = sigils[0]
			var bounds: AABB = sigil.mesh.get_aabb()
			check(sigil.mesh is ArrayMesh and bounds.size.x > bounds.size.y and bounds.size.y > 0.05 and sigil.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV].size() > 0, "Packed infinity emblem has horizontal UV-mapped ribbon geometry")
			var material: ShaderMaterial = sigil.material_override
			check(material != null and material.shader.resource_path == "res://shaders/grimoire_sigil.gdshader" and material.get_shader_parameter("albedo") == Color("9e4cf2") and material in gear.materials and material in fighter.animator.materials, "Packed infinity uses registered canonical purple sigil material")
			var uniforms: Dictionary = {}
			if material != null:
				for uniform: Dictionary in material.shader.get_shader_uniform_list():
					uniforms[uniform.name] = true
			check(uniforms.has("hit_flash") and uniforms.has("desat") and uniforms.has("camera_visibility"), "Packed sigil supports combat and camera material controls")
		return
	var sword: Node3D = rig.sword
	check(sword != null and sword._blade_forms.size() == 3, "Packed Choko builds three sword forms")
	if sword == null:
		return
	var thin_uv: bool = true
	for form: Mesh in sword._blade_forms:
		var bounds: AABB = form.get_aabb()
		var arrays: Array = form.surface_get_arrays(0)
		var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		thin_uv = thin_uv and bounds.size.x > 0.05 and bounds.size.x <= 0.145 and bounds.size.z <= 0.025 and bounds.end.y > 0.9 and uv.size() == arrays[Mesh.ARRAY_VERTEX].size()
		var distinct: Dictionary = {}
		for point: Vector2 in uv:
			thin_uv = thin_uv and point.is_finite()
			distinct[point] = true
		thin_uv = thin_uv and distinct.size() >= 4
	check(thin_uv, "Packed sword blades are thin and have nondegenerate UVs")
	var drawn: bool = fighter.sword_drawn
	fighter.sword_drawn = false
	sword.reset_pose_state()
	var tip: Vector3 = sword.blade.global_transform * Vector3(0, sword.blade.mesh.get_aabb().end.y, 0)
	check(sword.global_transform.is_equal_approx(sword.back_grip()) and tip.y < sword.global_position.y - 0.5, "Packed carried sword uses actual torso socket with tip down")
	fighter.sword_drawn = drawn
	sword.reset_pose_state()

func check_camera_isolation(fighter: Node3D, camera: Camera3D, stage: Node3D) -> void:
	var shared: ShaderMaterial
	for part: MeshInstance3D in meshes(stage):
		if part.material_override is ShaderMaterial and part.material_override.shader.resource_path == "res://shaders/gear_surface.gdshader" and not fighter.is_ancestor_of(part):
			shared = part.material_override
			break
	check(shared != null, "Packed NPC garment supplies shared-material isolation fixture")
	if shared == null or fighter.skeletal.gear == null:
		return
	var original_visibility: Variant = shared.get_shader_parameter("camera_visibility")
	var late := MeshInstance3D.new()
	late.mesh = BoxMesh.new()
	late.material_override = shared
	var proximity: RefCounted = load("res://scripts/world/CityCameraProximity.gd").new()
	proximity.setup(fighter)
	fighter.skeletal.gear.add_child(late)
	var camera_pose: Transform3D = camera.global_transform
	camera.global_position = fighter.global_position + Vector3.UP * 1.2
	proximity.update(camera, 0.5)
	check(late.material_override != shared and float(late.material_override.get_shader_parameter("camera_visibility")) < 0.01 and shared.get_shader_parameter("camera_visibility") == original_visibility, "Packed camera fades late hero gear without fading shared NPC material")
	proximity.reset()
	check(late.material_override == shared and shared.get_shader_parameter("camera_visibility") == original_visibility, "Packed camera reset restores exact shared material pointer")
	camera.global_transform = camera_pose
	late.free()
