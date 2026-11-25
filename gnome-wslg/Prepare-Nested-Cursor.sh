#!/bin/bash
set -euo pipefail

base=$(dirname "$(realpath "$0")")
: "${XDG_RUNTIME_DIR:?Start this from your Ubuntu WSL session}"
root=$XDG_RUNTIME_DIR/wslg-gnome-cursor
theme=$(gsettings get org.gnome.desktop.interface cursor-theme | tr -d "'")
case "$theme" in ''|*[^a-zA-Z0-9_-]*) exit 1 ;; esac
source=/usr/share/icons/$theme/cursors
test -d "$source"
mkdir -p "$root/$theme/cursors" "$root/default/cursors"
gdk-pixbuf-thumbnailer -s 32 "$base/transparent-cursor.svg" "$root/transparent.png"
printf '32 0 0 %s\n' "$root/transparent.png" | xcursorgen - "$root/transparent.cursor"

for old in "$source"/*; do
    name=${old##*/}
    ln -sfn "$root/transparent.cursor" "$root/$theme/cursors/$name"
    ln -sfn "$root/transparent.cursor" "$root/default/cursors/$name"
done
test -e "$root/$theme/cursors/left_ptr"
