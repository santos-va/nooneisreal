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
package_ready=false
cleanup_local_install() {
    local status=$? recovery
    if [ "$status" -ne 0 ] && $package_ready && [ -s "$stage/package/manifest.json" ] && [ -s "$stage/package/NoOneIsReal-macos.zip" ]; then
        recovery=$(mktemp -d /tmp/nir-completed-package.XXXXXX)
        if mv "$stage/package" "$recovery/package"; then
            printf 'Completed package retained for installation retry: %s/package\n' "$recovery" >&2
        fi
    fi
    rm -rf -- "$stage"
}
trap cleanup_local_install EXIT
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
    local name="$1" expected actual cached cache_dir cache_tmp
    [ -f "$stage/SHA512-SUMS.txt" ] || fetch "$base/SHA512-SUMS.txt" "$stage/SHA512-SUMS.txt"
    expected=$(awk -v name="$name" '$2==name || $2=="*"name {print $1}' "$stage/SHA512-SUMS.txt")
    [[ "$expected" =~ ^[0-9a-fA-F]{128}$ ]] || fail "Missing official checksum for $name"
    cache_dir="$HOME/Library/Caches/No One Is Real/Installer/4.7-stable"
    [ ! -L "$HOME/Library/Caches/No One Is Real" ] && [ ! -L "${cache_dir%/*}" ] && [ ! -L "$cache_dir" ] || fail 'Installer cache must not be a symlink.'
    mkdir -p "$cache_dir"
    cached="$cache_dir/$name"
    [ ! -L "$cached" ] || fail 'Cached download must not be a symlink.'
    if [ -f "$cached" ]; then
        actual=$(/usr/bin/shasum -a 512 "$cached" | /usr/bin/awk '{print $1}')
        if [ "$actual" = "$expected" ]; then
            printf 'Reusing SHA512-verified cached download: %s\n' "$name"
            cp "$cached" "$stage/$name"
            return
        fi
    fi
    fetch "$base/$name" "$stage/$name"
    actual=$(/usr/bin/shasum -a 512 "$stage/$name" | /usr/bin/awk '{print $1}')
    [ "$actual" = "$expected" ] || fail "Official SHA512 mismatch: $name"
    cache_tmp=$(mktemp "$cache_dir/.download.XXXXXX")
    cp "$stage/$name" "$cache_tmp"
    mv "$cache_tmp" "$cached"
}
# Probe candidates before selection; an old GODOT_BIN must not block installation.
probe_godot() {
    local candidate="$1" output
    probe_version='not executable'
    [ -n "$candidate" ] && [ -x "$candidate" ] || return 1
    if ! output=$("$candidate" --headless --version 2>&1); then
        probe_version="probe failed: ${output:-no output}"
        return 1
    fi
    probe_version=$(printf '%s\n' "$output" | tr -d '\r' | awk '/^4\.7\.stable(\.[A-Za-z0-9_-]+)*$/ {print; exit}')
    if [ -z "$probe_version" ]; then probe_version="${output:-no output}"; return 1; fi
}
godot_bin=''
for candidate in "${GODOT_BIN:-}" /Applications/Godot.app/Contents/MacOS/Godot "$(command -v godot || true)"; do
    [ -n "$candidate" ] || continue
    case "$candidate" in */*) ;; *) candidate=$(command -v "$candidate" || printf '%s' "$candidate") ;; esac
    if probe_godot "$candidate"; then godot_bin="$candidate"; break; fi
    printf 'Skipping Godot candidate %s: %s\n' "$candidate" "$probe_version"
done
if [ -z "$godot_bin" ]; then
    printf 'Downloading official Godot 4.7 editor for this temporary build.\n'
    verified_download Godot_v4.7-stable_macos.universal.zip
    mkdir "$stage/editor"
    /usr/bin/ditto -x -k "$stage/Godot_v4.7-stable_macos.universal.zip" "$stage/editor"
    godot_bin="$stage/editor/Godot.app/Contents/MacOS/Godot"
    probe_godot "$godot_bin" || fail "Downloaded Godot is incompatible at $godot_bin: $probe_version"
fi
printf 'Using Godot %s at %s\n' "$probe_version" "$godot_bin"
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
# BSD stat is required; Homebrew GNU coreutils may precede system tools in PATH.
archive_size=$(/usr/bin/stat -f '%z' "$archive") || fail 'Cannot determine exported archive size with native macOS stat.'
[[ "$archive_size" =~ ^[1-9][0-9]{0,9}$ ]] || fail "Invalid archive size: $archive_size"
[ "$archive_size" -le 2000000000 ] || fail "Archive exceeds supported size: $archive_size"
archive_hash=$(/usr/bin/shasum -a 256 "$archive" | /usr/bin/awk '{print $1}') || fail 'Cannot hash exported archive.'
[[ "$archive_hash" =~ ^[0-9a-f]{64}$ ]] || fail 'Invalid archive SHA256.'
manifest="$stage/package/manifest.json"
/usr/bin/plutil -create xml1 "$manifest"
/usr/bin/plutil -insert schema -integer 1 "$manifest"
/usr/bin/plutil -insert revision -string "$revision" "$manifest"
/usr/bin/plutil -insert sha256 -string "$archive_hash" "$manifest"
/usr/bin/plutil -insert size -integer "$archive_size" "$manifest"
/usr/bin/plutil -convert json "$manifest"
package_ready=true
printf 'Installing the locally built app and enabling future main updates.\n'
/bin/bash "$stage/package/update-macos.sh" --install
