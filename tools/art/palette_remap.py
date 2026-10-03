#!/usr/bin/env python3
"""Палітра-атлас паку пропів → кольори Sketch-Cel. Інструмент T6 Аполлона.

Паки на кшталт KayKit фарбують усі моделі однією текстурою-атласом: сітка плашок-градієнтів, кожна модель
бере колір через UV. Перефарбуй атлас — і сотні моделей отримують нашу палітру за 0 кредитів
(docs/Plans/2026-10-03-Santos-Packs-Arenas.md, Ф3; таблиця — docs/Art/Palette-Remap.md).

  scan     плашки атласу (сітка + вкладені смуги), їхні кольори, хто з моделей паку їх бере (UV з .gltf/.glb)
  render   таблиця Palette-Remap.md → атлас із пласкими плашками нашої палітри; --board — дошка «було / стало»
  derive   колір «стало» за правилом: тон і насиченість — від джерела (Style-Guide / канон), світлота — від паку
  selftest синтетичний атлас + синтетичний glTF у тимчасовій теці: сітка, смуга, UV, заливка, ідемпотентність

Приклади:
  python3 tools/art/palette_remap.py scan --atlas <pack>/dungeon_texture.png --models <pack>/gltf
  python3 tools/art/palette_remap.py render --atlas <pack>/dungeon_texture.png \\
      --map docs/Art/Palette-Remap.md --out /tmp/kaykit_dungeon_day.png --board /tmp/board.png
  python3 tools/art/palette_remap.py selftest

Тільки Pillow + stdlib, без мережі. rc: 0 ok · 1 перевірка не пройшла · 2 не змогли виміряти.
"""
from __future__ import annotations

import argparse
import base64
import colorsys
import json
import re
import struct
import sys
import tempfile
from collections import Counter
from dataclasses import dataclass, field
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError:  # без Pillow виміряти не можемо — це rc 2, а не тихий нуль
    print("ВІДМОВА виміряти: немає Pillow (pip install pillow)")
    sys.exit(2)

DIFF = 18          # поріг різниці кольору (евклід RGB), вище — піксель належить вкладеній смузі
EDGE = 2           # стовпець-зразок рядка: стільки пікселів від лівого краю клітинки
HEX_RE = re.compile(r"^#[0-9A-Fa-f]{6}$")
ROW_RE = re.compile(r"^\|\s*`(r\d+c\d+s?)`\s*\|")


class Unmeasurable(Exception):
    """Вхід не дає виміряти (нема файла, битий glTF, кривий атлас) → rc 2."""


@dataclass
class Region:
    id: str                      # r<рядок>c<стовпець>, смуга — з суфіксом s
    rect: tuple[int, int, int, int]   # x0, y0, x1, y1 (x1/y1 не включно)
    parent: str | None = None
    fill: float = 1.0            # частка пікселів смуги в її рамці (1.0 — рівний прямокутник)
    verts: int = 0
    models: Counter = field(default_factory=Counter)
    used_rgb: list = field(default_factory=list)   # кольори атласу під кожною UV-вершиною

    def contains(self, x: int, y: int) -> bool:
        x0, y0, x1, y1 = self.rect
        return x0 <= x < x1 and y0 <= y < y1


def hexc(rgb) -> str:
    return "#{:02X}{:02X}{:02X}".format(*rgb[:3])


