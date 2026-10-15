extends SceneTree
## Plan docs/Plans/2026-10-09-City-Tidy-And-Modern-Props.md, phase 0 (steps 0a and 0b), on the real CityWorld.
## Subject: for every visible part of the district — none enters a window pane, every prop rests on what is under it or
## hangs from the structure, no two faces of different materials flicker in one plane, nothing exists twice, and the
## hero is stopped wherever a visible part stands in his way; the new props keep the T6 places and both heroes vault the
## new obstacles with real keys.
##   C1 pane    — no prop or anchor support goes more than 2 cm (SAT over oriented boxes) into a window pane (the audit
##                compares props with structure, never structure with structure);
##   C2 support — a prop with something under it (≥ 20 % of its footprint, up to 0.3 m) rests within 2 cm of it, neither
##                floating nor sunk — unless it is fixed to a wall beside it (a structure within 2 cm rising over its
##                foot) and stands clearly off the floor (≥ 0.1 m, T6 П4), when only sinking counts; a prop with nothing
##                under it hangs, through touching parts, from the structure;
##   D17/19/24  — a hero (r 0.35, Fighter.tscn) stands free at every shop's approach, visit and service point; each solid
##                balcony side has ≥ 3 balusters inside it; the street faces of the end shop walls are street material;
##   C3 zfight  — no two faces of different materials face the same way in one plane (< 6 mm apart) over ≥ 2 cm² where
##                the patch shows (not inside a third box within 0.1 m, not under the ground);
##   C4 dup     — no two visible parts (kind, centre, extent) and no two colliders (shape, transform) are equal to 1 mm;
##   C5 solid   — a part in the hero band (floor + 0.12…1.8 m, ≥ 0.08 m wide, ≥ 0.4 l) that ≤ 13 of its 27 points have in
##                a collider can never be entered 0.1 m deep by a free hero capsule (r 0.32, h 1.8) standing on that floor
##                (within 0.3 m of it: walking, not standing on furniture);
##   K          — new props ≥ 8 m from the court centre, pockets empty, ≥ 1 m from resident lanes; the southeast passage
##                keeps its 4 m, its axis and event points and its camera, its pipes ≤ 0.25 m out of the wall and ≥ 3.2 m
##                up; every anchor keeps the floor its rope fell to on 97675c7 (anchor 5: the street, its canopy rolled)
##                and no new collider stands in its column;
##                obstacles 0.9–1.1 m high, ≤ 0.8 m deep, level floor on both sides; no `ink` surface wider than 0.2 m
##                and no long ink strip on the street; no letters in the props; groups of ≤ 5, ≤ 3 of a kind; one mesh
##                per material and no light in the props;
##   V          — Choko and Skea vault every obstacle from each side with a free run-up, by real key events (W, Space):
##                vault_seconds of the shipped profile ± 1 tick, no hang, landing beyond at the take-off level;
##   V+         — every solid body that stands on the floor with a flat top 0.6–1.3 m over it (a stack counts by its
##                top) is either a vault obstacle (vaulted in V) or a step listed in STEP_PROPS, which T6 accepts (T4 audit
##                2026-10-09 proposal 8, plan 2026-10-14-Quality-Debt-Posts-Awning-Guards step 4); a listed step that is
##                no longer there fails too; and no listed step wedges a hero on its rim (T6 К7-а п. 2): a hero capsule
##                standing on the top that walks to a solid rising over it within 0.05–0.75 m of the edge and steps off
##                rests on the top (≤ 0.05 m under it) or off the step — never on its rim with the feet in the air
##                (wedges a T1 decision left open are pinned in STEP_WEDGE_OPEN and must stay as measured);
##   S          — each steam vent puffs (≤ 0.8 opacity), changes frame under 3 times a second, never jumps in opacity
##                by more than 0.1 a frame, stays ≤ 1.0 × 1.5 m and is gone while a hero stands at the vent;
##   M          — the steam vehicles (CityProps.VEHICLES, Blender GLBs; docs/Fix/2026-10-09-City-Vehicles-And-Iron-Paint
##                -Fix.md). For every vehicle: M1 one visible mesh, its imported hulls are city solids (layer 9, mask 0)
##                with a live shape each; M2 every surface is the city material its GLB names; M3 it rests on a level
##                floor within 2 cm, neither floating nor sunk; M4 no visible face in the hero band stands 0.1 m out of
##                every collider (a free hero capsule there would walk into the mesh, the C5 rule per face); M5 out of
##                every anchor's 0.75 m column, and a free swing on every rope (T5: L = max(2, y_a − y_floor − 1.25 −
##                0.5), feet 1.25 under the hand, body r 0.35) passes ≥ 0.3 m over it; M6 ≥ 8 m from the court centre,
##                out of every pocket, ≥ 1 m from every resident lane; M7 out of both run-ups of every vault obstacle;
##                M8 the camera arm keeps ≥ 3 m for a hero 1.2 m off each open side facing the vehicle and on its roof
##                facing each way; V-M both heroes run at each open side with W and Space: no vault (deeper than any
##                obstacle: no false promise, К7), never left inside its footprint below its top.
##   MC         — the terrace machines (CityProps.MACHINES: the steam crane № 10 and the steam winch № 11, Blender GLBs;
##                docs/Fix/2026-10-14-Steam-Crane-Winch-Fix.md). A machine's foot is its hulls that stand on the floor
##                (the crane's plinth, never its boom over the street). For every machine: MC1 one visible mesh, exactly
##                the hulls of the T6 form, each a city solid (layer 9, mask 0) with a live shape; MC2 every surface is the
##                city material its GLB names, and no key the form bans (the crane: brass, ink; the winch: ink); MC3 the
##                foot rests on a level floor within 2 cm; MC4 the M4 rule for every visible face in the hero band; MC5 out
##                of every anchor's column, every free rope swing passes ≥ 0.3 m under or over every visible point it
##                reaches (the swing hangs under the anchor: a point above the anchor never meets it), and every visible
##                part keeps ≥ 2 m from every anchor's point and mount; MC6 ≥ 8 m from the court centre, out of every pocket, and
##                nothing of it within a resident's walking band (lane floor + 1.8 m) comes within 1 m of the lane; MC7
##                nothing solid over the street (every hull within the block its foot stands on), and at the street
##                stations S2, S3, S4 of the T6 form (a hero facing north) the machines change nothing for the camera:
##                the same arm with and without them, no machine face between the lens and the hero, and at S3 (under
##                the boom) the arm keeps 6.00 m; of the machine points in the frame, those the lens sees (a ray from it)
##                all stand at or above the terrace's level, 4.0 m (T6's A5, docs/Audit/2026-10-14-T6-Crane-Winch-
##                Acceptance.md § 3 п. 1: «з вулиці видно лише частини вище рівня тераси (seen_y ≥ 4,0 м)»; the form's
##                «на S3 його в кадрі немає» was dropped there — the column over the terrace's edge is in the frame); MC8 the
##                camera arm keeps ≥ 3 m for a hero 1.2 m off
##                each open side of the foot facing it (M8); MC9 every foot hull leaves 0 or ≥ 1.2 m on each side to
##                whatever stops the hero beside it — a solid or the floor's edge (a slot between them wedges a hero);
##                MC10 the visible triangles stay within the ceiling (the crane ≤ 5646, the winch ≤ 2000); V-MC both
##                heroes run at each open side of the winch with W and Space: no vault, never left inside it.
## Literals: docs/Audit/2026-10-08-City-Tidy-Technical-Audit.md § 2 (2 cm, 0.3 m, 20 %, 6 mm, 2 cm², 0.1 m, 1 mm, r 0.32,
## 0.12–1.8 m, 13/27, 0.08 m, 0.4 l); docs/Art/2026-10-08-City-Modern-Realism-Props.md (П4 0.1 m, К4 0.2 m, К6 8 m / 1 m,
## Н7 0.25 m / 3.2 m, К8 5 / 3); the plan (obstacles 0.9–1.1 m, ≤ 0.8 m); 2026-10-07-Tight-Station-Readability-Criteria
## (≥ 3 m of camera); WCAG 2.3.1 (< 3 flashes a second). The anchor floors were measured on 97675c7 (see ANCHOR_FLOOR).
## --break=<m> is a negative control: one returned defect or another form of the same class (see MUTATIONS); sentinel
## CITY_TIDY_COMPLETE checks=N failures=M mutation=<m>; failures print "CITY_TIDY: ...".
const DT: float = 1.0 / 60.0
const GEOMETRY_BREAKS := ["pane_strut", "pane_wire", "float_barrel", "float_loaf", "sink_crate", "float_plate",
	"zfight_fascia", "zfight_jamb", "dup_wall", "dup_barrel", "solid_planter", "solid_dressform", "solid_sign", "service",
	"pump_spout", "pump_lever", "pump_layer"]
const PLACE_BREAKS := ["court", "anchor", "passage", "lane", "ink_strip"]
const VAULT_BREAKS := ["vault_high", "vault_deep"]
const STEAM_BREAKS := ["steam_hero", "steam_flash"]
## Vehicle negatives (M): the truck 5 cm up, the car 5 cm down, the truck's boiler hull gone, the truck's mesh 0.3 m off
## its hulls, both vehicles' hulls on the cover layer only, one surface back to the GLB's own material, the truck under
## anchor 9, the car in resident 10's lane, the truck on crates_east's north run-up, the car 1.7 m off the ramp (a
## camera station with the ramp behind it); the parkour profile allowed 3 m deep vaults (a vault over a vehicle).
const VEHICLE_BREAKS := ["vehicle_float", "vehicle_sink", "vehicle_nocollider", "vehicle_shift", "vehicle_layer",
	"vehicle_material", "vehicle_anchor", "vehicle_lane", "vehicle_runup", "vehicle_gap"]
const VEHICLE_RUN_BREAKS := ["vehicle_vault"]
## V+ negatives: a new unlisted 1.0 m crate on the street, one at the bottom literal 0.6 m, a listed step moved 0.3 m.
## V+ wedge negatives, one form each of «no rim between a step and a solid within the band»: a wall put 0.55 m off a free
## side of a street urn (a wall comes to a step); the grocer's display crate given a round top of its own depth, the
## same 0.32 m off the shop wall that its flat edge stands on (a round rim); a wall 0.66 m off a free side of the tailor's
## cutting table, just under the capsule's width (the band's deep end); a pinned OPEN wedge whose wall's collider is
## off (an OPEN that is gone must go red too).
const STEP_BREAKS := ["step_new", "step_low", "step_moved", "wedge_wall", "wedge_round", "wedge_deep", "wedge_open"]
## Machine negatives (MC): the hulls on the cover layer only; a winch surface off its city material; a crane surface
## named and painted brass; the winch 5 cm up, the crane 5 cm down; the winch's body hull gone; the crane's mesh 0.3 m off
## its hulls; the winch under anchor 24; the crane 1.1 m from anchor 12's vertical; the winch in the east terrace pocket
## and in resident 10's lane; a hull under the boom over the street; the crane on the street between the S3 hero and
## the lens, and sunk so that its hook (no hull) hangs across that line; the winch 1.7 m from the house (a camera
## station with the facade behind it)
## and 0.5 m from the terrace's edge; the winch's mesh with every surface twice; its listed step moved 0.3 m. V-MC: the
## winch's body a flat box and the profile allowing 1.2 m deep vaults.
const MACHINE_BREAKS := ["machine_layer", "machine_material", "machine_brass", "machine_float", "machine_sink",
	"machine_nocollider", "machine_shift", "machine_column", "machine_anchor", "machine_pocket", "machine_lane",
	"machine_street_hull", "machine_cross", "machine_occlude", "machine_gap", "machine_slot", "machine_budget",
	"machine_step", "machine_seen_hook", "machine_seen_street", "machine_seen_float"]
## MC7 seen_y negatives (A5), one form each of «a street lens sees a machine point under the terrace's level»: decor of
## the crane, standing where it stands, hangs under the level over the street (no hull; MC3 sees its box's bottom too);
## the crane stands on the street floor in the S2–S4 view (every other guard holds: only seen_y goes red); the winch
## hangs in front of the terrace's wall with no floor.
const MACHINE_RUN_BREAKS := ["machine_vault"]
## MC literals. The hulls (docs/Art/2026-10-14-Steam-Crane-Winch-Form.md § Колізії, both tables) and the keys the form
## bans (§ Матеріали, A2); the triangle ceilings «≤ 5646 / 2000» of plan 2026-10-14-T6-Acceptance-Crane-Albedo-AB,
## step 4 (5 646 is the truck's, docs/Art/Textures-Registry.md prop-steam-truck-v1; the form's A1 the same); a slot «0 or ≥ 1.2 m»
## (form § Простір, PLACEHOLDER: a hero wedged in the 0.5 m slot by the truck, CityProps.gd:41–42), 0 meaning ≤ 2 cm
## (SUPPORT_GAP); ≥ 2 m from an anchor ([К] № 10 «≥ 2 м від якоря 12 (26; 4; −11)», the support's mount,
## docs/Art/2026-10-08-City-Modern-Realism-Props.md:286; the form's A7 «від точки якоря 12», its point: both, for every
## anchor); the street stations S2–S4 of the form's camera table (§ Камера); the
## crane's arm at S3 6.00 m (A5). A foot hull stands within 0.25 m of the floor (the winch's flywheel hangs 0.18 over it).
const MACHINE_HULLS := {"steam_crane": ["CraneCab", "CraneColumn", "CranePlinth"], "steam_winch": ["WinchBody", "WinchFlywheel"]}
const MACHINE_BANNED := {"steam_crane": ["brass", "ink"], "steam_winch": ["ink"]}
const MACHINE_TRIANGLES := {"steam_crane": 5646, "steam_winch": 2000}
const MACHINE_RUNS := ["steam_winch"]
const MACHINE_FOOT: float = 0.25
const SLOT_MIN: float = 1.2
const SLOT_STEP: float = 0.04       # MC9 measures with 4 cm slabs, 4 cm apart: a grain, not a threshold
const ANCHOR_REACH: float = 2.0
const STREET_STATIONS := {"S2": Vector3(27, 0, 9), "S3": Vector3(28, 0, -6), "S4": Vector3(24, 0, 0)}
const STREET_ARM: float = 6.0
## A5: from S2–S4 only the parts above the terrace's level are seen, «seen_y ≥ 4,0 м» (docs/Audit/2026-10-14-T6-Crane-
## Winch-Acceptance.md § 3 п. 1, its literal; the terrace NorthEastRoof tops out at 4.0, the machines' level). 1 mm of
## float slack, no more: measured lows are 4.30 / 4.45 / 4.30 (docs/Fix/2026-10-14-Steam-Crane-Winch-Fix.md).
const STREET_SEEN_FLOOR: float = 4.0
## V+: the height band of the T4 audit's proposal 8 («пропи 0,6–1,3 м із пласким верхом»), inclusive to 5 mm.
const STEP_HEIGHT := Vector2(0.6, 1.3)
const STEP_TOLERANCE: float = 0.005
## Bodies that are the district's structure, never props: the architecture's colliders, the anchors' posts, parapets,
## the clock tower's drum on its roof (y 16).
const STEP_SKIP_PREFIX := ["ArchitectureSolid", "Anchor", "BridgeParapet", "NorthParapet", "TowerDrum"]
## V+ steps: «<module>@(x, top, z)» of a floor-standing flat-topped body (its stack's top) → what it is. A step is climbed
## or stepped round, never vaulted; the list is for T6 to accept (docs/Fix/2026-10-14-Lamp-Posts-Awning-Anchor-5-Fix.md
## § 4). PLACEHOLDER until T6 accepts it.
const STEP_PROPS: Dictionary = {
	"CityMarket@(-8.93, 1.27, 19.09)": "west z 18 stall, goods behind the counter: a stack of two crates",
	"CityMarket@(-8.98, 0.90, 16.98)": "west z 18 stall, goods behind the counter: a beer barrel",
	"CityMarket@(-9.06, 0.86, 24.34)": "west z 25 stall: the barrel on its trestles",
	"CityMarket@(-8.92, 0.72, 26.16)": "west z 25 stall, goods behind the counter: a crate",
	"CityMarket@(8.98, 0.72, 16.86)": "east z 18 stall, goods behind the counter: a crate",
	"CityMarket@(8.92, 1.27, 23.90)": "east z 25 stall, goods behind the counter: a stack of two crates",
	"CityMarket@(8.97, 0.90, 26.04)": "east z 25 stall, goods behind the counter: a beer barrel",
	"CityInteriors@(-26.80, 0.96, 17.60)": "the grocer's counter, indoors",
	"CityInteriors@(-28.85, 0.80, 12.62)": "the grocer's west display crate inside the shop front",
	"CityInteriors@(-24.35, 0.80, 12.62)": "the grocer's east display crate inside the shop front",
	"CityInteriors@(-23.95, 0.90, 15.00)": "the grocer's beer barrel, indoors",
	"CityInteriors@(-20.20, 0.96, 17.60)": "the tailor's counter, indoors",
	"CityInteriors@(-17.85, 1.00, 14.95)": "the tailor's cutting table, indoors",
	"CityInteriors@(-13.60, 0.96, 17.60)": "the workshop's counter, indoors",
	"CityInteriors@(-11.10, 1.00, 14.95)": "the workshop's bench, indoors",
	"CityInteriors@(-15.60, 0.62, 13.15)": "the tailor's waiting stool, indoors",
	"CityInteriors@(-26.45, 0.60, 8.00)": "a street bench's planter in front of the grocer (west)",
	"CityInteriors@(-22.95, 0.60, 8.00)": "a street bench's planter in front of the grocer (east)",
	"CityInteriors@(-15.75, 0.60, 8.00)": "a street bench's planter in front of the workshop (west)",
	"CityInteriors@(-12.25, 0.60, 8.00)": "a street bench's planter in front of the workshop (east)",
	"CityProps@(-9.55, 0.84, 22.20)": "market street, west: a water butt",
	"CityProps@(-9.35, 0.90, 21.35)": "market street, west: a beer barrel",
	"CityProps@(9.35, 0.84, 22.20)": "market street, east: a water butt",
	"CityProps@(9.30, 0.90, 21.35)": "market street, east: a beer barrel",
	"CityProps@(14.45, 0.90, -4.00)": "east street by the ramp: a tar barrel",
	"CityProps@(14.60, 0.90, -4.72)": "east street by the ramp: a tar barrel",
	"CityProps@(15.69, 0.90, -3.40)": "east street by the ramp: a tar barrel against the ramp's wall",
	"CityProps@(-27.20, 0.92, 8.25)": "west street: a street urn",
	"CityProps@(-11.45, 0.92, 8.25)": "west street: a street urn",
	"CityMaintenance@(-21.96, 5.18, -12.26)": "the maintenance yard: the tool chest on the work bench",
	"CityMaintenance@(-21.96, 4.82, -11.86)": "the maintenance yard: the work bench in the south-east corner",
	# Accepted by T6 in advance (docs/Art/2026-10-14-Steam-Crane-Winch-Form.md § Лебідка № 11, «V+»): climbed or walked
	# round, never vaulted (V-MC). The key as this check printed it (docs/Fix/2026-10-14-Steam-Crane-Winch-Fix.md).
	"CityProps@(27.24, 5.12, -18.63)": "the NE terrace: the steam winch, the top of its drum's flanges",
}
## V+ wedge. T6 acceptance docs/Audit/2026-10-14-T6-Acceptance.md § 2.1, К7-а п. 2: a step is honest when the hero ends
## on it — «не нижче за верх більш ніж на 0,05 м» (STEP_RIM) — or on the floor; the typical failure, «зазор 0,05–0,75 м
## між пропом і стіною, у якому заклинює капсула r 0,35» (STEP_GAP_BAND). T6's what_under.gd log
## (scratchpad t6-accept/logs/what_under.log) of the wedged runs: the hero touched EastRamp and the tar barrel 0.52 m off
## it (end_y 0.764 of a 0.90 top), SouthWall and the yard bench 0.55 m off it (0.760 of 0.825); the tailor's cutting
## table, 0.45 m off the shop wall, kept him 0.025 m under its top (GREEN). The band read as «no gap 0.05–0.75 m to a
## solid» would fail most of the 25 steps T6 accepted (0.07–0.45 m off walls, the hero on top), so the guard measures the
## rule itself: the capsule (Fighter.tscn r 0.35, h 1.8) stands on the top STEP_LIFT over it at STEP_SAMPLES points across
## each side, walks out until it meets a solid that rises over the top with its axis at most 0.75 − 0.35 m past the edge,
## and is lowered there. Resting more than STEP_RIM under the top while touching the step is a wedge. A start the
## capsule does not fit (a canopy over the goods, the chest on the bench) is not a place to stand: it is counted, not judged.
const STEP_GAP_BAND := Vector2(0.05, 0.75)
const STEP_RIM: float = 0.05
const STEP_SAMPLES: int = 9
const STEP_LIFT: float = 0.03
const FIGHTER_H: float = 1.8       # Fighter.tscn BodyShape height
## The start and its nudges (6 and 12 cm, eight ways; a grain, not a threshold): a free stance over the top.
const STEP_NUDGES: Array[Vector3] = [Vector3.ZERO,
	Vector3(0.06, 0, 0), Vector3(-0.06, 0, 0), Vector3(0, 0, 0.06), Vector3(0, 0, -0.06),
	Vector3(0.042, 0, 0.042), Vector3(-0.042, 0, 0.042), Vector3(0.042, 0, -0.042), Vector3(-0.042, 0, -0.042),
	Vector3(0.12, 0, 0), Vector3(-0.12, 0, 0), Vector3(0, 0, 0.12), Vector3(0, 0, -0.12),
	Vector3(0.085, 0, 0.085), Vector3(-0.085, 0, 0.085), Vector3(0.085, 0, -0.085), Vector3(-0.085, 0, -0.085)]
