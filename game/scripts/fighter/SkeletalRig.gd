class_name SkeletalRig
extends Node3D
## C1 mannequin (launch 4, docs/Plans/2026-10-03-Picks-to-Game-and-Animation.md § C1): the Quaternius UAL1 mannequin
## with UAL1 + UAL2 Source clips (120 + 134, CC0, one 65-bone skeleton).
## Enabled by default through GameState.skeletal_rig; `-- --capsules` selects the diagnostic capsule view.
##
## The capsule RigAnimator keeps running underneath, with its meshes hidden: ragdoll, afterimages and the smoke still
## read its part_snapshot()/pose. This node is presentation only — it never moves the fighter or a hitbox.
## The player is driven by hand from _physics_process (it runs after Fighter's, parent first), so a clip's pose
## follows the fighter's frame counters: authored contacts land on a known frame. The seven semantic
## procedural fallbacks consume the capsule animator's existing stepped drawing and seeded reaction.
##
## Launch 5: with CharacterData.model_scene set, the hero GLB (Meshy auto-rig, 24 bones) is drawn instead. The
## mannequin keeps playing, hidden — it is the pose source (the smoke reads it) — and every physics frame its pose is
## copied onto the hero bone by bone (HERO_BONES). The Meshy rest is an A-pose, the UAL rest a T-pose, so each hero
## bone first gets a rest alignment (its rest direction turned onto the mannequin's), then the mannequin's rotation
## from rest. Bone lengths stay the hero's; only the hips move, scaled by the hip-height ratio.

const HeroGear = preload("res://scripts/fighter/HeroGearPresentation.gd")
const BodyMotion = preload("res://scripts/fighter/HeroBodyMotion.gd")
const GroundContact = preload("res://scripts/fighter/HeroGroundContact.gd")
const MotionSignals = preload("res://scripts/fighter/FighterMotionSignals.gd")
const HookSource = preload("res://scripts/fighter/AuthoredHookMotion.gd")
const HookMotion = preload("res://scripts/fighter/GrappleMotion.gd")
const Cadence = preload("res://scripts/fighter/LocomotionCadence.gd")
const MotionFallback = preload("res://scripts/fighter/ProceduralMotionFallback.gd")
const FootContact = preload("res://scripts/fighter/HeroFootContact.gd")
const StancePresence = preload("res://scripts/fighter/IdlePresence.gd")
const AuthoredCombat = preload("res://scripts/fighter/AuthoredCombatMotion.gd")
const GroundMotion = preload("res://scripts/fighter/AuthoredLocomotion.gd")
const DodgeSource = preload("res://scripts/fighter/AuthoredDodgeMotion.gd")
const LandingSource = preload("res://scripts/fighter/AuthoredLandingMotion.gd")

