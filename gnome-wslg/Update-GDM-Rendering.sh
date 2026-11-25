#!/bin/bash
set -euo pipefail
base=$(dirname "$(realpath "$0")")
test -f /var/backups/wslg-ubuntu-desktop/original-target
test -x /usr/bin/Xorg.distrib
test -x /usr/bin/gnome-session.distrib

systemctl stop gdm.service
install -m 0755 "$base/Xorg-wslg-fullscreen" /usr/bin/Xorg
install -m 0755 "$base/gnome-session-wslg" /usr/bin/gnome-session
if [ ! -e /var/lib/gdm3/.config/monitors.xml ]; then
    install -d -m 0700 -o gdm -g gdm /var/lib/gdm3/.config
    install -m 0600 -o gdm -g gdm "$base/monitors.xml" /var/lib/gdm3/.config/monitors.xml
fi
systemctl start gdm.service
