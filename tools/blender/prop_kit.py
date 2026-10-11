# SPDX-License-Identifier: GPL-3.0-or-later
"""Shared helpers for Cronshift city props built with Blender as a Python module (bpy 5.2.2 LTS).

Deterministic by construction: no random numbers, no time, no dependence on the user's Blender preferences
(the scene starts from factory settings). Geometry is written with bmesh in explicit world coordinates.

Conventions (see tools/blender/README.md):
- Blender axes: +X right, +Y forward (the prop's front), +Z up; origin on the ground under the footprint centre.
  The glTF exporter turns +Y forward into Godot -Z (Node3D forward), +Z up into Godot +Y.
- Metres, real scale. Every transform is applied before export (no object scale: Jolt warns on scaled bodies).
- Materials are named after the keys of game/scripts/world/CityMaterials.gd and carry the same hex, so the game can
  swap each surface for the city shader by name. `iron_paint` (#577368, ADR-027's painted cast iron) is a key of
  CityMaterials.gd since 2026-10-09; EXTRA_KEYS stays empty unless a prop needs a colour before the game has it.
- Collision: separate objects named `<Name>-convcolonly`. Godot 4.7's scene importer turns each into a StaticBody3D
  with one ConvexPolygonShape3D and drops the visible mesh (editor/import/3d/resource_importer_scene.cpp,
  `_teststr(name, "convcolonly")`).
"""
from __future__ import annotations

import argparse
import hashlib
import math
import re
import sys
from pathlib import Path

import bpy  # first: the bpy module puts bmesh and mathutils on the path
import bmesh
from mathutils import Vector

REPO = Path(__file__).resolve().parents[2]
CITY_MATERIALS = REPO / "game" / "scripts" / "world" / "CityMaterials.gd"
# Keys a prop may use before CityMaterials.gd has them (the file's value wins). Empty: `iron_paint` is in the file.
EXTRA_KEYS: dict[str, str] = {}
AUTO_SMOOTH_DEG = 40.0  # faces meeting at less than this share normals: 10+ sided cylinders and cloth read smooth
TAU = math.tau
X = Vector((1.0, 0.0, 0.0))
Y = Vector((0.0, 1.0, 0.0))
Z = Vector((0.0, 0.0, 1.0))
AXES = {"X": (Y, Z, X), "Y": (X, Z, Y), "Z": (X, Y, Z)}  # axis -> (u, v, w): circle in u/v, length along w


def city_palette() -> dict[str, str]:
    """Material key -> 6-digit hex, read from CityMaterials.gd (single source of truth) plus EXTRA_KEYS."""
    text = CITY_MATERIALS.read_text(encoding="utf-8")
    found = dict(re.findall(r'result\["([a-z_]+)"\]\s*=\s*_material\("([0-9a-fA-F]{6})"', text))
    if not found:
        raise SystemExit(f"no palette keys parsed from {CITY_MATERIALS}")
    for key, value in EXTRA_KEYS.items():
        found.setdefault(key, value)
    return {key: value.lower() for key, value in found.items()}


def srgb_to_linear(channel: float) -> float:
    return channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4


