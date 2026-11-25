# WSLg Docker Workbench

**English** · [简体中文](README.zh-CN.md)

Give Claude a persistent Linux development environment on Windows. Choose which project folders it can edit, which tools it can run, and which Tailscale exit node its traffic uses.

Edit a repository in your Windows editor, ask Claude Code to run tests against the same files in Linux, and open Firefox for browser sign-in through the same gateway. WSLg gives each app its own Windows window. Docker keeps the workspace and session history available the next time you start it.

## How it works

- 📁 **Share selected folders.** By default, the Windows project folder appears at `/export`. Add other folders as read-only or read/write mounts. A change to a writable shared file is a change to the Windows original.
- 🌐 **Choose your network exit.** Claude, Firefox and the terminal share a Tailscale gateway. The launcher checks that the expected exit node is online. Firewall rules restrict public traffic from the unprivileged app user to the tunnel.
- 💾 **Keep your work across restarts.** Named volumes hold the Linux home directory, local Claude Code conversations, the Claude Desktop profile and the workspace. Put system packages in your profile so they can be installed again when the image is rebuilt.

## 🚀 Quick start

1. Prepare Windows 11 with an Ubuntu WSL 2 distribution, WSLg, Docker Desktop with Ubuntu integration enabled, and an approved Tailscale exit node.
2. Download or clone this repository to a permanent folder. Double-click **[Setup.cmd](Setup.cmd)**, sign in to Tailscale when prompted, and select your exit node.
3. Put a project in the Windows folder printed by Setup. Open **Claude (Docker)** from Start and select `/export/your-project` in the Code tab. The Start menu also includes **Firefox (Docker)** and **Terminal (Docker)** with the default installation.

## ⚙️ Customize

Copy [workbench.example.toml](workbench.example.toml) to `workbench.local.toml`. Set `packages` to choose apps and Debian tools, `workdir` to choose the starting directory, and `shares` to map Windows folders into the container. For example, give Claude write access to `D:\Research` and read-only access to `D:\Datasets`. An explicit share list replaces the default `/export` mapping. Run `Setup.cmd` again to apply changes.

**Guides in Chinese** · [Setup and troubleshooting](docs/setup.md) · [Storage and networking](docs/standards.md) · [Optional GNOME desktop and input](docs/display.md)
