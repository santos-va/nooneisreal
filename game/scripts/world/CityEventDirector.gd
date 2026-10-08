class_name CityEventDirector
extends Node3D
## «Випадки міста», stage 1 (plan 2026-10-08-City-Events-Stage-1, step 1; ADR-025; T7 brief § 2.3): short street events
## that happen by themselves. One event at a time; never in a conversation, a modal, a pause or a lethal fight; never
## near a fight pocket; never more often than the cooldowns; never in the first `grace_seconds` of a city session.
## The director draws only from its own RandomNumberGenerator (never the global one, never a fighter's), so a fixture
## with a seed replays the same city day. A scripted run (headless or --script) starts with the director off: a
## fixture switches it on with a seed (enable_for_test). Events use temporary passers-by (CityPasserby), never residents.
## Every number here is a PLACEHOLDER for T5/T7.
signal event_started(id: String)
signal event_finished(id: String, outcome: String)
signal conversation_started(actor: Node3D)
signal conversation_ended

const EVENTS: Array[String] = ["alley", "leaves"]
const ALLEY_SCRIPT := preload("res://scripts/world/CityAlleyEvent.gd")
const LEAVES_SCRIPT := preload("res://scripts/world/CityLeavesEvent.gd")
## The mouth of the southeast passage (CityLayout: wings x 10–18 and 22–30, z 12–30; lintel over z 12–16).
const PASSAGE_MOUTH := Vector3(20.0, 0.0, 11.0)
## В2 meets the hero near the market court or the roof bridge (T7 В2; CityPlaces.landmarks()).
const LEAVES_PLACES: Array[String] = ["market_court", "roof_bridge"]

@export var enabled: bool = true
@export var check_seconds: float = 1.0           # PLACEHOLDER: how often the director looks for a chance
@export var start_chance: float = 0.06           # PLACEHOLDER: chance per check while an event is possible
@export var grace_seconds: float = 90.0          # T_grace PLACEHOLDER: no event right after entering the city
@export var gap_seconds: float = 60.0            # PLACEHOLDER: quiet time after any event before the next one
@export var alley_cooldown_seconds: float = 240.0 # T_cooldown_alley PLACEHOLDER
@export var leaves_per_session: int = 1          # T7 В2: not more often than once a session (PLACEHOLDER)
@export var empty_radius: float = 8.0            # PLACEHOLDER: no resident this close — the street is empty
@export var pocket_margin: float = 6.0           # PLACEHOLDER: metres beyond a fight pocket's edge with no event
@export var alley_min_credits: int = 1           # PLACEHOLDER: the alley needs tokens to take
@export var alley_reach: float = 14.0            # PLACEHOLDER: hero within this of the passage mouth
@export var leaves_reach: float = 12.0           # PLACEHOLDER: hero within this of the market court / roof bridge

var rng := RandomNumberGenerator.new()
var world: Node
var player: CityFighter
var progress: CityProgress
var npc_director: CityNpcDirector
var lethal: Node
var haze: CityHaze
var content: Node
var camera: Camera3D
var dialogue: NpcDialogue
var active: Node = null
var session_time: float = 0.0
var last_end_time: float = -INF
var last_alley_time: float = -INF
var leaves_count: int = 0
var started: Array[String] = []        # every started id, in order (fixtures and the journal read it)
var outcomes: Array[String] = []       # "<id>:<outcome>" per finished event
var _check_left: float = 0.0
var _conversation_actor: Node3D = null


