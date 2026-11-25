#!/bin/bash
set -euo pipefail

# Only register choices on the local Xwayland desktop, never select one.
[[ ${XDG_SESSION_TYPE:-} == x11 ]] || exit 0
output=XWAYLAND0
modes=$(xrandr --current)
grep -q "^$output connected" <<<"$modes" || exit 0
for hz in 60 120; do
    name=3072x1920_${hz}
    if awk -v out="$output" -v name="$name" '
        /^[^[:space:]]/ { active = ($1 == out && $2 == "connected") }
        active && $1 == name { found=1 }
        END { exit !found }
    ' <<<"$modes"; then continue; fi
    clock=393.6576
    [[ $hz == 60 ]] || clock=787.3152
    # A previously defined but unattached mode can still be attached.
    xrandr --newmode "$name" "$clock" 3072 3120 3152 3232 1920 1923 1929 2030 +hsync -vsync ||
        printf 'Trying existing RandR mode %s\n' "$name" >&2
    xrandr --addmode "$output" "$name"
done
