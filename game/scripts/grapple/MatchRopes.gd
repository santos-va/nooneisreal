class_name MatchRopes
extends Node3D
## Match lifetime authority. An immutable owner and one token per issued harpoon.
## Decorative nodes never allocate, consume or refund inventory.
var records: Dictionary = {}
var capacities: Dictionary = {}
var _hooks: Dictionary = {}
var _next_token: int = 1

func register_hook(hook: Node, player: int, capacity: int) -> void:
	if not capacities.has(player):
		capacities[player] = capacity
	var old_hook: Node = _hooks[player].get_ref() if _hooks.has(player) else null
	if is_instance_valid(old_hook) and old_hook != hook:
		old_hook.on_match_cleared()
	# Replacing a fighter returns its unfinished shot; deployed property stays match-owned.
	for token: int in records.keys():
		if records[token].owner == player and not records[token].deployed:
			records.erase(token)
	_hooks[player] = weakref(hook)
	_notify(player)

func available(player: int) -> int:
	return int(capacities.get(player, 0)) - owned(player)

func owned(player: int) -> int:
	var count: int = 0
	for record: Dictionary in records.values():
		if record.owner == player:
			count += 1
	return count

func issue(player: int) -> int:
	if available(player) <= 0:
		return 0
	var token := _next_token
	_next_token += 1
	records[token] = {"owner": player, "deployed": false}
	_notify(player)
	return token

func refund(token: int, player: int) -> bool:
	if not records.has(token) or records[token].owner != player or records[token].deployed:
		return false
	records.erase(token)
	_notify(player)
	return true

func deploy(token: int, player: int, anchor: Vector3, _tail: Vector3, length: float) -> bool:
	if not records.has(token) or records[token].owner != player or records[token].deployed:
		return false
	var marker := Node3D.new()
	marker.name = "Rope%d" % token
	add_child(marker)
	marker.global_position = anchor
	marker.add_to_group("deployed_rope")
	marker.set_meta("rope_token", token)
	var record: Dictionary = records[token]
	record.deployed = true
	record.anchor = anchor
	record.tail = Vector3(anchor.x, maxf(anchor.y - length, -1.5 if GameState.water != null else 0.05), anchor.z)
	record.users = {}
	record.length = length
	record.marker = marker
	var visual_script: Script = load("res://scripts/grapple/RopeVisual.gd") if ResourceLoader.exists("res://scripts/grapple/RopeVisual.gd") else null
	if visual_script != null:
		var visual: Node3D = visual_script.new()
		marker.add_child(visual)
		record.visual = visual
	_notify(player)
	return true

func nearby(point: Vector3, max_distance: float = 2.0) -> int:
	var selected: int = 0
	var best := max_distance
	for key: int in records:
		var record: Dictionary = records[key]
		if not record.deployed:
			continue
		var near := Geometry3D.get_closest_point_to_segment(point, record.anchor, record.tail)
		var distance := point.distance_to(near)
		if distance < best:
			best = distance
			selected = key
	return selected

func attach_user(token: int, hook: Node) -> void:
	if records.has(token) and records[token].deployed:
		records[token].users[hook.get_instance_id()] = weakref(hook)

func detach_user(token: int, hook: Node) -> void:
	if records.has(token) and records[token].deployed:
		records[token].users.erase(hook.get_instance_id())

func visual_active(record: Dictionary) -> bool:
	for id: int in record.users.keys():
		var user: Node = record.users[id].get_ref()
		if is_instance_valid(user) and user.attached:
			return false
		record.users.erase(id)
	return true

func clear_match() -> void:
	for record: Dictionary in records.values():
		if record.has("marker") and is_instance_valid(record.marker):
			record.marker.queue_free()
	records.clear()
	for player: int in capacities:
		var hook: Node = _hooks[player].get_ref() if _hooks.has(player) else null
		if is_instance_valid(hook):
			hook.on_match_cleared()
		_notify(player)

func _notify(player: int) -> void:
	if _hooks.has(player):
		var hook: Node = _hooks[player].get_ref()
		if is_instance_valid(hook):
			hook.inventory_changed(available(player), int(capacities[player]))

func _physics_process(delta: float) -> void:
	for record: Dictionary in records.values():
		if record.deployed and record.has("visual") and is_instance_valid(record.visual):
			record.visual.visible = visual_active(record)
			if not record.visual.visible:
				continue
			record.visual.update_rope(record.anchor, record.tail, record.length, delta, GameState.water, true)