def hex_to_linear(hex_value: str) -> tuple[float, float, float, float]:
    rgb = [int(hex_value[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    return (srgb_to_linear(rgb[0]), srgb_to_linear(rgb[1]), srgb_to_linear(rgb[2]), 1.0)


def reset_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


class Builder:
    """Accumulates closed parts into one bmesh; each face carries the index of its palette key."""

    def __init__(self, palette: dict[str, str]):
        self.bm = bmesh.new()
        self.palette = palette
        self.keys: list[str] = []

    # ── materials ──────────────────────────────────────────────────────────────────────────────────
    def _index(self, key: str) -> int:
        if key not in self.palette:
            raise KeyError(f"material key '{key}' is not in the city palette: {sorted(self.palette)}")
        if key not in self.keys:
            self.keys.append(key)
        return self.keys.index(key)

    def _face(self, verts, key: str):
        face = self.bm.faces.new(verts)
        face.material_index = self._index(key)
        return face

    def _vert(self, point: Vector):
        return self.bm.verts.new(point)

    # ── loops ──────────────────────────────────────────────────────────────────────────────────────
    def _loop(self, centre: Vector, u: Vector, v: Vector, radius: float, segments: int,
              a0: float = 0.0, a1: float = TAU, closed: bool = True) -> list:
        count = segments if closed else segments + 1
        return [self._vert(centre + u * (radius * math.cos(a0 + (a1 - a0) * i / segments))
                           + v * (radius * math.sin(a0 + (a1 - a0) * i / segments))) for i in range(count)]

    def _bridge(self, loop_a: list, loop_b: list, key: str, closed: bool = True) -> None:
        count = len(loop_a)
        for i in range(count if closed else count - 1):
            j = (i + 1) % count
            self._face((loop_a[i], loop_a[j], loop_b[j], loop_b[i]), key)

    # ── primitives ─────────────────────────────────────────────────────────────────────────────────
    def box(self, centre, size, key: str, axes=(X, Y, Z)) -> None:
        """Box with half extents size/2 along the (unit) axes ex, ey, ez."""
        c = Vector(centre)
        ex, ey, ez = (Vector(a).normalized() for a in axes)
        hx, hy, hz = (s * 0.5 for s in size)
        corner = {}
        for sx in (-1, 1):
            for sy in (-1, 1):
                for sz in (-1, 1):
                    corner[(sx, sy, sz)] = self._vert(c + ex * (sx * hx) + ey * (sy * hy) + ez * (sz * hz))
        quads = [((-1, -1, -1), (-1, 1, -1), (1, 1, -1), (1, -1, -1)), ((-1, -1, 1), (1, -1, 1), (1, 1, 1), (-1, 1, 1)),
                 ((-1, -1, -1), (1, -1, -1), (1, -1, 1), (-1, -1, 1)), ((-1, 1, -1), (-1, 1, 1), (1, 1, 1), (1, 1, -1)),
                 ((-1, -1, -1), (-1, -1, 1), (-1, 1, 1), (-1, 1, -1)), ((1, -1, -1), (1, 1, -1), (1, 1, 1), (1, -1, 1))]
        for quad in quads:
            self._face([corner[k] for k in quad], key)

    def cylinder(self, centre, axis: str, radius: float, length: float, segments: int, key: str,
                 radius_end: float | None = None, phase: float = 0.0) -> None:
        """Capped (frustum) cylinder centred on `centre`, length along `axis`; radius_end at the +axis end."""
        u, v, w = AXES[axis]
        self.tube(Vector(centre), u, v, w, radius, radius if radius_end is None else radius_end, length, segments, key,
                  phase)

    def tube(self, centre: Vector, u: Vector, v: Vector, w: Vector, r0: float, r1: float, length: float,
             segments: int, key: str, phase: float = 0.0) -> None:
        half = w * (length * 0.5)
        a = self._loop(centre - half, u, v, r0, segments, phase, phase + TAU)
        b = self._loop(centre + half, u, v, r1, segments, phase, phase + TAU)
        self._bridge(a, b, key)
        self._face(list(reversed(a)), key)
        self._face(b, key)

    def rod(self, start, end, radius: float, segments: int, key: str, overshoot: float = 0.0) -> None:
        """Cylinder between two points; `overshoot` extends both ends to close elbows of a pipe run."""
        a, b = Vector(start), Vector(end)
        w = (b - a).normalized()
        helper = Z if abs(w.dot(Z)) < 0.9 else X
        u = w.cross(helper).normalized()
        v = w.cross(u).normalized()
        self.tube((a + b) * 0.5, u, v, w, radius, radius, (b - a).length + 2.0 * overshoot, segments, key)

    def pipe(self, points, radius: float, segments: int, key: str) -> None:
        for start, end in zip(points[:-1], points[1:]):
            self.rod(start, end, radius, segments, key, overshoot=radius)

    def ring(self, centre, axis: str, r_in: float, r_out: float, width: float, segments: int, key: str,
             a0: float = 0.0, a1: float = TAU) -> None:
        """Annulus of radial thickness r_out - r_in and `width` along the axis; a partial arc gets end caps.
        Angles are measured in the (u, v) plane of AXES[axis] (axis X: from +Y toward +Z)."""
        u, v, w = AXES[axis]
        self.ring_uvw(Vector(centre), u, v, w, r_in, r_out, width, segments, key, a0, a1)

    def ring_uvw(self, c: Vector, u: Vector, v: Vector, w: Vector, r_in: float, r_out: float, width: float,
                 segments: int, key: str, a0: float = 0.0, a1: float = TAU) -> None:
        closed = abs((a1 - a0) - TAU) < 1e-9
        half = w * (width * 0.5)
        loops = [self._loop(c - half, u, v, r_out, segments, a0, a1, closed),
                 self._loop(c + half, u, v, r_out, segments, a0, a1, closed),
                 self._loop(c + half, u, v, r_in, segments, a0, a1, closed),
                 self._loop(c - half, u, v, r_in, segments, a0, a1, closed)]
        for k in range(4):
            self._bridge(loops[k], loops[(k + 1) % 4], key, closed)
        if not closed:
            self._face([loop[0] for loop in loops], key)
            self._face([loop[-1] for loop in reversed(loops)], key)

    def loft(self, sections, key: str, cap_start: bool = True, cap_end: bool = True) -> None:
        """Closed cross-section loops (equal point counts) bridged in order; n-gon caps at both ends."""
        loops = [[self._vert(Vector(p)) for p in section] for section in sections]
        for loop_a, loop_b in zip(loops[:-1], loops[1:]):
            self._bridge(loop_a, loop_b, key)
        if cap_start:
            self._face(list(reversed(loops[0])), key)
        if cap_end:
            self._face(loops[-1], key)

    def spoked_wheel(self, centre, radius: float, tyre_width: float, spokes: int, segments: int,
                     hub_key: str, wood_key: str, tyre_key: str) -> None:
        """Artillery wheel on an X axle: iron tyre, wooden felloe, `spokes` wooden spokes, painted iron hub."""
        c = Vector(centre)
        tyre = 0.06
        felloe = 0.07
        self.ring(c, "X", radius - tyre, radius, tyre_width, segments, tyre_key)
        self.ring(c, "X", radius - tyre - felloe, radius - tyre + 0.005, tyre_width * 0.8, segments, wood_key)
        hub_r = 0.11 * radius / 0.5
        self.cylinder(c, "X", hub_r, tyre_width * 1.6, 12, hub_key, phase=math.pi / 12)
        inner = hub_r * 0.8
        outer = radius - tyre - felloe + 0.01
        for i in range(spokes):
            a = TAU * i / spokes + math.pi / spokes
            radial = Y * math.cos(a) + Z * math.sin(a)
            tangent = Y * -math.sin(a) + Z * math.cos(a)
            mid = (inner + outer) * 0.5
            self.box(c + radial * mid, (outer - inner, 0.085, 0.06), wood_key, axes=(radial, tangent, X))

    # ── output ─────────────────────────────────────────────────────────────────────────────────────
    def to_object(self, name: str, materials: dict[str, bpy.types.Material]):
        bmesh.ops.recalc_face_normals(self.bm, faces=list(self.bm.faces))
        mesh = bpy.data.meshes.new(name)
        self.bm.to_mesh(mesh)
        self.bm.free()
        for key in self.keys:
            mesh.materials.append(materials[key])
        mesh.shade_smooth()
        mesh.set_sharp_from_angle(angle=math.radians(AUTO_SMOOTH_DEG))
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        return obj


def make_materials(palette: dict[str, str]) -> dict[str, bpy.types.Material]:
    result = {}
    for key, hex_value in palette.items():
        material = bpy.data.materials.new(key)
        colour = hex_to_linear(hex_value)
        material.diffuse_color = colour
        bsdf = material.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = colour
        bsdf.inputs["Roughness"].default_value = 1.0
        bsdf.inputs["Metallic"].default_value = 0.0
        if key == "warm_window":  # the city shader gives warm glass a small glow (CityMaterials.gd)
            bsdf.inputs["Emission Color"].default_value = colour
            bsdf.inputs["Emission Strength"].default_value = 0.6
        result[key] = material
    return result


def convex_collider(name: str, points) -> bpy.types.Object:
    """`<name>-convcolonly` object: the convex hull of `points` (Godot builds one ConvexPolygonShape3D from it)."""
    bm = bmesh.new()
    verts = [bm.verts.new(Vector(p)) for p in points]
    hull = bmesh.ops.convex_hull(bm, input=verts, use_existing_faces=False)
    loose = [v for v in bm.verts if not v.link_faces]
    if loose:
        bmesh.ops.delete(bm, geom=loose, context="VERTS")
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    mesh = bpy.data.meshes.new(name + "-convcolonly")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name + "-convcolonly", mesh)
    bpy.context.scene.collection.objects.link(obj)
    del hull
    return obj


def box_points(centre, size):
    c = Vector(centre)
    h = Vector(size) * 0.5
    return [c + Vector((sx * h.x, sy * h.y, sz * h.z)) for sx in (-1, 1) for sy in (-1, 1) for sz in (-1, 1)]


def triangles(obj) -> int:
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def bounds(obj) -> tuple[Vector, Vector]:
    xs = [v.co for v in obj.data.vertices]
    lo = Vector((min(p.x for p in xs), min(p.y for p in xs), min(p.z for p in xs)))
    hi = Vector((max(p.x for p in xs), max(p.y for p in xs), max(p.z for p in xs)))
    return lo, hi


def export_glb(path: Path) -> str:
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(path), export_format="GLB", use_selection=False, export_apply=True, export_yup=True,
        export_normals=True, export_texcoords=False, export_tangents=False, export_materials="EXPORT",
        export_vertex_color="NONE", export_attributes=False, export_cameras=False, export_lights=False,
        export_extras=False, export_animations=False, export_skins=False, export_morph=False)
    return hashlib.sha256(path.read_bytes()).hexdigest()


def summary(name: str, visual, colliders, path: Path, digest: str, palette: dict[str, str], keys: list[str]) -> None:
    lo, hi = bounds(visual)
    size = hi - lo
    print(f"PROP_OK name={name} file={path} sha256={digest}")
    print(f"PROP_SIZE width_x={size.x:.3f} length_y={size.y:.3f} height_z={size.z:.3f} "
          f"min=({lo.x:.3f},{lo.y:.3f},{lo.z:.3f}) max=({hi.x:.3f},{hi.y:.3f},{hi.z:.3f})")
    print(f"PROP_MESH tris={triangles(visual)} verts={len(visual.data.vertices)} surfaces={len(keys)}")
    for index, key in enumerate(keys):
        tris = sum(len(p.vertices) - 2 for p in visual.data.polygons if p.material_index == index)
        print(f"PROP_MATERIAL {key} #{palette[key]} tris={tris}")
    for obj in colliders:
        clo, chi = bounds(obj)
        print(f"PROP_COLLIDER {obj.name} verts={len(obj.data.vertices)} tris={triangles(obj)} "
              f"min=({clo.x:.3f},{clo.y:.3f},{clo.z:.3f}) max=({chi.x:.3f},{chi.y:.3f},{chi.z:.3f})")


def render_previews(visual, out_dir: Path, stem: str, distance: float) -> None:
    """Cycles CPU (Workbench/Eevee need libEGL): 3/4, side, front and a black-on-white silhouette (K1)."""
    out_dir.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 24
    scene.cycles.use_denoising = False
    scene.render.resolution_x = 1280
    scene.render.resolution_y = 720
    scene.render.film_transparent = False
    scene.view_settings.view_transform = "Standard"
    world = bpy.data.worlds.new("preview_world")
    scene.world = world
    background = world.node_tree.nodes.get("Background")
    background.inputs["Color"].default_value = (0.36, 0.34, 0.32, 1.0)
    background.inputs["Strength"].default_value = 1.0
    sun = bpy.data.objects.new("preview_sun", bpy.data.lights.new("preview_sun", "SUN"))
    sun.data.energy = 3.0
    sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(35))
    scene.collection.objects.link(sun)
    lo, hi = bounds(visual)
    target = (lo + hi) * 0.5
    camera = bpy.data.objects.new("preview_camera", bpy.data.cameras.new("preview_camera"))
    camera.data.lens_unit = "FOV"
    camera.data.angle = math.radians(40)
    scene.collection.objects.link(camera)
    scene.camera = camera
    views = {"34": (1.0, 1.0, 0.55), "side": (1.0, 0.0, 0.18), "front": (0.0, 1.0, 0.18)}
    for view, direction in views.items():
        d = Vector(direction).normalized()
        camera.location = target + d * distance
        camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = str(out_dir / f"{stem}_cycles_{view}.png")
        bpy.ops.render.render(write_still=True)
    # Silhouette: every surface pure black emission-free, white world, from the 3/4 view.
    black = bpy.data.materials.new("silhouette")
    bsdf = black.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (0.0, 0.0, 0.0, 1.0)
    bsdf.inputs["Roughness"].default_value = 1.0
    bpy.context.view_layer.material_override = black
    background.inputs["Color"].default_value = (1.0, 1.0, 1.0, 1.0)
    sun.data.energy = 0.0
    d = Vector(views["34"]).normalized()
    camera.location = target + d * distance
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = str(out_dir / f"{stem}_cycles_silhouette.png")
    bpy.ops.render.render(write_still=True)
    bpy.context.view_layer.material_override = None


def parse_args(default_out: Path) -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, default=default_out, help="GLB path (default: the game asset)")
    parser.add_argument("--preview", type=Path, default=None, help="directory for Cycles preview PNGs (optional)")
    return parser.parse_args(argv)
