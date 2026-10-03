#!/usr/bin/env python3
"""Raw sound library -> shelf map + catalog. Runs on the Mac next to the library:
    python3 tools/audio/catalog.py            # writes tools/audio/library_catalog.tsv
    python3 tools/audio/catalog.py --view     # + tools/audio/nir-audio/_by-category/<shelf>/<pack> links

The library (tools/audio/nir-audio/, gitignored) keeps the bundles exactly as downloaded, because the
licence travels with the bundle. Sorting is a view on top: a symlink per pack under _by-category/,
shelf taken from library_categories.tsv. The catalog is committed, so agents without the library
(the cloud sessions) can still write recipes for build_sfx.py against real file names and hit times.

Columns: shelf, bundle, pack, file (path inside the bundle — what build_sfx.py globs match after the
bundle name), dur_s, sr, ch, peak_db, onsets_ms (starts of separate sounds in takes up to 30 s, for
the start_ms column of sfx_recipes.tsv), licence (from sfx_sources.tsv).
Needs ffmpeg/ffprobe. Only reads the library; the view holds symlinks only.
"""
from __future__ import annotations

import argparse
import fnmatch
import json
import os
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HERE = Path(__file__).resolve().parent
AUDIO_EXT = (".wav", ".ogg", ".flac", ".mp3", ".aif", ".aiff")
ONSET_MAX_S = 30.0      # longer takes are ambiences: no hit map
ONSET_FLOOR_DB = 30.0   # a sound starts where the level rises above (peak - 30 dB)
ONSET_GAP_S = 0.06      # silences shorter than this do not split two sounds
MAX_ONSETS = 24
VIEW = "_by-category"


def read_tsv(path: Path) -> list[list[str]]:
    rows = []
    for ln in path.read_text(encoding="utf-8").splitlines():
        if ln.strip() and not ln.lstrip().startswith("#"):
            rows.append([c.strip() for c in ln.split("\t")])
    return rows


def match(rows: list[list[str]], name: str) -> list[str] | None:
    return next((r for r in rows if fnmatch.fnmatch(name.lower(), r[0].lower())), None)


def probe(path: Path) -> dict:
    out = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "a:0", "-show_entries",
                          "stream=sample_rate,channels:format=duration", "-of", "json", str(path)],
                         capture_output=True, text=True).stdout
    try:
        j = json.loads(out)
        st = j["streams"][0]
        info = {"dur": float(j["format"]["duration"]), "sr": int(st["sample_rate"]), "ch": int(st["channels"])}
    except (KeyError, IndexError, ValueError, json.JSONDecodeError):
        return {"dur": 0.0, "sr": 0, "ch": 0, "peak": None, "onsets": []}
    info["peak"], info["onsets"] = None, []
    if info["dur"] <= ONSET_MAX_S:
        err = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", str(path), "-af", "volumedetect",
                              "-f", "null", "-"], capture_output=True, text=True).stderr
        m = re.search(r"max_volume: (-?[0-9.]+) dB", err)
        if m:
            peak = float(m.group(1))
            info["peak"] = peak
            err = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", str(path), "-af",
                                  f"silencedetect=noise={peak - ONSET_FLOOR_DB:.1f}dB:d={ONSET_GAP_S}",
                                  "-f", "null", "-"], capture_output=True, text=True).stderr
            starts = [float(x) for x in re.findall(r"silence_start: (-?[0-9.]+)", err)]
            ends = [float(x) for x in re.findall(r"silence_end: (-?[0-9.]+)", err)]
            onsets = [] if starts and starts[0] <= 0.001 else [0.0]
            onsets += [e for e in ends if e < info["dur"] - 0.02]
            info["onsets"] = [int(round(o * 1000)) for o in onsets[:MAX_ONSETS]]
    return info


