#!/usr/bin/env python3
"""Original provisional water SFX; no recordings, downloads, or dependencies.

Run normally to render; --check verifies existing WAVs against seeded synthesis.
All timbres and levels are design placeholders, not measured water acoustics.
"""
import argparse
import hashlib
import io
import json
import math
from pathlib import Path
import random
import struct
import wave

RATE = 48000
DEST = Path(__file__).resolve().parents[2] / "game/assets/audio/sfx"
# duration, peak dBFS, bubble count, noisy body decay, seed
RECIPES = {
    "water_step": (0.24, -12.0, 12, 0.043, 61001),
    "water_step_2": (0.27, -12.0, 15, 0.049, 61002),
    "water_land": (0.64, -6.0, 36, 0.105, 61101),
    "water_land_2": (0.59, -6.0, 32, 0.095, 61102),
    "water_dash": (0.39, -11.0, 21, 0.085, 61201),
    "water_dash_2": (0.42, -11.0, 24, 0.090, 61202),
    "water_skid": (0.29, -18.0, 10, 0.070, 61301),
    "water_skid_2": (0.32, -18.0, 13, 0.075, 61302),
}


def lowpass(samples, cutoff):
    alpha = 1.0 - math.exp(-math.tau * cutoff / RATE)
    state = 0.0
    result = []
    for sample in samples:
        state += alpha * (sample - state)
        result.append(state)
    return result


def synthesize(name, recipe):
    duration, peak_db, bubbles, decay, seed = recipe
    rng = random.Random(seed)
    count = round(duration * RATE)
    noise = [rng.uniform(-1.0, 1.0) for _ in range(count)]
    bright = lowpass(noise, rng.uniform(4000.0, 6800.0))
    dull = lowpass(bright, rng.uniform(550.0, 950.0))
    bass = lowpass(dull, 150.0)
    sound = []
    swish = "dash" in name or "skid" in name
    for i in range(count):
        t = i / RATE
        attack = 0.026 if swish else 0.0025
        envelope = (1.0 - math.exp(-t / attack)) * math.exp(-t / decay)
        # A noisy moving sheet of water, plus a lower displaced-water body.
        ripple = 0.80 + 0.20 * math.sin(math.tau * (19.0 * t + 12.0 * t * t))
        sound.append(((bright[i] - dull[i]) * ripple +
                      (dull[i] - bass[i]) * (2.2 if "land" in name else 1.3)) * envelope)
    for _ in range(bubbles):
        start = int(rng.uniform(0.006, duration * 0.68) * RATE)
        life = rng.uniform(0.010, 0.044)
        # Short rising, damped resonances suggest contracting air bubbles.
        # Random onset/frequency/lifetime avoids a fixed musical ringing loop.
        frequency = rng.uniform(430.0, 2600.0)
        sweep = rng.uniform(0.2, 0.9)
        amplitude = rng.uniform(0.022, 0.080)
        amplitude *= math.exp(-start / RATE / (duration * 0.65))
        phase = rng.uniform(0.0, math.tau)
        for offset in range(min(int(life * 5 * RATE), count - start)):
            t = offset / RATE
            envelope = (1.0 - math.exp(-t / 0.0008)) * math.exp(-t / life)
            phase += math.tau * frequency * (1.0 + sweep * (1.0 - math.exp(-t / life))) / RATE
            sound[start + offset] += amplitude * envelope * math.sin(phase)
    # DC rejection and tapered endpoints; weighted correction preserves fades.
    baseline = lowpass(sound, 80.0)
    window = [min(1.0, i / (RATE * 0.002), (count - 1 - i) / (RATE * 0.025))
              for i in range(count)]
    sound = [(s - b) * w for s, b, w in zip(sound, baseline, window)]
    correction = math.fsum(sound) / math.fsum(window)
    sound = [s - correction * w for s, w in zip(sound, window)]
    gain = 10 ** (peak_db / 20) / max(abs(s) for s in sound)
    pcm = [round(s * gain * 32767) for s in sound]
    data = struct.pack("<" + "h" * count, *pcm)
    output = io.BytesIO()
    with wave.open(output, "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(data)
    return output.getvalue()


def inspect(payload):
    with wave.open(io.BytesIO(payload), "rb") as wav:
        assert (wav.getnchannels(), wav.getsampwidth(), wav.getframerate()) == (1, 2, RATE)
        count = wav.getnframes()
        samples = struct.unpack("<" + "h" * count, wav.readframes(count))
    peak = max(abs(s) for s in samples) / 32768
    rms = math.sqrt(math.fsum(s * s for s in samples) / count) / 32768
    dc = math.fsum(samples) / count / 32768
    assert 0 < peak <= 10 ** (-3 / 20)
    assert rms > 0.001 and abs(dc) < 1e-5
    assert samples[0] == samples[-1] == 0
    return {"seconds": count / RATE, "peak_dbfs": round(20 * math.log10(peak), 3),
            "rms_dbfs": round(20 * math.log10(rms), 3), "dc": dc,
            "sha256": hashlib.sha256(payload).hexdigest()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Verify without writing files")
    args = parser.parse_args()
    for name, recipe in RECIPES.items():
        payload = synthesize(name, recipe)
        path = DEST / (name + ".wav")
        if args.check:
            assert path.read_bytes() == payload, f"Nonreproducible asset: {path}"
        else:
            DEST.mkdir(parents=True, exist_ok=True)
            path.write_bytes(payload)
        print(json.dumps({"file": path.name, **inspect(payload)}, sort_keys=True))


if __name__ == "__main__":
    main()
