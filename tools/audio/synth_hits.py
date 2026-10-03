#!/usr/bin/env python3
"""Re-layered synthetic hit SFX (plan 2026-10-03, step 1.3) — stdlib only, deterministic.

Each impact is the 4-layer recipe from docs/GDD/07-Audio.md, summed within 1-2 ms:
  transient (metal 2-6 kHz, 20-40 ms) + body (100-400 Hz, 80-150 ms) + sub (40-70 Hz, 100-200 ms)
  (+ the "whoosh" layer is its own file, fired at the start of active frames).
Mastering: feed-forward compressor (attack 1 ms, ratio 4:1, -24 dB) -> tanh soft clip -> peak
normalise to -1 dBFS (the offline equivalent of a brickwall limiter).
Variants: <name>.wav is variant 1, <name>_2.wav, <name>_3.wav ... (Sfx.gd builds an
AudioStreamRandomizer from them). Seeds are fixed, so a rerun reproduces the same bytes.

Run:  python3 tools/audio/synth_hits.py [--out game/assets/audio/sfx] [--only hit_light,...]
"""
from __future__ import annotations

import argparse
import math
import random
import struct
import wave
from pathlib import Path

SR = 44100
ROOT = Path(__file__).resolve().parents[2]


# --- primitives ---------------------------------------------------------------------------
def env(n: int, attack_s: float, decay_s: float) -> list[float]:
    a = max(1, int(attack_s * SR))
    out = []
    for i in range(n):
        if i < a:
            out.append(i / a)
        else:
            out.append(math.exp(-(i - a) / (decay_s * SR)))
    return out


def noise(n: int, rng: random.Random) -> list[float]:
    return [rng.uniform(-1.0, 1.0) for _ in range(n)]


def svf(x: list[float], f0, q: float, mode: str = "band") -> list[float]:
    """Chamberlin state-variable filter; f0 is a float or a per-sample callable."""
    low = band = 0.0
    out = []
    damp = 1.0 / q
    for i, s in enumerate(x):
        fc = f0(i) if callable(f0) else f0
        f = 2.0 * math.sin(math.pi * min(fc, SR / 6.0) / SR)
        low += f * band
        high = s - low - damp * band
        band += f * high
        out.append(band if mode == "band" else low if mode == "low" else high)
    return out


def sweep_sine(n: int, f_start: float, f_end: float, phase: float = 0.0) -> list[float]:
    out = []
    ph = phase
    for i in range(n):
        t = i / max(1, n - 1)
        f = f_start * (f_end / f_start) ** t
        ph += 2.0 * math.pi * f / SR
        out.append(math.sin(ph))
    return out


def mul(a: list[float], b: list[float]) -> list[float]:
    return [x * y for x, y in zip(a, b)]


def mix(length: int, *layers: tuple[list[float], float, float]) -> list[float]:
    """layers: (signal, gain, offset_seconds)."""
    out = [0.0] * length
    for sig, gain, off in layers:
        o = int(off * SR)
        for i, s in enumerate(sig):
            j = i + o
            if 0 <= j < length:
                out[j] += s * gain
    return out


def compress(x: list[float], thresh_db: float = -18.0, ratio: float = 4.0,
             attack_s: float = 0.001, release_s: float = 0.06) -> list[float]:
    ga = math.exp(-1.0 / (attack_s * SR))
    gr = math.exp(-1.0 / (release_s * SR))
    lvl = 0.0
    out = []
    for s in x:
        a = abs(s)
        c = ga if a > lvl else gr
        lvl = c * lvl + (1.0 - c) * a
        db = 20.0 * math.log10(max(lvl, 1e-9))
        over = db - thresh_db
        gain_db = -over * (1.0 - 1.0 / ratio) if over > 0 else 0.0
        out.append(s * 10.0 ** (gain_db / 20.0))
    return out


def master(x: list[float], peak_db: float = -1.0, fade_s: float = 0.004, drive: float = 2.5) -> list[float]:
    x = compress(x, thresh_db=-24.0)
    pk = max(1e-9, max(abs(s) for s in x))
    t = math.tanh(drive)
    x = [math.tanh(drive * s / pk) / t for s in x]   # soft clip: body up, transient peak tamed
    n = len(x)
    f = int(fade_s * SR)
    for i in range(min(f, n)):
        x[n - 1 - i] *= i / f
    pk = max(1e-9, max(abs(s) for s in x))
    g = 10.0 ** (peak_db / 20.0) / pk
    return [s * g for s in x]


def write_wav(path: Path, x: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in x))


# --- layers -------------------------------------------------------------------------------
def transient(rng: random.Random, dur: float, bright: float) -> list[float]:
    n = int(dur * SR)
    nz = svf(noise(n, rng), 3800.0 * bright, 1.4, "band")
    ring = [0.0] * n
    for f in (2300.0, 3700.0, 5100.0):
        fr = f * bright * rng.uniform(0.94, 1.06)
        s = sweep_sine(n, fr, fr * 0.98, rng.uniform(0, 6.28))
        ring = [a + b * 0.35 for a, b in zip(ring, s)]
    e = env(n, 0.0004, dur / 4.0)
    return mul([a * 1.6 + b for a, b in zip(nz, ring)], e)


