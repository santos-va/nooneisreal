#!/usr/bin/env bash
# Albedo A/B capture (plan 2026-10-14 step 5): native Compatibility/llvmpipe run of tools/art/albedo_ab_capture.gd
# under xvfb, isolated Godot profile, nothing written to game/ except the import cache it already has.
#   GODOT_BIN=/path/to/godot bash tools/art/albedo_ab_capture.sh OUT_DIR [--hero=skea] [--stations=pump,hero] [--dump-shaders]
# OUT_DIR gets the frames, receipt_<hero>.json, run.log and run.rc. Numbers and sheets: tools/art/albedo_ab_table.py.
# Needs an imported project (make check imports first). RES overrides the window size (default 1920x1080).
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" || exit 2
G="${GODOT_BIN:-$(command -v godot 2>/dev/null || true)}"
[ -n "$G" ] && [ -x "$G" ] || { echo "godot не знайдено: задай GODOT_BIN"; exit 2; }
command -v xvfb-run >/dev/null || { echo "xvfb-run відсутній: кадри потребують дисплея"; exit 2; }
[ -f "$ROOT/game/.godot/global_script_class_cache.cfg" ] || { echo "проєкт не імпортований: спершу make check"; exit 2; }
OUT="${1:-}"; [ -n "$OUT" ] || { echo "usage: $0 OUT_DIR [args]"; exit 2; }
shift
case "$OUT" in /*) ;; *) OUT="$PWD/$OUT" ;; esac
bash "$ROOT/tools/run/godot_guard.sh" busy "$ROOT/game" || exit $?
mkdir -p "$OUT"
RES="${RES:-1920x1080}"
profile="$(mktemp -d "${TMPDIR:-/tmp}/nir-albedo-ab.XXXXXX")" || exit 2
trap 'rm -rf -- "$profile"' EXIT
export XDG_DATA_HOME="$profile/data" XDG_CONFIG_HOME="$profile/config" XDG_CACHE_HOME="$profile/cache" XDG_RUNTIME_DIR="$profile/runtime"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"
export LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe
timeout --kill-after=10s "${TMO:-1500}s" xvfb-run -a -s "-screen 0 ${RES}x24 -nolisten tcp" "$G" --path "$ROOT/game" \
  --rendering-method gl_compatibility --audio-driver Dummy --fixed-fps 60 --resolution "$RES" --windowed \
  --script "$ROOT/tools/art/albedo_ab_capture.gd" -- --out="$OUT" "$@" > "$OUT/run.log" 2>&1
rc=$?
echo "rc=$rc" > "$OUT/run.rc"
echo "rc=$rc errors=$(grep -c -E '^(SCRIPT )?ERROR' "$OUT/run.log") log=$OUT/run.log"
exit "$rc"