## Wedges the walk finds beyond the three T6 named (docs/Fix/2026-10-14-T6-Acceptance-Geometry-Fix.md § 5): «<step key>
## <side>» → the narrowest gap it met on that side (± 2 cm) and why it stays. T6 accepted these steps from their run-ups
## (K7: no run-up, or the hero on top); the walk reaches the sides no run-up does. Moving them is outside T1's task for
## this fix (rows 1–5 of the T6 acceptance), so T1 decides; each must still wedge as measured.
const STEP_WEDGE_OPEN: Dictionary = {
	"CityMarket@(-9.06, 0.86, 24.34) (-1.00, 0.00, 0.00)": {"gap": 0.624, "why": "west z 25 stall, the barrel on trestles behind the counter: SouthWestRear 0.62 m behind it, 9 of 9 points 0.18 m under the top"},
	"CityMarket@(-9.06, 0.86, 24.34) (0.00, 0.00, -1.00)": {"gap": 0.410, "why": "the same barrel: the stall's back post 0.54 m off its north end, 1 of 9 points 0.07 m under"},
	"CityMarket@(-8.92, 0.72, 26.16) (-1.00, 0.00, 0.00)": {"gap": 0.190, "why": "west z 25 stall, the crate behind the counter: SouthWestRear 0.69 m behind it past the stall's post, 2 of 9 points 0.34 m under"},
	"CityMarket@(8.97, 0.90, 26.04) (1.00, 0.00, 0.00)": {"gap": 0.466, "why": "east z 25 stall, the beer barrel behind the counter: the east facade 0.65 m behind it, 3 of 9 points 0.18 m under"},
	"CityInteriors@(-26.80, 0.96, 17.60) (-1.00, 0.00, 0.00)": {"gap": 0.544, "why": "the grocer's counter: the end of the side stock shelf 0.54–0.62 m off its west end, 5 of 9 points 0.15 m under"},
	"CityInteriors@(-20.20, 0.96, 17.60) (-1.00, 0.00, 0.00)": {"gap": 0.544, "why": "the tailor's counter: the same side shelf, the same 0.15 m"},
	"CityInteriors@(-13.60, 0.96, 17.60) (-1.00, 0.00, 0.00)": {"gap": 0.544, "why": "the workshop's counter: the same side shelf, the same 0.15 m"},
	"CityInteriors@(-17.85, 1.00, 14.95) (0.00, 0.00, -1.00)": {"gap": 0.680, "why": "the tailor's cutting table: the dress form's torso 0.68 m off its north end, 2 of 9 points 0.28 m under"},
	"CityInteriors@(-15.60, 0.62, 13.15) (-1.00, 0.00, 0.00)": {"gap": 0.648, "why": "the tailor's waiting stool: the shop wall 0.65–0.75 m west of it, 7 of 9 points 0.30 m under; the stool's rim is T1's «капсула на ободі», hero movement after M3 with T5's numbers"},
}
const VEHICLE_LAYER: int = 1 | 8   # CityMarket._solid: walking and the camera, cover
const SWING_CLEAR: float = 0.3
const SWING_HAND: float = 1.25     # T5 Т3 (rope_pull_check HAND_Y): the hand over the feet
const SWING_FLOOR_GAP: float = 0.5 # T5 Т2 (rope_pull_check CLEARANCE)
const SWING_MIN_ROPE: float = 2.0  # T5 Т6
const FIGHTER_R: float = 0.35      # Fighter.tscn BodyShape radius
const STATION_GAP: float = 1.2     # tight_station_probe: start this far from the face
const RUN_UP: Vector2 = Vector2(1.05, 5.35)   # _vaults: the run-up samples from depth/2 + 1.05 to depth/2 + 5.35
const PANE_DEPTH: float = 0.02
const SUPPORT_GAP: float = 0.02
const SUPPORT_WINDOW: float = 0.3
const SUPPORT_SHARE: float = 0.2
const PLANE_GAP: float = 0.006
const PLANE_AREA: float = 0.0002
const BURIED_REACH: Array[float] = [0.0, 0.01, 0.03, 0.06, 0.1]
const SAME: float = 0.001
const HERO_R: float = 0.32
const BAND := Vector2(0.12, 1.8)
const COVERED: int = 13
const MIN_EXTENT: float = 0.08
const MIN_VOLUME: float = 0.0004
const PASS_THROUGH: float = 0.1
const COURT_CLEAR: float = 8.0
const LANE_CLEAR: float = 1.0
const PASSAGE_REACH: float = 0.25
const MAIN_HEIGHT: float = 3.2
const OBSTACLE_HEIGHT := Vector2(0.9, 1.1)
const OBSTACLE_DEPTH: float = 0.8
const INK_WIDTH: float = 0.2
const GROUP_MAX: int = 5
const SAME_KIND_MAX: int = 3
const CAMERA_SPACE: float = 3.0
const FLASH_HZ: float = 3.0
const PUFF_SIZE := Vector2(1.0, 1.5)
## The first floor under each anchor (ray down, mask 9) on 97675c7: `probe_inventory.gd` (scratchpad city-tidy/) →
## anchors.json, the same ray. Canopies of the four market stalls are under anchors 4–7 (audit D18).
## One deliberate change: anchor 5 (8.6, 6.7, 24.6) was 2.8023 (the east z 25 stall's spread canopy). T1 rolled that
## canopy up (Н6 «rolled», plan 2026-10-09-Rope-Pull-Jump-Arc-Substance-Momentum «Рішення T1 після кроків 1–4») because
## its edge cut the anchor's rope on the swing; now the rope falls to the street, 0.0. Anchors 4, 6, 7 keep their
## canopies and their 97675c7 floors; every other anchor is unchanged.
const ANCHOR_FLOOR: Array[float] = [0.0, 0.0, 0.0, 0.0, 2.8109, 0.0, 2.8109, 2.8023, 0.0, 0.0, 0.0, 3.83, 3.83, 3.83,
	0.0, 0.0, 0.0, 0.0, 0.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0]
## PLACEHOLDER (T5). The column around an anchor's vertical that a new prop or vehicle must stay out of (K anchors, M5).
## No plan or audit literal behind it: T2 set it in cd8f5dd and the T4 audit
## docs/Audit/2026-10-09-Rope-Jump-Momentum-Tidy-Steamcars-Review.md (§ П. 5, proposal 8) found it sourceless. The same
## 0.75 m is the radius of the support cylinder under an anchor in that audit's proposal 2a («циліндром r ≈ 0,75 м») and
## in plan 2026-10-14-Quality-Debt-Posts-Awning-Guards step 3 («r 0,75 м (PLACEHOLDER, T5)»); T5 owns the number.
const ANCHOR_COLUMN: float = 0.75
const HEX := {"8a8581": "paving", "9d9385": "stone", "9f7b73": "brick", "a9847b": "terracotta", "b6aa92": "plaster",
	"607078": "slate", "61717b": "roof_slate", "748075": "copper", "998162": "brass", "3b353c": "iron", "577368": "iron_paint", "2b2230": "ink",
	"4d6b70": "glass", "b79a60": "warm_window", "756454": "wood", "b9ad96": "cloth_cream", "98685e": "cloth_red",
	"617b79": "cloth_teal", "a6b79e": "marker"}
const DISTRICT_STRUCTURE := ["Ground", "NorthWestRoof", "NorthEastRoof", "SouthWestBlock", "SouthWestRear",
	"SouthEastWestWing", "SouthEastEastWing", "PassageLintel", "RoofBridge", "ClockTower", "WestBoundary",
	"EastBoundary", "NorthBoundary", "SouthBoundary", "EastRamp", "WestRamp", "PracticeLedge", "RoofApproachLow",
	"RoofApproachHigh", "PracticeLedgeGripLip", "RoofApproachLowGripLip", "RoofApproachHighGripLip"]
const MAINTENANCE_STRUCTURE := ["SouthWall", "EastWall", "NorthWall", "WestNorthWall", "WestSouthWall", "ServiceGate",
	"GateLintel", "OuterServiceRamp", "InnerServiceRamp", "ServiceGallery", "GalleryNorthRail", "GalleryPost"]
const GALLERY_STRUCTURE := ["NorthWall", "SouthWall", "EastWall", "EntryNorth", "EntrySouth", "EntryLintel",
	"ArchiveCanopy", "ArchiveFloor"]
## The water pump (CityWaterPump.gd) used to print its C5 findings as CITY_TIDY_OPEN: it belonged to the parallel branch.
## After the merge (T1, plan 2026-10-09 «Рішення T1 після кроків 1–4») its spout and lever have colliders and C5 checks
## it like every other prop; negatives pump_spout, pump_lever, pump_layer.

var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var world: Node3D
var district: Node3D
var props_node: Node3D
var space: PhysicsDirectSpaceState3D
var parts: Array[Dictionary] = []
var grid: Dictionary = {}
var fighter_script: Script
var arch_solids: Array[Dictionary] = []


class Rec extends RefCounted:
	var parts: Array[Dictionary] = []
	var stack: PackedStringArray = PackedStringArray()
	var module: String = ""
	static func at(label: String, v: Vector3) -> String:
		return "%s@%.2f,%.2f,%.2f" % [label, v.x, v.y, v.z]
	func push(label: String) -> void:
		stack.append(label)
	func pop() -> void:
		stack.remove_at(stack.size() - 1)
	func part(kind: String, xf: Transform3D, local: AABB, material: String) -> void:
		parts.append({"module": module, "ctx": "/".join(stack), "kind": kind, "mat": material, "xf": xf, "local": local, "visible": true})


class FakeDistrict extends Node3D:
	var materials: Dictionary = {}
	var geometry_count: int = 0


class ArchRec extends CityArchitecture:
	var rec: Rec
	var solids: Array[Dictionary] = []
	func _mesh(mesh: Mesh, center: Vector3, material: String, basis: Basis = Basis.IDENTITY) -> void:
		rec.part(mesh.get_class(), Transform3D(basis, center), mesh.get_aabb(), material)
		super(mesh, center, material, basis)
	func _collider(center: Vector3, size: Vector3, basis: Basis) -> void:
		solids.append({"ctx": "/".join(rec.stack), "xf": Transform3D(basis, center), "size": size})
		super(center, size, basis)
	func _building(center: Vector3, size: Vector3, bottom: float) -> void:
		rec.push(Rec.at("building", center)); super(center, size, bottom); rec.pop()
	func _facade(origin: Vector3, width: float, height: float, yaw: float, balconies: bool) -> void:
		rec.push(Rec.at("facade", origin)); super(origin, width, height, yaw, balconies); rec.pop()
	func _window(origin: Vector3, basis: Basis, bottom: Vector3, width: float, height: float, warm: bool) -> void:
		rec.push(Rec.at("arch_window", origin + basis * bottom)); super(origin, basis, bottom, width, height, warm); rec.pop()
	func _rectangular_window(origin: Vector3, basis: Basis, bottom: Vector3, width: float, height: float, warm: bool) -> void:
		rec.push(Rec.at("rect_window", origin + basis * bottom)); super(origin, basis, bottom, width, height, warm); rec.pop()
	func _balcony(origin: Vector3, basis: Basis, bottom: Vector3, width: float) -> void:
		rec.push(Rec.at("balcony", origin + basis * bottom)); super(origin, basis, bottom, width); rec.pop()
	func _mansard(center: Vector3, size: Vector3, top: float) -> void:
		rec.push(Rec.at("mansard", center)); super(center, size, top); rec.pop()


