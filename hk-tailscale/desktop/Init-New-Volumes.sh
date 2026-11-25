#!/bin/bash
set -euo pipefail
volumes=(hk-browser-session_browser-home hk-browser-session_claude-code-home hk-browser-session_claude-profile)
image=hk-browser-session-browser:latest
docker image inspect "$image" >/dev/null
for v in "${volumes[@]}"; do
    if docker volume inspect "$v" >/dev/null 2>&1; then
        docker run --rm --pull never --network none --user 1000:1000 \
            --mount "type=volume,src=$v,dst=/new,volume-nocopy" "$image" \
            sh -ec 'test -w /new; if [ "$1" = hk-browser-session_browser-home ]; then test -d /new/.config && test -w /new/.config; fi' sh "$v" ||
            { printf 'Check ownership of existing volume %s before continuing.\n' "$v" >&2; exit 1; }
        continue
    fi
    docker volume create "$v" >/dev/null
    docker run --rm --pull never --network none --user 0:0 \
        --mount "type=volume,src=$v,dst=/new,volume-nocopy" "$image" \
        sh -ec 'test -z "$(ls -A /new)"; chown 1000:1000 /new; chmod 0700 /new
                if [ "$1" = hk-browser-session_browser-home ]; then install -d -m 0700 -o 1000 -g 1000 /new/.config; fi' sh "$v"
done
