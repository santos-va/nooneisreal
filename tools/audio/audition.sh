#!/usr/bin/env bash
# Listen to the built game SFX on the Mac, one by one, name on screen (the ear check build_sfx.py can't do):
#   bash tools/audio/audition.sh               # every .ogg in game/assets/audio/sfx/
#   bash tools/audio/audition.sh hit_ kunai    # only names starting with these
#   AB=1 bash tools/audio/audition.sh hit_     # each new .ogg right after the old synth .wav of that name
# Verdicts go back into tools/audio/sfx_recipes.tsv (swap a glob or start_ms, rebuild with build_sfx.sh).
set -euo pipefail
sfx="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../game/assets/audio/sfx" && pwd)"
command -v afplay >/dev/null || { echo "audition: потрібен afplay (є лише на macOS)"; exit 2; }
shopt -s nullglob
n=0
for f in "$sfx"/*.ogg; do
  name="$(basename "$f" .ogg)"
  if [ $# -gt 0 ]; then
    hit=0; for p in "$@"; do [[ "$name" == "$p"* ]] && hit=1; done
    [ $hit -eq 1 ] || continue
  fi
  if [ "${AB:-0}" = 1 ] && [ -f "$sfx/$name.wav" ]; then
    printf '%-18s A (синт .wav)\n' "$name"; afplay "$sfx/$name.wav"; sleep 0.3
    printf '%-18s B (бібліотека .ogg)\n' "$name"
  else
    printf '%-18s\n' "$name"
  fi
  afplay "$f"; sleep 0.4
  n=$((n + 1))
done
[ $n -gt 0 ] || { echo "audition: нічого не знайдено в $sfx за фільтром: $*"; exit 1; }
