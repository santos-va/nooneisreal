#!/usr/bin/env bash
# Skea ult music: Santos's track window -> game/assets/audio/music/ult_skea_bass.ogg
# (plan docs/Plans/2026-10-03-Skea-Ult-Bass.md, step 2). Deterministic, runs anywhere with ffmpeg:
#   bash tools/audio/cut_ult_track.sh
#
# Source: tools/audio/sources/skea_ult_i_could_better_57-74s.mp3 (window 0 s ~= track 57.0 s, +-0.03 s).
# Marks measured on the source (RMS < 120 Hz, 10 ms windows, 2026-10-03):
#   3.03 s  drop: bass hits             (track ~60.03 s)
#  13.46 s  bass part 1 cuts out        (track ~70.46 s)
#  14.89 s  bass part 2 first hit       (track ~71.89 s)
# Cut 2.00 -> 14.85 s (track 59.0 -> 71.85 s): starts on the "inhale", drop lands at 1.03 s in the
# .ogg; stops 40 ms before part 2 so its first hit never leaks into the tail. 12.85 s, no loop.
# Gain -13 dB: the mix peaks near -3.6 dBFS RMS, music sits ~-18 dBFS in game (07-Audio).
# 10 ms fade-in (no click on the cut), 0.4 s fade-out over the break. The in-game end is the
# stinger `ult_end` (sfx_recipes.tsv) + a 0.3-0.5 s fade in code; this fade is the safety net.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
src="$root/tools/audio/sources/skea_ult_i_could_better_57-74s.mp3"
dst="$root/game/assets/audio/music/ult_skea_bass.ogg"

START=2.00
END=14.85
GAIN_DB=-13
FADE_IN=0.01
FADE_OUT=0.40

command -v ffmpeg >/dev/null || { echo "cut_ult_track: 'ffmpeg' не знайдено (macOS: brew install ffmpeg)"; exit 2; }
[ -f "$src" ] || { echo "cut_ult_track: немає джерела $src"; exit 2; }
mkdir -p "$(dirname "$dst")"

len="$(python3 -c "print(round($END - $START, 3))")"
fo_start="$(python3 -c "print(round($END - $START - $FADE_OUT, 3))")"
# Trim inside the filter graph (sample-exact) and reset timestamps, so the fades count from the cut.
ffmpeg -v error -y -i "$src" \
  -af "atrim=start=$START:end=$END,asetpts=PTS-STARTPTS,afade=t=in:st=0:d=$FADE_IN,afade=t=out:st=$fo_start:d=$FADE_OUT,volume=${GAIN_DB}dB" \
  -ar 48000 -ac 2 -c:a libvorbis -q:a 6 -map_metadata -1 "$dst"
echo "cut_ult_track: $dst (${len} s, ${GAIN_DB} dB)"
