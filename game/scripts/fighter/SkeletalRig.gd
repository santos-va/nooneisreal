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

const MANNEQUIN := "res://assets/animations/ual/UAL1.glb"
const EXTRA_LIBRARY := "res://assets/animations/ual/UAL2.glb"
const EXTRA_PREFIX := "ual2"
## Clips per fighter state — docs/GDD/02-Combat-System.md § Кліп → удар, «Спільні стани» (T5 Арес). Names are the
## GLB names; Godot's importer drops the `_Loop` suffix and loops the clip, so clip_name() maps them.
## HITSTUN low has no clip in GDD 02 (capsule flinch spring) — it uses mid until table 4a says otherwise.
const STATE_CLIPS := {
	"walk": "Walk_Loop",
	"walk_back": "Walk_Bwd_Loop",
	"crouch": "Crouch_Idle_Loop",
	"jump": "Jump_Loop",
	"dash": "Roll",
	"block": "Sword_Block",
	"hit_high": "Hit_Head",
	"hit_mid": "Hit_Chest",
	"hit_low": "Hit_Chest",
	"knockdown": "Hit_Knockback",
	"getup": "LayToIdle",
	"ko": "Death01",
}
## The model faces +Z; the capsule rig (and every hitbox_offset) faces +X.
const MODEL_YAW := PI / 2.0

var player: AnimationPlayer
var skeleton: Skeleton3D
var clip: String = ""            # resolved name now on the player ("" = none)
var clip_pos: float = 0.0        # seconds into `clip` after this frame
var _fighter: Fighter
var _state_frames: int = 0
var _last_state: int = -1


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


## Clip time for attack frame `frame` (0 = first startup frame). Startup maps 0 → `contact`, so the contact pose is
## on the first active frame; active + recovery map `contact` → the clip's end. Without a measured contact time the
## clip spans startup + active (GDD 02 § Кліп → удар) and recovery holds its last pose.
static func attack_clip_time(frame: int, startup: int, active: int, recovery: int, length: float, contact: float) -> float:
	if length <= 0.0:
		return 0.0
	if contact <= 0.0 or contact >= length:
		var window := maxi(startup + active, 1)
		return clampf(float(frame) / float(window), 0.0, 1.0) * length
	if frame <= startup:
		return contact * float(frame) / float(maxi(startup, 1))
	var rest := maxi(active + recovery, 1)
	return contact + (length - contact) * clampf(float(frame - startup) / float(rest), 0.0, 1.0)


## GLB clip this fighter state plays (attacks: the move's anim_clip; "" = hold the stance).
func state_clip(f: Fighter) -> String:
	match f.state:
		Fighter.State.ATTACK:
			return f.current_move.anim_clip if f.current_move != null else ""
		Fighter.State.WALK:
			var along := f.velocity.dot(f.forward) if GameState.free_move else f.velocity.x * float(f.facing)
			return STATE_CLIPS["walk_back"] if along < -0.1 else STATE_CLIPS["walk"]
		Fighter.State.CROUCH:
			return STATE_CLIPS["crouch"]
		Fighter.State.JUMP, Fighter.State.GRAPPLE:
			return STATE_CLIPS["jump"]
		Fighter.State.DASH:
			return STATE_CLIPS["dash"]
		Fighter.State.BLOCK, Fighter.State.BLOCKSTUN:
			return STATE_CLIPS["block"]
		Fighter.State.HITSTUN, Fighter.State.STUMBLE:
			return STATE_CLIPS["hit_" + f.animator.flinch_zone] if STATE_CLIPS.has("hit_" + f.animator.flinch_zone) else STATE_CLIPS["hit_mid"]
		Fighter.State.LAUNCHED, Fighter.State.KNOCKDOWN, Fighter.State.WALL_SPLAT:
			return STATE_CLIPS["knockdown"]
		Fighter.State.GETUP:
			return STATE_CLIPS["getup"]
		Fighter.State.KO:
			return STATE_CLIPS["ko"]
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
	var anim := player.get_animation(want)
	if want != clip:
		clip = want
		player.play(clip)
	if _fighter.state == Fighter.State.ATTACK and _fighter.current_move != null:
		var m := _fighter.current_move
		clip_pos = attack_clip_time(_fighter.move_frame, m.startup, m.active, m.recovery, anim.length, m.contact_time)
	elif anim.loop_mode != Animation.LOOP_NONE:
		clip_pos = fmod(float(_state_frames) * delta, anim.length)
	else:
		clip_pos = minf(float(_state_frames) * delta, anim.length)
	player.seek(clip_pos, true)
