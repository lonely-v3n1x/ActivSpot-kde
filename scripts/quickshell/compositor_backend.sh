#!/usr/bin/env bash

set -u

detect_backend() {
    if command -v hyprctl >/dev/null 2>&1 && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        echo "hyprland"
        return
    fi
    if command -v qdbus >/dev/null 2>&1 && qdbus org.kde.KWin /KWin >/dev/null 2>&1; then
        echo "kde"
        return
    fi
    echo "generic"
}

kb_layout_hypr() {
    hyprctl devices -j 2>/dev/null | jq -r '(.keyboards[] | select(.main == true) | .active_keymap) // .keyboards[0].active_keymap // empty' | head -n1
}

kb_layout_kde() {
    local layout
    layout="$(qdbus org.kde.keyboard /Layouts getLayoutName 2>/dev/null || true)"
    if [ -z "$layout" ]; then
        layout="$(qdbus org.kde.keyboard /Layouts org.kde.KeyboardLayouts.getLayoutName 2>/dev/null || true)"
    fi
    if [ -z "$layout" ]; then
        layout="$(qdbus org.kde.keyboard /Layouts layoutName 2>/dev/null || true)"
    fi
    printf '%s\n' "$layout"
}

normalize_layout() {
    local layout="$1"
    [ -z "$layout" ] && layout="US"
    printf '%s\n' "$layout" | cut -c1-2 | tr '[:lower:]' '[:upper:]'
}

get_keyboard_layout() {
    local backend layout
    backend="$(detect_backend)"
    case "$backend" in
        hyprland) layout="$(kb_layout_hypr)" ;;
        kde)      layout="$(kb_layout_kde)" ;;
        *)        layout="" ;;
    esac
    normalize_layout "$layout"
}

wait_keyboard_change() {
    local backend="$1"
    case "$backend" in
        hyprland)
            if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
                local sock="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
                socat -U - "UNIX-CONNECT:$sock" 2>/dev/null | grep --line-buffered "activelayout>>"
                return
            fi
            ;;
    esac
    sleep 1
}

switch_keyboard_next() {
    local backend
    backend="$(detect_backend)"
    case "$backend" in
        hyprland)
            hyprctl switchxkblayout main next >/dev/null 2>&1
            ;;
        kde)
            qdbus org.kde.keyboard /Layouts switchToNextLayout >/dev/null 2>&1 || \
            qdbus org.kde.keyboard /Layouts org.kde.KeyboardLayouts.switchToNextLayout >/dev/null 2>&1 || true
            ;;
        *)
            true
            ;;
    esac
}

current_workspace() {
    local backend
    backend="$(detect_backend)"
    case "$backend" in
        hyprland)
            timeout 2 hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // 1'
            ;;
        kde)
            qdbus org.kde.KWin /KWin currentDesktop 2>/dev/null || echo 1
            ;;
        *)
            echo 1
            ;;
    esac
}

workspace_count() {
    local backend
    backend="$(detect_backend)"
    case "$backend" in
        hyprland)
            timeout 2 hyprctl workspaces -j 2>/dev/null | jq -r 'length // 8'
            ;;
        kde)
            qdbus org.kde.KWin /KWin numberOfDesktops 2>/dev/null || echo 8
            ;;
        *)
            echo 8
            ;;
    esac
}

switch_workspace() {
    local ws="$1"
    local backend
    backend="$(detect_backend)"
    case "$backend" in
        hyprland)
            hyprctl --batch "dispatch workspace $ws" >/dev/null 2>&1
            ;;
        kde)
            qdbus org.kde.KWin /KWin setCurrentDesktop "$ws" >/dev/null 2>&1 || true
            ;;
        *)
            true
            ;;
    esac
}

move_to_workspace() {
    local ws="$1"
    local backend
    backend="$(detect_backend)"
    case "$backend" in
        hyprland)
            hyprctl --batch "dispatch movetoworkspace $ws" >/dev/null 2>&1
            ;;
        kde|generic)
            switch_workspace "$ws"
            ;;
    esac
}

case "${1:-}" in
    detect_backend) detect_backend ;;
    get_keyboard_layout) get_keyboard_layout ;;
    wait_keyboard_change) wait_keyboard_change "$(detect_backend)" ;;
    switch_keyboard_next) switch_keyboard_next ;;
    current_workspace) current_workspace ;;
    workspace_count) workspace_count ;;
    switch_workspace) switch_workspace "${2:-1}" ;;
    move_to_workspace) move_to_workspace "${2:-1}" ;;
    *)
        echo "Usage: $0 {detect_backend|get_keyboard_layout|wait_keyboard_change|switch_keyboard_next|current_workspace|workspace_count|switch_workspace N|move_to_workspace N}" >&2
        exit 1
        ;;
esac