func setup(owner_world: Node) -> void:
	world = owner_world
	player = world.get("player")
	progress = world.get("progress")
	npc_director = world.get("npc_director")
	lethal = world.get("lethal")
	haze = world.get("haze")
	var rig: Node = world.get("camera_rig")
	camera = rig.get("camera") if rig != null else null
	content = get_node_or_null("/root/ContentSettings")
	rng.randomize()
	var graphics: Node = get_node_or_null("/root/GraphicsSettings")
	if graphics != null and bool(graphics.call("scripted_run")):
		enabled = false
	dialogue = NpcDialogue.new()
	dialogue.name = "EventDialogue"
	add_child(dialogue)
	dialogue.local_toggle.hide()
	dialogue.prompt.visible = false
	dialogue.choice_selected.connect(_on_choice)
	dialogue.closed.connect(_on_closed)
	if content != null:
		content.changed.connect(_on_content_changed)
	if lethal != null and lethal.has_signal("opened"):
		lethal.opened.connect(func() -> void: abort_active("lethal"))


## Fixtures: a seeded, enabled director (the rest of the rules stay as they are).
func enable_for_test(seed_value: int) -> void:
	rng.seed = seed_value
	enabled = true
	_check_left = 0.0


func _physics_process(delta: float) -> void:
	if player == null:
		return
	session_time += delta
	if active != null:
		return
	if not enabled:
		return
	_check_left -= delta
	if _check_left > 0.0:
		return
	_check_left = check_seconds
	var candidates: Array[String] = []
	for id: String in EVENTS:
		if block_reason(id).is_empty():
			candidates.append(id)
	if candidates.is_empty():
		return
	if rng.randf() >= start_chance:
		return
	start(candidates[rng.randi_range(0, candidates.size() - 1)])


## Why no event can start now ("" when every shared rule allows one). Fixtures and the journal read the reasons.
func common_block_reason() -> String:
	if not enabled:
		return "disabled"
	if active != null:
		return "active"
	if session_time < grace_seconds:
		return "grace"
	if session_time - last_end_time < gap_seconds:
		return "gap"
	if get_tree().paused:
		return "paused"
	if InputRouter.ui_suppressed():
		return "ui"
	if lethal != null and bool(lethal.get("active")):
		return "lethal"
	if npc_director != null and (npc_director.dialogue.opened or npc_director.fight_lock):
		return "conversation"
	if player.control_locked or not player.on_ground() or player.grapple.busy() \
			or player.state not in [Fighter.State.IDLE, Fighter.State.WALK]:
		return "busy"
	if near_pocket(player.global_position):
		return "pocket"
	return ""


func block_reason(id: String) -> String:
	var shared := common_block_reason()
	if not shared.is_empty():
		return shared
	var point: Vector3 = player.global_position
	if id == "alley":
		if session_time - last_alley_time < alley_cooldown_seconds:
			return "cooldown"
		if progress == null or int(progress.summary().credits) < alley_min_credits:
			return "credits"
		if residents_near(point, empty_radius) > 0:
			return "residents"
		if inside_passage(point) or Vector2(point.x - PASSAGE_MOUTH.x, point.z - PASSAGE_MOUTH.z).length() > alley_reach \
				or absf(point.y - PASSAGE_MOUTH.y) > 0.75 or not clear_line(point, PASSAGE_MOUTH):
			return "place"
		return ""
	if id == "leaves":
		if not drugs_allowed():
			return "content"
		if leaves_count >= leaves_per_session:
			return "session"
		for place: Dictionary in CityPlaces.landmarks():
			if place.id in LEAVES_PLACES and point.distance_to(place.position) <= leaves_reach:
				return ""
		return "place"
	return "unknown"


## ADR-025 Р4 / plan step 3: the `drugs` content key. Off removes the event completely.
func drugs_allowed() -> bool:
	return content != null and bool(content.call("drugs_allowed"))


func near_pocket(point: Vector3) -> bool:
	for pocket: Dictionary in CityLayout.combat_pockets():
		var center: Vector3 = pocket.center
		if Vector2(point.x - center.x, point.z - center.z).length() <= float(pocket.radius) + pocket_margin:
			return true
	return false


static func inside_passage(point: Vector3) -> bool:
	return point.x > 18.0 and point.x < 22.0 and point.z > 12.0 and point.z < 30.0


