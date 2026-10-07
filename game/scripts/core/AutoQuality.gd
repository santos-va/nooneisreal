class_name AutoQuality
extends Resource
## AUTO presentation policy (docs/GDD/06-UI-UX.md § DISPLAY, AUTO-якість, T8 table; plan
## docs/Plans/2026-10-07-Auto-Display-And-Quality.md § Рішення після кроків 1–3). Presentation only: no gameplay,
## input or clock reads this. Every number is a PLACEHOLDER from the T8 table unless marked «T2 PLACEHOLDER»;
## none is a device performance claim. The controller measures the wall-clock frame interval, not GPU time:
## Godot 4.7 Metal returns 0 for GPU timestamps (T3, rendering_device_driver_metal.cpp:2342-2345).

## Start scale by output megapixels: ≤ 2.1 (1080p) → 1.0 · ≤ 3.7 (1440p) → 0.85 · ≤ 8.3 (4K) → 0.67 · above → 0.5.
@export var start_steps_mpx: PackedFloat32Array = PackedFloat32Array([2.1, 3.7, 8.3])
@export var start_scales: PackedFloat32Array = PackedFloat32Array([1.0, 0.85, 0.67, 0.5])
@export var scale_floor: float = 0.5                 # plan: dynamic lower bound PLACEHOLDER 0.5
@export var scale_max: float = 1.0
@export var internal_ceiling_mpx: float = 8.3        # internal 3D ceiling 3840×2160: 8K starts and stays at 0.5
@export var step: float = 0.05
@export var target_frame_ms: float = 16.7            # 60 FPS target; project cap run/max_fps=120
@export var fast_ratio: float = 0.8                  # up only while frames are shorter than 80 % of the target
@export var slow_hold_s: float = 2.0                 # down: longer than the target for 2 s in a row
@export var fast_hold_s: float = 5.0                 # up: shorter than 80 % of the target for 5 s in a row
@export var min_interval_s: float = 3.0              # at least 3 s between changes
## T2 PLACEHOLDER: one long frame counts at most this much, so a loading hitch alone is not a slow trend,
## while a steady 3 FPS still steps down (each frame then adds 0.25 s).
@export var hitch_cap_ms: float = 250.0
## T2 PLACEHOLDER (T8 left MSAA in AUTO to T3; T3 did not set it): internal 3D ≤ 2.1 Mpx at start keeps MSAA 4×
## (1080p AUTO = the old High), anything larger starts with 2×. The controller never changes MSAA.
@export var msaa_full_mpx: float = 2.1
## T2 PLACEHOLDER: lethal-blood budget from the start level (T8: «бюджет крові за стартовим рівнем; посеред бою не
## змінюється»). Internal 3D rows at start (screen height × start scale) ≤ 810 → low, ≤ 918 → medium, else high:
## the manual Low/Medium scales at 1080p, where T6 drops the rim because tiny drops turn into stair noise.
@export var blood_rows_low: float = 810.0
@export var blood_rows_medium: float = 918.0
@export var label_round: float = 0.05                # the panel shows the scale rounded to 5 %

var scale: float = 1.0
var ceiling: float = 1.0
var msaa: int = Viewport.MSAA_4X
var blood_tier: String = "high"
var changes: int = 0
var _slow_s: float = 0.0
var _fast_s: float = 0.0
var _since_change_s: float = 1.0e9


func start_scale(pixels: int) -> float:
	var mpx := float(maxi(pixels, 0)) / 1.0e6
	for i: int in start_steps_mpx.size():
		if mpx <= start_steps_mpx[i]:
			return start_scales[i]
	return start_scales[start_scales.size() - 1]


## The largest scale that keeps the internal 3D image within the ceiling (unknown output → full scale).
func ceiling_for(pixels: int) -> float:
	if pixels <= 0:
		return scale_max
	return clampf(sqrt(internal_ceiling_mpx * 1.0e6 / float(pixels)), scale_floor, scale_max)


func seed_from(pixels: int) -> void:
	ceiling = ceiling_for(pixels)
	scale = minf(start_scale(pixels), ceiling)
	var internal_mpx := float(maxi(pixels, 0)) * scale * scale / 1.0e6
	msaa = Viewport.MSAA_4X if internal_mpx <= msaa_full_mpx else Viewport.MSAA_2X
	reset()


func blood_tier_for(screen_rows: int, start: float) -> String:
	if screen_rows <= 0:
		return "high"
	var rows := float(screen_rows) * start
	if rows <= blood_rows_low:
		return "low"
	if rows <= blood_rows_medium:
		return "medium"
	return "high"


func reset() -> void:
	_slow_s = 0.0
	_fast_s = 0.0
	_since_change_s = 1.0e9


## One frame of wall-clock time. `active` is false in pause, menus and modal UI: nothing accumulates there.
## Returns true when the scale changed.
func feed(frame_s: float, active: bool) -> bool:
	if not active or frame_s <= 0.0:
		_slow_s = 0.0
		_fast_s = 0.0
		return false
	var counted := minf(frame_s, hitch_cap_ms / 1000.0)
	_since_change_s += counted
	var ms := frame_s * 1000.0
	if ms > target_frame_ms:
		_slow_s += counted
		_fast_s = 0.0
	elif ms < target_frame_ms * fast_ratio:
		_fast_s += frame_s
		_slow_s = 0.0
	else:
		_slow_s = 0.0
		_fast_s = 0.0
	if _since_change_s < min_interval_s:
		return false
	var next := scale
	if _slow_s >= slow_hold_s:
		next = maxf(scale_floor, scale - step)
	elif _fast_s >= fast_hold_s:
		next = minf(ceiling, scale + step)
	next = snappedf(next, 0.001)
	if is_equal_approx(next, scale):
		return false
	scale = next
	_slow_s = 0.0
	_fast_s = 0.0
	_since_change_s = 0.0
	changes += 1
	return true


## Spatial upscaler only (T8 U1; plan p. 4): MetalFX spatial when the device reports it, otherwise FSR 1.0 in
## Forward+, otherwise bilinear. Availability is decided before the request because Viewport.get_scaling_3d_mode()
## returns the requested mode, not the effective one (T3, viewport.cpp:5056-5062). Temporal modes are never chosen.
static func pick_upscaler(rendering_method: String, has_rendering_device: bool, metalfx_spatial: bool) -> int:
	if not has_rendering_device or rendering_method == "gl_compatibility":
		return Viewport.SCALING_3D_MODE_BILINEAR
	if metalfx_spatial:
		return Viewport.SCALING_3D_MODE_METALFX_SPATIAL
	if rendering_method == "forward_plus":
		return Viewport.SCALING_3D_MODE_FSR
	return Viewport.SCALING_3D_MODE_BILINEAR


static func upscaler_name(mode: int) -> String:
	match mode:
		Viewport.SCALING_3D_MODE_FSR:
			return "FSR"
		Viewport.SCALING_3D_MODE_METALFX_SPATIAL:
			return "MetalFX"
	return ""


func percent() -> int:
	return roundi(snappedf(scale, label_round) * 100.0)
