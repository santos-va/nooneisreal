#!/usr/bin/env python3
"""Albedo A/B numbers and sheets (plan 2026-10-14 step 5) from the frames of tools/art/albedo_ab_capture.gd.

    python3 -I tools/art/albedo_ab_table.py FRAMES_DIR [FRAMES_DIR ...] [--out DIR]
        [--sheets DIR --prefix 2026-10-14-albedo-ab --max-kb 300 --sun-sheet market,benches]

Each FRAMES_DIR holds receipt_<hero>[_sun].json and the PNGs it names; "_sun" receipts come from --only-sun runs
(series "sun"). Writes to --out (default: the first FRAMES_DIR) ab_table.tsv (every station x label x band),
ab_summary.tsv (city labels pooled over Choko's stations, per series) and ab_checks.txt. With --sheets: one labelled
A | B1 JPEG per sheet group of the "as-is" series (<= --max-kb) plus <prefix>-sun.jpg, a diagnostic only-sun sheet of
the --sun-sheet stations. rc 0 ok, 1 integrity failure, 2 no receipts.

Measurement (frames are Compatibility / llvmpipe, never M3):
  * pixels of a label = exact ID-pass colour (+-6 per channel) whose 8 neighbours carry the same label, so MSAA edges,
    ink hulls and anything drawn over the surface drop out;
  * lit / shadow = the lit pass (white = step(0.20, N.L) * step(0.5, ATTENUATION), city_surface.gdshader:118);
  * mean colour = mean of the pixels in linear light (exact sRGB curve), encoded back to sRGB 8-bit;
  * dE76 = CIE76 in CIELAB (D65) between that sRGB colour and the palette hex read as an sRGB colour (the screen
    value the style guide means). Both sides are display-referred sRGB, so they live in one space.
Integrity (rc 1, line "ALBEDO_AB_INTEGRITY FAIL ..."): A2 must equal A pixel for pixel; in every station the city
labels (all pixels) and the hero labels (sun-lit pixels only: in a cast shadow toon/hero_garment get no direct light,
ATTENUATION 0, so A and B1 agree there by design) must change between A and B1 in >= 50 % of their pixels (each
family with >= MIN_PX pixels), otherwise B1 did not reach that shader family (negative control: albedo_ab_capture.gd --break=stuck).
Formula columns (flat palette colour, no surface pattern, tonemap Linear, one sun, ambient off for city_surface):
  extends scratchpad t3-albedo-probe/formula_table.py (T3, docs/Research/2026-10-14-Godot-Diffuse-Albedo.md):
  Forward+  lit  A: A(f+g) + A^2 L k   B1: A(f+g) + A L k     A, T linear (uniforms converted on the CPU)
            shade   A^2 S L k ...           A S L k ...       S = 0.5*0.65 + 0.35*T
  Compat.   A = s2l_poly(p), E = s2l_poly(p(f+g)), S uses T raw sRGB, output l2s_poly (gles3 tonemap_inc.glsl).
  L = lin(sun) * energy = lin(1.0, 0.97, 0.94) * 0.95 (CityWorld.gd:466-467); f, k, g per label from the receipt's
  city_params (district: f 0.16, k 2.2 = city_surface.gdshader:17-18 defaults, warm_window g 0.15 = CityMaterials.gd:26;
  "<key>@f..k..g.." labels are variants such as CityInteriors.gd:14-17, f 0.28 k 1.65).
"""
import argparse
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

SUN = (1.0, 0.97, 0.94)
ENERGY = 0.95
TINT = "b07aa6"
FLAT_KINDS = {"copper", "brass", "iron", "iron_paint", "ink", "glass", "warm_window", "marker"}  # surface_kind 0
TITLES = {"pump": "вулиця з колонкою", "benches": "лавки й урни", "market": "ринок", "plaster": "фасад, штукатурка",
          "truck": "паровантажівка", "car": "паролегковик", "hero": "крупний план"}
TOL = 6
MIN_PX = 150