class MarketRec extends CityMarket:
	var rec: Rec
	func _primitive(mesh: Mesh, pose: Transform3D, material: String) -> void:
		rec.part(mesh.get_class(), pose, mesh.get_aabb(), material)
		super(mesh, pose, material)
	func _quad(material: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
		rec.part("Quad", Transform3D.IDENTITY, AABB(a, Vector3.ZERO).expand(b).expand(c).expand(d), material)
		super(material, a, b, c, d)
	func _stall(pose: Transform3D, cloth: String, state: String = "full", goods_seed: int = 0) -> void:
		rec.push(Rec.at("stall", pose.origin)); super(pose, cloth, state, goods_seed); rec.pop()
	func _canopy(pose: Transform3D, color: String) -> void:
		rec.push("canopy"); super(pose, color); rec.pop()
	func _crate(pose: Transform3D, size: Vector3) -> void:
		rec.push(Rec.at("crate", pose.origin)); super(pose, size); rec.pop()
	func _beer_barrel(pose: Transform3D) -> void:
		rec.push(Rec.at("beer_barrel", pose.origin)); super(pose); rec.pop()
	func _trestle_barrel(pose: Transform3D) -> void:
		rec.push(Rec.at("trestle_barrel", pose.origin)); super(pose); rec.pop()
	func _jar(pose: Transform3D, color: String, scale_factor: float, solid: bool = true) -> void:
		rec.push(Rec.at("jar", pose.origin)); super(pose, color, scale_factor, solid); rec.pop()
	func _wire(a: Vector3, b: Vector3, sag: float) -> void:
		rec.push(Rec.at("wire", a)); super(a, b, sag); rec.pop()
	func _lantern(center: Vector3, scale_factor: float) -> void:
		rec.push(Rec.at("lantern", center)); super(center, scale_factor); rec.pop()


class InteriorsRec extends CityInteriors:
	var rec: Rec
	func _primitive(mesh: Mesh, pose: Transform3D, material: String) -> void:
		rec.part(mesh.get_class(), pose, mesh.get_aabb(), material)
		super(mesh, pose, material)
	func _quad(material: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
		rec.part("Quad", Transform3D.IDENTITY, AABB(a, Vector3.ZERO).expand(b).expand(c).expand(d), material)
		super(material, a, b, c, d)
	func _shop(shop: Dictionary) -> void:
		rec.push("shop:" + String(shop.id)); super(shop); rec.pop()
	func _counter(pose: Transform3D, accent: String) -> void:
		rec.push(Rec.at("counter", pose.origin)); super(pose, accent); rec.pop()
	func _shelf(pose: Transform3D, kind: String) -> void:
		rec.push(Rec.at("shelf", pose.origin)); super(pose, kind); rec.pop()
	func _grocer(pose: Transform3D) -> void:
		rec.push("grocer"); super(pose); rec.pop()
	func _loaf(pose: Transform3D, size: float) -> void:
		rec.push(Rec.at("loaf", pose.origin)); super(pose, size); rec.pop()
	func _tailor(pose: Transform3D) -> void:
		rec.push("tailor"); super(pose); rec.pop()
	func _workshop(pose: Transform3D) -> void:
		rec.push("workshop"); super(pose); rec.pop()
	func _hanging_coat(pose: Transform3D, cloth: String) -> void:
		rec.push(Rec.at("coat", pose.origin)); super(pose, cloth); rec.pop()
	func _wall_clock(pose: Transform3D) -> void:
		rec.push(Rec.at("wall_clock", pose.origin)); super(pose); rec.pop()
	func _table(pose: Transform3D, size: Vector2, material: String) -> void:
		rec.push(Rec.at("table", pose.origin)); super(pose, size, material); rec.pop()
	func _stool(pose: Transform3D) -> void:
		rec.push(Rec.at("stool", pose.origin)); super(pose); rec.pop()
	func _street_furniture() -> void:
		rec.push("street_furniture"); super(); rec.pop()
	func _crate(pose: Transform3D, size: Vector3) -> void:
		rec.push(Rec.at("crate", pose.origin)); super(pose, size); rec.pop()
	func _beer_barrel(pose: Transform3D) -> void:
		rec.push(Rec.at("beer_barrel", pose.origin)); super(pose); rec.pop()
	func _jar(pose: Transform3D, color: String, scale_factor: float, solid: bool = true) -> void:
		rec.push(Rec.at("jar", pose.origin)); super(pose, color, scale_factor, solid); rec.pop()
	func _lantern(center: Vector3, scale_factor: float) -> void:
		rec.push(Rec.at("lantern", center)); super(center, scale_factor); rec.pop()


class PropsRec extends CityProps:
	var rec: Rec
	func _primitive(mesh: Mesh, pose: Transform3D, material: String) -> void:
		rec.part(mesh.get_class(), pose, mesh.get_aabb(), material)
		super(mesh, pose, material)
	func _crate(pose: Transform3D, size: Vector3) -> void:
		rec.push(Rec.at("crate", pose.origin)); super(pose, size); rec.pop()
	func _beer_barrel(pose: Transform3D) -> void:
		rec.push(Rec.at("beer_barrel", pose.origin)); super(pose); rec.pop()
	func _water_butt(pose: Transform3D) -> void:
		rec.push(Rec.at("water_butt", pose.origin)); super(pose); rec.pop()
	func _tar_barrel(pose: Transform3D) -> void:
		rec.push(Rec.at("tar_barrel", pose.origin)); super(pose); rec.pop()
	func _downpipe(points: Array[Vector3], clamps: Array[Vector4]) -> void:
		rec.push(Rec.at("downpipe", points[0])); super(points, clamps); rec.pop()
	func _obstacle(spec: Dictionary) -> void:
		rec.push(Rec.at("obstacle", spec.center)); super(spec); rec.pop()
	func _urn(pose: Transform3D) -> void:
		rec.push(Rec.at("urn", pose.origin)); super(pose); rec.pop()
	func _steam_main() -> void:
		rec.push(Rec.at("steam_main", Vector3(MAIN_X, MAIN_Y, MAIN_Z.x))); super(); rec.pop()
	func _steam_vent(spec: Dictionary) -> void:
		rec.push(Rec.at("steam_vent", spec.center)); super(spec); rec.pop()


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CITY_TIDY: " + label)


func _ticks(count: int) -> void:
	for tick: int in count:
		await physics_frame
		await process_frame


func _phase(name: String) -> bool:
	match name:
		"geometry":
			return mutation == "none" or mutation in GEOMETRY_BREAKS
		"places":
			return mutation == "none" or mutation in PLACE_BREAKS or mutation in VEHICLE_BREAKS or mutation in STEP_BREAKS or mutation in MACHINE_BREAKS
		"vault":
			return mutation == "none" or mutation in VAULT_BREAKS or mutation in VEHICLE_RUN_BREAKS or mutation in MACHINE_RUN_BREAKS
		"steam":
			return mutation == "none" or mutation in STEAM_BREAKS
	return false


static func _v(v: Vector3) -> String:
	return "(%.2f, %.2f, %.2f)" % [v.x, v.y, v.z]


# --- the world ---------------------------------------------------------------------------------------------------
func _open_world(hero: String) -> void:
	root.get_node("GameState").p1_character = hero
	world = load("res://scenes/world/CityWorld.tscn").instantiate()
	world.story_save_enabled = false
	world.journey_save_enabled = false
	world.lower_story_save_enabled = false
	root.add_child(world)
	current_scene = world
	world.progress.save_enabled = false
	world.npc_director.save_enabled = false
	await _ticks(20)
	district = world.district
	props_node = district.get_node("CityProps")
	space = world.get_world_3d().direct_space_state


func _close_world() -> void:
	_key(KEY_W, false)
	_key(KEY_SPACE, false)
	world.queue_free()
	current_scene = null
	await _ticks(3)


# --- parts -------------------------------------------------------------------------------------------------------
func _shape(p: Dictionary) -> void:
	var xf: Transform3D = p.xf
	var local: AABB = p.local
	var center: Vector3 = xf * (local.position + local.size * 0.5)
	var axes: Array[Vector3] = []
	var half := Vector3.ZERO
	var extent := Vector3.ZERO
	for k: int in 3:
		var column: Vector3 = xf.basis[k]
		var length: float = column.length()
		var unit: Vector3 = column / length if length > 0.000001 else Vector3.ZERO
		axes.append(unit)
		half[k] = length * local.size[k] * 0.5
		extent += (unit * half[k]).abs()
	p.center = center
	p.axes = axes
	p.half = half
	p.amin = center - extent
	p.amax = center + extent


func _move(selection: Array[Dictionary], offset: Vector3) -> void:
	for p: Dictionary in selection:
		p.xf = (p.xf as Transform3D).translated(offset)
		_shape(p)


func _select(module: String, needle: String, first_group_only: bool = true) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var group: String = ""
	for p: Dictionary in parts:
		if p.module != module or String(p.ctx).find(needle) < 0:
			continue
		var start: int = String(p.ctx).find(needle)
		var end: int = String(p.ctx).find("/", start)
		var owner: String = String(p.ctx).substr(0, end) if end >= 0 else String(p.ctx)
		if first_group_only:
			if group.is_empty():
				group = owner
			elif owner != group:
				continue
		result.append(p)
	return result


func _record_builders() -> void:
	var rec := Rec.new()
	var fake := FakeDistrict.new()
	fake.materials = CityMaterials.palette()
	rec.module = "CityArchitecture"
	var arch := ArchRec.new()
	arch.rec = rec
	arch._build(fake)
	arch_solids = arch.solids
	fake.free()
	for spec: Array in [["CityMarket", MarketRec.new()], ["CityInteriors", InteriorsRec.new()], ["CityProps", PropsRec.new()]]:
		rec.module = spec[0]
		var node: Node3D = spec[1]
		node.set("rec", rec)
		node._ready()
		node.free()
	var to_world: Transform3D = district.global_transform
	for entry: Dictionary in rec.parts:
		entry.xf = to_world * (entry.xf as Transform3D)
		entry.live = false
		_shape(entry)
		parts.append(entry)


func _material_key(material: Material) -> String:
	if material is ShaderMaterial:
		var hex: String = ((material as ShaderMaterial).get_shader_parameter("albedo") as Color).to_html(false)
		return String(HEX.get(hex, "#" + hex))
	if material is StandardMaterial3D:
		return "std#" + (material as StandardMaterial3D).albedo_color.to_html(false)
	return "none"


func _live_parts() -> void:
	for node: Node in district.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var path: PackedStringArray = String(district.get_path_to(mesh)).split("/")
		var top: String = path[0]
		if mesh.mesh == null or top in ["CityMarket", "CityInteriors", "CityProps", "CityBackdrop"] or top.begins_with("Architecture_"):
			continue
		var module: String = "CityDistrict"
		if top in ["CityMaintenance", "CityLowerGallery", "WaterPump"]:
			module = top
		var entry := {"module": module, "ctx": "/".join(path), "kind": mesh.mesh.get_class(), "mat": _material_key(mesh.material_override),
			"xf": mesh.global_transform, "local": mesh.mesh.get_aabb(), "visible": mesh.is_visible_in_tree(), "live": true}
		_shape(entry)
		parts.append(entry)


## role: struct | pane | anchor | prop; group: the prop instance.
func _classify() -> void:
	for p: Dictionary in parts:
		var ctx: String = p.ctx
		var elements: PackedStringArray = ctx.split("/")
		p.role = "prop"
		p.group = ""
		p.window = ""
		if p.module == "CityArchitecture":
			p.role = "struct"
			for index: int in elements.size():
				if elements[index].begins_with("arch_window@") or elements[index].begins_with("rect_window@") or elements[index].begins_with("mansard@"):
					p.window = "/".join(elements.slice(0, index + 1))
			if p.mat in ["glass", "warm_window"] and not String(p.window).is_empty():
				p.role = "pane"
			continue
		if p.live:
			var top: String = elements[0] if p.module == "CityDistrict" else (elements[1] if elements.size() > 1 else elements[0])
			if p.module == "CityDistrict":
				if top.begins_with("Anchor"):
					p.role = "anchor"
					p.group = "anchor:" + top.trim_prefix("AnchorPost").trim_prefix("AnchorArm").trim_prefix("AnchorPlate").trim_prefix("AnchorStrut").trim_prefix("AnchorCeramic").trim_prefix("AnchorBracket")
				elif top in DISTRICT_STRUCTURE or top.begins_with("NorthParapet") or top.begins_with("BridgeParapet"):
					p.role = "struct"
				else:
					p.group = "cc:CityDistrict"
			elif p.module == "CityMaintenance" and top in MAINTENANCE_STRUCTURE:
				p.role = "struct"
			elif p.module == "CityLowerGallery" and top in GALLERY_STRUCTURE:
				p.role = "struct"
			else:
				p.group = "cc:" + String(p.module)
			continue
		if p.module == "CityInteriors" and elements.size() == 1 and ctx.begins_with("shop:"):
			p.role = "struct"
			continue
		var deepest: int = -1
		for index: int in elements.size():
			if elements[index].find("@") >= 0:
				deepest = index
		if deepest >= 0:
			p.group = String(p.module) + ":" + "/".join(elements.slice(0, deepest + 1))
		else:
			p.group = "cc:" + String(p.module) + ":" + ctx
	# Parts of one cc: group that touch (≤ 1 cm) are one prop.
	var by_group: Dictionary = {}
	for index: int in parts.size():
		var p: Dictionary = parts[index]
		if p.role == "prop" and String(p.group).begins_with("cc:"):
			if not by_group.has(p.group):
				by_group[p.group] = []
			by_group[p.group].append(index)
	for key: String in by_group:
		var members: Array = by_group[key]
		var parent: Dictionary = {}
		for index: int in members:
			parent[index] = index
		for a: int in members.size():
			for b: int in range(a + 1, members.size()):
				if _aabb_gap(parts[members[a]], parts[members[b]]) <= 0.01:
					var ra: int = _find(parent, members[a])
					var rb: int = _find(parent, members[b])
					if ra != rb:
						parent[ra] = rb
		for index: int in members:
			parts[index].group = key + "#" + str(_find(parent, index))


func _find(parent: Dictionary, index: int) -> int:
	while parent[index] != index:
		parent[index] = parent[parent[index]]
		index = parent[index]
	return index


func _aabb_gap(a: Dictionary, b: Dictionary) -> float:
	var gap: Vector3 = ((a.amin as Vector3) - (b.amax as Vector3)).max((b.amin as Vector3) - (a.amax as Vector3)).max(Vector3.ZERO)
	return gap.length()


func _index_grid() -> void:
	grid.clear()
	for index: int in parts.size():
		var p: Dictionary = parts[index]
		var a: Vector3 = p.amin
		var b: Vector3 = p.amax
		for gx: int in range(floori(a.x / 2.0), floori(b.x / 2.0) + 1):
			for gz: int in range(floori(a.z / 2.0), floori(b.z / 2.0) + 1):
				var key := Vector2i(gx, gz)
				if not grid.has(key):
					grid[key] = []
				grid[key].append(index)


func _near(a: Vector3, b: Vector3, pad: float) -> Array[int]:
	var seen: Dictionary = {}
	var result: Array[int] = []
	for gx: int in range(floori((a.x - pad) / 2.0), floori((b.x + pad) / 2.0) + 1):
		for gz: int in range(floori((a.z - pad) / 2.0), floori((b.z + pad) / 2.0) + 1):
			for index: int in grid.get(Vector2i(gx, gz), []):
				if seen.has(index):
					continue
				seen[index] = true
				var q: Dictionary = parts[index]
				if ((q.amin as Vector3) - Vector3.ONE * pad).x <= b.x and (q.amax as Vector3).x + pad >= a.x \
						and (q.amin as Vector3).y - pad <= b.y and (q.amax as Vector3).y + pad >= a.y \
						and (q.amin as Vector3).z - pad <= b.z and (q.amax as Vector3).z + pad >= a.z:
					result.append(index)
	return result


func _inside_district(p: Dictionary) -> bool:
	var c: Vector3 = p.center
	return absf(c.x) < 33.5 and absf(c.z) < 33.5


func _sat(a: Dictionary, b: Dictionary) -> float:
	var axes: Array[Vector3] = []
	for k: int in 3:
		axes.append(a.axes[k])
		axes.append(b.axes[k])
	for i: int in 3:
		for j: int in 3:
			var cross: Vector3 = (a.axes[i] as Vector3).cross(b.axes[j])
			if cross.length() > 0.000001:
				axes.append(cross.normalized())
	var d: Vector3 = (b.center as Vector3) - (a.center as Vector3)
	var best: float = INF
	for axis: Vector3 in axes:
		if axis == Vector3.ZERO:
			continue
		var ra: float = 0.0
		var rb: float = 0.0
		for k: int in 3:
			ra += float(a.half[k]) * absf((a.axes[k] as Vector3).dot(axis))
			rb += float(b.half[k]) * absf((b.axes[k] as Vector3).dot(axis))
		best = minf(best, ra + rb - absf(d.dot(axis)))
		if best < 0.0:
			return best
	return best


func _label(p: Dictionary) -> String:
	var name: String = String(p.group) if not String(p.group).is_empty() else String(p.ctx)
	return "%s %s %s %s" % [p.module, name.get_slice("#", 0), p.mat, _v(p.center)]


# --- C1 ----------------------------------------------------------------------------------------------------------
func _c1_panes() -> void:
	var count: int = 0
	var bad: int = 0
	for index: int in parts.size():
		var pane: Dictionary = parts[index]
		if pane.role != "pane" or not pane.visible:
			continue
		count += 1
		for other: int in _near(pane.amin, pane.amax, 0.0):
			var q: Dictionary = parts[other]
			if other == index or not q.visible or q.kind == "Quad" or q.role in ["struct", "pane"]:
				continue
			var depth: float = _sat(pane, q)
			if depth > PANE_DEPTH:
				bad += 1
				_check(false, "C1 %s goes %.3f m into the pane %s" % [_label(q), depth, _v(pane.center)])
	_check(count > 150, "C1 the panes were found (%d)" % count)
	_check(bad == 0, "C1 no part goes more than %.2f m into a window pane (%d)" % [PANE_DEPTH, bad])
	print("CITY_TIDY_INFO C1 panes=%d intrusions=%d" % [count, bad])


# --- C2 ----------------------------------------------------------------------------------------------------------
func _c2_support() -> void:
	var groups: Dictionary = {}
	for index: int in parts.size():
		var p: Dictionary = parts[index]
		if p.role != "prop" or not p.visible or p.kind == "Quad" or not _inside_district(p):
			continue
		if not groups.has(p.group):
			groups[p.group] = []
		groups[p.group].append(index)
	var verdict: Dictionary = {}   # group → "rest" | "hang"
	var bad: int = 0
	for key: String in groups:
		var members: Array = groups[key]
		var member_set: Dictionary = {}
		var bottom: float = INF
		for index: int in members:
			member_set[index] = true
			bottom = minf(bottom, float((parts[index].amin as Vector3).y))
		var foot := Rect2()
		var started: bool = false
		for index: int in members:
			var p: Dictionary = parts[index]
			if float((p.amin as Vector3).y) < bottom + 0.05:
				var r := Rect2(Vector2(p.amin.x, p.amin.z), Vector2(p.amax.x - p.amin.x, p.amax.z - p.amin.z))
				foot = r if not started else foot.merge(r)
				started = true
		var area: float = maxf(foot.get_area(), 0.000001)
		var lo := Vector3(foot.position.x, bottom - SUPPORT_WINDOW, foot.position.y)
		var hi := Vector3(foot.end.x, bottom + SUPPORT_WINDOW, foot.end.y)
		var tops: Array[float] = []
		for other: int in _near(lo, hi, 0.0):
			var q: Dictionary = parts[other]
			if member_set.has(other) or not q.visible or q.kind == "Quad" or q.role == "pane":
				continue
			if float(q.amax.y) > bottom + SUPPORT_WINDOW or float(q.amin.y) > bottom:
				continue
			var r := Rect2(Vector2(q.amin.x, q.amin.z), Vector2(q.amax.x - q.amin.x, q.amax.z - q.amin.z))
			if foot.intersection(r).get_area() >= SUPPORT_SHARE * area:
				tops.append(float(q.amax.y))
		if tops.is_empty():
			verdict[key] = "hang"
			continue
		verdict[key] = "rest"
		var resting: bool = false
		for top: float in tops:
			resting = resting or absf(top - bottom) <= SUPPORT_GAP
		if resting:
			continue
		var top: float = tops.max()
		var gap: float = bottom - top
		if gap >= PASS_THROUGH and _mounted(members, member_set, bottom):
			continue
		bad += 1
		_check(false, "C2 %s %s %.3f m (bottom %.3f, support %.3f)" % [_label(parts[members[0]]), "floats" if gap > 0.0 else "sinks", absf(gap), bottom, top])
	# Hanging props must reach the structure or a resting prop through touching parts (≤ 2 cm).
	var grounded: Dictionary = {}
	for key: String in verdict:
		if verdict[key] == "rest":
			grounded[key] = true
	var changed: bool = true
	while changed:
		changed = false
		for key: String in verdict:
			if grounded.has(key):
				continue
			for index: int in groups[key]:
				var p: Dictionary = parts[index]
				for other: int in _near(p.amin, p.amax, SUPPORT_GAP):
					var q: Dictionary = parts[other]
					if q.group == key or not q.visible or q.kind == "Quad":
						continue
					if (q.role in ["struct", "pane", "anchor"] or grounded.has(q.group)) and _aabb_gap(p, q) <= SUPPORT_GAP:
						grounded[key] = true
						changed = true
						break
				if grounded.has(key):
					break
	for key: String in verdict:
		if not grounded.has(key):
			bad += 1
			_check(false, "C2 %s hangs in the air: nothing under it within %.1f m and nothing holds it" % [_label(parts[groups[key][0]]), SUPPORT_WINDOW])
	_check(groups.size() > 100, "C2 the props were found (%d groups)" % groups.size())
	_check(bad == 0, "C2 every prop rests within %.2f m or hangs from the structure (%d)" % [SUPPORT_GAP, bad])
	print("CITY_TIDY_INFO C2 groups=%d defects=%d" % [groups.size(), bad])


## A wall beside the prop: a structure part within 2 cm of one of its parts that rises over the prop's foot.
func _mounted(members: Array, member_set: Dictionary, bottom: float) -> bool:
	for index: int in members:
		var p: Dictionary = parts[index]
		for other: int in _near(p.amin, p.amax, SUPPORT_GAP):
			var q: Dictionary = parts[other]
			if member_set.has(other) or q.role != "struct" or not q.visible:
				continue
			if float(q.amax.y) > bottom + 0.05 and float(q.amin.y) < float(p.amax.y) and _aabb_gap(p, q) <= SUPPORT_GAP:
				return true
	return false


# --- C3 ----------------------------------------------------------------------------------------------------------
func _signature(p: Dictionary) -> String:
	var key: String = p.mat
	if key.begins_with("std#"):
		return key
	if p.module == "CityInteriors":
		return "base:" + key.trim_prefix("exterior_") if key.begins_with("exterior_") else "interiors:" + key
	return "base:" + key


func _faces(p: Dictionary) -> Array:
	var out: Array = []
	for k: int in 3:
		if p.kind != "BoxMesh" and not (p.kind == "CylinderMesh" and k == 1):
			continue
		for s: float in [-1.0, 1.0]:
			var n: Vector3 = (p.axes[k] as Vector3) * s
			var face: Vector3 = (p.center as Vector3) + n * float(p.half[k])
			out.append([n, n.dot(face), face, p.axes[(k + 1) % 3], float(p.half[(k + 1) % 3]), p.axes[(k + 2) % 3], float(p.half[(k + 2) % 3])])
	return out


func _buried(point: Vector3, normal: Vector3, skip: Array[int]) -> bool:
	if normal.y < -0.9 and point.y <= 0.01:
		return true
	for reach: float in BURIED_REACH:
		var at: Vector3 = point + normal * reach
		for index: int in _near(at, at, 0.0):
			var b: Dictionary = parts[index]
			if index in skip or b.kind != "BoxMesh" or not b.visible:
				continue
			var d: Vector3 = at - (b.center as Vector3)
			var inside: bool = true
			for k: int in 3:
				inside = inside and absf((b.axes[k] as Vector3).dot(d)) < float(b.half[k]) - 0.0001
			if inside:
				return true
	return false


func _c3_zfight() -> void:
	var bad: int = 0
	var pairs: int = 0
	for i: int in parts.size():
		var p: Dictionary = parts[i]
		if not p.visible or not (p.kind in ["BoxMesh", "CylinderMesh"]) or not _inside_district(p):
			continue
		var fp: Array = _faces(p)
		for j: int in _near(p.amin, p.amax, PLANE_GAP + 0.001):
			if j <= i:
				continue
			var q: Dictionary = parts[j]
			if not q.visible or not (q.kind in ["BoxMesh", "CylinderMesh"]) or _signature(p) == _signature(q):
				continue
			pairs += 1
			var fq: Array = _faces(q)
			for f1: Array in fp:
				for f2: Array in fq:
					var n1: Vector3 = f1[0]
					if n1.dot(f2[0]) < 0.9999:
						continue
					var gap: float = absf(float(f1[1]) - float(f2[1]))
					if gap >= PLANE_GAP - 0.0001:
						continue
					var ta: Vector3 = f1[3]
					var tb: Vector3 = f1[5]
					var sa: Vector3 = f2[3]
					var fa: float = f2[4]
					var sb: Vector3 = f2[5]
					var fb: float = f2[6]
					if maxf(absf(ta.dot(sa)), absf(ta.dot(sb))) < 0.9999:
						continue
					if absf(ta.dot(sb)) > absf(ta.dot(sa)):
						var swap_axis: Vector3 = sa
						sa = sb
						sb = swap_axis
						var swap_half: float = fa
						fa = fb
						fb = swap_half
					var c1: Vector3 = f1[2]
					var c2: Vector3 = f2[2]
					var o1: float = c2.dot(ta) - c1.dot(ta)
					var o2: float = c2.dot(tb) - c1.dot(tb)
					var ea: float = f1[4]
					var eb: float = f1[6]
					var ia: float = minf(ea, o1 + fa) - maxf(-ea, o1 - fa)
					var ib: float = minf(eb, o2 + fb) - maxf(-eb, o2 - fb)
					if ia <= 0.005 or ib <= 0.005 or ia * ib < PLANE_AREA:
						continue
					var mid1: float = (maxf(-ea, o1 - fa) + minf(ea, o1 + fa)) * 0.5
					var mid2: float = (maxf(-eb, o2 - fb) + minf(eb, o2 + fb)) * 0.5
					var point: Vector3 = c1 + ta * mid1 + tb * mid2 + n1 * (gap + 0.003)
					if _buried(point, n1, [i, j]):
						continue
					bad += 1
					_check(false, "C3 %s and %s share a plane (%.4f m apart, %.4f m², normal %s) at %s" % [_label(p), _label(q), gap, ia * ib, _v(n1), _v(point)])
	_check(bad == 0, "C3 no visible coplanar faces of different materials (%d)" % bad)
	print("CITY_TIDY_INFO C3 pairs=%d defects=%d" % [pairs, bad])


# --- C4 ----------------------------------------------------------------------------------------------------------
func _snap(v: Vector3) -> String:
	return "%d,%d,%d" % [roundi(v.x / SAME), roundi(v.y / SAME), roundi(v.z / SAME)]


func _shape_key(shape: Shape3D) -> String:
	if shape is BoxShape3D:
		return "box:" + _snap((shape as BoxShape3D).size)
	if shape is CylinderShape3D:
		return "cyl:%d,%d" % [roundi((shape as CylinderShape3D).radius / SAME), roundi((shape as CylinderShape3D).height / SAME)]
	if shape is SphereShape3D:
		return "sph:%d" % roundi((shape as SphereShape3D).radius / SAME)
	if shape is CapsuleShape3D:
		return "cap:%d,%d" % [roundi((shape as CapsuleShape3D).radius / SAME), roundi((shape as CapsuleShape3D).height / SAME)]
	if shape is ConvexPolygonShape3D:
		var points: PackedVector3Array = (shape as ConvexPolygonShape3D).points
		var box := AABB(points[0], Vector3.ZERO) if not points.is_empty() else AABB()
		for point: Vector3 in points:
			box = box.expand(point)
		return "convex:%d:%s:%s" % [points.size(), _snap(box.position), _snap(box.size)]
	if shape is ConcavePolygonShape3D:
		var faces: PackedVector3Array = (shape as ConcavePolygonShape3D).get_faces()
		var box2 := AABB(faces[0], Vector3.ZERO) if not faces.is_empty() else AABB()
		for point: Vector3 in faces:
			box2 = box2.expand(point)
		return "concave:%d:%s:%s" % [faces.size(), _snap(box2.position), _snap(box2.size)]
	return shape.get_class()


func _c4_duplicates() -> void:
	var seen: Dictionary = {}
	var bad: int = 0
	for p: Dictionary in parts:
		if not p.visible or p.kind == "Quad" or not _inside_district(p):
			continue
		var key: String = "%s|%s|%s" % [p.kind, _snap(p.center), _snap((p.amax as Vector3) - (p.amin as Vector3))]
		if seen.has(key):
			bad += 1
			_check(false, "C4 %s is drawn twice (also %s)" % [_label(p), seen[key]])
		else:
			seen[key] = _label(p)
	var bodies: Dictionary = {}
	var colliders: int = 0
	for node: Node in district.find_children("*", "CollisionShape3D", true, false):
		var shape := node as CollisionShape3D
		if shape.shape == null or shape.disabled:
			continue
		colliders += 1
		var xf: Transform3D = shape.global_transform
		var key: String = "%s|%s|%s|%s|%s" % [_shape_key(shape.shape), _snap(xf.origin), _snap(xf.basis.x), _snap(xf.basis.y), _snap(xf.basis.z)]
		if bodies.has(key):
			bad += 1
			_check(false, "C4 collider %s duplicates %s" % [district.get_path_to(shape), bodies[key]])
		else:
			bodies[key] = String(district.get_path_to(shape))
	_check(bad == 0, "C4 nothing is built twice (%d)" % bad)
	print("CITY_TIDY_INFO C4 parts=%d colliders=%d duplicates=%d" % [seen.size(), colliders, bad])


# --- C5 ----------------------------------------------------------------------------------------------------------
func _local_point(p: Dictionary, f: Vector3) -> Vector3:
	var local: AABB = p.local
	return (p.xf as Transform3D) * (local.position + local.size * f)


func _inside_collider(point: Vector3) -> bool:
	var query := PhysicsPointQueryParameters3D.new()
	query.position = point
	query.collision_mask = 1
	return not space.intersect_point(query, 1).is_empty()


func _capsule_free(feet: Vector3) -> bool:
	var capsule := CapsuleShape3D.new()
	capsule.radius = HERO_R
	capsule.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis.IDENTITY, feet + Vector3(0, 0.96, 0))
	query.collision_mask = 1
	return space.intersect_shape(query, 1).is_empty()


func _floor_under(at: Vector3, depth: float = 2.5) -> Dictionary:
	var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(at, at - Vector3.UP * depth, 1))
	if hit.is_empty() or Vector3(hit.normal).y < 0.7:
		return {}
	return hit


