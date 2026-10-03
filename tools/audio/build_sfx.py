#!/usr/bin/env python3
"""Library SFX -> layered, mastered game SFX (plan 2026-10-03, step 1.2). Entry: build_sfx.sh.

1. Unzip every zip in $NIR_AUDIO (default ~/Downloads/nir-audio) into a work dir.
2. Refuse a zip without a licence row in sfx_sources.tsv (rc 1).
3. For each recipe name and variant: pick one file per layer, trim leading silence, cut to max_ms,
   fade out, mono 44.1 kHz, gain, delay -> amix -> acompressor(1 ms, 4:1) -> alimiter(-1 dBFS)
   -> peak-normalise to -1.5 dBFS -> libvorbis .ogg into game/assets/audio/sfx/.
4. Verify every output peak <= -1.0 dBFS (ffmpeg volumedetect), else rc 1.
5. Write/replace one row per output in docs/Art/Textures-Registry.md (source files + licence).
Existing .wav placeholders are NOT deleted (deleting assets is a Red-zone action); Sfx.gd prefers
.ogg over .wav for the same name, so the new sound wins as soon as it exists.

Flags: --list (print files inside the packs), --dry-run (no writes), --out DIR, --registry FILE,
       --src DIR, --recipes FILE, --sources FILE.
"""
from __future__ import annotations

import argparse
import fnmatch
import os
import re
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
AUDIO_EXT = (".wav", ".ogg", ".flac", ".mp3", ".aif", ".aiff")
PEAK_MAX_DB = -1.0
TARGET_DB = -1.5


def read_tsv(path: Path) -> list[list[str]]:
    rows = []
    for ln in path.read_text(encoding="utf-8").splitlines():
        if not ln.strip() or ln.lstrip().startswith("#"):
            continue
        rows.append([c.strip() for c in ln.split("\t")])
    return rows


