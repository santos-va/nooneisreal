#!/bin/bash
# Build committed game sources without changing the user's checkout. Stock macOS tools.
set -euo pipefail
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
[ "$(uname -s)" = Darwin ] || fail 'Run this installer on macOS.'
repo=${1:?Usage: install-local-macos.sh /path/to/repository tooling-commit}
tooling=${2:?Supply the pinned tooling commit}
[[ "$tooling" =~ ^[0-9a-f]{40}$ ]] || fail 'Tooling revision must be a full commit hash.'
repo=$(git -C "$repo" rev-parse --show-toplevel)
revision=$tooling
git -C "$repo" cat-file -e "$tooling^{commit}"
[ -w /Applications ] || fail '/Applications is not writable for this account; no administrator changes were made.'
if pgrep -x 'No One Is Real' >/dev/null 2>&1; then fail 'Quit No One Is Real before installing.'; fi
printf 'Building pinned game revision %s. Your checkout and uncommitted edits are untouched.\n' "$revision"
stage=$(mktemp -d /tmp/nir-local-install.XXXXXX)
trap 'rm -rf -- "$stage"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP
mkdir -p "$stage/source" "$stage/package"
git -C "$repo" archive "$revision" game | tar -xf - -C "$stage/source"
git -C "$repo" show "$tooling:game/export_presets.cfg" > "$stage/preset.cfg"
git -C "$repo" show "$tooling:tools/distribution/update-macos.sh" > "$stage/package/update-macos.sh"
sed "s|application/additional_plist_content=\"\"|application/additional_plist_content=\"<key>NIRBuildRevision</key><string>$revision</string>\"|" "$stage/preset.cfg" > "$stage/source/game/export_presets.cfg"
base=https://github.com/godotengine/godot-builds/releases/download/4.7-stable
fetch() { curl --fail --location --show-error --proto '=https' --proto-redir '=https' --connect-timeout 30 --retry 3 --output "$2" "$1"; }
verified_download() {
    local name="$1" expected actual
    [ -f "$stage/SHA512-SUMS.txt" ] || fetch "$base/SHA512-SUMS.txt" "$stage/SHA512-SUMS.txt"
    expected=$(awk -v name="$name" '$2==name || $2=="*"name {print $1}' "$stage/SHA512-SUMS.txt")
    [[ "$expected" =~ ^[0-9a-fA-F]{128}$ ]] || fail "Missing official checksum for $name"
    fetch "$base/$name" "$stage/$name"
    actual=$(shasum -a 512 "$stage/$name" | awk '{print $1}')
    [ "$actual" = "$expected" ] || fail "Official SHA512 mismatch: $name"
}
godot_bin=${GODOT_BIN:-}
if [ -n "$godot_bin" ]; then
    [ -x "$godot_bin" ] || fail 'GODOT_BIN must name an executable.'
else
    for candidate in /Applications/Godot.app/Contents/MacOS/Godot "$(command -v godot || true)"; do
        if [ -n "$candidate" ] && [ -x "$candidate" ] && [[ "$("$candidate" --version)" = 4.7.stable* ]]; then godot_bin="$candidate"; break; fi
    done
fi
if [ -z "$godot_bin" ]; then
    printf 'Downloading official Godot 4.7 editor for this temporary build.\n'
    verified_download Godot_v4.7-stable_macos.universal.zip
    mkdir "$stage/editor"
    ditto -x -k "$stage/Godot_v4.7-stable_macos.universal.zip" "$stage/editor"
    godot_bin="$stage/editor/Godot.app/Contents/MacOS/Godot"
fi
[[ "$("$godot_bin" --version)" = 4.7.stable* ]] || fail 'Godot 4.7 stable is required.'
template="$HOME/Library/Application Support/Godot/export_templates/4.7.stable/macos.zip"
if [ ! -f "$template" ]; then
    printf 'macOS export template missing: downloading official template pack (about 1.28 GB).\n'
    verified_download Godot_v4.7-stable_export_templates.tpz
    unzip -p "$stage/Godot_v4.7-stable_export_templates.tpz" templates/macos.zip > "$stage/macos.zip"
    unzip -tq "$stage/macos.zip" >/dev/null
    template="$stage/macos.zip"
fi
# Explicit custom templates avoid changing the shared editor template installation.
sed -e "s|custom_template/debug=\"\"|custom_template/debug=\"$stage/macos.zip\"|" -e "s|custom_template/release=\"\"|custom_template/release=\"$stage/macos.zip\"|" "$stage/source/game/export_presets.cfg" > "$stage/preset.final"
[ "$template" = "$stage/macos.zip" ] || cp "$template" "$stage/macos.zip"
mv "$stage/preset.final" "$stage/source/game/export_presets.cfg"
logdir="$HOME/Library/Logs/No One Is Real"
mkdir -p "$logdir"
run_godot() {
    local name="$1"; shift
    if ! "$godot_bin" --headless --path "$stage/source/game" "$@" > "$logdir/$name.log" 2>&1; then
        tail -40 "$logdir/$name.log" >&2; fail "Build failed; log: $logdir/$name.log"
    fi
    if grep -E '(^|[[:space:]])(ERROR:|SCRIPT ERROR:|Parse Error:)' "$logdir/$name.log"; then fail "Build reported errors; log: $logdir/$name.log"; fi
}
printf 'Importing and exporting the game; logs: %s\n' "$logdir"
run_godot local-import --editor --import --quit
run_godot local-export --export-release macOS "$stage/package/NoOneIsReal-macos.zip"
archive="$stage/package/NoOneIsReal-macos.zip"
[ -s "$archive" ] || fail 'Exporter produced no app archive.'
manifest="$stage/package/manifest.json"
plutil -create xml1 "$manifest"
plutil -insert schema -integer 1 "$manifest"
plutil -insert revision -string "$revision" "$manifest"
plutil -insert sha256 -string "$(shasum -a 256 "$archive" | awk '{print $1}')" "$manifest"
plutil -insert size -integer "$(stat -f '%z' "$archive")" "$manifest"
plutil -convert json "$manifest"
printf 'Installing the locally built app and enabling future main updates.\n'
/bin/bash "$stage/package/update-macos.sh" --install
