#!/usr/bin/env python3
"""Frames of the in-game colour test switch (plan 2026-10-14-T6-Acceptance-Crane-Albedo-AB step 8,
docs/Fix/2026-10-15-Colour-Switch-Fix.md) held against the calibration tool's frames.

    python3 -I tools/art/colour_switch_compare.py --ref REF_DIR [REF_DIR ...] --switch SWITCH_DIR [SWITCH_DIR ...]
        [--out FILE.tsv] [--sheets DIR --prefix 2026-10-15-colour-switch --max-kb 292 --half-width 960]

REF_DIR: tools/art/albedo_ab_capture.gd without --switch, run on the head without the switch (receipt_<hero>.json,
frames <id>_<hero>_A.png and _B3.png: A = the product, B3 = the tool's text swap). SWITCH_DIR: the same tool with
--switch on the head with the switch (receipt_switch_<hero>.json, frames <id>_<hero>_off.png, _on.png, _off2.png).
Per station x hero (both runs must have it):
  off_vs_A     pixels whose RGB differ at all between OFF and A (two processes);
  on_vs_B3     the same between ON and B3, with the largest channel step and the pixels that step by more than 1 and 2;
  off_vs_refA  with --ref-shaders frames (same process, same paused shot, the five shaders set to the texts of the head
               without the switch): OFF against refA, and on_vs_refB3 likewise;
  on_vs_off    pixels the switch changes: must be > 0 (rc 1 otherwise);
  off2         OFF2 == OFF byte for byte (rc 1 otherwise);
  shot         hero position, camera position and basis of the two receipts are the same text.
Judged: off_vs_refA must be 0 when refA exists, else off_vs_A must be 0 (rc 1 otherwise). Across two processes the
residents are not frozen (they and their shadows may stand elsewhere even for the same code), so with refA present the
two-process numbers are reported, not judged.
With --sheets: one labelled OFF | ON JPEG per sheet group of the stations (<= --max-kb each).
rc 0 ok, 1 integrity failure, 2 nothing to compare or a frame missing. Frames are Compatibility / llvmpipe, never M3.
"""
import argparse
import glob
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

TITLES = {"pump": "вулиця з колонкою", "benches": "лавки й урни", "market": "ринок", "plaster": "фасад, штукатурка",
          "truck": "паровантажівка", "car": "паролегковик", "hero": "крупний план"}


def rows_of(dirs, pattern):
    rows = {}
    for frames_dir in dirs:
        for path in sorted(glob.glob(os.path.join(frames_dir, pattern))):
            receipt = json.load(open(path, encoding="utf-8"))
            for st in receipt["stations"]:
                rows[(st["id"], st["hero"])] = (frames_dir, st, receipt)
    return rows


def pixels(path):
    return np.asarray(Image.open(path).convert("RGB")).astype(np.int16)


def compare(a, b):
    step = np.abs(a - b).max(axis=2)
    return int((step > 0).sum()), int(step.max()), int((step > 1).sum()), int((step > 2).sum())


