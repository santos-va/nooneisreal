class_name CityParkourProfile
extends Resource
## PLACEHOLDER exploration tuning, pending play acceptance; never used by duel Fighter.
@export var reach_distance: float = 0.85
@export var reach_height: float = 2.05
@export var minimum_grip_height: float = 1.1
@export var hang_height: float = 1.42
@export var body_wall_offset: float = 0.43
@export var grip_half_width: float = 0.24
@export var top_inset: float = 0.12
@export var landing_inset: float = 0.65
@export var clearance: float = 0.035
@export var mantle_seconds: float = 0.5
@export var hang_seconds: float = 3.0
@export var wall_seconds: float = 0.65
@export var wall_up_speed: float = 5.0
@export var wall_along_speed: float = 4.0
@export var maximum_catch_fall_speed: float = 8.0
@export var minimum_wall_approach: float = 0.4
@export_group("Wall kick — PLACEHOLDER")
@export var wall_kick_up_speed: float = 7.4
@export var wall_kick_out_speed: float = 6.8
@export var wall_kick_seconds: float = 0.32
@export var minimum_kick_away: float = 0.4
@export_group("Landing roll — PLACEHOLDER")
@export var roll_min_fall_speed: float = 6.0
@export var roll_min_speed: float = 3.0
@export var roll_max_speed: float = 7.5
@export var roll_deceleration: float = 7.5
@export var roll_seconds: float = 0.6
@export var roll_min_floor_dot: float = 0.95
@export var roll_support_depth: float = 0.15
@export_group("Living-body moves — PLACEHOLDER (plan 2026-10-07-Living-Body step 2, T5 brief § 2.2)")
## «На бігу» for P1 and P4: the same floor as roll_min_speed.
@export var run_min_speed: float = 3.0
## P1 vault: an obstacle 0.6–1.3 m high and ≤ 0.8 m deep, crossed in 26 frames (SafetyVault ×1.7).
@export var vault_seconds: float = 26.0 / 60.0
@export var vault_min_height: float = 0.6
@export var vault_max_height: float = 1.3
@export var vault_max_depth: float = 0.8
## How far ahead the obstacle's face may be, and for how long after take-off the vault may still begin.
@export var vault_reach: float = 1.2
@export var vault_window_seconds: float = 0.15
## The floor beyond the obstacle is at the take-off level within this (brief: «опора на тому самому рівні»).
@export var vault_floor_tolerance: float = 0.2
## P4 side wall run: a jump along a wall (≤ 30° to it) on the run; Skea runs wall_seconds (39 frames), Choko 21.
@export var side_wall_max_angle: float = 30.0
@export var side_wall_short_seconds: float = 21.0 / 60.0
## The run starts once the jump has slowed to this rising speed (the apex window of J2) and holds that height.
@export var side_wall_start_rise: float = 2.0
## P5 ledge shimmy: left/right along the ledge in a hang; the hang timer keeps running.
@export var shimmy_speed: float = 1.2
