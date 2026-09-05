# Codex Clash No-TUN No-System-Proxy Connector（基于 Clash 的 Codex 无 TUN、无系统代理连接器）

<p align="right">
  <a href="README.md">English</a> · <strong>简体中文</strong>
</p>

这是一个适用于 Windows 的一键启动器：在**不启用 TUN、也不启用 Windows 系统代理**的情况下，通过已经运行的本地 Clash/Mihomo HTTP 代理启动或聚焦 Microsoft Store 版 Codex。

项目运行于 Windows PowerShell 5.1。它只是启动器，不管理 Clash 配置。

## 第三方声明

本项目不包含 Clash Verge Rev 的代码、安装包内容或代理核心二进制文件。若未来的可选安装器支持本地代理核心，必须直接获取官方 Mihomo 发布包、校验其公开哈希，并在重新分发二进制文件时保留 Mihomo 的版权与 MIT 许可证声明。请勿从 Clash Verge Rev 中拆取或再分发 `verge-mihomo` 侧载核心。

“Clash”与“Mihomo”是第三方项目名称。本项目独立开发，未获得其维护者的关联或背书。

## 功能

- Codex 已在运行时，仅恢复并置顶其主窗口，不重启。
- Codex 未运行时，使用 Electron 代理参数和代理环境变量启动 Store 版应用。
- 自动发现由受支持本地代理核心持有的可用本地 HTTP 代理。
- 检测到的端点仅保存在本机安装目录，不会写入仓库。
- 可创建开始菜单快捷方式，并可手动固定到任务栏。
- 运行日志只写入本地 `logs/`，Git 会忽略它。

## 明确不做的事

- 不包含、读取、修改、上传或发布 Clash 订阅。
- 不包含真实代理地址或端口。
- 不修改 Clash 的 TUN 模式、Windows 系统代理、路由、DNS、防火墙或现有网络设置。
- 不保存账号凭据、令牌、Cookie、Codex 会话或用户路径到仓库。

## 要求

- Windows 11 或其他支持 Windows PowerShell 5.1 的 Windows 版本。
- 已安装并登录 ChatGPT 账号的 Microsoft Store 版 Codex。
- 已经运行的、本地 Clash/Mihomo 兼容 HTTP 代理。代理服务商与配置由使用者自行负责。
- 代理须支持 HTTPS CONNECT 与 WebSocket 升级；Codex 会使用这两种流量。

## 一键安装

1. 先启动自己的本地代理核心。
2. 在项目目录运行：

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install-CodexScopedProxy.ps1
   ```

3. 安装器会自动检测本地 HTTP 代理，将启动器安装到 `%LOCALAPPDATA%`，并创建开始菜单快捷方式。仓库中不会写入代理 URL。
4. 在开始菜单中右键 `Codex Scoped Proxy`，选择“固定到任务栏”。

如需安装完成后立即启动：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install-CodexScopedProxy.ps1 -LaunchAfterInstall
```

## 卸载

运行已安装的卸载脚本：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\CodexScopedProxyLauncher\Uninstall-CodexScopedProxy.ps1"
```

它只移除本启动器文件和其开始菜单/任务栏快捷方式；不会删除 Codex、Clash、订阅、TUN 或系统代理设置。

## 行为

| Codex 状态 | 启动器行为 |
| --- | --- |
| 未运行 | 自动检测可用本地 HTTP 代理，再通过该代理启动 Codex。 |
| 已运行 | 恢复并置顶现有 Codex 窗口。 |
| 正在启动 | 不会启动第二个实例。 |
| 代理不可用 | 不启动 Codex；请查看 `logs/launcher.log`。 |

## 发布前隐私检查

在仓库根目录执行：

```powershell
git status --ignored
git ls-files
```

`config.json` 与 `logs/` 必须保持未跟踪状态。不要将 Clash 订阅 URL、访问令牌或服务商配置粘贴到 Issue、提交、截图或 Release 附件中。

## 故障排除

- `No working local HTTP proxy was detected`：启动代理核心后重新运行安装器或启动器。
- 账号无法加载：确认代理允许 OpenAI/ChatGPT 目标的 HTTPS 与 WebSocket 升级。
- 任务栏出现重复图标：取消固定旧快捷方式，只固定生成的 `Codex Scoped Proxy` 快捷方式，然后启动一次。

## 许可证

MIT。参见 [LICENSE](LICENSE)。
