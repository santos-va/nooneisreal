class_name WaveField
extends Resource
## Deterministic water surface for the river stage (docs/World/Stage-River.md).
## height(x) / slope(x) are a sum of three travelling sine waves along the fight axis plus a
## periodic "swell". Time is the WaveField's own physics-frame counter / 60, never wall-clock, so
## every machine sees the same surface on the same frame. The water shader (water_toon.gdshader)
## evaluates the identical formula from the uniforms that Water.gd copies out of this resource.
## Lives in scripts/core/ because both fighter/ and arena/ read it (no cross-imports between them).
## All numbers are PLACEHOLDER until T5 Арес / T3 Архімед ground them.

const FPS := 60.0

@export_group("Waves (PLACEHOLDER)")
@export var amplitudes: Vector3 = Vector3(0.06, 0.035, 0.018)     # metres
@export var wavelengths: Vector3 = Vector3(7.5, 3.3, 1.7)         # metres
@export var speeds: Vector3 = Vector3(1.1, -0.75, 1.5)            # metres / second (sign = direction)
@export var phases: Vector3 = Vector3(0.0, 1.7, 4.1)
@export var directions_deg: Vector3 = Vector3(0.0, 35.0, -50.0)  # travel direction in XZ, free movement only

## Free movement (GameState.free_move): waves use directions_deg and height depends on z. Set by Arena.
var use_z: bool = false

@export_group("Swell (PLACEHOLDER)")
@export var swell_every_min: float = 9.0      # seconds between swells (seeded RNG)
@export var swell_every_max: float = 12.0
@export var swell_frames: int = 40
@export var swell_amplitude: float = 0.14     # metres added on top of wave 0 at the swell's peak
@export var swell_strength_min: float = 0.45  # a fighter with water_balance below this stumbles
@export var swell_strength_max: float = 0.9
@export var stumble_frames: int = 14
@export var rng_seed: int = 4401

var frame: int = 0
var swell_strength: float = 0.0
var _swell_start: int = -1000
var _next_swell: int = 0
var _forced_strength: float = -1.0
var _rng := RandomNumberGenerator.new()


func reset(round_no: int = 1) -> void:
	frame = 0
	_swell_start = -1000
	swell_strength = 0.0
	_rng.seed = rng_seed + 7 * round_no
	_schedule()


func tick() -> void:
	frame += 1
	if frame >= _next_swell:
		var st := _forced_strength if _forced_strength >= 0.0 else _rng.randf_range(swell_strength_min, swell_strength_max)
		_forced_strength = -1.0
		start_swell(st)


## Test hook: the next tick starts a swell of exactly `strength` (smoke test).
func force_swell_next(strength: float) -> void:
	_next_swell = frame + 1
	_forced_strength = strength


func start_swell(strength: float) -> void:
	_swell_start = frame
	swell_strength = strength
	_schedule()


func time_s() -> float:
	return float(frame) / FPS


## 0 outside a swell, rises and falls as sin(pi * p) across swell_frames.
func swell_env() -> float:
	var p := float(frame - _swell_start) / float(swell_frames)
	if p < 0.0 or p > 1.0:
		return 0.0
	return sin(PI * p)


func swell_active() -> bool:
	return frame - _swell_start >= 0 and frame - _swell_start <= swell_frames


## True only on the first frame of a swell — the moment fighters may stumble.
func swell_started_now() -> bool:
	return frame == _swell_start


## Surface height at (x, z). In the plane (use_z off) z is ignored and every wave runs along +X,
## exactly as in 0.2. With use_z (free movement, 0.3-5) each wave travels along its own XZ direction
## (directions_deg), so the surface varies across the circle arena too.
func height(x: float, z: float = 0.0) -> float:
	var t := time_s()
	var h := 0.0
	for i in 3:
		var k := TAU / wavelengths[i]
		h += amplitudes[i] * sin(k * (_along(i, x, z) - speeds[i] * t) + phases[i])
	var k0 := TAU / wavelengths.x
	h += swell_amplitude * swell_env() * sin(k0 * (_along(0, x, z) - speeds.x * t) + phases.x + 1.2)
	return h


## ∂h/∂x — the slope along the fight line in the plane.
func slope(x: float, z: float = 0.0) -> float:
	return gradient(x, z).x


## (∂h/∂x, ∂h/∂z). In the plane the z component is 0.
func gradient(x: float, z: float = 0.0) -> Vector2:
	var t := time_s()
	var g := Vector2.ZERO
	for i in 3:
		var k := TAU / wavelengths[i]
		var c := amplitudes[i] * k * cos(k * (_along(i, x, z) - speeds[i] * t) + phases[i])
		g += _dir(i) * c
	var k0 := TAU / wavelengths.x
	g += _dir(0) * swell_amplitude * swell_env() * k0 * cos(k0 * (_along(0, x, z) - speeds.x * t) + phases.x + 1.2)
	return g


## Unit travel direction of wave i in XZ (x, z). Plane: always +X.
func _dir(i: int) -> Vector2:
	if not use_z:
		return Vector2(1.0, 0.0)
	var a := deg_to_rad(directions_deg[i])
	return Vector2(cos(a), sin(a))


## Position projected on wave i's direction. Plane: x itself (same arithmetic as 0.2).
func _along(i: int, x: float, z: float) -> float:
	if not use_z:
		return x
	var d := _dir(i)
	return d.x * x + d.y * z


## Lowest the surface can ever go — the stage puts its collision floor below this.
func min_height() -> float:
	return -(amplitudes.x + amplitudes.y + amplitudes.z + swell_amplitude)


func _schedule() -> void:
	_next_swell = frame + int(_rng.randf_range(swell_every_min, swell_every_max) * FPS)
