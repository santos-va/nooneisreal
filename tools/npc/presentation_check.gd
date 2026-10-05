extends SceneTree
const Appearance = preload("res://scripts/npc/NpcAppearance.gd")
const Chatter = preload("res://scripts/npc/NpcChatter.gd")
var checks := 0
var failures := 0
var max_parts := 0
var max_triangles := 0
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)
func _initialize() -> void:
	call_deferred("run")
func meshes(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if node is MeshInstance3D: result.append(node)
	for child in node.get_children(): result.append_array(meshes(child))
	return result
func run() -> void:
	var phenotypes := {}
	for seed_value in 100:
		var d := Appearance.describe(seed_value)
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var legacy := {"height": rng.randf_range(.9,1.12), "width":rng.randf_range(.88,1.2), "outfit":rng.randi_range(0,3), "color":rng.randi_range(0,5), "skin":rng.randi_range(0,4), "hair":rng.randi_range(0,3), "hair_color":rng.randi_range(0,3), "face":rng.randi_range(0,2)}
		for key in legacy: check(d[key] == legacy[key], "Legacy seed draw changed: " + key)
		phenotypes[d.phenotype] = true
		var visual := Appearance.build({"appearance_seed":seed_value})
		visual.set_work(["grocer", "tailor", "workshop"][seed_value % 3], 0)
		var parts := meshes(visual)
		var triangles := 0
		for part in parts:
			var arrays := part.mesh.surface_get_arrays(0)
			triangles += (arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX] != null and arrays[Mesh.ARRAY_INDEX].size() > 0 else arrays[Mesh.ARRAY_VERTEX].size()) / 3
		max_parts = maxi(max_parts, parts.size())
		max_triangles = maxi(max_triangles, triangles)
		check(parts.size() <= 48 and triangles <= 8000, "NPC geometry budget")
		check(visual.interaction_radius() <= .36, "Contact bound")
		if seed_value == 0:
			var duplicate := Appearance.build({"appearance_seed":seed_value,"role":"different"})
			duplicate.set_work("grocer",0)
			var same := meshes(duplicate)
			for i in parts.size(): check(parts[i].mesh == same[i].mesh and parts[i].material_override == same[i].material_override, "Resources not shared")
			for event in ["greet", "listen", "talk", "agree", "goodbye"]:
				visual.set_motion(0, 0)
				visual.presentation_event(event)
				visual.set_motion(0, .4)
				var pose: Vector3 = visual._arms[1].rotation
				visual.set_work("workshop", .4)
				check(visual._arms[1].rotation == pose, "Work clobbers gesture")
				visual.set_motion(0, 2)
				check(visual._arms[0].rotation == Vector3.ZERO and visual._arms[1].rotation == Vector3.ZERO and visual._head.rotation == Vector3.ZERO, "Gesture reset")
			visual.set_motion(0,3)
			visual.presentation_event("greet")
			visual.set_motion(0,3.4)
			var before_interrupt: Vector3 = visual._arms[1].rotation
			visual.presentation_event("listen")
			visual.set_motion(0,3.4)
			check(visual._arms[1].rotation == before_interrupt, "Interrupted gesture starts from displayed pose")
			visual.set_motion(0,3.416)
			check(visual._arms[1].rotation.distance_to(before_interrupt) < .1, "Interrupted gesture blends without one-frame jump")
			duplicate.free()
		visual.free()
	check(phenotypes.size() == 3, "Three phenotypes")
	var audio_hashes := {}
	for seed_value in 3:
		var stream := Chatter.stream_for(seed_value, "talk")
		check(stream == Chatter.stream_for(seed_value, "talk"), "PCM cache")
		check(stream.get_length() > .2 and stream.get_length() < .5, "PCM length")
		var peak := 0
		var sum_square := 0.0
		for i in stream.data.size()/2:
			var sample := stream.data.decode_s16(i*2)
			peak = maxi(peak, absi(sample))
			sum_square += float(sample)*sample
		check(peak > 1000 and peak < 30000, "PCM nonempty/unclipped")
		audio_hashes[stream.data.hex_encode().sha256_text()] = true
		print("NPC_AUDIO timbre=%d samples=%d peak=%d rms=%.2f" % [seed_value, stream.data.size()/2, peak, sqrt(sum_square/(stream.data.size()/2))])
		var out := OS.get_environment("NPC_CAPTURE_DIR")
		if not out.is_empty(): stream.save_to_wav(out.path_join("chatter_%d.wav" % seed_value))
	check(audio_hashes.size() == 3, "Distinct timbres")
	var listener := Node3D.new()
	root.add_child(listener)
	var chatter := Chatter.new()
	root.add_child(chatter)
	chatter.configure(listener)
	check(chatter._voices.size() == 2, "Global two-node pool")
	check(root.get_audio_listener_3d() == chatter._spatial_listener and chatter._spatial_listener.global_position == Vector3(0,1.5,0), "Spatial listener at hero head")
	check(chatter.speak(Vector3.ZERO, 0, "greet", "a"), "First voice admitted")
	chatter._clock += .20
	check(chatter.speak(Vector3.ZERO, 1, "talk", "b"), "Second voice admitted")
	chatter._clock += .20
	check(not chatter.speak(Vector3.ZERO, 2, "talk", "c"), "Third voice refused")
	chatter.release_actor("a")
	check(not chatter._voices[0].playing, "Despawn stops voice")
	check(not chatter.speak(Vector3.ZERO, 0, "talk", "a"), "Resident cooldown")
	check(not chatter.speak(Vector3(9,0,0), 0, "talk", "far"), "Out of range")
	AudioServer.set_bus_mute(0, true)
	chatter._process(.01)
	check(not chatter._voices[1].playing and not chatter.speak(Vector3.ZERO,2,"talk","mute"), "Mute stops and rejects")
	AudioServer.set_bus_mute(0, false)
	chatter._clock += 3
	check(chatter.speak(Vector3.ZERO,0,"talk","range_stop"), "Voice restarts after cooldown")
	listener.position.x = 10
	chatter._process(.01)
	check(not chatter._voices[0].playing, "Walking out of range stops active voice")
	chatter.free()
	check(root.get_audio_listener_3d() == null, "Spatial listener released on scene exit")
	listener.free()
	var prior_listener := AudioListener3D.new()
	root.add_child(prior_listener)
	prior_listener.make_current()
	var target := Node3D.new()
	root.add_child(target)
	var ownership := Chatter.new()
	root.add_child(ownership)
	ownership.configure(target)
	var newer_listener := AudioListener3D.new()
	root.add_child(newer_listener)
	newer_listener.make_current()
	ownership.free()
	check(root.get_audio_listener_3d() == newer_listener, "Exit must not steal newer listener ownership")
	newer_listener.free()
	prior_listener.make_current()
	ownership = Chatter.new()
	root.add_child(ownership)
	ownership.configure(target)
	ownership.free()
	check(root.get_audio_listener_3d() == prior_listener, "Normal exit restores prior listener")
	prior_listener.free()
	target.free()
	print("NPC_PRESENTATION_COMPLETE checks=%d failures=%d max_parts=%d max_triangles=%d" % [checks, failures, max_parts, max_triangles])
	quit(0 if failures == 0 else 1)
