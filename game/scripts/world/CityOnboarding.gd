class_name CityOnboarding
extends RefCounted
## Session-only guidance: completed actions are reported by the world, never by raw input.
signal changed

## PLACEHOLDER tutorial thresholds, not movement or combat balance.
const STEPS := [
	{"id": "move", "target": 3.0, "title": "1 / 4 · FIND YOUR FEET"},
	{"id": "look", "target": 0.35, "title": "2 / 4 · READ THE CITY"},
	{"id": "jump", "target": 1.0, "title": "3 / 4 · TAKE THE UPPER ROUTE"},
	{"id": "rope", "target": 1.0, "title": "4 / 4 · REACH AN ANCHOR"},
]

var step_index: int = 0
var progress: float = 0.0
var suspended: bool = false
var skipped: bool = false


func current_id() -> String:
	return "explore" if is_complete() else String(STEPS[step_index].id)


func is_complete() -> bool:
	return step_index >= STEPS.size()


func record_event(kind: String, amount: float = 1.0) -> void:
	if suspended or is_complete() or kind != current_id() or not is_finite(amount) or amount <= 0.0:
		return
	progress += amount
	if progress >= float(STEPS[step_index].target):
		step_index += 1
		progress = 0.0
		changed.emit()


func restart() -> void:
	step_index = 0
	progress = 0.0
	suspended = false
	skipped = false
	changed.emit()


func skip() -> void:
	step_index = STEPS.size()
	progress = 0.0
	skipped = true
	changed.emit()


func title() -> String:
	return "FREE EXPLORATION" if is_complete() else String(STEPS[step_index].title)
