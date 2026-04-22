#!/usr/bin/env bash
set -euo pipefail

missing=()
required_cmds=(
    quickshell
    inotifywait
    jq
    playerctl
    qdbus
)

for cmd in "${required_cmds[@]}"; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done

if [ "${#missing[@]}" -gt 0 ]; then
    echo "Missing dependencies: ${missing[*]}" >&2
    echo "Install them before running ActivSpot-kde on Plasma." >&2
    exit 1
fi

echo "Dependency check passed."
