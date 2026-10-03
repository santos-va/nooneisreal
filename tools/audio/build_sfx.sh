#!/usr/bin/env bash
# Library SFX -> layered, mastered game SFX (plan 2026-10-03, step 1.2). Runs on Santos's Mac:
#   bash tools/audio/build_sfx.sh            # zips from ~/Downloads/nir-audio/
#   NIR_AUDIO=/path/to/zips bash tools/audio/build_sfx.sh --dry-run
# Recipes: tools/audio/sfx_recipes.tsv · licences: tools/audio/sfx_sources.tsv (no licence -> refuse).
# Needs: python3, ffmpeg (with libvorbis), unzip. Logic lives in build_sfx.py.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for bin in python3 ffmpeg unzip; do
  command -v "$bin" >/dev/null || { echo "build_sfx: '$bin' не знайдено (macOS: brew install ${bin/python3/python})"; exit 2; }
done
exec python3 "$here/build_sfx.py" "$@"
