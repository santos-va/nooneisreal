class_name LimbMoves
extends RefCounted
## T5 bounded normal strings, docs/GDD/02-Combat-System.md. All combat numbers come
## from existing character donors; these deterministic copies change presentation only.
const ACTIONS: Array[String] = ["left_hand", "right_hand", "left_leg", "right_leg"]

static func resolve(data: CharacterData, action: String, index: int, previous: String, crouching: bool, airborne: bool, active_hand: String = "", sequence: String = "") -> MoveData:
	if action not in ACTIONS:
		return null
	var foot := action.ends_with("leg")
	var donor: MoveData = data.heavy if foot else data.light
	var variant: String
	if airborne:
		donor = data.air_light
		variant = "airkick" if foot else "airhand"
	elif crouching:
		donor = data.crouch_light
		variant = "lowkick" if foot else "lowhand"
	elif foot:
		variant = ["frontkick", "roundhouse", "spin"][clampi(index, 0, 2)]
	elif index <= 0:
		variant = "jab"
	elif index == 1:
		variant = "bodyhook" if action == previous else "cross"
	else:
		variant = "uppercut"
	# Directional finishers are authored trajectories, not only a mirrored same pose.
	if not crouching and not airborne and index == 2:
		if sequence == "right_hand>left_hand>right_hand":
			variant = "hammer"
		elif sequence == "right_leg>left_leg>right_leg":
			variant = "hookspin"
	if donor == null:
		return null
	var move := donor.duplicate() as MoveData
	var family := "limb"
	if data.id == "choko" and data.weapon_kind == "sword" and action == active_hand + "_hand":
		family = "sword"
		variant = "aircut" if airborne else ("lowcut" if crouching else ["cut", "thrust", "rising"][clampi(index, 0, 2)])
		if not crouching and not airborne and sequence == "right_hand>left_hand>right_hand":
			variant = "cleave"
	move.id = "%s_%s_%s" % [family, action, variant]
	move.display_name = action.replace("_", " ").capitalize() + " · " + variant
	move.anim = move.id
	move.anim_chain = ""
	move.anim_clip = ""
	move.anim_clip_rec = ""
	move.anim_clip_chain = ""
	move.anim_clip_chain_rec = ""
	move.contact_time = 0.0
	move.contact_time_chain = 0.0
	return move
