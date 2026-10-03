class_name SkeletalRig
extends Node3D
## C1 mannequin (launch 4, docs/Plans/2026-10-03-Picks-to-Game-and-Animation.md § C1): the Quaternius UAL1 mannequin
## with the UAL1 + UAL2 Source clips (CC0, one 65-bone skeleton, so both libraries share one AnimationPlayer — no
## retarget until launch 5). On only with GameState.skeletal_rig (`-- --skeletal-rig`).
##
## The capsule RigAnimator keeps running underneath, with its meshes hidden: ragdoll, afterimages and the smoke still
## read its part_snapshot()/pose. This node is presentation only — it never moves the fighter or a hitbox.
## The player is driven by hand from _physics_process (it runs after Fighter's, parent first), so a clip's pose
## is a pure function of the fighter's frame counters: deterministic, and the contact pose lands on a known frame.
##
## Launch 5: with CharacterData.model_scene set, the hero GLB (Meshy auto-rig, 24 bones) is drawn instead. The
## mannequin keeps playing, hidden — it is the pose source (the smoke reads it) — and every physics frame its pose is
## copied onto the hero bone by bone (HERO_BONES). The Meshy rest is an A-pose, the UAL rest a T-pose, so each hero
## bone first gets a rest alignment (its rest direction turned onto the mannequin's), then the mannequin's rotation
## from rest. Bone lengths stay the hero's; only the hips move, scaled by the hip-height ratio.

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
	_hide_capsules()
	if f.data.model_scene != "":
		_setup_hero(f.data.model_scene)


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
	var hips := hero_skeleton.find_bone("Hips")
	_hip_scale = hero_skeleton.get_bone_global_rest(hips).origin.y / maxf(skeleton.get_bone_global_rest(skeleton.find_bone("pelvis")).origin.y, 1e-4)


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


## GLB clip this fighter state plays (attacks: the move's anim_clip; "" = hold the stance).
func state_clip(f: Fighter) -> String:
	match f.state:
		Fighter.State.ATTACK:
			if f.current_move == null:
				return ""
			var c := attack_clips(f.current_move, f.chain_index)
			var m := f.current_move
			return c[1] if c[1] != "" and f.move_frame >= m.startup + m.active else c[0]
		Fighter.State.WALK:
			var along := f.velocity.dot(f.forward) if GameState.free_move else f.velocity.x * float(f.facing)
			return STATE_CLIPS["walk_back"] if along < -0.1 else STATE_CLIPS["walk"]
		Fighter.State.CROUCH:
			return STATE_CLIPS["crouch"]
		Fighter.State.JUMP, Fighter.State.GRAPPLE:
			return STATE_CLIPS["jump"]
		Fighter.State.DASH:
			return f.data.dash_clip
		Fighter.State.BLOCK, Fighter.State.BLOCKSTUN:
			return STATE_CLIPS["block"]
		Fighter.State.HITSTUN, Fighter.State.STUMBLE:
			return STATE_CLIPS["hit_" + f.animator.flinch_zone] if STATE_CLIPS.has("hit_" + f.animator.flinch_zone) else STATE_CLIPS["hit_mid"]
		Fighter.State.LAUNCHED, Fighter.State.KNOCKDOWN, Fighter.State.WALL_SPLAT:
			return STATE_CLIPS["knockdown"]
		Fighter.State.GETUP:
			return f.data.getup_clip
		Fighter.State.KO:
			return STATE_CLIPS["ko"]
		Fighter.State.IDLE:
			if f.fatigue >= Fighter.FATIGUE_TIRED:
				return STATE_CLIPS["tired"]
	return f.data.idle_clip


func _physics_process(delta: float) -> void:
	if _fighter == null or player == null:
		return
	visible = _fighter.animator.visible
	rotation.y = _fighter.animator.rotation.y
	if _fighter.frozen_frames > 0 or _fighter.hitstop_frames > 0:
		return   # time stop / hitstop: hold the drawing
	if _fighter.state != _last_state:
		_last_state = _fighter.state
		_state_frames = 0
	else:
		_state_frames += 1
	var want := clip_name(state_clip(_fighter))
	if want == "":
		want = clip_name(_fighter.data.idle_clip)
	if want == "":
		return   # no stance clip either (bad .tres name — the smoke names it)
	var anim := player.get_animation(want)
	if want != clip:
		clip = want
		player.play(clip)
	if _fighter.state == Fighter.State.ATTACK and _fighter.current_move != null and clip_name(state_clip(_fighter)) == clip:
		var m := _fighter.current_move
		var c := attack_clips(m, _fighter.chain_index)
		var window := m.startup + m.active
		if c[1] != "" and _fighter.move_frame >= window:
			clip_pos = anim.length * clampf(float(_fighter.move_frame - window) / float(maxi(m.recovery, 1)), 0.0, 1.0)
		else:
			var span := window if c[1] != "" else window + m.recovery
			clip_pos = attack_clip_time(_fighter.move_frame, m.startup, span, anim.length, c[2])
	elif anim.loop_mode != Animation.LOOP_NONE:
		clip_pos = fmod(float(_state_frames) * delta, anim.length)
	elif _fighter.state == Fighter.State.GETUP:
		# tired get-up plays slower, stretched with getup_frames() (02 § Втома (г))
		clip_pos = minf(float(_state_frames) * delta / _fighter.fatigue_mult(Fighter.FATIGUE_GETUP), anim.length)
	else:
		clip_pos = minf(float(_state_frames) * delta, anim.length)
	player.seek(clip_pos, true)
	if hero_skeleton != null:
		retarget()
