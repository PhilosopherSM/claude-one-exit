FROM node:22-bookworm-slim@sha256:e9f565d32859f0cbfb52125eafe8be39390f24dac302dc3cdf566e8ba3ab21ee AS desktop-pilot

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl dbus gpg \
    && curl -fsSL -o /usr/share/keyrings/claude-desktop-archive-keyring.asc https://downloads.claude.ai/claude-desktop/key.asc \
    && gpg --batch --show-keys --with-colons /usr/share/keyrings/claude-desktop-archive-keyring.asc \
        | awk -F: '$1 == "pub" { keys++ } $1 == "fpr" && $10 == "31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE" { match_key = 1 } END { exit !(keys == 1 && match_key) }' \
    && printf '%s\n' 'deb [signed-by=/usr/share/keyrings/claude-desktop-archive-keyring.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main' > /etc/apt/sources.list.d/claude-desktop.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends claude-desktop fonts-liberation \
    && rm -rf /var/lib/apt/lists/* \
    && install -d -m 0700 -o node -g node /run/desktop

USER node
WORKDIR /home/node
CMD ["dbus-run-session", "--", "claude-desktop", "--ozone-platform=wayland"]