def body(rng: random.Random, dur: float, f_hi: float, f_lo: float, crunch: float) -> list[float]:
    n = int(dur * SR)
    tone = sweep_sine(n, f_hi, f_lo, rng.uniform(0, 6.28))
    thud = svf(noise(n, rng), 260.0, 0.9, "low")
    crack = svf(noise(n, rng), 1400.0, 1.0, "band")
    e = env(n, 0.0015, dur / 3.2)
    ec = env(n, 0.0005, 0.012)
    sig = [math.tanh(2.2 * (t * 0.7 + d * 1.8)) for t, d in zip(tone, thud)]
    return [s * a + c * b * crunch for s, a, c, b in zip(sig, e, crack, ec)]


def sub(rng: random.Random, dur: float, f0: float) -> list[float]:
    n = int(dur * SR)
    return mul(sweep_sine(n, f0 * 1.25, f0 * 0.85, 0.0), env(n, 0.003, dur / 2.8))


def whoosh(rng: random.Random, dur: float, f_from: float, f_to: float) -> list[float]:
    n = int(dur * SR)
    centre = lambda i: f_from * (f_to / f_from) ** (i / n)
    sig = svf(noise(n, rng), centre, 2.2, "band")
    # swell then cut: the air moves fastest just before contact
    e = [math.sin(math.pi * min(1.0, (i / n) / 0.85)) ** 2 if i / n < 0.85 else
         math.exp(-((i / n) - 0.85) * 40.0) for i in range(n)]
    return mul(sig, e)


# --- recipes ------------------------------------------------------------------------------
def r_hit_light(rng):
    L = 0.16
    return mix(int(L * SR), (transient(rng, 0.03, rng.uniform(0.9, 1.1)), 0.55, 0.0),
               (body(rng, 0.10, rng.uniform(320, 380), 140, 0.6), 1.0, 0.0008),
               (sub(rng, 0.11, rng.uniform(62, 70)), 1.1, 0.001))


def r_hit_heavy(rng):
    L = 0.34
    return mix(int(L * SR), (transient(rng, 0.04, rng.uniform(0.75, 0.9)), 0.6, 0.0),
               (body(rng, 0.15, rng.uniform(220, 260), 95, 1.0), 1.0, 0.001),
               (sub(rng, 0.2, rng.uniform(44, 52)), 1.4, 0.0015))


def r_block(rng):
    L = 0.14
    return mix(int(L * SR), (transient(rng, 0.04, rng.uniform(1.05, 1.2)), 1.0, 0.0),
               (body(rng, 0.07, 420, 260, 0.2), 0.35, 0.001))


def r_whoosh(rng):
    return whoosh(rng, rng.uniform(0.2, 0.26), rng.uniform(500, 700), rng.uniform(2600, 3400))


def r_kunai(rng):
    L = 0.14
    return mix(int(L * SR), (transient(rng, 0.025, rng.uniform(1.15, 1.3)), 0.9, 0.0),
               (body(rng, 0.06, 420, 200, 0.8), 0.5, 0.001),
               (sub(rng, 0.08, 70), 0.6, 0.001))


def r_sword(rng):
    L = 0.32
    sw = whoosh(rng, 0.16, 900, 3800)
    return mix(int(L * SR), (sw, 0.7, 0.0), (transient(rng, 0.05, 0.95), 0.8, 0.15),
               (body(rng, 0.12, 300, 120, 0.7), 0.8, 0.151), (sub(rng, 0.14, 55), 0.6, 0.152))


def r_crit(rng):
    L = 0.42
    return mix(int(L * SR), (transient(rng, 0.06, 1.25), 0.9, 0.0),
               (transient(rng, 0.05, 0.8), 0.5, 0.012),
               (body(rng, 0.18, 260, 80, 1.2), 1.0, 0.001), (sub(rng, 0.26, 42), 1.0, 0.002))


# name -> (recipe, variants, peak dBFS, seed)
RECIPES = {
    "hit_light": (r_hit_light, 3, -1.0, 11),
    "hit_heavy": (r_hit_heavy, 3, -1.0, 23),
    "block": (r_block, 3, -1.0, 37),
    "whoosh": (r_whoosh, 3, -6.0, 41),
    "kunai": (r_kunai, 2, -1.0, 53),
    "sword": (r_sword, 2, -1.0, 67),
    "crit": (r_crit, 1, -1.0, 79),
}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(ROOT / "game/assets/audio/sfx"))
    ap.add_argument("--only", default="")
    a = ap.parse_args()
    only = {s for s in a.only.split(",") if s}
    for name, (fn, variants, peak, seed) in RECIPES.items():
        if only and name not in only:
            continue
        rng = random.Random(seed)
        for v in range(1, variants + 1):
            x = master(fn(rng), peak, drive=1.2 if name == "whoosh" else 2.5)
            fname = f"{name}.wav" if v == 1 else f"{name}_{v}.wav"
            write_wav(Path(a.out) / fname, x)
            print(f"{fname}  {len(x) / SR:.3f} s")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
