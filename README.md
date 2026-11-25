# WSLg Docker Workbench

在 Windows 开始菜单打开 **Claude (Docker)** 或 **Firefox (Docker)**。应用在 Docker 里运行，文件和登录资料保存在本机，联网使用你选定的 Tailscale 出口。

## 开始使用

1. 准备好 Windows 11、WSL 2 Ubuntu、已启用 Ubuntu 集成的 Docker Desktop，以及一台已授权的 Tailscale 出口节点。
2. 解压或克隆到固定目录，双击 **[Setup.cmd](Setup.cmd)**。按提示登录 Tailscale，从列表选择自己的出口。
3. 在开始菜单搜索 **Claude (Docker)**、**Firefox (Docker)** 或 **Terminal (Docker)**。

安装结束会显示 Windows 共享目录。在容器里打开 `/export` 就是同一份文件。

[部署与排错](docs/setup.md) · [数据与网络](docs/standards.md) · [可选 GNOME 桌面](docs/display.md)
