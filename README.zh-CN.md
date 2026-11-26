# WSLg Docker Workbench

[English](README.md) · **简体中文**

**给 Windows 上的 Claude 一个独立、持久的 Linux 开发环境。你决定把哪些 Windows 项目交给它，以及它通过哪台设备上网。**

让 Claude 改代码时，它需要读写仓库、运行命令，有时还会打开浏览器完成授权。WSLg Docker Workbench 把 Claude Desktop、它的本地 Code 会话、Firefox 和终端放在同一个 Docker 容器里。你可以在 Windows 编辑项目，让 Claude 在 Linux 里跑测试，下次开机再接着上次的对话工作。

## 它怎样工作

- 📁 **文件共享**　把项目放进安装器选定的 Windows 共享目录。比如 Windows 上的 `D:\DockerCopy\my-project` 在容器里就是 `/export/my-project`。Claude 的修改直接写回原文件。共享目录下的所有项目对容器可见，Windows 用户主目录和 SSH 密钥默认留在宿主机。
- 🌐 **指定网络出口**　Claude、Firefox 和终端共用一个 Tailscale 网关。你可以选家里的 Apple TV 做出口，让浏览器授权和后续命令走同一条家宽线路。启动器会核对所选节点是否在线，检查失败就停止启动；网关防火墙限制普通应用的公网流量只能经 Tailscale 隧道发出。
- 💾 **保留工作现场**　Docker 卷保存用户主目录、Claude Code 本地会话、Firefox 配置和工作区。重启后可以继续使用原项目和用户环境。在 Windows 上，WSLg 把 Linux 应用显示成可独立切换的窗口；完整 Ubuntu 桌面按需启用。

## 🚀 第一次使用

1. **准备 Windows。** 安装 Docker Desktop 和名为 `Ubuntu` 的 Ubuntu 24.04 WSL 2 发行版，启用 WSLg。在 Docker Desktop → Settings → Resources → WSL integration 勾选 Ubuntu，并准备一台已获批准的 Tailscale 出口节点。
2. **设置出口所在地的时区和所需语言。** 把仓库解压或克隆到固定目录，将 `workbench.example.toml` 复制为 `workbench.local.toml`。下面以芝加哥出口、美国英语为例，这两行放在第一个 `[[shares]]` 前。

   ```toml
   timezone = "America/Chicago"
   locale = "en_US.UTF-8"
   ```

   这两项由你按实际节点填写。一个 Tailscale 地址无法确定使用者喜欢哪种语言。默认是 UTC 和 `C.UTF-8`，切换出口后请同步检查这两项。
3. **安装。** 双击 [Setup.cmd](Setup.cmd)，按提示完成 Tailscale 登录，输入列表里目标出口的 **Tailscale IPv4 地址**。安装器会构建应用镜像、准备持久卷，并打印 Windows 共享目录。
4. **验证。** 在开始菜单打开 **Terminal (Docker)**，依次运行 `date '+%Z %z'`、`printenv LANG` 和 `locale charmap`。按上例配置，时区应随季节显示 CST 或 CDT，语言和字符集应分别为 `en_US.UTF-8` 与 `UTF-8`。运行 `curl -4 -fsS https://api.ipify.org`，将结果和在出口端独立查到的公网 IPv4 比对。
5. **打开项目。** 在 **Claude (Docker) → Code** 选择容器中的项目目录。使用默认共享时，Windows 共享目录下的 `demo` 对应 `/export/demo`。已有仓库可以留在原位置，用下方的配置添加映射。需要网页授权时，从开始菜单打开 **Firefox (Docker)**，它会使用同一网关。
6. **下次继续。** 保存工作并正常退出应用。下次从开始菜单打开时会按需启动 Docker Desktop、复用应用容器。选择同一个项目目录即可接续本地 Code 会话。

## ⚙️ 自定义

安装前把 [workbench.example.toml](workbench.example.toml) 复制为 `workbench.local.toml`。用 `packages` 选择应用和开发工具，用 `[[shares]]` 将任意已有 Windows 项目目录绑定到容器，并用 `read_only` 控制写入权限。例如可以让 Claude 修改 `D:\Research`，同时只读访问 `D:\Datasets`。显式指定共享清单会替代默认的 `/export` 映射。修改配置后重新运行 `Setup.cmd`。

[配置方法与排错](docs/setup.md) · [数据与网络](docs/standards.md) · [可选 GNOME 桌面](docs/display.md)
