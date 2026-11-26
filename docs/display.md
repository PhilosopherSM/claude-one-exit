# 显示与输入

| 入口或功能 | 方案与验证范围 |
| --- | --- |
| 独立 Windows 窗口 | Windows 启动器按需启动 Docker Desktop，等待 Linux 引擎就绪，再检查网关和 Wayland socket。Firefox 和 Claude 继续使用容器内的配置及网络 |
| 嵌套 GNOME | [启动脚本](../gnome-wslg/Start-Ubuntu-Wayland.sh) 准备私有显示目录并运行用户级 GNOME 会话。Docker 显示绑定为只读。遇到 root 所有的运行时目录，先核对 owner、类型、链接和挂载，再定点修复 |
| GDM 全屏 | 原始教程使用 GDM/Xwayland。仓库收录了已有的系统改动、备份及恢复脚本。此路线涉及系统服务和 dpkg diversion；请先审阅安装器的前置检查与恢复脚本。[原始 Gist](https://gist.github.com/tdcosta100/e28636c216515ca88d1f2e7a2e188912) · [嵌套 Wayland 参考](https://gist.github.com/tdcosta100/7def60bccc8ae32cf9cacb41064b1c0f) |
| 分辨率和刷新率 | [RandR 脚本](../gnome-wslg/Register-Gdm-Display-Modes.sh) 为 XWAYLAND0 注册参考面板的 3072×1920、60/120 Hz 选择，XML 只记录已选模式。参考机实测 GNOME 能列出两档。端到端实际帧率有待测量 |
| GPU | [独立 GDM 会话条目](../gnome-wslg/ubuntu-wslg-gpu.desktop) 使用 Mesa D3D12；普通 Ubuntu 入口可回退。参考机 Intel GPU 在独立显示测试中通过 GNOME 加速探测。完整 GPU 登录和帧率须本机验收 |
| 中文 | 默认应用镜像含 CJK 字体。Ubuntu 侧可用 IBus/Rime 小鹤双拼。独立 WSLg 窗口也可配合下述 Windows IME 桥使用微软拼音。 |
| 截图 | [Windows 桥接脚本](../gnome-wslg/Bridge-Claude-Screenshot.ps1) 在目标窗口获得焦点时，将 Windows 剪贴板图片在内存转成 PNG 并交给 WSLg。Snipaste 保留自己的截图键。历史验证读取到有效 PNG，附件预览应在具体客户端验收 |
| 指针热点 | [Weston 补丁](../patches/weston-hotspot.patch) 将热点按图像缓冲变换和当前输出的缩放换算。WSLg 1.0.71、200% 内屏上，标记中心 (12,15) 的实际热点从 (6,8) 修正为 (12,15)，放大镜 (22,19) 和箭头 (7,7) 也分别对齐。物理外屏拖动尚待验证。Windows 原生语义光标切换仍是上游功能请求。[热点问题及补丁来源](https://github.com/microsoft/wslg/issues/935) · [原生光标讨论](https://github.com/microsoft/wslg/issues/65) |

## Windows IME

这是参考主机的可选系统级集成。使用微软拼音的小鹤双拼时，有候选词的组词提交和直接按标点键走不同的文本编辑路径。Windows 插件补丁监听 TSF 报告的本次文本变更，在没有活动组词时，将完整的非 ASCII 标点串传给 Linux 客户端。独立 Claude 窗口使用 `--enable-wayland-ime --wayland-text-input-version=3`。[标点源码补丁](../patches/wslg-ime-direct-punctuation.patch)

1. 准备社区 Windows 插件的完整 Git checkout，包含上游版本标签，切换到提交 `f22007562f3b509b3913ad69ddf32c2205756645`。在 checkout 根目录执行 `git apply --check <补丁路径>`，通过后执行 `git apply <补丁路径>`。[上游 Windows 源码](https://github.com/baiiiii/wslg/tree/f22007562f3b509b3913ad69ddf32c2205756645)
2. 在 Visual Studio 2022 Developer PowerShell 中运行上游版本资源生成脚本 `./WSLDVCPlugin/UpdateRCVersion.ps1 -separator "."`。使用 v143、匹配的 x64 Spectre 运行库及 Windows SDK，通过 `msbuild WSLDVCPlugin/WSLDVCPlugin.vcxproj /p:Configuration=Release /p:Platform=x64` 构建。若链接器报告缺少 WinRT 激活函数，将 SDK 的 `windowsapp.lib` 加入链接依赖。
3. 与提供 `zwp_text_input_manager_v3` 的社区 Weston 配套使用。参考主机使用提交 `2b0487044c69260603cd0338c1d3dc0113ab0675` 加下节的热点补丁。备份当前 DLL、WSLg 镜像路径和 `.wslconfig`，保存工作并停止 Docker Desktop、关闭 WSL 后再替换插件。回退时恢复上一次可用的组件组合。[Linux 端源码](https://github.com/baiiiii/weston-mirror/tree/2b0487044c69260603cd0338c1d3dc0113ab0675) · [上游部署说明](https://github.com/baiiiii/wslg-build)
4. 在 Claude 空草稿框中，用中文模式直接测试 `,`、`.`、左右括号及 `Shift+6`。依次检查 `，`、`。`、`（`、`）` 和完整的 `……`，再检查连按、英文模式及拼音选词后跟标点。

参考机已确认中文选词和独立逗号、句号、括号上屏。扩展版 DLL 已加载，省略号通过 Windows 字符类别测试；当次采样尚未独立确认一次实际按键提交两个 U+2026。

## 维护私有 WSLg 镜像

历史构建以 Weston 提交 `2318fecaeac1f1a2d5a7a042c34d931c71dae04c` 为基准，在源码根目录以 `patch -p3 --fuzz=0` 应用随附补丁。使用 [Mariner 构建配方](../patches/Dockerfile.cursor)。构建上下文需要已打补丁源码 `src/`、可信 CA 包 `builder-ca.pem`，以及从对应原版系统镜像提取的 FreeRDP、WinPR、rdpapplist 头文件、库与 pkg-config 文件组成的 `layer/usr/`。生成物是 `rdp-backend.so`。

在独立 ext4 副本中替换 `/usr/lib/libweston-9/rdp-backend.so`，保留其所有者和执行权限。参考部署对替换后的文件做哈希回读、文件系统检查和固定 VHD 转换比对。使用 `.wslconfig` 的 `[wsl2] systemDistro` 指向私有镜像。切换前保存任务并正常停止 Docker 和 WSL。回退时移除该项并重新启动 WSL。更新 WSL 后需要重新核对 ABI，因为私有镜像路径仍会生效。[微软构建与私有镜像说明](https://github.com/microsoft/wslg/blob/main/CONTRIBUTING.md)
