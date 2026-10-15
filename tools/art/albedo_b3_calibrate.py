#!/usr/bin/env python3
"""Variant B3 of the albedo A/B (Santos 2026-10-15 «Зняти Б3»): B1 (no ALBEDO inside light()) plus light strengths
re-calibrated in the same five shaders, so that on Forward+ (M3 = Forward+ on Metal) both bands land on the palette.

    python3 -I tools/art/albedo_b3_calibrate.py [--json OUT.json] [--tsv OUT.tsv]

Reads the inputs from the repository (nothing typed twice), prints the B3 constants and the per-key table, rc 0;
rc 2 when an input is not found where this script expects it.

Targets (what «на палітрі» means for each band):
  lit    = the palette hex itself (CityMaterials.palette(), read as a screen sRGB colour);
  shadow = the palette hex × the style guide's shadow multiplier #B07AA6, channel by channel on sRGB values
           (docs/Art/Style-Guide.md «Тінь (множник) #B07AA6»; its own worked example: K1 #A3243B × #B07AA6 = #711126).
  The palette hex as the shadow target as well (the metric of the A/B table, docs/Fix/2026-10-14-Albedo-AB-Fix.md) is
  degenerate: in every B form the shadow is the lit colour times a factor, so both bands hit the hex only when that
  factor is 1 — no shadow at all. That metric is still printed (column dE_hex) so the numbers sit next to the A/B ones.

Forward+ formula (docs/Research/2026-10-14-Godot-Diffuse-Albedo.md: uniforms linearised on the CPU, LIGHT_COLOR =
lin(colour) * energy * PI, the engine multiplies DIFFUSE_LIGHT and ambient by ALBEDO once after light(), EMISSION is
added linear; tonemap Linear; flat palette colour, no surface pattern, one sun). A = lin(palette), L = lin(sun) * energy:
  city_surface (ambient off)   A : A(f+g) + A^2 Sb L k        B1: A(f+g) + A Sb L k
                               B3: A(f*FS + g) + A Sb3 L k*KS  Sb = 1 lit | 0.50*0.65 + 0.35*lin(T) shadow (shader :119)
                                   Sb3 = 1 lit | b(1-m) + m*lin(T) shadow
  toon / sword_dissolve /      A : A amb + A^2 sh L PI        B1: A amb + A sh L PI
  hero_garment / gear_surface  B3: A amb + A sh3 L HG          (B3 multiplies each DIFFUSE_LIGHT line by HG / PI)
                               sh = 1 lit | mix(T, 1, 1 - ss) shadow band (a = 0) | Tc * 0.75 cloth/gear shadow
                               sh3 = 1 lit | mix(T, 1, 1 - ss*SS) | Tc * CS
  amb = lin(ambient colour) * energy (RD render_scene_data_rd.cpp:185-189); a cast shadow (ATTENUATION 0) leaves
  only A amb in every variant, so B3 cannot move it.
Compatibility model (for the frame columns of albedo_ab_table.py; never calibrated against): A = s2l_poly(p),
EMISSION read as sRGB, uniforms in light() raw sRGB (T), output l2s_poly (gles3 tonemap_inc.glsl:14-25).

Calibration: minimise the median dE76 over the district's palette keys, lit and shadow separately. For city_surface
the two share f*FS and k*KS, so the search minimises median_lit + median_shadow over (FS, KS, b, m) on a grid and then
refines it; for the hero shaders HG minimises the lit median alone (sh3 = 1 there), then SS / CS the shadow median.
The hero shaders have no palette (atlas textures); the district keys serve as test albedos — in a B form the screen
colour is the albedo times a factor, so the fit hardly depends on which colours test it.
All results are PLACEHOLDER (artistic), rounded to 3 decimals.
"""
import argparse
import json
import math
import os
import re
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
STYLE_SHADOW = "b07aa6"  # docs/Art/Style-Guide.md, «Тінь (множник)»
INK = [0x2b / 255, 0x22 / 255, 0x30 / 255]  # the line colour #2B2230 (Style-Guide.md «Лінія»): a shadow must not merge with it
ROUND = 3


