# 墙内版 · Upstream proxy

适用于需要上游代理才能连接 Tailscale 的网络。Mihomo 使用你提供的机场节点建立上游连接，应用的预期最终出口仍是你选定的 Tailscale exit node。准备好允许从当前位置接入的节点和端口。

1. 在本目录将 `.env.example` 复制为 `.env`，将 `upstream.example.yaml` 复制为 `upstream.local.yaml`。
2. 在两个文件中填入同一上游节点的 IPv4 和端口，并在 YAML 中配置协议所需的认证信息。样例采用 SOCKS5。真实配置仅保存在本机。
3. 从本目录执行 `docker compose up -d --wait tailscale`，再执行 `docker compose exec tailscale tailscale up --accept-dns=false` 完成授权。
4. 执行 `docker compose exec tailscale tailscale exit-node list`，再用 `docker compose exec tailscale tailscale set --exit-node=<节点的 Tailscale IPv4>` 选择出口。
5. 在仓库根目录执行 `bash direct/desktop/Start-Browser.sh --build` 构建探测和桌面服务共用的应用镜像。回到本目录，执行 `docker compose --profile verify up -d --wait probe`，用 `docker compose exec probe curl -4 -fsS https://api.ipify.org` 与出口端独立观察到的公网地址比对。

实验范围和故障验收见[运行标准](../docs/standards.md)。当前 Windows 快捷方式安装器对应墙外版；墙内版使用本目录的 Compose 入口。真实上游、实际出口和断线行为需要在目标网络验收。

**English.** Use this experimental Compose edition when Tailscale needs an upstream proxy. Supply your own Mihomo-compatible node, authorize Tailscale, select an exit node, and verify the observed public IP from the probe before starting workloads. [Network and storage standards](../docs/standards.md)
