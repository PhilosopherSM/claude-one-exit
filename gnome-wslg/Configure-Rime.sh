#!/bin/bash
set -euo pipefail
base=$(dirname "$(realpath "$0")")
test -r /usr/share/rime-data/double_pinyin_flypy.schema.yaml
: "${XDG_RUNTIME_DIR:?Start this from Ubuntu WSL}"

rime=${XDG_CONFIG_HOME:-$HOME/.config}/ibus/rime/default.custom.yaml
if [ ! -e "$rime" ]; then
    install -D -m 0644 "$base/rime-default.custom.yaml" "$rime"
else
    cmp -s "$base/rime-default.custom.yaml" "$rime" || {
        printf '%s\n' 'Existing Rime custom configuration was not overwritten.' >&2
        exit 1
    }
fi

legacy=$XDG_RUNTIME_DIR/systemd/user/org.freedesktop.IBus.session.GNOME.service.d/80-wslg-docker.conf
if [ -f "$legacy" ] && cmp -s "$base/ibus-wslg.conf" "$legacy"; then
    unlink "$legacy"
    systemctl --user daemon-reload
fi

python3 - <<'PY'
from gi.repository import Gio, GLib

settings = Gio.Settings.new('org.gnome.desktop.input-sources')
sources = settings.get_value('sources').unpack()
if ('ibus', 'rime') not in sources:
    settings.set_value('sources', GLib.Variant('a(ss)', [*sources, ('ibus', 'rime')]))
    Gio.Settings.sync()
PY

if systemctl --user is-active --quiet org.gnome.Shell@wayland.service; then
    service=org.freedesktop.IBus.session.GNOME.service
    if ! systemctl --user is-active --quiet "$service"; then
        systemctl --user reset-failed "$service"
        systemctl --user start "$service"
    fi
fi
