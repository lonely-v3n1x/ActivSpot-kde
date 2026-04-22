#!/usr/bin/env bash
BACKEND_HELPER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/compositor_backend.sh"

# ============================================================================
# 1. ZOMBIE PREVENTION
# Kills any older instances of this script. When Quickshell reloads, 
# it can leave the old listener pipelines running in the background infinitely.
# ============================================================================
for pid in $(pgrep -f "quickshell/workspaces.sh"); do
    if [ "$pid" != "$$" ] && [ "$pid" != "$PPID" ]; then
        kill -9 "$pid" 2>/dev/null
    fi
done

# Cleanly kill immediate children (like socat) when the script exits normally
cleanup() {
    pkill -P $$ 2>/dev/null
}
trap cleanup EXIT SIGTERM SIGINT

# --- Special Cleanup for Network/Bluetooth ---
# The network toggle starts a background bluetooth scan that must be killed explicitly.
BT_PID_FILE="$HOME/.cache/bt_scan_pid"

if [ -f "$BT_PID_FILE" ]; then
    kill $(cat "$BT_PID_FILE") 2>/dev/null
    rm -f "$BT_PID_FILE"
fi

# Ensure bluetooth scan is explicitly turned off (timeout prevents deadlocks on fresh installs)
(timeout 2 bluetoothctl scan off > /dev/null 2>&1) &
# ---------------------------------------------

# Configuration fallback: How many workspaces do you want to show?
SEQ_END=8

print_workspaces() {
    local backend active end
    backend="$("$BACKEND_HELPER" detect_backend)"
    active="$("$BACKEND_HELPER" current_workspace 2>/dev/null)"
    end="$("$BACKEND_HELPER" workspace_count 2>/dev/null)"

    [[ "$active" =~ ^[0-9]+$ ]] || active=1
    [[ "$end" =~ ^[0-9]+$ ]] || end="$SEQ_END"
    (( end < 1 )) && end=1
    (( end > 12 )) && end=12

    if [ "$backend" = "hyprland" ]; then
        local spaces
        spaces=$(timeout 2 hyprctl workspaces -j 2>/dev/null)
        if [ -z "$spaces" ]; then return; fi
        echo "$spaces" | jq --unbuffered --argjson a "$active" --arg end "$end" -c '
            (map( { (.id|tostring): . } ) | add) as $s
            |
            [range(1; ($end|tonumber) + 1)] | map(
                . as $i |
                (if $i == $a then "active"
                 elif ($s[$i|tostring] != null and $s[$i|tostring].windows > 0) then "occupied"
                 else "empty" end) as $state |
                (if $s[$i|tostring] != null then $s[$i|tostring].lastwindowtitle else "Workspace \($i)" end) as $win |
                { id: $i, state: $state, tooltip: $win }
            )
        ' > /tmp/qs_workspaces.tmp
    else
        jq -n --argjson a "$active" --arg end "$end" -c '
            [range(1; ($end|tonumber) + 1)] | map(
                . as $i |
                { id: $i, state: (if $i == $a then "active" else "empty" end), tooltip: "Workspace \($i)" }
            )
        ' > /tmp/qs_workspaces.tmp
    fi

    mv /tmp/qs_workspaces.tmp /tmp/qs_workspaces.json
}

# Print initial state
print_workspaces

if [ "$("$BACKEND_HELPER" detect_backend)" = "hyprland" ] && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    while true; do
        socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r line; do
            case "$line" in
                workspace*|focusedmon*|activewindow*|createwindow*|closewindow*|movewindow*|destroyworkspace*)
                    while read -t 0.05 -r _; do continue; done
                    print_workspaces
                    ;;
            esac
        done
        sleep 1
    done
else
    while true; do
        sleep 1
        print_workspaces
    done
fi