def read(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as fh:
        return fh.read()


def need(pattern, text, what, flags=0):
    found = re.search(pattern, text, flags)
    if not found:
        print("ALBEDO_B3_CALIBRATE missing input: %s (/%s/)" % (what, pattern))
        sys.exit(2)
    return found


def lin(c):
    return c / 12.92 if c < 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def srgb(x):
    x = max(0.0, min(1.0, x))
    return 12.92 * x if x < 0.0031308 else 1.055 * x ** (1 / 2.4) - 0.055


def poly(c):  # gles3 tonemap_inc.glsl:22-25
    return c * (c * (c * 0.305306011 + 0.682171111) + 0.012522878)


def srgb_a(x):  # gles3 tonemap_inc.glsl:14-19
    return max(1.055 * max(x, 0.0) ** 0.416666667 - 0.055, 0.0)


def hex_rgb(h):
    h = h.lstrip("#")
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
    return math.dist(lab(a), lab(b))


def lab_np(rgb):
    """lab() for an (n, 3) array of sRGB colours (same constants)."""
    c = np.asarray(rgb, dtype=np.float64)
    li = np.where(c < 0.04045, c / 12.92, np.power((c + 0.055) / 1.055, 2.4))
    x = (0.4124564 * li[:, 0] + 0.3575761 * li[:, 1] + 0.1804375 * li[:, 2]) / 0.95047
    y = 0.2126729 * li[:, 0] + 0.7151522 * li[:, 1] + 0.0721750 * li[:, 2]
    z = (0.0193339 * li[:, 0] + 0.1191920 * li[:, 1] + 0.9503041 * li[:, 2]) / 1.08883
    t = np.stack([x, y, z], axis=1)
    f = np.where(t > 216 / 24389, np.cbrt(t), (24389 / 27 * t + 16) / 116)
    return np.stack([116 * f[:, 1] - 16, 500 * (f[:, 0] - f[:, 1]), 200 * (f[:, 1] - f[:, 2])], axis=1)


def shadow_target(hexcode):
    """The style guide's shadow: sRGB channel product with #B07AA6, rounded like its worked example (#711126)."""
    p = [int(hexcode[i:i + 2], 16) for i in (0, 2, 4)]
    t = [int(STYLE_SHADOW[i:i + 2], 16) for i in (0, 2, 4)]
    return [math.floor(a * b / 255 + 0.5) / 255 for a, b in zip(p, t)]


def inputs():
    """Every number the formula uses, with where it was read."""
    mats = read("game/scripts/world/CityMaterials.gd")
    palette = {}
    for key, hexcode in re.findall(r'result\["(\w+)"\]\s*=\s*_material\("([0-9a-fA-F]{6})"', mats):
        palette[key] = hexcode.lower()
    if len(palette) < 10:
        need(r"^$", "", "CityMaterials.palette() keys")
    glow = {key: float(v) for key, v in re.findall(r'result\["(\w+)"\]\.set_shader_parameter\("glow",\s*([0-9.]+)\)', mats)}
    tint = need(r'"shadow_tint",\s*Color\("([0-9a-fA-F]{6})"\)', mats, "CityMaterials shadow_tint").group(1).lower()
    city = read("game/shaders/city_surface.gdshader")
    fill = float(need(r"uniform float painted_fill[^=]*=\s*([0-9.]+)", city, "painted_fill default").group(1))
    gain = float(need(r"uniform float key_gain[^=]*=\s*([0-9.]+)", city, "key_gain default").group(1))
    mix_found = need(r"mix\(vec3\(([0-9.]+)\),\s*shadow_tint\.rgb,\s*([0-9.]+)\)", city, "city shadow mix")
    base, share = float(mix_found.group(1)), float(mix_found.group(2))
    world = read("game/scripts/world/CityWorld.gd")
    sun = [float(v) for v in need(r"sun\.light_color\s*=\s*Color\(([0-9.]+),\s*([0-9.]+),\s*([0-9.]+)\)", world, "sun colour").groups()]
    energy = float(need(r"sun\.light_energy\s*=\s*([0-9.]+)", world, "sun energy").group(1))
    ambient = [float(v) for v in need(r"ambient_light_color\s*=\s*Color\(([0-9.]+),\s*([0-9.]+),\s*([0-9.]+)\)", world, "ambient colour").groups()]
    ambient_energy = float(need(r"ambient_light_energy\s*=\s*([0-9.]+)", world, "ambient energy").group(1))
    variants = {"district": (fill, gain)}
    for name, rel in (("interiors", "game/scripts/world/CityInteriors.gd"), ("backdrop", "game/scripts/world/CityBackdrop.gd")):
        text = read(rel)
        f = float(need(r'"painted_fill",\s*([0-9.]+)', text, name + " painted_fill").group(1))
        k = float(need(r'"key_gain",\s*([0-9.]+)', text, name + " key_gain").group(1))
        variants[name] = (f, k)
    toon = read("game/shaders/toon.gdshader")
    ss = float(need(r"uniform float shadow_strength[^=]*=\s*([0-9.]+)", toon, "toon shadow_strength").group(1))
    hero_tint = [float(v) for v in need(r"uniform vec4 shadow_tint[^=]*=\s*vec4\(([0-9.]+),\s*([0-9.]+),\s*([0-9.]+)", toon, "toon shadow_tint default").groups()]
    npc = read("game/scripts/npc/NpcAppearance.gd")
    npc_tint = need(r'"shadow_tint",\s*Color\("([0-9a-fA-F]{6})"\)', npc, "NPC shadow_tint").group(1).lower()
    sword = read("game/scripts/fighter/SwordPresentation.gd")
    sword_tint = need(r'"shadow_tint",\s*Color\("([0-9a-fA-F]{6})"\)', sword, "sword shadow_tint").group(1).lower()
    gear = read("game/shaders/gear_surface.gdshader")
    cloth = need(r"ALBEDO \* vec3\(([0-9.]+),([0-9.]+),([0-9.]+)\) \* ([0-9.]+);", gear, "gear shadow constant")
    garment = read("game/shaders/hero_garment.gdshader")
    need(r"ALBEDO \* vec3\(0\.69,0\.48,0\.65\) \* 0\.75", garment, "hero_garment cloth shadow constant")
    return {
        "palette": palette, "glow": glow, "tint": tint, "fill": fill, "gain": gain, "mix_base": base, "mix_share": share,
        "sun": sun, "energy": energy, "ambient": ambient, "ambient_energy": ambient_energy, "variants": variants,
        "shadow_strength": ss, "hero_tint_default": hero_tint, "npc_tint": npc_tint, "sword_tint": sword_tint,
        "cloth_tint": [float(cloth.group(i)) for i in (1, 2, 3)], "cloth_share": float(cloth.group(4)),
        "sources": {
            "palette": "game/scripts/world/CityMaterials.gd:9-31", "tint": "CityMaterials.gd:39",
            "fill/gain/mix": "game/shaders/city_surface.gdshader:17-18,119", "sun/ambient": "game/scripts/world/CityWorld.gd",
            "interiors": "game/scripts/world/CityInteriors.gd", "backdrop": "game/scripts/world/CityBackdrop.gd",
            "hero": "game/shaders/toon.gdshader:11-12, NpcAppearance.gd, SwordPresentation.gd, gear_surface.gdshader:56",
            "style shadow": "docs/Art/Style-Guide.md «Тінь (множник) #B07AA6»"},
    }


class Model:
    def __init__(self, inp):
        self.inp = inp
        self.L = np.array([lin(c) for c in inp["sun"]]) * inp["energy"]
        self.Lc = self.L  # Compatibility converts the light colour on the CPU too (rasterizer_scene_gles3.cpp:1763)
        self.amb = np.array([lin(c) for c in inp["ambient"]]) * inp["ambient_energy"]
        self.t_lin = np.array([lin(c) for c in hex_rgb(inp["tint"])])
        self.t_raw = np.array(hex_rgb(inp["tint"]))
        self.keys = sorted(inp["palette"])
        self.P = np.array([hex_rgb(inp["palette"][k]) for k in self.keys])            # sRGB
        self.A = np.vectorize(lin)(self.P)                                             # linear (Forward+)
        self.G = np.array([inp["glow"].get(k, 0.0) for k in self.keys])[:, None]
        self.target = {"lit": self.P, "shadow": np.array([shadow_target(inp["palette"][k]) for k in self.keys])}
        self.lab_target = {band: lab_np(self.target[band]) for band in self.target}
        self.lab_hex = lab_np(self.P)

    # ---- city_surface, Forward+ -------------------------------------------------------------------------------
    def city_fplus(self, variant, band, f, k, b=None, m=None, FS=1.0, KS=1.0):
        A, G, L = self.A, self.G, self.L
        if variant == "A":
            sb = 1.0 if band == "lit" else self.inp["mix_base"] * (1 - self.inp["mix_share"]) + self.inp["mix_share"] * self.t_lin
            return A * (f + G) + A * A * sb * L * k
        if variant == "B1":
            sb = 1.0 if band == "lit" else self.inp["mix_base"] * (1 - self.inp["mix_share"]) + self.inp["mix_share"] * self.t_lin
            return A * (f + G) + A * sb * L * k
        sb = 1.0 if band == "lit" else b * (1 - m) + m * self.t_lin
        return A * (f * FS + G) + A * sb * L * k * KS

    def city_compat(self, variant, band, f, k, b=None, m=None, FS=1.0, KS=1.0):
        P, G = self.P, self.G
        a = np.vectorize(poly)(P)
        if variant == "B3":
            e = np.vectorize(poly)(P * (f * FS + G))
            sb = 1.0 if band == "lit" else b * (1 - m) + m * self.t_raw
            return np.minimum(1.0, e + a * sb * self.Lc * k * KS)
        e = np.vectorize(poly)(P * (f + G))
        sb = 1.0 if band == "lit" else self.inp["mix_base"] * (1 - self.inp["mix_share"]) + self.inp["mix_share"] * self.t_raw
        if variant == "A":
            return np.minimum(1.0, e + a * a * sb * self.Lc * k)
        return np.minimum(1.0, e + a * sb * self.Lc * k)

    # ---- hero shaders, Forward+ -----------------------------------------------------------------------------------
    def hero_fplus(self, variant, shade, HG=1.0):
        A, L = self.A, self.L
        if variant == "A":
            return A * self.amb + A * A * shade * L * math.pi
        if variant == "B1":
            return A * self.amb + A * shade * L * math.pi
        return A * self.amb + A * shade * L * HG

    # ---- dE ---------------------------------------------------------------------------------------------------------
    @staticmethod
    def to_srgb(lin_rgb):
        x = np.clip(np.asarray(lin_rgb, dtype=np.float64), 0.0, 1.0)
        return np.where(x < 0.0031308, 12.92 * x, 1.055 * np.power(x, 1 / 2.4) - 0.055)

    def de(self, srgb_rgb, band, hexmetric=False):
        ref = self.lab_hex if hexmetric else self.lab_target[band]
        return np.sqrt(((lab_np(srgb_rgb) - ref) ** 2).sum(axis=1))


def median(v):
    return float(np.median(v))


def calibrate_city(model):
    f0, k0 = model.inp["variants"]["district"]

    def cost(FS, KS, b, m):
        lit = model.de(model.to_srgb(model.city_fplus("B3", "lit", f0, k0, b, m, FS, KS)), "lit")
        sh = model.de(model.to_srgb(model.city_fplus("B3", "shadow", f0, k0, b, m, FS, KS)), "shadow")
        return median(lit) + median(sh), median(lit), median(sh)

    best = None
    for FS in np.linspace(0.0, 2.5, 11):
        for KS in np.linspace(0.30, 0.70, 17):
            for b in np.linspace(0.0, 1.0, 6):
                for m in np.linspace(0.0, 1.0, 11):
                    c = cost(FS, KS, b, m)[0]
                    if best is None or c < best[0]:
                        best = (c, FS, KS, b, m)
    _, FS, KS, b, m = best
    lo = [0.0, 0.05, 0.0, 0.0]
    hi = [2.5, 1.50, 1.0, 1.0]
    x = [FS, KS, b, m]
    step = [0.125, 0.0125, 0.1, 0.05]
    for _ in range(60):  # coordinate descent with halving steps
        improved = False
        for i in range(4):
            for sign in (1, -1):
                y = list(x)
                y[i] = min(hi[i], max(lo[i], y[i] + sign * step[i]))
                if cost(*y)[0] < cost(*x)[0] - 1e-9:
                    x = y
                    improved = True
        if not improved:
            step = [s / 2 for s in step]
            if max(step) < 1e-4:
                break
    FS, KS, b, m = x
    # round the numbers the shader will carry, and report the cost of the rounded ones
    f_new, k_new = round(f0 * FS, ROUND), round(k0 * KS, ROUND)
    b, m = round(b, ROUND), round(m, ROUND)
    FS, KS = f_new / f0, k_new / k0
    total, lit_med, sh_med = cost(FS, KS, b, m)
    return {"painted_fill": f_new, "key_gain": k_new, "fill_scale": FS, "gain_scale": KS, "shadow_base": b,
            "shadow_share": m, "median_lit": lit_med, "median_shadow": sh_med, "cost": total}


def calibrate_hero(model):
    def lit_cost(HG):
        return median(model.de(model.to_srgb(model.hero_fplus("B3", 1.0, HG)), "lit"))

    HG = min(np.linspace(0.3, 2.0, 341), key=lit_cost)
    for step in (0.0025, 0.000625):
        HG = min(np.arange(HG - 8 * step, HG + 8 * step + 1e-12, step), key=lit_cost)
    HG = round(float(HG), ROUND)
    inp = model.inp
    ss = inp["shadow_strength"]
    tints = {
        "toon": ("NPC " + inp["npc_tint"], np.array([lin(c) for c in hex_rgb(inp["npc_tint"])])),
        "sword_dissolve": ("sword " + inp["sword_tint"], np.array([lin(c) for c in hex_rgb(inp["sword_tint"])])),
        "hero_garment": ("default %s" % inp["hero_tint_default"], np.array([lin(c) for c in inp["hero_tint_default"]])),
    }
    out = {"hero_gain": HG, "median_lit": lit_cost(HG), "shadow_strength": ss, "shaders": {}}
    for name, (label, tint) in tints.items():
        def sh_cost(SS, tint=tint):
            shade = tint * (ss * SS) + (1 - ss * SS)  # mix(T, 1, 1 - ss*SS)
            return median(model.de(model.to_srgb(model.hero_fplus("B3", shade, HG)), "shadow"))
        grid = np.linspace(0.0, 1.0 / ss, 401)
        SS = float(min(grid, key=sh_cost))
        new_ss = round(ss * SS, ROUND)
        SS = new_ss / ss
        a_shade = tint * ss + (1 - ss)
        out["shaders"][name] = {"tint": label, "shadow_scale": SS, "shadow_strength_new": new_ss,
                                "median_shadow": sh_cost(SS),
                                "median_shadow_A": median(model.de(model.to_srgb(model.hero_fplus("A", a_shade)), "shadow")),
                                "median_shadow_B1": median(model.de(model.to_srgb(model.hero_fplus("B1", a_shade)), "shadow"))}
    cloth = np.array(inp["cloth_tint"])  # shader literals: no colour conversion in any renderer

    def cloth_cost(CS):
        return median(model.de(model.to_srgb(model.hero_fplus("B3", cloth * CS, HG)), "shadow"))
    CS = round(float(min(np.linspace(0.0, 1.5, 601), key=cloth_cost)), ROUND)
    out["cloth"] = {"tint": inp["cloth_tint"], "share_old": inp["cloth_share"], "share_new": CS, "median_shadow": cloth_cost(CS),
                    "median_shadow_A": median(model.de(model.to_srgb(model.hero_fplus("A", cloth * inp["cloth_share"])), "shadow")),
                    "median_shadow_B1": median(model.de(model.to_srgb(model.hero_fplus("B1", cloth * inp["cloth_share"])), "shadow"))}
    out["median_lit_A"] = median(model.de(model.to_srgb(model.hero_fplus("A", 1.0)), "lit"))
    out["median_lit_B1"] = median(model.de(model.to_srgb(model.hero_fplus("B1", 1.0)), "lit"))
    out["cast_shadow"] = "A·amb in every variant, amb = %s (linear)" % ", ".join("%.3f" % v for v in model.amb)
    return out


def b3_constants():
    """The B3 constants albedo_ab_capture.gd must carry (its receipt is checked against these)."""
    model = Model(inputs())
    city = calibrate_city(model)
    hero = calibrate_hero(model)
    return model, city, hero


def city_rows(model, city):
    f0, k0 = model.inp["variants"]["district"]
    rows = []
    for band in ("lit", "shadow"):
        cols = {}
        for variant in ("A", "B1", "B3"):
            fp = model.to_srgb(model.city_fplus(variant, band, f0, k0, city["shadow_base"], city["shadow_share"],
                                                city["fill_scale"], city["gain_scale"]))
            cp = np.vectorize(srgb_a)(model.city_compat(variant, band, f0, k0, city["shadow_base"], city["shadow_share"],
                                                        city["fill_scale"], city["gain_scale"]))
            cols[variant] = (fp, model.de(fp, band), model.de(fp, band, True), cp, model.de(cp, band), model.de(cp, band, True))
        for i, key in enumerate(model.keys):
            row = {"key": key, "band": band, "palette": model.inp["palette"][key], "target": rgb_hex(model.target[band][i])}
            for variant in ("A", "B1", "B3"):
                fp, de_fp, hex_fp, cp, de_cp, hex_cp = cols[variant]
                row.update({"F_" + variant: rgb_hex(fp[i]), "dE_F_" + variant: de_fp[i], "dEhex_F_" + variant: hex_fp[i],
                            "C_" + variant: rgb_hex(cp[i]), "dE_C_" + variant: de_cp[i], "dEhex_C_" + variant: hex_cp[i],
                            "dEink_F_" + variant: de76(list(fp[i]), INK)})
            rows.append(row)
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--json")
    ap.add_argument("--tsv")
    args = ap.parse_args()
    model, city, hero = b3_constants()
    inp = model.inp
    f0, k0 = inp["variants"]["district"]
    print("ALBEDO_B3_INPUTS keys=%d sun=%s energy=%.2f L_lin=%s ambient_lin=%s tint=%s fill=%.2f gain=%.2f mix=(%.2f, %.2f) variants=%s" % (
        len(model.keys), inp["sun"], inp["energy"], np.round(model.L, 4).tolist(), np.round(model.amb, 4).tolist(), inp["tint"],
        f0, k0, inp["mix_base"], inp["mix_share"], inp["variants"]))
    print("ALBEDO_B3_CITY painted_fill %.2f -> %.3f (x%.4f) | key_gain %.2f -> %.3f (x%.4f) | shadow mix(vec3(%.2f), shadow_tint, %.2f) -> mix(vec3(%.3f), shadow_tint, %.3f) | median dE lit %.2f shadow %.2f" % (
        f0, city["painted_fill"], city["fill_scale"], k0, city["key_gain"], city["gain_scale"], inp["mix_base"], inp["mix_share"],
        city["shadow_base"], city["shadow_share"], city["median_lit"], city["median_shadow"]))
    for name, (f, k) in inp["variants"].items():
        print("ALBEDO_B3_CITY_VARIANT %s painted_fill %.2f -> %.3f key_gain %.2f -> %.3f" % (name, f, f * city["fill_scale"], k, k * city["gain_scale"]))
    print("ALBEDO_B3_HERO gain HG %.3f (B3 multiplies each DIFFUSE_LIGHT line by HG/PI; A and B1 carry PI) | median dE lit A %.2f B1 %.2f B3 %.2f" % (
        hero["hero_gain"], hero["median_lit_A"], hero["median_lit_B1"], hero["median_lit"]))
    for name, h in hero["shaders"].items():
        print("ALBEDO_B3_HERO_SHADOW %s (%s) shadow_strength %.2f -> %.3f (x%.4f) | median dE shadow A %.2f B1 %.2f B3 %.2f" % (
            name, h["tint"], hero["shadow_strength"], h["shadow_strength_new"], h["shadow_scale"], h["median_shadow_A"],
            h["median_shadow_B1"], h["median_shadow"]))
    c = hero["cloth"]
    print("ALBEDO_B3_HERO_CLOTH vec3(%s) * %.2f -> * %.3f | median dE shadow A %.2f B1 %.2f B3 %.2f" % (
        ",".join("%.2f" % v for v in c["tint"]), c["share_old"], c["share_new"], c["median_shadow_A"], c["median_shadow_B1"], c["median_shadow"]))
    print("ALBEDO_B3_HERO_CAST %s" % hero["cast_shadow"])
    rows = city_rows(model, city)
    for band in ("lit", "shadow"):
        sel = [r for r in rows if r["band"] == band]
        parts = []
        for variant in ("A", "B1", "B3"):
            parts.append("%s F+ %.1f (hex %.1f) Compat %.1f (hex %.1f)" % (
                variant, median([r["dE_F_" + variant] for r in sel]), median([r["dEhex_F_" + variant] for r in sel]),
                median([r["dE_C_" + variant] for r in sel]), median([r["dEhex_C_" + variant] for r in sel])))
        print("ALBEDO_B3_MEDIAN %s n=%d | %s" % (band, len(sel), " | ".join(parts)))
    for r in rows:
        if r["band"] == "shadow" and r["key"] in ("iron", "iron_paint", "ink", "glass", "slate", "wood"):
            print("ALBEDO_B3_INK %s shadow F+: A #%s dE_ink %.1f | B3 #%s dE_ink %.1f (target #%s)" % (
                r["key"], r["F_A"], r["dEink_F_A"], r["F_B3"], r["dEink_F_B3"], r["target"]))
    if args.tsv:
        cols = ["key", "band", "palette", "target"] + [p + v for v in ("A", "B1", "B3") for p in
                                                       ("F_", "dE_F_", "dEhex_F_", "C_", "dE_C_", "dEhex_C_", "dEink_F_")]
        with open(args.tsv, "w", encoding="utf-8") as fh:
            fh.write("\t".join(cols) + "\n")
            for r in rows:
                fh.write("\t".join(("%.1f" % r[c]) if isinstance(r[c], float) else str(r[c]) for c in cols) + "\n")
    if args.json:
        with open(args.json, "w", encoding="utf-8") as fh:
            json.dump({"city": city, "hero": hero, "inputs": {k: v for k, v in inp.items() if k != "palette"},
                       "palette": inp["palette"]}, fh, indent=1, default=float)
    return 0


if __name__ == "__main__":
    sys.exit(main())
