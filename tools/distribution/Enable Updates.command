#!/bin/bash
set -euo pipefail
cd -- "$(dirname -- "$0")"
printf 'Enabling incremental main updates for the installed No One Is Real app.\n'
if /bin/bash ./update-macos.sh --enable-updates; then
    printf '\nEnabled. New verified main builds download changed blocks after the game closes.\n'
else
    printf '\nUpdater setup stopped; see the error above.\n' >&2
    read -r -p 'Press Return to close. ' unused
    exit 1
fi
