class_name LimbMoves
extends RefCounted
## T5 bounded normal strings, docs/GDD/02-Combat-System.md. All combat numbers come
## from existing character donors; these deterministic copies change presentation only.
const ACTIONS: Array[String] = ["left_hand", "right_hand", "left_leg", "right_leg"]

static func resolve(data: CharacterData, action: String, index: int, previous: String, crouching: bool, airborne: bool) -> MoveData:
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
	if donor == null:
		return null
	var move := donor.duplicate() as MoveData
	move.id = "limb_%s_%s" % [action, variant]
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
