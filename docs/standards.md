# 运行标准与验收记录

| 对象 | 运行约定 | 验收方法 |
| --- | --- | --- |
| 应用进程 | Claude、Firefox 和文件管理器用 UID/GID 1000，丢弃全部 capabilities，使用 seccomp 和 no-new-privileges | 查看应用容器的 `docker inspect`、`id`、`/proc/self/status`。Docker 管理 socket 仅供宿主启动器使用 |
| 公网出口 | 应用加入 Tailscale 网关网络命名空间。IPv4 OUTPUT 默认 DROP，允许网关 root 建立隧道，普通用户经 tailscale0 出站，另有本地回环例外。禁用该命名空间的 IPv6 | 比对两个容器的 `/proc/self/ns/net`，核对预期 exit node、路由及防火墙。启动器的公网 HTTPS 探测证明当次连通；独立验证出口地址需和出口端实测值比对 |
| 容器生命周期 | 启动时复用现有容器。更新镜像或强制重建会替换系统可写层 | 普通停启后容器 ID 和测试文件应保留。隔离测试中重建后卷内文件保留，系统层标记消失 |
| 用户数据 | `/home/node` 整体持久化。`.claude` 和 `.config/Claude` 分别挂私有卷，保留 Code 正文和 Desktop 索引、身份。Firefox 配置、下载和用户级安装在主目录卷 | 用 UID 1000 检查各目录可读写。桌面恢复后打开原会话，核对原消息和回复。旧环境里只剩索引的会话可能无法恢复 |
| 项目文件 | 应用容器有独立的 `/workspace` 卷以及 `D:\DockerCopy` ↔ `/export` 读写共享。VS Code 容器有自己的 `/home/node` 卷 | 双向写入同一个测试文件。检查 Windows ACL，尤其是共享电脑上的继承权限 |
| 工具权限 | 用户态软件、项目和临时目录可加入本地 Code 的附加目录。可审阅 [配置模板](../direct/desktop/claude-code/settings.json)，按需合并至用户设置 | 检查原有审批模式。Cowork 云端任务另外依赖在线设备和已授权文件夹，单独做会话写入验收 |
| 文件浏览 | GNOME 的 Files (Docker) 在应用容器中以普通用户启动 Thunar；Terminal (Docker) 打开同一容器中的 shell | 文件管理器用 Ctrl+L 查看 `/export`，终端运行 `id` 和 `pwd` |
| 备份与关机 | 定期备份持久卷和 Windows 项目。先保存工作并退出应用，再停止 Docker Desktop 和 WSL | `Safe-Shutdown.ps1 -CheckOnly` 可检查状态；正常执行会请求 Windows 关机。之前验证了只读预检 |

## 上游代理实验

`upstream-proxy/` 为独立配置。Mihomo 按配置限制上游，Tailscale 使用受限链路，探测服务与其共用命名空间。真实入口在各自忽略的 `.env` 和 `upstream.local.yaml`；仓库只含样例地址和测试网段。此目录的应用配置与主工作台的持久卷约定分别管理。

历史隔离夹具验证过控制面握手、DERP HTTPS 可达及停掉上游时的失败行为。上游代理、已认证数据路径、切网重启和 DNS 故障仍需在部署网络验收。仓库版本补上了可选 desktop 配置引用的 workspace 卷，仅完成 Compose 解析验证。

## 运维边界

接手环境时，先查看应用容器的 Compose 标签，确认实际使用的仓库目录、配置文件和挂载。检查预期 Tailscale 节点在线，再以普通用户核对工作目录、卷权限及应用容器实际使用的时区和 locale。更换节点后，在个人 TOML 中同步更新区域设置并运行安装器。保存手头任务后再确认容器重建。

参考环境实测过 Docker 停启及隔离重建后的卷数据、共享目录读写保护，以及独立镜像中的 UTF-8、冬夏令时切换。自定义 WSLg 镜像、Windows 输入法 DLL 和资源管理器“发送到”入口是参考部署的额外集成。公开安装入口的共享配置使用 TOML，显示组件和输入法的验收范围见[显示与输入](display.md)。

WSLg 负责图形和剪贴板。Windows 进程、云端工具及另一个容器各有独立的文件和网络边界。应用项目中固定的镜像和上游 apt 签名需在升级时重新核对。日常升级前记录当前卷、镜像、用户权限和出口验证结果；镜像清理需同时核对 Dockerfile 的 FROM 引用，保留构建依赖。归档或发布源码时剔除用户配置、账号数据、订阅、私钥、卷导出和虚拟磁盘。
