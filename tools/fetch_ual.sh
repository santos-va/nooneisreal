#!/usr/bin/env bash
# Launch 4 (C1 mannequin): put Quaternius Universal Animation Library 1 + 2 GLBs (Source or Standard tier) into the game.
# The cloud agent cannot reach itch.io (network policy 403), so this runs on Santos's Mac:
#   1. download both zips from
#        https://quaternius.itch.io/universal-animation-library
#        https://quaternius.itch.io/universal-animation-library-2
#      into ~/Downloads (keep the names itch gives them). Santos bought «Source» (2026-10-03); the script takes
#      Source over the free «Standard» if both are there;
#   2. in the repo:  bash tools/fetch_ual.sh
# It checks the zips against the sha256 T3 Архімед recorded (docs/Research/2026-10-03-Animation-Sources.md),
# extracts Unreal-Godot/UAL{1,2}.glb (Source) or UAL{1,2}_Standard.glb (no _RM, CC0) into game/assets/animations/ual/,
# adds the two rows to docs/Art/Textures-Registry.md, commits on a branch `assets/ual` from fresh origin/main and
# pushes it. T2 Гефест takes it from there. `--list` only prints what the zips hold (for the paid Pro /
# Source tiers, whose names and contents nobody has checked yet) and changes nothing. Run it from the repo folder (it may live outside the repo). Flags: --no-push (stop after the commit), --src DIR (default ~/Downloads).
set -euo pipefail
main() {  # the whole body is parsed before it runs: `git switch` below may replace this very file
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "fetch_ual: запускай з теки репо nooneisreal"; exit 2; }
SRC="$HOME/Downloads"; PUSH=1; LIST=0
while [ $# -gt 0 ]; do
  case "$1" in
    --no-push) PUSH=0 ;;
    --src) SRC="$2"; shift ;;
    --list) LIST=1 ;;
    *) echo "fetch_ual: unknown flag $1"; exit 2 ;;
  esac
  shift
done
OUT="game/assets/animations/ual"
BRANCH="assets/ual"
# Expected sha256 (prefix … suffix). Standard — as T3 recorded them; Source — the zips Santos bought,
# as `fetch_ual.sh --list` printed them on his Mac (2026-10-03). UAL_SKIP_SHA=1 only for the script's own test.
SHA_Standard_1=("cc73fc4e" "37724");    SHA_Standard_2=("4008ea20" "a2b2177d")
SHA_Source_1=("28f75286" "47ed868ed5"); SHA_Source_2=("85df4e98" "65cb1b50e8")

cd "$ROOT"
for bin in unzip python3 git; do command -v "$bin" >/dev/null || { echo "fetch_ual: '$bin' не знайдено"; exit 2; }; done
sha() { if command -v shasum >/dev/null; then shasum -a 256 "$1" | cut -d' ' -f1; else sha256sum "$1" | cut -d' ' -f1; fi; }

