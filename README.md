# Claude One Exit

**English** · [简体中文](README.zh-CN.md)

Claude One Exit gives Claude a stable network environment on Windows. Wherever Claude is supported, your apps can use the same Tailscale exit node as you move between networks.

Edit a repository in your Windows editor, ask Claude Code to run tests against the same files in Linux, and open Firefox for browser sign-in through the same gateway. WSLg gives each app its own Windows window. Docker keeps the workspace and session history available the next time you start it.

[Claude supported regions](https://www.anthropic.com/legal/supported-regions)

## Choose a network configuration

| Choose your network edition | When to use it |
| --- | --- |
| [Direct connection](direct/README.md) | Tailscale can connect on your network. Use the Windows installer below. |
| [Upstream proxy](upstream-proxy/README.md) | Tailscale needs a user-supplied upstream proxy. Start with the Mihomo configuration and verification steps for this experimental edition. |

- 📁 **Share selected folders.** By default, the Windows project folder appears at `/export`. Add other folders as read-only or read/write mounts. A change to a writable shared file is a change to the Windows original.
- 🌐 **Choose your network exit.** Claude, Firefox and the terminal share a Tailscale gateway. The launcher checks that the expected exit node is online. Firewall rules restrict public traffic from the unprivileged app user to the tunnel.
- 💾 **Keep your work across restarts.** Named volumes hold the Linux home directory, local Claude Code conversations, the Claude Desktop profile and the workspace. Put system packages in your profile so they can be installed again when the image is rebuilt.

## Desktop fixes

- **Windows IME punctuation.** The optional WSLg input bridge can forward punctuation typed directly in a Claude draft, including multi-character commits such as `……`. [Patch, build notes and test status](docs/display.md#windows-ime)

- **Clicks on small controls at 200% scale.** A WSLg cursor hotspot bug made the magnifier appear to point at an attachment's close button while the click landed beside it. The optional Weston patch applies the same coordinate transform to the hotspot and its image. On the reference display, a target at pixel (12,15) registered at (6,8) before the fix and at (12,15) afterwards. The arrow and magnifier were checked separately. [Patch and verification](docs/display.md)
- **Pasting Windows screenshots.** The Windows launcher bridges clipboard images to WSLg as PNG so you can keep your usual screenshot shortcut and paste in Claude. [Clipboard bridge](gnome-wslg/Bridge-Claude-Screenshot.ps1)
- **Reopening conversations after a restart.** The container persists both the Desktop session index and the Code transcript files it points to. A test conversation retained its messages after the app container was recreated. [Storage layout](docs/standards.md)

## 🚀 First session with the direct edition

1. **Prepare Windows.** Install Docker Desktop and an Ubuntu 24.04 WSL 2 distribution named `Ubuntu` with WSLg. Enable Ubuntu under Docker Desktop → Settings → Resources → WSL integration. Have an approved Tailscale exit node available.
2. **Choose the regional settings.** Extract or clone the repository to a permanent folder. Copy `workbench.example.toml` to `workbench.local.toml`. Enter the exit node's IANA timezone and your preferred UTF-8 locale. For a neutral starting configuration, place these settings before any `[[shares]]` sections.

   ```toml
   timezone = "Etc/UTC"
   locale = "C.UTF-8"
   ```

   These values are set manually. A Tailscale address alone cannot determine the owner's preferred language. The defaults are UTC and `C.UTF-8`. Review both values whenever you switch exits.
3. **Install.** Double-click [Setup.cmd](Setup.cmd). Complete the Tailscale sign-in when prompted and enter the exit node's **Tailscale IPv4 address** from the displayed list. Setup builds the app image, creates its storage, and prints the shared Windows folder.
4. **Verify.** From Windows Start open **Terminal (Docker)**. Run `date '+%Z %z'`, `printenv LANG`, and `locale charmap`. With the example above, expect UTC +0000, `C.UTF-8` and `UTF-8`. Run `curl -4 -fsS https://api.ipify.org` and compare the result with the public IPv4 independently observed at your exit.
5. **Open a project.** Use **Claude (Docker)** → Code and select the container project directory. With default sharing, a repo named `demo` inside the Windows folder printed by Setup appears at `/export/demo`. To work on a repo in its original location, configure a share below. Open **Firefox (Docker)** for browser authorization through the same gateway.
6. **Resume later.** Save your work and quit the apps. The Windows shortcuts start Docker Desktop when needed and reuse the app container. Reopen the same project directory to resume its local Code sessions.

## ⚙️ Customize

Copy [workbench.example.toml](workbench.example.toml) to `workbench.local.toml`. Set `packages` to choose apps and Debian tools, `workdir` to choose the starting directory, and `shares` to map Windows folders into the container. For example, give Claude write access to `D:\Research` and read-only access to `D:\Datasets`. An explicit share list replaces the default `/export` mapping. Run `Setup.cmd` again to apply changes.

**Guides in Chinese** · [Setup and troubleshooting](docs/setup.md) · [Storage and networking](docs/standards.md) · [Optional GNOME desktop and input](docs/display.md)
