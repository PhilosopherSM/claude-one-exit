#!/bin/bash
set -euo pipefail

base=$(dirname "$(realpath "$0")")
if [[ -s "$base/../export-dir.local" ]]; then
    export WORKBENCH_EXPORT_DIR="$(cat "$base/../export-dir.local")"
fi
runtime=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
display_dir=${runtime%/}/gnome-docker-display
browser=hk-browser-session-browser-1
profile=$(mktemp --suffix=.json)
trap 'rm -f -- "$profile"' EXIT
python3 "$base/../../profile.py" > "$profile"
files=(-f "$base/compose.browser.yaml" -f "$profile"
       -f "$base/compose.home.yaml" -f "$base/compose.claude-profile.yaml")
if [ -S "$display_dir/wayland" ]; then
    export GNOME_WAYLAND_DIR="$display_dir"
    files+=(-f "$base/compose.ime.yaml")
fi

case "${1:-}" in
    --check) docker compose "${files[@]}" config --quiet; exit ;;
    --build) docker compose "${files[@]}" build browser; exit ;;
    --config) docker compose "${files[@]}" config; exit ;;
    --apply|'') ;;
    *) exit 2 ;;
esac
check_mounts() {
    local mounts expected
    mounts=$(docker inspect -f '{{range .Mounts}}{{.Destination}} {{.Type}} {{.Name}} {{.RW}}{{println}}{{end}}' "$browser")
    for expected in \
        '/home/node volume hk-browser-session_browser-home true' \
        '/home/node/.claude volume hk-browser-session_claude-code-home true' \
        '/home/node/.config/Claude volume hk-browser-session_claude-profile true' \
        '/workspace volume hk-browser-session_workspace true'; do
        if ! grep -Fxq -- "$expected" <<<"$mounts"; then
            printf 'Required browser mount is missing or incorrect: %s\n' "$expected" >&2
            return 1
        fi
    done
}

if docker container inspect "$browser" >/dev/null 2>&1; then
    check_mounts
fi
if [ "${1:-}" = --apply ] || [ "$(docker inspect -f '{{.State.Running}}' "$browser" 2>/dev/null || true)" != true ]; then
    # Docker can recreate a previous bind source as root when restarting the container.
    # A terminal or direct WSLg window does not need a nested compositor.
    # Keep Docker's unused, read-only bind source in place when GNOME is absent.
    if ! { [ -d "$display_dir" ] &&
            [ ! -L "$display_dir" ] && [ ! -e "$display_dir/wayland" ] &&
            [ "$(stat -c '%u:%a' "$display_dir")" = 0:755 ]; }; then
        bash "$base/../../gnome-wslg/Prepare-Gnome-Display.sh"
    fi
    reuse=(--no-recreate)
    if [ "${1:-}" = --apply ]; then reuse=(); fi
    docker compose "${files[@]}" up -d --no-build "${reuse[@]}" browser
fi
check_mounts
want=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["services"]["browser"]["labels"]["workbench.profile"])' "$profile")
actual=$(docker inspect -f '{{index .Config.Labels "workbench.profile"}}' "$browser")
if [[ "$actual" != "$want" && ( -n "$actual" || -e "$base/../../workbench.local.toml" ) ]]; then
    echo 'Profile changed. Save your work and rerun Setup.cmd to apply it.' >&2
    exit 1
fi
docker exec -u 1000:1000 "$browser" sh -ec '
    for dir in /home/node /home/node/.config /home/node/.claude /home/node/.config/Claude /workspace; do
        if ! test -d "$dir" || ! test -r "$dir" || ! test -w "$dir" || ! test -x "$dir"; then
            printf "Browser user cannot access %s\n" "$dir" >&2
            exit 1
        fi
    done
'