const MANNEQUIN := "res://assets/animations/ual/UAL1.glb"
const EXTRA_LIBRARY := "res://assets/animations/ual/UAL2.glb"
const EXTRA_PREFIX := "ual2"
## Clips per fighter state — docs/GDD/02-Combat-System.md § Кліп → удар, «Спільні стани» (T5 Арес). Names are the
## GLB names; Godot's importer drops the `_Loop` suffix and loops the clip, so clip_name() maps them.
## Per-fighter clips (stance, dash, get-up) live in CharacterData; attack clips in MoveData.
const STATE_CLIPS := {
	"walk": "Walk_Loop",
	"walk_back": "Walk_Bwd_Loop",
	"crouch": "Crouch_Idle_Loop",
	"jump": "Jump_Loop",
	"block": "Sword_Block",
	"hit_high": "Hit_Head",
	"hit_mid": "Hit_Chest",
	"hit_low": "Hit_Stomach",
	"knockdown": "Hit_Knockback",
	"ko": "Death01",
	"tired": "Idle_Tired_Loop",   # 02 § Втома (г): the stance from fatigue 0.5
}
## The model faces +Z; the capsule rig (and every hitbox_offset) faces +X.
const MODEL_YAW := PI / 2.0
## Hero (Meshy) bone → mannequin (UAL) bone. Meshy counts the spine from the top: Spine02 sits on the hips.
## head_end / headfront have no UAL twin and keep their rest.
const HERO_BONES := {
	"Hips": "pelvis", "Spine02": "spine_01", "Spine01": "spine_02", "Spine": "spine_03", "neck": "neck_01", "Head": "Head",
	"LeftShoulder": "clavicle_l", "LeftArm": "upperarm_l", "LeftForeArm": "lowerarm_l", "LeftHand": "hand_l",
	"RightShoulder": "clavicle_r", "RightArm": "upperarm_r", "RightForeArm": "lowerarm_r", "RightHand": "hand_r",
	"LeftUpLeg": "thigh_l", "LeftLeg": "calf_l", "LeftFoot": "foot_l", "LeftToeBase": "ball_l",
	"RightUpLeg": "thigh_r", "RightLeg": "calf_r", "RightFoot": "foot_r", "RightToeBase": "ball_r",
}
## Hero bone → the child whose direction aims it (rest alignment). Bones without one take their parent's alignment.
const HERO_AIM := {
	"Hips": "Spine02", "Spine02": "Spine01", "Spine01": "Spine", "Spine": "neck", "neck": "Head",
	"LeftShoulder": "LeftArm", "LeftArm": "LeftForeArm", "LeftForeArm": "LeftHand",
	"RightShoulder": "RightArm", "RightArm": "RightForeArm", "RightForeArm": "RightHand",
	"LeftUpLeg": "LeftLeg", "LeftLeg": "LeftFoot", "LeftFoot": "LeftToeBase",
	"RightUpLeg": "RightLeg", "RightLeg": "RightFoot", "RightFoot": "RightToeBase",
}
## Ink outline width on the hero, metres — same as the capsule rig (RigAnimator._mat).
const HERO_OUTLINE := 0.022

var player: AnimationPlayer
var skeleton: Skeleton3D
var clip: String = ""            # resolved name now on the player ("" = none)
var clip_pos: float = 0.0        # seconds into `clip` after this frame
var _fighter: Fighter
var _state_frames: int = 0
var _last_state: int = -1
## Launch 5 hero (null = the bare mannequin is drawn).
var hero: Node3D = null
var hero_skeleton: Skeleton3D = null
var hero_mesh: MeshInstance3D = null
var _map: Array = []              # [[hero bone, mannequin bone]], parents first
var _align: Dictionary = {}       # hero bone → rest alignment Quaternion
var _src_rest: Dictionary = {}    # mannequin bone → global rest rotation
var _hip_scale: float = 1.0
var _gait_scale: float = 1.0
## Launch 7.1: the skeleton ragdoll running on the mannequin (null = none); while set, the hero is drawn.
var ragdoll: BoneRagdoll = null
var idle_presence = StancePresence.new()
var foot_contact = FootContact.new()
var cadence = Cadence.new()
var _crouch_exit_frames: int = -1
var sword: SwordPresentation
var _sword_mirror_base: Dictionary = {}
## PLACEHOLDER art duration: return to stance after a swing, never blend into a contact/reaction.
@export_range(0.0, 0.2) var attack_return_seconds: float = 0.10
var _attack_return_source: Array[Transform3D] = []
var _attack_return_base: Array[Transform3D] = []
var _attack_return_elapsed: float = 0.0
var _had_procedural_motion: bool = false
var authored_combat = AuthoredCombat.new()
var locomotion = GroundMotion.new()
var authored_dodge = DodgeSource.new()
var authored_landing = LandingSource.new()
var authored_hook = HookSource.new()
var body_motion = BodyMotion.new()
var ground_contact = GroundContact.new()
var motion_signals = MotionSignals.new()
var gear: Node3D


