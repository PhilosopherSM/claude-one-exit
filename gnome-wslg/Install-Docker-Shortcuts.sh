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

for app in claude firefox terminal files; do
    entry=$app-docker.desktop
    desktop-file-validate "$base/$entry"
    install_entry "$base/$entry" "$data/applications/$entry" 0644
    install_entry "$base/$entry" "$desktop/$entry" 0755
    gio set -t string "$desktop/$entry" metadata::trusted true
done

container=hk-browser-session-browser-1
icon_src=/usr/share/icons/hicolor/128x128/apps
icon_dst=$data/icons/hicolor/128x128/apps
if [ ! -e "$icon_dst/claude-docker.png" ]; then
    docker cp "$container:$icon_src/claude-desktop.png" "$icon_dst/claude-docker.png"
fi
if [ ! -e "$icon_dst/firefox-docker.png" ]; then
    docker cp "$container:$icon_src/firefox-esr.png" "$icon_dst/firefox-docker.png"
fi

gio info -a metadata::trusted "$desktop/claude-docker.desktop" "$desktop/firefox-docker.desktop" "$desktop/terminal-docker.desktop" "$desktop/files-docker.desktop"
