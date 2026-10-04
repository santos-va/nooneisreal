#!/bin/bash
# macOS 12+ stock tools only. The updater never changes Godot user:// save data.
set -euo pipefail
PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PATH
REPOSITORY="santos-va/nooneisreal"
APP_NAME="No One Is Real.app"
BUNDLE_ID="com.santos.nooneisreal"
APP="/Applications/$APP_NAME"
STATE_DIR="$HOME/Library/Application Support/No One Is Real/Updater"
AGENT="$HOME/Library/LaunchAgents/com.santos.nooneisreal.update.plist"
LABEL="com.santos.nooneisreal.update"
STAGE=""
LOCK=""
BACKUP=""
REPLACING=false

log() { printf '%s %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*"; }
fail() { log "ERROR: $*" >&2; exit 1; }
cleanup() {
    if $REPLACING && [ ! -e "$APP" ] && [ -n "$BACKUP" ] && [ -e "$BACKUP" ]; then
        if ! mv -- "$BACKUP" "$APP"; then
            log "ERROR: automatic restoration failed. Prior app: $BACKUP; staged build: $STAGE" >&2
            STAGE="" # Keep verified stage for manual recovery; never discard both copies.
        fi
    fi
    [ -z "$STAGE" ] || rm -rf -- "$STAGE"
    [ -z "$LOCK" ] || rm -rf -- "$LOCK"
}
field() { plutil -extract "$2" raw -o - "$1"; }
bundle_field() { /usr/libexec/PlistBuddy -c "Print:$2" "$1/Contents/Info.plist"; }
running() { pgrep -x 'No One Is Real' >/dev/null 2>&1; }
fetch() {
    local limit="${3:-2000000000}"
    # curl rejects oversized advertised bodies; RLIMIT_FSIZE also caps bodies
    # without Content-Length on stock macOS curl. Use a conservative block cap.
    (ulimit -f "$((limit / 1024 + 1))"
     curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
        --max-filesize "$limit" --connect-timeout 20 --max-time 900 --retry 3 --output "$2" "$1")
}
# Validate every archive member before ditto sees it. Exported Godot bundles do not
# need symlinks; rejecting them also prevents links redirecting later zip entries.
validate_archive() {
    local archive="$1" names="$2" entry mode
    zipinfo -1 "$archive" > "$names" || return 1
    [ -s "$names" ] || return 1
    while IFS= read -r entry; do
        case "$entry" in
            "$APP_NAME"|"$APP_NAME/"*) ;;
            *) log "Archive member outside app: $entry" >&2; return 1 ;;
        esac
        case "/$entry/" in
            *'/../'*|*'/./'*|*'//'*)
                # A single trailing slash is normal for directory records.
                case "$entry" in */) entry=${entry%/} ;; esac
                case "/$entry/" in *'/../'*|*'/./'*|*'//'*) return 1 ;; esac ;;
        esac
        case "$entry" in *\\*|*:*|*\^*|*$'\r'*|*$'\t'*) return 1 ;; esac
    done < "$names"
    LC_ALL=C zipinfo -l "$archive" > "$names.details" || return 1
    if LC_ALL=C grep -E '^[lbcps][rwxstST-]{9}[[:space:]]' "$names.details" > /dev/null; then return 1; fi
    return 0
}
check_bundle() {
    local bundle="$1" revision="$2"
    [ ! -L "$bundle" ] && [ -d "$bundle" ] || return 1
    [ "$(bundle_field "$bundle" CFBundleIdentifier)" = "$BUNDLE_ID" ] || return 1
    [ "$(bundle_field "$bundle" CFBundleExecutable)" = 'No One Is Real' ] || return 1
    [ "$(bundle_field "$bundle" NIRBuildRevision)" = "$revision" ] || return 1
    [ -x "$bundle/Contents/MacOS/No One Is Real" ] || return 1
    codesign --verify --deep --strict "$bundle" || return 1
    lipo -archs "$bundle/Contents/MacOS/No One Is Real" | grep -w arm64 > /dev/null || return 1
}
update() {
    [ "$(uname -s)" = Darwin ] || fail 'This installer requires macOS.'
    [ ! -L "$STATE_DIR" ] || fail 'Updater directory must not be a symlink.'
    mkdir -p "$STATE_DIR"
    chmod 700 "$STATE_DIR"
    local lock_path="$STATE_DIR/lock" old_pid
    if ! mkdir "$lock_path" 2>/dev/null; then
        old_pid=$(cat "$lock_path/pid" 2>/dev/null || true)
        case "$old_pid" in
            ''|*[!0-9]*)
                local modified now
                modified=$(stat -f '%m' "$lock_path")
                now=$(date +%s)
                if [ "$((now - modified))" -lt 300 ]; then log 'Another updater is starting; deferred.'; return 0; fi ;;
            *) if kill -0 "$old_pid" 2>/dev/null; then log 'Updater already running.'; return 0; fi ;;
        esac
        rm -rf -- "$lock_path"
        mkdir "$lock_path" || return 0
    fi
    LOCK="$lock_path"
    printf '%s\n' "$$" > "$LOCK/pid"
    trap cleanup EXIT
    trap 'exit 130' INT TERM HUP
    if running; then log 'Game is running; update deferred until a later check.'; return 0; fi
    local app_parent="${APP%/*}"
    [ -w "$app_parent" ] || fail '/Applications is not writable. Ask an administrator to grant your account write access; no app was changed.'
    [ ! -L "$APP" ] || fail 'Installed app must not be a symlink.'
    if [ -e "$APP" ]; then
        [ "$(bundle_field "$APP" CFBundleIdentifier)" = "$BUNDLE_ID" ] || fail 'A different app already uses this name; refusing to replace it.'
    fi
    BACKUP="$app_parent/.No One Is Real.previous.app"
    if [ ! -e "$APP" ] && [ -e "$BACKUP" ]; then
        [ ! -L "$BACKUP" ] && [ "$(bundle_field "$BACKUP" CFBundleIdentifier)" = "$BUNDLE_ID" ] || fail 'Unexpected recovery backup.'
        mv -- "$BACKUP" "$APP" || fail 'Could not restore the interrupted update.'
    fi
    STAGE=$(mktemp -d "$app_parent/.nooneisreal-update.XXXXXX")
    local manifest="$STAGE/manifest.json" revision checksum expected_size current actual_size archive
    local offline_dir="${1:-}"
    if [ -n "$offline_dir" ]; then
        cp -- "$offline_dir/manifest.json" "$manifest"
    else
        fetch "https://github.com/$REPOSITORY/releases/download/macos-main/manifest.json" "$manifest" 1048576
    fi
    [ "$(field "$manifest" schema)" = 1 ] || fail 'Unsupported update manifest.'
    revision=$(field "$manifest" revision)
    checksum=$(field "$manifest" sha256)
    expected_size=$(field "$manifest" size)
    [[ "$revision" =~ ^[0-9a-f]{40}$ ]] || fail 'Invalid build revision.'
    [[ "$checksum" =~ ^[0-9a-f]{64}$ ]] || fail 'Invalid SHA-256.'
    [[ "$expected_size" =~ ^[0-9]{1,10}$ ]] || fail 'Invalid archive size.'
    [ "$expected_size" -gt 0 ] && [ "$expected_size" -le 2000000000 ] || fail 'Archive exceeds supported size.'
    current=$(bundle_field "$APP" NIRBuildRevision 2>/dev/null || true)
    if [ "$current" = "$revision" ]; then log "Already current: $revision"; return 0; fi
    archive="$STAGE/app.zip"
    if [ -n "$offline_dir" ]; then
        cp -- "$offline_dir/NoOneIsReal-macos.zip" "$archive"
    else
        fetch "https://github.com/$REPOSITORY/releases/download/macos-$revision/NoOneIsReal-macos.zip" "$archive"
    fi
    actual_size=$(stat -f '%z' "$archive")
    [ "$actual_size" = "$expected_size" ] || fail 'Archive size mismatch; current app preserved.'
    [ "$(shasum -a 256 "$archive" | awk '{print $1}')" = "$checksum" ] || fail 'Checksum mismatch; current app preserved.'
    validate_archive "$archive" "$STAGE/members.txt" || fail 'Unsafe or invalid ZIP; current app preserved.'
    mkdir "$STAGE/extracted"
    ditto -x -k "$archive" "$STAGE/extracted"
    local incoming="$STAGE/extracted/$APP_NAME" backup="$BACKUP"
    check_bundle "$incoming" "$revision" || fail 'Bundle identity, signature, architecture or build marker is invalid.'
    if running; then log 'Game started during download; replacement deferred.'; return 0; fi
    # Do not recursively clear Gatekeeper quarantine or disable system protections.
    # curl/ditto installation uses the verified ad-hoc-signed developer build as-is.
    if [ -e "$backup" ]; then
        [ ! -L "$backup" ] && [ "$(bundle_field "$backup" CFBundleIdentifier)" = "$BUNDLE_ID" ] || fail 'Unexpected backup path.'
        rm -rf -- "$backup"
    fi
    REPLACING=true
    if [ -e "$APP" ]; then mv -- "$APP" "$backup"; fi
    if ! mv -- "$incoming" "$APP"; then
        [ ! -e "$backup" ] || mv -- "$backup" "$APP"
        fail 'Replacement failed; prior app restored.'
    fi
    REPLACING=false
    log "Installed $revision at $APP. Save data was not touched."
}
install_agent() {
    local script_dir installer_copy
    script_dir=$(cd -- "$(dirname -- "$0")" && pwd)
    if [ -f "$script_dir/manifest.json" ] && [ -f "$script_dir/NoOneIsReal-macos.zip" ]; then
        update "$script_dir"
    else
        update
    fi
    # If a running game prevented first install, do not report an absent app as installed.
    [ -d "$APP" ] || fail 'Quit the game and run Install.command again.'
    installer_copy="$STATE_DIR/update-macos.sh"
    if [ "$script_dir/update-macos.sh" != "$installer_copy" ]; then
        cp -- "$script_dir/update-macos.sh" "$installer_copy.tmp"
        chmod 700 "$installer_copy.tmp"
        mv -- "$installer_copy.tmp" "$installer_copy"
    fi
    chmod 700 "$installer_copy"
    mkdir -p "$HOME/Library/LaunchAgents"
    # plutil builds XML safely even when HOME contains spaces or XML characters.
    rm -f -- "$AGENT.tmp"
    plutil -create xml1 "$AGENT.tmp"
    plutil -insert Label -string "$LABEL" "$AGENT.tmp"
    plutil -insert ProgramArguments -json '["/bin/bash"]' "$AGENT.tmp"
    plutil -insert ProgramArguments.1 -string "$installer_copy" "$AGENT.tmp"
    plutil -insert RunAtLoad -bool YES "$AGENT.tmp"
    plutil -insert StartInterval -integer 900 "$AGENT.tmp"
    plutil -insert ProcessType -string Background "$AGENT.tmp"
    plutil -insert StandardOutPath -string "$STATE_DIR/update.log" "$AGENT.tmp"
    plutil -insert StandardErrorPath -string "$STATE_DIR/update-error.log" "$AGENT.tmp"
    chmod 600 "$AGENT.tmp"
    mv -- "$AGENT.tmp" "$AGENT"
    launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$AGENT"
    log 'Automatic main updates enabled at login and every 15 minutes, while the game is closed.'
    log "Installed revision: $(bundle_field "$APP" NIRBuildRevision)"
    log "Updater logs: $STATE_DIR/update.log and update-error.log"
    open "$APP"
}
main() {
    case "${1:-}" in
        --install) install_agent ;;
        --validate-archive) validate_archive "$2" "$3" ;;
        '') update ;;
        *) fail 'Usage: update-macos.sh [--install]' ;;
    esac
}
if [ "${BASH_SOURCE[0]}" = "$0" ]; then main "$@"; fi
