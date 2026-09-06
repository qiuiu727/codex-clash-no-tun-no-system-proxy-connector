# Codex Clash No-TUN No-System-Proxy Connector（基于 Clash 的 Codex 无 TUN、无系统代理连接器）

<p align="right">
  <a href="README.md">English</a> · <strong>简体中文</strong>
</p>

这是一个交互式 Windows 安装程序：它在不启用 TUN、也不修改 Windows 系统代理的前提下，经由已经运行的本地 HTTP 代理启动 Microsoft Store 版 Codex。

启动器的作用范围被刻意限制：只有**通过它生成的启动入口新建的 Codex 进程**，才会收到代理环境变量和 Electron 代理参数。原始 Codex 图标、系统代理、TUN 模式、DNS、路由以及其他软件均不会被修改。

## 安装

1. 先启动自己的本地代理核心（例如 Clash/Mihomo）。它需要提供支持 HTTPS CONNECT 的可用回环 HTTP 代理。
2. 双击 [Setup-CodexConnection.cmd](Setup-CodexConnection.cmd)，或在 PowerShell 中运行：

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Setup-CodexConnection.ps1
   ```

3. 安装程序默认英文；第一个提示输入 `ZH` 可切换简体中文，然后输入 `1` 安装或输入 `2` 卸载。
4. 安装时输入 `1` 生成可选的“重启 Codex Connection”脚本，输入 `2` 代表不生成（N）；普通“启动 Codex Connection”脚本一定会生成。
5. 安装器会先自动检测正在运行的本地 HTTP 代理，成功后创建名为 `Codex Connection` 的开始菜单快捷方式。在该快捷方式上右键，选择“固定到任务栏”。

本地安装目录为 `%LOCALAPPDATA%\CodexConnection`。

## 启动行为

| 启动方式 | 结果 |
| --- | --- |
| 使用 `Codex Connection`，且 Codex 未运行 | 仅为新建的 Codex 进程注入检测到的本地代理。 |
| 使用 `Codex Connection`，且 Codex 已打开 | 仅聚焦现有窗口；不重启，也不会追溯更改该进程。 |
| 使用原始 Codex 图标 | 正常启动；本项目不会注入代理参数。 |
| 可选的“重启 Codex Connection”脚本 | 关闭 Codex 后再通过专用启动器启动。仅在你明确要重启时运行它。 |

## 卸载

再次运行 [Setup-CodexConnection.cmd](Setup-CodexConnection.cmd) 并选择 `U`，或运行已安装的卸载脚本：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\CodexConnection\Uninstall-CodexScopedProxy.ps1"
```

它只移除本项目的本地文件和快捷方式；不会改动 Codex、代理软件、订阅、TUN 或系统代理。

## 隐私与代理配置

- 安装器优先自动识别已经运行的本地代理，无需手动输入端口。
- 该版本不会索取、导入、修改、上传或发布订阅链接或节点链接。
- 检测出的本地端点只保存在本机安装目录，Git 会忽略它；绝不能提交、放入截图、Issue 或 Release 附件。
- 本地诊断输出也不会写入仓库，只在安装或启动失败时供排查使用。

## 前提条件

- 支持 Windows PowerShell 5.1 的 Windows。
- 已安装 Microsoft Store 版 Codex。
- 已运行的 Clash/Mihomo 兼容本地 HTTP 代理。服务商与其配置由用户自行负责。

## 第三方声明

本项目不包含 Clash Verge Rev 的代码、安装包内容、订阅或代理核心二进制文件。若未来的可选安装器支持本地代理核心，必须直接获取官方 Mihomo 发布包、校验其公开哈希，并在重新分发二进制文件时保留 Mihomo 的版权与 MIT 许可证声明。请勿从 Clash Verge Rev 中拆取或再分发 `verge-mihomo` 侧载核心。

“Clash”与“Mihomo”是第三方项目名称。本项目独立开发，未获得其维护者的关联或背书。

## 排查

- **未检测到可用的本地 HTTP 代理**：启动代理核心，确认其 HTTP 监听在回环地址并支持 HTTPS CONNECT，然后重新运行安装程序。
- **Codex 账号未加载**：检查代理能否访问 ChatGPT/OpenAI 目标的 HTTPS 和 WebSocket。代理端口能连通并不代表桌面端请求一定已成功路由。
- **旧任务栏图标行为不同**：取消固定旧图标，改为固定生成的 `Codex Connection` 开始菜单快捷方式。
- **安装或启动失败**：查看 `%LOCALAPPDATA%\CodexConnection\logs\setup.log`、`installer.log` 或 `launcher.log`。这些日志仅在本机保存，会遮蔽节点链接和令牌类值，且绝不会被放入 Release。

## 许可证

MIT。参见 [LICENSE](LICENSE)。
