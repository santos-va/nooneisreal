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
