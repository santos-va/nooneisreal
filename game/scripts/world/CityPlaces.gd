class_name CityPlaces
extends RefCounted
## Authored district destinations shared by geometry, residents and player objectives.
## Distances are PLACEHOLDER design metres; doors are continuous physical openings.

static func shops() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var ids: Array[String] = ["grocer", "tailor", "workshop"]
	var titles: Array[String] = ["Крамниця «Шавлія»", "Ательє «Червона нитка»", "Майстерня «Мідна година»"]
	for index: int in 3:
		var x: float = -26.6 + float(index) * 6.6
		result.append({"id": ids[index], "title": titles[index], "npc_index": index,
			"door": Vector3(x, 0, 12), "approach": Vector3(x, 0, 10),
			"visit": Vector3(x, 0, 15.4), "worker": Vector3(x + 2.10, 0, 17.60), "service": Vector3(x + 2.10, 0, 16.40),
			"radius": 2.8, "door_width": 2.4, "door_height": 3.2,
			"bounds": AABB(Vector3(x - 3.1, 0, 12.2), Vector3(6.2, 4, 7.6)),
			"worker_path": [Vector3(x, 0, 10), Vector3(x, 0, 12), Vector3(x, 0, 15.4),
				Vector3(x, 0, 16.65), Vector3(x + 2.55, 0, 16.65), Vector3(x + 2.10, 0, 17.60)]})
	return result

static func worker_positions() -> Dictionary:
	var result: Dictionary = {}
	for shop: Dictionary in shops():
		result[shop.id] = shop.worker
	return result

static func landmarks() -> Array[Dictionary]:
	var result: Array[Dictionary] = [
		{"id": "clock_tower", "title": "Годинникова вежа", "position": Vector3(-24, 4, -19), "radius": 3.0},
		{"id": "roof_bridge", "title": "Міст дахів", "position": Vector3(0, 4, -20), "radius": 3.0},
		{"id": "market_court", "title": "Ринкова площа", "position": Vector3(0, 0, 20), "radius": 3.0},
	]
	for shop: Dictionary in shops():
		result.append({"id": shop.id, "title": shop.title, "position": shop.visit, "radius": shop.radius})
	return result
