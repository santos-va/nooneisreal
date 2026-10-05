class_name CombatIntent
extends RefCounted
## One confirmed-normal continuation. Only the owner's attack hitstop pauses its age.
var action: String = ""
var age: int = 0
var history_revision: int = -1

func clear() -> void:
	action = ""
	age = 0

func update(player: int, eligible: bool, hitstop: bool, interrupted: bool, hands_busy: bool) -> void:
	var suppressed: bool = InputRouter.ui_suppressed()
	var revision: int = InputRouter.press_history_revision(player)
	if revision != history_revision:
		clear()
		history_revision = revision
	if interrupted or suppressed or not eligible:
		clear()
		return
	if not action.is_empty() and not hitstop:
		age += 1
		if age > InputRouter.BUFFER_FRAMES:
			clear()
	# Without a hitstop continuation, ordinary recovery buffering remains InputRouter's job.
	if not hitstop and action.is_empty():
		return
	var newest: String = ""
	var newest_age: int = InputRouter.BUFFER_FRAMES + 1
	for candidate: String in LimbMoves.ACTIONS:
		var candidate_age: int = InputRouter.buffered_age(player, candidate)
		if candidate_age < 0 or candidate_age > InputRouter.BUFFER_FRAMES:
			continue
		# Consume all competing fresh entries once; stable ACTIONS order resolves equal timestamps.
		InputRouter.buffered(player, candidate)
		if hands_busy and candidate.ends_with("hand"):
			continue
		if candidate_age < newest_age:
			newest = candidate
			newest_age = candidate_age
	if not newest.is_empty():
		action = newest
		age = newest_age

func take(player: int, requested: String) -> bool:
	if InputRouter.ui_suppressed() or history_revision != InputRouter.press_history_revision(player):
		clear()
	if action != requested or action.is_empty():
		return false
	clear()
	return true
