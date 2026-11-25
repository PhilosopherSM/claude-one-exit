# WSLg Docker Workbench

**给 Windows 上的 Claude 一个独立、持久的 Linux 开发环境。你决定把哪些 Windows 项目交给它，以及它通过哪台设备上网。**

让 Claude 改代码时，它需要读写仓库、运行命令，有时还会打开浏览器完成授权。WSLg Docker Workbench 把 Claude Desktop、它的本地 Code 会话、Firefox 和终端放在同一个 Docker 容器里。你可以在 Windows 编辑项目，让 Claude 在 Linux 里跑测试，下次开机再接着上次的对话工作。

## 它怎样工作

- **文件共享**　把项目放进安装器选定的 Windows 共享目录。比如 Windows 上的 `D:\DockerCopy\my-project` 在容器里就是 `/export/my-project`。Claude 的修改直接写回原文件。共享目录下的所有项目对容器可见，Windows 用户主目录和 SSH 密钥默认留在宿主机。
- **指定网络出口**　Claude、Firefox 和终端共用一个 Tailscale 网关。你可以选家里的 Apple TV 做出口，让浏览器授权和后续命令走同一条家宽线路。启动器会核对所选节点是否在线，检查失败就停止启动；网关防火墙限制普通应用的公网流量只能经 Tailscale 隧道发出。
- **保留工作现场**　Docker 卷保存用户主目录、Claude Code 本地会话、Firefox 配置和工作区。重启后可以继续使用原项目和用户环境。在 Windows 上，WSLg 把 Linux 应用显示成可独立切换的窗口；完整 Ubuntu 桌面按需启用。

## 开始使用

1. 准备好 Windows 11、WSL 2 Ubuntu、已启用 Ubuntu 集成的 Docker Desktop，以及一台已授权的 Tailscale 出口节点。
2. 解压或克隆到固定目录，双击 **[Setup.cmd](Setup.cmd)**。按提示登录 Tailscale，从列表选择自己的出口。
3. 把仓库放入安装结束时显示的共享目录。打开开始菜单里的 **Claude (Docker)**，在 Code 页选择容器中的 `/export/项目名`，即可让 Claude 处理这个仓库。

## 自定义

安装前把 [workbench.example.toml](workbench.example.toml) 复制为 `workbench.local.toml`。用 `packages` 选择应用和开发工具，用 `[[shares]]` 将任意已有 Windows 项目目录绑定到容器，并用 `read_only` 控制写入权限。例如可以让 Claude 修改 `D:\Research`，同时只读访问 `D:\Datasets`。修改配置后重新运行 `Setup.cmd`。

[配置方法与排错](docs/setup.md) · [数据与网络](docs/standards.md) · [可选 GNOME 桌面](docs/display.md)