func setup(f: Fighter) -> void:
	_fighter = f
	var model: Node = (load(MANNEQUIN) as PackedScene).instantiate()
	model.name = "Mannequin"
	model.rotation.y = MODEL_YAW
	add_child(model)
	player = model.get_node("AnimationPlayer") as AnimationPlayer
	skeleton = model.get_node("Armature/Skeleton3D") as Skeleton3D
	var extra: Node = (load(EXTRA_LIBRARY) as PackedScene).instantiate()
	var lib: AnimationLibrary = (extra.get_node("AnimationPlayer") as AnimationPlayer).get_animation_library("")
	player.add_animation_library(EXTRA_PREFIX, lib)
	extra.free()
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	authored_combat.setup(player, skeleton)
	authored_landing.setup(player, skeleton)
	authored_hook.setup(player, skeleton)
	# retarget after the mannequin's modifiers ran: outside this signal get_bone_global_pose() gives the clip's pose,
	# not the skeleton ragdoll's (launch 7.1)
	skeleton.skeleton_updated.connect(_on_mannequin_updated)
	_hide_capsules()
	if f.data.model_scene != "":
		_setup_hero(f.data.model_scene)
	if f.data.weapon_kind == "sword":
		sword = SwordPresentation.new()
		sword.name = "SwordPresentation"
		add_child(sword)
		sword.setup(f, self)
	if hero_skeleton != null:
		gear = HeroGear.new()
		gear.name = "HeroGear"
		add_child(gear)
		gear.setup(f,self)


## Loads the hero GLB beside the mannequin, hides the mannequin's mesh and precomputes the retarget.
func _setup_hero(path: String) -> void:
	hero = (load(path) as PackedScene).instantiate() as Node3D
	hero.name = "Hero"
	hero.rotation.y = MODEL_YAW
	add_child(hero)
	hero_skeleton = hero.get_node("Armature/Skeleton3D") as Skeleton3D
	hero_mesh = hero_skeleton.find_children("*", "MeshInstance3D", false, false)[0] as MeshInstance3D
	for m in skeleton.find_children("*", "MeshInstance3D", false, false):
		(m as MeshInstance3D).visible = false
	var ap := hero.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if ap != null:
		ap.active = false   # Meshy's own idle clip — the mannequin drives this skeleton
	_cel_material()
	for i in hero_skeleton.get_bone_count():
		var hb := hero_skeleton.get_bone_name(i)
		if HERO_BONES.has(hb) and skeleton.find_bone(HERO_BONES[hb]) >= 0:
			_map.append([i, skeleton.find_bone(HERO_BONES[hb])])
	for pair in _map:
		var hi: int = pair[0]
		var si: int = pair[1]
		_src_rest[si] = skeleton.get_bone_global_rest(si).basis.orthonormalized().get_rotation_quaternion()
		var hb := hero_skeleton.get_bone_name(hi)
		if HERO_AIM.has(hb):
			var hc := hero_skeleton.find_bone(HERO_AIM[hb])
			var sc := skeleton.find_bone(HERO_BONES[HERO_AIM[hb]])
			var dh := hero_skeleton.get_bone_global_rest(hc).origin - hero_skeleton.get_bone_global_rest(hi).origin
			var ds := skeleton.get_bone_global_rest(sc).origin - skeleton.get_bone_global_rest(si).origin
			_align[hi] = Quaternion(dh.normalized(), ds.normalized())
		else:
			var hp := hero_skeleton.get_bone_parent(hi)
			_align[hi] = _align.get(hp, Quaternion.IDENTITY)
	foot_contact.setup(hero_skeleton, hero_mesh)
	body_motion.setup(hero_skeleton, skeleton)
	ground_contact.setup(hero_skeleton, hero_mesh, foot_contact.samples)
	var hips := hero_skeleton.find_bone("Hips")
	_hip_scale = hero_skeleton.get_bone_global_rest(hips).origin.y / maxf(skeleton.get_bone_global_rest(skeleton.find_bone("pelvis")).origin.y, 1e-4)
	# Cadence follows world-space leg length, not hip height: Meshy has different pelvis proportions.
	# Retarget translation still needs the separate centimetre-space hip ratio above.
	_gait_scale = leg_length(hero_skeleton, ["LeftUpLeg", "LeftLeg", "LeftFoot"]) / maxf(leg_length(skeleton, ["thigh_l", "calf_l", "foot_l"]), 0.0001)