def peak_db(path: Path) -> float:
    out = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", str(path), "-af", "volumedetect",
                          "-f", "null", "-"], capture_output=True, text=True).stderr
    m = re.search(r"max_volume: (-?[0-9.]+) dB", out)
    return float(m.group(1)) if m else 0.0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default=os.environ.get("NIR_AUDIO", str(Path.home() / "Downloads/nir-audio")))
    ap.add_argument("--out", default=str(ROOT / "game/assets/audio/sfx"))
    ap.add_argument("--registry", default=str(ROOT / "docs/Art/Textures-Registry.md"))
    ap.add_argument("--recipes", default=str(HERE / "sfx_recipes.tsv"))
    ap.add_argument("--sources", default=str(HERE / "sfx_sources.tsv"))
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    src = Path(a.src).expanduser()
    zips = sorted(src.glob("*.zip")) if src.is_dir() else []
    if not zips:
        print(f"build_sfx: у {src} немає zip-ів — нічого збирати")
        return 2
    sources = read_tsv(Path(a.sources))
    work = Path(tempfile.mkdtemp(prefix="nir-audio-"))
    files: list[tuple[str, Path, str, str]] = []   # (rel path, abs, licence, url)
    refused = []
    for z in zips:
        row = next((r for r in sources if fnmatch.fnmatch(z.name.lower(), r[0].lower())), None)
        if row is None or len(row) < 3 or not row[1]:
            refused.append(z.name)
            continue
        dest = work / z.stem
        with zipfile.ZipFile(z) as zf:
            zf.extractall(dest)
        for p in sorted(dest.rglob("*")):
            if p.suffix.lower() in AUDIO_EXT and not p.name.startswith("._"):
                files.append((f"{z.name}/{p.relative_to(dest).as_posix()}", p, row[1], row[2]))
    if refused:
        print("ВІДМОВА: немає рядка ліцензії в sfx_sources.tsv для: " + ", ".join(refused))
        print("  відкрий сторінку завантаження, прочитай ліцензію, додай рядок і запусти знову")
        return 1
    if a.list:
        for rel, _, lic, _ in files:
            print(f"{lic:28s} {rel}")
        return 0

    recipes: dict[str, dict] = {}
    for r in read_tsv(Path(a.recipes)):
        name, variants, layer, glob, gain, off, mx = r[:7]
        rec = recipes.setdefault(name, {"variants": int(variants), "layers": []})
        rec["layers"].append({"layer": layer, "glob": glob.lower(), "gain": float(gain),
                              "off": int(off), "max": int(mx)})

    out_dir = Path(a.out)
    rows: list[tuple[str, str, str, str]] = []   # (out path, sources, licences, name)
    rc = 0
    for name, rec in recipes.items():
        for v in range(1, rec["variants"] + 1):
            inputs, chains, used, lics = [], [], [], set()
            for li, L in enumerate(rec["layers"]):
                cand = [f for f in files if fnmatch.fnmatch(f[0].lower(), L["glob"])]
                if not cand:
                    print(f"  {name}: шар '{L['layer']}' — нічого не знайдено за '{L['glob']}' (пропускаю шар)")
                    continue
                rel, path, lic, url = cand[(v - 1) % len(cand)]
                k = len(inputs) // 2
                inputs += ["-i", str(path)]
                chains.append(
                    f"[{k}:a]aformat=sample_rates=44100:channel_layouts=mono,"
                    f"silenceremove=start_periods=1:start_threshold=-50dB,"
                    f"atrim=0:{L['max'] / 1000:.3f},asetpts=PTS-STARTPTS,"
                    f"afade=t=out:st={max(0, L['max'] - 15) / 1000:.3f}:d=0.015,"
                    f"volume={L['gain']}dB,adelay={L['off']}[l{k}]")
                used.append(f"{L['layer']}: {rel}")
                lics.add(lic)
            if not inputs:
                print(f"  {name}_{v}: жодного шару — пропущено")
                continue
            n = len(chains)
            graph = ";".join(chains) + ";" + "".join(f"[l{i}]" for i in range(n)) + \
                f"amix=inputs={n}:normalize=0:duration=longest," \
                f"acompressor=threshold=0.125:ratio=4:attack=1:release=80:makeup=2," \
                f"alimiter=limit=0.891:level=false:attack=1:release=30[o]"
            fname = f"{name}.ogg" if v == 1 else f"{name}_{v}.ogg"
            dst = out_dir / fname
            if a.dry_run:
                print(f"  [dry] {fname} <- " + " | ".join(used))
                continue
            dst.parent.mkdir(parents=True, exist_ok=True)
            tmp_wav = work / f"_{fname}.wav"
            cmd = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *inputs,
                   "-filter_complex", graph, "-map", "[o]", str(tmp_wav)]
            res = subprocess.run(cmd, capture_output=True, text=True)
            if res.returncode != 0:
                print(f"  ПОМИЛКА ffmpeg на {fname}: {res.stderr.strip()[:300]}")
                rc = 1
                continue
            # second pass: peak-normalise to TARGET (a little under -1 so Vorbis overshoot stays legal)
            gain = TARGET_DB - peak_db(tmp_wav)
            res = subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(tmp_wav),
                                  "-af", f"volume={gain:.2f}dB", "-c:a", "libvorbis", "-q:a", "6", str(dst)],
                                 capture_output=True, text=True)
            if res.returncode != 0:
                print(f"  ПОМИЛКА кодування {fname}: {res.stderr.strip()[:300]}")
                rc = 1
                continue
            pk = peak_db(dst)
            ok = pk <= PEAK_MAX_DB
            print(f"  {'ok ' if ok else 'ПІК'} {fname}  peak {pk:+.1f} dBFS  <- " + " | ".join(used))
            if not ok:
                rc = 1
            rows.append((f"game/assets/audio/sfx/{fname}", "; ".join(used), ", ".join(sorted(lics)), name))

    if rows and not a.dry_run:
        reg = Path(a.registry)
        text = reg.read_text(encoding="utf-8")
        lines = text.split("\n")
        paths = {r[0] for r in rows}
        lines = [ln for ln in lines if not any(f"`{p}`" in ln for p in paths)]
        # insert after the last row of the "На диску" table
        anchor = max(i for i, ln in enumerate(lines) if "`game/assets/" in ln)
        new = [f"| sfx-lib-{Path(p).stem.replace('_', '-')} | `{p}` | build_sfx.sh: {src_} | бібліотека | {lic} | "
               f"`Sfx.play(\"{name}\")` |" for p, src_, lic, name in rows]
        lines[anchor + 1:anchor + 1] = new
        reg.write_text("\n".join(lines), encoding="utf-8")
        print(f"реєстр: {len(new)} рядків у {reg}")
    print("далі: make gates (РЕЄ) і прослухати в грі (make run)")
    return rc


if __name__ == "__main__":
    sys.exit(main())