func _c5_solid() -> void:
	var examined: int = 0
	var bad: Dictionary = {}
	for p: Dictionary in parts:
		if p.role != "prop" or not p.visible or p.kind == "Quad" or not _inside_district(p):
			continue
		var floor_y: float = 4.0 if float(p.amin.y) >= 3.9 else 0.0
		if not (float(p.amin.y) < floor_y + BAND.y and float(p.amax.y) > floor_y + BAND.x):
			continue
		if maxf(float(p.amax.x - p.amin.x), float(p.amax.z - p.amin.z)) < MIN_EXTENT:
			continue
		if 8.0 * float(p.half.x) * float(p.half.y) * float(p.half.z) < MIN_VOLUME:
			continue
		var covered: int = 0
		for fx: float in [0.2, 0.5, 0.8]:
			for fy: float in [0.2, 0.5, 0.8]:
				for fz: float in [0.2, 0.5, 0.8]:
					if _inside_collider(_local_point(p, Vector3(fx, fy, fz))):
						covered += 1
		if covered > COVERED:
			continue
		examined += 1
		var reach: float = HERO_R - PASS_THROUGH
		var found: bool = false
		for fx: float in [0.05, 0.5, 0.95]:
			for fy: float in [0.05, 0.5, 0.95]:
				for fz: float in [0.05, 0.5, 0.95]:
					if found:
						break
					var point: Vector3 = _local_point(p, Vector3(fx, fy, fz))
					if point.y < floor_y + BAND.x or point.y > floor_y + BAND.y:
						continue
					for step: int in 17:
						var offset := Vector3.ZERO
						if step > 0:
							var angle: float = TAU * float((step - 1) % 8) / 8.0
							offset = Vector3(cos(angle), 0, sin(angle)) * (reach * (0.5 if step <= 8 else 1.0))
						var axis: Vector3 = Vector3(point.x, point.y, point.z) + offset
						var hit: Dictionary = _floor_under(axis)
						if hit.is_empty():
							continue
						var feet: float = float(hit.position.y)
						if absf(feet - floor_y) > SUPPORT_WINDOW or point.y < feet + 0.06 or point.y > feet + 1.86:
							continue
						if _capsule_free(Vector3(axis.x, feet, axis.z)):
							found = true
							break
		if found:
			var key: String = _label(p)
			if not bad.has(key):
				bad[key] = true
				_check(false, "C5 a hero walks %.2f m into %s: it has no collider where he meets it (%d/27 points in colliders)" % [PASS_THROUGH, key, covered])
	_check(bad.is_empty(), "C5 every visible part in the hero band stops the hero (%d)" % bad.size())
	print("CITY_TIDY_INFO C5 examined=%d defects=%d" % [examined, bad.size()])


# --- K -----------------------------------------------------------------------------------------------------------
func _props_parts() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for p: Dictionary in parts:
		if p.module == "CityProps" and p.visible:
			result.append(p)
	return result


func _flat_distance(p: Dictionary, point: Vector3) -> float:
	var nearest := Vector2(clampf(point.x, p.amin.x, p.amax.x), clampf(point.z, p.amin.z, p.amax.z))
	return nearest.distance_to(Vector2(point.x, point.z))


func _k_places() -> void:
	var own: Array[Dictionary] = _props_parts()
	_check(own.size() > 100, "K the new props are there (%d parts)" % own.size())
	# К6: the court, the pockets and the lanes.
	var closest: float = INF
	for p: Dictionary in own:
		closest = minf(closest, _flat_distance(p, Vector3.ZERO))
	_check(closest >= COURT_CLEAR, "K6 nothing new within %.0f m of the court centre (closest %.2f m)" % [COURT_CLEAR, closest])
	for pocket: Dictionary in CityLayout.combat_pockets():
		var cylinder := CylinderShape3D.new()
		cylinder.radius = pocket.radius
		cylinder.height = 2.0
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = cylinder
		query.transform = Transform3D(Basis.IDENTITY, Vector3(pocket.center) + Vector3(0, 1.1, 0))
		query.collision_mask = 1
		var hits: Array[Dictionary] = space.intersect_shape(query, 8)
		_check(hits.is_empty(), "K6 the %s pocket (r %.0f) holds no collider (%d)" % [pocket.id, pocket.radius, hits.size()])
		for p: Dictionary in own:
			if _flat_distance(p, pocket.center) < float(pocket.radius) and absf(float(p.center.y) - float(pocket.center.y)) < 3.0:
				_check(false, "K6 %s stands in the %s pocket" % [_label(p), pocket.id])
	var director: Script = load("res://scripts/npc/CityNpcDirector.gd")
	var lane_bad: int = 0
	for resident: int in range(3, 12):
		var lane: Array = director.lane(resident)
		for p: Dictionary in own:
			if float(p.amin.y) > BAND.y:
				continue
			for i: int in lane.size():
				var a: Vector3 = lane[i]
				var b: Vector3 = lane[(i + 1) % lane.size()]
				var c := Vector2(p.center.x, p.center.z)
				var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(c, Vector2(a.x, a.z), Vector2(b.x, b.z))
				if _flat_distance(p, Vector3(nearest.x, 0, nearest.y)) < LANE_CLEAR:
					lane_bad += 1
					_check(false, "K6 %s is within %.0f m of resident lane %d" % [_label(p), LANE_CLEAR, resident])
					break
	_check(lane_bad == 0, "K6 the new props keep %.0f m from every resident lane (%d)" % [LANE_CLEAR, lane_bad])
	print("CITY_TIDY_INFO K6 closest_to_court=%.2f lane_breaches=%d" % [closest, lane_bad])
	await _k_passage(own)
	_k_anchors()
	_k_obstacles()
	_k_style(own)


func _k_passage(own: Array[Dictionary]) -> void:
	var inside: int = 0
	var reach: float = 0.0
	var lowest: float = INF
	var main_low: float = INF
	for p: Dictionary in own:
		if p.center.x < 18.0 or p.center.x > 22.0 or p.center.z < 12.0 or p.center.z > 30.0:
			continue
		inside += 1
		reach = maxf(reach, CityProps.MAIN_WALL_X - float(p.amin.x))
		lowest = minf(lowest, float(p.amin.y))
		if String(p.group).find("steam_main@") >= 0 and float(p.amax.z - p.amin.z) > 8.0:
			main_low = minf(main_low, float(p.amin.y))
	_check(inside > 20, "K7 the steam main is in the southeast passage (%d parts)" % inside)
	_check(reach <= PASSAGE_REACH + 0.001, "K7 the passage pipes stand ≤ %.2f m out of the wall (%.3f m)" % [PASSAGE_REACH, reach])
	_check(main_low < INF and main_low >= MAIN_HEIGHT, "K7 the main runs ≥ %.1f m up (%.2f m)" % [MAIN_HEIGHT, main_low])
	_check(lowest >= BAND.y + 0.6, "K7 nothing in the passage comes down into reach (lowest %.2f m)" % lowest)
	var box := BoxShape3D.new()
	box.size = Vector3(3.9, 4.2, 18.0)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = box
	query.transform = Transform3D(Basis.IDENTITY, Vector3(20, 2.2, 21))
	query.collision_mask = 1
	_check(space.intersect_shape(query, 4).is_empty(), "K7 the passage (x 18.05–21.95, z 12–30) holds no collider: 4 m wide, the camera arm free")
	var alley: Dictionary = load("res://scripts/world/CityAlleyEvent.gd").get_script_constant_map()
	for key: String in ["MOUTH", "STAND", "BLOCK", "INSIDE", "NORTH_EXIT", "SOUTH_EXIT"]:
		_check(_capsule_free(alley[key]), "K7 the alley point %s %s is free" % [key, _v(alley[key])])
	var z: float = 9.0
	var axis_free: bool = true
	while z <= 31.0:
		axis_free = axis_free and _capsule_free(Vector3(20, 0, z))
		z += 0.5
	_check(axis_free, "K7 the passage axis x = 20 is free from z 9 to 31")
	var player: Node3D = world.player
	player.restart_at(Vector3(20, 0, 21))
	player._set_forward(Vector3(0, 0, -1))
	world.camera_rig.aim.yaw_offset = 0.0
	world.camera_rig.reset_view()
	await _ticks(20)
	var arm: float = world.camera_rig.arm.get_hit_length()
	_check(arm >= CAMERA_SPACE, "K7 the camera arm in the passage keeps ≥ %.0f m (%.2f m)" % [CAMERA_SPACE, arm])
	print("CITY_TIDY_INFO K7 passage parts=%d reach=%.3f lowest=%.2f main=%.2f arm=%.2f" % [inside, reach, lowest, main_low, arm])


func _k_anchors() -> void:
	var supports: Array[Dictionary] = CityLayout.anchor_supports()
	_check(supports.size() == ANCHOR_FLOOR.size(), "K anchors: %d now, %d measured on 97675c7" % [supports.size(), ANCHOR_FLOOR.size()])
	var own_bodies: Array[Node] = props_node.find_children("*", "StaticBody3D", true, false)
	for index: int in mini(supports.size(), ANCHOR_FLOOR.size()):
		var point: Vector3 = supports[index].point
		var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(point - Vector3(0, 0.2, 0), point - Vector3(0, 12, 0), 9))
		var y: float = float(hit.position.y) if not hit.is_empty() else -INF
		_check(absf(y - ANCHOR_FLOOR[index]) <= 0.001, "K anchor %d: the rope still falls to y %.4f (now %.4f)" % [index, ANCHOR_FLOOR[index], y])
		for body: Node in own_bodies:
			for node: Node in body.get_children():
				var shape := node as CollisionShape3D
				if shape == null or shape.shape == null:
					continue
				var box: AABB = shape.shape.get_debug_mesh().get_aabb()
				var world_box: AABB = shape.global_transform * box
				var nearest := Vector2(clampf(point.x, world_box.position.x, world_box.end.x), clampf(point.z, world_box.position.z, world_box.end.z))
				if nearest.distance_to(Vector2(point.x, point.z)) < ANCHOR_COLUMN and world_box.position.y < point.y:
					_check(false, "K anchor %d: %s stands in its column (≤ %.2f m)" % [index, body.name, ANCHOR_COLUMN])


func _k_obstacles() -> void:
	for spec: Dictionary in props_node.get_meta("obstacles", []):
		var body: Node = props_node.get_node_or_null("VaultObstacle_" + String(spec.id))
		_check(body is StaticBody3D, "K8 obstacle %s has its collider" % spec.id)
		if not body is StaticBody3D:
			continue
		var shape: BoxShape3D = ((body as StaticBody3D).get_child(0) as CollisionShape3D).shape as BoxShape3D
		var run: Vector3 = spec.run
		var depth: float = absf(shape.size.dot(run))
		_check(shape.size.y >= OBSTACLE_HEIGHT.x and shape.size.y <= OBSTACLE_HEIGHT.y, "K8 obstacle %s is %.2f m high (%.1f–%.1f)" % [spec.id, shape.size.y, OBSTACLE_HEIGHT.x, OBSTACLE_HEIGHT.y])
		_check(depth <= OBSTACLE_DEPTH, "K8 obstacle %s is %.2f m deep (≤ %.1f)" % [spec.id, depth, OBSTACLE_DEPTH])
		var center: Vector3 = (body as StaticBody3D).global_position
		for side: float in [-1.0, 1.0]:
			var beyond: Vector3 = Vector3(center.x, 0, center.z) + run * side * (depth * 0.5 + 0.8)
			var hit: Dictionary = _floor_under(beyond + Vector3(0, 1.0, 0), 2.0)
			_check(not hit.is_empty() and absf(float(hit.position.y) - float(spec.center.y)) <= 0.05, "K8 obstacle %s: the floor %s of it is at its own level" % [spec.id, "behind" if side > 0 else "before"])


func _k_style(own: Array[Dictionary]) -> void:
	var ink_bad: int = 0
	for p: Dictionary in parts:
		if p.mat != "ink" or not p.visible:
			continue
		var sizes: Array[float] = [float(p.half.x) * 2.0, float(p.half.y) * 2.0, float(p.half.z) * 2.0]
		sizes.sort()
		var strip: bool = float(p.amax.y - p.amin.y) < 0.05 and maxf(float(p.amax.x - p.amin.x), float(p.amax.z - p.amin.z)) > 1.0
		if sizes[1] > INK_WIDTH or strip:
			ink_bad += 1
			_check(false, "K4 %s is an ink surface (%.2f m wide%s)" % [_label(p), sizes[1], ", a strip on the street" if strip else ""])
	_check(ink_bad == 0, "K4/Н1 ink is only outline: no surface wider than %.1f m, no street strip (%d)" % [INK_WIDTH, ink_bad])
	_check(props_node.find_children("*", "Label3D", true, false).is_empty(), "K5 the new props carry no letters")
	_check(props_node.find_children("*", "Light3D", true, false).is_empty(), "K9 the new props add no light")
	var meshes: Array[Node] = props_node.find_children("*", "MeshInstance3D", false, false)
	var materials: Dictionary = {}
	for p: Dictionary in own:
		materials[p.mat] = true
	_check(meshes.size() == materials.size(), "K9 the new props are one mesh per material (%d meshes, %d materials)" % [meshes.size(), materials.size()])
	# К8: groups of props (gaps ≤ 1 m) hold ≤ 5, ≤ 3 of one kind.
	var items: Array = props_node.get_meta("props", [])
	var parent: Dictionary = {}
	for i: int in items.size():
		parent[i] = i
	for i: int in items.size():
		for j: int in range(i + 1, items.size()):
			var gap: float = Vector2(items[i].position.x - items[j].position.x, items[i].position.z - items[j].position.z).length() - float(items[i].radius) - float(items[j].radius)
			if gap <= 1.0:
				var ri: int = _find(parent, i)
				var rj: int = _find(parent, j)
				if ri != rj:
					parent[ri] = rj
	var clusters: Dictionary = {}
	for i: int in items.size():
		var root_index: int = _find(parent, i)
		if not clusters.has(root_index):
			clusters[root_index] = []
		clusters[root_index].append(items[i])
	for key: int in clusters:
		var members: Array = clusters[key]
		var kinds: Dictionary = {}
		for item: Dictionary in members:
			kinds[item.kind] = int(kinds.get(item.kind, 0)) + 1
		_check(members.size() <= GROUP_MAX, "K8 a group at %s holds %d props (≤ %d)" % [_v(members[0].position), members.size(), GROUP_MAX])
		for kind: String in kinds:
			_check(int(kinds[kind]) <= SAME_KIND_MAX, "K8 a group at %s holds %d of %s (≤ %d)" % [_v(members[0].position), kinds[kind], kind, SAME_KIND_MAX])
	print("CITY_TIDY_INFO K8 props=%d groups=%d" % [items.size(), clusters.size()])


## D17, D19, D24 of the audit, each measured the way the audit measured it.
func _places_of_the_audit() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	for shop: Dictionary in CityPlaces.shops():
		for key: String in ["approach", "visit", "service"]:
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = capsule
			query.transform = Transform3D(Basis.IDENTITY, Vector3(shop[key]) + Vector3(0, 0.96, 0))
			query.collision_mask = 1
			var hits: Array[Dictionary] = space.intersect_shape(query, 4)
			var names: Array[String] = []
			for hit: Dictionary in hits:
				names.append(String(hit.collider.name))
			_check(hits.is_empty(), "D17 a hero (r 0.35) stands free at the %s %s point %s (%s)" % [shop.id, key, _v(shop[key]), ", ".join(names)])
	var sides: int = 0
	var bare: int = 0
	for solid: Dictionary in arch_solids:
		var size: Vector3 = solid.size
		if String(solid.ctx).find("balcony@") < 0 or absf(size.x - 0.07) > 0.001 or absf(size.z - 0.85) > 0.001:
			continue
		sides += 1
		var inverse: Transform3D = (district.global_transform * (solid.xf as Transform3D)).affine_inverse()
		var inside: int = 0
		for p: Dictionary in parts:
			if p.module != "CityArchitecture" or p.ctx != solid.ctx or not p.visible or float(p.amax.y - p.amin.y) < 0.6:
				continue
			var local: Vector3 = inverse * (p.center as Vector3)
			if absf(local.x) <= size.x * 0.5 and absf(local.y) <= size.y * 0.5 and absf(local.z) <= size.z * 0.5:
				inside += 1
		if inside < 3:
			bare += 1
	_check(sides >= 30, "D19 the solid balcony sides were found (%d)" % sides)
	_check(bare == 0, "D19 every solid balcony side has ≥ 3 balusters inside it (%d bare)" % bare)
	for wall: Vector2 in [Vector2(-10.0, 1.0), Vector2(-30.0, -1.0)]:
		var faces: int = 0
		var wrong: Array[String] = []
		for p: Dictionary in parts:
			if not p.visible or p.kind != "BoxMesh" or float(p.amax.z) < 12.5 or float(p.amin.z) > 19.5 or float(p.amax.y) < 1.0 or float(p.amin.y) > 3.0:
				continue
			var face: float = float(p.amax.x) if wall.y > 0.0 else float(p.amin.x)
			if absf(face - wall.x) > 0.005 or float(p.amax.x - p.amin.x) > 1.0:
				continue
			faces += 1
			if not _signature(p).begins_with("base:"):
				wrong.append(_label(p))
		_check(faces > 0 and wrong.is_empty(), "D24 the street face x %.1f of the end shop wall is street material (%d faces; %s)" % [wall.x, faces, ", ".join(wrong)])


func _triangles() -> void:
	var by_module: Dictionary = {}
	var total: int = 0
	var instances: int = 0
	for node: Node in district.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh == null:
			continue
		var top: String = String(district.get_path_to(mesh)).get_slice("/", 0)
		var key: String = top if top in ["CityMarket", "CityInteriors", "CityBackdrop", "CityProps", "CityMaintenance", "CityLowerGallery", "WaterPump"] else ("CityArchitecture" if top.begins_with("Architecture_") else "CityDistrict")
		var count: int = int(mesh.mesh.get_faces().size() / 3)
		by_module[key] = int(by_module.get(key, 0)) + count
		total += count
		instances += 1
	print("CITY_TIDY_INFO triangles district=%d mesh_instances=%d %s" % [total, instances, JSON.stringify(by_module)])


# --- V -----------------------------------------------------------------------------------------------------------
func _key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _vaults(hero: String) -> void:
	var profile: Resource = load("res://data/world/city_parkour.tres")
	var want: int = roundi(float(profile.get("vault_seconds")) * 60.0)
	world.npc_director.process_mode = Node.PROCESS_MODE_DISABLED
	for spec: Dictionary in props_node.get_meta("obstacles", []):
		var body: StaticBody3D = props_node.get_node("VaultObstacle_" + String(spec.id))
		var size: Vector3 = ((body.get_child(0) as CollisionShape3D).shape as BoxShape3D).size
		var axis: Vector3 = spec.run
		var depth: float = absf(size.dot(axis))
		var center: Vector3 = spec.center
		var tested: int = 0
		for side: float in [1.0, -1.0]:
			var run: Vector3 = axis * side
			var start: Vector3 = center - run * (depth * 0.5 + 5.0)
			var clear: bool = true
			var s: float = 0.0
			while s <= 4.3:
				var at: Vector3 = start + run * s
				var hit: Dictionary = _floor_under(at + Vector3(0, 0.5, 0), 1.0)
				clear = clear and not hit.is_empty() and absf(float(hit.position.y) - center.y) < 0.05 and _capsule_free(at)
				s += 0.5
			if not clear:
				continue
			tested += 1
			var out: Dictionary = await _vault_run(start, run, center, depth)
			var beyond: float = (Vector3(out.end) - center).dot(run)
			_check(absi(int(out.ticks) - want) <= 1, "V %s vaults %s from %s for %d ticks (want %d)" % [hero, spec.id, _v(start), out.ticks, want])
			_check(not out.hang, "V %s: no hang on %s" % [hero, spec.id])
			_check(beyond > depth * 0.5 + 0.35 and absf(float(out.landed) - center.y) < 0.05, "V %s lands beyond %s at the take-off level (%.2f m past the centre, y %.3f)" % [hero, spec.id, beyond, out.landed])
			print("CITY_TIDY_INFO V %s %s side %+.0f: %d ticks, speed %.2f, beyond %.2f, y %.3f" % [hero, spec.id, side, out.ticks, out.speed, beyond, out.landed])
		_check(tested >= 1, "V %s: %s has a free run-up from at least one side (%d)" % [hero, spec.id, tested])
	world.npc_director.process_mode = Node.PROCESS_MODE_INHERIT


## V+ (see the header). Every solid body of the district but its structure: its world box from its shapes; the floor
## under its centre (the body itself excluded); a body standing on that floor (its foot within 5 cm) starts a stack —
## itself and whatever rests on it, touching within 3 cm. The stack's top body is a candidate when it is 0.6–1.3 m over
## the floor, at least as wide as the hero's body radius both ways (FIGHTER_R: narrower is a leg or a post, nothing to
## vault or stand on) and flat (the top shape a box or a cylinder standing upright, or a convex hull with three corners
## level within 1 cm). One candidate per top body, keyed by it.
func _step_candidates() -> Array[Dictionary]:
	var boxes: Array[Dictionary] = []
	for node: Node in district.find_children("*", "StaticBody3D", true, false):
		var body := node as StaticBody3D
		var path: PackedStringArray = String(district.get_path_to(body)).split("/")
		var module: String = path[0] if path.size() > 1 else "CityDistrict"
		var name: String = String(body.name)
		var skip: bool = (module == "CityDistrict" and name in DISTRICT_STRUCTURE) or (module == "CityMaintenance" and name in MAINTENANCE_STRUCTURE) or (module == "CityLowerGallery" and name in GALLERY_STRUCTURE)
		for prefix: String in STEP_SKIP_PREFIX:
			skip = skip or name.begins_with(prefix)
		var box := AABB()
		var top_shape: CollisionShape3D = null
		for child: Node in body.get_children():
			var shape := child as CollisionShape3D
			if shape == null or shape.shape == null or shape.disabled:
				continue
			var world_box: AABB = shape.global_transform * shape.shape.get_debug_mesh().get_aabb()
			if top_shape == null or world_box.end.y > box.end.y:
				top_shape = shape
			box = world_box if box.size == Vector3.ZERO else box.merge(world_box)
		if top_shape == null:
			continue
		boxes.append({"body": body, "module": module, "name": name, "skip": skip, "box": box, "flat": _flat_top(top_shape),
			"vault": name.begins_with("VaultObstacle_")})
	var out: Array[Dictionary] = []
	var keys: Dictionary = {}
	for entry: Dictionary in boxes:
		if entry.skip:
			continue
		var box: AABB = entry.box
		var centre := box.get_center()
		var query := PhysicsRayQueryParameters3D.create(Vector3(centre.x, box.position.y + 0.05, centre.z), Vector3(centre.x, box.position.y - 0.5, centre.z), 1)
		query.exclude = [(entry.body as StaticBody3D).get_rid()]
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty() or absf(float(hit.position.y) - box.position.y) > 0.05:
			continue
		var floor_y: float = hit.position.y
		# The stack: bodies resting on the top (their foot within 3 cm of it, overlapping it on the ground plane).
		var top: float = box.end.y
		var flat: bool = entry.flat
		var top_entry: Dictionary = entry
		var grown := true
		var stacked: Array[String] = []
		while grown:
			grown = false
			for other: Dictionary in boxes:
				var ob: AABB = other.box
				if other.body == entry.body or ob.end.y <= top + 0.001 or absf(ob.position.y - top) > 0.03:
					continue
				if ob.position.x < box.end.x and ob.end.x > box.position.x and ob.position.z < box.end.z and ob.end.z > box.position.z:
					top = ob.end.y
					flat = other.flat
					top_entry = other
					stacked.append(String(other.name))
					grown = true
		var height: float = top - floor_y
		var top_box: AABB = top_entry.box
		if height < STEP_HEIGHT.x - STEP_TOLERANCE or height > STEP_HEIGHT.y + STEP_TOLERANCE or not flat:
			continue
		if minf(top_box.size.x, top_box.size.z) < FIGHTER_R:
			continue
		var key := "%s@(%.2f, %.2f, %.2f)" % [top_entry.module, top_box.get_center().x, top, top_box.get_center().z]
		if keys.has(key):
			continue
		keys[key] = true
		out.append({"key": key, "body": top_entry.body, "name": top_entry.name, "module": top_entry.module, "height": height,
			"vault": entry.vault, "stacked": stacked, "size": top_box.size, "base": entry.name})
	return out