static func leg_length(rig: Skeleton3D, names: Array[String]) -> float:
	var upper: Vector3 = rig.global_transform * rig.get_bone_global_rest(rig.find_bone(names[0])).origin
	var knee: Vector3 = rig.global_transform * rig.get_bone_global_rest(rig.find_bone(names[1])).origin
	var foot: Vector3 = rig.global_transform * rig.get_bone_global_rest(rig.find_bone(names[2])).origin
	return upper.distance_to(knee) + knee.distance_to(foot)


## Toon + ink outline like the capsule rig, on the hero's own texture; registered with the capsule rig's materials so
## the hit flash and the time-stop tint reach it.
func _cel_material() -> void:
	var src := hero_mesh.get_active_material(0)
	var m := ShaderMaterial.new()
	m.shader = RigAnimator.TOON
	if src is BaseMaterial3D and (src as BaseMaterial3D).albedo_texture != null:
		m.set_shader_parameter("albedo_tex", (src as BaseMaterial3D).albedo_texture)
	var o := ShaderMaterial.new()
	o.shader = RigAnimator.OUTLINE
	# the outline pushes vertices in the mesh's local space; the Meshy armature is scaled (bones in cm)
	o.set_shader_parameter("width", HERO_OUTLINE / maxf(hero_mesh.global_transform.basis.get_scale().x / global_transform.basis.get_scale().x, 1e-4))
	m.next_pass = o
	hero_mesh.material_override = m
	_fighter.animator.materials.append(m)


## Copies the mannequin's pose onto the hero: per bone, global rotation = mannequin's rotation from its rest ·
## rest alignment · hero rest; local = parent⁻¹ · global. Hips position follows the mannequin's, scaled.
func retarget() -> void:
	var glob: Dictionary = {}
	for pair in _map:
		var hi: int = pair[0]
		var si: int = pair[1]
		var src_rot := skeleton.get_bone_global_pose(si).basis.orthonormalized().get_rotation_quaternion()
		var delta: Quaternion = src_rot * (_src_rest[si] as Quaternion).inverse()
		var rest_rot := hero_skeleton.get_bone_global_rest(hi).basis.orthonormalized().get_rotation_quaternion()
		var g: Quaternion = delta * (_align[hi] as Quaternion) * rest_rot
		glob[hi] = g
		var hp := hero_skeleton.get_bone_parent(hi)
		var parent_rot: Quaternion = glob[hp] if glob.has(hp) else (hero_skeleton.get_bone_global_rest(hp).basis.orthonormalized().get_rotation_quaternion() if hp >= 0 else Quaternion.IDENTITY)
		hero_skeleton.set_bone_pose_rotation(hi, (parent_rot.inverse() * g).normalized())
		if hp < 0:
			var s_rest := skeleton.get_bone_global_rest(si).origin
			var s_now := skeleton.get_bone_global_pose(si).origin
			hero_skeleton.set_bone_pose_position(hi, hero_skeleton.get_bone_rest(hi).origin + (s_now - s_rest) * _hip_scale)
	# One ordered final pose: body/support first, semantic contacts afterwards.
	if ragdoll == null:
		body_motion.apply_balance(hero_skeleton, _fighter)
	authored_landing.apply(hero_skeleton, locomotion.moving_landing_phase())
	foot_contact.apply(_fighter, ragdoll)
	ground_contact.apply(_fighter, skeleton, clip, clip_pos, body_motion._dt, ragdoll)
	authored_combat.adjust_hero_contact(hero_skeleton, _fighter)
	authored_hook.apply_hands(hero_skeleton, _fighter)
	body_motion.apply_gaze(hero_skeleton, skeleton, _fighter, ragdoll)


## Presentation endpoint only; physics keeps GrappleHook.HAND and its deterministic rope constraint.
func hand_world(side: String = "Right") -> Vector3:
	if is_instance_valid(hero_skeleton):
		var bone: int = hero_skeleton.find_bone(side + "Hand")
		if bone >= 0:
			return hero_skeleton.global_transform * hero_skeleton.get_bone_global_pose(bone).origin
	return _fighter.global_position + Vector3(0.0, 1.25, 0.0)


