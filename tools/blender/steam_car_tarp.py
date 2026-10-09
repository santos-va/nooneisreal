"""Catalogue No. 29 «Легковик-паровик під брезентом» — a steam passenger car under a canvas cover, standing prop.

Canon of form: the left-hand vehicle of game/assets/sprites/sprite_steamcars_v1.png (registry `sprite-steamcars-v1`):
a dark-green cab car with a hood in front and a vertical boiler with a tall chimney behind the cab. Here it stands
covered (T7 brief O9: parked for a long time, the yard keeper sweeps its leaves): one canvas drapes the hood, the cab
and the boiler hump, ropes hold it; the tall chimney pokes through a tied collar, the wheels, running boards and the
green lower body show under the hem. No ornament (P2, P5), no brass on show (nothing here is to be touched, P6), no
letters or numbers. The cover is city `cloth_teal`, the car's own green is ADR-027 painted iron `iron_paint`.

Sizes are PLACEHOLDER real-world metres (T6 catalogue about 3.5 x 1.7 x 2.6).

    bpyvenv/bin/python tools/blender/steam_car_tarp.py [--out PATH.glb] [--preview DIR]
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import prop_kit as kit  # noqa: E402
from mathutils import Vector  # noqa: E402

NAME = "SteamCarTarp"
DEFAULT_OUT = kit.REPO / "game" / "assets" / "props" / "city" / "prop_steam_car_tarp_v1.glb"

# ── PLACEHOLDER dimensions, metres ───────────────────────────────────────────────────────────────
WHEEL_R = 0.43
WHEEL_X = 0.70
FRONT_AXLE_Y, REAR_AXLE_Y = 1.10, -1.05
CHIMNEY = (-0.36, -1.45)   # behind the cab on the left, as on the sprite
CHIMNEY_R, CHIMNEY_TOP = 0.10, 2.60

# Cover stations front to back: (y, roof top z, roof half width, hem half width, hem z, roof rounding radius).
# Hood -> windscreen -> cab roof (sagging between the frame bows) -> boiler hump; the hem alternates up/down by 3 cm
# so the canvas falls in folds.
STATIONS = [
    (1.78, 0.98, 0.40, 0.74, 0.76, 0.18),
    (1.72, 1.16, 0.50, 0.82, 0.71, 0.22),
    (1.55, 1.24, 0.55, 0.84, 0.68, 0.24),
    (1.25, 1.27, 0.56, 0.85, 0.71, 0.24),
    (0.95, 1.29, 0.57, 0.84, 0.68, 0.24),
    (0.72, 1.40, 0.60, 0.85, 0.71, 0.25),
    (0.55, 1.78, 0.64, 0.84, 0.68, 0.27),
    (0.40, 2.08, 0.67, 0.85, 0.71, 0.28),
    (0.18, 2.16, 0.68, 0.84, 0.68, 0.28),
    (-0.15, 2.11, 0.67, 0.85, 0.71, 0.28),
    (-0.50, 2.17, 0.68, 0.84, 0.68, 0.28),
    (-0.85, 2.12, 0.67, 0.85, 0.71, 0.28),
    (-1.08, 2.15, 0.66, 0.84, 0.68, 0.28),
    (-1.24, 2.00, 0.60, 0.84, 0.71, 0.30),
    (-1.45, 1.94, 0.55, 0.82, 0.68, 0.32),
    (-1.64, 1.86, 0.50, 0.80, 0.71, 0.30),
    (-1.76, 1.50, 0.42, 0.74, 0.76, 0.24),
]
ROPES = (0.18, -0.85)  # straps over the cab, at those stations


def cover_section(station, arc_points: int = 9, grow: float = 0.0, fold: float = 0.0, y_shift: float = 0.0):
    """Closed loop: hem, side drape (flares out over the fenders), rounded roof, other side, flat bottom (hidden)."""
    y, top, roof_half, hem_half, hem, rnd = station
    y += y_shift
    if top - rnd - hem < 0.6:
        # Low hood and tucked ends: the canvas rides over the fenders, so the drape keeps out past the wheel tops.
        side_x = hem_half - 0.03 + fold
        side_z = hem + (top - rnd - hem) * 0.6
    else:
        side_x = roof_half + (hem_half - roof_half) * 0.45 + fold
        side_z = hem + (top - rnd - hem) * 0.5
    pts = [Vector((-hem_half - grow, y, hem - grow)), Vector((-side_x - grow, y, side_z))]
    cz = top - rnd
    for i in range(arc_points):
        a = math.pi - math.pi * i / (arc_points - 1)
        pts.append(Vector(((roof_half + grow) * math.cos(a), y, cz + (rnd + grow) * math.sin(a))))
    pts += [Vector((side_x + grow, y, side_z)), Vector((hem_half + grow, y, hem - grow))]
    return pts


def build(palette):
    materials = kit.make_materials(palette)
    b = kit.Builder(palette)

    # Wheels, axles, springs, the green lower body and running boards that show under the hem.
    for x in (-WHEEL_X, WHEEL_X):
        for y in (FRONT_AXLE_Y, REAR_AXLE_Y):
            b.spoked_wheel((x, y, WHEEL_R), WHEEL_R, 0.12, 10, 24, "iron_paint", "wood", "iron")
            b.box((x * 0.74, y, 0.62), (0.08, 0.80, 0.08), "iron_paint")             # leaf spring
        b.box((x * 1.14, -0.0, 0.40), (0.20, 1.20, 0.04), "iron_paint")              # running board
        for y in (-0.45, 0.45):
            b.box((x * 1.03, y, 0.46), (0.12, 0.05, 0.12), "iron_paint")              # board bracket
    for y in (FRONT_AXLE_Y, REAR_AXLE_Y):
        b.cylinder((0, y, WHEEL_R), "X", 0.04, 2 * WHEEL_X, 10, "iron_paint")
    b.box((0, 0.0, 0.62), (1.40, 3.10, 0.24), "iron_paint")                          # lower body under the cover
    for x in (-0.45, 0.45):
        b.box((x, 0.0, 0.50), (0.08, 3.30, 0.12), "iron_paint")                      # frame rails

    # Canvas cover with side folds, two rope straps.
    sections = []
    for index, station in enumerate(STATIONS):
        fold = 0.025 * math.sin(index * 2.1)
        sections.append(cover_section(station, fold=fold))
    b.loft(sections, "cloth_teal")
    by_y = {s[0]: s for s in STATIONS}
    for y in ROPES:
        station = by_y[y]
        b.loft([cover_section(station, grow=0.018, y_shift=-0.04), cover_section(station, grow=0.018, y_shift=0.04)],
               "wood")

    # The tall chimney of the vertical boiler, out through a tied collar in the cover.
    cx, cy = CHIMNEY
    b.cylinder((cx, cy, (1.55 + CHIMNEY_TOP - 0.14) * 0.5), "Z", CHIMNEY_R, CHIMNEY_TOP - 0.14 - 1.55, 16,
               "iron_paint")
    b.cylinder((cx, cy, CHIMNEY_TOP - 0.07), "Z", CHIMNEY_R + 0.01, 0.14, 16, "copper", radius_end=CHIMNEY_R + 0.05)
    b.ring((cx, cy, 1.93), "Z", CHIMNEY_R - 0.005, CHIMNEY_R + 0.05, 0.07, 16, "wood")       # rope collar
    b.ring((cx, cy, 2.20), "Z", CHIMNEY_R - 0.005, CHIMNEY_R + 0.025, 0.05, 16, "iron")       # chimney band

    visual = b.to_object(NAME, materials)

    def hull_points(stations):
        points = []
        for station in stations:
            for p in cover_section(station, arc_points=7):
                points += [p, Vector((p.x, p.y, 0.0))]
        return points
    hood = [s for s in STATIONS if s[0] >= 0.72]
    screen = [s for s in STATIONS if 0.40 <= s[0] <= 0.72]
    cab = [s for s in STATIONS if s[0] <= 0.40]
    chimney_pts = kit.box_points((cx, cy, (1.80 + CHIMNEY_TOP) * 0.5), (0.30, 0.30, CHIMNEY_TOP - 1.80))
    boards = kit.box_points((0, 0, 0.21), (2 * WHEEL_X * 1.14 + 0.20, 1.20, 0.42))  # running boards, to the ground
    colliders = [kit.convex_collider("CarHood", hull_points(hood)), kit.convex_collider("CarScreen", hull_points(screen)),
                 kit.convex_collider("CarCab", hull_points(cab) + boards),
                 kit.convex_collider("CarChimney", chimney_pts)]
    return visual, colliders, b.keys


def main() -> None:
    args = kit.parse_args(DEFAULT_OUT)
    kit.reset_scene()
    palette = kit.city_palette()
    visual, colliders, keys = build(palette)
    digest = kit.export_glb(args.out)
    kit.summary(NAME, visual, colliders, args.out, digest, palette, keys)
    if args.preview is not None:
        for obj in colliders:
            obj.hide_render = True
        kit.render_previews(visual, args.preview, "steam_car_tarp", 8.5)


if __name__ == "__main__":
    main()
