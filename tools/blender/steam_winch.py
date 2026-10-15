# SPDX-License-Identifier: GPL-3.0-or-later
"""Catalogue No. 11 «Парова лебідка» — a standing direct-drive steam winch by the crane on the NE terrace (ADR-027).

Canon of form: docs/Art/2026-10-14-Steam-Crane-Winch-Form.md (T6, § Лебідка № 11) after the L1·2 cell text: a
horizontal drum with thick rope, a single steam cylinder with a piston rod, a big spoked flywheel, a heavy iron bed,
a steam pipe coming in; chest-high. Functional, no ornament, no gears (direct drive, П2, П5): steam from under the
terrace (a flange in the floor) -> stop valve (the one brass part: a hand wheel you may touch, П6) -> valve chest ->
cylinder -> piston rod, crosshead, connecting rod -> crank -> shaft with the flywheel and the drum -> rope; the hook on
the rope's end is «parked» on a lug of the bed; exhaust steam goes back into the floor; a brake band holds the drum.
No letters, no `ink`. Sizes follow the T6 table (its PLACEHOLDERs stay PLACEHOLDER); the cylinder gets a saddle down to
the bed (T6 left it floating 0.49 m over the bed), see docs/Fix/2026-10-14-Steam-Crane-Winch-Fix.md.

Blender axes: X the drum's axis, +Y the side the rope leaves, +Z up; origin on the floor under the footprint centre.
In the game the node stands at (27.6, 4.0, -18.6) with yaw = pi: the rope faces south, the flywheel (local +X) west.

Colliders (T6 § Колізії): WinchBody (everything but the flywheel; the top of the drum's flanges at 1.12 m is its flat
top — T6 accepts it as a step, V+) and WinchFlywheel (rim and hub, Ø 1.20 × 0.08).

    bpyvenv/bin/python tools/blender/steam_winch.py [--out PATH.glb] [--preview DIR]
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import prop_kit as kit  # noqa: E402
from mathutils import Vector  # noqa: E402

NAME = "SteamWinch"
DEFAULT_OUT = kit.REPO / "game" / "assets" / "props" / "city" / "prop_steam_winch_v1.glb"

# ── T6 dimensions, metres (docs/Art/2026-10-14-Steam-Crane-Winch-Form.md § Лебідка № 11) ───────────────────────
BED_Z0, BED_Z1 = 0.08, 0.18
AXIS_Y, AXIS_Z = 0.10, 0.78               # drum and shaft
FLANGE_X, FLANGE_R = 0.47, 0.35           # the flanges' flat top edge: 0.78 + 0.35 cos(pi/16) = 1.12 m
CYL_X, CYL_Y = -0.70, -0.38               # the steam cylinder, its axis along Y
FLYWHEEL_X, FLYWHEEL_R = 0.80, 0.60       # its top: 0.78 + 0.60 = 1.38 m (1.4 [К])
INLET = Vector((-0.38, -0.38, 0.04))      # the steam pipe out of the floor through the bed (its 0.04 m end overshoot
EXHAUST = Vector((-0.55, -0.45, 0.04))    # reaches the floor, not under it)


def member(b: kit.Builder, start, end, size: float, key: str) -> None:
    """A square-section straight member (a box) between two centre points, its width axis kept close to X."""
    a, c = Vector(start), Vector(end)
    w = (c - a).normalized()
    ex = (kit.X - w * kit.X.dot(w)).normalized()
    ey = w.cross(ex).normalized()
    b.box((a + c) * 0.5, (size, size, (c - a).length), key, axes=(ex, ey, w))


def body(b: kit.Builder) -> None:
    """Everything but the shaft and the flywheel."""
    for x in (-0.60, 0.60):
        b.box((x, 0, 0.04), (0.15, 1.00, 0.08), "wood")                                   # sleepers
    b.box((0, 0, (BED_Z0 + BED_Z1) * 0.5), (1.50, 0.95, BED_Z1 - BED_Z0), "iron_paint")   # heavy iron bed
    for x in (-0.55, 0.55):
        b.box((x, 0.05, (BED_Z1 + AXIS_Z) * 0.5), (0.10, 0.80, AXIS_Z - BED_Z1), "iron_paint")   # side stands
        b.box((x, AXIS_Y, AXIS_Z), (0.14, 0.18, 0.12), "iron")                                     # bearings
    b.cylinder((0, AXIS_Y, AXIS_Z), "X", 0.25, 0.90, 16, "iron_paint")                    # drum
    # Flanges turned pi/16, so each has a flat top edge, not a top vertex: the body hull's top is then a level strip
    # between them (four corners within 1 cm), which T6 accepts as a step (V+). With a vertex up the hull keeps only the
    # two outer top points (the inner ones are collinear with them) and its top is a ridge.
    for x in (-FLANGE_X, FLANGE_X):
        b.cylinder((x, AXIS_Y, AXIS_Z), "X", FLANGE_R, 0.04, 16, "iron_paint", phase=math.pi / 16)
    b.cylinder((0, AXIS_Y, AXIS_Z), "X", 0.29, 0.82, 16, "wood")                          # wound rope

    # The single steam cylinder on its saddle, two covers, the valve chest on top.
    b.box((CYL_X, CYL_Y, (BED_Z1 + 0.70) * 0.5), (0.10, 0.22, 0.70 - BED_Z1), "iron_paint")
    b.cylinder((CYL_X, CYL_Y, AXIS_Z), "Y", 0.11, 0.30, 12, "iron_paint")
    for y in (CYL_Y - 0.165, CYL_Y + 0.165):
        b.cylinder((CYL_X, y, AXIS_Z), "Y", 0.13, 0.03, 12, "iron_paint")
    b.box((CYL_X, CYL_Y, 0.95), (0.12, 0.26, 0.12), "iron_paint")
    # Piston rod with the crosshead, the connecting rod to the crank pin (30° over the shaft), the crank disc.
    b.box((CYL_X, -0.14, AXIS_Z), (0.08, 0.18, 0.08), "iron")
    pin = Vector((CYL_X, AXIS_Y + 0.10 * math.cos(math.radians(30)), AXIS_Z + 0.10 * math.sin(math.radians(30))))
    member(b, (CYL_X, -0.07, AXIS_Z), pin, 0.08, "iron")
    b.cylinder((-0.64, AXIS_Y, AXIS_Z), "X", 0.15, 0.06, 12, "iron_paint")

    # Steam in: from the floor through the bed, a stop valve with a brass hand wheel facing -Y, over to the chest.
    b.pipe([INLET, (INLET.x, INLET.y, 1.06), (CYL_X, INLET.y, 1.06), (CYL_X, INLET.y, 1.00)], 0.04, 8, "copper")
    for at in (INLET, EXHAUST):
        b.cylinder((at.x, at.y, BED_Z1 + 0.02), "Z", 0.10, 0.04, 12, "copper")             # flanges where they pass the bed
    b.cylinder((INLET.x, -0.40, 0.55), "Y", 0.06, 0.18, 10, "copper")                     # valve body
    b.ring((INLET.x, -0.50, 0.55), "Y", 0.10, 0.12, 0.02, 12, "brass")                    # hand wheel
    # Exhaust steam back into the floor.
    b.pipe([(-0.62, EXHAUST.y, 0.76), (EXHAUST.x, EXHAUST.y, 0.60), EXHAUST], 0.04, 8, "copper")

    # Brake band round the left flange's lower half and its lever (no brass: the grip is thinner than 0.1 m, П4).
    b.ring((-FLANGE_X, AXIS_Y, AXIS_Z), "X", FLANGE_R + 0.005, FLANGE_R + 0.025, 0.05, 12, "iron",
           a0=math.pi, a1=kit.TAU)
    b.cylinder((-0.40, 0.45, (BED_Z1 + 1.05) * 0.5), "Z", 0.03, 1.05 - BED_Z1, 6, "iron_paint")
    b.cylinder((-0.40, 0.45, 1.05), "X", 0.04, 0.14, 8, "iron_paint")

    # Parked: the rope's tail runs off the drum to a lug on the bed, its hook over the lug.
    b.box((0, 0.44, BED_Z1 + 0.04), (0.08, 0.06, 0.08), "iron")
    b.ring((0, 0.44, BED_Z1 + 0.08), "X", 0.04, 0.07, 0.05, 10, "iron", a0=-math.pi / 2, a1=math.pi)
    b.rod((0, 0.32, 0.62), (0, 0.44, BED_Z1 + 0.15), 0.03, 6, "wood")


def flywheel(b: kit.Builder) -> None:
    """The shaft through both bearings and the big spoked flywheel on its +X end (direct drive)."""
    # The shaft ends flush with the crank disc (-0.67) and the flywheel's hub (+0.86): the T6 габарит X −0.81…+0.84,
    # not its 1.75 m length, which would stick out of both.
    shaft0, shaft1 = -0.67, FLYWHEEL_X + 0.06
    b.cylinder(((shaft0 + shaft1) * 0.5, AXIS_Y, AXIS_Z), "X", 0.04, shaft1 - shaft0, 8, "iron")
    c = Vector((FLYWHEEL_X, AXIS_Y, AXIS_Z))
    rim_in = FLYWHEEL_R - 0.08
    b.ring(c, "X", rim_in, FLYWHEEL_R, 0.08, 24, "iron_paint")
    b.cylinder(c, "X", 0.09, 0.12, 12, "iron_paint")
    inner, outer = 0.08, rim_in + 0.01
    for i in range(6):
        a = kit.TAU * i / 6 + math.pi / 6
        radial = kit.Y * math.cos(a) + kit.Z * math.sin(a)
        tangent = kit.Y * -math.sin(a) + kit.Z * math.cos(a)
        b.box(c + radial * ((inner + outer) * 0.5), (outer - inner, 0.10, 0.06), "iron_paint",
              axes=(radial, tangent, kit.X))


def build(palette):
    materials = kit.make_materials(palette)
    b = kit.Builder(palette)
    body(b)
    body_points = [v.co.copy() for v in b.bm.verts]
    start = len(b.bm.verts)
    flywheel(b)
    b.bm.verts.ensure_lookup_table()
    shaft_verts = 2 * 8   # the shaft is the first cylinder of flywheel(): two loops of 8
    wheel_points = [b.bm.verts[i].co.copy() for i in range(start + shaft_verts, len(b.bm.verts))]
    visual = b.to_object(NAME, materials)
    colliders = [kit.convex_collider("WinchBody", body_points), kit.convex_collider("WinchFlywheel", wheel_points)]
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
        kit.render_previews(visual, args.preview, "steam_winch", 4.2)


if __name__ == "__main__":
    main()