def dist(a, b) -> float:
    return ((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2) ** 0.5


def parse_grid(s: str) -> tuple[int, int]:
    m = re.fullmatch(r"(\d+)x(\d+)", s)
    if not m or int(m.group(1)) < 1 or int(m.group(2)) < 1:
        raise argparse.ArgumentTypeError(f"сітка має бути CxR, напр. 8x4, а не {s!r}")
    return int(m.group(1)), int(m.group(2))


def load_atlas(path: Path) -> Image.Image:
    if not path.is_file():
        raise Unmeasurable(f"атласу немає: {path}")
    try:
        return Image.open(path).convert("RGB")
    except OSError as exc:
        raise Unmeasurable(f"атлас не читається: {path} ({exc})")


def find_regions(img: Image.Image, cols: int, rows: int) -> list[Region]:
    """Клітинки сітки + вкладена смуга в кожній, де вона є.

    Плашки — вертикальні градієнти, тож зразок рядка — піксель біля лівого краю клітинки: усе, що в тому ж
    рядку відрізняється від нього більше за DIFF, належить смузі (обрамлення, торець, кант).
    """
    w, h = img.size
    if w % cols or h % rows:
        raise Unmeasurable(f"атлас {w}×{h} не ділиться на сітку {cols}×{rows}")
    cw, ch = w // cols, h // rows
    if cw <= EDGE * 2 or ch < 2:
        raise Unmeasurable(f"клітинка {cw}×{ch} надто мала для сітки {cols}×{rows}")
    px = img.load()
    out: list[Region] = []
    for r in range(rows):
        for c in range(cols):
            x0, y0 = c * cw, r * ch
            main = Region(f"r{r}c{c}", (x0, y0, x0 + cw, y0 + ch))
            out.append(main)
            bx0 = by0 = 10 ** 9
            bx1 = by1 = -1
            hits = 0
            for y in range(y0, y0 + ch):
                ref = px[x0 + EDGE, y]
                for x in range(x0, x0 + cw):
                    if dist(px[x, y], ref) > DIFF:
                        hits += 1
                        bx0, by0 = min(bx0, x), min(by0, y)
                        bx1, by1 = max(bx1, x), max(by1, y)
            if hits:
                area = (bx1 - bx0 + 1) * (by1 - by0 + 1)
                out.append(Region(f"r{r}c{c}s", (bx0, by0, bx1 + 1, by1 + 1), parent=main.id,
                                  fill=hits / area))
    return out


# ---------- glTF: тільки те, що треба для UV ----------

_COMP = {5126: ("f", 4, None), 5123: ("H", 2, 65535.0), 5121: ("B", 1, 255.0)}


def _load_gltf(path: Path) -> tuple[dict, list[bytes]]:
    data = path.read_bytes()
    if path.suffix.lower() == ".glb":
        if data[:4] != b"glTF":
            raise Unmeasurable(f"{path.name}: не GLB")
        off, js, binchunk = 12, None, b""
        while off + 8 <= len(data):
            ln, kind = struct.unpack_from("<II", data, off)
            chunk = data[off + 8: off + 8 + ln]
            if kind == 0x4E4F534A:
                js = json.loads(chunk.decode("utf-8"))
            elif kind == 0x004E4942:
                binchunk = chunk
            off += 8 + ln
        if js is None:
            raise Unmeasurable(f"{path.name}: у GLB немає JSON")
        bufs = []
        for i, b in enumerate(js.get("buffers", [])):
            bufs.append(binchunk if i == 0 and "uri" not in b else _buffer_uri(path, b["uri"]))
        return js, bufs
    js = json.loads(data.decode("utf-8"))
    return js, [_buffer_uri(path, b["uri"]) for b in js.get("buffers", [])]


def _buffer_uri(path: Path, uri: str) -> bytes:
    if uri.startswith("data:"):
        return base64.b64decode(uri.split(",", 1)[1])
    p = path.parent / uri
    if not p.is_file():
        raise Unmeasurable(f"{path.name}: немає буфера {uri}")
    return p.read_bytes()


def _texcoords(js: dict, bufs: list[bytes], acc_i: int) -> list[tuple[float, float]]:
    a = js["accessors"][acc_i]
    if a.get("type") != "VEC2" or a.get("componentType") not in _COMP:
        raise Unmeasurable(f"TEXCOORD_0 непідтримуваного типу {a.get('type')}/{a.get('componentType')}")
    fmt, size, norm = _COMP[a["componentType"]]
    bv = js["bufferViews"][a["bufferView"]]
    buf = bufs[bv["buffer"]]
    off = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    stride = bv.get("byteStride") or size * 2
    out = []
    for i in range(a["count"]):
        u, v = struct.unpack_from("<" + fmt * 2, buf, off + i * stride)
        if norm:
            u, v = u / norm, v / norm
        out.append((u, v))
    return out


def model_uvs(path: Path, atlas_name: str) -> tuple[list[tuple[float, float]], list[str]]:
    """UV усіх примітивів, чий baseColor — саме цей атлас (за іменем файла). Плюс примітки."""
    try:
        js, bufs = _load_gltf(path)
    except (OSError, ValueError, KeyError, struct.error) as exc:
        raise Unmeasurable(f"{path.name}: glTF не читається ({exc})")
    notes = []
    if "KHR_texture_transform" in js.get("extensionsUsed", []):
        notes.append(f"{path.name}: KHR_texture_transform ігнорується")
    images = js.get("images", [])
    textures = js.get("textures", [])
    mats = js.get("materials", [])

    def uses_atlas(mat_i) -> bool:
        if mat_i is None or mat_i >= len(mats):
            return False
        bct = mats[mat_i].get("pbrMetallicRoughness", {}).get("baseColorTexture")
        if not bct:
            return False
        src = textures[bct["index"]].get("source")
        if src is None or src >= len(images):
            return False
        img = images[src]
        name = Path(img.get("uri", "")).name or img.get("name", "")
        return Path(name).stem == Path(atlas_name).stem

    out = []
    for mesh in js.get("meshes", []):
        for prim in mesh.get("primitives", []):
            tc = prim.get("attributes", {}).get("TEXCOORD_0")
            if tc is None or not uses_atlas(prim.get("material")):
                continue
            try:
                out.extend(_texcoords(js, bufs, tc))
            except (KeyError, IndexError, struct.error) as exc:
                raise Unmeasurable(f"{path.name}: UV не читаються ({exc})")
    return out, notes


def attach_usage(img: Image.Image, regions: list[Region], models_dir: Path, atlas_name: str) -> dict:
    if not models_dir.is_dir():
        raise Unmeasurable(f"теки моделей немає: {models_dir}")
    files = sorted(p for p in models_dir.iterdir() if p.suffix.lower() in (".gltf", ".glb"))
    if not files:
        raise Unmeasurable(f"у {models_dir} немає .gltf/.glb")
    w, h = img.size
    px = img.load()
    strips = [r for r in regions if r.parent]
    mains = [r for r in regions if not r.parent]
    stats = {"models": len(files), "with_atlas": 0, "verts": 0, "wrapped": 0, "notes": []}
    for f in files:
        uvs, notes = model_uvs(f, atlas_name)
        stats["notes"].extend(notes)
        if not uvs:
            continue
        stats["with_atlas"] += 1
        for u, v in uvs:
            if not (0.0 <= u <= 1.0 and 0.0 <= v <= 1.0):
                stats["wrapped"] += 1
                u, v = u % 1.0, v % 1.0
            # glTF: (0, 0) — лівий верхній кут зображення
            x, y = min(int(u * w), w - 1), min(int(v * h), h - 1)
            reg = next((s for s in strips if s.contains(x, y)), None) or \
                next(m for m in mains if m.contains(x, y))
            reg.verts += 1
            reg.models[f.stem] += 1
            reg.used_rgb.append(px[x, y])
        stats["verts"] += len(uvs)
    return stats


def region_colors(img: Image.Image, reg: Region) -> tuple[str, str, str]:
    """Верх · середина · низ плашки (для смуги — по її центральному стовпцю)."""
    px = img.load()
    x0, y0, x1, y1 = reg.rect
    x = x0 + EDGE if not reg.parent else (x0 + x1) // 2
    pick = lambda t: hexc(px[x, min(y1 - 1, y0 + int((y1 - y0) * t))])
    return pick(0.05), pick(0.5), pick(0.95)


def used_color(reg: Region) -> str:
    if not reg.used_rgb:
        return "—"
    chans = list(zip(*reg.used_rgb))
    return hexc([sorted(c)[len(c) // 2] for c in chans])


def cmd_scan(a) -> int:
    img = load_atlas(a.atlas)
    regions = find_regions(img, *a.grid)
    stats = attach_usage(img, regions, a.models, a.atlas.name) if a.models else None
    print("| плашка | рамка x0,y0–x1,y1 | верх · середина · низ | під UV (медіана) | вершин | моделей | хто бере (топ-5) |")
    print("|---|---|---|---|---|---|---|")
    for reg in regions:
        t, m, b = region_colors(img, reg)
        top = ", ".join(f"`{k}`" for k, _ in reg.models.most_common(5)) or "—"
        rect = "{},{}–{},{}".format(*reg.rect)
        if reg.parent and reg.fill < 0.95:
            rect += f" (відрізняється від градієнта в {reg.fill:.0%} рамки)"
        print(f"| `{reg.id}` | {rect} | `{t}` · `{m}` · `{b}` | `{used_color(reg)}` | {reg.verts} | "
              f"{len(reg.models)} | {top} |")
    if stats:
        used = sum(1 for r in regions if r.verts)
        print(f"\nмоделей: {stats['models']} · з цим атласом: {stats['with_atlas']} · вершин: {stats['verts']} · "
              f"UV поза [0,1] (загорнуто): {stats['wrapped']} · плашок: {len(regions)} · з вершинами: {used}")
        for n in stats["notes"]:
            print(f"   примітка: {n}")
    return 0


def parse_map(path: Path, section: str | None = None) -> dict[str, str | None]:
    """Таблиця з колонками «плашка» і «стало». Значення: #RRGGBB або «—» (лишити як є).

    section — текст заголовка: читаємо лише від нього до наступного заголовка того ж або вищого рівня
    (у файлі кілька атласів, а id плашок r0c0… у них однакові).
    """
    if not path.is_file():
        raise Unmeasurable(f"таблиці немає: {path}")
    lines = path.read_text(encoding="utf-8").splitlines()
    if section:
        start = level = None
        fence = False
        for i, line in enumerate(lines):
            if line.lstrip().startswith("```"):
                fence = not fence
            h = None if fence else re.match(r"^(#+)\s+(.*)", line)
            if not h:
                continue
            if start is None and section in h.group(2):
                start, level = i, len(h.group(1))
            elif start is not None and len(h.group(1)) <= level:
                lines = lines[start:i]
                break
        else:
            if start is None:
                raise Unmeasurable(f"{path.name}: немає заголовка з «{section}»")
            lines = lines[start:]
    col = None
    out: dict[str, str | None] = {}
    seen: set[str] = set()
    bad = []
    for ln, line in enumerate(lines, 1):
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if "плашка" in cells[0] and any("стало" in c for c in cells):
            col = next(i for i, c in enumerate(cells) if "стало" in c)
            continue
        m = ROW_RE.match(line.strip())
        if not m or col is None:
            continue
        rid = m.group(1)
        if rid in seen:
            bad.append(f"рядок {ln}: `{rid}` удруге")
            continue
        seen.add(rid)
        val = cells[col].strip("` ") if col < len(cells) else ""
        if val in ("—", "-"):
            out[rid] = None
        elif HEX_RE.match(val):
            out[rid] = val.upper()
        else:
            bad.append(f"рядок {ln}: `{rid}` → {val!r} не #RRGGBB і не «—»")
    if col is None:
        raise Unmeasurable(f"{path.name}: немає заголовка з колонками «плашка» і «стало»")
    if bad:
        raise ValueError("; ".join(bad))
    return out


def render(img: Image.Image, regions: list[Region], mapping: dict[str, str | None]) -> Image.Image:
    out = img.copy()
    draw = ImageDraw.Draw(out)
    # спершу клітинки, потім смуги поверх — смуга живе всередині своєї клітинки
    for reg in sorted(regions, key=lambda r: r.parent is not None):
        val = mapping.get(reg.id)
        if val:
            x0, y0, x1, y1 = reg.rect
            draw.rectangle([x0, y0, x1 - 1, y1 - 1], fill=val)
    return out


def board(img: Image.Image, new: Image.Image, regions: list[Region]) -> Image.Image:
    """Кожна плашка: ліворуч — було (середина), праворуч — стало; підпис id."""
    sw, pad, per_row = 120, 8, 8
    rows = (len(regions) + per_row - 1) // per_row
    cell_w, cell_h = sw * 2 + pad, sw // 2 + 18
    b = Image.new("RGB", (per_row * (cell_w + pad) + pad, rows * (cell_h + pad) + pad), "#B8CBB1")
    d = ImageDraw.Draw(b)
    po, pn = img.load(), new.load()
    for i, reg in enumerate(regions):
        x = pad + (i % per_row) * (cell_w + pad)
        y = pad + (i // per_row) * (cell_h + pad)
        x0, y0, x1, y1 = reg.rect
        cx, cy = (x0 + x1) // 2 if reg.parent else x0 + EDGE, (y0 + y1) // 2
        d.rectangle([x, y, x + sw - 1, y + sw // 2 - 1], fill=po[cx, cy])
        d.rectangle([x + sw + pad, y, x + 2 * sw + pad - 1, y + sw // 2 - 1], fill=pn[cx, cy])
        d.text((x, y + sw // 2 + 3), f"{reg.id}  {hexc(po[cx, cy])} > {hexc(pn[cx, cy])}", fill="#2B2230")
    return b


def save_png(im: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path, format="PNG", optimize=False)   # без метаданих і дат → той самий sha256 щоразу


def cmd_render(a) -> int:
    img = load_atlas(a.atlas)
    regions = find_regions(img, *a.grid)
    try:
        mapping = parse_map(a.map, a.section)
    except ValueError as exc:
        print(f"ВІДМОВА: таблиця крива — {exc}")
        return 1
    ids = {r.id for r in regions}
    unknown = sorted(set(mapping) - ids)
    missing = sorted(ids - set(mapping))
    if a.models:
        attach_usage(img, regions, a.models, a.atlas.name)
        missing_used = [r.id for r in regions if r.id in missing and r.verts]
    else:
        missing_used = []
    for rid in unknown:
        print(f"   у таблиці, але не в атласі: `{rid}`")
    for rid in missing:
        tag = " (її беруть моделі!)" if rid in missing_used else ""
        print(f"   немає в таблиці: `{rid}`{tag}")
    if unknown or missing_used or (missing and a.strict):
        print("ВІДМОВА: таблиця не покриває атлас — нічого не записано")
        return 1
    new = render(img, regions, mapping)
    save_png(new, a.out)
    print(f"   записано: {a.out} ({new.size[0]}×{new.size[1]}), перефарбовано плашок: "
          f"{sum(1 for r in regions if mapping.get(r.id))} з {len(regions)}")
    if a.board:
        save_png(board(img, new, regions), a.board)
        print(f"   дошка: {a.board}")
    return 0


def derive(src: str, like: str, sat_cap: float, light: float | None = None, sat: float | None = None) -> str:
    """Тон джерела + насиченість не вище стелі (або явна) + світлота плашки паку (або явна).

    Світлоту беремо з паку, бо автор паку вже розвів нею частини моделі (стіна світліша за фундамент);
    тон і насиченість — наші, щоб пропи не сперечались із бійцями за найяскравішу пляму.
    """
    for h in (src, like):
        if not HEX_RE.match(h):
            raise ValueError(f"{h!r} не #RRGGBB")
    rgb = lambda h: [int(h[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    hs, ls, ss = colorsys.rgb_to_hls(*rgb(src))
    _, ll, _ = colorsys.rgb_to_hls(*rgb(like))
    for v in (sat_cap, light, sat):
        if v is not None and not 0.0 <= v <= 1.0:
            raise ValueError(f"{v} поза 0..1")
    r, g, b = colorsys.hls_to_rgb(hs, ll if light is None else light, min(ss, sat_cap) if sat is None else sat)
    return hexc([round(c * 255) for c in (r, g, b)])


def cmd_derive(a) -> int:
    try:
        print(derive(a.src, a.like, a.sat_cap, a.light, a.sat))
    except ValueError as exc:
        print(f"ВІДМОВА: {exc}")
        return 1
    return 0


def cmd_selftest(_a) -> int:
    """Синтетика з відомою відповіддю: якщо будь-що зламається в сітці, смузі, UV чи заливці — rc 1."""
    fails = []
    with tempfile.TemporaryDirectory() as td:
        t = Path(td)
        # атлас 4×2 клітинки по 8×16: градієнти + смуга в r0c1 (x 13–15, y 2–13)
        img = Image.new("RGB", (32, 32))
        px = img.load()
        for c in range(4):
            for y in range(32):
                for x in range(c * 8, c * 8 + 8):
                    px[x, y] = (40 * c + 20, 200 - y * 3, 60 + y * 2)
        for y in range(2, 14):
            for x in range(13, 16):
                px[x, y] = (250, 250, 250)
        img.save(t / "atlas.png")
        regs = find_regions(img, 4, 2)
        ids = [r.id for r in regs]
        if ids.count("r0c1s") != 1 or len(regs) != 9:
            fails.append(f"сітка/смуга: {ids}")
        strip = next((r for r in regs if r.id == "r0c1s"), None)
        if strip and strip.rect != (13, 2, 16, 14):
            fails.append(f"рамка смуги {strip.rect} ≠ (13, 2, 16, 14)")
        # glTF з трьома UV: смуга r0c1s, клітинка r1c3, і u=1.5 (загортається в r0c2)
        uv = struct.pack("<6f", 14.5 / 32, 5 / 32, 30 / 32, 25 / 32, 1.5, 3 / 32)
        js = {
            "asset": {"version": "2.0"},
            "buffers": [{"uri": "data:application/octet-stream;base64," + base64.b64encode(uv).decode(),
                         "byteLength": len(uv)}],
            "bufferViews": [{"buffer": 0, "byteOffset": 0, "byteLength": len(uv)}],
            "accessors": [{"bufferView": 0, "componentType": 5126, "count": 3, "type": "VEC2"}],
            "images": [{"uri": "atlas.png"}], "textures": [{"source": 0}],
            "materials": [{"pbrMetallicRoughness": {"baseColorTexture": {"index": 0}}}],
            "meshes": [{"primitives": [{"attributes": {"TEXCOORD_0": 0}, "material": 0}]}],
        }
        (t / "m").mkdir()
        (t / "m" / "probe.gltf").write_text(json.dumps(js), encoding="utf-8")
        st = attach_usage(img, regs, t / "m", "atlas.png")
        got = {r.id: r.verts for r in regs if r.verts}
        if got != {"r0c1s": 1, "r1c3": 1, "r0c2": 1} or st["wrapped"] != 1:
            fails.append(f"UV → плашки: {got}, загорнуто {st['wrapped']}")
        # таблиця: перефарбувати r0c1 і смугу, решту лишити
        md = t / "map.md"
        md.write_text("| плашка | що | стало |\n|---|---|---|\n| `r0c1` | a | `#112233` |\n"
                      "| `r0c1s` | b | `#FFEEDD` |\n| `r1c3` | c | — |\n", encoding="utf-8")
        new = render(img, regs, parse_map(md))
        npx = new.load()
        if npx[9, 14] != (0x11, 0x22, 0x33) or npx[14, 5] != (0xFF, 0xEE, 0xDD) or npx[0, 0] != px[0, 0]:
            fails.append("заливка: клітинка/смуга/незмінна плашка не ті")
        # ідемпотентність: два записи — байт у байт
        save_png(new, t / "a.png")
        save_png(render(img, regs, parse_map(md)), t / "b.png")
        if (t / "a.png").read_bytes() != (t / "b.png").read_bytes():
            fails.append("два прогони дали різні файли")
        # два атласи в одному файлі: секція бере лише свою таблицю
        md.write_text("# A\n```\n# B — коментар у коді, не заголовок\n```\n"
                      "| плашка | стало |\n|---|---|\n| `r0c0` | `#000001` |\n"
                      "# B\n| плашка | стало |\n|---|---|\n| `r0c0` | `#000002` |\n", encoding="utf-8")
        try:
            got_a, got_b = parse_map(md, "A"), parse_map(md, "B")
            if got_b != {"r0c0": "#000002"} or got_a != {"r0c0": "#000001"}:
                fails.append(f"секції: A={got_a}, B={got_b}")
        except (ValueError, Unmeasurable) as exc:
            fails.append(f"секції: {exc}")
        # крива таблиця має падати, а не мовчати
        md.write_text("| плашка | стало |\n|---|---|\n| `r0c1` | синій |\n", encoding="utf-8")
        try:
            parse_map(md)
            fails.append("крива таблиця пройшла")
        except ValueError:
            pass
    # derive: тон джерела, світлота паку, стеля насиченості
    if derive("#FF0000", "#808080", 1.0) != "#FF0101":   # L паку 128/255 = 0.502 → 1.0, 0.004, 0.004
        fails.append(f"derive червоний: {derive('#FF0000', '#808080', 1.0)}")
    if derive("#FF0000", "#808080", 0.0) != "#808080":
        fails.append(f"derive без насиченості ≠ сірий паку: {derive('#FF0000', '#808080', 0.0)}")
    for f in fails:
        print(f"   FAIL: {f}")
    print("selftest: OK" if not fails else f"selftest: {len(fails)} FAIL")
    return 1 if fails else 0


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("scan")
    s.add_argument("--atlas", type=Path, required=True)
    s.add_argument("--models", type=Path, help="тека з .gltf/.glb паку (необов'язково)")
    s.add_argument("--grid", type=parse_grid, default=(8, 4))
    r = sub.add_parser("render")
    r.add_argument("--atlas", type=Path, required=True)
    r.add_argument("--map", type=Path, required=True)
    r.add_argument("--out", type=Path, required=True)
    r.add_argument("--board", type=Path)
    r.add_argument("--section", help="заголовок розділу з таблицею цього атласу (у файлі їх кілька)")
    r.add_argument("--models", type=Path, help="з моделями: плашка, яку беруть моделі, мусить бути в таблиці")
    r.add_argument("--grid", type=parse_grid, default=(8, 4))
    r.add_argument("--strict", action="store_true", help="кожна плашка атласу мусить бути в таблиці")
    d = sub.add_parser("derive")
    d.add_argument("--src", required=True, help="тон-джерело, #RRGGBB (Style-Guide або канон)")
    d.add_argument("--like", required=True, help="плашка паку, з якої береться світлота, #RRGGBB")
    d.add_argument("--sat-cap", type=float, default=0.35, help="стеля насиченості HSL, 0..1")
    d.add_argument("--light", type=float, help="світлота HSL 0..1 замість світлоти паку")
    d.add_argument("--sat", type=float, help="насиченість HSL 0..1 замість стелі (коли тон-джерело надто сіре)")
    sub.add_parser("selftest")
    a = p.parse_args(argv)
    try:
        return {"scan": cmd_scan, "render": cmd_render, "derive": cmd_derive,
                "selftest": cmd_selftest}[a.cmd](a)
    except Unmeasurable as exc:
        print(f"ВІДМОВА виміряти: {exc}")
        return 2


if __name__ == "__main__":
    sys.exit(main())
