#!/bin/bash
set -euo pipefail

app=${1:?Specify claude, firefox, terminal, files or prepare}
case "$app" in
    claude) command=(claude-desktop --ozone-platform=wayland --disable-setuid-sandbox) ;;
    firefox) command=(firefox-esr --new-window about:blank) ;;
    files) command=(thunar .) ;;
    terminal|prepare) ;;
    *) exit 2 ;;
esac
check=false
wslg=false
start_args=()
for option in "${@:2}"; do
    case "$option" in
        --check) check=true ;;
        --wslg) wslg=true ;;
        --apply) [[ "$app" == prepare ]] || exit 2; start_args=(--apply) ;;
        *) printf 'Unknown option: %s\n' "$option" >&2; exit 2 ;;
    esac
done

if [[ "$app" = claude || "$app" = firefox || "$app" = files ]] && ! "$check"; then
    trap 'rc=$?; if ((rc != 0)); then zenity --error --title="Docker App Launcher" --text="Could not start the app. Check Docker Desktop, the persistent storage mounts, and the Apple TV exit node." || true; fi; exit "$rc"' EXIT
fi
if [ "$app" = terminal ] && ! "$check" && [ -t 0 ]; then
    trap 'rc=$?; if ((rc != 0)); then read -r -p "Could not open the Docker terminal. Press Enter to close. " _ || true; fi; exit "$rc"' EXIT
fi

launcher_dir=$(dirname "$(realpath "$0")")
socket=/var/run/docker.sock
if [ ! -S "$socket" ] || { [ -w "$socket" ] && ! docker info >/dev/null 2>&1; }; then
    ps=/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe
    "$ps" -NoProfile -File "$(wslpath -w "$launcher_dir/Ensure-Docker-Desktop.ps1")"
    for attempt in {1..30}; do
        if [ -S "$socket" ] && command -v docker >/dev/null; then break; fi
        sleep 1
    done
fi
if [ ! -w "$socket" ]; then
    if [ "${DOCKER_APP_GROUP_REFRESHED:-0}" = 1 ] || [ "$(stat -Lc '%G' "$socket" 2>/dev/null || true)" != docker ] || ! id -Gn "$(id -un)" | tr ' ' '\n' | grep -Fxq docker; then
        printf '%s\n' 'Cannot access the Docker socket with the current account.' >&2
        exit 1
    fi
    # The GNOME user manager may predate this user's Docker group membership.
    printf -v launch '%q ' /usr/bin/env DOCKER_APP_GROUP_REFRESHED=1 /usr/bin/bash "$(realpath "$0")" "$@"
    exec /usr/bin/sg docker -c "$launch"
fi

base=$launcher_dir/../hk-tailscale
node_file=$base/exit-node.local
if [[ ! -s "$node_file" ]]; then
    printf 'Configure the expected exit node in %s before launching.\n' "$node_file" >&2
    exit 1
fi
expected_node=$(cat "$node_file")
gateway=hk-tailscale-tailscale-1
browser=hk-browser-session-browser-1
docker compose -f "$base/compose.yaml" up -d --no-deps --no-build --no-recreate --wait --wait-timeout 40 tailscale

check_exit() {
    docker exec "$gateway" tailscale status --json | python3 -c '
import ipaddress, json, sys
s = json.load(sys.stdin)
e = s.get("ExitNodeStatus") or {}
node = str(ipaddress.IPv4Address(sys.argv[1]))
sys.exit(not (s.get("BackendState") == "Running" and e.get("Online")
              and node + "/32" in e.get("TailscaleIPs", [])))' "$expected_node"
}
for attempt in {1..12}; do
    if check_exit; then break; fi
    if ((attempt == 12)); then printf '%s\n' 'The Apple TV exit node is not active.' >&2; exit 1; fi
    sleep 2
done

bash "$base/desktop/Start-Browser.sh" "${start_args[@]}"
gateway_ns=$(docker exec "$gateway" readlink /proc/self/ns/net)
browser_ns=$(docker exec "$browser" readlink /proc/self/ns/net)
test -n "$gateway_ns" && test "$gateway_ns" = "$browser_ns"
for attempt in {1..10}; do
    if docker exec "$browser" test -S /run/desktop/session-bus; then break; fi
    if ((attempt == 10)); then printf '%s\n' 'The application D-Bus socket is not ready.' >&2; exit 1; fi
    sleep 1
done
docker exec "$browser" curl -4 --noproxy '*' -fsS --max-time 10 -o /dev/null https://api.ipify.org/

display_args=()
if [ "${XDG_SESSION_TYPE:-}" = x11 ] && ! docker exec "$browser" test -S /display/gnome/wayland; then
    wslg=true
fi
if "$wslg" && [[ "$app" = claude || "$app" = firefox || "$app" = files ]]; then
    docker exec "$browser" test -S /display/wayland-0
    display_args=(-e WAYLAND_DISPLAY=/display/wayland-0 -e GTK_IM_MODULE=)
elif [ "$app" = claude ] && [ "$(docker exec "$browser" printenv WAYLAND_DISPLAY)" = /display/gnome/wayland ]; then
    command+=(--enable-wayland-ime --wayland-text-input-version=3)
fi

if [[ "$app" != terminal && "$app" != prepare ]]; then
    docker exec "$browser" sh -ec 'command -v "$1" >/dev/null' sh "${command[0]}" ||
        { printf '%s is missing. Add its package in workbench.local.toml and rerun Setup.cmd.\n' "${command[0]}" >&2; exit 1; }
fi
if "$check" || [ "$app" = prepare ]; then exit 0; fi
if [ "$app" = terminal ]; then
    docker exec -it "$browser" /bin/bash
    exit
fi
if [ "$app" = firefox ]; then
    docker exec -d "${display_args[@]}" "$browser" sh -c 'exec "$@" > /tmp/wslg-firefox-launch.log 2>&1' sh "${command[@]}"
else
    exec docker exec -d "${display_args[@]}" "$browser" "${command[@]}"
fi
