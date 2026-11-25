# 部署手册

参考主机使用 Windows 11、WSL 2 Ubuntu 24.04、UID/GID 1000、WSLg、Docker Desktop Linux 引擎和 Ubuntu WSL integration。Compose 需支持 `!override`。GNOME 快捷方式模板预设仓库位于 `C:\src\wslg-docker-workbench`。其他路径请先调整 `gnome-wslg/*.desktop` 中的 Exec。启动器及 Compose 使用固定服务名，在已有同名部署的机器上请先核对 `docker inspect` 的挂载和 Compose 来源。

## 首次配置

双击仓库根目录的 `Setup.cmd` 使用默认组合。需要个人配置时，在首次运行前复制并编辑 `workbench.example.toml` 为 `workbench.local.toml`。此文件由 Git 忽略。

| 配置 | 行为 |
| --- | --- |
| `packages` | 填 Debian 软件包名列表，替代整套默认可选软件。例如只要浏览器、Git 和 Python 可填 `["firefox-esr", "git", "python3-venv"]`。Node、证书、curl 和会话总线属于基础运行环境。 |
| `[[shares]]` | 每组填写现有 Windows 文件夹、容器绝对路径和可选的 `read_only = true`。支持空格及中文路径。目标可使用 `/export`、`/data`、`/projects`、`/mnt` 或它们的子目录，也可使用 `/workspace` 下的子目录。 |
| `shares = []` | 仅使用容器持久卷。省略 shares 时使用默认 Windows 共享目录；定义 shares 时只绑定清单中的 Windows 项目目录。 |
| `workdir` | 终端和文件管理器的起始位置。可选 `/workspace`、`/home/node` 或某个已配置的共享目标。 |

从 Ubuntu 的仓库根目录运行 `bash hk-tailscale/desktop/Start-Browser.sh --config` 可预览最终配置。共享目录改名或移位置后需要更新 TOML。重新运行安装器会请求确认，再更新镜像和应用容器。主目录与项目卷继续使用；要保留的系统软件应列入 packages。日常快捷方式仍然复用容器。

先在 Windows 创建 `D:\DockerCopy`。在 Ubuntu 的仓库根目录运行以下命令。首次 Tailscale 登录由使用者自行完成。

```bash
docker volume create hk-tailscale_workspace-home
docker compose -f hk-tailscale/compose.yaml up -d --wait tailscale
docker compose -f hk-tailscale/compose.yaml exec tailscale tailscale up --accept-dns=false
docker compose -f hk-tailscale/compose.yaml exec tailscale tailscale exit-node list
read -rp 'Expected exit node Tailscale IPv4: ' node_ip
printf '%s\n' "$node_ip" > hk-tailscale/exit-node.local
docker compose -f hk-tailscale/compose.yaml exec tailscale tailscale set --exit-node="$node_ip"
bash hk-tailscale/desktop/Start-Browser.sh --build
```

以下步骤仅用于全新的浏览器卷。由普通用户拥有的 `.config` 必须在 Docker 建立嵌套挂载前存在，否则 Firefox 首次启动可能提示 Profile Missing。已有卷应先备份，并按 [运行标准](standards.md) 核对。

```bash
bash hk-tailscale/desktop/Init-New-Volumes.sh
bash gnome-wslg/Open-Docker-App.sh prepare --check
bash gnome-wslg/Open-Docker-App.sh firefox --wslg
```

在 Windows PowerShell 中从仓库根目录运行 `./gnome-wslg/Install-Docker-StartMenu.ps1`，安装 Claude、Firefox 和终端入口。组合桌面和关机入口分别是 `Open-Ubuntu-Docker.cmd` 和 `Safe-Shutdown.ps1`。GNOME 用户可从 Ubuntu 运行 `bash gnome-wslg/Install-Docker-Shortcuts.sh`。执行前需准备 GNOME Console、zenity、desktop-file-utils、xdg-user-dirs 及用户会话总线。截图桥需要 Ubuntu 的 `wl-clipboard`。

首次部署完成后，从应用容器发起公网出口测试，与家宽侧独立观察到的地址比对。新仓库的验证使用配置解析和脚本语法检查；全新机器的安装验收仍需执行。