## A collision shape with a level top: an upright box or cylinder, or a convex hull with ≥ 3 points level with its top.
func _flat_top(shape: CollisionShape3D) -> bool:
	var up: Vector3 = shape.global_transform.basis.y.normalized()
	if shape.shape is BoxShape3D or shape.shape is CylinderShape3D:
		return up.dot(Vector3.UP) > 0.999
	if shape.shape is ConvexPolygonShape3D:
		var points: PackedVector3Array = (shape.shape as ConvexPolygonShape3D).points
		var high: float = -INF
		for point: Vector3 in points:
			high = maxf(high, (shape.global_transform * point).y)
		var level: int = 0
		for point: Vector3 in points:
			level += int(absf((shape.global_transform * point).y - high) <= 0.01)
		return level >= 3
	return false


func _v_steps() -> void:
	var candidates: Array[Dictionary] = _step_candidates()
	var seen: Dictionary = {}
	var steps: int = 0
	var vaults: int = 0
	for c: Dictionary in candidates:
		var label := "%s «%s» %.2f m high, top %.2f × %.2f m%s" % [c.key, c.name, c.height, c.size.x, c.size.z, (" on " + c.base) if not (c.stacked as Array).is_empty() else ""]
		if c.vault:
			vaults += 1
			print("CITY_TIDY_INFO V+ vault %s" % label)
			continue
		if STEP_PROPS.has(c.key):
			steps += 1
			seen[c.key] = true
			print("CITY_TIDY_INFO V+ step %s — %s" % [label, STEP_PROPS[c.key]])
			continue
		_check(false, "V+ %s has a flat top 0.6–1.3 m over the floor: neither a vault obstacle nor a listed step" % label)
	for key: String in STEP_PROPS:
		_check(seen.has(key), "V+ the listed step %s (%s) is no longer a floor body with a flat top 0.6–1.3 m" % [key, STEP_PROPS[key]])
	print("CITY_TIDY_INFO V+ candidates=%d vaults=%d steps=%d listed=%d" % [candidates.size(), vaults, steps, STEP_PROPS.size()])


## V+ wedge (see STEP_GAP_BAND): every listed step, each side (±x, ±z), STEP_SAMPLES points across it.
func _v_wedges() -> void:
	var wedges: int = 0
	var sides: int = 0
	var blocked: int = 0
	var seen_open: Dictionary = {}
	for c: Dictionary in _step_candidates():
		if c.vault or not STEP_PROPS.has(c.key):
			continue
		var body: StaticBody3D = c.body
		var shape: CollisionShape3D = _top_shape(body)
		var top: float = _body_box(body).end.y
		var floor_y: float = top - float(c.height)
		var centre: Vector3 = _step_centre(shape)
		for out: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
			var across := Vector3(absf(out.z), 0, absf(out.x))
			var half: float = _step_extent(shape, across)
			var counts := {"top": 0, "off": 0, "wedge": 0, "blocked": 0, "open": 0}
			var narrowest: float = INF
			var worst: Dictionary = {}
			for i: int in STEP_SAMPLES:
				var s: float = lerpf(-half + 0.03, half - 0.03, float(i) / float(STEP_SAMPLES - 1))
				var at: Vector3 = centre + across * s
				var w: Dictionary = _step_walk(at, out, _step_edge(shape, out, s), top, floor_y, body)
				counts[w.result] = int(counts[w.result]) + 1
				if w.has("gap"):
					narrowest = minf(narrowest, float(w.gap))
				if w.result == "wedge" and (worst.is_empty() or float(w.depth) > float(worst.depth)):
					worst = w
			sides += 1
			blocked += int(int(counts.blocked) == STEP_SAMPLES)
			var tag := "%s %s" % [c.key, _v(out)]
			var label := "%s «%s» side %s" % [c.key, c.name, _v(out)]
			var wedged: bool = int(counts.wedge) > 0
			if STEP_WEDGE_OPEN.has(tag):
				seen_open[tag] = true
				var pinned: float = float(STEP_WEDGE_OPEN[tag].gap)
				_check(wedged and absf(narrowest - pinned) <= 0.02, "V+ wedge OPEN %s no longer wedges as pinned (%d of %d points, gap %.3f, pinned %.3f): fix STEP_WEDGE_OPEN" % [label, counts.wedge, STEP_SAMPLES, narrowest, pinned])
			else:
				wedges += int(wedged)
				_check(not wedged, "V+ wedge %s: a hero pressed to %s %.3f m off the edge rests %.3f m under the top on its rim (%d of %d points; T6 К7-а п. 2: ≤ %.2f m or off the step)" % [label, worst.get("wall", "?"), worst.get("gap", 0.0), worst.get("depth", 0.0), counts.wedge, STEP_SAMPLES, STEP_RIM])
			print("CITY_TIDY_INFO V+ wedge %s %s narrowest=%s%s" % [label, JSON.stringify(counts), "none" if is_inf(narrowest) else "%.3f" % narrowest,
				(" worst=%.3f under, by %s" % [worst.depth, worst.wall]) if wedged else ""])
	for tag: String in STEP_WEDGE_OPEN:
		_check(seen_open.has(tag), "V+ wedge OPEN %s is no longer a listed step side: fix STEP_WEDGE_OPEN" % tag)
	_check(wedges == 0, "V+ no listed step wedges a hero on its rim (%d sides)" % wedges)
	print("CITY_TIDY_INFO V+ wedge sides=%d wedges=%d open=%d blocked_sides=%d" % [sides, wedges, seen_open.size(), blocked])


## The highest collision shape of a body (its top for V+).
func _top_shape(body: StaticBody3D) -> CollisionShape3D:
	var best: CollisionShape3D = null
	var high: float = -INF
	for child: Node in body.get_children():
		var shape := child as CollisionShape3D
		if shape == null or shape.shape == null or shape.disabled:
			continue
		var end: float = (shape.global_transform * shape.shape.get_debug_mesh().get_aabb()).end.y
		if end > high:
			high = end
			best = shape
	return best


func _step_centre(shape: CollisionShape3D) -> Vector3:
	if shape.shape is BoxShape3D or shape.shape is CylinderShape3D:
		var o: Vector3 = shape.global_transform.origin
		return Vector3(o.x, 0, o.z)
	var c: Vector3 = (shape.global_transform * shape.shape.get_debug_mesh().get_aabb()).get_center()
	return Vector3(c.x, 0, c.z)


## Half the top's width along the floor direction `dir`.
func _step_extent(shape: CollisionShape3D, dir: Vector3) -> float:
	if shape.shape is CylinderShape3D:
		return (shape.shape as CylinderShape3D).radius
	if shape.shape is BoxShape3D:
		var half: Vector3 = (shape.shape as BoxShape3D).size * 0.5
		var b: Basis = shape.global_transform.basis.orthonormalized()
		return absf(b.x.dot(dir)) * half.x + absf(b.z.dot(dir)) * half.z
	var box: AABB = shape.global_transform * shape.shape.get_debug_mesh().get_aabb()
	return absf(dir.x) * box.size.x * 0.5 + absf(dir.z) * box.size.z * 0.5


## How far the top reaches along `out` at `s` across it: a round top's chord, a flat top's half width.
func _step_edge(shape: CollisionShape3D, out: Vector3, s: float) -> float:
	if shape.shape is CylinderShape3D:
		var r: float = (shape.shape as CylinderShape3D).radius
		return sqrt(maxf(r * r - s * s, 0.0))
	return _step_extent(shape, out)


## One point of V+ wedge: the capsule stands on the top at `at` (its body inside the edge, STEP_LIFT over the top), walks
## along `out` until it meets a solid with its axis at most STEP_GAP_BAND.y − FIGHTER_R past the edge, and is lowered.
## result: blocked (no room to stand), open (nothing met), top, off (rests off the step: floor, another body), wedge.
func _step_walk(at: Vector3, out: Vector3, edge: float, top: float, floor_y: float, body: StaticBody3D) -> Dictionary:
	var capsule := CapsuleShape3D.new()
	capsule.radius = FIGHTER_R
	capsule.height = FIGHTER_H
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	query.exclude = [(world.player as CollisionObject3D).get_rid()]
	var feet: float = top + STEP_LIFT
	var inset: float = maxf(0.0, edge - FIGHTER_R - 0.01)
	var start: Vector3 = at + out * inset + Vector3(0, feet + FIGHTER_H * 0.5, 0)
	# A step flush with a wall leaves no room for the capsule over its middle: the hero stands a little off it. Try the
	# start, then the STEP_NUDGES round it, keeping the axis over the top (`body` under it).
	var free: bool = false
	for nudge: Vector3 in STEP_NUDGES:
		query.transform = Transform3D(Basis.IDENTITY, start + nudge)
		if space.intersect_shape(query, 1).is_empty() and _over_body(start + nudge, feet, body):
			start += nudge
			inset += nudge.dot(out)
			free = true
			break
	if not free:
		return {"result": "blocked"}
	var reach: float = maxf(edge - inset, 0.0) + STEP_GAP_BAND.y - FIGHTER_R
	query.motion = out * reach
	var walk: PackedFloat32Array = space.cast_motion(query)
	if walk[0] >= 1.0:
		return {"result": "open"}
	var gap: float = inset + float(walk[0]) * reach - edge + FIGHTER_R
	var walls: PackedStringArray = PackedStringArray()
	query.motion = Vector3.ZERO
	query.transform = Transform3D(Basis.IDENTITY, start + out * (float(walk[1]) * reach))
	for hit: Dictionary in space.intersect_shape(query, 4):
		walls.append(_body_label(hit.collider as Node))
	var axis: Vector3 = start + out * (float(walk[0]) * reach)
	var drop: float = feet - floor_y + 0.1
	query.transform = Transform3D(Basis.IDENTITY, axis)
	query.motion = Vector3(0, -drop, 0)
	var down: PackedFloat32Array = space.cast_motion(query)
	var rest: float = feet - float(down[0]) * drop
	var touches: bool = false
	query.motion = Vector3.ZERO
	query.transform = Transform3D(Basis.IDENTITY, axis - Vector3(0, float(down[1]) * drop, 0))
	for hit: Dictionary in space.intersect_shape(query, 8):
		touches = touches or hit.collider == body
	var result: String = "top" if rest >= top - STEP_RIM else ("wedge" if touches else "off")
	return {"result": result, "gap": gap, "depth": top - rest, "wall": ",".join(walls)}


## Whether the point under `axis` (the capsule's axis) on the top is `body`'s.
func _over_body(axis: Vector3, feet: float, body: StaticBody3D) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(Vector3(axis.x, feet, axis.z), Vector3(axis.x, feet - 0.1, axis.z), 1)
	ray.exclude = [(world.player as CollisionObject3D).get_rid()]
	var hit: Dictionary = space.intersect_ray(ray)
	return not hit.is_empty() and hit.collider == body


## «<parent>/<name>» of a body, or «<parent>/<engine name>@(x, z)» for the engine's own @-names, which change with the
## node count.
static func _body_label(node: Node) -> String:
	var name: String = String(node.name)
	if name.begins_with("@"):
		var at: Vector3 = (node as Node3D).global_position
		name = "%s@(%.2f, %.2f)" % [node.get_class(), at.x, at.z]
	return "%s/%s" % [String(node.get_parent().name), name]


func _vault_run(start: Vector3, run: Vector3, center: Vector3, depth: float) -> Dictionary:
	var player: Node3D = world.player
	_key(KEY_W, false)
	_key(KEY_SPACE, false)
	player.restart_at(start)
	player._set_forward(run)
	world.camera_rig.reset_view()
	world.camera_rig.aim.yaw_offset = atan2(-run.x, -run.z)
	await _ticks(10)
	var out: Dictionary = {"ticks": 0, "hang": false, "end": start, "landed": INF, "speed": 0.0}
	_key(KEY_W, true)
	var jumped: bool = false
	var held: int = 0
	for tick: int in 240:
		var along: float = (player.global_position - center).dot(run)
		if not jumped and along >= -depth * 0.5 - 1.15 and player.is_on_floor():
			jumped = true
			out.speed = Vector2(player.velocity.x, player.velocity.z).length()
			_key(KEY_SPACE, true)
		await _ticks(1)
		if jumped:
			held += 1
			if held == 2:
				_key(KEY_SPACE, false)
		var phase: String = player.parkour.phase
		if phase == "vault":
			out.ticks = int(out.ticks) + 1
		out.hang = bool(out.hang) or phase in ["hang", "mantle"]
		if jumped and held > 10 and player.is_on_floor() and phase.is_empty() and player.state != fighter_script.State.JUMP:
			out.landed = player.global_position.y
			break
	_key(KEY_W, false)
	_key(KEY_SPACE, false)
	out.end = player.global_position
	await _ticks(4)
	return out


# --- S -----------------------------------------------------------------------------------------------------------
func _steam() -> void:
	var vents: Array[Node] = []
	for child: Node in props_node.get_children():
		if child is CitySteamVent:
			vents.append(child)
	_check(vents.size() == 2, "S two steam vents (%d)" % vents.size())
	var player: Node3D = world.player
	for node: Node in vents:
		var vent: CitySteamVent = node as CitySteamVent
		vent.set_process(false)
		if mutation == "steam_hero":
			vent.hero_clear = 0.0
		if mutation == "steam_flash":
			vent.frame_seconds = 0.1
		player.restart_at(CityLayout.spawn_position())
		await _ticks(3)
		vent.clock = 0.0
		vent.step(0.0)
		var peak: float = 0.0
		var jump: float = 0.0
		var changes: int = 0
		var shown: float = 0.0
		var last_alpha: float = vent.puff_alpha()
		var last_frame: int = vent.puff_frame()
		for tick: int in roundi(vent.period / DT):
			vent.step(DT)
			var alpha: float = vent.puff_alpha()
			peak = maxf(peak, alpha)
			jump = maxf(jump, absf(alpha - last_alpha))
			if alpha > 0.01:
				shown += DT
				if vent.puff_frame() != last_frame:
					changes += 1
			last_alpha = alpha
			last_frame = vent.puff_frame()
		var rate: float = float(changes) / maxf(shown, DT)
		_check(peak >= 0.5 and peak <= 0.8 + 0.001, "S %s puffs at ≤ 0.8 opacity (peak %.2f)" % [vent.get_path(), peak])
		_check(rate < FLASH_HZ, "S %s changes frame %.2f times a second (< %.0f)" % [vent.get_path(), rate, FLASH_HZ])
		_check(jump <= 0.1, "S %s never jumps in opacity by more than 0.1 a frame (%.3f)" % [vent.get_path(), jump])
		var size: Vector2 = CitySteamVent.CELL * vent.sprite.pixel_size
		_check(size.x <= PUFF_SIZE.x and size.y <= PUFF_SIZE.y, "S %s puff is %.2f × %.2f m (≤ %.1f × %.1f)" % [vent.get_path(), size.x, size.y, PUFF_SIZE.x, PUFF_SIZE.y])
		_check(vent.sprite.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "S %s puff casts no shadow" % vent.get_path())
		player.restart_at(vent.global_position + Vector3(0.6, 0, 0))
		await _ticks(3)
		vent.clock = 0.0
		var over_hero: float = 0.0
		for tick: int in roundi(vent.period / DT):
			vent.step(DT)
			if float(tick) * DT >= 0.5:
				over_hero = maxf(over_hero, vent.puff_alpha())
		_check(over_hero <= 0.02, "S %s holds the puff while a hero stands at it (peak %.3f)" % [vent.get_path(), over_hero])
		print("CITY_TIDY_INFO S %s peak=%.2f rate=%.2f jump=%.3f over_hero=%.3f size=%.2fx%.2f" % [vent.get_path(), peak, rate, jump, over_hero, size.x, size.y])
		vent.set_process(true)


# --- M: the steam vehicles ---------------------------------------------------------------------------------------
## Each vehicle of CityProps.VEHICLES as built in the live world: its node, visible meshes, hulls and footprint.
func _vehicles() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for spec: Dictionary in props_node.get_meta("vehicles", []):
		var node: Node3D = props_node.get_node_or_null("Vehicle_" + String(spec.id))
		var meshes: Array[MeshInstance3D] = []
		var bodies: Array[StaticBody3D] = []
		var box := AABB()
		if node != null:
			for n: Node in node.find_children("*", "MeshInstance3D", true, false):
				var mesh := n as MeshInstance3D
				if mesh.mesh == null or not mesh.is_visible_in_tree():
					continue
				var world_box: AABB = mesh.global_transform * mesh.get_aabb()
				box = world_box if meshes.is_empty() else box.merge(world_box)
				meshes.append(mesh)
			for n: Node in node.find_children("*", "StaticBody3D", true, false):
				bodies.append(n as StaticBody3D)
		var rids: Array[RID] = []
		for body: StaticBody3D in bodies:
			rids.append(body.get_rid())
		# The street level the vehicle stands on: the floor under its footprint centre, its own hulls excluded.
		var level: float = 0.0
		if not meshes.is_empty():
			var at := Vector3(box.get_center().x, box.position.y + 1.0, box.get_center().z)
			var query := PhysicsRayQueryParameters3D.create(at, at - Vector3.UP * 3.0, 1)
			query.exclude = rids
			var hit: Dictionary = space.intersect_ray(query)
			level = float(hit.position.y) if not hit.is_empty() else box.position.y
		out.append({"id": String(spec.id), "node": node, "meshes": meshes, "bodies": bodies, "rids": rids, "box": box,
			"foot": Rect2(Vector2(box.position.x, box.position.z), Vector2(box.size.x, box.size.z)), "level": level})
	return out


static func _rect_point(r: Rect2, p: Vector2) -> float:
	var dx: float = maxf(0.0, maxf(r.position.x - p.x, p.x - r.end.x))
	var dz: float = maxf(0.0, maxf(r.position.y - p.y, p.y - r.end.y))
	return sqrt(dx * dx + dz * dz)


static func _rect_rect(a: Rect2, b: Rect2) -> float:
	var dx: float = maxf(0.0, maxf(a.position.x - b.end.x, b.position.x - a.end.x))
	var dz: float = maxf(0.0, maxf(a.position.y - b.end.y, b.position.y - a.end.y))
	return sqrt(dx * dx + dz * dz)


