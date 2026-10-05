extends SceneTree
## Actual input + skinned-shoe regression; support windows frozen from raw UAL.
var checks: int = 0
var failures: int = 0
var actor: GDScript
var windows: Dictionary
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("GROUND_CONTACT: " + message)
func point(rig: Skeleton3D, name: String) -> Vector3:
	return rig.global_transform * rig.get_bone_global_pose(rig.find_bone(name)).origin
func phase_contact(clip: String, time: float, side: String) -> bool:
	var key: String = clip.get_file().trim_suffix("_Loop") + "_Loop"
	if not windows.has(key):
		return false
	var profile: Dictionary = windows[key]
	var phase: float = fposmod(time / float(profile.length), 1.0)
	for interval: Array in profile.sides[side].intervals:
		if phase >= float(interval[0]) and phase <= float(interval[1]):
			return true
	return false
func run() -> void:
	await process_frame
	actor = load("res://scripts/fighter/Fighter.gd")
	var helper: GDScript = load("res://scripts/fighter/HeroGroundContact.gd")
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/animation/foot_contacts.json"))
	windows = metadata.clips
	check(helper.validated_profiles(metadata).size() == 18, "all frozen source clips admitted")
	for wrong: Variant in [null, true, 1, "x", [], {"clips":true}, {"clips":{"Walk_Loop":true}}]:
		check(helper.validated_profiles(wrong).is_empty(), "malformed profile rejected without runtime error")
	for wrong: Variant in [null, true, "1", 0, -1, INF, NAN, 31]:
		var bad: Dictionary = metadata.duplicate(true)
		bad.clips.Walk_Loop.length = wrong
		check(helper.validated_profiles(bad).is_empty(), "malformed duration rejected atomically")
	for wrong: Variant in [true, {}, [true], [[0]], [[0,true]], [[-0.1,0.2]], [[0.8,0.2]], [[0,1.1]], [[0,0.5],[0.4,0.8]]]:
		var bad: Dictionary = metadata.duplicate(true)
		bad.clips.Walk_Loop.sides.Left.intervals = wrong
		check(helper.validated_profiles(bad).is_empty(), "malformed phase intervals rejected atomically")
	root.get_node("GameState").skeletal_rig = true
	root.get_node("GameState").free_move = true
	root.get_node("GameState").water = null
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position.y = -0.5
	root.add_child(floor_body)
	var input: Node = root.get_node("InputRouter")
	input.apply_profile("solo", false)
	input.set_view_basis(1, Vector3.FORWARD)
	for hero: String in ["choko", "skea"]:
		var f = load("res://scenes/fighter/Fighter.tscn").instantiate()
		f.set_script(load("res://scripts/world/CityFighter.gd"))
		f.data = load("res://data/characters/%s.tres" % hero)
		root.add_child(f)
		f.set_physics_process(false)
		f.skeletal.set_physics_process(false)
		f.control_locked = false
		f.state = actor.State.IDLE
		f.forward = Vector3.RIGHT
		var sk = f.skeletal
		var rig: Skeleton3D = sk.hero_skeleton
		var contact = sk.ground_contact
		var rest: Dictionary = {}
		for bone: int in rig.get_bone_count():
			rest[bone] = rig.get_bone_rest(bone).origin.length()
		var fixed_points: Dictionary = {"start":[],"turn":[]}
		var groups: Dictionary = {}
		var max_drift: float = 0.0
		var min_sole: float = INF
		var plant_windows: int = 0
		for frame: int in 480:
			await physics_frame
			input.v_set(1, "right", frame >= 60 and frame < 200)
			input.v_set(1, "up", frame >= 200 and frame < 260)
			input.v_set(1, "crouch", frame >= 330 and frame < 390)
			input.v_set(1, "block", frame >= 420 and frame < 450)
			f._physics_process(1.0 / 60.0)
			var authority: Array = [f.transform, f.velocity, f.state, f.hp, f.meter]
			sk._physics_process(1.0 / 60.0)
			check(authority == [f.transform, f.velocity, f.state, f.hp, f.meter], "presentation has no gameplay authority")
			# Immutable baseline source-phase windows: include visible transition slip
			# even if candidate clip selection/metadata changes its own classifier.
			if (hero == "choko" and frame >= 64 and frame <= 69) or (hero == "skea" and frame >= 63 and frame <= 68):
				fixed_points.start.append(point(rig,"LeftToeBase"))
			if hero == "choko" and frame >= 203 and frame <= 206:
				fixed_points.turn.append(point(rig,"RightToeBase"))
			for side: String in ["Left", "Right"]:
				var sole: float = -sk.foot_contact.penetration(side, null)
				min_sole = minf(min_sole, sole)
				check(sole >= -0.005, "%s frame%d %s skinned sole %.6fm" % [hero, frame, side, sole])
				if phase_contact(sk.clip, sk.clip_pos, side):
					var toe: Vector3 = point(rig, side + "ToeBase")
					if not groups.has(side):
						groups[side] = {"points":[], "clip":sk.clip}
					groups[side].points.append(toe)
				else:
					if groups.has(side) and groups[side].points.size() >= 4:
						plant_windows += 1
						var points: Array = groups[side].points
						for a: Vector3 in points:
							for b: Vector3 in points:
								max_drift = maxf(max_drift, Vector2(a.x-b.x,a.z-b.z).length())
					groups.erase(side)
			if frame % 30 == 0:
				for side: String in ["Left","Right"]:
					var projected: float = contact._sole_clearance(side,contact._poses(),{"normal":Vector3.UP,"point":Vector3.ZERO,"water":false})
					check(absf(projected + sk.foot_contact.penetration(side,null)) < 0.00002, "optimized plane projection equals full weighted skin truth")
				for bone: int in rig.get_bone_count():
					check(absf(rig.get_bone_pose_position(bone).length() - rest[bone]) <= maxf(0.0001,rest[bone] * 0.005) or bone == rig.find_bone("Hips"), "rest segment length retained")
				var rotations: Array[Quaternion] = []
				for bone: int in rig.get_bone_count():
					rotations.append(rig.get_bone_pose_rotation(bone))
				var counters: Array = [contact.query_count,contact.body_support_reads,contact.history_updates,contact.sample_count,contact.pose_reads]
				sk._on_mannequin_updated()
				check(counters == [contact.query_count,contact.body_support_reads,contact.history_updates,contact.sample_count,contact.pose_reads], "duplicate callback reuses rays, samples and history")
				for bone: int in rig.get_bone_count():
					check(rotations[bone].angle_to(rig.get_bone_pose_rotation(bone)) < 0.0015, "repeat retarget is pose-idempotent")
				check(contact.query_count <= 2 and contact.body_support_reads <= 1, "bounded foot and root support queries")
		for name: String in fixed_points:
			var fixed_drift: float = 0.0
			for a: Vector3 in fixed_points[name]:
				for b: Vector3 in fixed_points[name]:
					fixed_drift = maxf(fixed_drift,Vector2(a.x-b.x,a.z-b.z).length())
			check(fixed_drift <= 0.03, "%s baseline %s window world excursion %.6fm" % [hero,name,fixed_drift])
		check(plant_windows >= 4, "actual input includes independently classified source stance windows")
		check(max_drift <= 0.03, "%s frozen-source plant max excursion %.6fm" % [hero,max_drift])
		input.v_clear(1)
		# Start real moves, then let normal Fighter physics advance all phases.
		var moves: GDScript = load("res://scripts/fighter/LimbMoves.gd")
		var cases: Array = [["left_hand",0,""],["right_hand",0,""],["left_hand",2,"right_hand>left_hand>right_hand"],["right_hand",2,"right_hand>left_hand>right_hand"],["left_leg",0,""],["right_leg",0,""]]
		for entry: Array in cases:
			f.state = actor.State.IDLE
			f.velocity = Vector3.ZERO
			for settle: int in 20:
				f._physics_process(1.0/60.0)
				sk._physics_process(1.0/60.0)
			var move = moves.resolve(f.data,entry[0],entry[1],"",false,false,"",entry[2])
			f._start_move(move)
			var attack_min: float = INF
			var raised: float = -INF
			var active_frames: int = 0
			for frame: int in 75:
				f._physics_process(1.0/60.0)
				sk._physics_process(1.0/60.0)
				if f.state != actor.State.ATTACK:
					continue
				for side: String in ["Left","Right"]:
					var sole: float = -sk.foot_contact.penetration(side,null)
					attack_min = minf(attack_min,sole)
					check(sole >= -0.005, "%s %s frame%d %s attack support sole %.6f" % [hero,move.id,frame,side,sole])
				if f.move_frame >= move.startup and f.move_frame < move.startup+move.active:
					active_frames += 1
					if String(entry[0]).ends_with("leg"):
						raised = maxf(raised,-sk.foot_contact.penetration("Left" if entry[0] == "left_leg" else "Right",null))
			check(active_frames > 0, "real attack reached active phase")
			if String(entry[0]).ends_with("leg"):
				check(raised > 0.20, "authored kicking foot remains raised")
			print("GROUND_ATTACK %s %s min=%.6f raised=%.6f" % [hero,move.id,attack_min,raised])
		var attacker = load("res://scenes/fighter/Fighter.tscn").instantiate()
		attacker.data = load("res://data/characters/choko.tres")
		root.add_child(attacker)
		attacker.set_physics_process(false)
		attacker.skeletal.set_physics_process(false)
		attacker.forward = Vector3.LEFT
		for kind: int in 3:
			f.state = actor.State.IDLE
			f.velocity = Vector3.ZERO
			var seen: int = 0
			var reaction_min: float = INF
			for frame: int in 150:
				input.v_set(1,"block",kind == 0 and frame >= 40 and frame < 80)
				if frame == 50:
					attacker.global_position = f.global_position + Vector3(2,0,0)
					if kind < 2:
						f.receive_hit(attacker,attacker.data.light)
					else:
						f.stun_frames = 24
						f.animator.flinch(Vector3(-f.facing,0,0),40.0,f.facing)
						f._set_state(actor.State.STUMBLE)
				f._physics_process(1.0/60.0)
				sk._physics_process(1.0/60.0)
				if f.state in [actor.State.BLOCKSTUN,actor.State.HITSTUN,actor.State.STUMBLE]:
					seen += 1
					for side: String in ["Left","Right"]:
						var sole: float = -sk.foot_contact.penetration(side,null)
						reaction_min = minf(reaction_min,sole)
						check(sole >= -0.005, "%s reaction%d frame%d %s standing sole %.6f" % [hero,kind,frame,side,sole])
			check(seen > 0, "standing hit/block/stumble actually reached")
			print("GROUND_REACTION %s kind%d sole_min=%.6f frames=%d" % [hero,kind,reaction_min,seen])
		input.v_clear(1)
		attacker.queue_free()
		floor_body.position.y = 3.5
		f.position = Vector3(0,4,0)
		f.velocity = Vector3.ZERO
		contact.reset()
		await physics_frame
		input.v_set(1,"crouch",true)
		for frame: int in 75:
			f._physics_process(1.0/60.0)
			sk._physics_process(1.0/60.0)
		for side: String in ["Left","Right"]:
			var sole: float = -sk.foot_contact.penetration(side,null)
			check(sole >= 3.995 and sole < 4.04, "%s elevated crouch uses actual support surface %.6f" % [hero,sole])
		# Real sloped collision support, independently skin every cached shoe vertex.
		floor_body.rotation.z = deg_to_rad(10.0)
		f.position = Vector3(0,4.1,0)
		f.velocity = Vector3.ZERO
		await physics_frame
		f.position.y = f.floor_y()
		contact.reset()
		for frame: int in 30:
			f._physics_process(1.0/60.0)
			sk._physics_process(1.0/60.0)
		var normal: Vector3 = floor_body.global_basis.y
		var top: Vector3 = floor_body.global_position + normal * 0.5
		for side: String in ["Left","Right"]:
			var lowest: float = INF
			for influences: Array in contact.samples[side]:
				var vertex := Vector3.ZERO
				for influence: Array in influences:
					vertex += rig.get_bone_global_pose(influence[0]) * influence[1] * influence[2]
				vertex = rig.global_transform * vertex
				lowest = minf(lowest,(vertex-top).dot(normal))
			var projected: float = contact._sole_clearance(side,contact._poses(),{"normal":normal,"point":top,"water":false})
			check(absf(projected-lowest/normal.y) < 0.00002, "translated ramp projection preserves unnormalized skin weight truth")
			check(lowest >= -0.005 and lowest < 0.04, "%s ramp skinned sole %.6f" % [hero,lowest])
		# Nonlinear WaveField retains world-XZ skinning, not a planar shortcut.
		var wave = load("res://scripts/core/WaveField.gd").new()
		wave.use_z = true
		root.get_node("GameState").water = wave
		for mode: bool in [false,true]:
			wave.use_z = mode
			wave.frame = 0
			wave.start_swell(0.8)
			for tick: int in [0,17,20,59,130]:
				wave.frame = tick
				for side: String in ["Left","Right"]:
					var actual: float = contact._sole_clearance(side,contact._poses(),{"water":true})
					check(absf(actual + sk.foot_contact.penetration(side,wave)) < 0.00002, "nonlinear water clearance equals full skinned vertex truth")
		root.get_node("GameState").water = null
		# Unsupported edge and airborne poses cannot keep a previous world anchor.
		f.position = Vector3(150,4,0)
		contact.begin_frame(1.0/60.0)
		var histories: int = contact.history_updates
		contact.apply(f,sk.skeleton,sk.clip,sk.clip_pos,1.0/60.0)
		check(contact.history_updates == histories and contact.query_count == 0, "edge releases before foot rays")
		f.position = Vector3(0,5,0)
		f.state = actor.State.JUMP
		contact.begin_frame(1.0/60.0)
		var leg_pose: Quaternion = rig.get_bone_pose_rotation(rig.find_bone("LeftUpLeg"))
		contact.apply(f,sk.skeleton,sk.clip,sk.clip_pos,1.0/60.0)
		check(leg_pose == rig.get_bone_pose_rotation(rig.find_bone("LeftUpLeg")) and contact.query_count == 0, "air preserves authored legs and releases support")
		floor_body.rotation = Vector3.ZERO
		print("GROUND_CONTACT_METRICS %s sole_min=%.6f plant_max=%.6f windows=%d" % [hero,min_sole,max_drift,plant_windows])
		input.v_clear(1)
		floor_body.position.y = -0.5
		f.queue_free()
		await process_frame
	floor_body.queue_free()
	for name: String in ["Sfx","UltMusic","Music"]:
		root.get_node(name).queue_free()
	await create_timer(0.25).timeout
	print("GROUND_CONTACT_COMPLETE checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