## Angle (degrees) between a hero bone's direction and its mannequin twin's, both skeleton space — the smoke's
## retarget check. Only bones in HERO_AIM have a direction.
func aim_error(hero_bone: String) -> float:
	var hi := hero_skeleton.find_bone(hero_bone)
	var hc := hero_skeleton.find_bone(HERO_AIM[hero_bone])
	var si := skeleton.find_bone(HERO_BONES[hero_bone])
	var sc := skeleton.find_bone(HERO_BONES[HERO_AIM[hero_bone]])
	var dh := hero_skeleton.get_bone_global_pose(hc).origin - hero_skeleton.get_bone_global_pose(hi).origin
	var ds := skeleton.get_bone_global_pose(sc).origin - skeleton.get_bone_global_pose(si).origin
	return rad_to_deg(dh.angle_to(ds))


## The capsule meshes stay in the tree (snapshots read them), just not drawn.
func _hide_capsules() -> void:
	for m in _fighter.animator.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).visible = false


## Player name for a GLB clip name: `_Loop` dropped by the importer, UAL2 clips under `ual2/`. "" when missing.
func clip_name(glb_name: String) -> String:
	if glb_name == "" or player == null:
		return ""
	var n := glb_name.trim_suffix("_Loop")
	if player.has_animation(n):
		return n
	if player.has_animation(EXTRA_PREFIX + "/" + n):
		return EXTRA_PREFIX + "/" + n
	return ""


## Time in the first attack clip at attack frame `frame` (0 = first startup frame); the clip spans `span` frames
## (startup + active with a _Rec clip, the whole move without). Startup maps 0 → `contact`, so the contact pose is on
## the first active frame; the rest of the span maps `contact` → the clip's end. contact 0 = not measured: linear.
static func attack_clip_time(frame: int, startup: int, span: int, length: float, contact: float) -> float:
	if length <= 0.0:
		return 0.0
	if contact <= 0.0 or contact >= length or span <= startup:
		return clampf(float(frame) / float(maxi(span, 1)), 0.0, 1.0) * length
	if frame <= startup:
		return contact * float(frame) / float(maxi(startup, 1))
	return contact + (length - contact) * clampf(float(frame - startup) / float(span - startup), 0.0, 1.0)


## The attack's clip names and contact for this swing: [clip, rec clip, contact] (odd chain hits use *_chain).
static func attack_clips(m: MoveData, chain_index: int) -> Array:
	if chain_index % 2 == 1 and m.anim_clip_chain != "":
		return [m.anim_clip_chain, m.anim_clip_chain_rec, m.contact_time_chain]
	return [m.anim_clip, m.anim_clip_rec, m.contact_time]


## Eight source locomotion clips, relative to the fighter's facing, not the camera.
## Sector centres are 45 degrees apart, so diagonals keep their diagonal footwork.
static func walk_clip(velocity: Vector3, forward: Vector3) -> String:
	var right: Vector3 = forward.cross(Vector3.UP)
	var sector: int = posmod(roundi(atan2(velocity.dot(right), velocity.dot(forward)) / (PI / 4.0)), 8)
	return ["Walk_Loop", "Walk_Fwd_R_Loop", "Walk_R_Loop", "Walk_Bwd_R_Loop",
		"Walk_Bwd_Loop", "Walk_Bwd_L_Loop", "Walk_L_Loop", "Walk_Fwd_L_Loop"][sector]


