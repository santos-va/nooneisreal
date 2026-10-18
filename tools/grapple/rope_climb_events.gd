extends CityEventDirector
## Negative control for the passer-by's talk on the rope (T8 acceptance docs/Audit/2026-10-15-T8-Rope-Climb-Input-Acceptance.md
## ТЗ 1; tools/grapple/rope_climb_check.gd P10b). Never used by the game: CityWorld runs this script only when a fixture sets
## CityWorld.events_script before the world enters the tree. The mutation is read from the engine meta
## "rope_climb_mutation" (anything else: CityEventDirector byte for byte in behaviour).
##   passerby     — can_talk_to without the hook's check: the reach alone, as before the fix (the alley's, the leaves' and
##                  the pedlar's prompt shows on the rope and while a rope reels in, and their interact opens the menu);
##   alley_reach  — only the alley's asker is asked by the reach alone (T4 re-audit 15а Y-B: its prompt calling
##                  in_talk_reach instead of can_talk_to, T4's product mutant `alley_reach`); the other events as they are;
##   vendor_reach — the same for the pedlar (T4's `vendor_reach`).


func talk_blocked() -> bool:
	if String(Engine.get_meta("rope_climb_mutation", "")) == "passerby":
		return false
	return super.talk_blocked()


func can_talk_to(passerby: Node3D) -> bool:
	var mutation := String(Engine.get_meta("rope_climb_mutation", ""))
	if mutation in ["alley_reach", "vendor_reach"] and active != null and is_instance_valid(active) \
			and String(active.get("id")) + "_reach" == mutation:
		return in_talk_reach(passerby)
	return super.can_talk_to(passerby)
