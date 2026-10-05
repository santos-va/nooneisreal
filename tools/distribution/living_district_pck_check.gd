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
	for path: String in ["res://scripts/fighter/AuthoredHookMotion.gd", "res://scripts/npc/NpcConversationContext.gd", "res://scripts/npc/NpcLocalConversation.gd", "res://scripts/npc/NpcChatter.gd", "res://scripts/world/CityCameraProximity.gd", "res://scripts/world/CityConversationFrame.gd", "res://shaders/camera_proximity.gdshaderinc"]:
		check(ResourceLoader.exists(path), "Packed resource exists: " + path)
		if ResourceLoader.exists(path):
			check(load(path) != null, "Packed resource loads: " + path)
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
	var chatter: Script = load("res://scripts/npc/NpcChatter.gd")
	var timbres: Dictionary = {}
	for seed_value: int in 3:
		var stream: AudioStreamWAV = chatter.stream_for(seed_value, "talk")
		check(stream != null and stream.data.size() > 1000 and stream.get_length() > 0.2, "Packed chatter synthesizes nonempty PCM")
		check(stream == chatter.stream_for(seed_value, "talk"), "Packed chatter stream is cached")
		timbres[stream.data.hex_encode().sha256_text()] = true
	check(timbres.size() == 3, "Three distinct packed chatter timbres")
	# A real hero forces both imported animation libraries and the hook sampler to load.
	var state: Node = root.get_node("GameState")
	state.skeletal_rig = true
	state.free_move = true
	var fighter: Node3D = load("res://scenes/fighter/Fighter.tscn").instantiate()
	fighter.data = load("res://data/characters/skea.tres")
	stage.add_child(fighter)
	fighter.set_physics_process(false)
	fighter.position = Vector3(-4.0,0,0)
	check(fighter.skeletal != null, "Packed authored hero rig builds")
	if fighter.skeletal != null:
		var hook: RefCounted = fighter.skeletal.authored_hook
		for clip: String in ["Interact", "Climb_Enter", "Climb_Idle", "Climb_Up", "OverhandThrow"]:
			check(hook._cache.has(clip) and not hook._cache[clip].is_empty(), "Imported hook source sampled from package: " + clip)
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
