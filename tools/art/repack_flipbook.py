#!/usr/bin/env python3
"""Repack a generated flipbook sheet into an exact N x N grid.

Image models draw the 4 x 4 grid by eye: frames drift off the 512 px cells and big
frames cross the cell borders, so `hframes = vframes = 4` in Godot slices them apart.
This finds the model's own gaps between frames (empty bands in the alpha projection),
cuts each frame on those gaps and pastes it into a clean cell, all frames scaled by
ONE factor so the animation keeps its size and center.

    python3 tools/art/repack_flipbook.py in.png out.png [--grid 4] [--cell 512] [--margin 8]
    python3 tools/art/repack_flipbook.py in.png --check     # only report, write nothing

Exit 1 when the sheet cannot be split into grid x grid frames (re-roll it).
Needs Pillow. Used by the lane D VFX sheets — docs/Art/Prompts/VFX-Sheets-Prompts.md.
"""
import argparse
import sys

from PIL import Image

ALPHA_ON = 16  # alpha above this counts as content (soft edges below it are noise)


def _cuts(profile, parts):
    """Positions of the parts-1 widest empty runs in a 0/1 profile, as run midpoints."""
    runs, start = [], None
    for i, v in enumerate(profile + [1]):
        if v == 0 and start is None:
            start = i
        elif v != 0 and start is not None:
            if start > 0 and i < len(profile):  # interior gaps only
                runs.append((i - start, (start + i) // 2))
            start = None
    if len(runs) < parts - 1:
        return None
    return sorted(mid for _, mid in sorted(runs, reverse=True)[: parts - 1])


def split(alpha, grid):
    """Frame boxes (l, t, r, b) in reading order, or None when the gaps are not there."""
    w, h = alpha.size
    px = alpha.load()
    rows_on = [int(any(px[x, y] > ALPHA_ON for x in range(w))) for y in range(h)]
    ycuts = _cuts(rows_on, grid)
    if ycuts is None:
        return None
    ys = [0] + ycuts + [h]
    boxes = []
    for r in range(grid):
        t, b = ys[r], ys[r + 1]
        cols_on = [int(any(px[x, y] > ALPHA_ON for y in range(t, b))) for x in range(w)]
        xcuts = _cuts(cols_on, grid)
        if xcuts is None:
            return None
        xs = [0] + xcuts + [w]
        boxes += [(xs[c], t, xs[c + 1], b) for c in range(grid)]
    return boxes


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("src")
    ap.add_argument("dst", nargs="?")
    ap.add_argument("--grid", type=int, default=4)
    ap.add_argument("--cell", type=int, default=512)
    ap.add_argument("--margin", type=int, default=8)
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()

    im = Image.open(a.src).convert("RGBA")
    alpha = im.getchannel("A")
    boxes = split(alpha, a.grid)
    if boxes is None:
        print(f"FAIL {a.src}: no {a.grid}x{a.grid} gaps between frames — re-roll the sheet")
        return 1
    # content bbox of every frame; the anchor is the NOMINAL cell center the model aimed at
    # (gap midpoints wander frame to frame and would make the animation jitter)
    nom = im.width / a.grid
    frames = []
    for l, t, r, b in boxes:
        bb = alpha.crop((l, t, r, b)).point(lambda v: 255 if v > ALPHA_ON else 0).getbbox()
        if bb is None:
            print(f"FAIL {a.src}: empty frame at {l},{t}")
            return 1
        frames.append(((l, t, r, b), (l + bb[0], t + bb[1], l + bb[2], t + bb[3])))
    # one scale for all frames: the largest half-extent from a region center must fit the cell
    half = a.cell / 2 - a.margin
    reach = max(
        max(cx - c[0], c[2] - cx, cy - c[1], c[3] - cy)
        for i, (_, c) in enumerate(frames)
        for cx, cy in [((i % a.grid + 0.5) * nom, (i // a.grid + 0.5) * nom)]
    )
    scale = min(1.0, half / reach)
    print(f"OK {a.src}: {len(frames)} frames, scale {scale:.3f}, widest reach {reach:.0f} px")
    if a.check or not a.dst:
        return 0
    out = Image.new("RGBA", (a.cell * a.grid, a.cell * a.grid), (0, 0, 0, 0))
    for i, (_, c) in enumerate(frames):
        cx, cy = (i % a.grid + 0.5) * nom, (i // a.grid + 0.5) * nom
        piece = im.crop(c)
        if scale < 1.0:
            piece = piece.resize((max(1, round(piece.width * scale)), max(1, round(piece.height * scale))), Image.LANCZOS)
        ox = (i % a.grid) * a.cell + a.cell / 2 + (c[0] - cx) * scale
        oy = (i // a.grid) * a.cell + a.cell / 2 + (c[1] - cy) * scale
        out.alpha_composite(piece, (round(ox), round(oy)))
    out.save(a.dst)
    print(f"wrote {a.dst} {out.size[0]}x{out.size[1]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