find_zip() { # $1 = 1 or 2; prints the newest zip of the best tier (Source > Standard) in $SRC ("" if none)
  local f n tier best="" best_rank=0 rank
  for f in "$SRC"/*.zip; do
    [ -f "$f" ] || continue
    n="$(basename "$f")"
    case "$n" in *"Animation Library"*) ;; *) continue ;; esac
    case "$n" in *"Library 2"*) [ "$1" = 2 ] || continue ;; *) [ "$1" = 1 ] || continue ;; esac
    case "$n" in *Source*) rank=2 ;; *Standard*) rank=1 ;; *) continue ;; esac   # Pro: contents unchecked
    if [ "$rank" -gt "$best_rank" ] || { [ "$rank" -eq "$best_rank" ] && [ "$f" -nt "$best" ]; }; then
      best="$f"; best_rank="$rank"
    fi
  done
  printf '%s' "$best"
}
if [ "$LIST" = "1" ]; then
  # show what the zips hold, change nothing
  found=0
  for f in "$SRC"/*.zip; do
    [ -f "$f" ] || continue
    case "$(basename "$f")" in *"Animation Library"*|*UAL*|*"Universal Animation"*) ;; *) continue ;; esac
    found=1
    echo "== $(basename "$f")  ($(wc -c < "$f" | tr -d ' ') байт)"
    echo "   sha256 $(sha "$f")"
    lic="$(unzip -Z1 "$f" | grep -iE '(^|/)licen[sc]e[^/]*\.txt$' | head -n 1)"
    if [ -n "$lic" ]; then echo "   ліцензія ($lic): $(unzip -p "$f" "$lic" | tr '\n' ' ' | cut -c1-160)"; else echo "   ліцензійного файлу немає"; fi
    echo "   3D-файли всередині (glb/gltf/fbx/blend), перші 40:"
    unzip -Z1 "$f" | grep -iE '\.(glb|gltf|fbx|blend)$' | head -n 40 | sed 's/^/     /'
  done
  [ "$found" = 1 ] || echo "fetch_ual --list: у $SRC немає zip з «Animation Library» в імені"
  exit 0
fi
tier_of() { case "$(basename "$1")" in *Source*) echo Source ;; *) echo Standard ;; esac; }
Z1="$(find_zip 1)"
Z2="$(find_zip 2)"
[ -n "$Z1" ] || { echo "fetch_ual: у $SRC немає zip UAL1 тиру Source чи Standard («Universal Animation Library[…].zip»)"; exit 1; }
[ -n "$Z2" ] || { echo "fetch_ual: у $SRC немає zip UAL2 тиру Source чи Standard («Universal Animation Library 2[…].zip»)"; exit 1; }
T1="$(tier_of "$Z1")"; T2="$(tier_of "$Z2")"
echo "UAL1 ($T1): $Z1"; echo "UAL2 ($T2): $Z2"

check() { # zip head tail
  local s; s="$(sha "$1")"
  if [ "${UAL_SKIP_SHA:-0}" = "1" ]; then echo "  sha256 $s (перевірку пропущено — тест)"; return 0; fi
  if [[ "$s" == "$2"* && "$s" == *"$3" ]]; then echo "  sha256 $s ✓"; return 0; fi
  echo "fetch_ual: sha256 $s не збігається з очікуваним ($2…$3) — інша версія паку? Нічого не змінено."; return 1
}
eval "sums1=(\"\${SHA_${T1}_1[@]}\")"; eval "sums2=(\"\${SHA_${T2}_2[@]}\")"
check "$Z1" "${sums1[0]}" "${sums1[1]}"
check "$Z2" "${sums2[0]}" "${sums2[1]}"

if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "fetch_ual: є незакомічені зміни — закоміть або git stash, потім знову"; exit 1
fi
git fetch -q origin
git switch -q -C "$BRANCH" origin/main

mkdir -p "$OUT"
extract() { # zip glb_name
  local inner; inner="$(unzip -Z1 "$1" | grep -E "(^|/)Unreal-Godot/$2\$" | grep -v "Female Mannequin" | head -n 1)"
  [ -n "$inner" ] || { echo "fetch_ual: у $(basename "$1") немає Unreal-Godot/$2"; exit 1; }
  unzip -p "$1" "$inner" > "$OUT/$2"
  local lic; lic="$(unzip -Z1 "$1" | grep -iE '(^|/)License\.txt$' | head -n 1)"
  [ -n "$lic" ] && unzip -p "$1" "$lic" | grep -qiE "CC0|publicdomain/zero" || { echo "fetch_ual: License.txt у $(basename "$1") не каже CC0 — зупиняюсь"; exit 1; }
  local size; size="$(wc -c < "$OUT/$2" | tr -d ' ')"
  if [ "$size" -gt 95000000 ]; then
    echo "fetch_ual: $2 — $size байт, GitHub не прийме файл > 100 МБ без LFS. Зупиняюсь, нічого не закомічено — напиши Гефесту."
    git checkout -q -- docs/Art/Textures-Registry.md 2>/dev/null || true
    exit 1
  fi
  echo "  $OUT/$2  $size байт, License.txt → CC0"
}
G1="UAL1.glb"; [ "$T1" = Source ] || G1="UAL1_Standard.glb"
G2="UAL2.glb"; [ "$T2" = Source ] || G2="UAL2_Standard.glb"
extract "$Z1" "$G1"
extract "$Z2" "$G2"

python3 - "$OUT" "$G1" "$T1" "$G2" "$T2" <<'PY'
import sys
out, g1, t1, g2, t2 = sys.argv[1:6]
p = "docs/Art/Textures-Registry.md"
s = open(p, encoding="utf-8").read()
def row(rid, g, tier, pack, use):
    return (f"| {rid} | `{out}/{g}` | Quaternius {pack} «{tier}» (itch.io, {'куплено Santos 2026-10-03' if tier == 'Source' else 'free tier'}), "
            f"`Unreal-Godot/{g}`, без root motion | Quaternius | CC0 1.0 (`License.txt` у zip) | {use} |")
rows = [
    row("anim-ual1", g1, t1, "Universal Animation Library", "манекен `Mannequin` + кліпи UAL1; запуск 4 (C1), `-- --skeletal-rig`"),
    row("anim-ual2", g2, t2, "Universal Animation Library 2", "кліпи UAL2 на тому самому скелеті (меч, блок, реакції, нокдаун); запуск 4 (C1)"),
]
lines = [l for l in s.split("\n") if f"`{out}/" not in l]
plan = next(j for j, x in enumerate(lines) if x.startswith("## Заплановано"))
anchor = max(i for i, l in enumerate(lines) if "`game/assets/" in l and i < plan)
lines[anchor + 1:anchor + 1] = rows
open(p, "w", encoding="utf-8").write("\n".join(lines))
print("  реєстр: 2 рядки")
PY

git add "$OUT" docs/Art/Textures-Registry.md
git commit -q -m "Add Quaternius UAL1 ($T1) / UAL2 ($T2) GLBs (CC0) for launch 4 (C1 mannequin)" \
  -m "Extracted by tools/fetch_ual.sh on Santos's Mac; zip sha256 matched the expected sums."
echo "коміт: $(git log --oneline -1)"
if [ "$PUSH" = "1" ]; then
  git push -q -u origin "$BRANCH"
  echo "готово: гілка $BRANCH запушена — напиши Гефесту «T2, UAL у гілці»"
else
  echo "готово (без push): гілка $BRANCH"
fi
}
main "$@"
