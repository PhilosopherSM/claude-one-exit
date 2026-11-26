# WSLg Docker Workbench

**English** · [简体中文](README.zh-CN.md)

Give Claude a persistent Linux development environment on Windows. Choose which project folders it can edit, which tools it can run, and which Tailscale exit node its traffic uses.

Edit a repository in your Windows editor, ask Claude Code to run tests against the same files in Linux, and open Firefox for browser sign-in through the same gateway. WSLg gives each app its own Windows window. Docker keeps the workspace and session history available the next time you start it.

## How it works

- 📁 **Share selected folders.** By default, the Windows project folder appears at `/export`. Add other folders as read-only or read/write mounts. A change to a writable shared file is a change to the Windows original.
- 🌐 **Choose your network exit.** Claude, Firefox and the terminal share a Tailscale gateway. The launcher checks that the expected exit node is online. Firewall rules restrict public traffic from the unprivileged app user to the tunnel.
- 💾 **Keep your work across restarts.** Named volumes hold the Linux home directory, local Claude Code conversations, the Claude Desktop profile and the workspace. Put system packages in your profile so they can be installed again when the image is rebuilt.

## 🚀 First session

1. **Prepare Windows.** Install Docker Desktop and an Ubuntu 24.04 WSL 2 distribution named `Ubuntu` with WSLg. Enable Ubuntu under Docker Desktop → Settings → Resources → WSL integration. Have an approved Tailscale exit node available.
2. **Choose the regional settings.** Extract or clone the repository to a permanent folder. Copy `workbench.example.toml` to `workbench.local.toml`. Enter the exit node's IANA timezone and your preferred UTF-8 locale. For example, an English-language environment using a Chicago exit uses these top-level settings before any `[[shares]]` sections.

   ```toml
   timezone = "America/Chicago"
   locale = "en_US.UTF-8"
   ```

   These values are set manually. A Tailscale address alone cannot determine the owner's preferred language. The defaults are UTC and `C.UTF-8`. Review both values whenever you switch exits.
3. **Install.** Double-click [Setup.cmd](Setup.cmd). Complete the Tailscale sign-in when prompted and enter the exit node's **Tailscale IPv4 address** from the displayed list. Setup builds the app image, creates its storage, and prints the shared Windows folder.
4. **Verify.** From Windows Start open **Terminal (Docker)**. Run `date '+%Z %z'`, `printenv LANG`, and `locale charmap`. With the example above, expect CST or CDT according to the season, plus `en_US.UTF-8` and `UTF-8`. Run `curl -4 -fsS https://api.ipify.org` and compare the result with the public IPv4 independently observed at your exit.
5. **Open a project.** Use **Claude (Docker)** → Code and select the container project directory. With default sharing, a repo named `demo` inside the Windows folder printed by Setup appears at `/export/demo`. To work on a repo in its original location, configure a share below. Open **Firefox (Docker)** for browser authorization through the same gateway.
6. **Resume later.** Save your work and quit the apps. The Windows shortcuts start Docker Desktop when needed and reuse the app container. Reopen the same project directory to resume its local Code sessions.

## ⚙️ Customize

Copy [workbench.example.toml](workbench.example.toml) to `workbench.local.toml`. Set `packages` to choose apps and Debian tools, `workdir` to choose the starting directory, and `shares` to map Windows folders into the container. For example, give Claude write access to `D:\Research` and read-only access to `D:\Datasets`. An explicit share list replaces the default `/export` mapping. Run `Setup.cmd` again to apply changes.

**Guides in Chinese** · [Setup and troubleshooting](docs/setup.md) · [Storage and networking](docs/standards.md) · [Optional GNOME desktop and input](docs/display.md)
