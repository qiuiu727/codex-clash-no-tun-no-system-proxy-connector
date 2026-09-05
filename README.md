# Codex Clash No-TUN No-System-Proxy Connector（基于 Clash 的 Codex 无 TUN、无系统代理连接器）

One-click install, start, or focus the Microsoft Store Codex desktop app through an already-running local HTTP proxy, without changing the Windows system proxy or TUN mode.

This is a Windows PowerShell 5.1 project. It is a launcher, not a Clash configuration manager.

## What it does

- If Codex is already running, restores its main window instead of restarting it.
- If Codex is closed, starts the Store app with an Electron proxy argument plus proxy environment variables for the bundled backend.
- Auto-detects a working local HTTP proxy owned by a supported local proxy core.
- Saves the detected endpoint only in the local installation directory, never in the repository.
- Creates an optional Start Menu shortcut that can be pinned to the taskbar.
- Writes local runtime logs to `logs/`, which Git ignores.

## What it deliberately does not do

- Does not include, read, modify, upload, or publish a Clash subscription.
- Does not include a real proxy address or port.
- Does not modify Clash TUN mode, Windows system proxy, routes, DNS, firewall rules, or existing network settings.
- Does not store account credentials, tokens, cookies, Codex conversations, or user paths in the repository.

## Requirements

- Windows 11 or another Windows version with Windows PowerShell 5.1.
- Microsoft Store Codex installed and signed in with a ChatGPT account.
- A local Clash/Mihomo-compatible HTTP proxy already running. Its provider and configuration are your responsibility.
- The proxy must support HTTPS CONNECT and WebSocket upgrades. Codex uses both HTTPS and WebSocket traffic.

## One-click installation

1. Start your own local proxy core first.
2. Run:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install-CodexScopedProxy.ps1
   ```

3. The installer detects the local HTTP proxy, installs launcher files under `%LOCALAPPDATA%`, and creates a Start Menu shortcut. No proxy URL is typed into the repository.
4. Right-click `Codex Scoped Proxy` in the Start Menu and select **Pin to taskbar**.

To launch immediately after installation:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install-CodexScopedProxy.ps1 -LaunchAfterInstall
```

## Uninstall

Run the installed uninstaller:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\CodexScopedProxyLauncher\Uninstall-CodexScopedProxy.ps1"
```

It removes only this launcher's files plus its Start Menu/taskbar shortcuts. It does not remove Codex, Clash, subscriptions, TUN, or system proxy settings.

## Behavior

| Codex state | Launcher action |
| --- | --- |
| Not running | Auto-detects a working local HTTP proxy, then starts Codex with that proxy. |
| Running | Restores and foregrounds the existing Codex window. |
| Still starting | Does not start a second instance. |
| Proxy unavailable | Does not launch Codex; see `logs/launcher.log`. |

## Privacy checklist before publishing a fork

Run these checks from the repository root:

```powershell
git status --ignored
git ls-files
```

`config.json` and `logs/` must remain untracked. Never paste a Clash subscription URL, access token, or provider configuration into an issue, commit, screenshot, or release asset.

## Troubleshooting

- `No working local HTTP proxy was detected`: start the proxy core, then rerun the installer or launcher.
- Account fails to load: verify that the proxy permits HTTPS and WebSocket upgrades for OpenAI/ChatGPT destinations.
- The taskbar shows a duplicate icon: unpin the old shortcut, pin only the generated `Codex Scoped Proxy` shortcut, then launch it once.

## License

MIT. See [LICENSE](LICENSE).
