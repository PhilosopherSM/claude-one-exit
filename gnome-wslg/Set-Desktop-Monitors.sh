#!/bin/bash
set -euo pipefail
test "$EUID" = 0
base=$(dirname "$(realpath "$0")")
backup=/var/backups/wslg-ubuntu-desktop
test -f "$backup/original-target"
test -x /usr/bin/Xorg.distrib
read -r user home < <(getent passwd 1000 | awk -F: '{print $1, $6}')
test -n "$user" && test -d "$home"
group=$(id -gn "$user")
test ! -e "$home/.config/monitors.xml" && test ! -L "$home/.config/monitors.xml"

systemctl stop gdm.service
install -m 0755 "$base/Xorg-wslg-fullscreen" /usr/bin/Xorg
if [ -f /var/lib/gdm3/.config/monitors.xml ]; then
    cp -an /var/lib/gdm3/.config/monitors.xml "$backup/gdm-monitors.before-16-10.xml"
fi
install -d -m 0700 -o gdm -g gdm /var/lib/gdm3/.config
install -m 0600 -o gdm -g gdm "$base/monitors.xml" /var/lib/gdm3/.config/monitors.xml
runuser -u "$user" -- mkdir -p "$home/.config"
install -m 0600 -o "$user" -g "$group" "$base/monitors.xml" "$home/.config/monitors.xml"
printf '%s\n' "$home/.config/monitors.xml" > "$backup/user-monitor-path"
