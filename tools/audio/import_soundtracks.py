#!/usr/bin/env python3
"""Stage three authorized sources at equal integrated loudness; never alter originals.
Example: python3 tools/audio/import_soundtracks.py --menu '/path/menu.mp3' \
  --battle '/path/a.mp3' '/path/b.mp3' --output /tmp/santos-normalized
Review report and license provenance before copying outputs into game/assets.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import subprocess
import tempfile

TARGET_I = -20.0  # PLACEHOLDER listening target; quieter than commercial beat masters.
TARGET_TP = -2.0


def run(args):
    return subprocess.run(['ffmpeg', '-hide_banner', '-nostdin', *args],
                          check=True, capture_output=True, text=True).stderr


def measure(source):
    log = run(['-i', str(source), '-vn', '-af',
               f'loudnorm=I={TARGET_I}:TP={TARGET_TP}:LRA=11:print_format=json',
               '-f', 'null', '-'])
    result = json.loads(log[log.rfind('{'):log.rfind('}') + 1])
    if not all(math.isfinite(float(result[k])) for k in
               ('input_i', 'input_tp', 'input_lra', 'input_thresh', 'target_offset')):
        raise ValueError(f'Cannot normalize silence/nonfinite measurements: {source}')
    return result


def normalize(source, target):
    first = measure(source)
    params = ':'.join(f'{out}={first[key]}' for out, key in (
        ('measured_I', 'input_i'), ('measured_TP', 'input_tp'),
        ('measured_LRA', 'input_lra'), ('measured_thresh', 'input_thresh'),
        ('offset', 'target_offset')))
    run(['-i', str(source), '-vn', '-map_metadata', '-1', '-af',
         f'loudnorm=I={TARGET_I}:TP={TARGET_TP}:LRA=11:{params}:linear=true',
         '-ar', '48000', '-ac', '2', '-c:a', 'libvorbis', '-q:a', '6', str(target)])
    final = measure(target)  # Measure the encoded file, including codec overshoot.
    if abs(float(final['input_i']) - TARGET_I) > 1.0 or float(final['input_tp']) > -1.0:
        raise ValueError(f'Encoded loudness/peak verification failed: {target}: {final}')
    return {'source_name': source.name,
            'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
            'before': first, 'after': final}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--menu', required=True, type=Path)
    parser.add_argument('--battle', required=True, nargs=2, type=Path)
    parser.add_argument('--output', required=True, type=Path,
                        help='New staging directory; must not already exist')
    args = parser.parse_args()
    sources = [args.menu.resolve(), *(p.resolve() for p in args.battle)]
    if any(not p.is_file() for p in sources):
        parser.error('All three source files must exist')
    if args.output.exists():
        parser.error('Output already exists; refusing to overwrite')
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=args.output.parent) as temporary:
        staging = Path(temporary)
        report = {}
        for slot, source in zip(('menu', 'battle_1', 'battle_2'), sources):
            report[slot] = normalize(source, staging / f'santos_{slot}.ogg')
        (staging / 'measurements.json').write_text(json.dumps(report, indent=2) + '\n')
        (staging / 'soundtracks.cfg').write_text('[tracks]\n' + ''.join(
            f'{slot}="res://assets/audio/music/santos_{slot}.ogg"\n' for slot in report))
        staging.rename(args.output)
    print(f'Verified three tracks at {TARGET_I} LUFS (±1 LU): {args.output}')
    print('Staged only. Register actual source rights before admitting assets to game/.')


if __name__ == '__main__':
    main()