func _m_vehicles() -> void:
	var vehicles: Array[Dictionary] = _vehicles()
	_check(vehicles.size() == 2, "M the two steam vehicles are listed (%d)" % vehicles.size())
	var supports: Array[Dictionary] = CityLayout.anchor_supports()
	var director: Script = load("res://scripts/npc/CityNpcDirector.gd")
	for v: Dictionary in vehicles:
		var id: String = v.id
		var meshes: Array[MeshInstance3D] = v.meshes
		var bodies: Array[StaticBody3D] = v.bodies
		_check(v.node != null and meshes.size() == 1, "M1 %s has one visible mesh (%d)" % [id, meshes.size()])
		_check(not bodies.is_empty(), "M1 %s has its hulls (%d bodies)" % [id, bodies.size()])
		if meshes.is_empty():
			continue
		for body: StaticBody3D in bodies:
			var shapes: int = 0
			for child: Node in body.get_children():
				if child is CollisionShape3D and not (child as CollisionShape3D).disabled and (child as CollisionShape3D).shape != null:
					shapes += 1
			_check(body.collision_layer == VEHICLE_LAYER and body.collision_mask == 0 and shapes >= 1,
				"M1 %s/%s is a city solid: layer %d (%d), mask %d (0), %d live shapes" % [id, body.name, body.collision_layer, VEHICLE_LAYER, body.collision_mask, shapes])
		# M2: one manner with the district — the city shader material of the very name the GLB gave the surface.
		var surfaces: int = 0
		var wrong: Array[String] = []
		for mesh: MeshInstance3D in meshes:
			for surface: int in mesh.mesh.get_surface_count():
				surfaces += 1
				var source: Material = mesh.mesh.surface_get_material(surface)
				var want: String = source.resource_name if source != null else "?"
				var override: Material = mesh.get_surface_override_material(surface)
				var got: String = _material_key(override) if override != null else "none"
				if not override is ShaderMaterial or got != want:
					wrong.append("%d:%s→%s" % [surface, want, got])
		_check(surfaces > 0 and wrong.is_empty(), "M2 %s: every one of %d surfaces is the city material it names (%s)" % [id, surfaces, ", ".join(wrong)])
		# M3: a level floor under the footprint, the bottom on it within 2 cm.
		var box: AABB = v.box
		var foot: Rect2 = v.foot
		var floors: Array[float] = []
		for f: Vector2 in [Vector2(0.1, 0.1), Vector2(0.9, 0.1), Vector2(0.1, 0.9), Vector2(0.9, 0.9), Vector2(0.5, 0.5)]:
			var at := Vector3(foot.position.x + foot.size.x * f.x, box.position.y + 1.0, foot.position.y + foot.size.y * f.y)
			var query := PhysicsRayQueryParameters3D.create(at, at - Vector3.UP * 3.0, 1)
			query.exclude = v.rids
			var hit: Dictionary = space.intersect_ray(query)
			floors.append(float(hit.position.y) if not hit.is_empty() else -INF)
		var floor_high: float = floors.max()
		var floor_low: float = floors.min()
		var gap: float = box.position.y - floor_high
		_check(floor_low > -INF and floor_high - floor_low <= SUPPORT_GAP, "M3 %s stands on a level floor (%.3f…%.3f)" % [id, floor_low, floor_high])
		_check(absf(gap) <= SUPPORT_GAP, "M3 %s %s %.3f m (bottom %.3f, floor %.3f)" % [id, "rests within" if absf(gap) <= SUPPORT_GAP else ("floats" if gap > 0.0 else "sinks"), absf(gap), box.position.y, floor_high])
		# M4: a visible face in the hero band 0.1 m out of every collider — a free hero capsule would walk into it.
		var examined: int = 0
		var bare: Array[String] = []
		var reach: float = HERO_R - PASS_THROUGH
		for mesh: MeshInstance3D in meshes:
			var faces: PackedVector3Array = mesh.mesh.get_faces()
			var xf: Transform3D = mesh.global_transform
			for i: int in range(0, faces.size(), 3):
				var a: Vector3 = xf * faces[i]
				var b: Vector3 = xf * faces[i + 1]
				var c: Vector3 = xf * faces[i + 2]
				var centre: Vector3 = (a + b + c) / 3.0
				if centre.y < floor_high + BAND.x or centre.y > floor_high + BAND.y:
					continue
				var normal: Vector3 = (b - a).cross(c - a)
				if normal.length() < 0.000001:
					continue
				normal = normal.normalized()
				if absf(normal.y) > 0.7:
					continue
				examined += 1
				var flat := Vector3(normal.x, 0, normal.z).normalized()
				for side: float in [1.0, -1.0]:
					var axis: Vector3 = centre + flat * side * reach
					var hit: Dictionary = _floor_under(Vector3(axis.x, floor_high + 0.5, axis.z), 1.0)
					if hit.is_empty() or absf(float(hit.position.y) - floor_high) > SUPPORT_WINDOW:
						continue
					if _capsule_free(Vector3(axis.x, float(hit.position.y), axis.z)):
						if bare.size() < 6:
							bare.append(_v(centre))
						else:
							bare.append("")
						break
		_check(examined > 100, "M4 %s: the hero-band faces were found (%d)" % [id, examined])
		_check(bare.is_empty(), "M4 %s: no visible face in the hero band stands %.2f m out of every collider (%d: %s)" % [id, PASS_THROUGH, bare.size(), " ".join(bare.slice(0, 6))])
		print("CITY_TIDY_INFO M %s box=%s floor=%.3f faces=%d bare=%d bodies=%d" % [id, box, floor_high, examined, bare.size(), bodies.size()])
		# M5: out of every anchor's column; a free swing on every rope clears the top by 0.3 m.
		var worst: float = INF
		var worst_index: int = -1
		var column_bad: int = 0
		for index: int in mini(supports.size(), ANCHOR_FLOOR.size()):
			var point: Vector3 = supports[index].point
			var d: float = _rect_point(foot, Vector2(point.x, point.z))
			if d < ANCHOR_COLUMN and box.position.y < point.y:
				column_bad += 1
				_check(false, "M5 %s stands in anchor %d's column (%.2f m < %.2f)" % [id, index, d, ANCHOR_COLUMN])
			var rope: float = maxf(SWING_MIN_ROPE, point.y - ANCHOR_FLOOR[index] - SWING_HAND - SWING_FLOOR_GAP)
			if d >= rope + FIGHTER_R:
				continue
			var s: float = maxf(0.0, d - FIGHTER_R)
			var feet: float = point.y - sqrt(maxf(0.0, rope * rope - s * s)) - SWING_HAND
			if feet - box.end.y < worst:
				worst = feet - box.end.y
				worst_index = index
		_check(column_bad == 0, "M5 %s stands out of every anchor column (%d)" % [id, column_bad])
		_check(worst >= SWING_CLEAR, "M5 %s: every free rope swing passes ≥ %.1f m over it (worst %s, anchor %d)" % [id, SWING_CLEAR, "none in reach" if worst == INF else "%.2f m" % worst, worst_index])
		# M6: the court, the pockets, the resident lanes.
		var court: float = _rect_point(foot, Vector2.ZERO)
		_check(court >= COURT_CLEAR, "M6 %s stands %.2f m from the court centre (≥ %.0f)" % [id, court, COURT_CLEAR])
		for pocket: Dictionary in CityLayout.combat_pockets():
			var edge: float = _rect_point(foot, Vector2(pocket.center.x, pocket.center.z)) - float(pocket.radius)
			_check(edge >= 0.0, "M6 %s stays out of the %s pocket (%.2f m from its edge)" % [id, pocket.id, edge])
		var lane_min: float = INF
		var lane_who: int = -1
		for resident: int in range(3, 12):
			var lane: Array = director.lane(resident)
			var r := Rect2(Vector2(lane[0].x, lane[0].z), Vector2.ZERO)
			for corner: Vector3 in lane:
				r = r.expand(Vector2(corner.x, corner.z))
			var d: float = _rect_rect(foot, r)
			if d < lane_min:
				lane_min = d
				lane_who = resident
		_check(lane_min >= LANE_CLEAR, "M6 %s keeps %.0f m from every resident lane (%.2f m from lane %d)" % [id, LANE_CLEAR, lane_min, lane_who])
		# M7: both run-ups of every vault obstacle stay free of it.
		var taken: Array[String] = []
		for spec: Dictionary in props_node.get_meta("obstacles", []):
			var run: Vector3 = spec.run
			var depth: float = absf((spec.size as Vector3).dot(run))
			var centre: Vector3 = spec.center
			for side: float in [1.0, -1.0]:
				var near: Vector3 = centre - run * side * (depth * 0.5 + RUN_UP.x)
				var far: Vector3 = centre - run * side * (depth * 0.5 + RUN_UP.y)
				var r := Rect2(Vector2(near.x, near.z), Vector2.ZERO).expand(Vector2(far.x, far.z)).grow(HERO_R)
				if r.intersects(foot):
					taken.append("%s %+.0f" % [spec.id, side])
		_check(taken.is_empty(), "M7 %s takes no run-up of a vault obstacle (%s)" % [id, ", ".join(taken)])
		print("CITY_TIDY_INFO M %s court=%.2f lane=%.2f(%d) swing_margin=%s anchor=%d runups_taken=%d" % [id, court, lane_min, lane_who, "inf" if worst == INF else "%.2f" % worst, worst_index, taken.size()])


## M8: the camera near each vehicle — a hero 1.2 m off each open side facing it, and on its roof facing each way.
func _m_camera() -> void:
	var player: Node3D = world.player
	var rig: Node3D = world.camera_rig
	world.npc_director.process_mode = Node.PROCESS_MODE_DISABLED
	for v: Dictionary in _vehicles():
		if (v.meshes as Array).is_empty():
			continue
		var box: AABB = v.box
		var centre := Vector3(box.get_center().x, 0, box.get_center().z)
		var stations: Array[Array] = []
		for out: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
			var reach: float = absf(out.x) * box.size.x * 0.5 + absf(out.z) * box.size.z * 0.5 + STATION_GAP
			var at: Vector3 = centre + out * reach
			var hit: Dictionary = _floor_under(at + Vector3(0, 0.5, 0), 1.0)
			if hit.is_empty() or absf(float(hit.position.y) - float(v.level)) > 0.05 or not _capsule_free(Vector3(at.x, float(hit.position.y), at.z)):
				print("CITY_TIDY_INFO M8 %s side %s: no hero stands there" % [v.id, _v(out)])
				continue
			stations.append([Vector3(at.x, float(hit.position.y), at.z), -out, "side " + _v(out)])
		_check(not stations.is_empty(), "M8 %s has an open side to stand at" % v.id)
		var roof := Vector3(centre.x, 0, centre.z)
		var top: Dictionary = _floor_under(Vector3(roof.x, box.end.y + 0.5, roof.z), box.size.y)
		if not top.is_empty() and float(top.position.y) > float(v.level) + 1.0:
			for face: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
				stations.append([Vector3(roof.x, float(top.position.y), roof.z), face, "roof facing " + _v(face)])
		for station: Array in stations:
			var face: Vector3 = station[1]
			player.restart_at(station[0])
			player._set_forward(face)
			rig.reset_view()   # first: it resets the yaw; then the lens goes behind the hero, as in _vault_run
			rig.aim.yaw_offset = atan2(-face.x, -face.z)
			await _ticks(20)
			var arm: float = rig.arm.get_hit_length()
			_check(arm >= CAMERA_SPACE, "M8 %s: the camera arm at %s (%s) keeps ≥ %.0f m (%.2f m)" % [v.id, _v(station[0]), station[2], CAMERA_SPACE, arm])
			print("CITY_TIDY_INFO M8 %s %s at %s arm=%.2f" % [v.id, station[2], _v(player.global_position), arm])
	world.npc_director.process_mode = Node.PROCESS_MODE_INHERIT


## V-M (К7): both heroes run at each open side of each vehicle with W and Space, as at a vault obstacle. A vehicle is
## deeper than any obstacle, so the motor must never vault it; the hero ends on the floor or on top, never inside.
func _vehicle_runs(hero: String) -> void:
	world.npc_director.process_mode = Node.PROCESS_MODE_DISABLED
	for v: Dictionary in _vehicles():
		if (v.meshes as Array).is_empty():
			continue
		var box: AABB = v.box
		var centre := Vector3(box.get_center().x, 0, box.get_center().z)
		var runs: int = 0
		for out: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
			world.player.restart_at(CityLayout.spawn_position())   # the hero's own capsule is no run-up obstacle
			await _ticks(2)
			var depth: float = absf(out.x) * box.size.x + absf(out.z) * box.size.z
			var start: Vector3 = centre + out * (depth * 0.5 + 5.0)
			var clear: bool = true
			var s: float = 0.0
			while s <= 4.3:
				var at: Vector3 = start - out * s
				var hit: Dictionary = _floor_under(at + Vector3(0, 0.5, 0), 1.0)
				clear = clear and not hit.is_empty() and absf(float(hit.position.y) - float(v.level)) < 0.05 and _capsule_free(at)
				s += 0.5
			if not clear:
				continue
			runs += 1
			var result: Dictionary = await _vehicle_run(start, -out, centre, depth)
			var end: Vector3 = result.end
			var inside: bool = absf(end.x - centre.x) < box.size.x * 0.5 - 0.05 and absf(end.z - centre.z) < box.size.z * 0.5 - 0.05 and end.y < box.end.y - 0.3
			_check(int(result.vault) == 0, "V-M %s: no vault over %s from %s (%d vault ticks)" % [hero, v.id, _v(start), result.vault])
			_check(not inside, "V-M %s is not left inside %s after the run from %s (end %s)" % [hero, v.id, _v(start), _v(end)])
			var under: Dictionary = _floor_under(end + Vector3(0, 0.3, 0), 1.0)
			var stood: String = "nothing" if under.is_empty() else "%s %s" % [String((under.collider as Node).get_parent().name) + "/" if String((under.collider as Node).get_parent().name).begins_with("Vehicle_") else "", (under.collider as Node).name]
			print("CITY_TIDY_INFO V-M %s %s from %s: phases=%s end=%s on=%s" % [hero, v.id, _v(start), ",".join(result.phases), _v(end), stood])
		_check(runs >= 1, "V-M %s: %s has a free run-up from at least one side (%d)" % [hero, v.id, runs])
	world.npc_director.process_mode = Node.PROCESS_MODE_INHERIT


func _vehicle_run(start: Vector3, run: Vector3, centre: Vector3, depth: float) -> Dictionary:
	var player: Node3D = world.player
	_key(KEY_W, false)
	_key(KEY_SPACE, false)
	player.restart_at(start)
	player._set_forward(run)
	world.camera_rig.reset_view()
	world.camera_rig.aim.yaw_offset = atan2(-run.x, -run.z)
	await _ticks(10)
	var out: Dictionary = {"vault": 0, "phases": PackedStringArray(), "end": start}
	_key(KEY_W, true)
	var jumped: bool = false
	var held: int = 0
	var last: String = ""
	var phases := PackedStringArray()   # a value type: kept local, stored in `out` at the end
	for tick: int in 150:
		var along: float = (player.global_position - centre).dot(run)
		if not jumped and along >= -depth * 0.5 - 1.15 and player.is_on_floor():
			jumped = true
			_key(KEY_SPACE, true)
		await _ticks(1)
		if jumped:
			held += 1
			if held == 2:
				_key(KEY_SPACE, false)
		var phase: String = player.parkour.phase
		if phase == "vault":
			out.vault = int(out.vault) + 1
		if phase != last:
			phases.append(phase if not phase.is_empty() else "-")
			last = phase
		if jumped and held > 60 and phase.is_empty() and player.is_on_floor():
			break
	_key(KEY_W, false)
	_key(KEY_SPACE, false)
	await _ticks(4)
	out.end = player.global_position
	out.phases = phases
	return out


# --- MC: the terrace machines --------------------------------------------------------------------------------------
## Each machine of CityProps.MACHINES as built in the live world: its node, visible meshes, hulls (world boxes), its foot
## (the hulls standing on the floor) and the floor under the foot's centre, its own hulls excluded.
func _machines() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for spec: Dictionary in props_node.get_meta("machines", []):
		var node: Node3D = props_node.get_node_or_null("Machine_" + String(spec.id))
		var meshes: Array[MeshInstance3D] = []
		var bodies: Array[StaticBody3D] = []
		var hulls: Array[Dictionary] = []
		var box := AABB()
		if node != null:
			for n: Node in node.find_children("*", "MeshInstance3D", true, false):
				var mesh := n as MeshInstance3D
				if mesh.mesh == null or not mesh.is_visible_in_tree():
					continue
				var world_box: AABB = mesh.global_transform * mesh.get_aabb()
				box = world_box if meshes.is_empty() else box.merge(world_box)
				meshes.append(mesh)
			for n: Node in node.find_children("*", "StaticBody3D", true, false):
				var body := n as StaticBody3D
				bodies.append(body)
				var hull := AABB()
				var shapes: int = 0
				for child: Node in body.get_children():
					var shape := child as CollisionShape3D
					if shape == null or shape.shape == null or shape.disabled:
						continue
					var shape_box: AABB = shape.global_transform * shape.shape.get_debug_mesh().get_aabb()
					hull = shape_box if shapes == 0 else hull.merge(shape_box)
					shapes += 1
				if shapes > 0:
					hulls.append({"name": String(body.name), "body": body, "box": hull})
		var rids: Array[RID] = []
		for body: StaticBody3D in bodies:
			rids.append(body.get_rid())
		var origin_y: float = node.global_position.y if node != null else 0.0
		var foot_box := AABB()
		var feet: int = 0
		for hull: Dictionary in hulls:
			var hb: AABB = hull.box
			if hb.position.y <= origin_y + MACHINE_FOOT:
				foot_box = hb if feet == 0 else foot_box.merge(hb)
				feet += 1
		if feet == 0:
			foot_box = box   # no hull on the floor (a negative took it away): the mesh's box stands in
		var foot := Rect2(Vector2(foot_box.position.x, foot_box.position.z), Vector2(foot_box.size.x, foot_box.size.z))
		var level: float = origin_y
		var floor_body: Object = null
		if node != null:
			var at := Vector3(foot.get_center().x, origin_y + 1.0, foot.get_center().y)
			var query := PhysicsRayQueryParameters3D.create(at, at - Vector3.UP * 3.0, 1)
			query.exclude = rids
			var hit: Dictionary = space.intersect_ray(query)
			if not hit.is_empty():
				level = float(hit.position.y)
				floor_body = hit.collider
		out.append({"id": String(spec.id), "node": node, "meshes": meshes, "bodies": bodies, "hulls": hulls, "rids": rids,
			"box": box, "foot": foot, "level": level, "floor": floor_body})
	return out


## The world-space triangles of a machine's visible meshes (three points each).
func _machine_faces(m: Dictionary) -> PackedVector3Array:
	var out := PackedVector3Array()
	for mesh: MeshInstance3D in m.meshes:
		var xf: Transform3D = mesh.global_transform
		for p: Vector3 in mesh.mesh.get_faces():
			out.append(xf * p)
	return out


