extends SceneTree
## Actual hero world-space foot trajectories, distance-driven phase, low stance and four-limb drawings.
var failures: int = 0
var checks: int = 0
var FighterScript: GDScript
var Motion: GDScript
const EXPECTED_SOURCE: Dictionary = {
	"jab": "Punch_Jab", "cross": "Punch_Cross", "bodyhook": "Melee_Hook",
	"uppercut": "Melee_Uppercut", "hammer": "OverhandThrow", "lowhand": "Punch_Jab",
	"airhand": "Punch_Cross", "frontkick": "Kick", "roundhouse": "Kick",
	"spin": "Kick", "hookspin": "Kick", "lowkick": "Kick", "airkick": "Kick",
}

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("GAIT: " + label)

func _initialize() -> void:
	await process_frame
	FighterScript = load("res://scripts/fighter/Fighter.gd")
	Motion = load("res://scripts/fighter/LimbMotion.gd")
	var state: Node = root.get_node("GameState")
	state.skeletal_rig = true
	state.free_move = true
	state.water = null
	for id: String in ["choko", "skea"]:
		var f = load("res://scenes/fighter/Fighter.tscn").instantiate()
		f.data = load("res://data/characters/%s.tres" % id)
		root.add_child(f)
		f.set_physics_process(false)
		f.skeletal.set_physics_process(false)
		var sk = f.skeletal
		f.position = Vector3.ZERO
		f.forward = Vector3.RIGHT
		f.state = FighterScript.State.WALK
		f.velocity = f.forward * f.data.walk_speed
		var last_foot: Vector3 = Vector3.ZERO
		var maximum_step: float = 0.0
		var contacts: Array[float] = []
		var minimum_y: float = INF
		var maximum_y: float = -INF
		for frame: int in 180:
			f.position += f.velocity / 60.0
			f.animator.tick(1.0 / 60.0, f, false)
			sk._physics_process(1.0 / 60.0)
			sk.retarget()
			var bone: int = sk.hero_skeleton.find_bone("LeftToeBase")
			var foot: Vector3 = sk.hero_skeleton.global_transform * sk.hero_skeleton.get_bone_global_pose(bone).origin
			check(foot.is_finite(), id + " finite world toe")
			minimum_y = minf(minimum_y, foot.y)
			maximum_y = maxf(maximum_y, foot.y)
			if frame > 0:
				maximum_step = maxf(maximum_step, foot.distance_to(last_foot))
				if foot.y < 0.10 and last_foot.y < 0.10:
					contacts.append(Vector2(foot.x - last_foot.x, foot.z - last_foot.z).length() * 60.0)
			last_foot = foot
		check(sk.clip == sk.clip_name("Jog_Fwd_Loop"), id + " authored jog at combat speed")
		check(maximum_y - minimum_y > 0.08, id + " visible foot lift")
		check(maximum_step < 0.75, id + " no discontinuous metre-scale foot jumps")
		var old_phase: float = sk.cadence.phase
		for frame: int in 20:
			sk._physics_process(1.0 / 60.0)
		check(is_equal_approx(sk.cadence.phase, old_phase), id + " blocked body does not treadmill")
		contacts.sort()
		# Independent old-behaviour control: same hero, distance and ground; Walk played at 1x.
		var baseline: Array[float] = []
		var old_walk: String = sk.clip_name("Walk_Loop")
		var old_length: float = sk.player.get_animation(old_walk).length
		sk.player.play(old_walk)
		for frame: int in 180:
			f.position += f.velocity / 60.0
			sk.player.seek(fmod(float(frame) / 60.0, old_length), true)
			sk.retarget()
			var toe: int = sk.hero_skeleton.find_bone("LeftToeBase")
			var point: Vector3 = sk.hero_skeleton.global_transform * sk.hero_skeleton.get_bone_global_pose(toe).origin
			if frame > 0 and point.y < 0.10 and last_foot.y < 0.10:
				baseline.append(Vector2(point.x - last_foot.x, point.z - last_foot.z).length() * 60.0)
			last_foot = point
		baseline.sort()
		check(contacts.size() >= 5 and baseline.size() >= 5, id + " both contact traces sampled")
		if contacts.size() >= 5 and baseline.size() >= 5:
			var current_slip: float = contacts[contacts.size() / 2]
			var baseline_slip: float = baseline[baseline.size() / 2]
			# Require a material reduction, not zero slip that the current retarget cannot claim.
			check(current_slip < baseline_slip * 0.4, id + " more than 60 percent lower stance slip than fixed Walk")
			print("GAIT_BASELINE %s old_slip=%s new_slip=%s ratio=%s" % [id, baseline_slip, current_slip, current_slip / baseline_slip])
		sk.clip = ""  # The control intentionally changed AnimationPlayer outside the runtime selector.
		print("GAIT_TRACE %s toe_y=%s..%s max_frame_step=%s contact_median_speed=%s samples=%s" % [id, minimum_y, maximum_y, maximum_step, contacts[contacts.size() / 2] if not contacts.is_empty() else -1.0, contacts.size()])
		f.state = FighterScript.State.IDLE
		f.velocity = Vector3.ZERO
		sk._physics_process(1.0 / 60.0)
		sk.retarget()
		var hips: int = sk.hero_skeleton.find_bone("Hips")
		var standing: float = sk.hero_skeleton.get_bone_global_pose(hips).origin.y
		f.state = FighterScript.State.CROUCH
		f.animator.tick(1.0 / 60.0, f, false)
		sk._physics_process(1.0 / 60.0)
		check(sk.clip == sk.clip_name("Crouch_Enter"), id + " authored crouch transition")
		for frame: int in 90:
			f.animator.tick(1.0 / 60.0, f, false)
			sk._physics_process(1.0 / 60.0)
		sk.retarget()
		check(sk.clip == sk.clip_name("Crouch_Idle_Loop"), id + " settled crouch")
		check(sk.hero_skeleton.get_bone_global_pose(hips).origin.y < standing * 0.8, id + " hips actually lower")
		check(f.animator.target_pose["thigh_l"].z > 1.0, id + " guard does not erase squat")
		f.state = FighterScript.State.IDLE
		sk._physics_process(1.0 / 60.0)
		check(sk.clip == sk.clip_name("Crouch_Exit"), id + " authored crouch exit")
		var jab_reach: Dictionary = {}
		for action: String in ["left_hand", "right_hand", "left_leg", "right_leg"]:
			var drawings: Array[int] = []
			var variants: Array = Motion.HANDS if action.ends_with("hand") else Motion.FEET
			for variant: String in variants:
				var m = f.data.light.duplicate(true)
				m.anim = "limb_" + action + "_" + variant
				m.anim_clip = ""
				m.anim_clip_chain = ""
				m.anim_chain = ""
				f.current_move = m
				f.chain_index = 0
				f.state = FighterScript.State.ATTACK
				f.move_frame = m.startup
				var before: Array = [f.position, f.velocity, f.hp, f.meter, m.damage, m.hitbox_offset]
				f.animator.tick(1.0 / 60.0, f, false)
				sk._physics_process(1.0 / 60.0)
				sk.retarget()
				var source_name: String = "Melee_Knee" if id == "skea" and variant == "airkick" else EXPECTED_SOURCE[variant]
				var imported: String = sk.clip_name(source_name)
				check(not imported.is_empty() and sk.clip == imported, m.anim + " actual imported authored source")
				check(not sk.uses_procedural_motion(), m.anim + " authored motion replaces fallback")
				check(before == [f.position, f.velocity, f.hp, f.meter, m.damage, m.hitbox_offset], m.anim + " no gameplay mutation")
				var side: String = "Left" if action.begins_with("left") else "Right"
				var endpoint: int = sk.hero_skeleton.find_bone(side + ("Hand" if action.ends_with("hand") else "Foot"))
				check(sk.hero_skeleton.get_bone_global_pose(endpoint).origin.is_finite(), m.anim + " finite attacking limb")
				var drawing: int = hash(f.animator.target_pose)
				check(drawing not in drawings, m.anim + " distinct contact drawing")
				drawings.append(drawing)
				if variant == "jab":
					var shoulder: int = sk.hero_skeleton.find_bone(side + "Arm")
					var world_hand: Vector3 = sk.hero_skeleton.global_transform * sk.hero_skeleton.get_bone_global_pose(endpoint).origin
					var world_shoulder: Vector3 = sk.hero_skeleton.global_transform * sk.hero_skeleton.get_bone_global_pose(shoulder).origin
					var reach: float = (world_hand - world_shoulder).dot(f.forward)
					jab_reach[side] = reach
					check(reach > 0.3, id + side + " jab extends forward from shoulder")
					print("LIMB_REACH %s %s jab=%s" % [id, side, reach])
				var suffix: String = "l" if side == "Left" else "r"
				if action.ends_with("hand"):
					check(f.animator.target_pose["forearm_" + suffix].z >= 0.0, m.anim + " elbow does not hyperextend")
				else:
					check(f.animator.target_pose["shin_" + suffix].z <= 0.0, m.anim + " knee does not hyperextend")
		check(absf(jab_reach["Left"] - jab_reach["Right"]) < 0.08, id + " bilateral jab reach symmetry")
		var hook_script: GDScript = load("res://scripts/grapple/GrappleHook.gd")
		var hook_drawings: Array[int] = []
		f.state = FighterScript.State.GRAPPLE
		f.grapple.anchor_point = f.global_position + Vector3(4.0, 6.0, 2.0)
		for phase: int in [hook_script.Phase.WINDUP, hook_script.Phase.FLIGHT, hook_script.Phase.HANG]:
			f.grapple.phase = phase
			f.grapple.windup_progress = 0.5
			f.velocity = Vector3(2.0, 0.0, 0.0)
			var authority: Array = [f.position, f.velocity, f.grapple.phase, f.grapple.anchor_point, f.grapple.rope_length]
			for frame: int in 30:
				f.animator.tick(1.0 / 60.0, f, false)
				sk._physics_process(1.0 / 60.0)
			check(not sk.uses_procedural_motion() and not sk.authored_hook.source_clip.is_empty(), id + " hook phase has authored upper-body source")
			if phase == hook_script.Phase.WINDUP:
				check(f.animator.root_offset.y < -0.15 and absf(f.animator.pose["torso"].y) > 0.4, id + " hook windup loads hips and torso")
			var drawing: int = hash(f.animator.target_pose)
			check(drawing not in hook_drawings, id + " hook phase body drawing differs")
			hook_drawings.append(drawing)
			check(authority == [f.position, f.velocity, f.grapple.phase, f.grapple.anchor_point, f.grapple.rope_length], id + " hook motion presentation only")
		f.grapple.phase = hook_script.Phase.IDLE
		f.free()
	check(not Motion.supports("limb_left_hand_unknown"), "unknown variation rejected")
	check(not Motion.supports("limb_left_leg_jab"), "wrong limb variation rejected")
	print("GAIT_CHECK_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
