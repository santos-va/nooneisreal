class_name DuelFrame
extends RefCounted
## Free movement (Prototype 0.3, GameState.free_move): the shared screen frame of a duel.
## `right` is the horizontal unit vector the duel camera shows as screen-right; it runs along the
## line between the fighters and turns with it. Movement input is read relative to it, so it is
## part of the simulation: updated once per physics frame from fighter positions (deterministic,
## docs/Decisions/ADR-004-Physics-Is-Presentation.md); the camera only reads it.
## Plan: docs/Plans/2026-10-03-Prototype-0.3-Free-Movement.md

## Below this separation the line between fighters has no direction; the last one is kept.
const MIN_LINE := 0.05

var right: Vector3 = Vector3.RIGHT
## ADR-015: solo vs CPU the camera stands behind P1. Then P1's stick is read in that camera's frame: y = toward
## the opponent along `line`, x = screen right (circling). P2 (CPU / pad) keeps the side frame. Set by Arena.
var behind: bool = false
## Unit P1 → P2 on the ground, never sign-flipped (behind P1 the view always looks at P2). Held like `right`.
var line: Vector3 = Vector3.RIGHT
var _frame: int = -1
var _hold: int = 0


## Keeps `right` as it is for `frames` physics frames (Flash Step: input stays in the pre-flash
## camera frame, docs/GDD/02-Combat-System.md § Камера дуелі, п. 4).
func hold(frames: int) -> void:
	_hold = maxi(_hold, frames)


func reset() -> void:
	right = Vector3.RIGHT
	line = Vector3.RIGHT   # `behind` stays: it is the match's camera mode, not round state
	_frame = -1
	_hold = 0


## Recomputes `right` from P1 → P2 once per physics frame (the first caller wins, later callers
## in the same frame get the cached value). The sign is kept continuous: when the fighters swap
## sides (a jump over, a flash-step through) the frame does not flip 180°, the sides swap on screen
## instead — like a side switch in a 2D fighter.
func sync(p1_pos: Vector3, p2_pos: Vector3, frame: int) -> void:
	if frame == _frame:
		return
	_frame = frame
	if _hold > 0:
		_hold -= 1
		return
	var d := Vector3(p2_pos.x - p1_pos.x, 0.0, p2_pos.z - p1_pos.z)
	if d.length() < MIN_LINE:
		return
	d = d.normalized()
	line = d
	right = d if d.dot(right) >= 0.0 else -d


## Screen-away direction (into the picture), perpendicular to `right` on the ground plane.
func depth() -> Vector3:
	return Vector3.UP.cross(right)


## Camera-relative stick → world direction on the ground plane (x = screen right, y = screen up).
## `player` 1 with `behind`: the camera behind P1 looks along `line`, so up = toward P2, right = line × up.
func to_world(move: Vector2, player: int = 0) -> Vector3:
	if behind and player == 1:
		return line.cross(Vector3.UP) * move.x + line * move.y
	return right * move.x + depth() * move.y
