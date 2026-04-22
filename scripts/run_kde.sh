#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$HOME/.config/hypr"

"$REPO_ROOT/scripts/check_kde_deps.sh"

mkdir -p "$CONFIG_DIR"
ln -sfn "$REPO_ROOT/scripts" "$CONFIG_DIR/scripts"
ln -sfn "$REPO_ROOT/settings.json" "$CONFIG_DIR/settings.json"

chmod +x "$REPO_ROOT/scripts/quickshell/compositor_backend.sh"
find "$REPO_ROOT/scripts" -type f -name "*.sh" -exec chmod +x {} \;

launch_qml() {
    local qml="$1"
    if ! pgrep -f "quickshell.*${qml##*/}" >/dev/null; then
        quickshell -p "$qml" >/dev/null 2>&1 &
        disown
    fi
}

launch_qml "$CONFIG_DIR/scripts/quickshell/Main.qml"
launch_qml "$CONFIG_DIR/scripts/quickshell/TopBar.qml"
launch_qml "$CONFIG_DIR/scripts/quickshell/DynamicIsland.qml"
launch_qml "$CONFIG_DIR/scripts/quickshell/AppLauncher.qml"
launch_qml "$CONFIG_DIR/scripts/quickshell/ClipboardViewer.qml"

echo "ActivSpot-kde launched for KDE Plasma."
