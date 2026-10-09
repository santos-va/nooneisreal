"""Catalogue No. 9 «Паромобіль-вантажівка» — steam cargo truck, a standing city prop (ADR-027).

Canon of form: the right-hand vehicle of game/assets/sprites/sprite_steamcars_v1.png (registry `sprite-steamcars-v1`)
and the V1 card text in docs/Art/Prompts/City-Props-Prompts.md: round riveted boiler at the front with a short chimney
and two round lamps, a small open driver's seat with a plain steering wheel, a long wooden bed with plank sides under a
tied canvas tarpaulin, four spoked wooden wheels with iron tyres, the front pair smaller. Functional, no ornament (P2,
P5): water tank -> feed pipe -> boiler (firebox door, pressure gauge, safety valve) -> steam pipe -> engine -> chain
case -> rear axle; smoke leaves by the chimney. The red body of the sprite is not carried over (T6 bans: dE76 15.9 from
#711126): bed sides and mudguards are city `slate`. Brass only on the steering wheel rim (P6). No letters or numbers.

Sizes are PLACEHOLDER real-world metres (T6 catalogue 5.0 x 2.0 x 2.8; T1 brief 5-6 x 2 x 2.6-3, wheel ~1 m).

    bpyvenv/bin/python tools/blender/steam_truck.py [--out PATH.glb] [--preview DIR]
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import prop_kit as kit  # noqa: E402
from mathutils import Vector  # noqa: E402

NAME = "SteamTruck"
DEFAULT_OUT = kit.REPO / "game" / "assets" / "props" / "city" / "prop_steam_truck_v1.glb"

# ── PLACEHOLDER dimensions, metres ───────────────────────────────────────────────────────────────
REAR_WHEEL_R = 0.50   # diameter 1.0 m
FRONT_WHEEL_R = 0.45  # the front pair is smaller (V1 card)
WHEEL_X = 0.82        # wheel centre plane; tyre outer face at 0.82 + 0.08
REAR_AXLE_Y = -1.55
FRONT_AXLE_Y = 1.85
BED_Y0, BED_Y1 = -2.78, 0.36   # cargo bed from the tailboard to the front board
BED_HALF = 0.98
DECK_Z0, DECK_Z1 = 1.04, 1.14
SIDE_TOP = 1.70
TARP_HEM, TARP_TOP, TARP_HALF, TARP_ROUND = 1.60, 2.75, 1.00, 0.36
CAB_Y1 = 1.40                  # boiler backhead
CANOPY_Y1 = 1.25
BOILER_R, BOILER_Y0, BOILER_Y1, BOILER_Z = 0.52, 1.40, 2.75, 1.28
CHIMNEY_Y = 2.45


def tarp_section(y: float, top: float, half: float, hem: float, rnd: float, arc_points: int = 9, grow: float = 0.0,
                 hem_half: float | None = None):
    """Closed loop in the XZ plane at `y`: hem, side, rounded roof, other side, flat bottom (hidden in the bed).
    `half` is the roof's half width; the hem keeps `hem_half` (default `half`) so a sagging roof never bares the
    plank sides under it."""
    hem_x = (half if hem_half is None else hem_half) + grow
    pts = [Vector((-hem_x, y, hem - grow))]
    cz = top - rnd
    for i in range(arc_points):
        a = math.pi - math.pi * i / (arc_points - 1)
        pts.append(Vector(((half + grow) * math.cos(a), y, cz + (rnd + grow) * math.sin(a))))
    pts.append(Vector((hem_x, y, hem - grow)))
    return pts


def tarp_stations():
    """Stations along the bed; the cloth sags 5 cm between the three ropes and tucks in at both ends."""
    ropes = (-2.35, -1.25, -0.15)
    spans = [(BED_Y0 - 0.04, -0.07), (BED_Y0, -0.02), (-2.60, -0.02), (ropes[0], 0.0), (-2.05, -0.035),
             (-1.80, -0.05), (-1.52, -0.035), (ropes[1], 0.0), (-0.95, -0.035), (-0.70, -0.05), (-0.42, -0.035),
             (ropes[2], 0.0), (0.12, -0.02), (BED_Y1 - 0.02, -0.02), (BED_Y1 + 0.02, -0.07)]
    return ropes, spans


def build(palette):
    materials = kit.make_materials(palette)
    b = kit.Builder(palette)

    # Wheels, axles, springs.
    for x in (-WHEEL_X, WHEEL_X):
        b.spoked_wheel((x, REAR_AXLE_Y, REAR_WHEEL_R), REAR_WHEEL_R, 0.16, 10, 24, "iron_paint", "wood", "iron")
        b.spoked_wheel((x, FRONT_AXLE_Y, FRONT_WHEEL_R), FRONT_WHEEL_R, 0.15, 10, 24, "iron_paint", "wood", "iron")
        b.box((x * 0.62, REAR_AXLE_Y, 0.76), (0.09, 0.95, 0.10), "iron_paint")   # leaf spring under the frame
        b.box((x * 0.62, FRONT_AXLE_Y, 0.70), (0.09, 0.80, 0.10), "iron_paint")
    b.cylinder((0, REAR_AXLE_Y, REAR_WHEEL_R), "X", 0.05, 2 * WHEEL_X, 10, "iron_paint")
    b.cylinder((0, FRONT_AXLE_Y, FRONT_WHEEL_R), "X", 0.045, 2 * WHEEL_X, 10, "iron_paint")
    for x in (-0.62, 0.62):  # spring hangers from axle to frame
        b.box((x, REAR_AXLE_Y, 0.66), (0.07, 0.10, 0.30), "iron_paint")
        b.box((x, FRONT_AXLE_Y, 0.60), (0.07, 0.10, 0.34), "iron_paint")

    # Chassis frame: two rails and cross members.
    for x in (-0.55, 0.55):
        b.box((x, -0.10, 0.95), (0.10, 5.30, 0.18), "iron_paint")
    for y in (-2.70, -0.60, 0.40, 2.62):
        b.box((0, y, 0.95), (1.20, 0.10, 0.14), "iron_paint")

    # Cargo bed: wooden deck, slate plank sides, painted iron stakes, a hoop rail under the tarp hem.
    bed_len = BED_Y1 - BED_Y0
    bed_mid = (BED_Y0 + BED_Y1) * 0.5
    b.box((0, bed_mid, (DECK_Z0 + DECK_Z1) * 0.5), (2 * BED_HALF, bed_len, DECK_Z1 - DECK_Z0), "wood")
    side_h = SIDE_TOP - DECK_Z1
    for x in (-BED_HALF + 0.03, BED_HALF - 0.03):
        b.box((x, bed_mid, DECK_Z1 + side_h * 0.5), (0.06, bed_len, side_h), "slate")
    for y in (BED_Y0 + 0.03, BED_Y1 - 0.03):
        b.box((0, y, DECK_Z1 + side_h * 0.5), (2 * BED_HALF, 0.06, side_h), "slate")
    for y in (-2.62, -1.80, -0.98, -0.16):  # stakes stop under the tarp hem
        for x in (-BED_HALF - 0.005, BED_HALF + 0.005):
            b.box((x, y, (DECK_Z0 - 0.04 + TARP_HEM) * 0.5), (0.03, 0.09, TARP_HEM - DECK_Z0 + 0.04), "iron_paint")

    # Tarpaulin: lofted canvas with sag between ropes; three rope straps over it.
    ropes, spans = tarp_stations()
    sections = []
    for y, sag in spans:
        tuck = min(0.0, sag + 0.035) * 0.6  # extra pull-in only at the tucked ends
        sections.append(tarp_section(y, TARP_TOP + sag, TARP_HALF + sag * 0.4 + tuck, TARP_HEM, TARP_ROUND,
                                     hem_half=TARP_HALF + (tuck * 0.5 if tuck < 0 else 0.0)))
    b.loft(sections, "cloth_cream")
    for y in ropes:
        strap = [tarp_section(y - 0.045, TARP_TOP, TARP_HALF, TARP_HEM, TARP_ROUND, grow=0.018),
                 tarp_section(y + 0.045, TARP_TOP, TARP_HALF, TARP_HEM, TARP_ROUND, grow=0.018)]
        b.loft(strap, "wood")

    # Canopy over the open driver's seat: the same canvas roof, a 4 cm sheet, on two painted iron posts.
    def canopy_loop(y: float, drop: float):
        outer = tarp_section(y, TARP_TOP - drop, TARP_HALF - 0.01, TARP_TOP - TARP_ROUND - 0.10, TARP_ROUND)[1:-1]
        inner = tarp_section(y, TARP_TOP - drop - 0.04, TARP_HALF - 0.05, TARP_TOP - TARP_ROUND - 0.10,
                             TARP_ROUND - 0.04)[1:-1]
        return outer + list(reversed(inner))
    b.loft([canopy_loop(BED_Y1, 0.02), canopy_loop(0.80, 0.06), canopy_loop(CANOPY_Y1, 0.03)], "cloth_cream")
    for x in (-0.93, 0.93):
        b.box((x, CANOPY_Y1 - 0.03, (DECK_Z0 + 2.40) * 0.5), (0.06, 0.06, 2.40 - DECK_Z0), "iron_paint")

    # Driver's place: floor, coal box under the seat, seat, low side panels, step, steering column and wheel.
    b.box((0, (BED_Y1 + CAB_Y1) * 0.5, 0.98), (1.80, CAB_Y1 - BED_Y1, 0.08), "wood")
    b.box((0, 0.58, 1.18), (1.50, 0.40, 0.36), "slate")
    b.box((0, 0.60, 1.42), (1.56, 0.46, 0.10), "wood")
    for x in (-0.94, 0.94):
        b.box((x, 0.62, 1.20), (0.05, 0.52, 0.40), "slate")
        b.box((x * 1.0, 1.02, 0.56), (0.16, 0.38, 0.04), "iron_paint")        # step plate
        b.box((x * 0.97, 1.02, 0.76), (0.04, 0.05, 0.40), "iron_paint")       # step bracket
    column_base = Vector((-0.30, 1.22, 1.02))
    column_top = Vector((-0.30, 0.98, 1.78))
    b.rod(column_base, column_top, 0.03, 8, "iron_paint")
    axis = (column_top - column_base).normalized()
    u = axis.cross(kit.X).normalized()
    v = axis.cross(u).normalized()
    wheel_c = column_top + axis * 0.02
    b.ring_uvw(wheel_c, u, v, axis, 0.17, 0.21, 0.036, 20, "brass")                    # plain rim, brass (V1, P6)
    b.rod(wheel_c - u * 0.18, wheel_c + u * 0.18, 0.015, 6, "iron_paint")    # two plain spokes

    # Boiler: painted iron drum with three bolted iron bands, smokebox door, dome, safety valve, chimney.
    boiler_len = BOILER_Y1 - BOILER_Y0
    boiler_c = Vector((0, (BOILER_Y0 + BOILER_Y1) * 0.5, BOILER_Z))
    b.cylinder(boiler_c, "Y", BOILER_R, boiler_len, 24, "iron_paint")
    for y in (BOILER_Y0 + 0.14, boiler_c.y, BOILER_Y1 - 0.14):
        b.ring((0, y, BOILER_Z), "Y", BOILER_R - 0.01, BOILER_R + 0.025, 0.07, 24, "iron")
    b.cylinder((0, BOILER_Y1 + 0.03, BOILER_Z), "Y", 0.43, 0.06, 24, "iron_paint")      # smokebox door
    for z in (BOILER_Z - 0.22, BOILER_Z + 0.22):
        b.box((0.06, BOILER_Y1 + 0.07, z), (0.62, 0.03, 0.06), "iron")                # door straps
    b.cylinder((0, BOILER_Y1 + 0.09, BOILER_Z), "Y", 0.05, 0.08, 10, "iron_paint")      # door handle
    b.cylinder((0, 1.85, BOILER_Z + BOILER_R + 0.06), "Z", 0.16, 0.20, 16, "copper")     # steam dome
    b.cylinder((0, 1.85, BOILER_Z + BOILER_R + 0.20), "Z", 0.16, 0.08, 16, "copper", radius_end=0.09)
    b.cylinder((0, 1.60, BOILER_Z + BOILER_R + 0.10), "Z", 0.05, 0.24, 10, "copper")     # safety valve
    b.cylinder((0, 1.60, BOILER_Z + BOILER_R + 0.24), "Z", 0.075, 0.05, 10, "copper")
    chimney_base = BOILER_Z + BOILER_R - 0.06
    b.cylinder((0, CHIMNEY_Y, chimney_base + 0.08), "Z", 0.23, 0.16, 16, "iron_paint")    # saddle flange
    b.cylinder((0, CHIMNEY_Y, (chimney_base + 2.70) * 0.5), "Z", 0.15, 2.70 - chimney_base, 16, "iron_paint")
    b.cylinder((0, CHIMNEY_Y, 2.77), "Z", 0.16, 0.14, 16, "copper", radius_end=0.22)       # flared cap

    # Backhead (driver side): firebox door with a warm slit, pressure gauge with a plain glass face.
    b.box((-0.08, BOILER_Y0 - 0.02, 1.08), (0.36, 0.04, 0.28), "iron_paint")
    b.box((-0.08, BOILER_Y0 - 0.045, 1.02), (0.24, 0.02, 0.035), "warm_window")
    b.box((-0.08, BOILER_Y0 - 0.05, 1.16), (0.10, 0.03, 0.03), "iron")                  # door latch
    b.cylinder((0.26, BOILER_Y0 - 0.03, 1.56), "Y", 0.10, 0.06, 16, "copper")
    b.cylinder((0.26, BOILER_Y0 - 0.065, 1.56), "Y", 0.08, 0.02, 16, "glass")

    # Lamps on a front crossbar.
    b.box((0, 2.66, 0.98), (1.66, 0.08, 0.08), "iron_paint")
    for x in (-0.74, 0.74):
        b.box((x, 2.66, 1.08), (0.06, 0.06, 0.14), "iron_paint")
        b.cylinder((x, 2.74, 1.25), "Y", 0.13, 0.20, 16, "iron_paint")
        b.cylinder((x, 2.85, 1.25), "Y", 0.105, 0.03, 16, "warm_window")

    # Front mudguards over the smaller wheels (slate), on stays to the frame.
    for x in (-WHEEL_X, WHEEL_X):
        b.ring((x, FRONT_AXLE_Y, FRONT_WHEEL_R), "X", FRONT_WHEEL_R + 0.07, FRONT_WHEEL_R + 0.10, 0.22, 12, "slate",
               a0=math.radians(10), a1=math.radians(175))
        b.box((x * 0.82, FRONT_AXLE_Y - 0.25, 0.98), (0.30, 0.05, 0.05), "iron_paint")

    # Working steam: tank -> feed pipe -> boiler; dome -> steam pipe -> engine -> chain case -> rear axle.
    b.cylinder((0, -0.75, 0.56), "X", 0.27, 1.10, 16, "iron_paint")                      # feed-water tank
    for x in (-0.55, 0.55):
        b.box((x, -0.75, 0.80), (0.06, 0.12, 0.20), "iron_paint")                        # tank straps to frame
    b.pipe([(-0.25, -0.50, 0.56), (-0.25, 1.62, 0.56), (-0.25, 1.62, BOILER_Z - BOILER_R + 0.04)], 0.035, 8, "copper")
    b.box((0.12, 0.05, 0.64), (0.62, 0.78, 0.38), "iron_paint")                          # engine block
    b.cylinder((0.12, 0.05, 0.88), "Y", 0.10, 0.70, 12, "iron_paint")                    # cylinder barrel
    b.pipe([(0.10, 1.85, BOILER_Z + BOILER_R + 0.12), (0.66, 1.85, BOILER_Z + BOILER_R + 0.12),
            (0.66, 1.85, 0.66), (0.66, 0.30, 0.66), (0.43, 0.30, 0.66)], 0.04, 8, "copper")
    b.box((0.47, (REAR_AXLE_Y + 0.05) * 0.5, 0.55), (0.08, abs(REAR_AXLE_Y - 0.05) + 0.20, 0.22), "iron_paint")

    visual = b.to_object(NAME, materials)

    # Colliders: the canvas body (bed + canopy) to the ground, the boiler front with the small wheels, the chimney.
    body_pts = []
    for y in (BED_Y0 - 0.04, CANOPY_Y1):
        for p in tarp_section(y, TARP_TOP, TARP_HALF, TARP_HEM, TARP_ROUND, arc_points=7):
            body_pts.append(p)
            body_pts.append(Vector((p.x, p.y, 0.0)))
    front_pts = []
    for y in (CANOPY_Y1, 2.90):
        for i in range(12):
            a = kit.TAU * i / 12
            front_pts.append(Vector((BOILER_R * math.cos(a), y, BOILER_Z + BOILER_R * math.sin(a))))
        for x in (-0.92, 0.92):
            front_pts += [Vector((x, y, 0.0)), Vector((x, y, FRONT_WHEEL_R * 2 + 0.06))]
    chimney_pts = kit.box_points((0, CHIMNEY_Y, (chimney_base + 2.84) * 0.5), (0.44, 0.44, 2.84 - chimney_base))
    colliders = [kit.convex_collider("TruckBody", body_pts), kit.convex_collider("TruckFront", front_pts),
                 kit.convex_collider("TruckChimney", chimney_pts)]
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
        kit.render_previews(visual, args.preview, "steam_truck", 11.0)


if __name__ == "__main__":
    main()