def main() -> int:
    ap = argparse.ArgumentParser()
    local = HERE / "nir-audio"
    ap.add_argument("--src", default=os.environ.get(
        "NIR_AUDIO", str(local if local.is_dir() else Path.home() / "Downloads/nir-audio")))
    ap.add_argument("--out", default=str(HERE / "library_catalog.tsv"))
    ap.add_argument("--categories", default=str(HERE / "library_categories.tsv"))
    ap.add_argument("--sources", default=str(HERE / "sfx_sources.tsv"))
    ap.add_argument("--view", action="store_true", help=f"rebuild <src>/{VIEW}/ symlinks")
    ap.add_argument("--jobs", type=int, default=6)
    a = ap.parse_args()

    src = Path(a.src).expanduser()
    if not src.is_dir():
        print(f"catalog: бібліотеки {src} немає")
        return 2
    cats, sources = read_tsv(Path(a.categories)), read_tsv(Path(a.sources))
    bundles = sorted(p for p in src.iterdir() if p.is_dir() and not p.name.startswith((".", "_")))
    entries = []   # (shelf, bundle, pack, pack_dir, rel, abs, licence)
    for b in bundles:
        lic = (match(sources, b.name) or ["", "БЕЗ ЛІЦЕНЗІЇ"])[1]
        for f in sorted(b.rglob("*")):
            if f.suffix.lower() not in AUDIO_EXT or f.name.startswith("._"):
                continue
            rel = f.relative_to(b)
            first = rel.parts[0] if len(rel.parts) > 1 else ""
            row = match(cats, first) if first else None
            pack, pack_dir = (first, b / first) if row else (b.name, b)
            row = row or match(cats, b.name)
            entries.append((row[1] if row else "unsorted", b.name, pack, pack_dir, rel.as_posix(), f, lic))
    if not entries:
        print(f"catalog: у {src} немає звуків")
        return 2

    with ThreadPoolExecutor(max_workers=a.jobs) as ex:
        infos = list(ex.map(lambda e: probe(e[5]), entries))

    lines = ["# shelf\tbundle\tpack\tfile\tdur_s\tsr\tch\tpeak_db\tonsets_ms\tlicence",
             "# generated by tools/audio/catalog.py — do not edit by hand; shelves live in library_categories.tsv"]
    for e, i in sorted(zip(entries, infos), key=lambda t: (t[0][0], t[0][2].lower(), t[0][4].lower())):
        peak = "" if i["peak"] is None else f"{i['peak']:.1f}"
        lines.append("\t".join([e[0], e[1], e[2], e[4], f"{i['dur']:.2f}", str(i["sr"]), str(i["ch"]), peak,
                                ",".join(map(str, i["onsets"])), e[6]]))
    Path(a.out).write_text("\n".join(lines) + "\n", encoding="utf-8")

    shelves: dict[str, set[str]] = {}
    for e in entries:
        shelves.setdefault(e[0], set()).add(e[2])
    print(f"catalog: {len(entries)} звуків, {len({e[3] for e in entries})} паків → {a.out}")
    for s in sorted(shelves):
        n = sum(1 for e in entries if e[0] == s)
        print(f"  {s:16s} {len(shelves[s]):3d} паків  {n:4d} файлів")
    missing = sorted({e[1] for e in entries if e[6] == "БЕЗ ЛІЦЕНЗІЇ"})
    if missing:
        print("  без рядка ліцензії в sfx_sources.tsv: " + ", ".join(missing))

    if a.view:
        view = src / VIEW
        if view.exists():   # the view holds only links made here (+ Finder's .DS_Store): unlink, drop empty shelves
            for p in sorted(view.rglob("*"), key=lambda q: len(q.parts), reverse=True):
                if p.is_symlink() or p.name == ".DS_Store":
                    p.unlink()
                elif p.is_dir() and not any(p.iterdir()):
                    p.rmdir()
        for shelf, pack_dir in sorted({(e[0], e[3]) for e in entries}):
            d = view / shelf
            d.mkdir(parents=True, exist_ok=True)
            (d / pack_dir.name).symlink_to(os.path.relpath(pack_dir, d), target_is_directory=True)
        print(f"  вид по полицях: {view}/<полиця>/<пак> (посилання, оригінали на місці)")
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
