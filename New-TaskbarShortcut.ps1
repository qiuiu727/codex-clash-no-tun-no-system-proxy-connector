[CmdletBinding()]
param(
    [ValidateSet('en', 'zh')][string]$Language = 'en'
)

$ErrorActionPreference = 'Stop'
$launcherPath = Join-Path $PSScriptRoot 'CodexConnectionLauncher.exe'
if (-not (Test-Path -LiteralPath $launcherPath -PathType Leaf)) {
    throw "Launcher was not found: $launcherPath"
}

$startMenuDirectory = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$zhShortcutName = 'Codex' + [char]0x542F + [char]0x52A8 + '.lnk'
$shortcutName = if ($Language -eq 'zh') { $zhShortcutName } else { 'Start Codex.lnk' }
$shortcutPath = Join-Path $startMenuDirectory $shortcutName

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $launcherPath
$shortcut.Arguments = '--start'
$shortcut.WorkingDirectory = $PSScriptRoot
$shortcut.IconLocation = $launcherPath + ',0'
$shortcut.Description = 'Start or focus Codex through a local proxy without changing system proxy settings'
$shortcut.Save()

Write-Output "Created $shortcutPath"
Write-Output 'Right-click the new Start Menu shortcut and choose Pin to taskbar.'
