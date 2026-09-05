[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$launcherPath = Join-Path $PSScriptRoot 'Start-CodexScopedProxy.ps1'
if (-not (Test-Path -LiteralPath $launcherPath -PathType Leaf)) {
    throw "Launcher was not found: $launcherPath"
}

$package = Get-AppxPackage -Name 'OpenAI.Codex' -ErrorAction Stop |
    Sort-Object Version -Descending |
    Select-Object -First 1
if (-not $package) {
    throw 'Microsoft Store Codex was not found.'
}

$appPath = Join-Path $package.InstallLocation 'app\ChatGPT.exe'
$startMenuDirectory = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$shortcutPath = Join-Path $startMenuDirectory 'Codex Scoped Proxy.lnk'
$powerShellPath = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $powerShellPath
$shortcut.Arguments = '-NoLogo -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $launcherPath + '"'
$shortcut.WorkingDirectory = $PSScriptRoot
$shortcut.IconLocation = $appPath + ',0'
$shortcut.Description = 'Start or focus Codex with a locally configured HTTP proxy'
$shortcut.Save()

Write-Output "Created $shortcutPath"
Write-Output 'Right-click the new Start Menu shortcut and choose Pin to taskbar.'