def lin(c):
    return c / 12.92 if c < 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def srgb(x):
    x = max(0.0, min(1.0, x))
    return 12.92 * x if x < 0.0031308 else 1.055 * x ** (1 / 2.4) - 0.055


def poly(c):  # gles3 tonemap_inc.glsl:22-25 (srgb_to_linear approximation)
    return c * (c * (c * 0.305306011 + 0.682171111) + 0.012522878)


def srgb_a(x):  # gles3 tonemap_inc.glsl:14-19 (linear_to_srgb approximation)
    return max(1.055 * max(x, 0.0) ** 0.416666667 - 0.055, 0.0)


def hex_rgb(h):
    return [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]


def rgb_hex(rgb):
    return "".join("%02x" % int(round(max(0, min(1, c)) * 255)) for c in rgb)


def lab(rgb):
    r, g, b = (lin(c) for c in rgb)
    x = (0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / 0.95047
    y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b
    z = (0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / 1.08883
    f = [t ** (1 / 3) if t > 216 / 24389 else (24389 / 27 * t + 16) / 116 for t in (x, y, z)]
    return (116 * f[1] - 16, 500 * (f[0] - f[1]), 200 * (f[1] - f[2]))


def de76(a, b):
    la, lb = lab(a), lab(b)
    return math.sqrt(sum((p - q) ** 2 for p, q in zip(la, lb)))


def formula(hexcode, fill, gain, glow):
    """{(renderer, variant, band): sRGB triple} for a flat palette colour with this painted_fill / key_gain / glow."""
    p = hex_rgb(hexcode)
    t = hex_rgb(TINT)
    out = {}
    for ch in range(3):
        light = lin(SUN[ch]) * ENERGY * gain
        a_f = lin(p[ch])
        s_f = 0.325 + 0.35 * lin(t[ch])
        a_c = poly(p[ch])
        e_c = poly(p[ch] * (fill + glow))
        s_c = 0.325 + 0.35 * t[ch]
        for band, sf, sc in (("lit", 1.0, 1.0), ("shadow", s_f, s_c)):
            out.setdefault(("F+", "A", band), []).append(srgb(a_f * (fill + glow) + a_f * a_f * sf * light))
            out.setdefault(("F+", "B1", band), []).append(srgb(a_f * (fill + glow) + a_f * sf * light))
            out.setdefault(("Compat", "A", band), []).append(srgb_a(min(1.0, e_c + a_c * a_c * sc * light)))
            out.setdefault(("Compat", "B1", band), []).append(srgb_a(min(1.0, e_c + a_c * sc * light)))
    return out


LIN = np.array([lin(v / 255) for v in range(256)], dtype=np.float64)


def load(path):
    return np.asarray(Image.open(path).convert("RGB"), dtype=np.uint8)


def decode(label_img, labels):
    names = list(labels)
    ids = np.full(label_img.shape[:2], -1, dtype=np.int16)
    img = label_img.astype(np.int16)
    for index, name in enumerate(names):
        want = np.array([int(labels[name][i:i + 2], 16) for i in (0, 2, 4)], dtype=np.int16)
        hit = np.abs(img - want).max(axis=2) <= TOL
        ids[hit] = index
    pad = np.pad(ids, 1, constant_values=-2)
    same = ids >= 0
    h, w = ids.shape
    for dy in (0, 1, 2):
        for dx in (0, 1, 2):
            same &= pad[dy:dy + h, dx:dx + w] == ids
    ids[~same] = -1
    return names, ids


def mean_srgb(img, mask):
    linear = LIN[img[mask]].mean(axis=0)
    return [srgb(c) for c in linear]


CHANGED_MIN = 0.5


def measure(frames_dir, receipt):
    rows = []
    checks = []
    fails = []
    params = receipt["city_params"]
    series = "sun" if receipt.get("only_sun") else "as-is"
    for st in receipt["stations"]:
        fr = st["frames"]
        if not all(fr.get(k) for k in ("A", "B1", "label", "lit", "A2")):
            checks.append("%s_%s: missing frames %s" % (st["id"], st["hero"], fr))
            continue
        a, b1, a2 = (load(os.path.join(frames_dir, fr[k])) for k in ("A", "B1", "A2"))
        names, ids = decode(load(os.path.join(frames_dir, fr["label"])), receipt["labels"])
        lit = load(os.path.join(frames_dir, fr["lit"])).mean(axis=2) > 127
        labelled = ids >= 0
        diff_a2 = np.abs(a.astype(np.int16) - a2).max(axis=2)
        diff_b1 = np.abs(a.astype(np.int16) - b1).max(axis=2)
        checks.append("[%s] %s_%s: A vs A2 differing px %d (max %d), in labelled %d | A vs B1 changed px %.1f %% of frame, "
                      "%.1f %% of labelled | labelled %.1f %% (lit %.1f %%)" % (
                          series, st["id"], st["hero"], int((diff_a2 > 0).sum()), int(diff_a2.max()),
                          int((diff_a2[labelled] > 0).sum()), 100 * (diff_b1 > 0).mean(),
                          100 * (diff_b1[labelled] > 0).mean() if labelled.any() else 0.0,
                          100 * labelled.mean(), 100 * (labelled & lit).mean()))
        if (diff_a2 > 0).any():
            fails.append("%s_%s: A2 differs from A in %d px" % (st["id"], st["hero"], int((diff_a2 > 0).sum())))
        for family in ("city:", "hero:"):
            fam = np.isin(ids, [i for i, n in enumerate(names) if n.startswith(family)])
            if family == "hero:":
                fam &= lit
            if fam.sum() >= MIN_PX:
                share = float((diff_b1[fam] > 0).mean())
                checks.append("[%s] %s_%s: %s labelled px %d, changed A->B1 %.1f %%" % (
                    series, st["id"], st["hero"], family[:-1], int(fam.sum()), 100 * share))
                if share < CHANGED_MIN:
                    fails.append("%s_%s: %s pixels changed A->B1 only %.1f %% (< %d %%)" % (
                        st["id"], st["hero"], family[:-1], 100 * share, 100 * CHANGED_MIN))
        stable = diff_a2 == 0
        for index, name in enumerate(names):
            for band, band_mask in (("lit", lit), ("shadow", ~lit)):
                mask = (ids == index) & band_mask & stable
                n = int(mask.sum())
                if n < MIN_PX:
                    continue
                ma, mb = mean_srgb(a, mask), mean_srgb(b1, mask)
                row = {"series": series, "hero": st["hero"], "station": st["id"], "label": name, "band": band, "px": n,
                       "share": n / mask.size, "A": rgb_hex(ma), "B1": rgb_hex(mb), "dE_A_B1": de76(ma, mb),
                       "L_A": lab(ma)[0], "L_B1": lab(mb)[0], "_A": ma, "_B1": mb}
                if name in params:
                    cp = params[name]
                    key = cp["key"]
                    pal = hex_rgb(cp["hex"])
                    f = formula(cp["hex"], cp["fill"], cp["gain"], cp["glow"])
                    row.update({"palette": cp["hex"], "fill": cp["fill"], "gain": cp["gain"], "glow": cp["glow"], "dE_A": de76(ma, pal), "dE_B1": de76(mb, pal),
                                "FA": rgb_hex(f[("F+", "A", band)]), "FB1": rgb_hex(f[("F+", "B1", band)]),
                                "dE_FA": de76(f[("F+", "A", band)], pal), "dE_FB1": de76(f[("F+", "B1", band)], pal),
                                "CA": rgb_hex(f[("Compat", "A", band)]), "CB1": rgb_hex(f[("Compat", "B1", band)]),
                                "dE_meas_CA": de76(ma, f[("Compat", "A", band)]),
                                "dE_meas_CB1": de76(mb, f[("Compat", "B1", band)]), "flat": key in FLAT_KINDS})
                rows.append(row)
    return rows, checks, fails


def pooled(rows, params, series):
    out = []
    for name in sorted(params):
        cp = params[name]
        key = name[5:]
        for band in ("lit", "shadow"):
            sel = [r for r in rows if r["label"] == name and r["band"] == band and r["hero"] == "choko"
                   and r["series"] == series]
            if not sel:
                continue
            n = sum(r["px"] for r in sel)
            # pixel-weighted mean in linear light over the stations
            ma = [srgb(sum(lin(r["_A"][c]) * r["px"] for r in sel) / n) for c in range(3)]
            mb = [srgb(sum(lin(r["_B1"][c]) * r["px"] for r in sel) / n) for c in range(3)]
            pal = hex_rgb(cp["hex"])
            f = formula(cp["hex"], cp["fill"], cp["gain"], cp["glow"])
            out.append({"series": series, "key": key, "band": band, "px": n, "stations": ",".join(r["station"] for r in sel),
                        "palette": cp["hex"], "A": rgb_hex(ma), "B1": rgb_hex(mb), "dE_A": de76(ma, pal),
                        "dE_B1": de76(mb, pal), "FA": rgb_hex(f[("F+", "A", band)]),
                        "FB1": rgb_hex(f[("F+", "B1", band)]), "dE_FA": de76(f[("F+", "A", band)], pal),
                        "dE_FB1": de76(f[("F+", "B1", band)], pal), "CA": rgb_hex(f[("Compat", "A", band)]),
                        "dE_meas_CA": de76(ma, f[("Compat", "A", band)]), "flat": cp["key"] in FLAT_KINDS})
    return out


def write_tsv(path, rows, cols):
    with open(path, "w", encoding="utf-8") as fh:
        fh.write("\t".join(cols) + "\n")
        for r in rows:
            cells = []
            for c in cols:
                v = r.get(c, "")
                if isinstance(v, float):
                    v = "%.4f" % v if c == "share" else "%.2f" % v if c in ("fill", "gain", "glow") else "%.1f" % v
                cells.append(str(v))
            fh.write("\t".join(cells) + "\n")


def font(size):
    for path in ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/System/Library/Fonts/Supplemental/Arial.ttf"):
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def sheets(receipts, out_dir, prefix, max_kb, half_w, sun_stations):
    groups = {}
    for frames_dir, receipt in receipts:
        for st in receipt["stations"]:
            if not receipt.get("only_sun"):
                groups.setdefault(st["sheet"], []).append((frames_dir, st))
            elif st["id"] in sun_stations and st["hero"] == "choko":
                groups.setdefault("sun", []).append((frames_dir, st))
    made = []
    head = font(22)
    small = font(17)
    for group, stations in groups.items():
        half_h = None
        tiles = []
        for frames_dir, st in stations:
            a = Image.open(os.path.join(frames_dir, st["frames"]["A"])).convert("RGB")
            b = Image.open(os.path.join(frames_dir, st["frames"]["B1"])).convert("RGB")
            half_h = round(a.height * half_w / a.width)
            tiles.append((st, a.resize((half_w, half_h), Image.LANCZOS), b.resize((half_w, half_h), Image.LANCZOS)))
        bar = 34
        top = 40
        sheet = Image.new("RGB", (2 * half_w, top + len(tiles) * (bar + half_h)), (24, 22, 28))
        draw = ImageDraw.Draw(sheet)
        if group == "sun":
            note = "ДІАГНОСТИКА --only-sun: лампи крамниць сховані, у продукті вони є. Compatibility / llvmpipe, не M3"
        else:
            note = "Compatibility / llvmpipe, 1920×1080 → %d px, той самий кадр, сонце й пауза; не M3 / не Forward+" % half_w
        draw.text((10, 8), note, fill=(230, 226, 214), font=small)
        y = top
        for st, a, b in tiles:
            name = "%s · %s%s" % (TITLES.get(st["id"], st["id"]), st["hero"].capitalize(),
                                  " · лише сонце" if group == "sun" else "")
            draw.text((10, y + 5), "А — як є (%s)" % name, fill=(240, 236, 220), font=head)
            draw.text((half_w + 10, y + 5), "Б1 — без ALBEDO у light() (%s)" % name, fill=(240, 236, 220), font=head)
            y += bar
            sheet.paste(a, (0, y))
            sheet.paste(b, (half_w, y))
            draw.line([(half_w, y), (half_w, y + half_h)], fill=(255, 255, 255), width=2)
            y += half_h
        path = os.path.join(out_dir, "%s-%s.jpg" % (prefix, group))
        for quality in range(88, 40, -4):
            sheet.save(path, "JPEG", quality=quality, optimize=True, progressive=True)
            if os.path.getsize(path) <= max_kb * 1024:
                break
        made.append("%s %dx%d q%d %d B" % (path, sheet.width, sheet.height, quality, os.path.getsize(path)))
    return made


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("frames", nargs="+")
    ap.add_argument("--out", help="where the TSVs go (default: the first FRAMES_DIR)")
    ap.add_argument("--sheets")
    ap.add_argument("--prefix", default="2026-10-14-albedo-ab")
    ap.add_argument("--max-kb", type=int, default=300)
    ap.add_argument("--half-width", type=int, default=800)
    ap.add_argument("--sun-sheet", default="market,benches", help="stations of the diagnostic only-sun sheet")
    args = ap.parse_args()
    receipts = []
    for frames_dir in args.frames:
        for name in sorted(os.listdir(frames_dir)):
            if name.startswith("receipt_") and name.endswith(".json"):
                with open(os.path.join(frames_dir, name), encoding="utf-8") as fh:
                    receipts.append((frames_dir, json.load(fh)))
    if not receipts:
        print("no receipt_*.json in %s" % args.frames)
        return 2
    out = args.out or args.frames[0]
    os.makedirs(out, exist_ok=True)
    rows, checks, fails = [], [], []
    for frames_dir, receipt in receipts:
        r, c, f = measure(frames_dir, receipt)
        rows += r
        fails += f
        checks += ["renderer=%s adapter=%s hero=%s only_sun=%s hidden_lights=%d swap=%s census=%s" % (
            receipt["renderer"], receipt["adapter"], receipt["hero"], receipt.get("only_sun", False),
            len(receipt.get("hidden_lights", [])), receipt["swap_albedo_tokens"],
            receipt["census"])] + c
    cols = ["series", "hero", "station", "label", "band", "px", "share", "palette", "fill", "gain", "glow", "A", "B1", "dE_A", "dE_B1", "FA", "FB1",
            "dE_FA", "dE_FB1", "CA", "CB1", "dE_meas_CA", "dE_meas_CB1", "dE_A_B1", "L_A", "L_B1", "flat"]
    write_tsv(os.path.join(out, "ab_table.tsv"), rows, cols)
    params = {}
    for _, receipt in receipts:
        params.update(receipt["city_params"])
    summary = pooled(rows, params, "as-is") + pooled(rows, params, "sun")
    write_tsv(os.path.join(out, "ab_summary.tsv"), summary,
              ["series", "key", "band", "px", "stations", "palette", "A", "B1", "dE_A", "dE_B1", "FA", "FB1", "dE_FA", "dE_FB1",
               "CA", "dE_meas_CA", "flat"])
    with open(os.path.join(out, "ab_checks.txt"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(checks) + "\n")
    print("\n".join(checks))
    for line in fails:
        print("ALBEDO_AB_INTEGRITY FAIL " + line)
    print("ALBEDO_AB_TABLE rows=%d summary=%d integrity_failures=%d" % (len(rows), len(summary), len(fails)))
    if args.sheets:
        for line in sheets(receipts, args.sheets, args.prefix, args.max_kb, args.half_width,
                           [x for x in args.sun_sheet.split(",") if x]):
            print("ALBEDO_AB_SHEET " + line)
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
