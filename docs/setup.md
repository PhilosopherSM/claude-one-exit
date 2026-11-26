# 部署手册

参考主机使用 Windows 11、WSL 2 Ubuntu 24.04、UID/GID 1000、WSLg、Docker Desktop Linux 引擎和 Ubuntu WSL integration。Compose 需支持 `!override`。GNOME 快捷方式模板预设仓库位于 `C:\src\wslg-docker-workbench`。其他路径请先调整 `gnome-wslg/*.desktop` 中的 Exec。启动器及 Compose 使用固定服务名，在已有同名部署的机器上请先核对 `docker inspect` 的挂载和 Compose 来源。

## 首次配置

### 旧版原地升级

原墙外目录 `hk-tailscale` 现为 `direct`，原墙内目录 `hk-mainland` 现为 `upstream-proxy`。更新同一 checkout 后，将旧目录里 Git 忽略的个人配置复制到对应新目录（例如出口节点、共享目录记录或上游代理配置），再重跑相应入口。Compose 项目和数据卷沿用已有标识。旧版安装在其他 checkout 时请先核对来源。

双击仓库根目录的 `Setup.cmd` 使用默认组合。需要个人配置时，在首次运行前复制并编辑 `workbench.example.toml` 为 `workbench.local.toml`。此文件由 Git 忽略。

| 配置 | 行为 |
| --- | --- |
| `packages` | 填 Debian 软件包名列表，替代整套默认可选软件。例如只要浏览器、Git 和 Python 可填 `["firefox-esr", "git", "python3-venv"]`。Node、证书、curl 和会话总线属于基础运行环境。 |
| `[[shares]]` | 每组填写现有 Windows 文件夹、容器绝对路径和可选的 `read_only = true`。支持空格及中文路径。目标可使用 `/export`、`/data`、`/projects`、`/mnt` 或它们的子目录，也可使用 `/workspace` 下的子目录。 |
| `shares = []` | 仅使用容器持久卷。省略 shares 时使用默认 Windows 共享目录；定义 shares 时只绑定清单中的 Windows 项目目录。 |
| `workdir` | 终端和文件管理器的起始位置。可选 `/workspace`、`/home/node` 或某个已配置的共享目标。 |
| `timezone` | 按当前出口所在地填 IANA 时区。芝加哥用 `America/Chicago`，默认 `Etc/UTC`。日期显示和夏令时规则由 tzdata 处理。 |
| `locale` | 应用容器的 Debian 系统语言和区域格式，如 `en_US.UTF-8`，默认 `C.UTF-8`。构建时生成 locale，启动时设置 LANG 和 LC_ALL。应用自身保存的界面语言偏好仍可能优先。 |

从 Ubuntu 的仓库根目录运行 `bash direct/desktop/Start-Browser.sh --config` 可预览最终配置。共享目录改名或移位置后需要更新 TOML。重新运行安装器会请求确认，再更新镜像和应用容器。主目录与项目卷继续使用；要保留的系统软件应列入 packages。日常快捷方式仍然复用容器。

更换出口时，先保存任务并退出应用，在 Ubuntu 的仓库根目录运行 `docker compose -f direct/compose.yaml exec tailscale tailscale exit-node list`。将选中的 Tailscale IPv4 单独一行写入 `direct/exit-node.local`，按实际位置更新 TOML 的时区和语言，再运行 `Setup.cmd`。完成后用 README 第 4 步核对。

以下为手动部署顺序。先在 Windows 创建 `D:\DockerCopy`。在 Ubuntu 的仓库根目录运行以下命令。首次 Tailscale 登录由使用者自行完成。

```bash
docker volume create hk-tailscale_workspace-home
docker compose -f direct/compose.yaml up -d --wait tailscale
docker compose -f direct/compose.yaml exec tailscale tailscale up --accept-dns=false
docker compose -f direct/compose.yaml exec tailscale tailscale exit-node list
read -rp 'Expected exit node Tailscale IPv4: ' node_ip
printf '%s\n' "$node_ip" > direct/exit-node.local
docker compose -f direct/compose.yaml exec tailscale tailscale set --exit-node="$node_ip"
bash direct/desktop/Start-Browser.sh --build
```

以下步骤仅用于全新的浏览器卷。由普通用户拥有的 `.config` 必须在 Docker 建立嵌套挂载前存在，否则 Firefox 首次启动可能提示 Profile Missing。已有卷应先备份，并按 [运行标准](standards.md) 核对。

```bash
bash direct/desktop/Init-New-Volumes.sh
bash gnome-wslg/Open-Docker-App.sh prepare --check
bash gnome-wslg/Open-Docker-App.sh firefox --wslg
```

在 Windows PowerShell 中从仓库根目录运行 `./gnome-wslg/Install-Docker-StartMenu.ps1`，安装 Claude、Firefox 和终端入口。组合桌面和关机入口分别是 `Open-Ubuntu-Docker.cmd` 和 `Safe-Shutdown.ps1`。GNOME 用户可从 Ubuntu 运行 `bash gnome-wslg/Install-Docker-Shortcuts.sh`。执行前需准备 GNOME Console、zenity、desktop-file-utils、xdg-user-dirs 及用户会话总线。截图桥需要 Ubuntu 的 `wl-clipboard`。

首次部署完成后，从应用容器发起公网出口测试，与家宽侧独立观察到的地址比对。新仓库的验证使用配置解析和脚本语法检查；全新机器的安装验收仍需执行。
