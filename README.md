# Codex Clash No-TUN No-System-Proxy Connector（基于 Clash 的 Codex 无 TUN、无系统代理连接器）

<p align="right">
  <strong>English</strong> · <a href="README.zh-CN.md">简体中文</a>
</p>

An interactive Windows installer that starts the Microsoft Store Codex desktop app through an already-running local HTTP proxy, without enabling TUN or changing the Windows system proxy.

The launcher is intentionally scoped: only a **new Codex process started through its generated launcher** receives the proxy environment and Electron proxy argument. The original Codex shortcut, system proxy, TUN mode, DNS, routes, and other applications are not modified.

## Install

1. Start your own local proxy core (for example, Clash/Mihomo) first. It must expose a working loopback HTTP proxy with HTTPS CONNECT support.
2. Double-click [Setup-CodexConnection.cmd](Setup-CodexConnection.cmd), or run it from PowerShell:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Setup-CodexConnection.ps1
   ```

3. The setup program defaults to English. Type `ZH` at its first prompt for Simplified Chinese, then type `1` to install or `2` to uninstall.
4. During installation, type `1` to create the optional **Restart Codex Connection** script, or `2` for No. The normal **Start Codex Connection** script is always installed.
5. Setup auto-detects a live local HTTP proxy before installing. It creates a `Codex Connection` Start Menu shortcut. Right-click that shortcut and choose **Pin to taskbar**.

The local installation is `%LOCALAPPDATA%\CodexConnection`.

## Launch behavior

| How Codex is started | Result |
| --- | --- |
| `Codex Connection` launcher, Codex closed | Starts Codex with the detected local proxy for that child process only. |
| `Codex Connection` launcher, Codex already open | Focuses the existing window; it does not restart or retroactively change that process. |
| Original Codex icon | Starts Codex normally, with no proxy parameter injected by this project. |
| Optional `Restart Codex Connection` script | Stops the Codex app and then launches it through the scoped launcher. Run it only when you explicitly want a restart. |

## Uninstall

Run [Setup-CodexConnection.cmd](Setup-CodexConnection.cmd) again and select `U`, or run the installed uninstaller:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\CodexConnection\Uninstall-CodexScopedProxy.ps1"
```

It removes only this project's local files and shortcuts. Codex, proxy applications, subscriptions, TUN, and the system proxy remain unchanged.

## Privacy and proxy configuration

- The installer first detects an already-running local proxy automatically; no port needs to be typed.
- This version does not ask for, import, modify, upload, or publish subscriptions or node links.
- The detected local endpoint is stored only in the local installation directory. It is ignored by Git and must never be committed, included in a screenshot, issue, or release asset.
- Local diagnostic output is also kept outside the repository and is only useful if setup or launching fails.

## Requirements

- Windows with Windows PowerShell 5.1.
- Microsoft Store Codex installed.
- An already-running local Clash/Mihomo-compatible HTTP proxy. The provider and its configuration are the user's responsibility.

## Third-party notice

This project contains no Clash Verge Rev code, installer content, subscription, or proxy-core binary. If a future optional installer supports a local proxy core, it must obtain the official Mihomo release directly, verify the published checksum, and include Mihomo's copyright and MIT license notice with any redistributed binary. Do not extract or redistribute the `verge-mihomo` sidecar from Clash Verge Rev.

"Clash" and "Mihomo" are third-party project names. This project is independent and is not affiliated with or endorsed by their maintainers.

## Troubleshooting

- **No working local HTTP proxy was detected**: start the proxy core, confirm its HTTP listener is bound to loopback and supports HTTPS CONNECT, then run setup again.
- **Codex account does not load**: test the proxy's HTTPS and WebSocket access to ChatGPT/OpenAI destinations. A successful proxy listener alone is not proof that the desktop app has a working route.
- **Old taskbar icon behaves differently**: unpin the old icon and pin the generated `Codex Connection` Start Menu shortcut.
- **Setup or launch failed**: inspect `%LOCALAPPDATA%\CodexConnection\logs\setup.log`, `installer.log`, or `launcher.log`. These local logs redact node URIs and token-like values and are never included in releases.

## License

MIT. See [LICENSE](LICENSE).
