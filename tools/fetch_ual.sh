#!/usr/bin/env bash
# Launch 4 (C1 mannequin): put Quaternius Universal Animation Library 1 + 2 «Standard» GLBs into the game.
# The cloud agent cannot reach itch.io (network policy 403), so this runs on Santos's Mac:
#   1. download both FREE zips (Standard tier) from
#        https://quaternius.itch.io/universal-animation-library
#        https://quaternius.itch.io/universal-animation-library-2
#      into ~/Downloads (keep the names itch gives them);
#   2. in the repo:  bash tools/fetch_ual.sh
# It checks the zips against the sha256 T3 Архімед recorded (docs/Research/2026-10-03-Animation-Sources.md),
# extracts Unreal-Godot/UAL{1,2}_Standard.glb (no _RM, CC0) into game/assets/animations/ual/, adds the two
# rows to docs/Art/Textures-Registry.md, commits on a branch `assets/ual-standard` from fresh origin/main and
# pushes it. T2 Гефест takes it from there. Run it from the repo folder (it may live outside the repo). Flags: --no-push (stop after the commit), --src DIR (default ~/Downloads).
set -euo pipefail
main() {  # the whole body is parsed before it runs: `git switch` below may replace this very file
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "fetch_ual: запускай з теки репо nooneisreal"; exit 2; }
SRC="$HOME/Downloads"; PUSH=1
while [ $# -gt 0 ]; do
  case "$1" in
    --no-push) PUSH=0 ;;
    --src) SRC="$2"; shift ;;
    *) echo "fetch_ual: unknown flag $1"; exit 2 ;;
  esac
  shift
done
OUT="game/assets/animations/ual"
BRANCH="assets/ual-standard"
# sha256 as T3 recorded them (prefix … suffix); set UAL_SKIP_SHA=1 only for the script's own test
SHA1_HEAD="cc73fc4e"; SHA1_TAIL="37724"
SHA2_HEAD="4008ea20"; SHA2_TAIL="a2b2177d"

cd "$ROOT"
for bin in unzip python3 git; do command -v "$bin" >/dev/null || { echo "fetch_ual: '$bin' не знайдено"; exit 2; }; done
sha() { if command -v shasum >/dev/null; then shasum -a 256 "$1" | cut -d' ' -f1; else sha256sum "$1" | cut -d' ' -f1; fi; }

find_zip() { # $1 = 1 or 2; prints the newest matching zip in $SRC ("" if none)
  local f n best=""
  for f in "$SRC"/*.zip; do
    [ -f "$f" ] || continue
    n="$(basename "$f")"
    case "$n" in *"Animation Library"*Standard*) ;; *) continue ;; esac
    case "$n" in *"Library 2"*) [ "$1" = 2 ] || continue ;; *) [ "$1" = 1 ] || continue ;; esac
    if [ -z "$best" ] || [ "$f" -nt "$best" ]; then best="$f"; fi
  done
  printf '%s' "$best"
}
Z1="$(find_zip 1)"
Z2="$(find_zip 2)"
[ -n "$Z1" ] || { echo "fetch_ual: у $SRC немає «Universal Animation Library[Standard].zip» (UAL1, безкоштовний тир)"; exit 1; }
[ -n "$Z2" ] || { echo "fetch_ual: у $SRC немає «Universal Animation Library 2[Standard].zip» (UAL2, безкоштовний тир)"; exit 1; }
echo "UAL1: $Z1"; echo "UAL2: $Z2"

check() { # zip head tail
  local s; s="$(sha "$1")"
  if [ "${UAL_SKIP_SHA:-0}" = "1" ]; then echo "  sha256 $s (перевірку пропущено — тест)"; return 0; fi
  if [[ "$s" == "$2"* && "$s" == *"$3" ]]; then echo "  sha256 $s ✓"; return 0; fi
  echo "fetch_ual: sha256 $s не збігається з брифом Архімеда ($2…$3) — інша версія паку? Нічого не змінено."; return 1
}
check "$Z1" "$SHA1_HEAD" "$SHA1_TAIL"
check "$Z2" "$SHA2_HEAD" "$SHA2_TAIL"

if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "fetch_ual: є незакомічені зміни — закоміть або git stash, потім знову"; exit 1
fi
git fetch -q origin
git switch -q -C "$BRANCH" origin/main

mkdir -p "$OUT"
extract() { # zip glb_name
  local inner; inner="$(unzip -Z1 "$1" | grep -E "(^|/)Unreal-Godot/$2\$" | head -n 1)"
  [ -n "$inner" ] || { echo "fetch_ual: у $(basename "$1") немає Unreal-Godot/$2"; exit 1; }
  unzip -p "$1" "$inner" > "$OUT/$2"
  local lic; lic="$(unzip -Z1 "$1" | grep -iE '(^|/)License\.txt$' | head -n 1)"
  [ -n "$lic" ] && unzip -p "$1" "$lic" | grep -q "CC0" || { echo "fetch_ual: License.txt у $(basename "$1") не каже CC0 — зупиняюсь"; exit 1; }
  echo "  $OUT/$2  $(wc -c < "$OUT/$2" | tr -d ' ') байт, License.txt → CC0"
}
extract "$Z1" "UAL1_Standard.glb"
extract "$Z2" "UAL2_Standard.glb"

python3 - "$OUT" <<'PY'
import sys
out = sys.argv[1]
p = "docs/Art/Textures-Registry.md"
s = open(p, encoding="utf-8").read()
rows = [
    f"| anim-ual1-standard | `{out}/UAL1_Standard.glb` | Quaternius Universal Animation Library «Standard» (itch.io, free tier), `Unreal-Godot/UAL1_Standard.glb` | Quaternius | CC0 1.0 (`License.txt` у zip) | манекен `Mannequin` + 42 кліпи; запуск 4 (C1), `-- --skeletal-rig` |",
    f"| anim-ual2-standard | `{out}/UAL2_Standard.glb` | Quaternius Universal Animation Library 2 «Standard» (itch.io, free tier), `Unreal-Godot/UAL2_Standard.glb` | Quaternius | CC0 1.0 (`License.txt` у zip) | бібліотека кліпів на тому самому скелеті (меч, блок, реакції, нокдаун); запуск 4 (C1) |",
]
lines = s.split("\n")
lines = [l for l in lines if f"`{out}/UAL1_Standard.glb`" not in l and f"`{out}/UAL2_Standard.glb`" not in l]
anchor = max(i for i, l in enumerate(lines) if "`game/assets/" in l and i < next(j for j, x in enumerate(lines) if x.startswith("## Заплановано")))
lines[anchor + 1:anchor + 1] = rows
open(p, "w", encoding="utf-8").write("\n".join(lines))
print("  реєстр: 2 рядки")
PY

git add "$OUT" docs/Art/Textures-Registry.md
git commit -q -m "Add Quaternius UAL1/UAL2 Standard GLBs (CC0) for launch 4 (C1 mannequin)" \
  -m "Extracted by tools/fetch_ual.sh on Santos's Mac; sha256 of the zips matches T3's brief."
echo "коміт: $(git log --oneline -1)"
if [ "$PUSH" = "1" ]; then
  git push -q -u origin "$BRANCH"
  echo "готово: гілка $BRANCH запушена — напиши Гефесту «T2, UAL у гілці»"
else
  echo "готово (без push): гілка $BRANCH"
fi
}
main "$@"
