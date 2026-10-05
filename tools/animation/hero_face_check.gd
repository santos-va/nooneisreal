extends SceneTree
## Real imported heroes: finite surface controls, authority isolation and stable physical clock.
var Face: Script
var checks: int = 0
var failures: int = 0
var Actor: Script

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("HERO_FACE: " + message)

func authority(f: Node3D) -> Array:
	return [f.transform,f.velocity,f.state,f.hp,f.meter,f.motion_revision,f._rng.state,f.grapple.phase,f.grapple.rope_length,f.sword_hand,f.sword_drawn]

func poses(sk: Skeleton3D) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	for bone: int in sk.get_bone_count():
		result.append(sk.get_bone_pose(bone))
	return result

func run() -> void:
	await process_frame
	Face = load("res://scripts/fighter/HeroFacePresentation.gd")
	Actor = load("res://scripts/fighter/Fighter.gd")
	root.get_node("GameState").skeletal_rig = true
	root.get_node("GameState").free_move = true
	for hero: String in ["choko","skea"]:
		var f = load("res://scenes/fighter/Fighter.tscn").instantiate()
		f.data = load("res://data/characters/"+hero+".tres")
		root.add_child(f)
		f.set_physics_process(false)
		f.skeletal.set_physics_process(false)
		f.state = Actor.State.IDLE
		f.animator.tick(1.0/60.0,f,false)
		f.skeletal._physics_process(1.0/60.0)
		var face = f.skeletal.face_presentation
		check(Face.valid_profile(face.profile),"admitted real face profile "+hero)
		check(face.material == f.skeletal.hero_mesh.material_override,"real hero material controls "+hero)
		var arrays: Array = f.skeletal.hero_mesh.mesh.surface_get_arrays(0)
		var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var feature_counts: Array[int] = [0,0]
		for i: int in uvs.size():
			for eye: int in 2:
				var region: Vector4 = face.profile.eye_left if eye == 0 else face.profile.eye_right
				if (uvs[i]*face.profile.atlas_size).distance_to(Vector2(region.x,region.y)) < maxf(region.z,region.w) and colors[i].r > 0.99:
					feature_counts[eye] += 1
		check(feature_counts[0] >= 3 and feature_counts[1] >= 3,"both actual eye regions have real mesh samples "+hero+str(feature_counts))
		var original: Array = authority(f)
		var bones: Array[Transform3D] = poses(f.skeletal.hero_skeleton)
		face.reset()
		check(face.closure == Vector2.ZERO,"neutral preserves original face")
		var maximum: float = 0.0
		for tick: int in 420:
			face.update(f,1.0/60.0,tick)
			maximum = maxf(maximum,face.closure.x)
			var snapshot: Array = [face.elapsed,face.closure,face.expression,face.blink_count]
			face.update(f,1.0/60.0,tick)
			face.apply()
			check(snapshot == [face.elapsed,face.closure,face.expression,face.blink_count],"same serial does not step face")
			check(face.closure.is_finite() and face.closure.x >= 0.0 and face.closure.x <= 1.0,"finite bounded eyelid aperture")
		check(maximum > 0.96,"actual deterministic full blink "+hero)
		check(original == authority(f),"expression cannot alter gameplay or RNG")
		check(bones == poses(f.skeletal.hero_skeleton),"surface expression does not touch any bone")
		f.state = Actor.State.BLOCK
		face.update(f,1.0/60.0,421)
		check(face.expression == "focus" and (face.closure.x > face.profile.focus_close or is_equal_approx(face.closure.x,face.profile.focus_close)),"real defensive state focuses eyes")
		f.state = Actor.State.HITSTUN
		face.update(f,1.0/60.0,422)
		check(face.expression == "hurt" and face.closure.x > 0.9 and face.mouth_tension > 0.5 and face.brow_tension < 0.0,"hurt overrides focus with eye and mouth tension")
		f.state = Actor.State.KO
		face.update(f,1.0/60.0,423)
		check(face.expression == "ko" and face.closure == Vector2.ONE and face.mouth_tension > 0.9,"KO closes both eyes and relaxes the painted mouth")
		f.frozen_frames = 3
		f.state = Actor.State.IDLE
		var frozen: float = face.elapsed
		face.update(f,1.0/60.0,424)
		check(face.elapsed == frozen and face.expression == "ko","time stop holds existing expression")
		f.frozen_frames = 0
		f.hitstop_frames = 2
		face.update(f,1.0/60.0,425)
		check(face.elapsed == frozen and face.expression == "ko","hitstop holds existing expression")
		f.hitstop_frames = 0
		face.reset()
		check(face.closure == Vector2.ZERO and face.elapsed == 0.0,"reset removes stale KO/blink")
		var invalid: Resource = face.profile.duplicate()
		invalid.upper_left = PackedVector2Array()
		check(not Face.valid_profile(invalid),"missing aperture landmarks fail closed")
		invalid = face.profile.duplicate()
		invalid.upper_left = invalid.upper_left.duplicate()
		invalid.upper_left[2] = Vector2(NAN,0)
		check(not Face.valid_profile(invalid),"nonfinite aperture landmark fails closed")
		invalid = face.profile.duplicate()
		invalid.lower_right = invalid.lower_right.duplicate()
		invalid.lower_right[2] = invalid.upper_right[2]
		check(not Face.valid_profile(invalid),"collapsed aperture fails closed")
		invalid = face.profile.duplicate()
		invalid.upper_left = invalid.upper_left.duplicate()
		invalid.upper_left[1] = invalid.upper_left[3]
		check(not Face.valid_profile(invalid),"folded aperture landmark order fails closed")
		invalid = face.profile.duplicate()
		invalid.eye_left = Vector4(NAN,0,0,0)
		check(not Face.valid_profile(invalid),"NaN eye fails closed")
		invalid = face.profile.duplicate()
		invalid.axis_left = Vector2.ZERO
		check(not Face.valid_profile(invalid),"degenerate UV basis fails closed")
		invalid = face.profile.duplicate()
		invalid.blink_interval = 0.0
		check(not Face.valid_profile(invalid),"invalid clock fails closed")
		invalid = face.profile.duplicate()
		invalid.mouth_left = Vector4(100,100,4,0)
		check(not Face.valid_profile(invalid),"active mouth cannot divide by zero height")
		invalid = face.profile.duplicate()
		invalid.cheek_left = Vector2(INF,0)
		check(not Face.valid_profile(invalid),"nonfinite skin sample fails closed")
		invalid = face.profile.duplicate()
		invalid.mouth_axis_left = Vector2.ZERO
		check(not Face.valid_profile(invalid),"degenerate mouth basis fails closed")
		invalid = face.profile.duplicate()
		invalid.brow_left = Vector4(2048,2048,12,12)
		check(not Face.valid_profile(invalid),"out-of-atlas brow fails closed")
		check(Face.mask_vertex(hero,Vector3.ZERO,Vector2.ZERO,1.0) == 1.0,"continuous head-domain mask; shader bounds actual feature pixels")
		check(Face.mask_vertex(hero,Vector3.ZERO,Vector2(0.3,0.1),0.0) == 0.0,"nonhead anatomy excluded")
		check(Face.mask_vertex("unsupported",Vector3.ZERO,Vector2(0.3,0.1),1.0) == 0.0,"unknown hero stays original")
		var peer = load("res://scenes/fighter/Fighter.tscn").instantiate()
		peer.data = f.data
		root.add_child(peer)
		peer.set_physics_process(false)
		peer.skeletal.set_physics_process(false)
		peer.state = Actor.State.KO
		peer.skeletal.face_presentation.update(peer,1.0/60.0,1)
		check(peer.skeletal.face_presentation.material != face.material,"same-hero instances have independent face materials")
		check(face.material.get_shader_parameter("face_closure") == Vector2.ZERO and peer.skeletal.face_presentation.material.get_shader_parameter("face_closure") == Vector2.ONE,"cached mesh never shares expression state")
		peer.free()
		f.state = Actor.State.KO
		f.skeletal._physics_process(1.0/60.0)
		check(face.expression == "ko","rig drives actual KO face")
		f.reset_for_round(0.0,1)
		f.state = Actor.State.IDLE
		f.skeletal._physics_process(1.0/60.0)
		check(face.expression == "idle" and face.closure == Vector2.ZERO and face.elapsed < 0.02,"round motion revision clears stale face even at same position")
		f.free()
	for singleton: String in ["Sfx","UltMusic"]:
		root.get_node(singleton).queue_free()
	var until: int = Time.get_ticks_msec()+250
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("HERO_FACE_COMPLETE checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
