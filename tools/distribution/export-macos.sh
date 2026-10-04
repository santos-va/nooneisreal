#!/usr/bin/env bash
# Linux/macOS build host; Python is only a build dependency, never an installer dependency.
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "$0")/../.." && pwd)
output=${1:?Usage: export-macos.sh /absolute/output/directory [40-character revision]}
revision=${2:-$(git -C "$repo_root" rev-parse HEAD)}
[[ "$output" = /* ]] || { echo 'Output must be absolute' >&2; exit 1; }
[[ "$revision" =~ ^[0-9a-f]{40}$ ]] || { echo 'Invalid revision' >&2; exit 1; }
godot_bin=${GODOT_BIN:-godot}
version=$("$godot_bin" --version)
[[ "$version" = 4.7.stable* ]] || { echo "Godot 4.7 stable required; got $version" >&2; exit 1; }
mkdir -p "$output"
stage=$(mktemp -d "${TMPDIR:-/tmp}/nir-macos-export.XXXXXX")
trap 'rm -rf -- "$stage"' EXIT
mkdir "$stage/game"
# Do not mutate the shared working project's preset/import cache while building.
(cd "$repo_root/game" && tar --exclude=.godot --exclude=export -cf - .) | (cd "$stage/game" && tar -xf -)
python3 - "$stage/game/export_presets.cfg" "$revision" <<'PY'
import pathlib, sys
preset=pathlib.Path(sys.argv[1]); text=preset.read_text()
revision=sys.argv[2]
text=text.replace('application/additional_plist_content=""', f'application/additional_plist_content="<key>NIRBuildRevision</key><string>{revision}</string>"')
if (preset.parent/'assets/ui/app_icon.png').is_file():
    text=text.replace('application/icon="res://icon.svg"', 'application/icon="res://assets/ui/app_icon.png"')
preset.write_text(text)
PY
"$godot_bin" --headless --path "$stage/game" --editor --import --quit > "$output/import.log" 2>&1
if grep -E '(^|[[:space:]])(ERROR:|SCRIPT ERROR:|Parse Error:)' "$output/import.log"; then
    echo 'Godot import reported errors; refusing package.' >&2; exit 1
fi
"$godot_bin" --headless --path "$stage/game" --export-release macOS "$output/NoOneIsReal-macos.zip" > "$output/export.log" 2>&1
if grep -E '(^|[[:space:]])(ERROR:|SCRIPT ERROR:|Parse Error:)' "$output/export.log"; then
    echo 'Godot export reported errors; refusing package.' >&2; exit 1
fi
# Require actual app metadata and native arm64 payload, not only exporter exit code.
python3 "$repo_root/tools/distribution/package-macos.py" "$output" "$revision"
# Release bootstrap can be bundled with the first verified archive before main is merged.
mkdir -p "$output/No One Is Real Installer"
cp "$repo_root/tools/distribution/Install.command" "$repo_root/tools/distribution/update-macos.sh" "$output/No One Is Real Installer/"
cp "$output/manifest.json" "$output/NoOneIsReal-macos.zip" "$output/No One Is Real Installer/"
(cd "$output" && zip -qr NoOneIsReal-Installer.zip 'No One Is Real Installer')
printf 'Exported revision %s to %s\n' "$revision" "$output"
