#!/bin/bash
set -euo pipefail

base=$(dirname "$(realpath "$0")")
: "${XDG_RUNTIME_DIR:?Start this from your Ubuntu WSL session}"
unit=ubuntu-wslg-wayland.service
shell_unit=org.gnome.Shell@wayland.service
if systemctl --user is-active --quiet "$unit" && systemctl --user is-active --quiet "$shell_unit"; then
    exit 0
fi

# Closing the outer WSLg window can leave the session manager running without a shell.
if systemctl --user is-active --quiet "$unit"; then
    systemctl --user stop "$unit"
fi

dropin=$XDG_RUNTIME_DIR/systemd/user/org.gnome.Shell@wayland.service.d
bash "$base/Prepare-Gnome-Display.sh"
bash "$base/Prepare-Nested-Cursor.sh"
if command -v ibus-daemon >/dev/null && [ -r /usr/share/rime-data/double_pinyin_flypy.schema.yaml ]; then
    bash "$base/Configure-Rime.sh"
fi
install -D -m 0644 "$base/gnome-shell-wayland.conf" "$dropin/80-wslg-nested.conf"
systemctl --user daemon-reload
systemd-run --user --unit="$unit" --collect --setenv=DISPLAY=:0 \
    --setenv=WAYLAND_DISPLAY=wayland-0 --setenv="XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR" \
    --setenv=DESKTOP_SESSION=ubuntu --setenv=GDMSESSION=ubuntu \
    --setenv=GNOME_SHELL_SESSION_MODE=ubuntu --setenv=XDG_SESSION_TYPE=wayland \
    --setenv=XDG_CURRENT_DESKTOP=ubuntu:GNOME --setenv=XDG_SESSION_DESKTOP=ubuntu \
    --setenv=XDG_DATA_DIRS=/usr/share/ubuntu:/usr/local/share:/usr/share \
    --setenv=MUTTER_DEBUG_DUMMY_MODE_SPECS=1408x880 \
    --setenv=LANG=C.UTF-8 --setenv=LANGUAGE=en_US:en --setenv=TZ=America/Chicago \
    /usr/bin/gnome-session.distrib --session=ubuntu

for attempt in {1..30}; do
    if systemctl --user is-active --quiet "$unit" && systemctl --user is-active --quiet "$shell_unit"; then
        exit 0
    fi
    sleep 1
done

printf '%s\n' 'Ubuntu session did not start GNOME Shell.' >&2
journalctl --user -u "$unit" -u "$shell_unit" -n 12 --no-pager >&2
exit 1