## The closest point of triangle abc to p (C. Ericson, Real-Time Collision Detection § 5.1.5).
static func _closest_on_triangle(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var ab: Vector3 = b - a
	var ac: Vector3 = c - a
	var ap: Vector3 = p - a
	var d1: float = ab.dot(ap)
	var d2: float = ac.dot(ap)
	if d1 <= 0.0 and d2 <= 0.0:
		return a
	var bp: Vector3 = p - b
	var d3: float = ab.dot(bp)
	var d4: float = ac.dot(bp)
	if d3 >= 0.0 and d4 <= d3:
		return b
	var vc: float = d1 * d4 - d3 * d2
	if vc <= 0.0 and d1 >= 0.0 and d3 <= 0.0:
		return a + ab * (d1 / (d1 - d3))
	var cp: Vector3 = p - c
	var d5: float = ab.dot(cp)
	var d6: float = ac.dot(cp)
	if d6 >= 0.0 and d5 <= d6:
		return c
	var vb: float = d5 * d2 - d1 * d6
	if vb <= 0.0 and d2 >= 0.0 and d6 <= 0.0:
		return a + ac * (d2 / (d2 - d6))
	var va: float = d3 * d6 - d5 * d4
	if va <= 0.0 and d4 - d3 >= 0.0 and d5 - d6 >= 0.0:
		return b + (c - b) * ((d4 - d3) / ((d4 - d3) + (d5 - d6)))
	var denom: float = 1.0 / (va + vb + vc)
	return a + ab * (vb * denom) + ac * (vc * denom)


## The plan box of a collision object's live shapes (the block a machine stands on).
static func _body_box(body: Object) -> AABB:
	var box := AABB()
	var first: bool = true
	if body is Node:
		for child: Node in (body as Node).get_children():
			var shape := child as CollisionShape3D
			if shape == null or shape.shape == null or shape.disabled:
				continue
			var world_box: AABB = shape.global_transform * shape.shape.get_debug_mesh().get_aabb()
			box = world_box if first else box.merge(world_box)
			first = false
	return box


## MC1–MC7 (the hulls, materials, floor, faces, anchors, places, street) and MC10 (the triangles) of every machine.
func _mc_machines() -> void:
	var machines: Array[Dictionary] = _machines()
	_check(machines.size() == 2, "MC the two terrace machines are listed (%d)" % machines.size())
	var supports: Array[Dictionary] = CityLayout.anchor_supports()
	var director: Script = load("res://scripts/npc/CityNpcDirector.gd")
	for m: Dictionary in machines:
		var id: String = m.id
		var meshes: Array[MeshInstance3D] = m.meshes
		var bodies: Array[StaticBody3D] = m.bodies
		# MC1: one mesh; exactly the hulls of the form, each a live city solid.
		_check(m.node != null and meshes.size() == 1, "MC1 %s has one visible mesh (%d)" % [id, meshes.size()])
		var names := PackedStringArray()
		for body: StaticBody3D in bodies:
			names.append(String(body.name))
		names.sort()
		var want := PackedStringArray(MACHINE_HULLS.get(id, []))
		_check(",".join(names) == ",".join(want), "MC1 %s carries exactly the hulls of the T6 form (%s; want %s)" % [id, ",".join(names), ",".join(want)])
		for body: StaticBody3D in bodies:
			var shapes: int = 0
			for child: Node in body.get_children():
				if child is CollisionShape3D and not (child as CollisionShape3D).disabled and (child as CollisionShape3D).shape != null:
					shapes += 1
			_check(body.collision_layer == VEHICLE_LAYER and body.collision_mask == 0 and shapes >= 1,
				"MC1 %s/%s is a city solid: layer %d (%d), mask %d (0), %d live shapes" % [id, body.name, body.collision_layer, VEHICLE_LAYER, body.collision_mask, shapes])
		if meshes.is_empty():
			continue
		# MC2: the city material of the very name the GLB gave each surface, and no key the form bans.
		var surfaces: int = 0
		var wrong: Array[String] = []
		var banned: Array[String] = []
		var ban: Array = MACHINE_BANNED.get(id, [])
		for mesh: MeshInstance3D in meshes:
			for surface: int in mesh.mesh.get_surface_count():
				surfaces += 1
				var source: Material = mesh.mesh.surface_get_material(surface)
				var named: String = source.resource_name if source != null else "?"
				var override: Material = mesh.get_surface_override_material(surface)
				var got: String = _material_key(override) if override != null else "none"
				if not override is ShaderMaterial or got != named:
					wrong.append("%d:%s→%s" % [surface, named, got])
				if named in ban or got in ban:
					banned.append("%d:%s" % [surface, got])
		_check(surfaces > 0 and wrong.is_empty(), "MC2 %s: every one of %d surfaces is the city material it names (%s)" % [id, surfaces, ", ".join(wrong)])
		_check(banned.is_empty(), "MC2 %s carries no %s surface (%s)" % [id, "/".join(PackedStringArray(ban)), ", ".join(banned)])
		# MC3: the foot on a level floor, the lowest point on it within 2 cm.
		var box: AABB = m.box
		var foot: Rect2 = m.foot
		var floors: Array[float] = []
		for f: Vector2 in [Vector2(0.1, 0.1), Vector2(0.9, 0.1), Vector2(0.1, 0.9), Vector2(0.9, 0.9), Vector2(0.5, 0.5)]:
			var at := Vector3(foot.position.x + foot.size.x * f.x, float(m.level) + 1.0, foot.position.y + foot.size.y * f.y)
			var query := PhysicsRayQueryParameters3D.create(at, at - Vector3.UP * 3.0, 1)
			query.exclude = m.rids
			var hit: Dictionary = space.intersect_ray(query)
			floors.append(float(hit.position.y) if not hit.is_empty() else -INF)
		var floor_high: float = floors.max()
		var floor_low: float = floors.min()
		var gap: float = box.position.y - floor_high
		_check(floor_low > -INF and floor_high - floor_low <= SUPPORT_GAP, "MC3 %s stands on a level floor (%.3f…%.3f)" % [id, floor_low, floor_high])
		_check(absf(gap) <= SUPPORT_GAP, "MC3 %s %s %.3f m (bottom %.3f, floor %.3f)" % [id, "rests within" if absf(gap) <= SUPPORT_GAP else ("floats" if gap > 0.0 else "sinks"), absf(gap), box.position.y, floor_high])
		# MC4: the M4 rule — a visible face in the hero band 0.1 m out of every collider lets a free hero into the mesh.
		var examined: int = 0
		var bare: Array[String] = []
		var reach: float = HERO_R - PASS_THROUGH
		var faces: PackedVector3Array = _machine_faces(m)
		for i: int in range(0, faces.size(), 3):
			var a: Vector3 = faces[i]
			var b: Vector3 = faces[i + 1]
			var c: Vector3 = faces[i + 2]
			var centre: Vector3 = (a + b + c) / 3.0
			if centre.y < floor_high + BAND.x or centre.y > floor_high + BAND.y:
				continue
			var normal: Vector3 = (b - a).cross(c - a)
			if normal.length() < 0.000001:
				continue
			normal = normal.normalized()
			if absf(normal.y) > 0.7:
				continue
			examined += 1
			var flat := Vector3(normal.x, 0, normal.z).normalized()
			for side: float in [1.0, -1.0]:
				var axis: Vector3 = centre + flat * side * reach
				var hit: Dictionary = _floor_under(Vector3(axis.x, floor_high + 0.5, axis.z), 1.0)
				if hit.is_empty() or absf(float(hit.position.y) - floor_high) > SUPPORT_WINDOW:
					continue
				if _capsule_free(Vector3(axis.x, float(hit.position.y), axis.z)):
					bare.append(_v(centre))
					break
		_check(examined > 50, "MC4 %s: the hero-band faces were found (%d)" % [id, examined])
		_check(bare.is_empty(), "MC4 %s: no visible face in the hero band stands %.2f m out of every collider (%d: %s)" % [id, PASS_THROUGH, bare.size(), " ".join(bare.slice(0, 6))])
		# MC5: the anchors — out of every column; every free swing clears every point it reaches; ≥ 2 m from each anchor.
		var column_bad: int = 0
		var worst: float = INF
		var worst_index: int = -1
		var nearest: float = INF
		var nearest_what: String = ""
		for index: int in mini(supports.size(), ANCHOR_FLOOR.size()):
			var point: Vector3 = supports[index].point
			var mount: Vector3 = supports[index].mount
			for hull: Dictionary in m.hulls:
				var hb: AABB = hull.box
				var d: float = _rect_point(Rect2(Vector2(hb.position.x, hb.position.z), Vector2(hb.size.x, hb.size.z)), Vector2(point.x, point.z))
				if d < ANCHOR_COLUMN and hb.position.y < point.y:
					column_bad += 1
					_check(false, "MC5 %s/%s stands in anchor %d's column (%.2f m < %.2f)" % [id, hull.name, index, d, ANCHOR_COLUMN])
			var rope: float = maxf(SWING_MIN_ROPE, point.y - ANCHOR_FLOOR[index] - SWING_HAND - SWING_FLOOR_GAP)
			for i: int in range(0, faces.size(), 3):
				for p: Vector3 in [faces[i], faces[i + 1], faces[i + 2], (faces[i] + faces[i + 1] + faces[i + 2]) / 3.0]:
					if p.y >= point.y:
						continue
					var d: float = Vector2(p.x - point.x, p.z - point.z).length()
					if d >= rope + FIGHTER_R:
						continue
					var s: float = maxf(0.0, d - FIGHTER_R)
					var feet: float = point.y - sqrt(maxf(0.0, rope * rope - s * s)) - SWING_HAND
					if feet - p.y < worst:
						worst = feet - p.y
						worst_index = index
				for target: Vector3 in [point, mount]:
					var q: Vector3 = _closest_on_triangle(target, faces[i], faces[i + 1], faces[i + 2])
					var dist: float = q.distance_to(target)
					if dist < nearest:
						nearest = dist
						nearest_what = "anchor %d %s" % [index, "point" if target == point else "mount"]
		_check(column_bad == 0, "MC5 %s stands out of every anchor column (%d)" % [id, column_bad])
		_check(worst >= SWING_CLEAR, "MC5 %s: every free rope swing passes ≥ %.1f m clear of it (worst %s, anchor %d)" % [id, SWING_CLEAR, "none in reach" if worst == INF else "%.2f m" % worst, worst_index])
		_check(nearest >= ANCHOR_REACH, "MC5 %s keeps ≥ %.0f m from every anchor (%.2f m from %s)" % [id, ANCHOR_REACH, nearest, nearest_what])
		# MC6: the court, the pockets (the whole plan of the machine, boom included), the residents' walking band.
		var plan := Rect2(Vector2(box.position.x, box.position.z), Vector2(box.size.x, box.size.z))
		var court: float = _rect_point(plan, Vector2.ZERO)
		_check(court >= COURT_CLEAR, "MC6 %s stands %.2f m from the court centre (≥ %.0f)" % [id, court, COURT_CLEAR])
		for pocket: Dictionary in CityLayout.combat_pockets():
			var edge: float = _rect_point(plan, Vector2(pocket.center.x, pocket.center.z)) - float(pocket.radius)
			_check(edge >= 0.0, "MC6 %s stays out of the %s pocket (%.2f m from its edge)" % [id, pocket.id, edge])
		var lane_min: float = INF
		var lane_who: int = -1
		for resident: int in range(3, 12):
			var lane: Array = director.lane(resident)
			for k: int in lane.size():
				var la: Vector3 = lane[k]
				var lb: Vector3 = lane[(k + 1) % lane.size()]
				for p: Vector3 in faces:
					if p.y > la.y + BAND.y or p.y < la.y - SUPPORT_WINDOW:
						continue
					var closest: Vector2 = Geometry2D.get_closest_point_to_segment(Vector2(p.x, p.z), Vector2(la.x, la.z), Vector2(lb.x, lb.z))
					var d: float = closest.distance_to(Vector2(p.x, p.z))
					if d < lane_min:
						lane_min = d
						lane_who = resident
		_check(lane_min >= LANE_CLEAR, "MC6 %s keeps %.0f m from every resident lane in its walking band (%s from lane %d)" % [id, LANE_CLEAR, "none in the band" if lane_min == INF else "%.2f m" % lane_min, lane_who])
		# MC7: nothing solid over the street — every hull within the plan of the block its foot stands on.
		var block: AABB = _body_box(m.floor)
		var block_rect := Rect2(Vector2(block.position.x, block.position.z), Vector2(block.size.x, block.size.z)).grow(0.01)
		var outside: Array[String] = []
		for hull: Dictionary in m.hulls:
			var hb: AABB = hull.box
			if not block_rect.encloses(Rect2(Vector2(hb.position.x, hb.position.z), Vector2(hb.size.x, hb.size.z))):
				outside.append(String(hull.name))
		_check(m.floor != null and outside.is_empty(), "MC7 %s: every hull stands within %s, nothing solid over the street (%s)" % [id, (m.floor as Node).name if m.floor is Node else "no floor", ", ".join(outside)])
		# MC10: the triangle ceiling.
		var triangles: int = int(faces.size() / 3)
		var ceiling: int = int(MACHINE_TRIANGLES.get(id, 0))
		_check(triangles <= ceiling, "MC10 %s has %d visible triangles (≤ %d)" % [id, triangles, ceiling])
		print("CITY_TIDY_INFO MC %s triangles=%d ceiling=%d surfaces=%d hulls=%s box=%s foot=%s level=%.3f faces=%d bare=%d" % [id, triangles, ceiling, surfaces, ",".join(names), box, foot, floor_high, examined, bare.size()])
		print("CITY_TIDY_INFO MC %s court=%.2f lane=%s(%d) swing_margin=%s anchor=%d nearest_anchor=%.2f (%s) floor=%s" % [id, court, "inf" if lane_min == INF else "%.2f" % lane_min, lane_who, "inf" if worst == INF else "%.2f" % worst, worst_index, nearest, nearest_what, (m.floor as Node).name if m.floor is Node else "-"])


## MC8: the camera on the floor round each machine — a hero 1.2 m off each open side of its foot, facing it.
func _mc_camera() -> void:
	var player: Node3D = world.player
	var rig: Node3D = world.camera_rig
	world.npc_director.process_mode = Node.PROCESS_MODE_DISABLED
	for m: Dictionary in _machines():
		if (m.meshes as Array).is_empty():
			continue
		var foot: Rect2 = m.foot
		var centre := Vector3(foot.get_center().x, float(m.level), foot.get_center().y)
		var stations: Array[Array] = []
		for out: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
			var reach: float = absf(out.x) * foot.size.x * 0.5 + absf(out.z) * foot.size.y * 0.5 + STATION_GAP
			var at: Vector3 = centre + out * reach
			var hit: Dictionary = _floor_under(at + Vector3(0, 0.5, 0), 1.0)
			if hit.is_empty() or absf(float(hit.position.y) - float(m.level)) > 0.05 or not _capsule_free(Vector3(at.x, float(hit.position.y), at.z)):
				print("CITY_TIDY_INFO MC8 %s side %s: no hero stands there" % [m.id, _v(out)])
				continue
			stations.append([Vector3(at.x, float(hit.position.y), at.z), -out, "side " + _v(out)])
		_check(not stations.is_empty(), "MC8 %s has an open side to stand at" % m.id)
		for station: Array in stations:
			var face: Vector3 = station[1]
			player.restart_at(station[0])
			player._set_forward(face)
			rig.reset_view()
			rig.aim.yaw_offset = atan2(-face.x, -face.z)
			await _ticks(20)
			var arm: float = rig.arm.get_hit_length()
			_check(arm >= CAMERA_SPACE, "MC8 %s: the camera arm at %s (%s) keeps ≥ %.0f m (%.2f m)" % [m.id, _v(station[0]), station[2], CAMERA_SPACE, arm])
			print("CITY_TIDY_INFO MC8 %s %s at %s arm=%.2f" % [m.id, station[2], _v(player.global_position), arm])
	world.npc_director.process_mode = Node.PROCESS_MODE_INHERIT


## Every machine's bodies on (their own layers back) or off (layer 0) and its meshes shown or hidden.
func _set_machines(machines: Array[Dictionary], on: bool, layers: Dictionary) -> void:
	for m: Dictionary in machines:
		if m.node != null:
			(m.node as Node3D).visible = on
		for body: StaticBody3D in m.bodies:
			if not is_instance_valid(body):
				continue
			if not on:
				layers[body.get_instance_id()] = body.collision_layer
				body.collision_layer = 0
			else:
				body.collision_layer = int(layers.get(body.get_instance_id(), body.collision_layer))


## A hero at `at` facing `face` with the camera behind him: the arm, the lens and the hero's feet+0.3 / 1.0 / 1.7 m.
func _street_view(at: Vector3, face: Vector3) -> Dictionary:
	var player: Node3D = world.player
	var rig: Node3D = world.camera_rig
	player.restart_at(at)
	player._set_forward(face)
	rig.reset_view()
	rig.aim.yaw_offset = atan2(-face.x, -face.z)
	await _ticks(20)
	var feet: Vector3 = player.global_position
	return {"arm": rig.arm.get_hit_length(), "lens": (rig.camera as Camera3D).global_position, "camera": rig.camera,
		"hero": [feet + Vector3(0, 0.3, 0), feet + Vector3(0, 1.0, 0), feet + Vector3(0, 1.7, 0)], "feet": feet}


## MC7 (street): at S2, S3, S4 of the T6 form a hero facing north. The machines change nothing for the camera (the same
## arm without them), no machine face crosses lens → hero, and at S3 the arm keeps 6.00 m. The machine points in the
## frame, and of them those the lens sees (a ray from it, the machines' own hulls excluded), are printed for T6.
func _mc_street_camera() -> void:
	var machines: Array[Dictionary] = _machines()
	var faces := PackedVector3Array()
	for m: Dictionary in machines:
		faces.append_array(_machine_faces(m))
	world.npc_director.process_mode = Node.PROCESS_MODE_DISABLED
	var layers: Dictionary = {}
	for key: String in STREET_STATIONS:
		var at: Vector3 = STREET_STATIONS[key]
		var with: Dictionary = await _street_view(at, Vector3.FORWARD)
		var camera: Camera3D = with.camera
		var in_frame: int = 0
		var seen: int = 0
		var seen_low: float = INF
		var seen_high: float = -INF
		var own: Array[RID] = []
		for m: Dictionary in machines:
			own.append_array(m.rids)
		for p: Vector3 in faces:
			if not camera.is_position_in_frustum(p):
				continue
			in_frame += 1
			var sight := PhysicsRayQueryParameters3D.create(with.lens, p.lerp(with.lens, 0.02 / maxf(0.02, p.distance_to(with.lens))), 1)
			sight.exclude = own
			if space.intersect_ray(sight).is_empty():
				seen += 1
				seen_low = minf(seen_low, p.y)
				seen_high = maxf(seen_high, p.y)
		var crossing: int = 0
		for hero_point: Vector3 in with.hero:
			for i: int in range(0, faces.size(), 3):
				if Geometry3D.segment_intersects_triangle(with.lens, hero_point, faces[i], faces[i + 1], faces[i + 2]) != null:
					crossing += 1
		_set_machines(machines, false, layers)
		var without: Dictionary = await _street_view(at, Vector3.FORWARD)
		_set_machines(machines, true, layers)
		await _ticks(2)
		_check(absf(float(with.arm) - float(without.arm)) <= 0.001, "MC7 %s %s: the machines change nothing for the street camera (arm %.3f with them, %.3f without)" % [key, _v(at), with.arm, without.arm])
		_check(crossing == 0, "MC7 %s %s: no machine face stands between the lens and the hero (%d crossings)" % [key, _v(at), crossing])
		if key == "S3":
			_check(float(with.arm) >= STREET_ARM - 0.005, "MC7 S3 %s: the arm keeps %.2f m (%.3f)" % [_v(at), STREET_ARM, with.arm])
		_check(seen == 0 or seen_low >= STREET_SEEN_FLOOR - 0.001, "MC7 %s %s: the lens sees no machine point under the terrace's level %.1f m (%s)" % [key, _v(at), STREET_SEEN_FLOOR, "none seen" if seen == 0 else "lowest seen %.2f m" % seen_low])
		print("CITY_TIDY_INFO MC7 %s hero=%s lens=%s arm=%.3f without=%.3f crossing=%d in_frame=%d seen=%d seen_y=%s" % [key, _v(with.feet), _v(with.lens), with.arm, without.arm, crossing, in_frame, seen, "-" if seen == 0 else "%.2f…%.2f" % [seen_low, seen_high]])
	world.npc_director.process_mode = Node.PROCESS_MODE_INHERIT


## How far from one side of `box` (its face toward `out`) nothing stops a hero: a solid (a 4 cm slab of the side's
## length over the hero band) or the floor's edge (three rays down along the side); the machine's own hulls excluded.
## SLOT_MIN when nothing does within it; 0 when the first slab already meets something.
func _side_free(box: AABB, out: Vector3, level: float, rids: Array[RID]) -> float:
	var along: Vector3 = Vector3(absf(out.z), 0, absf(out.x))
	var length: float = (box.size * along).length()
	var half_depth: float = (box.size * out.abs()).length() * 0.5
	var centre := Vector3(box.get_center().x, level, box.get_center().z) + out * half_depth
	var slab := BoxShape3D.new()
	slab.size = along * length + out.abs() * SLOT_STEP + Vector3(0, BAND.y - BAND.x, 0)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = slab
	query.collision_mask = 1
	query.exclude = rids
	var d: float = SLOT_STEP * 0.5
	while d < SLOT_MIN:
		query.transform = Transform3D(Basis.IDENTITY, centre + out * d + Vector3(0, (BAND.x + BAND.y) * 0.5, 0))
		if not space.intersect_shape(query, 1).is_empty():
			return maxf(0.0, d - SLOT_STEP * 0.5)
		for f: float in [-0.45, 0.0, 0.45]:
			var probe: Vector3 = centre + out * d + along * (length * f)
			var ray := PhysicsRayQueryParameters3D.create(probe + Vector3(0, 0.5, 0), probe - Vector3(0, 0.5, 0), 1)
			ray.exclude = rids
			var hit: Dictionary = space.intersect_ray(ray)
			if hit.is_empty() or absf(float(hit.position.y) - level) > 0.05:
				return d
		d += SLOT_STEP
	return SLOT_MIN


## MC9: every foot hull of a machine leaves 0 or ≥ 1.2 m on each side to a solid or to the floor's edge (the crane's
## column on its plinth has the plinth round it: a step, not a slot).
func _mc_slots() -> void:
	for m: Dictionary in _machines():
		var level: float = m.level
		var slots: int = 0
		for hull: Dictionary in m.hulls:
			var hb: AABB = hull.box
			if hb.position.y > level + MACHINE_FOOT:
				continue
			for out: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
				var free: float = _side_free(hb, out, level, m.rids)
				var ok: bool = free <= SUPPORT_GAP or free >= SLOT_MIN
				if not ok:
					slots += 1
				_check(ok, "MC9 %s/%s side %s leaves a %.2f m slot (0 or ≥ %.1f m)" % [m.id, hull.name, _v(out), free, SLOT_MIN])
				print("CITY_TIDY_INFO MC9 %s/%s side %s free=%s" % [m.id, hull.name, _v(out), ("≥ %.2f" % SLOT_MIN) if free >= SLOT_MIN else "%.2f" % free])
		_check(slots == 0, "MC9 %s leaves no slot a hero wedges in (%d)" % [m.id, slots])


## V-MC (К7): both heroes run at each open side of the winch with W and Space: no vault, never left inside it.
func _machine_runs(hero: String) -> void:
	world.npc_director.process_mode = Node.PROCESS_MODE_DISABLED
	for m: Dictionary in _machines():
		if not (String(m.id) in MACHINE_RUNS) or (m.meshes as Array).is_empty():
			continue
		var foot: Rect2 = m.foot
		var box: AABB = m.box
		var level: float = m.level
		var centre := Vector3(foot.get_center().x, level, foot.get_center().y)
		var runs: int = 0
		for out: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
			world.player.restart_at(CityLayout.spawn_position())
			await _ticks(2)
			var depth: float = absf(out.x) * foot.size.x + absf(out.z) * foot.size.y
			var start: Vector3 = centre + out * (depth * 0.5 + 5.0)
			var clear: bool = true
			var s: float = 0.0
			while s <= 4.3:
				var at: Vector3 = start - out * s
				var hit: Dictionary = _floor_under(at + Vector3(0, 0.5, 0), 1.0)
				clear = clear and not hit.is_empty() and absf(float(hit.position.y) - level) < 0.05 and _capsule_free(Vector3(at.x, float(hit.position.y), at.z))
				s += 0.5
			if not clear:
				continue
			runs += 1
			var result: Dictionary = await _vehicle_run(start, -out, centre, depth)
			var end: Vector3 = result.end
			var inside: bool = absf(end.x - centre.x) < foot.size.x * 0.5 - 0.05 and absf(end.z - centre.z) < foot.size.y * 0.5 - 0.05 and end.y < box.end.y - 0.3
			_check(int(result.vault) == 0, "V-MC %s: no vault over %s from %s (%d vault ticks)" % [hero, m.id, _v(start), result.vault])
			_check(not inside, "V-MC %s is not left inside %s after the run from %s (end %s)" % [hero, m.id, _v(start), _v(end)])
			var under: Dictionary = _floor_under(end + Vector3(0, 0.3, 0), 1.0)
			var stood: String = "nothing" if under.is_empty() else String((under.collider as Node).name)
			print("CITY_TIDY_INFO V-MC %s %s from %s: phases=%s end=%s on=%s" % [hero, m.id, _v(start), ",".join(result.phases), _v(end), stood])
		_check(runs >= 1, "V-MC %s: %s has a free run-up from at least one side (%d)" % [hero, m.id, runs])
	world.npc_director.process_mode = Node.PROCESS_MODE_INHERIT


# --- mutations ---------------------------------------------------------------------------------------------------
## Breaks applied to the live scene, before anything is measured.
func _break_scene() -> void:
	match mutation:
		"step_new", "step_low":
			# V+: a crate nobody listed — 1.0 m, or the band's bottom 0.6 m — on the open street east of the spawn.
			var crate := StaticBody3D.new()
			crate.name = "Crate"   # no skipped prefix: the check must judge it as any prop
			crate.collision_layer = 1 | 8
			crate.collision_mask = 0
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			var height: float = 1.0 if mutation == "step_new" else STEP_HEIGHT.x
			box.size = Vector3(0.8, height, 0.6)
			shape.shape = box
			crate.add_child(shape)
			props_node.add_child(crate)
			crate.global_position = Vector3(3.0, height * 0.5, 13.5)
		"wedge_wall", "wedge_deep":
			# V+ wedge: a wall 2.2 m high — 0.55 m off the street urn (−11.45, 8.25)'s north side (its face z 8.475), or
			# 0.66 m off the tailor's cutting table's free west side (its face x −18.45), just under the capsule's width.
			var wall := StaticBody3D.new()
			wall.name = "NegativeWall"
			wall.collision_layer = 1 | 8
			wall.collision_mask = 0
			var wall_shape := CollisionShape3D.new()
			var wall_box := BoxShape3D.new()
			wall_box.size = Vector3(1.2, 2.2, 0.2) if mutation == "wedge_wall" else Vector3(0.2, 2.2, 1.8)
			wall_shape.shape = wall_box
			wall.add_child(wall_shape)
			props_node.add_child(wall)
			wall.global_position = Vector3(-11.45, 1.1, 8.475 + 0.55 + 0.1) if mutation == "wedge_wall" else Vector3(-18.45 - 0.66 - 0.1, 1.1, 14.95)
		"wedge_round":
			# V+ wedge: the grocer's west display crate keeps its place, depth and top but has a round top (r 0.425): the
			# shop wall, 0.32 m off its flat edge, is now 0.52 m off the rim.
			for c: Dictionary in _step_candidates():
				if c.key == "CityInteriors@(-28.85, 0.80, 12.62)":
					var crate_shape := _top_shape(c.body)
					var round := CylinderShape3D.new()
					round.radius = 0.425
					round.height = (crate_shape.shape as BoxShape3D).size.y
					crate_shape.shape = round
		"wedge_open":
			# V+ wedge: the grocer's side shelf without its collider, so the pinned OPEN at its counter is gone.
			for node: Node in district.get_node("CityInteriors/StockShelf").get_children():
				if node is CollisionShape3D:
					(node as CollisionShape3D).disabled = true
		"step_moved":
			# V+: a listed step moved 0.3 m, so the list names a place where it no longer stands.
			for c: Dictionary in _step_candidates():
				if STEP_PROPS.has(c.key):
					(c.body as Node3D).global_position.x += 0.3
					break
		"pane_strut":
			# D1 returned: anchor 22's strut from 0.75 m under its arm, as before the fix.
			var spec: Dictionary = CityLayout.anchor_supports()[22]
			var mount: Vector3 = spec.mount
			var point: Vector3 = spec.point
			var low: Vector3 = mount + Vector3(0, -0.75, 0)
			var high := Vector3((mount.x + point.x) * 0.5, mount.y - 0.05, (mount.z + point.z) * 0.5)
			var strut: Node3D = district.get_node("AnchorStrut22")
			strut.transform = Transform3D(Basis.looking_at((high - low).normalized(), Vector3.UP), (low + high) * 0.5)
			(strut.get_child(0) as MeshInstance3D).mesh.size = Vector3(0.08, 0.08, low.distance_to(high))
		"float_plate":
			# D5 returned: the archive plate 6 cm off its wall.
			(district.get_node("CityLowerGallery/RoutePlate") as Node3D).position.x -= 0.06
		"solid_planter":
			for node: Node in district.get_node("CityInteriors").find_children("BenchPlanter*", "StaticBody3D", false, false):
				node.free()
				break
		"solid_dressform":
			for node: Node in district.get_node("CityInteriors").find_children("DressForm*", "StaticBody3D", false, false):
				node.free()
		"pump_spout", "pump_lever", "pump_layer":
			# The pump's spout (pipe and mouth) or its lever (bar and handle grip) without a collider, or both on a body
			# on the cover layer only, which the hero's capsule (mask 1) never meets.
			var pump_body: StaticBody3D = district.get_node("WaterPump/PumpBody")
			var names: Array[String] = []
			if mutation != "pump_lever":
				names.append_array(["SpoutPipe", "SpoutMouth"])
			if mutation != "pump_spout":
				names.append_array(["LeverBar", "HandleGrip"])
			var cover := StaticBody3D.new()
			cover.collision_layer = 8
			cover.collision_mask = 0
			if mutation == "pump_layer":
				pump_body.add_child(cover)
			for id: String in names:
				var piece: CollisionShape3D = pump_body.get_node(id)
				if mutation == "pump_layer":
					piece.reparent(cover, false)
				else:
					piece.disabled = true
			if mutation != "pump_layer":
				cover.free()
		"solid_sign":
			var plaque: Node = district.get_node("CityMaintenance/BypassSignPlaque")
			for node: Node in plaque.get_children():
				if node is CollisionShape3D:
					(node as CollisionShape3D).disabled = true
		"service":
			# D17 returned: the atelier's cutting table 0.25 m nearer the counter aisle, as before the fix.
			for node: Node in district.get_node("CityInteriors").find_children("WorkTable*", "StaticBody3D", false, false):
				var table := node as StaticBody3D
				if absf(table.global_position.x - (-17.85)) < 0.05:
					table.global_position.z += 0.25
		"dup_wall":
			var wall: StaticBody3D = district.get_node("CityInteriors").find_children("ShopWall*", "StaticBody3D", false, false)[0]
			var copy: StaticBody3D = wall.duplicate()
			district.get_node("CityInteriors").add_child(copy)
		"anchor":
			# A tar drum under anchor 2's rope.
			var drum: StaticBody3D = props_node.find_children("TarBarrel*", "StaticBody3D", false, false)[0]
			var point: Vector3 = CityLayout.anchor_supports()[2].point
			drum.global_position = Vector3(point.x, 0.45, point.z)
		"vehicle_float":
			(props_node.get_node("Vehicle_steam_truck") as Node3D).position.y += 0.05
		"vehicle_sink":
			(props_node.get_node("Vehicle_steam_car_tarp") as Node3D).position.y -= 0.05
		"vehicle_nocollider":
			props_node.get_node("Vehicle_steam_truck/TruckFront").free()
		"vehicle_shift":
			(props_node.get_node("Vehicle_steam_truck/SteamTruck") as Node3D).position.x += 0.3
		"vehicle_layer":
			for body: Node in props_node.find_children("*", "StaticBody3D", true, false):
				if String(body.get_parent().name).begins_with("Vehicle_"):
					(body as StaticBody3D).collision_layer = 8
		"vehicle_material":
			(props_node.get_node("Vehicle_steam_car_tarp/SteamCarTarp") as MeshInstance3D).set_surface_override_material(3, null)
		"vehicle_anchor":
			# Under anchor 9 (28, 8.6, 10.6): its rope would fall on the cargo.
			(props_node.get_node("Vehicle_steam_truck") as Node3D).position = Vector3(28.0, 0, 9.0)
		"vehicle_lane":
			(props_node.get_node("Vehicle_steam_car_tarp") as Node3D).position = Vector3(25.6, 0, 4.0)
		"vehicle_runup":
			# On crates_east's north run-up (x 30.4, z −5.35…−1.05), clear of the crates themselves.
			(props_node.get_node("Vehicle_steam_truck") as Node3D).position = Vector3(30.6, 0, -5.6)
		"vehicle_gap":
			# The car 1.7 m off the ramp's west side: a strip between them where a hero stands with the ramp at his back.
			(props_node.get_node("Vehicle_steam_car_tarp") as Node3D).position.x -= 1.6
		"vehicle_vault":
			# A vehicle the motor would vault. The shipped one cannot be: its tarp hull's top slopes at the edges (the
			# vault wants a flat top, normal·up ≥ 0.95) and it stands 2.75 m high, 2 m deep. Here the cargo hull is a flat
			# box of the same bounds, the profile allows 3 m high, 2.5 m deep vaults, and the truck stands in the open
			# street (level floor on both long sides), so a run across its width can clear its roof.
			world.player.parkour.profile = (world.player.parkour.profile as Resource).duplicate()
			world.player.parkour.profile.set("vault_max_height", 3.0)
			world.player.parkour.profile.set("vault_max_depth", 2.5)
			var truck: Node3D = props_node.get_node("Vehicle_steam_truck")
			truck.position = Vector3(27.0, 0, 3.0)
			var flat := BoxShape3D.new()
			flat.size = Vector3(2.0, 2.75, 4.07)
			var cargo: CollisionShape3D = truck.get_node("TruckBody").get_child(0)
			cargo.shape = flat
			cargo.position = Vector3(0, 1.375, 0.785)
		"machine_layer":
			for body: Node in props_node.find_children("*", "StaticBody3D", true, false):
				if String(body.get_parent().name).begins_with("Machine_"):
					(body as StaticBody3D).collision_layer = 8
		"machine_material":
			(props_node.get_node("Machine_steam_winch/SteamWinch") as MeshInstance3D).set_surface_override_material(0, null)
		"machine_brass":
			# A crane surface that names brass and shows it: the GLB's own `iron` renamed and painted city brass.
			var crane_mesh: MeshInstance3D = props_node.get_node("Machine_steam_crane/SteamCrane")
			for surface: int in crane_mesh.mesh.get_surface_count():
				var source: Material = crane_mesh.mesh.surface_get_material(surface)
				if source != null and source.resource_name == "iron":
					source.resource_name = "brass"
					crane_mesh.set_surface_override_material(surface, CityMaterials.palette()["brass"])
		"machine_float":
			(props_node.get_node("Machine_steam_winch") as Node3D).position.y += 0.05
		"machine_sink":
			(props_node.get_node("Machine_steam_crane") as Node3D).position.y -= 0.05
		"machine_nocollider":
			props_node.get_node("Machine_steam_winch/WinchBody").free()
		"machine_shift":
			(props_node.get_node("Machine_steam_crane/SteamCrane") as Node3D).position.x += 0.3
		"machine_column":
			# Under anchor 24 (24, 9.3, −24.6): its rope falls on the winch.
			(props_node.get_node("Machine_steam_winch") as Node3D).position = Vector3(24.0, 4.0, -23.6)
		"machine_anchor":
			# Every hull ≥ 1.1 m from anchor 12's vertical (out of its 0.75 m column), but the free swing on anchor 12
			# meets the column and the plinth comes within 2 m of the anchor's mount.
			(props_node.get_node("Machine_steam_crane") as Node3D).position = Vector3(27.0, 4.0, -11.5)
		"machine_pocket":
			(props_node.get_node("Machine_steam_winch") as Node3D).position = Vector3(21.0, 4.0, -19.0)
		"machine_lane":
			(props_node.get_node("Machine_steam_winch") as Node3D).position = Vector3(25.6, 0, 4.0)
		"machine_street_hull":
			# A hull under the boom, 1 m past the terrace's edge: a solid over the street.
			var hull := StaticBody3D.new()
			hull.name = "BoomHull"
			hull.collision_layer = 1 | 8
			hull.collision_mask = 0
			var hull_shape := CollisionShape3D.new()
			var hull_box := BoxShape3D.new()
			hull_box.size = Vector3(0.6, 0.6, 2.0)
			hull_shape.shape = hull_box
			hull.add_child(hull_shape)
			props_node.get_node("Machine_steam_crane").add_child(hull)
			hull.global_position = Vector3(28.0, 11.0, -9.0)
		"machine_cross":
			# On the street between the S3 hero (28, 0, −6) and the lens behind him: its column takes the arm.
			(props_node.get_node("Machine_steam_crane") as Node3D).position = Vector3(28.0, 0.0, -2.5)
		"machine_occlude":
			# Sunk under the street so that its hook block (decor, no hull: the arm never sees it) hangs at (28, 2.2–2.55,
			# −3.0), across the line from the S3 lens to the hero's head.
			(props_node.get_node("Machine_steam_crane") as Node3D).position = Vector3(28.0, -4.9, -9.26)
		"machine_gap":
			# 1.7 m from the house's facade (z −25.78): a station north of the winch has the facade behind the hero.
			(props_node.get_node("Machine_steam_winch") as Node3D).position = Vector3(27.6, 4.0, -22.64)
		"machine_slot":
			# 0.5 m from the terrace's east edge (x 30).
			(props_node.get_node("Machine_steam_winch") as Node3D).position = Vector3(28.67, 4.0, -18.6)
		"machine_budget":
			# Every surface of the winch's mesh twice, each with its own city material: the mesh over its ceiling.
			var winch_mesh: MeshInstance3D = props_node.get_node("Machine_steam_winch/SteamWinch")
			var doubled := ArrayMesh.new()
			var overrides: Array[Material] = []
			for repeat: int in 2:
				for surface: int in winch_mesh.mesh.get_surface_count():
					doubled.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, winch_mesh.mesh.surface_get_arrays(surface))
					doubled.surface_set_material(doubled.get_surface_count() - 1, winch_mesh.mesh.surface_get_material(surface))
					overrides.append(winch_mesh.get_surface_override_material(surface))
			winch_mesh.mesh = doubled
			for surface: int in overrides.size():
				winch_mesh.set_surface_override_material(surface, overrides[surface])
		"machine_step":
			(props_node.get_node("Machine_steam_winch") as Node3D).position.x += 0.3
		"machine_seen_hook":
			# Decor of the crane where it stands: a 0.3 × 0.8 × 0.3 m block (one more surface of its own mesh, its own
			# city material) hangs at (29.3, 2.6–3.4, −8.8), past the terrace's edge (z −10) over the street.
			var hook_mesh: MeshInstance3D = props_node.get_node("Machine_steam_crane/SteamCrane")
			var hung := ArrayMesh.new()
			var keep: Array[Material] = []
			for surface: int in hook_mesh.mesh.get_surface_count():
				hung.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, hook_mesh.mesh.surface_get_arrays(surface))
				hung.surface_set_material(surface, hook_mesh.mesh.surface_get_material(surface))
				keep.append(hook_mesh.get_surface_override_material(surface))
			var block := BoxMesh.new()
			block.size = Vector3(0.3, 0.8, 0.3)
			var arrays: Array = block.get_mesh_arrays()
			var to_local: Transform3D = hook_mesh.global_transform.affine_inverse() * Transform3D(Basis.IDENTITY, Vector3(29.3, 3.0, -8.8))
			var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			for i: int in points.size():
				points[i] = to_local * points[i]
				normals[i] = (to_local.basis * normals[i]).normalized()
			arrays[Mesh.ARRAY_VERTEX] = points
			arrays[Mesh.ARRAY_NORMAL] = normals
			arrays[Mesh.ARRAY_TANGENT] = null
			hung.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			hung.surface_set_material(hung.get_surface_count() - 1, hook_mesh.mesh.surface_get_material(0))
			keep.append(hook_mesh.get_surface_override_material(0))
			hook_mesh.mesh = hung
			for surface: int in keep.size():
				hook_mesh.set_surface_override_material(surface, keep[surface])
		"machine_seen_street":
			# The crane stands on the street at (24.5, 0, −4), north of the S4 hero and west of the S3 line: on a level
			# floor, out of every anchor's column and swing, lane and pocket, its sides and slots free, nothing between a
			# lens and a hero — every other guard holds; only the street lens sees it under the terrace's level.
			(props_node.get_node("Machine_steam_crane") as Node3D).position = Vector3(24.5, 0.0, -4.0)
		"machine_seen_float":
			# The winch hangs in front of the terrace's wall, its bottom 2.2 m over the street, nothing under it.
			(props_node.get_node("Machine_steam_winch") as Node3D).position = Vector3(29.0, 2.2, -9.0)
		"machine_vault":
			# A winch the motor would vault: its body hull a flat box of the same bounds and the profile allowing 1.2 m
			# deep vaults (the shipped one is 1.07 m deep across the rope's side and 1.58 m along its drum).
			world.player.parkour.profile = (world.player.parkour.profile as Resource).duplicate()
			world.player.parkour.profile.set("vault_max_depth", 1.2)
			var winch_body: CollisionShape3D = props_node.get_node("Machine_steam_winch/WinchBody").get_child(0)
			var bounds: AABB = winch_body.shape.get_debug_mesh().get_aabb()
			var flat_body := BoxShape3D.new()
			flat_body.size = bounds.size
			winch_body.shape = flat_body
			winch_body.position += bounds.get_center()
		"vault_high", "vault_deep":
			var body: StaticBody3D = props_node.get_node("VaultObstacle_crates_east")
			var shape := ((body.get_child(0) as CollisionShape3D).shape as BoxShape3D).duplicate() as BoxShape3D
			if mutation == "vault_high":
				shape.size.y = 1.5
				body.position.y = 0.75
			else:
				shape.size.z = 1.2
			(body.get_child(0) as CollisionShape3D).shape = shape


