#!/bin/bash
set -euo pipefail

runtime=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
display_dir=${runtime%/}/gnome-docker-display
if [ ! -d "$runtime" ] || [ ! -O "$runtime" ] || [ -L "$display_dir" ] ||
    { [ -e "$display_dir" ] && { [ ! -d "$display_dir" ] || [ ! -O "$display_dir" ]; }; }; then
    printf 'Expected a private, user-owned GNOME display directory at %s\n' "$display_dir" >&2
    exit 1
fi
install -d -m 0700 "$display_dir"
