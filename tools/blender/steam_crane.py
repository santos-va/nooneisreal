# SPDX-License-Identifier: GPL-3.0-or-later
"""Catalogue No. 10 «Паровий поворотний кран» — a standing steam slewing crane on the NE terrace (ADR-027 п. 4).

Canon of form: docs/Art/2026-10-14-Steam-Crane-Winch-Form.md (T6, step 3 of plan 2026-10-14-T6-Acceptance-Crane-
Albedo-AB): a round painted cast-iron column Ø 0.8 m, its fixed part 4.0 m high [К]; a slewing platform with a short
boxy cab, a counterweight water tank at its back and a portal for the ties; a straight lattice boom 7.0 m [К] at 40°
[V2] with few diagonals; a hook block on a short chain under the boom head. Functional, no ornament, no visible gears
(П2, П5): firebox (warm slit) -> vertical boiler (gauge on the cab wall, safety valve and chimney through the roof);
counterweight tank -> feed pipe -> boiler; boiler -> steam pipe -> two engine cylinders -> covered gear -> drum ->
chain over the head sheave -> hook block. No brass anywhere (П6: brass means «you may grab this»; the crane is no rope
anchor), no `ink`, no letters. Sizes follow the T6 tables (their PLACEHOLDERs stay PLACEHOLDER).

Blender axes (prop_kit.py): +X right, +Y the boom's direction, +Z up; origin on the terrace floor on the column axis.
In the game the node stands at (28.0, 4.0, -14.0) with yaw = pi: Blender (X, Y, Z) -> world (28.0 - X, 4.0 + Z, -14.0 + Y).

Colliders (T6 § Колізії): CranePlinth (plinth + flange), CraneColumn (the column alone, so no invisible skirt round it
at head height), CraneCab (slewing ring, cab and counterweight). The boom, ties, chain, hook, chimney, valve, gauge and
the platform's front have none: nothing solid stands over the street.

    bpyvenv/bin/python tools/blender/steam_crane.py [--out PATH.glb] [--preview DIR]
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import prop_kit as kit  # noqa: E402
from mathutils import Vector  # noqa: E402

NAME = "SteamCrane"
DEFAULT_OUT = kit.REPO / "game" / "assets" / "props" / "city" / "prop_steam_crane_v1.glb"

# ── T6 dimensions, metres (docs/Art/2026-10-14-Steam-Crane-Winch-Form.md § Частини й розміри) ───────────────────
COLUMN_Z0, COLUMN_Z1 = 0.45, 3.80
COLUMN_R0, COLUMN_R1 = 0.40, 0.33          # [К] Ø 0.8; the taper is a T6 PLACEHOLDER (cast iron)
PLATFORM_Z0, PLATFORM_Z1 = 4.00, 4.15      # top of the fixed part = 4.0 [К]
CAB_X = 0.90
CAB_Y0, CAB_Y1 = -1.45, 0.25
CAB_Z0, CAB_Z1 = PLATFORM_Z1, 6.15
WALL = 0.08
BOILER_Y, BOILER_R = -1.00, 0.35
DRUM_Y, DRUM_Z = -0.05, 4.60
HEEL = Vector((0.0, 0.90, 4.50))           # boom heel pin
HEAD = Vector((0.0, 6.26, 9.00))           # boom head sheave axle: 7.0 m [К] at 40° [V2] from the heel
BOOM_WIDTH = (0.90, 0.36)                  # truss centre to truss centre, heel -> head
BOOM_DEPTH = (0.50, 0.22)                  # chord centre to chord centre within a truss, heel -> head
CHORD, LACING = 0.14, 0.10
SHEAVE_R = 0.25
PORTAL_X, PORTAL_Y, PORTAL_TOP = 0.97, -0.60, 7.20
HOOK_BLOCK_Z0 = 7.09


def boom_frame():
    """Unit vectors of the boom: d along it (heel -> head), n across it in the YZ plane, pointing up."""
    d = (HEAD - HEEL).normalized()
    n = Vector((0.0, -d.z, d.y))
    return d, n


def chord_point(u: float, side: float, level: float) -> Vector:
    """Centre line of a chord at fraction u of the boom (0 heel, 1 head); side ±1 in X, level ±1 (lower/upper)."""
    d, n = boom_frame()
    width = BOOM_WIDTH[0] + (BOOM_WIDTH[1] - BOOM_WIDTH[0]) * u
    depth = BOOM_DEPTH[0] + (BOOM_DEPTH[1] - BOOM_DEPTH[0]) * u
    return HEEL + (HEAD - HEEL) * u + kit.X * (side * width * 0.5) + n * (level * depth * 0.5)


def member(b: kit.Builder, start: Vector, end: Vector, size: float, key: str) -> None:
    """A square-section straight member (a box) between two centre points; its width axis kept close to X."""
    w = (end - start).normalized()
    ex = (kit.X - w * kit.X.dot(w))
    if ex.length < 1e-6:
        ex = kit.Y - w * kit.Y.dot(w)
    ex.normalize()
    ey = w.cross(ex).normalized()
    b.box((start + end) * 0.5, (size, size, (end - start).length), key, axes=(ex, ey, w))


def column_radius(z: float) -> float:
    return COLUMN_R0 + (COLUMN_R1 - COLUMN_R0) * (z - COLUMN_Z0) / (COLUMN_Z1 - COLUMN_Z0)


def roof_section(y: float):
    """Closed loop in the XZ plane at `y`: flat underside on the walls (no gable gap), a 0.15 m rise, 0.06 m eaves."""
    pts = [Vector((1.00, y, CAB_Z1))]
    for i in range(12):
        x = 1.00 - 2.00 * i / 11
        pts.append(Vector((x, y, CAB_Z1 + 0.06 + 0.15 * (1.0 - x * x))))
    pts.append(Vector((-1.00, y, CAB_Z1)))
    return pts


def build(palette):
    materials = kit.make_materials(palette)
    b = kit.Builder(palette)

    # Fixed part: stone plinth, flange, tapered column with two iron belts, slewing ring (top of the fixed part 4.0).
    b.box((0, 0, 0.15), (1.60, 1.60, 0.30), "stone")
    b.cylinder((0, 0, 0.375), "Z", 0.65, 0.15, 24, "iron_paint")
    b.cylinder((0, 0, (COLUMN_Z0 + COLUMN_Z1) * 0.5), "Z", COLUMN_R0, COLUMN_Z1 - COLUMN_Z0, 20, "iron_paint",
               radius_end=COLUMN_R1)
    for z in (1.30, 2.90):
        b.cylinder((0, 0, z), "Z", column_radius(z) + 0.03, 0.08, 20, "iron")
    b.cylinder((0, 0, 3.90), "Z", 0.70, 0.20, 24, "iron_paint")

    # Slewing platform and the cab: back and side walls, two front posts, a lintel; the front stays open.
    b.box((0, -0.475, (PLATFORM_Z0 + PLATFORM_Z1) * 0.5), (1.90, 3.15, PLATFORM_Z1 - PLATFORM_Z0), "iron_paint")
    cab_h = CAB_Z1 - CAB_Z0
    cab_zc = (CAB_Z0 + CAB_Z1) * 0.5
    b.box((0, CAB_Y0 + WALL * 0.5, cab_zc), (2 * CAB_X, WALL, cab_h), "iron_paint")
    side_len = CAB_Y1 - (CAB_Y0 + WALL)
    for s in (-1.0, 1.0):
        b.box((s * (CAB_X - WALL * 0.5), CAB_Y0 + WALL + side_len * 0.5, cab_zc), (WALL, side_len, cab_h), "iron_paint")
        b.box((s * (CAB_X - 0.075), CAB_Y1 - WALL * 0.5, cab_zc), (0.15, WALL, cab_h), "iron_paint")   # front post
        b.box((s * (CAB_X + 0.005), -0.195, 5.40), (0.02, 0.55, 0.60), "glass")                         # side window
    b.box((0, CAB_Y1 - WALL * 0.5, CAB_Z1 - 0.15), (1.50, WALL, 0.30), "iron_paint")                   # lintel
    b.loft([roof_section(CAB_Y0 - 0.10), roof_section(CAB_Y1 + 0.10)], "copper")                       # copper roof

    # Vertical boiler with the firebox door (warm slit) on its +Y face, toward the open front. The door stands 0.95 m
    # over the platform, not at T6's z ≈ 4.5: there the drum (top 4.90) hides it from the front (A11 wants the slit in
    # the frame); waist height is where a fireman feeds a vertical boiler anyway.
    face = BOILER_R * math.cos(math.pi / 16)            # a 16-gon with this phase has a flat face on +Y
    b.cylinder((0, BOILER_Y, 4.95), "Z", BOILER_R, 1.60, 16, "iron_paint", phase=math.pi / 16)
    door_y = BOILER_Y + face + 0.015
    b.box((0, door_y, 5.10), (0.30, 0.06, 0.26), "iron_paint")
    b.box((0, door_y + 0.035, 5.05), (0.24, 0.02, 0.035), "warm_window")
    # Chimney through the roof: an iron collar on the roof, a copper flare on top.
    roof_top = CAB_Z1 + 0.21
    b.cylinder((0, BOILER_Y, (5.75 + 7.30) * 0.5), "Z", 0.12, 7.30 - 5.75, 12, "iron_paint")
    b.cylinder((0, BOILER_Y, roof_top), "Z", 0.18, 0.12, 12, "iron_paint")
    b.cylinder((0, BOILER_Y, 7.375), "Z", 0.12, 0.15, 12, "copper", radius_end=0.18)
    # Safety valve on the roof over the boiler, near the chimney.
    b.cylinder((0, -0.72, roof_top + 0.095), "Z", 0.05, 0.25, 10, "copper")
    b.cylinder((0, -0.72, roof_top + 0.245), "Z", 0.075, 0.05, 10, "copper")
    # Pressure gauge on the right wall outside: copper body, a plain glass face (no rim of brass, no marks).
    b.cylinder((CAB_X + 0.03, -1.05, 5.40), "X", 0.10, 0.06, 16, "copper")
    b.cylinder((CAB_X + 0.07, -1.05, 5.40), "X", 0.08, 0.02, 16, "glass")

    # Winding drum with flanges and the wound chain, its support on the right, the gear cover on the left down to the
    # platform (no visible gears), two vertical engine cylinders on the right end.
    b.cylinder((0, DRUM_Y, DRUM_Z), "X", 0.225, 0.90, 16, "iron_paint")
    for s in (-1.0, 1.0):
        b.cylinder((s * 0.47, DRUM_Y, DRUM_Z), "X", 0.30, 0.04, 16, "iron_paint")
    b.cylinder((0, DRUM_Y, DRUM_Z), "X", 0.26, 0.80, 16, "iron")
    b.box((-0.565, DRUM_Y, (CAB_Z0 + DRUM_Z + 0.30) * 0.5), (0.15, 0.60, DRUM_Z + 0.30 - CAB_Z0), "iron_paint")
    b.box((0.53, DRUM_Y, (CAB_Z0 + DRUM_Z + 0.08) * 0.5), (0.04, 0.30, DRUM_Z + 0.08 - CAB_Z0), "iron_paint")
    for y in (-0.06, 0.16):
        b.cylinder((0.66, y, (CAB_Z0 + DRUM_Z) * 0.5), "Z", 0.09, DRUM_Z - CAB_Z0, 12, "iron_paint")
    # Steam pipe boiler -> engine; control lever at the left front post (iron: no brass, П6).
    b.pipe([(0.25, -0.85, 4.75), (0.66, -0.85, 4.75), (0.66, -0.06, 4.75), (0.66, -0.06, DRUM_Z - 0.02)], 0.035, 8,
           "copper")
    b.cylinder((-0.68, 0.12, CAB_Z0 + 0.50), "Z", 0.03, 1.00, 6, "iron")
    b.cylinder((-0.68, 0.12, CAB_Z0 + 1.00), "X", 0.035, 0.14, 8, "iron")

    # Counterweight: a water tank with ballast at the back, two iron straps; feed pipe from the tank to the boiler.
    b.box((0, -1.725, 4.70), (1.80, 0.55, 1.10), "iron_paint")
    for x in (-0.50, 0.50):
        b.box((x, -1.725, 4.70), (0.06, 0.57, 1.12), "iron")
    b.pipe([(0.40, -1.72, 5.20), (0.40, -1.72, 5.45), (0.40, -1.10, 5.45), (0.22, -1.10, 5.45)], 0.03, 8, "copper")

    # Portal for the ties: two posts from the platform's side and a beam.
    for s in (-1.0, 1.0):
        b.box((s * PORTAL_X, PORTAL_Y, (PLATFORM_Z0 + PORTAL_TOP) * 0.5), (0.14, 0.14, PORTAL_TOP - PLATFORM_Z0),
              "iron_paint")
    b.box((0, PORTAL_Y, PORTAL_TOP - 0.07), (2 * PORTAL_X + 0.14, 0.14, 0.14), "iron_paint")

    # Boom heel: two lugs on the platform and the pin.
    for s in (-1.0, 1.0):
        b.box((s * 0.45, HEEL.y, PLATFORM_Z1 + 0.20), (0.12, 0.30, 0.40), "iron_paint")
    b.cylinder(HEEL, "X", 0.05, 1.02, 10, "iron_paint")

    # Lattice boom: 4 chords, 5 diagonals per side truss (panels 1.4 m along the boom), 3 + 3 ties between the trusses.
    for side in (-1.0, 1.0):
        for level in (-1.0, 1.0):
            member(b, chord_point(0.0, side, level), chord_point(1.0, side, level), CHORD, "iron_paint")
        for k in range(5):
            level = -1.0 if k % 2 == 0 else 1.0
            member(b, chord_point(k / 5, side, level), chord_point((k + 1) / 5, side, -level), LACING, "iron_paint")
    for u in (0.06, 0.40, 0.80):
        member(b, chord_point(u, -1.0, -1.0), chord_point(u, 1.0, -1.0), LACING, "iron_paint")
    for u in (0.20, 0.55, 0.88):
        member(b, chord_point(u, -1.0, 1.0), chord_point(u, 1.0, 1.0), LACING, "iron_paint")

    # Boom head: two cheek plates along the boom (set back 0.08 m, so their corners stay inside the sheave's envelope:
    # the head's top 9.25 and front 6.51 of the T6 габарит), the sheave and its axle.
    d, n = boom_frame()
    for s in (-1.0, 1.0):
        b.box(HEAD - d * 0.08 + kit.X * (s * 0.16), (0.04, 0.44, 0.36), "iron_paint", axes=(kit.X, d, n))
    b.ring(HEAD, "X", SHEAVE_R - 0.08, SHEAVE_R, 0.08, 16, "iron")
    b.cylinder(HEAD, "X", 0.04, 0.40, 8, "iron")

    # Ties from the portal beam to the head (dark iron lines hold the side triangle on any background).
    for s in (-1.0, 1.0):
        b.rod((s * 0.90, PORTAL_Y, PORTAL_TOP), (s * 0.18, HEAD.y, HEAD.z + 0.05), 0.05, 8, "iron")

    # Hoist chain: from the drum's top through the open front, over the boom to the sheave's back-top tangent.
    drum_top = Vector((0.0, DRUM_Y, DRUM_Z + 0.26))
    to_head = Vector((0.0, HEAD.y - drum_top.y, HEAD.z - drum_top.z))
    dist = to_head.length
    angle = math.atan2(to_head.z, to_head.y) + math.asin(SHEAVE_R / dist)
    tangent = HEAD + Vector((0.0, -math.sin(angle), math.cos(angle))) * SHEAVE_R
    b.rod(drum_top, tangent, 0.025, 6, "iron")
    # Two falls under the sheave (0.16 m apart, the group 0.21 m), the hook block, the shank and an open J hook.
    sheave_under = HEAD.z - math.sqrt(SHEAVE_R ** 2 - 0.08 ** 2)
    block_top = HOOK_BLOCK_Z0 + 0.36
    for dy in (-0.08, 0.08):
        b.rod((0.0, HEAD.y + dy, block_top), (0.0, HEAD.y + dy, sheave_under), 0.025, 6, "iron")
    b.box((0.0, HEAD.y, HOOK_BLOCK_Z0 + 0.18), (0.26, 0.18, 0.36), "iron")
    hook_c = Vector((0.0, HEAD.y + 0.10, HOOK_BLOCK_Z0 - 0.21))
    b.cylinder((0.0, HEAD.y, (HOOK_BLOCK_Z0 + hook_c.z) * 0.5), "Z", 0.04, HOOK_BLOCK_Z0 - hook_c.z, 8, "iron")
    b.ring(hook_c, "X", 0.07, 0.13, 0.08, 10, "iron", a0=math.pi, a1=math.radians(390))

    visual = b.to_object(NAME, materials)

    # Colliders (T6 § Колізії): plinth + flange; the column alone; slewing ring + cab + counterweight.
    plinth = kit.box_points((0, 0, 0.225), (1.60, 1.60, 0.45))
    column = []
    for z, r in ((COLUMN_Z0, COLUMN_R0), (COLUMN_Z1, COLUMN_R1)):
        for i in range(20):
            a = kit.TAU * i / 20
            column.append(Vector((r * math.cos(a), r * math.sin(a), z)))
    # The slewing ring under the platform joins the cab's hull only up to the cab's open front (Y 0.25): the hull of
    # the whole ring (to Y 0.70) would put an invisible wedge in front of the opening.
    ring = [Vector((0.70 * math.cos(kit.TAU * i / 24), 0.70 * math.sin(kit.TAU * i / 24), 3.80)) for i in range(24)]
    edge = math.sqrt(0.70 ** 2 - CAB_Y1 ** 2)
    cab = [p for p in ring if p.y <= CAB_Y1] + [Vector((-edge, CAB_Y1, 3.80)), Vector((edge, CAB_Y1, 3.80))]
    cab += kit.box_points((0, (-2.05 + CAB_Y1) * 0.5, (PLATFORM_Z0 + 6.35) * 0.5), (1.90, CAB_Y1 + 2.05, 6.35 - PLATFORM_Z0))
    colliders = [kit.convex_collider("CranePlinth", plinth), kit.convex_collider("CraneColumn", column),
                 kit.convex_collider("CraneCab", cab)]
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
        kit.render_previews(visual, args.preview, "steam_crane", 25.0, silhouettes=("34", "side"))


if __name__ == "__main__":
    main()
