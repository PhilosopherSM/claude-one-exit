#!/bin/bash
set -euo pipefail
test "$EUID" = 0
base=$(dirname "$(realpath "$0")")
backup=/var/backups/wslg-ubuntu-desktop
test -f "$backup/original-target"

systemctl stop gdm.service
systemctl stop wslg-ubuntu-desktop-x11.service || true
for command in Xorg gnome-session; do
    target=/usr/bin/$command
    source=$base/gnome-session-wslg
    if [ "$command" = Xorg ]; then source=$base/Xorg-wslg-fullscreen; fi
    if test -f "$target.distrib" && cmp -s "$source" "$target"; then
        unlink "$target"
        dpkg-divert --local --rename --remove "$target"
    fi
done
cp -a "$backup/custom.conf" /etc/gdm3/custom.conf
for path in /etc/systemd/system/gdm.service.d/80-wslg.conf /etc/systemd/system/wslg-ubuntu-desktop-x11.service /usr/local/libexec/wslg-x11-directory; do
    if test -f "$path"; then unlink "$path"; fi
done
if [ "$(readlink /etc/systemd/user/wslg-session.service || true)" = /dev/null ]; then
    unlink /etc/systemd/user/wslg-session.service
fi
if ! findmnt --mountpoint /tmp/.X11-unix >/dev/null; then
    mount --bind /mnt/wslg/.X11-unix /tmp/.X11-unix
    mount -o remount,bind,ro /tmp/.X11-unix
fi
systemctl daemon-reload
systemctl set-default "$(cat "$backup/original-target")"