func residents_near(point: Vector3, radius: float) -> int:
	var count: int = 0
	if npc_director == null:
		return 0
	for index: int in npc_director.actors:
		var actor: Node3D = npc_director.actors[index]
		if is_instance_valid(actor) and Vector2(actor.global_position.x - point.x, actor.global_position.z - point.z).length() <= radius:
			count += 1
	return count


## A clear chest-height line on the ground between two points (no wall, no building).
func clear_line(from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from + Vector3.UP * 1.0, to + Vector3.UP * 1.0, 1)
	query.exclude = [player.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func out_of_view(point: Vector3) -> bool:
	if camera == null or not camera.is_inside_tree():
		return true
	return not camera.is_position_in_frustum(point + Vector3.UP * 1.0)


## Talk reach to a passer-by: the residents' hand reach (CityNpcDirector TALK_GAP / TALK_VERTICAL) and a free line.
func can_talk_to(passerby: Node3D) -> bool:
	if not is_instance_valid(passerby):
		return false
	var offset: Vector3 = passerby.global_position - player.global_position
	if absf(offset.y) > CityNpcDirector.TALK_VERTICAL or Vector2(offset.x, offset.z).length() > 1.0 + 0.35 + 0.30 + CityNpcDirector.TALK_GAP:
		return false
	return clear_line(player.global_position, passerby.global_position)


func spawn_passerby(seed_value: int, at: Vector3) -> CityPasserby:
	var person := CityPasserby.new()
	person.name = "Passerby%d" % (get_child_count())
	add_child(person)
	person.setup(seed_value)
	person.global_position = at
	return person


func start(id: String) -> bool:
	if active != null or id not in EVENTS:
		return false
	var event: Node = (ALLEY_SCRIPT if id == "alley" else LEAVES_SCRIPT).new()
	event.name = "Event_" + id
	add_child(event)
	active = event
	started.append(id)
	if id == "leaves":
		leaves_count += 1
	event.finished.connect(_on_finished.bind(id, event), CONNECT_ONE_SHOT)
	event.call("begin", self)
	event_started.emit(id)
	return true


## Fixtures and the shared rules: start `id` only when every rule allows it now (no chance roll).
func try_start(id: String) -> bool:
	if not block_reason(id).is_empty():
		return false
	return start(id)


func abort_active(reason: String) -> void:
	if active != null and is_instance_valid(active):
		active.call("abort", reason)


func _on_finished(outcome: String, id: String, event: Node) -> void:
	if active == event:
		active = null
	if dialogue.opened:
		dialogue.close()
	end_conversation()
	dialogue.prompt.visible = false
	last_end_time = session_time
	if id == "alley":
		last_alley_time = session_time
	outcomes.append(id + ":" + outcome)
	event.queue_free()
	event_finished.emit(id, outcome)


# --- the event's modal conversation (the same NpcDialogue as the residents, its own instance) ------------------------
## `close_label` names what Esc / B does in this menu; `guard` marks a menu the world opened (NpcDialogue.guard_seconds).
func show_choices(text: String, options: Array[Dictionary], actor: Node3D, close_label: String = NpcDialogue.CLOSE_LABEL, guard: bool = false) -> void:
	dialogue.show_choices(text, options, close_label, guard)
	if is_instance_valid(actor) and actor != _conversation_actor:
		_conversation_actor = actor
		conversation_started.emit(actor)


func end_conversation() -> void:
	if _conversation_actor != null:
		_conversation_actor = null
		conversation_ended.emit()


func _on_choice(action: String) -> void:
	if active != null and dialogue.opened:
		active.call("choose", action)


func _on_closed() -> void:
	end_conversation()
	if active != null:
		active.call("dialogue_closed")


func _on_content_changed(key: String, _value: Variant) -> void:
	if key == "drugs" and not drugs_allowed():
		# Off removes the event completely: the passer-by, its leaves and the state it caused.
		if active != null and active.get("id") == "leaves":
			abort_active("content")
		if haze != null:
			haze.clear()


func _exit_tree() -> void:
	if dialogue != null and dialogue.opened:
		dialogue.close()