## Breaks applied to the measured parts (the batched builders cannot be edited after the fact).
func _break_parts() -> void:
	match mutation:
		"pane_wire":
			# D4 returned: the south market wire back at z 28, into the arched window of bay z 28.2.
			_move(_select("CityMarket", "wire@-10.00,6.20,27.00", false), Vector3(0, 0, 1.0))
		"float_barrel":
			_move(_select("CityProps", "beer_barrel@"), Vector3(0, 0.03, 0))
		"float_loaf":
			var loaves: Array[Dictionary] = []
			for p: Dictionary in parts:
				if p.module == "CityInteriors" and String(p.ctx).find("shelf@") >= 0 and String(p.ctx).find("loaf@") >= 0:
					if loaves.is_empty() or p.ctx == loaves[0].ctx:
						loaves.append(p)
			_move(loaves, Vector3(0, 0.04, 0))
		"sink_crate":
			_move(_select("CityMarket", "crate@"), Vector3(0, -0.03, 0))
		"zfight_fascia":
			# D12 returned: the fascia 0.30 m high again, its front over the awning's. The tailor's: the grocer's awning is
			# rolled since plan 2026-10-14 step 2 and its valance hangs from the roll, not over an awning front.
			for p: Dictionary in parts:
				if p.module == "CityInteriors" and p.ctx == "shop:tailor" and p.mat == "cloth_cream" and absf(float(p.half.y) - 0.13) < 0.001:
					p.local = AABB(Vector3(-3.25, -0.15, -0.055), Vector3(6.5, 0.3, 0.11))
					var xf: Transform3D = p.xf
					xf.origin.y = 3.65
					p.xf = xf
					_shape(p)
		"zfight_jamb":
			# D11 returned: the grocer's east display wall ends in the jamb's plane again.
			for p: Dictionary in parts:
				if p.module == "CityInteriors" and p.ctx == "shop:grocer" and absf(float(p.half.x) - 1.0) < 0.001 and absf(float(p.half.y) - 0.47) < 0.001 and float(p.center.x) > -26.6:
					p.local = AABB(Vector3(-1.05, -0.47, -0.14), Vector3(2.1, 0.94, 0.28))
					var xf: Transform3D = p.xf
					xf.origin.x -= 0.05
					p.xf = xf
					_shape(p)
		"dup_wall":
			for p: Dictionary in parts:
				if p.module == "CityInteriors" and p.ctx == "shop:tailor" and p.mat == "plaster" and absf(float(p.half.z) - 4.0) < 0.001:
					var copy: Dictionary = p.duplicate(true)
					parts.append(copy)
					break
		"dup_barrel":
			for p: Dictionary in _select("CityProps", "tar_barrel@"):
				parts.append(p.duplicate(true))
		"court":
			var urn: Array[Dictionary] = _select("CityProps", "urn@")
			_move(urn, Vector3(-5.0, 0, 5.0) - Vector3(urn[0].center.x, 0, urn[0].center.z))
		"passage":
			_move(_select("CityProps", "steam_main@", false), Vector3(-0.12, 0, 0))
		"lane":
			var crates: Array[Dictionary] = _select("CityProps", "obstacle@-12.40")
			_move(crates, Vector3(-1.4, 0, 2.2))
		"ink_strip":
			# D15 / Н1 returned: one 62 m ink seam along the street at x 5, as before the fix.
			var seam := {"module": "CityDistrict", "ctx": "StreetSeam5_0/Mesh", "kind": "BoxMesh", "mat": "ink",
				"xf": Transform3D(Basis.IDENTITY, Vector3(5, 0.004, 0)), "local": AABB(Vector3(-0.04, -0.004, -31), Vector3(0.08, 0.008, 62)),
				"visible": true, "live": true}
			_shape(seam)
			parts.append(seam)


func _run() -> void:
	await process_frame
	if mutation != "none" and not (mutation in GEOMETRY_BREAKS or mutation in PLACE_BREAKS or mutation in VAULT_BREAKS or mutation in STEAM_BREAKS or mutation in VEHICLE_BREAKS or mutation in VEHICLE_RUN_BREAKS or mutation in STEP_BREAKS or mutation in MACHINE_BREAKS or mutation in MACHINE_RUN_BREAKS):
		push_error("CITY_TIDY: unknown --break=" + mutation)
		quit(2)
		return
	fighter_script = load("res://scripts/fighter/Fighter.gd")
	var state: Node = root.get_node("GameState")
	state.set_free_move(true)
	root.get_node("InputRouter").apply_profile("solo", false)
	await _open_world("choko")
	_break_scene()
	await _ticks(2)
	if _phase("geometry") or _phase("places"):
		_record_builders()
		_live_parts()
		_break_parts()
		_classify()
		_index_grid()
		print("CITY_TIDY_INFO parts=%d" % parts.size())
	if _phase("geometry"):
		_c1_panes()
		_c2_support()
		_c3_zfight()
		_c4_duplicates()
		_c5_solid()
		_places_of_the_audit()
		_triangles()
	if _phase("places"):
		await _k_places()
		_m_vehicles()
		await _m_camera()
		_mc_machines()
		await _mc_camera()
		await _mc_street_camera()
		_mc_slots()
		_v_steps()
		_v_wedges()
	if _phase("steam"):
		await _steam()
	if _phase("vault"):
		await _vaults("choko")
		await _vehicle_runs("choko")
		await _machine_runs("choko")
		await _close_world()
		await _open_world("skea")
		_break_scene()
		await _ticks(2)
		await _vaults("skea")
		await _vehicle_runs("skea")
		await _machine_runs("skea")
	await _close_world()
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		if root.has_node(singleton):
			root.get_node(singleton).queue_free()
	var deadline: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < deadline:
		await process_frame
		OS.delay_msec(1)
	print("CITY_TIDY_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
	quit(1 if failures else 0)
