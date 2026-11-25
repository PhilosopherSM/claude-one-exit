#!/bin/bash
set -euo pipefail
root=$(dirname "$(realpath "$0")")
cd "$root"
[[ $(id -u) == 1000 && $(id -g) == 1000 ]] || { echo 'Use the default Ubuntu user (UID/GID 1000).'; exit 1; }
docker info >/dev/null || { echo 'Enable Ubuntu in Docker Desktop > Settings > Resources > WSL integration.'; exit 1; }
test -S /mnt/wslg/runtime-dir/wayland-0 || { echo 'Enable WSLg GUI support in Ubuntu.'; exit 1; }
for pair in 'hk-tailscale-tailscale-1 hk-tailscale' 'hk-browser-session-browser-1 hk-tailscale/desktop'; do
    read -r container directory <<< "$pair"
    if docker container inspect "$container" >/dev/null 2>&1; then
        previous=$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project.working_dir"}}' "$container")
        [[ "$previous" == "$root/$directory" ]] || { echo "Existing $container belongs to $previous. Use that installation or plan a migration."; exit 1; }
    fi
done
bash hk-tailscale/desktop/Start-Browser.sh --check
if [[ ${1:-} == --check ]]; then exit 0; fi
if docker container inspect hk-browser-session-browser-1 >/dev/null 2>&1; then
    read -rp 'Setup may recreate the app container. Save work and quit apps first. Continue [y/N]? ' consent
    [[ "$consent" == [Yy] ]] || exit 1
fi
if ! command -v wl-copy >/dev/null; then
    sudo apt-get update
    sudo apt-get install -y wl-clipboard
fi
if [[ ! -s hk-tailscale/export-dir.local ]]; then
    if mountpoint -q /mnt/d; then
        export_dir=/mnt/d/DockerCopy
    else
        profile=$(cmd.exe /d /c 'echo %USERPROFILE%' | tr -d '\r')
        export_dir="$(wslpath -u "$profile")/DockerCopy"
    fi
    mkdir -p "$export_dir"
    printf '%s\n' "$export_dir" > hk-tailscale/export-dir.local
fi
gateway=(docker compose -f hk-tailscale/compose.yaml)
docker volume create hk-tailscale_workspace-home >/dev/null
"${gateway[@]}" up -d --wait --no-recreate tailscale
state=$("${gateway[@]}" exec -T tailscale tailscale status --json | python3 -c 'import sys,json; print(json.load(sys.stdin)["BackendState"])') || state=unknown
if [[ "$state" != Running ]]; then
    "${gateway[@]}" exec -T tailscale tailscale up --accept-dns=false
fi
if [[ ! -s hk-tailscale/exit-node.local ]]; then
    "${gateway[@]}" exec -T tailscale tailscale exit-node list
    read -rp 'Enter the Tailscale IPv4 address of your exit node: ' node
    python3 -c 'import ipaddress,sys; ipaddress.IPv4Address(sys.argv[1])' "$node"
    "${gateway[@]}" exec -T tailscale tailscale set --exit-node="$node"
    printf '%s\n' "$node" > hk-tailscale/exit-node.local
else
    "${gateway[@]}" exec -T tailscale tailscale set --exit-node="$(cat hk-tailscale/exit-node.local)"
fi
bash hk-tailscale/desktop/Start-Browser.sh --build
bash hk-tailscale/desktop/Init-New-Volumes.sh
bash gnome-wslg/Open-Docker-App.sh prepare --check --apply
python3 profile.py --list