## GLB clip this fighter state plays. Empty attack clips use the explicit procedural bridge when supported;
## otherwise the stance remains the safe fallback. The bridge runs after seeking the base clip.
func state_clip(f: Fighter) -> String:
	if not locomotion.special_clip.is_empty() and f.state in [Fighter.State.IDLE, Fighter.State.WALK, Fighter.State.JUMP]:
		return locomotion.special_clip
	if (f.state in [Fighter.State.IDLE, Fighter.State.WALK] or HookSource.grounded_travel(f)) and locomotion.moving():
		return locomotion.source_clip
	if f.state == Fighter.State.WALK and locomotion.active and not locomotion.moving():
		return f.data.idle_clip
	match f.state:
		Fighter.State.ATTACK:
			if f.current_move == null:
				return ""
			var authored: Dictionary = AuthoredCombat.resolve(f.current_move, f.data.id)
			if not authored.is_empty():
				return authored.recovery if authored.recovery != "" and f.move_frame >= f.current_move.startup + f.current_move.active else authored.clip
			var c := attack_clips(f.current_move, f.chain_index)
			var m := f.current_move
			return c[1] if c[1] != "" and f.move_frame >= m.startup + m.active else c[0]
		Fighter.State.WALK:
			var forward: Vector3 = f.forward if GameState.free_move else Vector3(float(f.facing), 0.0, 0.0)
			return Cadence.choose(f.velocity, forward, _gait_scale)
		Fighter.State.CROUCH:
			var enter: String = clip_name("Crouch_Enter")
			if enter != "" and float(_state_frames) / 60.0 < player.get_animation(enter).length:
				return "Crouch_Enter"
			return STATE_CLIPS["crouch"]
		Fighter.State.GRAPPLE:
			return f.data.idle_clip if f.on_ground() else STATE_CLIPS["jump"]
		Fighter.State.JUMP:
			return STATE_CLIPS["jump"]
		Fighter.State.DASH:
			return DodgeSource.source(f) if f.dodging else f.data.dash_clip
		Fighter.State.BLOCK, Fighter.State.BLOCKSTUN:
			return STATE_CLIPS["crouch"] if f.crouching else STATE_CLIPS["block"]
		Fighter.State.HITSTUN, Fighter.State.STUMBLE:
			return STATE_CLIPS["hit_" + f.animator.flinch_zone] if STATE_CLIPS.has("hit_" + f.animator.flinch_zone) else STATE_CLIPS["hit_mid"]
		Fighter.State.LAUNCHED, Fighter.State.KNOCKDOWN, Fighter.State.WALL_SPLAT:
			return STATE_CLIPS["knockdown"]
		Fighter.State.GETUP:
			return f.data.getup_clip
		Fighter.State.KO:
			return STATE_CLIPS["ko"]
		Fighter.State.IDLE:
			if _crouch_exit_frames >= 0:
				return "Crouch_Exit"
			if f.fatigue >= Fighter.FATIGUE_TIRED:
				return STATE_CLIPS["tired"]
	return f.data.idle_clip


