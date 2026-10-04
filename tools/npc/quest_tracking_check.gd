extends SceneTree
class Residents:
	extends Node3D
	var actors: Dictionary = {}
	var actor_states: Dictionary = {}
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("QUEST_TRACKING: " + label)
func _run() -> void:
	var model := CityProgress.new()
	model.setup("choko", false)
	model.save_enabled = false
	check(model.tracked_quest_id().is_empty() and CityQuestTargets.resolve(model).is_empty(), "new hero without accepted quest has no target")
	check(not model.track_quest("introductions") and not model.track_quest("invented"), "cannot track available or unknown quests")
	model.accept_quest("introductions")
	model.accept_quest("roof_walk")
	check(model.tracked_quest_id() == "introductions" and model.tracking_mode() == "auto", "legacy absent selection falls back to first eligible quest")
	check(model.track_quest("roof_walk") and model.summary().active_title == model.quest("roof_walk").title, "explicit quest controls HUD title")
	model.accept_quest("neighbours")
	check(model.tracked_quest_id() == "roof_walk", "accepting another quest preserves explicit selection")
	var target: Dictionary = CityQuestTargets.resolve(model, null, Vector3(0, 4, -20))
	check(target.id == "roof_bridge" and target.position == Vector3(0, 4, -20), "unvisited roof goal comes from actual CityPlaces")
	model.visit_landmark("roof_bridge")
	target = CityQuestTargets.resolve(model)
	check(target.id == "clock_tower", "visited roof point excluded from next goal")
	model.visit_landmark("clock_tower")
	check(CityQuestTargets.resolve(model).id == "workshop", "ready roof quest returns to giver")
	model.track_quest("introductions")
	var origin: Vector3 = CityPlaces.shops()[0].visit
	for index: int in 3:
		target = CityQuestTargets.resolve(model, null, origin)
		check(target.id == "resident_%02d" % index, "missing worker advances %d" % index)
		model.record_event("meet", "resident_%02d" % index)
	check(CityQuestTargets.resolve(model).id == "grocer", "ready introductions returns to actual grocer")
	model.complete_quest("introductions")
	check(model.tracked_quest_id() == "roof_walk" and model.tracking_mode() == "auto", "completed manual quest falls back without stale marker")
	check(not model.track_quest("introductions"), "completed quest cannot be selected")
	model.complete_quest("roof_walk")
	model.accept_quest("parcel")
	model.track_quest("parcel")
	check(CityQuestTargets.resolve(model).id == "tailor", "parcel action targets tailor")
	model.record_event("deliver", "thread_parcel")
	check(CityQuestTargets.resolve(model).id == "grocer", "delivered parcel targets giver")
	model.complete_quest("parcel")
	model.accept_quest("rope_route")
	model.track_quest("rope_route")
	var anchors: Array[Vector3] = CityLayout.anchors()
	check(CityQuestTargets.resolve(model, null, anchors[0]).id == "anchor_0", "nearest unused real anchor selected")
	model.record_event("rope", "anchor_0")
	target = CityQuestTargets.resolve(model, null, anchors[0])
	check(target.id != "anchor_0" and target.kind == "rope", "used anchor excluded")
	model.record_event("rope", "anchor_0")
	check(CityQuestTargets.resolve(model, null, anchors[0]).id == target.id, "repeat anchor cannot advance next target")
	model.record_event("rope", target.id)
	check(CityQuestTargets.resolve(model).id == "workshop", "two distinct contacts return to workshop")
	model.complete_quest("rope_route")
	model.track_quest("neighbours")
	var residents := Residents.new()
	root.add_child(residents)
	residents.position = Vector3(10, 0, 0)
	var actor := Node3D.new()
	residents.add_child(actor)
	actor.position = Vector3(0, 0, 0)
	residents.actors[3] = actor
	target = CityQuestTargets.resolve(model, residents, actor.global_position)
	check(target.id == "resident_03" and target.position == actor.global_position, "streamed resident uses live world position")
	actor.position.z = 2
	check(CityQuestTargets.resolve(model, residents, actor.global_position).position == actor.global_position, "guide follows moving resident")
	model.record_event("resident", "resident_03")
	check(CityQuestTargets.resolve(model, residents, actor.global_position).id != "resident_03", "already met resident excluded")
	residents.actor_states[4] = {"position": Vector3(2, 0, 2)}
	target = CityQuestTargets.resolve(model, residents, Vector3(12, 0, 2))
	check(target.id == "resident_04" and target.position == Vector3(12, 0, 2), "streamed-out resident uses transformed last known position")
	for index: int in range(4, 7):
		model.record_event("resident", "resident_%02d" % index)
	check(CityQuestTargets.resolve(model).id == "tailor", "four neighbours return to tailor")
	model.complete_quest("neighbours")
	model.accept_quest("own_style")
	model.track_quest("own_style")
	check(CityQuestTargets.resolve(model).id == "tailor", "missing palette action targets tailor first")
	model.set_palette("mint")
	check(CityQuestTargets.resolve(model).id == "market_court", "equipped palette advances to unvisited market")
	check(model.track_quest("") and model.summary().tracking_mode == "off" and CityQuestTargets.resolve(model).is_empty(), "explicit opt-out hides target")
	model.save_path = "user://quest_tracking_test.json"
	model.save_enabled = true
	check(model.persist(), "save explicit opt-out")
	var restored := CityProgress.new()
	restored.setup("choko", true, model.save_path)
	restored.save_enabled = false
	check(restored.tracking_mode() == "off" and restored.tracked_quest_id().is_empty(), "opt-out survives actual disk reload without fallback")
	model.save_enabled = false
	model.hero_id = "skea"
	model._ensure_hero()
	model.accept_quest("roof_walk")
	model.track_quest("roof_walk")
	check(model.tracked_quest_id() == "roof_walk" and model.heroes.choko.tracked_quest == "", "second hero has independent tracking")
	var stable: Dictionary = restored.snapshot()
	for wrong: Variant in [null, 7, "unknown", "introductions", "rope_route"]:
		var bad: Dictionary = stable.duplicate(true)
		bad.heroes.choko.tracked_quest = wrong
		check(not restored.restore(bad) and restored.snapshot() == stable, "invalid or completed tracking rejected atomically: " + str(wrong))
	for wrong_version: Variant in [true, "1", null]:
		var bad_version: Dictionary = stable.duplicate(true)
		bad_version.version = wrong_version
		check(not restored.restore(bad_version) and restored.snapshot() == stable, "wrong version type rejected without partial overwrite")
	var legacy: Dictionary = stable.duplicate(true)
	legacy.heroes.choko.erase("tracked_quest")
	check(restored.restore(legacy) and restored.tracked_quest_id() == "own_style", "old save without optional field migrates to eligible fallback")
	check(restored.track_quest("own_style"), "accepted active quest selectable after legacy load")
	var selected_save: Dictionary = restored.snapshot()
	check(restored.restore(JSON.parse_string(JSON.stringify(selected_save))) and restored.tracked_quest_id() == "own_style", "explicit selection survives JSON reload")
	restored.visit_landmark("market_court")
	check(CityQuestTargets.resolve(restored).id == "tailor", "ready style targets turn-in")
	restored.complete_quest("own_style")
	check(restored.tracked_quest_id().is_empty() and CityQuestTargets.resolve(restored).is_empty() and restored.summary().completed == 6, "all completed quests leave no marker")
	DirAccess.remove_absolute(model.save_path)
	residents.free()
	model.free()
	restored.free()
	print("[quest-tracking] %d checks / %d failures" % [checks, failures])
	quit(1 if failures else 0)
