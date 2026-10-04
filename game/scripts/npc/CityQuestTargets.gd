class_name CityQuestTargets
extends RefCounted
## World-space direction hints from remaining facts, never a path through geometry.

static func resolve(progress: CityProgress, director: Node = null, origin: Vector3 = Vector3.ZERO) -> Dictionary:
	if progress == null:
		return {}
	var selected: String = progress.tracked_quest_id()
	if selected.is_empty():
		return {}
	var definition: Dictionary = progress.quest(selected)
	if progress.quest_status(selected) == "ready":
		return _with_quest(_shop(definition.giver), selected)
	var candidates: Array[Dictionary] = []
	var events: Dictionary = progress.heroes[progress.hero_id].events
	for goal: Dictionary in definition.goals:
		if progress._count(goal) >= int(goal.count):
			continue
		var done: Array = events.get(goal.kind, [])
		match goal.kind:
			"meet", "resident":
				for index: int in NpcPopulation.COUNT:
					var id: String = "resident_%02d" % index
					if id in done or (goal.id != "*" and goal.id != id) or (goal.kind == "resident" and index < 3):
						continue
					if index < 3:
						var target: Dictionary = _shop(["grocer", "tailor", "workshop"][index])
						target.id = id
						candidates.append(target)
					else:
						candidates.append({"id": id, "title": "Поговорити: " + NpcPopulation.NAMES[index], "kind": "resident", "position": _resident_position(index, director)})
			"visit":
				for place: Dictionary in CityPlaces.landmarks():
					if place.id not in done and (goal.id == "*" or goal.id == place.id):
						candidates.append({"id": place.id, "title": place.title, "kind": "visit", "position": place.position})
			"deliver", "palette":
				# These actions are available only from the tailor's real dialogue.
				return _with_quest(_shop("tailor"), selected)
			"rope":
				var anchors: Array[Vector3] = CityLayout.anchors()
				for index: int in anchors.size():
					var id: String = "anchor_%d" % index
					if id not in done and (goal.id == "*" or goal.id == id):
						candidates.append({"id": id, "title": "Нова опора мотузки %d" % (index + 1), "kind": "rope", "position": anchors[index]})
	if candidates.is_empty():
		return {}
	var chosen: Dictionary = candidates[0]
	var best: float = origin.distance_squared_to(chosen.position)
	for candidate: Dictionary in candidates:
		var distance: float = origin.distance_squared_to(candidate.position)
		if distance < best:
			chosen = candidate
			best = distance
	return _with_quest(chosen, selected)

static func _shop(id: String) -> Dictionary:
	for shop: Dictionary in CityPlaces.shops():
		if shop.id == id:
			return {"id": id, "title": shop.title, "kind": "shop", "position": shop.visit}
	return {}

static func _with_quest(target: Dictionary, id: String) -> Dictionary:
	if target.is_empty():
		return {}
	target.quest_id = id
	return target

static func _resident_position(index: int, director: Node) -> Vector3:
	if director != null:
		var actors: Variant = director.get("actors")
		if actors is Dictionary and actors.has(index) and is_instance_valid(actors[index]) and actors[index] is Node3D:
			return actors[index].global_position
		var saved: Variant = director.get("actor_states")
		if saved is Dictionary and saved.has(index) and saved[index] is Dictionary and saved[index].get("position") is Vector3:
			return director.to_global(saved[index].position) if director is Node3D else saved[index].position
	var home: Vector3 = CityNpcActor.home_for(index)
	return director.to_global(home) if director is Node3D else home