func _physics_process(delta: float) -> void:
	if _fighter == null or player == null:
		return
	visible = _fighter.animator.visible or ragdoll != null
	rotation.y = _fighter.animator.rotation.y
	if get_tree().paused or _fighter.frozen_frames > 0 or _fighter.hitstop_frames > 0:
		return   # time stop / hitstop: hold the drawing
	motion_signals.update(_fighter, delta)
	if gear != null:
		gear.advance(delta)
	if motion_signals.discontinuous:
		body_motion.restore_source(skeleton)
		_restore_attack_return_base()
		locomotion.restore(skeleton)
		locomotion = GroundMotion.new()
		cadence.phase = 0.0
		body_motion.reset()
		ground_contact.reset()
		_last_state = _fighter.state
		_state_frames = 0
		_crouch_exit_frames = -1
		_attack_return_source.clear()
		_attack_return_base.clear()
	body_motion.update(_fighter, delta, motion_signals.actual_velocity, motion_signals.acceleration)
	ground_contact.begin_frame(delta)
	body_motion.prepare_source(skeleton, _fighter)
	authored_hook.update(_fighter, skeleton, delta)
	authored_dodge.prepare(skeleton, _fighter)
	var return_allowed: bool = _fighter.state in [Fighter.State.IDLE, Fighter.State.WALK, Fighter.State.CROUCH] and ragdoll == null and not RigAnimator.levitating(_fighter) and not HookMotion.recovery_active(_fighter)
	if _last_state == Fighter.State.ATTACK and return_allowed and attack_return_seconds > 0.0:
		_attack_return_source = _bone_poses()
		_attack_return_elapsed = 0.0
	elif not return_allowed:
		_attack_return_source.clear()
	if _fighter.state != _last_state:
		_crouch_exit_frames = -1
		if _last_state == Fighter.State.CROUCH and _fighter.state == Fighter.State.IDLE:
			var enter_name: String = clip_name("Crouch_Enter")
			var exit_name: String = clip_name("Crouch_Exit")
			if enter_name != "" and exit_name != "":
				var depth: float = clampf(float(_state_frames) * delta / player.get_animation(enter_name).length, 0.0, 1.0)
				_crouch_exit_frames = int((1.0 - depth) * player.get_animation(exit_name).length / delta)
		_last_state = _fighter.state
		_state_frames = 0
	else:
		_state_frames += 1
	if _crouch_exit_frames >= 0:
		_crouch_exit_frames += 1
		var exit_clip: String = clip_name("Crouch_Exit")
		if exit_clip == "" or float(_crouch_exit_frames) * delta >= player.get_animation(exit_clip).length:
			_crouch_exit_frames = -1
	var distance: float = motion_signals.distance
	locomotion.update(_fighter, distance, delta, _gait_scale, ragdoll == null and not RigAnimator.levitating(_fighter) and _crouch_exit_frames < 0)
	var source: Dictionary = AuthoredCombat.resolve(_fighter.current_move, _fighter.data.id) if _fighter.state == Fighter.State.ATTACK else {}
	var want := clip_name(state_clip(_fighter))
	if want == "":
		want = clip_name(_fighter.data.idle_clip)
	if want == "":
		return   # no stance clip either (bad .tres name — the smoke names it)
	var anim := player.get_animation(want)
	if want != clip:
		clip = want
		player.play(clip)
	var ground_time: float = locomotion.special_time(anim.length)
	if _fighter.dodging:
		clip_pos = DodgeSource.source_time(_fighter)
	elif ground_time >= 0.0:
		clip_pos = ground_time
	elif not source.is_empty():
		clip_pos = AuthoredCombat.clip_time(_fighter.current_move, _fighter.move_frame, source, anim.length)
	elif _fighter.state == Fighter.State.ATTACK and _fighter.current_move != null and clip_name(state_clip(_fighter)) == clip:
		var m := _fighter.current_move
		var c := attack_clips(m, _fighter.chain_index)
		var window := m.startup + m.active
		if c[1] != "" and _fighter.move_frame >= window:
			clip_pos = anim.length * clampf(float(_fighter.move_frame - window) / float(maxi(m.recovery, 1)), 0.0, 1.0)
		else:
			var span := window if c[1] != "" else window + m.recovery
			clip_pos = attack_clip_time(_fighter.move_frame, m.startup, span, anim.length, c[2])
	elif locomotion.moving():
		clip_pos = cadence.advance(distance, state_clip(_fighter), anim.length, _gait_scale)
	elif _crouch_exit_frames >= 0:
		clip_pos = minf(float(_crouch_exit_frames) * delta, anim.length)
	elif anim.loop_mode != Animation.LOOP_NONE:
		clip_pos = fmod(float(_state_frames) * delta, anim.length)
	elif _fighter.state == Fighter.State.GETUP:
		# tired get-up plays slower, stretched with getup_frames() (02 § Втома (г))
		clip_pos = minf(float(_state_frames) * delta / _fighter.fatigue_mult(Fighter.FATIGUE_GETUP), anim.length)
	else:
		clip_pos = minf(float(_state_frames) * delta, anim.length)
	# Undo our previous overlay before seeking: constant tracks may be absent in a clip.
	body_motion.restore_source(skeleton)
	_restore_attack_return_base()
	authored_hook.restore(skeleton)
	authored_dodge.restore(skeleton)
	authored_combat.restore(skeleton)
	SwordMotion.restore_mirror(skeleton, _sword_mirror_base)
	idle_presence.restore_base(skeleton)
	var procedural: bool = uses_procedural_motion()
	if _had_procedural_motion and not procedural and ragdoll == null:
		skeleton.reset_bone_poses()
	_had_procedural_motion = procedural
	locomotion.restore(skeleton)
	player.seek(clip_pos, true)
	locomotion.apply(skeleton, clip, delta)
	authored_combat.apply(skeleton, source, _fighter)
	authored_dodge.apply(skeleton, _fighter, delta)
	authored_hook.apply(skeleton, _fighter)
	_sword_mirror_base = SwordMotion.mirror_authored(skeleton, _fighter)
	var recovering: bool = HookMotion.recovery_active(_fighter)
	if procedural:
		MotionFallback.apply(skeleton, _fighter.animator)
	if ragdoll == null and not recovering and not RigAnimator.levitating(_fighter) and not locomotion.moving():
		idle_presence.apply(skeleton, _fighter, delta)
	_apply_attack_return(delta)
	body_motion.apply_source(skeleton)
	# Transitions start from what was actually drawn, including stance overlays.
	locomotion._last_output = _bone_poses()
	# State/rays advance at physics rate even when rendering is slower. Deferred
	# skeleton callbacks reapply the same cached frame; ragdoll remains modifier-led.
	if ragdoll == null:
		_on_mannequin_updated()


