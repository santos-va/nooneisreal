#!/bin/bash
cd -- "$(dirname -- "$0")" || exit 1
printf 'Checking installed and published builds. This does not install anything.\n'
/bin/bash ./update-macos.sh --status
result=$?
printf '\nPress Return to close.\n'
read -r _
exit "$result"
