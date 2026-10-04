#!/bin/bash
set -euo pipefail
cd -- "$(dirname -- "$0")"
printf 'Installing No One Is Real in /Applications and enabling updates from the public main release.\n'
if /bin/bash ./update-macos.sh --install; then
    printf '\nInstalled. Future updates wait until the game is closed.\n'
else
    printf '\nInstallation or updater setup stopped. Save data was not changed; see the error above.\n' >&2
    read -r -p 'Press Return to close. ' unused
    exit 1
fi
