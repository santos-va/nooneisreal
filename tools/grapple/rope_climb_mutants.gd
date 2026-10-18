extends GrappleHook
## Negative controls for the city rope's guards (plan 2026-10-15-Rope-Climb-Perch-Release step 5, 15а; T5
## docs/GDD/2026-10-15-Rope-Climb-Numbers.md § 8). Never used by the game: a fixture puts this script on a hero's
## GrappleHook node before the hero enters the tree (tools/grapple/rope_climb_fighter.gd, or weighted_swing_check.gd on
## its own body). Without a mutation the class is GrappleHook, byte for byte in behaviour.
## Each mutation is one product change a guard family must catch:
##   noreq     — Л-в: the rope climbs with nothing held (climb_input 0 read as +1);
##   perpetual — Е-1: every hanging tick the body's velocity × 1.01;
##   twosided  — Е-2/Е-3: a pump along the motion whatever the stick says, k 24 m/s² (T5 § 8);
##   boost     — Е-6: + 1 m/s along the motion on every let-go;
##   overlong  — the slide ignores the rope's deployed length;
##   stuck     — the slide does not let go when the feet touch a floor;
##   double    — П-2: the grip on the anchor refunds a second slot (an issued token returned on the same tick);
##   far       — П-4: the reel takes a rope up to 20 m from the hand, line or not;
##   hung      — П-4: the reel takes a rope somebody hangs on;
##   transfer_skip — ADR-028 п. 5: a transfer's new rope no longer passes the post just left (T3 s7b's cut back);
##   reel_range — ADR-028 п. 4: the reel takes a rope up to 16 m from the hand, the line still clear (T4 audit 15а RED-2 а);
##   reel_right — T6 acceptance 2026-10-15 § 9 п. 4: the reeled rope is drawn from the right hand again, not between both;
##   tail_stays — the same, п. 6: the pull-up draws the tail at its whole length (it no longer comes up to the hand);
##   instant    — the same, п. 6: the HUD counts the rope back on the grip's tick, not when its hook lands;
##   mute_deny  — T8 acceptance 2026-10-15 ТЗ 7: a refused traversal press never emits `denied` (the HUD says nothing).
var mutation: String = ""


func drive(delta: float, held: bool, reel_held: bool = false) -> void:
	if mutation == "noreq" and climb_enabled and climb_input == 0 and phase == Phase.HANG:
		climb_input = 1
	if mutation == "transfer_skip":
		_transfer_skip.clear()
	super.drive(delta, held, reel_held)
	if not attached or phase != Phase.HANG:
		return
	if mutation == "perpetual":
		fighter.velocity *= 1.01
	elif mutation == "twosided":
		var tangent := Vector3(fighter.velocity)
		if tangent.length() > 0.3:
			var wish := fighter.wish()
			fighter.velocity += tangent.normalized() * 24.0 * absf(wish.dot(tangent.normalized())) * delta


func _deny(reason: String) -> void:
	if mutation != "mute_deny":
		super._deny(reason)


func _draw_tail(delta: float, length: float = -1.0) -> void:
	super._draw_tail(delta, -1.0 if mutation == "tail_stays" else length)


func pending_return() -> int:
	return 0 if mutation == "instant" else super.pending_return()


func _physics_process(delta: float) -> void:
	if mutation != "reel_right":
		super._physics_process(delta)


func _draw_rope(a: Vector3, b: Vector3) -> void:
	if mutation != "reel_right":
		super._draw_rope(a, b)
		return
	var keep := reeling_in
	reeling_in = false
	super._draw_rope(a, b)
	reeling_in = keep


func slide_limit() -> float:
	return INF if mutation == "overlong" else super.slide_limit()


func _release(reached: bool) -> void:
	if mutation == "stuck" and slid_to_floor:
		slid_to_floor = false
		return
	var before := Vector3(fighter.velocity)
	super._release(reached)
	if mutation == "boost" and before.length() > 0.001:
		fighter.velocity = before + before.normalized() * 1.0


func _grip_anchor() -> void:
	super._grip_anchor()
	if mutation == "double":
		# One more slot of the owner comes back on the grip's tick: an issued token is minted and refunded at once.
		var extra := registry.issue(fighter.player_index)
		if extra != 0:
			registry.records.erase(extra)
			registry.capacities[fighter.player_index] = int(registry.capacities[fighter.player_index]) + 1
			registry._notify(fighter.player_index)


func reel_candidate() -> Dictionary:
	if mutation == "reel_range":
		var keep := range_m
		range_m = 16.0
		var found := super.reel_candidate()
		range_m = keep
		return found
	if mutation not in ["far", "hung"]:
		return super.reel_candidate()
	if registry == null or busy():
		return {}
	var hand := fighter.global_position + HAND
	var best: Dictionary = {}
	for key: int in registry.records:
		var record: Dictionary = registry.records[key]
		if not record.deployed or int(record.owner) != fighter.player_index:
			continue
		if mutation == "far" and hand.distance_to(record.anchor) > 20.0:
			continue
		if mutation == "hung" and (hand.distance_to(record.anchor) > range_m or not line_clear(hand, record.anchor)):
			continue
		var grip := registry.closest_grip(key, hand)
		if not grip.is_empty() and (best.is_empty() or float(grip.distance) < float(best.distance)):
			best = {"token": key, "distance": float(grip.distance), "anchor": record.anchor}
	return best


func begin_reel(key: int) -> bool:
	if mutation == "reel_range":
		var keep := range_m
		range_m = 16.0
		var began := super.begin_reel(key)
		range_m = keep
		return began
	if mutation not in ["far", "hung"]:
		return super.begin_reel(key)
	if key == 0 or busy() or not registry.records.has(key) or not registry.records[key].deployed:
		return false
	var anchor: Vector3 = registry.records[key].anchor
	# The refusals the guard expects are skipped: range and line for `far`, a rope in use for `hung`.
	if registry.records[key].has("marker") and is_instance_valid(registry.records[key].marker):
		registry.records[key].marker.remove_from_group("deployed_rope")
		registry.records[key].marker.queue_free()
	for id: int in registry.records[key].users.keys():
		var user: Node = registry.records[key].users[id].get_ref()
		if is_instance_valid(user) and user != self:
			user.detach()
	registry.records[key] = {"owner": fighter.player_index, "deployed": false}
	token = key
	projectile_position = anchor
	_flight_direction = (anchor - (fighter.global_position + HAND)).normalized()
	_begin_rewind()
	reeling_in = true
	return true
