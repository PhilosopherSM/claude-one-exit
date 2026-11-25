#!/bin/bash
set -euo pipefail

base=$(dirname "$(realpath "$0")")
desktop=$(xdg-user-dir DESKTOP)
test "$desktop" != "$HOME" && test -d "$desktop"
data=${XDG_DATA_HOME:-$HOME/.local/share}
mkdir -p "$data/applications" "$data/icons/hicolor/128x128/apps"

install_entry() {
    local source=$1 target=$2 mode=$3
    if [ -e "$target" ] || [ -L "$target" ]; then
        test ! -L "$target" && cmp -s "$source" "$target" || {
            printf 'Existing shortcut was left untouched: %s\n' "$target" >&2
            exit 1
        }
    fi
    install -m "$mode" "$source" "$target"
}

container=hk-browser-session-browser-1
docker inspect -f '{{.State.Running}}' "$container" | grep -qx true
for app in claude firefox terminal files; do
    entry=$app-docker.desktop
    case "$app" in
        claude) exe=claude-desktop ;;
        firefox) exe=firefox-esr ;;
        files) exe=thunar ;;
        terminal) exe=bash ;;
    esac
    if ! docker exec "$container" sh -c 'command -v "$1" >/dev/null' sh "$exe"; then
        for path in "$data/applications/$entry" "$desktop/$entry"; do
            if [[ -f "$path" && ! -L "$path" ]] && cmp -s "$base/$entry" "$path"; then unlink "$path"; fi
        done
        continue
    fi
    desktop-file-validate "$base/$entry"
    install_entry "$base/$entry" "$data/applications/$entry" 0644
    install_entry "$base/$entry" "$desktop/$entry" 0755
    gio set -t string "$desktop/$entry" metadata::trusted true
done

icon_src=/usr/share/icons/hicolor/128x128/apps
icon_dst=$data/icons/hicolor/128x128/apps
if [ ! -e "$icon_dst/claude-docker.png" ] && docker exec "$container" test -f "$icon_src/claude-desktop.png"; then
    docker cp "$container:$icon_src/claude-desktop.png" "$icon_dst/claude-docker.png"
fi
if [ ! -e "$icon_dst/firefox-docker.png" ] && docker exec "$container" test -f "$icon_src/firefox-esr.png"; then
    docker cp "$container:$icon_src/firefox-esr.png" "$icon_dst/firefox-docker.png"
fi

gio info -a metadata::trusted "$desktop/terminal-docker.desktop"
