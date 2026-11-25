#!/bin/bash
set -euo pipefail
test "$EUID" = 0
base=$(dirname "$(realpath "$0")")
backup=/var/backups/wslg-ubuntu-desktop
test ! -e "$backup/original-target"
test -z "$(dpkg-divert --list /usr/bin/Xorg)"
test -z "$(dpkg-divert --list /usr/bin/gnome-session)"
test ! -e /etc/systemd/user/wslg-session.service
test ! -e /etc/systemd/system/gdm.service.d/80-wslg.conf
test ! -e /etc/systemd/system/wslg-ubuntu-desktop-x11.service
test ! -e /usr/local/libexec/wslg-x11-directory
test -x /usr/bin/Xorg
test -x /usr/bin/Xwayland
grep -q '^\[daemon\][[:space:]]*$' /etc/gdm3/custom.conf

install -d -m 0700 "$backup"
cp -a /etc/gdm3/custom.conf "$backup/custom.conf"
systemctl get-default > "$backup/original-target"

install -D -m 0755 "$base/wslg-x11-directory" /usr/local/libexec/wslg-x11-directory
install -D -m 0644 "$base/wslg-ubuntu-desktop-x11.service" /etc/systemd/system/wslg-ubuntu-desktop-x11.service
install -D -m 0644 "$base/gdm-wslg.conf" /etc/systemd/system/gdm.service.d/80-wslg.conf
ln -s /dev/null /etc/systemd/user/wslg-session.service

dpkg-divert --local --add --rename /usr/bin/Xorg
install -m 0755 "$base/Xorg-wslg-fullscreen" /usr/bin/Xorg
dpkg-divert --local --add --rename /usr/bin/gnome-session
install -m 0755 "$base/gnome-session-wslg" /usr/bin/gnome-session

awk '
    /^\[daemon\][[:space:]]*$/ { daemon=1; print; print "WaylandEnable=false"; next }
    /^\[/ { daemon=0 }
    daemon && /^[[:space:]#]*WaylandEnable=/ { next }
    { print }
' "$backup/custom.conf" > "$backup/custom.wslg.conf"
install -m 0644 "$backup/custom.wslg.conf" /etc/gdm3/custom.conf
systemctl set-default multi-user.target
systemctl unmask --runtime gdm.service gdm3.service
systemctl daemon-reload