def font(size):
    for path in ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/System/Library/Fonts/Supplemental/Arial.ttf"):
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def sheets(pairs, out_dir, prefix, max_kb, half_w):
    groups = {}
    for frames_dir, st in pairs:
        groups.setdefault(st["sheet"], []).append((frames_dir, st))
    head, small = font(22), font(17)
    made = []
    for group, stations in groups.items():
        tiles = []
        half_h = 0
        for frames_dir, st in stations:
            off = Image.open(os.path.join(frames_dir, st["frames"]["off"])).convert("RGB")
            on = Image.open(os.path.join(frames_dir, st["frames"]["on"])).convert("RGB")
            half_h = round(off.height * half_w / off.width)
            tiles.append((st, off.resize((half_w, half_h), Image.LANCZOS), on.resize((half_w, half_h), Image.LANCZOS)))
        bar, top = 34, 40
        sheet = Image.new("RGB", (2 * half_w, top + len(tiles) * (bar + half_h)), (24, 22, 28))
        draw = ImageDraw.Draw(sheet)
        draw.text((10, 8), "Гра з перемикачем COLOURS (TEST) · Compatibility / llvmpipe, 1920×1080 → %d px, той самий кадр "
                  "і пауза; не M3 / не Forward+" % half_w, fill=(230, 226, 214), font=small)
        y = top
        for st, off, on in tiles:
            name = "%s · %s" % (TITLES.get(st["id"], st["id"]), st["hero"].capitalize())
            draw.text((10, y + 5), "Вимкнено — А, як є (%s)" % name, fill=(240, 236, 220), font=head)
            draw.text((half_w + 10, y + 5), "Увімкнено — Б3 (%s)" % name, fill=(240, 236, 220), font=head)
            y += bar
            sheet.paste(off, (0, y))
            sheet.paste(on, (half_w, y))
            draw.line([(half_w, y), (half_w, y + half_h)], fill=(255, 255, 255), width=2)
            y += half_h
        path = os.path.join(out_dir, "%s-%s.jpg" % (prefix, group))
        quality = 88
        for quality in range(88, 40, -4):
            sheet.save(path, "JPEG", quality=quality, optimize=True, progressive=True)
            if os.path.getsize(path) <= max_kb * 1024:
                break
        made.append("%s %dx%d q%d %d B" % (path, sheet.width, sheet.height, quality, os.path.getsize(path)))
    return made


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--ref", nargs="+", required=True)
    parser.add_argument("--switch", nargs="+", required=True)
    parser.add_argument("--out")
    parser.add_argument("--sheets")
    parser.add_argument("--prefix", default="2026-10-15-colour-switch")
    parser.add_argument("--max-kb", type=int, default=292)
    parser.add_argument("--half-width", type=int, default=960)
    args = parser.parse_args()
    ref = rows_of(args.ref, "receipt_*.json")
    ref = {key: row for key, row in ref.items() if row[2].get("mode") != "switch" and not row[2].get("only_sun")}
    switch = rows_of(args.switch, "receipt_switch_*.json")
    keys = [key for key in switch if key in ref]
    if not keys:
        print("COLOUR_SWITCH_COMPARE nothing to compare (ref %d, switch %d)" % (len(ref), len(switch)))
        return 2
    failures = 0
    lines = ["station\thero\toff_vs_A\ton_vs_B3\ton_vs_B3_max_step\ton_vs_B3_gt1\ton_vs_B3_gt2\toff_vs_refA\ton_vs_refB3\t"
             "on_vs_refB3_max_step\ton_vs_off\toff2_equals_off\tsame_shot\tpixels"]
    pairs = []
    for key in keys:
        ref_dir, ref_st, _ = ref[key]
        sw_dir, sw_st, _ = switch[key]
        try:
            a = pixels(os.path.join(ref_dir, ref_st["frames"]["A"]))
            b3 = pixels(os.path.join(ref_dir, ref_st["frames"]["B3"]))
            off = pixels(os.path.join(sw_dir, sw_st["frames"]["off"]))
            on = pixels(os.path.join(sw_dir, sw_st["frames"]["on"]))
            off2 = pixels(os.path.join(sw_dir, sw_st["frames"]["off2"]))
        except (KeyError, OSError) as error:
            print("COLOUR_SWITCH_COMPARE %s_%s frame missing: %s" % (key[0], key[1], error))
            return 2
        if a.shape != off.shape:
            print("COLOUR_SWITCH_INTEGRITY FAIL %s_%s: frame sizes differ %s vs %s" % (key[0], key[1], a.shape, off.shape))
            failures += 1
            continue
        off_a = compare(off, a)[0]
        on_b3 = compare(on, b3)
        on_off = compare(on, off)[0]
        off2_ok = bool((off2 == off).all())
        has_ref = "refA" in sw_st["frames"] and "refB3" in sw_st["frames"]
        off_ref, on_ref = (-1, (-1, -1, -1, -1))
        if has_ref:
            off_ref = compare(off, pixels(os.path.join(sw_dir, sw_st["frames"]["refA"])))[0]
            on_ref = compare(on, pixels(os.path.join(sw_dir, sw_st["frames"]["refB3"])))
        same_shot = all(ref_st[field] == sw_st[field] for field in ("hero_position", "camera_position", "camera_basis"))
        total = off.shape[0] * off.shape[1]
        print("COLOUR_SWITCH_COMPARE %s_%s off_vs_A=%d on_vs_B3=%d max_step=%d gt1=%d gt2=%d off_vs_refA=%d on_vs_refB3=%d "
              "ref_max_step=%d on_vs_off=%d off2_equals_off=%s same_shot=%s px=%d"
              % (key[0], key[1], off_a, on_b3[0], on_b3[1], on_b3[2], on_b3[3], off_ref, on_ref[0], on_ref[1], on_off,
                 off2_ok, same_shot, total))
        lines.append("\t".join(str(v) for v in (key[0], key[1], off_a, *on_b3, off_ref, on_ref[0], on_ref[1], on_off,
                                                 off2_ok, same_shot, total)))
        judged = (off_ref != 0, "OFF differs from refA in %d px" % off_ref) if has_ref else \
            (off_a != 0, "OFF differs from A in %d px" % off_a)
        for bad, why in (judged, (on_off == 0, "ON equals OFF"), (not off2_ok, "OFF2 differs from OFF")):
            if bad:
                print("COLOUR_SWITCH_INTEGRITY FAIL %s_%s: %s" % (key[0], key[1], why))
                failures += 1
        pairs.append((sw_dir, sw_st))
    if args.out:
        with open(args.out, "w", encoding="utf-8") as handle:
            handle.write("\n".join(lines) + "\n")
    if args.sheets:
        os.makedirs(args.sheets, exist_ok=True)
        for made in sheets(pairs, args.sheets, args.prefix, args.max_kb, args.half_width):
            print("COLOUR_SWITCH_SHEET " + made)
    print("COLOUR_SWITCH_COMPARE_COMPLETE stations=%d failures=%d" % (len(keys), failures))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