func _bone_poses() -> Array[Transform3D]:
	var poses: Array[Transform3D] = []
	for bone in skeleton.get_bone_count():
		poses.append(skeleton.get_bone_pose(bone))
	return poses


func _set_bone_pose(bone: int, pose: Transform3D) -> void:
	skeleton.set_bone_pose_position(bone, pose.origin)
	skeleton.set_bone_pose_rotation(bone, pose.basis.orthonormalized().get_rotation_quaternion())
	skeleton.set_bone_pose_scale(bone, pose.basis.get_scale())


func _restore_attack_return_base() -> void:
	for bone in _attack_return_base.size():
		_set_bone_pose(bone, _attack_return_base[bone])
	_attack_return_base.clear()


func _apply_attack_return(delta: float) -> void:
	if _attack_return_source.is_empty():
		return
	_attack_return_elapsed += maxf(delta, 0.0)
	if _attack_return_elapsed >= attack_return_seconds:
		_attack_return_source.clear()
		return
	_attack_return_base = _bone_poses()
	var weight: float = smoothstep(0.0, attack_return_seconds, _attack_return_elapsed)
	for bone in _attack_return_source.size():
		_set_bone_pose(bone, _attack_return_source[bone].interpolate_with(_attack_return_base[bone], weight))


func uses_procedural_motion() -> bool:
	if ragdoll != null:
		return false
	return RigAnimator.levitating(_fighter) or (_fighter.state == Fighter.State.ATTACK and MotionFallback.supports(_fighter.data.id, _fighter.current_move) and AuthoredCombat.resolve(_fighter.current_move, _fighter.data.id).is_empty())


func _on_mannequin_updated() -> void:
	# A queued skeleton update can arrive while the arena is being removed/replaced.
	if not is_inside_tree() or not is_instance_valid(_fighter) or not is_instance_valid(hero_skeleton):
		return
	if get_tree().paused or _fighter.frozen_frames > 0 or _fighter.hitstop_frames > 0:
		return
	retarget()
	if sword != null:
		SwordMotion.apply_transfer(hero_skeleton, _fighter)
		sword.update_pose()
	if gear != null:
		gear.update_pose()


## Aligned hand rest used to calibrate a prop; leaf hand rests differ between the two Meshy arms.
func aligned_hand_rest(side: String) -> Basis:
	if hero_skeleton != null:
		var bone := hero_skeleton.find_bone("RightHand" if side == "right" else "LeftHand")
		return Basis(_align.get(bone, Quaternion.IDENTITY)) * hero_skeleton.get_bone_global_rest(bone).basis.orthonormalized()
	return skeleton.get_bone_global_rest(skeleton.find_bone("hand_r" if side == "right" else "hand_l")).basis.orthonormalized()
