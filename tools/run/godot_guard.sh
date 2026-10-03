#!/usr/bin/env bash
# Чесний `make run` (план 2026-10-03-Path-to-First-Fight § Godot падає, поки агент працює, пункт 2).
#
#   godot_guard.sh busy <game_dir>          rc=3 і причина, якщо інший процес Godot уже працює на цю теку
#   godot_guard.sh need-import <game_dir>   rc=0 — треба імпортувати (кешу нема або HEAD змінився), rc=1 — не треба
#   godot_guard.sh stamp <game_dir>         записати HEAD у <game_dir>/.godot/nir_import_head після імпорту
#
# «Процес Godot» = перше слово командного рядка має ім'я godot* (без регістру). Тека процесу — з `--path`
# (відносний шлях розв'язується від cwd процесу: на macOS `lsof -d cwd`, на Linux `/proc/PID/cwd`).
# Godot без `--path` (Project Manager, відкритий вручну) не ловиться — про нього скрипт не знає.
# NIR_GUARD_OFF=1 вимикає `busy` (свідомо, на свою відповідальність).
set -u

cmd="${1:-}"; dir="${2:-}"
[ -n "$cmd" ] && [ -n "$dir" ] || { echo "usage: $0 busy|need-import|stamp <game_dir>" >&2; exit 2; }
target="$(cd "$dir" 2>/dev/null && pwd -P)" || { echo "немає теки $dir" >&2; exit 2; }
cache="$target/.godot/global_script_class_cache.cfg"
stampf="$target/.godot/nir_import_head"

proc_cwd() {
  if [ -d "/proc/$1" ]; then readlink "/proc/$1/cwd" 2>/dev/null
  else lsof -a -p "$1" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p' | head -n 1; fi
}

case "$cmd" in
  busy)
    [ "${NIR_GUARD_OFF:-0}" = "1" ] && exit 0
    found=0
    while read -r pid args; do
      [ -n "$pid" ] || continue
      first="${args%% *}"
      case "$(basename "$first" | tr '[:upper:]' '[:lower:]')" in godot*) ;; *) continue ;; esac
      # значення --path: «--path X» або «--path=X»
      p="$(printf '%s\n' "$args" | sed -n -e 's/.*--path[= ]\([^ ]*\).*/\1/p')"
      [ -n "$p" ] || continue
      case "$p" in /*) abs="$p" ;; *) c="$(proc_cwd "$pid")"; [ -n "$c" ] || continue; abs="$c/$p" ;; esac
      abs="$(cd "$abs" 2>/dev/null && pwd -P)" || continue
      if [ "$abs" = "$target" ]; then
        echo "ВІДМОВА: на $target уже працює Godot (pid $pid): $args"
        found=1
      fi
    done < <(ps -axo pid=,args=)
    if [ $found -eq 1 ]; then
      echo "  Два Godot на одну теку ламають кеш класів (план § Godot падає, поки агент працює)."
      echo "  Закрий той Godot або дочекайся, поки агент закінчить; гра — в окремій копії ~/dev/nir-play."
      exit 3
    fi
    exit 0 ;;
  need-import)
    [ -f "$cache" ] || exit 0
    [ -f "$stampf" ] || exit 0
    head="$(git -C "$target" rev-parse HEAD 2>/dev/null)" || exit 1   # не git — штампу нема з чим звіряти
    [ "$(cat "$stampf")" = "$head" ] && exit 1 || exit 0 ;;
  stamp)
    head="$(git -C "$target" rev-parse HEAD 2>/dev/null)" || exit 0
    mkdir -p "$target/.godot" && printf '%s\n' "$head" > "$stampf" ;;
  *) echo "невідома команда: $cmd" >&2; exit 2 ;;
esac
